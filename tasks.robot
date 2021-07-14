# +
*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.

Library         RPA.Robocloud.Secrets
Library         RPA.Browser
Library         RPA.HTTP
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.Archive
Library         Dialogs
Library         Collections

# -


*** Keywords ***
Fetch order file name from user
    ${Order_url}=   Get Value From User     Input Order.csv URL 
    Download    ${Order_url}   overwrite=True		target_file=${OUTPUT_DIR}

*** Keywords ***
Fetch browser URL from vault
     ${secret}=     Get Secret   credentials
     ${weburl}=        Set Variable    ${secret}[weburl]
     Set Global Variable     ${URL}     ${weburl}


*** Keywords ***
Place order
    @{sales_order}=    Read Table From Csv  ${OUTPUT_DIR}${/}orders.csv   header=True
       
    FOR    ${order}   IN    @{sales_order}
    Build robot  ${order}
    END

*** Keywords ***
Build robot 
    [Arguments]     ${order} 
    Open Available Browser  ${URL}
    Click Button When Visible  //button[normalize-space()='OK']
    Maximize Browser Window
       
    ${Head} =	Get From Dictionary	${order}	Head
    Select From List By Value   //select[@id='head']    ${Head}
    
    ${Body} =   Get From Dictionary	${order}    Body
    Click Element   //*[@id="id-body-${Body}"]
    
    ${Legs} =	Get From Dictionary	${order}	Legs
    Input Text  //input[@placeholder='Enter the part number for the legs']  ${Legs}
    
    ${Address} =   Get From Dictionary	${order}    Address
    Input Text  //input[@placeholder='Shipping address']    ${Address}
    
    Wait Until Keyword Succeeds     3x      5s   Click Button    //button[normalize-space()='Preview']
    
    Wait Until Keyword Succeeds     3x      5s      Click Button    //button[normalize-space()='Order']
    Sleep   5s
        
    ${IsElementVisible}=  Run Keyword And Return Status   Page Should Contain Element   //button[normalize-space()='Order another robot']
    
    Run Keyword If    ${IsElementVisible}==False    Close Browser 
    
    Run Keyword If    ${IsElementVisible}   Capture Element Screenshot   //div[@id='robot-preview-image']    ${OUTPUT_DIR}${/}output${/}sales_summary.png
    Sleep   5s       
    Run Keyword If    ${IsElementVisible}  Save order receipt  ${order}   ELSE      Build robot   ${order}
    Close Browser



# +
*** Keywords ***
Save order receipt
    [Arguments]     ${order}
    ${OrderNumber} =	Get From Dictionary	${order}	Order number
    ${sales_results_html}=    Get Element Attribute    //div[@id='receipt']    outerHTML
    Html To Pdf    ${sales_results_html}    ${OUTPUT_DIR}${/}output${/}sales_results_${OrderNumber}.pdf
    Open Pdf    ${OUTPUT_DIR}${/}output${/}sales_results_${OrderNumber}.pdf
    ${files}=    Create List
    ...    ${OUTPUT_DIR}${/}output${/}sales_results_${OrderNumber}.pdf
    ...    ${OUTPUT_DIR}${/}output${/}sales_summary.png
    Add Files To PDF     ${files}      ${OUTPUT_DIR}${/}output${/}sales_results_${OrderNumber}.pdf     
    Close Pdf   ${OUTPUT_DIR}${/}output${/}sales_results_${OrderNumber}.pdf
    
   
# -

*** Keywords ***
Create a ZIP archive of receipts
     Archive Folder With ZIP   ${OUTPUT_DIR}${/}output  ${OUTPUT_DIR}${/}Receipts.zip   recursive=True  include=*.pdf  exclude=/.*


*** Tasks ***
Ordering Robots
    Fetch order file name from user
    Fetch browser URL from vault
    Place order
    Create a ZIP archive of receipts









