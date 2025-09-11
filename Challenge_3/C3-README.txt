CHALLENGE 3

Retrieves economic data from a Federal Reserve Bank of St. Louis API and saves it to CSV files.




*FILES*
key.ps1 – Sets your FRED_API_KEY for the session. 

Answer3.ps1 – Core script that fetches one series from FRED and outputs the json files and logs.

QuickStart.ps1 – Convenience runner that loads your key and then runs Answer3.ps1 




*STEPS*
Step One:   Download Answers repo from GitHub. 

Step Two:   Go to Downloads & unzip the Answers.zip

Step Three: Drag 'Answers-main' folder into C drive & rename the folder to 'Answers'. (Ensure it is not in a second Answers-main folder.)

Step Four:  Open powershell. (May need to run as admin)

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

