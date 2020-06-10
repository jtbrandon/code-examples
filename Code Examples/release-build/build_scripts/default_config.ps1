#### Global Properties ####
$buildDate = Get-Date
$deployRemote = $false
$configuration = "Debug"

#### Common Paths ####
$baseDir = resolve-path .
$buildDir = "$baseDir\build"
$solutionFile = "$baseDir\Yleo.Macco.sln"
$gitVersionFilePath = "GitVersionSemVer.txt"
$octopusServerUrl = "http://octopus.yleo.us"
$octoDeployNugetServer = "$octopusServerUrl/nuget/packages"
$octo_deploy_publish_key= "API-BJZAIWRUTV30LLD2JMMMIHQEXUO"
$gitVersionPropertiesPath = "GitVersionSemVer.props"
$nuget_package_deploy_dir = "$buildDir\NugetPackages\"
$nuget_repository_dir = "C:\DefaultImport"
$proget_API_key = 'asdfasdf'
$proget_Url = 'https://proget.yleo.us/nuget/nuget/'

#### External Tool Paths ####
$nugetPath = "lib\NuGet.exe"
$gitVersionPath = "./gv.ps1"
$octoExe = "C:\tools\OctopusCommandLine\Octo.exe"
$dotnet =   "c:\Program Files\dotnet\dotnet.exe"
$msbuild = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe | select-object -first 1
$opencoverExe = $env:USERPROFILE + "\.nuget\packages\opencover\4.6.519\tools\OpenCover.Console"
$reportGeneratorExe = $env:USERPROFILE + "\.nuget\packages\ReportGenerator\2.5.7\tools\ReportGenerator.exe"
$fluentMigratorPath = $env:USERPROFILE + "\.nuget\packages\fluentmigrator.console\3.1.3\net461\x64"
$fluentMigratorExe = "$fluentMigratorPath\Migrate.exe"

  #### Nuget Package Specific ####
$clientConfig = @{
	projectPath = "$baseDir/Yleo.Macco.Client";
	projectFolder = "Yleo.Macco.Client";
}

$coreConfig = @{
	projectPath = "$baseDir/Yleo.Macco.Core";
	projectFolder = "Yleo.Macco.Core";
}

$webProjectConfig = @{
	projectFolder = "Yleo.Macco.Web";
	projectPath = "$baseDir/$projectFolder"
	projectFile = "$baseDir/Yleo.Macco.Web/Yleo.Macco.Web.csproj"
	launchSettings = "$baseDir/Yleo.Macco.Web/Properties/launchSettings.json"
	shortName = "MaccoWeb"
}

$webApiConfig = @{
	projectFolder = "Yleo.Macco.WebApi";
	projectFile = "Yleo.Macco.WebApi.csproj";
	nuspecFile = "Yleo.Macco.WebApi.nuspec";
}

$migrationProjectConfig = @{
	projectFolder = "Yleo.Macco.Migrations";
	projectFile = "Yleo.Macco.Migrations.csproj";
	nuspecFile = "Yleo.Macco.Migrations.nuspec";
}
