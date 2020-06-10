
<#PSScriptInfo

.VERSION 1.12

.GUID 78a0131d-de23-4632-8f90-0f08d88bbdd8

.AUTHOR cgibbons

#>

<# 

.DESCRIPTION 
 Build Script Functions 

#>

Param()

# Begin Common Build Vars

    #Originally build_functions.ps1 vars
    $buildURLNugetPowershell = "https://proget.yleo.us/nuget/powershell/"
    $buildURLNugetPsscripts = "https://proget.yleo.us/nuget/psscripts/"
    
    #Originally default_config.ps1 vars
    $buildOctopusServerUrl = "https://octopus.yleo.us"
    $buildNpm_registry = "https://proget.yleo.us/npm/npm/"

# End Common Build Vars

function LoadVSSetup(){
	if (Get-Module -ListAvailable -Name VSSetup) {
		Write-Host "Get-VSSetup exists"
	} else {
		Install-Module -Name VSSetup -Scope CurrentUser -Force -AllowClobber
	}
}

function DeleteDirectory([string]$directory_name)
{
  rd $directory_name -recurse -force  -ErrorAction SilentlyContinue | out-null
}

function CreateDirectory($directory_name)
{
  mkdir $directory_name  -ErrorAction SilentlyContinue  | out-null
}

function UpdateGitVersionFile(){
	$file = 'gv.ps1'
	$ylRepo = Get-PSRepository -Name "*YLNewInternal*" -ErrorAction SilentlyContinue
	if(!$ylRepo){
		Register-PSRepository -Name 'YLNewInternal' -InstallationPolicy Trusted -PackageManagementProvider NuGet -SourceLocation $buildURLNugetPowershell  -PublishLocation $buildURLNugetPowershell -ScriptSourceLocation $buildURLNugetPsscripts -ScriptPublishLocation $buildURLNugetPsscripts
	}
	$scriptVersion = $null
	if(Test-Path $file){
		try{
			$scriptVersion = Test-ScriptFileInfo $file -ErrorAction SilentlyContinue
		}
		catch{
			remove-item $file -force -ErrorAction SilentlyContinue | out-null
			Save-Script -Name 'gv' -Repository 'YLNewInternal' -Path '.'
		}
		
	}
	
	$repoScriptVerison = Find-Script -Name 'gv' -Repository 'YLNewInternal'
	if(!(Test-Path $file) -or ($scriptVersion -and $repoScriptVerison) -and $repoScriptVerison.Version -gt $scriptVersion.Version){
		Save-Script -Name 'gv' -Repository 'YLNewInternal' -Path '.'
	}
	if(($scriptVersion -and $repoScriptVerison) -and $repoScriptVerison.Version -gt $scriptVersion.Version){
		remove-item $file -force -ErrorAction SilentlyContinue | out-null
		Save-Script -Name 'gv' -Repository 'YLNewInternal' -Path '.'
	}
}

function DoSummary([System.Collections.ArrayList] $taskList){
	$totalElapsed = [TimeSpan]@{}
	#foreach($entry in $taskList){$totalElapsed = $totalElapsed + $entry.Elapsed}
	Write-Host $taskList.Count
	for($i=0; $i -lt $taskList.Count; $i++){
		if($i -eq $taskList.Count - 1){
			$taskList[$i].Elapsed = $taskList[$i].Elapsed - $totalElapsed
			if($taskList[$i].Elapsed -lt 0){
				$taskList[$i].Elapsed = [TimeSpan]0
			}
		}
		$totalElapsed = $totalElapsed + $taskList[$i].Elapsed
	}
	$obj = New-Object -TypeName PSObject
	$obj | Add-Member -MemberType NoteProperty -Name Name -Value 'Total Elapsed'
	$obj | Add-Member -MemberType NoteProperty -Name Elapsed -Value $totalElapsed
	$taskList.Add($obj)
	$taskList | Format-Table @{Label = "Task"; Expression = {$_.Name}}, @{Label = "Elapsed Time"; Expression = {$_.Elapsed}}
}

