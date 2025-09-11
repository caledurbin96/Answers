###CHALLENGE 1###

Deploys a wifi profile to Windows with an XML file. 



*FILES*
Answer1.ps1 - PowerShell script that deploys a Wifi profile to Windows using a XML file.  

FakeProfile.xml - Example Wifi profile definition used for testing the script.  

QuickStart.ps1 - Simple wrapper that runs Answer1.ps1 automatically with FakeProfile.xml.  




*STEPS*
Step One:   Download Answers repo from GitHub.

Step Two:   Go to Downloads & unzip the Answers.zip

Step Three: Drag Answers folder into C drive. (Ensure it is not in a second Answers folder.)

Step Four:  Open powershell.

[Instead of Step 5 you can run QuickStart.ps1 to autorun it. You may have to click "Open" & enter "R" twice if prompted!]

Step Five:  Copy/paste the following command:   & "C:\Answers\Challenge_1\Answer1.ps1" -Path "C:\Answers\Challenge_1\FakeProfile.xml"

Step Six:   Open powershell.

Step Seven: Copy/paste the following command to view TestWifi:   netsh wlan show profiles




*USE EXAMPLE*
<ScriptPath>.ps1 -Path '<ProfilePath>.xml'
"C:\Answers\Challenge_1\Answer1.ps1" -Path "C:\Answers\Challenge_1\FakeProfile.xml"




*CODES*
0   = Success (added)
1   = File missing
2   = Malformed/invalid XML
10  = Skipped (already exists)
99  = Unknown errors
