Check SSL expiration and notify per mail [AzureRM]
==================================================

            

 


This runbook will check all certificates, within your subscription, on expiration date.


By default it uses sendgrid for mail notifications whenever a certificate hits the given treshold.
Please leave me feedback when you feel like this runbook needs improvements.

Obviously you can use any other kind of notification when you feel like mails are not your thing.


# This script has been created by Bram Stoop
# Feel free to visit my website https://bramstoop.com/ and leave me comments/give me feedback on this runbook
# You can also follow me on twitter https://twitter.com/bramstoopcom

Make sure you have the AzureRM.websites module installed withing Azure Automation.
Keep in mind that the Sendgrid username has this format azure_somekindofnumber@azure.com - this can be found in the azure portal.


 

 

        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
