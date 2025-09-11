CHALLENGE 2

Takes a blocklist of domains, emails, and IPs and sorts them into categories. 




*FILES*
Answer2.ps1 – The core PowerShell script that parses blocklist.txt into categories.

blocklist.txt – The input file of IP addresses, domains, and emails.

QuickStart.ps1 – A helper script that automatically runs Answer2.ps1 against blocklist.txt.




*STEPS*

Step One:   Download Answers repo from GitHub.

Step Two:   Go to Downloads & unzip the Answers.zip

Step Three: Drag Answers folder into C drive. (Ensure it is not in a second Answers folder.)

Step Four:  Open powershell.

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
