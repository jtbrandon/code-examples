function UpdateBuildFunctionsScriptIfNeeded(){
	$buildFile = 'build_scripts/build_functions.ps1'
	$ylRepo = Get-PSRepository -Name "*YLNewInternal*" -ErrorAction SilentlyContinue
	if(!$ylRepo){
		Register-PSRepository -Name 'YLNewInternal' -InstallationPolicy Trusted -PackageManagementProvider NuGet -SourceLocation 'https://proget.yleo.us/nuget/powershell/' -PublishLocation 'https://proget.yleo.us/nuget/powershell/' -ScriptSourceLocation 'https://proget.yleo.us/nuget/psscripts/' -ScriptPublishLocation 'https://proget.yleo.us/nuget/psscripts/'
	}
	$scriptVersion = $null
	if(Test-Path $buildFile){
		try{
			$scriptVersion = Test-ScriptFileInfo $buildFile -ErrorAction SilentlyContinue
		}
		catch{
			remove-item $buildFile -force -ErrorAction SilentlyContinue | out-null
			Save-Script -Name 'build_functions' -Repository 'YLNewInternal' -Path 'build_scripts'
		}

	}

	$repoScriptVerison = Find-Script -Name 'build_functions' -Repository 'YLNewInternal'
	if(!(Test-Path $buildFile) -or ($scriptVersion -and $repoScriptVerison) -and $repoScriptVerison.Version -gt $scriptVersion.Version){
		Save-Script -Name 'build_functions' -Repository 'YLNewInternal' -Path 'build_scripts'
	}
	if(($scriptVersion -and $repoScriptVerison) -and $repoScriptVerison.Version -gt $scriptVersion.Version){
		remove-item $buildFile -force -ErrorAction SilentlyContinue | out-null
		Save-Script -Name 'build_functions' -Repository 'YLNewInternal' -Path 'build_scripts'
	}
}

UpdateBuildFunctionsScriptIfNeeded

. 'build_scripts/build_functions.ps1'

UpdateGitVersionFile

$gvValue = RunGitVersion "./gv.ps1"
$returnString = $gvValue.LegacySemVerPadded
$output = $returnString.Replace("`r`n","`n")

return $output
