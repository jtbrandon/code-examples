#used as a wrapper to make sure code can run from anywhere
#Rough steps
# create and CD into a temp folder <
# Git clone the build-release and gv.ps1 files from whatever repo
# Prompt user for the ssh path to clone
# Clone the Desired repo
# CD into the repo
# run the build-release.ps1 or python scripty
# Delete the temp folder

param(
    [Parameter(Mandatory=$true)][string]$repo = "",
    [string]$DryRun = "False"
)
#Variables
$jrepo = "ssh://git@git.youngliving.com:7999/devops/jamison-stash.git"
$current = $pwd
$tempFolder = "$current\tempFolder"

#Clone Repo down
function gitClone($repo){
    git clone $repo
}
#This function will extract the folder name from the git repo URI
function gitCD($r){
    $re = $r.split("/")
    foreach($i in $re){
        if($i -like "*.git"){
            $j = $i.split(".")
            $h = $j[0]
            return $h;
        }
    }
}

#Create Temp Folder to work in and CD into it
New-Item -ItemType directory -Path $tempFolder
cd $tempFolder

#Clone and CD into the repo where the build-release and gv scripts are
gitClone $jrepo
gitCD $jrepo | cd

#Clone and CD into the git repo to build a release
gitClone $repo
gitCD $repo | cd

#Running the build scripty
Clear-Host
Write-host "**** Running build-release.ps1 scripty`n"
Write-host "**** This is the current directory $pwd"
if ($DryRun -eq "True"){
    Write-host "*******   THIS IS A DRY RUN TO MAKE SURE THINGS   *******"
    Write-Host "*******  WORK WITHOUT ACTUALLY MESSING THINGS UP  *******"
    Write-Host "*******               THANK YOU                   *******"
    ../build-release.ps1 -DryRun True
}else{
    ../build-release.ps1
}

#move up in the dir tree and tear down the tempFolder
cd $tempFolder
cd ..
Start-Sleep -s 3
Write-host "**** Success!"
Write-host "**** Deleting $tempFolder"
Remove-item -Path $tempFolder -recurse -force