function GetFileList($source, $filter){
    if ($filter -eq $Null) { $filter = "*.Specs.dll" }
    $result = (Get-ChildItem -Path $source -Recurse -Include $filter | foreach {$_.fullname}) -join "`" `""
    return $result
}

function StartJobHere([scriptblock]$block){
  start-job -argumentlist (get-location),$block { set-location $args[0]; invoke-expression $args[1] }
}

function WriteSection([string]$title){
    Write-Host "###########################################################"
    Write-Host $title
    Write-Host "###########################################################"
}

function ChangeDistributorAppConfig($path, $transportPath){
  $transportConfigPath = $transportPath
  $webConfigPath = $path
  $currentDate = (get-date).tostring("mm_dd_yyyy-hh_mm_s") # month_day_year - hours_mins_seconds
  $backup = $webConfigPath + "_$currentDate"
  $xml = [xml](get-content $webConfigPath)
  $xmlTransport = [xml](get-content $transportConfigPath)
  $xml.Save($backup)
  $root = $xml.get_DocumentElement()
  $rootTransport = $xmlTransport.get_DocumentElement()
  $root.TransportConfig.MaximumConcurrencyLevel = $rootTransport.TransportConfig.MaximumConcurrencyLevel
  $xml.Save($webConfigPath)
}

function ZipDirectory($directory,$file)
{
    delete_file $file
    cd $directory
    &"$base_dir\lib\7zip\7za.exe" a -mx=9 -r -sfx $file *.*
    cd $base_dir
}

function DeleteFile($file)
{
    if($file) {
        remove-item $file  -force  -ErrorAction SilentlyContinue | out-null} 
}

function CopyAndFlatten ($source,$filter,$dest)
{
  ls $source -filter $filter -r | cp -dest $dest
}

function CopyFiles($source,$destination,$exclude=@()){    
    CreateDirectory $destination
    Copy-Item $source $destination -recurse -Force
}

function CreateCommonAssemblyInfo($version,$applicationName,$filename)
{
    "using System;
    using System.Reflection;
    using System.Runtime.InteropServices;

    //------------------------------------------------------------------------------
    // <auto-generated>
    //     This code was generated by a tool.
    //     Runtime Version:2.0.50727.4927
    //
    //     Changes to this file may cause incorrect behavior and will be lost if
    //     the code is regenerated.
    // </auto-generated>
    //------------------------------------------------------------------------------

    [assembly: ComVisibleAttribute(false)]
    [assembly: AssemblyVersionAttribute(""$version"")]
    [assembly: AssemblyFileVersionAttribute(""$version"")]
    [assembly: AssemblyCopyrightAttribute(""Copyright 2010"")]
    [assembly: AssemblyProductAttribute(""$applicationName"")]
    [assembly: AssemblyCompanyAttribute("""")]
    [assembly: AssemblyConfigurationAttribute(""release"")]
    [assembly: AssemblyInformationalVersionAttribute(""$version"")]"  | out-file $filename -encoding "ASCII"
}  

function CreateTempCopy([string]$file){
        $tmpFile = [System.IO.Path]::GetTempFileName()
        Copy-Item $file $tmpFile
        return $tmpFile
}

function ReplaceInFile ([string] $file, [string]$match, [string] $replacement, [string] $encoding){
    $output = (cat $file) -replace $match, $replacement
    Set-Content -Encoding $encoding $file $output
}

function CompileProject([string]$projectFile) {
	WriteSection "Building $projectFile"
	exec { msbuild /m "$projectFile" /t:Rebuild /P:Configuration=$configuration;}
}

function GetHashFromGit
{
  $hash = git rev-parse HEAD
  return $hash
}

function GetGitShortHash {
    git rev-parse --short HEAD
}

function GitTag($version,$description)
{
    git tag -a $version -m $description
    git push origin $version
}

function GitTag($version,$description, $revision)
{
    git tag -a $version -m $description $revision
    git push origin $version
}

function ReplaceGitRevision([string[]] $files) {
    $shortHash = GetGitShortHash 

    foreach ($file in $files){
       $output = (cat $file) -replace 'GIT_REVISION', $shortHash 
       Set-Content -Encoding "UTF8" $file $output
    }
}

function RunGitVersion([string]$exePath, [string]$writePath){
	UpdateGitVersionFile
    DeleteFile $writePath
    $gitVersionOutput = & $exePath
    if(![string]::IsNullOrEmpty($writePath)){
        Set-Content -Encoding "UTF8" $writePath $gitVersionOutput
    }
    $gitVersionOutput -join "`n" | Write-Host
	$objectOutput = @"
	$gitVersionOutput
"@


	$gitVersionObject = $objectOutput | ConvertFrom-Json
	return $gitVersionObject
}

