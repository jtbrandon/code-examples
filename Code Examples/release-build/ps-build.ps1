#This script will create a release branch for the specified version based off an up-to-date Master Branch
#It will then merge the up-to-date integration branch into the newly created release branch
#Finally it will push up the changes to the Origin 

#variables4
param(
    [string]$DryRun = "False"
)

$masterBranch = "master"
$rel = Read-Host -prompt "Please enter the version # for the release branch to be created (ie. 1.8 for release/1.8)"
$relBranch = "release/$rel"
$intBranch = Read-Host -prompt "Please enter the integration branch"

#function for checking out for a given branch
function gitCheckout($branch, $new){
	if (!$new){
        Write-Host "**** Checking out $branch branch"
        git checkout $branch
    }else {
        Write-Host "**** Creating branch: Using git checkout $new $branch"
        Try{

            git checkout -b $branch
        }
        Catch{
            Write-Host $_
        }
    }
}
#simple merge of the integration branch into the new release branch
function gitMerge($dest){
    Write-Host "**** Merging $dest branch into $relBranch"
    git merge $dest
}
#pushing new branch up to origin after user is ready
function gitpush($branch){
    $i = 0
    while ($i -ne 1){
        Write-Host "Running version checking Script; See results below"
        ../gv.ps1
        $pick = Read-Host -prompt "**** About to push $branch upstream. Are you ready?(y/n)"
        if ($pick -eq "y"){
            try{
                Write-Host "**** Pushing new branch: $branch up"
                if ($DryRun -eq "True"){
                    Write-Host "***** DRY RUN, NOTHING PUSHED *****"
                    Write-Host "**** Normal Run would run:git push --set-upstream origin $branch"
                    clean
                }else{
                    Write-Host "**** PUSHING TO ORIGIN"
                    git push --set-upstream origin $branch
                }
            }catch {
                Write-Host $_
                Write-Host "**** Error in pushing $relBranch to Origin"
            }
            $i = 1
        }elseif ($pick -eq "n"){
            Write-Host "`n**** Please get yourself ready and re-run the script. Thank You ****"
            clean
            $i = 1
            Exit 1
        }else{
            Clear-Host
            Write-Host "*******************************************************************"
            Write-Host "`n#\**** Sorry, does not compute. Neither y or n was submitted ****/#"
            Write-Host "#\****   Please prep accordingingly and re-run the script    ****/#" 

        }
    }
}
#simple git pull
function gitpull(){
    Write-Host "**** Pulling the latest using git pull"
    git pull
}
#incase of messups this will checkout master and delete the created release branch
function clean(){
    Write-Host "`n**** Cleaning some things up..."
    gitCheckout $masterBranch
    Write-Host "`n**** Deleting $relBranch"
    git branch -D $relBranch
}

Write-Host "**** Here are the values; Release branch: $relBranch, and integration branch: $intBranch"
try{
    Write-Host "**** Here is the current Directory:"
    Get-Location
    #Master Branch Checkout and Pull
    gitCheckout $masterBranch
    gitPull

    #Release Branch creation
    gitCheckout $relBranch "-b"

    #Integration Branch Checkout and Pull
    gitCheckout $intBranch
    gitpull

    #Checkout Release Branch and Merge in Integration Branch
    gitCheckout $relBranch
    gitMerge $intBranch 
    gitpush $relBranch
    Write-Host "-\|/-\|/- Success! -\|/-\|/- "
}
catch{
    Write-Host $_
}

