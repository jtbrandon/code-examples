# Maintenance Page Enabler/Disabler

Use this script to enable the Maintenance page on our DNS account. It works by storing a backup copy of the current geo redundant CNAME record(s), then updating them to point to 'redirects'. Once the maintenance page is no longer needed, it will restore the proper backed up values to the CNAME record(s)

**TO USE:**
In CLI with Docker installed run the following (-e to enable the maintenace page, and -d to disable it): 

`DOCKER RUN --name $NAME youngliving/maintenance-page -e|-d --apikey ######### --secretkey ######### --cname www|clone --domain youngliving.com --sanbox`