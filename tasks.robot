*** Settings ***
Documentation   Template robot main suite.
Library         RPA.Browser.Selenium
Library         RPA.HTTP
Library         RPA.Excel.Files
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.FileSystem
Library         RPA.Archive
Library         RPA.Dialogs
Library         RPA.Robocloud.Secrets


*** Keywords ***
Ask the user for download url
    Create Form    Order list
    Add Text Input    label=Give url for the orders.csv file   name=url
    ${result}=    Request Response
    [Return]      ${result["url"]}

*** Keywords ***
Get the website url from vault
    ${secret}=    Get Secret    website
    Log    ${secret}[url]
    [Return]     ${secret}[url]

*** Keywords ***
Open the website
    [Arguments]             ${url}
    Open Chrome Browser     ${url}

*** Keywords ***
Close the modal
    Click Button When Visible   xpath:/html/body/div/div/div[2]/div/div/div/div/div/button[1]

*** Keywords ***
Get orders
    [Arguments]   ${url}
    Download      ${url}       overwrite=True
    ${orders}=    Read Table From Csv    orders.csv   header=True
    [Return]      ${orders}

*** Keywords ***
Fill the form
    [Arguments]    ${order}
    Select From List By Index    id:head       ${order}[Head]
    Select Radio Button          body          ${order}[Body]
    Input Text           xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input      ${order}[Legs]
    Input Text           id:address    ${order}[Address]

*** Keywords ***
Take a screenshot
    [Arguments]         ${order_number}
    Sleep       0.5s
    ${screenshot}=      Capture Element Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}robot-${order_number}.png
    [Return]            ${screenshot}

*** Keywords ***
Submit the order
    Click Button    id:order
    Wait Until Page Contains Element    id:receipt

*** Keywords ***
Save the receipt as PDF
    [Arguments]        ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${CURDIR}${/}output${/}receipt-${order_number}.pdf

*** Keywords ***
Create a full receipt
    [Arguments]    ${order_number}
    ${files}=     Create List     ${CURDIR}${/}output${/}receipt-${order_number}.pdf     ${CURDIR}${/}output${/}robot-${order_number}.png
    Add Files To Pdf    ${files}     ${CURDIR}${/}output${/}receipt-order-${order_number}.pdf

*** Keywords ***
Clean up
    [Arguments]    ${order_number}
    Remove Files    ${CURDIR}${/}output${/}receipt-${order_number}.pdf     ${CURDIR}${/}output${/}robot-${order_number}.png

*** Tasks ***
Order robots from website
    Set Selenium Timeout    0.2
    ${download_url}=    Ask the user for download url
    ${website_url}=     Get the website url from vault
    ${orders}=   Get orders    ${download_url}
    Open the website    ${website_url}
    FOR  ${order}  IN  @{orders}
        Close the modal
        Fill the form    ${order}
        Click Button    id:preview
        Wait Until Keyword Succeeds    10x   0.1s    Submit the order
        ${pdf}=          Save the receipt as PDF    ${order}[Order number]
        ${screenshot}=   Take a screenshot          ${order}[Order number]
        Create a full receipt    ${order}[Order number]
        Clean up    ${order}[Order number]
        Click Button    id:order-another
    END
    Archive Folder With Zip     ${CURDIR}${/}output    ${CURDIR}${/}output.zip