function WriteSemVerToFile([string]$exePath,[string]$filePath){
	$gitVersionOutput = & $exePath
	Set-Content -Encoding "UTF8" $filePath $gitVersionOutput
}


function SetJsBuildVariables ([string]$baseDir) {
    $path = "$baseDir\YoungLiving.VirtualOffice.WebSite\Content\app\main\build-variables.js"
    $file = Get-Content $path
    $shortHash = Get-GitShortHash 
    $text = [IO.File]::ReadAllText($path)

    $text = $text.Replace("revision.short", $shortHash);
    Set-Content -Encoding "UTF8" $path $text
}

function GetDateVersionString([DateTime] $date){
    $year = $date.Year - 2000;
    $day_of_year = $buildDate.DayOfYear.ToString("000")
    $hour = $date.Hour.ToString("00")
    $minute = $date.Minute.ToSTring("00")
	return "$year$day_of_year.$hour$minute"
}

function GetDateTag([DateTime]$date, [string]$configuration){
    return "$configuration_" + $date.ToString("yyyy.MM.dd.HH_mm")
}

function GetProp([string]$prop){
	return $props[$prop]
}

function SetProp([string]$prop, $value){
	$props[$prop] = $value
}

function GetLatestDeployedDirs($folder){
	Get-ChildItem -Path $folder -Directory |
	Where-Object { $_.Name -match '\d\d\d\d.\d\d.\d\d.\d\d_\d\d' } |
	Sort-Object Name -desc 
}

function IsNull($objectToCheck) {
    if (!$objectToCheck) {
        return $true
    }
 
    if ($objectToCheck -is [String] -and $objectToCheck -eq [String]::Empty) {
        return $true
    }
 
    if ($objectToCheck -is [DBNull] -or $objectToCheck -is [System.Management.Automation.Language.NullString]) {
        return $true
    }
 
    return $false
}

function ReplaceText($configFileName, $stringToReplace, $replacementText){
    Write-Host $configFileName
    Write-Host $stringToReplace
    Write-Host $replacementText
    (Get-Content $configFileName) | Foreach-Object {$_ -replace $stringToReplace, $replacementText} | Set-Content $configFileName
}


function XmlDocTransform($xml, $xdt)
{
    if (!$xml -or !(Test-Path -path $xml -PathType Leaf)) {
        throw "File not found. $xml";
    }
    if (!$xdt -or !(Test-Path -path $xdt -PathType Leaf)) {
        throw "File not found. $xdt";
    }

    Add-Type -LiteralPath "$baseDir\lib\Microsoft.Web.XmlTransform.dll"

    $xmldoc = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument;
    $xmldoc.PreserveWhitespace = $true
    $xmldoc.Load($xml);

    $transf = New-Object Microsoft.Web.XmlTransform.XmlTransformation($xdt);
    if ($transf.Apply($xmldoc) -eq $false)
    {
        throw "Transformation failed."
    }
    $xmldoc.Save($xml);
}

