### ALL CHALLENGE READMES ###


=========================================================================================


##CHALLENGE 1##

Deploys a wifi profile to Windows with an XML file. 



*FILES*
Answer1.ps1 - PowerShell script that deploys a Wifi profile to Windows using a XML file.  

FakeProfile.xml - Example Wifi profile definition used for testing the script.  

QuickStart.ps1 - Simple wrapper that runs Answer1.ps1 automatically with FakeProfile.xml.  




*STEPS*
Step One:   Download Answers repo from GitHub.

Step Two:   Go to Downloads & unzip the Answers.zip

Step Three: Drag 'Answers-main' folder into C drive & rename the folder to 'Answers'. (Ensure it is not in a second Answers-main folder.)

Step Four:  Open powershell. (May need to run as admin.)

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


=========================================================================================


##CHALLENGE 2##

Takes a blocklist of domains, emails, and IPs and sorts them into categories. 




*FILES*
Answer2.ps1 – The core PowerShell script that parses blocklist.txt into categories.

blocklist.txt – The raw mixed input file of IP addresses, domains, and emails that your script processes.

QuickStart.ps1 – A helper script that automatically runs Answer2.ps1 against blocklist.txt.




*STEPS*

Step One:   Download Answers repo from GitHub.

Step Two:   Go to Downloads & unzip the Answers.zip

Step Three: Drag 'Answers-main' folder into C drive & rename the folder to 'Answers'. (Ensure it is not in a second Answers-main folder.)

Step Four:  Open powershell. (May need to run as admin.)

[Instead of Step 5 you can open QuickStart.ps1 or run it in powershell to autorun it. You may have to click "Open" & enter "R" twice if prompted!]

Step Five:  Copy/paste the following command:   C:\Answers\Challenge_2\Answer2.ps1 -Path 'C:\Answers\Challenge_2\blocklist.txt'

Step Six:   Go to C:\Answers\Challenge_2\output for your output information. 




*USE EXAMPLE*
<ScriptPath>.ps1 -Path '<BlockListPath>.txt'
C:\Answers\Challenge_2\Answer2.ps1 -Path 'C:\Answers\Challenge_2\blocklist.txt'




*CODES*
0  = Success
1  = File not found
99 = Unknown error


=========================================================================================


##CHALLENGE 3##

Retrieves economic data from a Federal Reserve Bank of St. Louis API and saves it to json files.




*FILES*
key.ps1 – Sets your FRED_API_KEY for the session. 

Answer3.ps1 – Core script that fetches one series from FRED and outputs the json files and logs.

QuickStart.ps1 – Convenience runner that loads your key and then runs Answer3.ps1 




*STEPS*
Step One:   Download Answers repo from GitHub. 

Step Two:   Go to Downloads & unzip the Answers.zip

Step Three: Drag 'Answers-main' folder into C drive & rename the folder to 'Answers'. (Ensure it is not in a second Answers-main folder.)

Step Four:  Open powershell. (May need to run as admin.)

[Instead of Step 5-7 you can run QuickStart.ps1 to autorun it. You may have to click "Open" & enter "R" twice if prompted!]

Step Five:  Right click on C:\Answers\Challenge_3\key.ps1 and select 'Edit in notepad'. Replace the FRED_API_KEY or ensure it is correct.

Step Six:   Open or run key.ps1 with powershell. "Open" & enter "R" if prompted!

Step Seven:   While still in powershell, copy/paste the following commands:
C:\Answers\Challenge_3\Answer3.ps1 -SeriesId UNRATE -Start 2015-01-01
C:\Answers\Challenge_3\Answer3.ps1 -SeriesId CPIAUCSL -Start 2015-01-01
C:\Answers\Challenge_3\Answer3.ps1 -SeriesId DGS10 -Start 2015-01-01

Step Eight:   Go to C:\Answers\Challenge_3\output for your output information. 




*USE EXAMPLE*
<KeyPath>.ps1
C:\Answers\Challenge_3\key.ps1

<ScriptPath>.ps1 -SeriesId <FREDSeriesID> -Start <StartDate>
C:\Answers\Challenge_3\Answer3.ps1 -SeriesId UNRATE -Start 2015-01-01
C:\Answers\Challenge_3\Answer3.ps1 -SeriesId CPIAUCSL -Start 2015-01-01
C:\Answers\Challenge_3\Answer3.ps1 -SeriesId DGS10 -Start 2015-01-01



*CODES*
0 = Success
2 = No observations / unusable data
99 = Unknown error




