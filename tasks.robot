# +
*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.
...             Saves the order receipt
...             Saves screenshot of order
...             Embeds screenshot into a PDF receipt
...             Creates ZIP archive

Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           Collections
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets
Library           OperatingSystem


# +
*** Variables ***
${url}            https://robotsparebinindustries.com/#/robot-order

${img_folder}     ${CURDIR}${/}image_files
${pdf_folder}     ${CURDIR}${/}pdf_files
${output_folder}  ${CURDIR}${/}output

${orders_file}    ${CURDIR}${/}orders.csv
${zip_file}       ${output_folder}${/}pdf_archive.zip
${csv_url}        https://robotsparebinindustries.com/orders.csv
# -

*** Keywords ***
Open the robot order website
    Open Available Browser     ${url}

*** Keywords ***
Get orders
    Download    url=${csv_url}         target_file=${orders_file}    overwrite=True
    ${table}=   Read table from CSV    path=${orders_file}
    [Return]    ${table}

*** Keywords ***
Close the annoying modal
    Click Button   Yep

*** Keywords ***
Fill the form
    [Arguments]     ${myrow}
    
    Select From List By Value   id:head         ${myrow}[Head]
    Click Element       CSS:div.stacked > div.radio input#id-body-${myrow}[Body]
    Input Text  //*[@placeholder="Enter the part number for the legs"]    ${myrow}[Legs]
    Input Text  id:address    ${myrow}[Address]

*** Keywords ***
Preview the robot
    Set Local Variable              ${btn_preview}      //*[@id="preview"]
    Set Local Variable              ${img_preview}      //*[@id="robot-preview-image"]
    Click Button                    ${btn_preview}
    Wait Until Element Is Visible   ${img_preview}

*** Keywords ***
Submit the order
    
    Set Local Variable              ${btn_order}        //*[@id="order"]
    Set Local Variable              ${lbl_receipt}      //*[@id="receipt"]

    
    Mute Run On Failure             Page Should Contain Element 

   
    Click button                    ${btn_order}
    Page Should Contain Element     ${lbl_receipt}

*** Keywords ***
Take a screenshot of the robot
    
    Set Local Variable      ${lbl_orderid}      xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable      ${img_robot}        //*[@id="robot-preview-image"]

   
    Wait Until Element Is Visible   ${img_robot}
    Wait Until Element Is Visible   ${lbl_orderid} 

   
    ${orderid}=                     Get Text            //*[@id="receipt"]/p[1]
    
    Set Local Variable              ${fully_qualified_img_filename}    ${img_folder}${/}${orderid}.png

    Sleep   1sec
    Log To Console                  Capturing Screenshot to ${fully_qualified_img_filename}
    Capture Element Screenshot      ${img_robot}    ${fully_qualified_img_filename}
    
    [Return]    ${orderid}  ${fully_qualified_img_filename}

*** Keywords ***
Go to order another robot
    Click Button    id:order-another

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]        ${ORDER_NUMBER}

    Wait Until Element Is Visible   //*[@id="receipt"]
    Log To Console                  Printing ${ORDER_NUMBER}
    ${order_receipt_html}=          Get Element Attribute   //*[@id="receipt"]  outerHTML

    Set Local Variable              ${fully_qualified_pdf_filename}    ${pdf_folder}${/}${ORDER_NUMBER}.pdf

    Html To Pdf                     content=${order_receipt_html}   output_path=${fully_qualified_pdf_filename}

    [Return]    ${fully_qualified_pdf_filename}

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${IMG_FILE}     ${PDF_FILE}

    Log To Console                  Printing Embedding image ${IMG_FILE} in pdf file ${PDF_FILE}

    Open PDF        ${PDF_FILE}

    @{myfiles}=       Create List     ${IMG_FILE}:x=0,y=0

    Add Files To PDF    ${myfiles}    ${PDF_FILE}     ${True}

    Close PDF           ${PDF_FILE}

*** Keywords ***
Log Out And Close The Browser
    Close Browser

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
   
   
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form           ${row}
        Wait Until Keyword Succeeds     10x     2s    Preview the robot
        Wait Until Keyword Succeeds     10x     2s    Submit The Order
        ${orderid}  ${img_filename}=    Take a screenshot of the robot
        ${pdf_filename}=                Store the receipt as a PDF file    ORDER_NUMBER=${order_id}
        Embed the robot screenshot to the receipt PDF file     IMG_FILE=${img_filename}    PDF_FILE=${pdf_filename}
        Go to order another robot
    END
    Log Out And Close The Browser

