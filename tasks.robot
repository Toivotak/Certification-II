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

*** Variables ***

${URL}=           https://robotsparebinindustries.com/#/robot-order
${GLOBAL_RETRY_AMOUNT}=      10x
${GLOBAL_RETRY_INTERVAL}=    0.1s

*** Keywords ***

Open robot order website
    Log    Page opening
    Open Available Browser      ${URL}
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}     Click OK

Download orders file
    ${URLS}=    Get Secret    urls
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
    ${pdf}=         Open Pdf    ${CURDIR}${/}output${/}receipts${/}receipt${orderNumber}.pdf
    Add Watermark Image To Pdf    ${CURDIR}${/}output${/}pngs${/}${orderNumber}.png   ${CURDIR}${/}output${/}receipts${/}receipt${orderNumber}.pdf     ${CURDIR}${/}output${/}receipts${/}receipt${orderNumber}.pdf 
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
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}     Order another
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}     Click OK

Order another
    Click Button    order-another
    Sleep    0.1s
    Element Should Not Be Visible    order-another

Click OK
    Click Button    OK
    Sleep    0.1s
    Element Should Not Be Visible    OK

Make order
    Wait Until Element Is Visible   id:robot-preview-image 
    Click Button    order
    Sleep    0.1s
    Element Should Not Be Visible    order

*** Keywords ***
Fill order
    [Arguments]     ${order}
    Log    Order filling
    Select From List By Value    head                                           ${order}[Head]
    Select Radio Button          body                                           ${order}[Body]
    Input Text                   css:div.form-group:nth-child(3) > input        ${order}[Legs]
    Input Text                   address                                        ${order}[Address]
    Open Preview
    Wait Until Keyword Succeeds    3x    1s    Make order
    Create PDF reciept
    
Fill orders from csv
    ${orders}=      Read table from CSV    orders.csv   
    FOR    ${order}    IN    @{orders}
        Log             ${order}
        Run Keyword And Continue On Failure    Fill order      ${order}
        Run Keyword And Continue On Failure    New order
    END

*** Keywords ***
Creating a ZIP archive
   Archive Folder With ZIP   ${CURDIR}${/}output${/}receipts${/}  receipts.zip   recursive=True  include=*.pdf  exclude=/.*
   @{files}                  List Archive             receipts.zip
   FOR  ${file}  IN  ${files}
      Log  ${file}
   END

*** Keywords ***
Get user input
    Add heading         Write us a review!                      
    Add text input      input    label=Anything on your mind?
    ${response}=        Run dialog
    [Return]    ${response}
Display user input
    [Arguments]    ${input}
    Add heading    ${input.input}
    Run dialog

*** Keywords ***
Cleaning tasks
    Close Browser
    Empty Directory     ${CURDIR}${/}output${/}receipts${/}
    Empty Directory     ${CURDIR}${/}output${/}pngs${/}
    Remove Directory    ${CURDIR}${/}output${/}receipts${/}
    Remove Directory    ${CURDIR}${/}output${/}pngs${/}
    Remove File         ${CURDIR}${/}output${/}*.yaml
    
*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open robot order website
    Download orders file
    Fill orders from csv
    Creating a ZIP archive
    ${input}=    Get user input
    Display user input    ${input}
    [Teardown]  Cleaning tasks
