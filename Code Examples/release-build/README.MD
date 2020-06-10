# README for the release branch build

DryRun is used to test the functionality without breaking anything

	* A Python Version (main-build.py)

- Main-Build.py

	- Mainly a wrapper for the other scripts it calls
	- The main-build will create a temp folder and clone the jamison's stach repo and the repo argument/param provided
	- It will call the build-release.ps1 or relb.py, passing the DryRun argument/param. 
	- Once the script has finished it will remove/delete the temp folder
	
- Build.py

	- This script will run all the fun stuff
	- It will checkout the Master Branch and pull down the latest
	- It will create the new release branch based off the user input
	- It will checkout the integration branch based off the user input
	- It will merge the integration branch into the release branch
	- It will push the newly create release branch up to origin

**Python:**

	* In you shell of choice run: python ./main-build.py -r {repo} {DryRun}
		* ex. for DryRun of Nature's Ultra: python ./main-build.py -r ssh://git@git.youngliving.com:7999/ylcore/natures-ultra.git
		**Run DryRun true to test functionality**
	* It will run and prompt user for Release # and integration branch
	* It will prompt for final verification after the gv.ps1 script has been run to find the version into