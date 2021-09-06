*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.Excel.Files
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.Images
Library           RPA.Archive
Library           Collections
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault
Library           OperatingSystem



# +
*** Variables ***

${URL}=           https://robotsparebinindustries.com/#/robot-order
#${CSVURL}=        asd
${GLOBAL_RETRY_AMOUNT}=      3x
${GLOBAL_RETRY_INTERVAL}=    0.5s

# +
*** Keywords ***

Open robot order website
    Log    Page opening
    #${URL}=           https://robotsparebinindustries.com/#/robot-order
    Open Available Browser      ${URL}
    Click Button    OK

Download orders file
    ${URLS}=    Get Secret    urls
    
    #${CSVURL}=        ${URLS}[ordersURL]
    Log         Downloading orders
    Download    ${URLS}[ordersURL]   overwrite=True

# +
*** Keywords ***
Take picture
    [Arguments]     ${orderNumber}
    Capture Element Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}pngs${/}${orderNumber}.png
    [Return]    ${orderNumber}.png

Open Preview
    Click Button    preview
    Wait Until Element Is Visible    id:robot-preview-image

Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${orderNumber}
    #@{myfiles}=     Create List    ${CURDIR}${/}output${/}pngs${/}${orderNumber}.png
    ${pdf}=         Open Pdf    ${CURDIR}${/}output${/}receipts${/}receipt${orderNumber}.pdf
    Add Watermark Image To Pdf    ${CURDIR}${/}output${/}pngs${/}${orderNumber}.png   ${CURDIR}${/}output${/}receipts${/}receipt${orderNumber}.pdf     ${CURDIR}${/}output${/}receipts${/}receipt${orderNumber}.pdf
    #Add Files To Pdf        ${myfiles}    ${pdf}
    Close Pdf   ${pdf}

Create PDF reciept
    Wait Until Element Is Visible     id:receipt
    ${receipt}=         Get Element Attribute    receipt    innerHTML
    ${orderNumber}=     Get Text   css:.badge

    Html To Pdf    ${receipt}    ${CURDIR}${/}output${/}receipts${/}receipt${orderNumber}.pdf
    Take picture    ${orderNumber}
    Embed the robot screenshot to the receipt PDF file      ${orderNumber}
    [Return]    ${orderNumber}

New order
    #Wait Until Element Is Visible    order-another
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}     Click Button    order-another
    #Wait Until Element Is Visible    OK
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}     Click Button    OK

Make order
    Wait Until Element Is Visible   id:robot-preview-image 
    
    Wait Until Keyword Succeeds    3x    1s     Click Button    order
    #Page Should Not Contain Button    order

# +
*** Keywords ***
Fill order
    [Arguments]     ${order}
    Log    Order filling
    Select From List By Value    head                                           ${order}[Head]
    Select Radio Button          body                                           ${order}[Body]
    Input Text                   css:div.form-group:nth-child(3) > input        ${order}[Legs]
    Input Text                   address                                        ${order}[Address]
    Open Preview
    Make order
    Create PDF reciept
    #Take picture                ${orderNumber}
    
    

Fill orders from csv
    #Set Screenshot Directory    output/screenshots/
    ${orders}=      Read table from CSV    orders.csv   
    FOR    ${order}    IN    @{orders}
        Log             ${order}
        Run Keyword And Continue On Failure    Fill order      ${order}
        Run Keyword And Continue On Failure    New order
    END
# -

*** Keywords ***
Creating a ZIP archive
   Archive Folder With ZIP   ${CURDIR}${/}output${/}receipts${/}  receipts.zip   recursive=True  include=*.pdf  exclude=/.*
   @{files}                  List Archive             receipts.zip
   FOR  ${file}  IN  ${files}
      Log  ${file}
   END

*** Keywords ***
Cleaning tasks
    Close Browser
    Empty Directory    ${CURDIR}${/}output${/}

*** Keywords ***
Get user input
    Add heading         Write us a review!                      
    Add text input      input    label=Anything on your mind?
    Sleep    5000

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open robot order website
    Download orders file
    Fill orders from csv
    Creating a ZIP archive
    Get user input
    [Teardown]  Cleaning tasks
