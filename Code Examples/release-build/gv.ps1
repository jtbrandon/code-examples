<#PSScriptInfo

.VERSION 2.20

.GUID 87b1856b-1bb3-44ba-a43e-9181d47b6e74

.AUTHOR Daniel Tabuenca, Chris Gibbons (at least I tried)

.COMPANYNAME YoungLiving

#>

<# 

.DESCRIPTION 
 GitVersion Version Getter 

#> 

$versionExpression = "^(\d+\.\d+\.\d+)($|-rc.*?|-beta[-A-Za-z0-9]*?)(\d{0,4})?$" 
$releaseBranchExpression = "^refs/heads/release/(\d+).(\d+)$"
$rcBranchExpression = "^refs/heads/rc/(.*)$"
$integrationBranchExpression = "^refs/heads/integration/(.*)$"

function rollUpToNextMajor([System.Version] $version) {
    New-Object System.Version(($version.major + 1), 0, 0, 0);
}

function incrementMinor([System.Version] $version) {
    New-Object System.Version($version.major, ($version.minor + 1), 0, 0);
}

function incrementPatch([System.Version] $version) {
    New-Object System.Version($version.major, $version.minor, ($version.build + 1), 0);
}

function incrementRevision([System.Version] $version) {
    New-Object System.Version($version.major, $version.minor, $version.build, ($version.Revision + 1));
}

function specificVersion($major, $minor, $suffix) {
    "^($major\.$minor\.\d+)($|-$suffix)(\d*)$" 
}


function getVersionFromMatch($match) {
    $mainVersion = $match.groups[1];
    $suffixVersion = if ($match.groups[3].value) {$match.groups[3].value } else {"0"};
    $version = "$mainVersion.$suffixVersion"
    return New-Object System.Version($version)
}

function getIntegrationName($branch) {
    $match = (($branch -match $integrationBranchExpression) -or ($branch -match $rcBranchExpression))
    if ($match) {
        $truncatedBranch = $matches[1]
        if ($truncatedBranch.length -lt 11) {
            #$truncatedBranch = $integrationName
        }
        else {
            $truncatedBranch = $truncatedBranch.subString(0, 10) #Need to truncate since nuget only supports 20 characters in the "special" part of the version.
        }
        return $truncatedBranch
    }
}

function getTags([string] $versionExpression) {
    $tags = (git tag -l | select-string $versionExpression)
    $versions = ($tags |foreach {
            getVersionFromMatch $_.Matches[0];
        } | Sort-Object -Descending)
    return $versions
}


function getCurrentTagVersion() {
    $currentTags = (git tag -l --points-at HEAD | Select-String $versionExpression )
    $versions = ($currentTags | foreach { 
            getVersionFromMatch $_.Matches[0]} | Sort-Object -Descending);
    if ($versions) {
        return $versions[0];
    }
}

function findMasterVersion() {
    $latest = getTags($versionExpression)  | where {$_.Revision -eq 0} | select -First 1
    return incrementPatch($latest)
}

function getPossibleNextVersion($currentVersion, $possibleNextVersion) {
    $nextVersionTags = (getTags(specificVersion $possibleNextVersion.major $possibleNextVersion.minor "beta" |select -First 1))
    if ($nextVersionTags) {
        return $possibleNextVersion
    }
    return $currentVersion
}

function findDevelopVersion($integrationName) {
    $latest = getTags($versionExpression) | where {$_.Revision -eq 0} | select -First 1
    if (!$latest) {
        $developVersion = New-Object System.Version(1, 0, 0, 0);
    }
    else {
        $developVersion = incrementMinor($latest);
    }

    $developVersion = getPossibleNextVersion $developVersion (incrementMinor($developVersion))
    $developVersion = getPossibleNextVersion $developVersion (rollUpToNextMajor($latest))


    $tagSuffix = "beta";

    if ($integrationName.Length) {
        $tagSuffix = "beta-$integrationName"
    }
    

    $specific = (getTags(specificVersion $developVersion.major $developVersion.minor $tagSuffix) |select -First 1)
    if ($specific) {
        $developVersion = $specific
    }
    $developVersion = incrementRevision $developVersion;
    return $developVersion;
}

function determineLatest($release, $master){
    $releaseBase = New-Object System.Version($release.major, $release.minor, $release.patch, 0)
    if($master -ge $releaseBase){
        return $master;
    }
    return $release;
}

function findReleaseVersion($major, $minor) {
    $releaseVersion = (getTags(specificVersion $major $minor "rc") | select -First 1)
    $masterVersion = (getTags(specificVersion $major $minor) | select -First 1)
    $releaseVersion = determineLatest $releaseVersion $masterVersion;
    if ($releaseVersion -and $releaseVersion.Revision -eq 0 ) {
        #we got this from master
        $releaseVersion = incrementPatch($releaseVersion)
    }
    if (!$releaseVersion) {
        $releaseVersion = New-Object System.Version($major, $minor, 0, 0)
    }
    $releaseVersion = incrementRevision $releaseVersion;
    return $releaseVersion;
}


function getBranchType($branch) {
    if ($branch -eq "refs/heads/master") {
        return "master";
    }
    if ($branch -eq "refs/heads/develop") {
        return "develop"
    }

    if ($branch -match $rcBranchExpression) {
        return "rc"
    }

    if ($branch -match $releaseBranchExpression) {
        return "release"
    }

    if ($branch -match $integrationBranchExpression) {
        return "integration"
    }
}

function outputVersion($version, $branchType, $integrationName) {
    $versionJson = @{
        Major              = $($version.major);
        Minor              = $($version.minor);
        Patch              = $($version.build);
        LegacySemVer       = '';
        AssemblySemVer     = '';
        LegacySemVerPadded = '';
    }
    if ($branchType -eq "develop") {
        $versionJson.LegacySemVer = "$($version.major).$($version.minor).$($version.build)-beta$($version.revision)"
        $versionJson.AssemblySemVer = "$($version.major).$($version.minor).$($version.build).$($version.revision)"
        $versionJson.LegacySemVerPadded = "$($version.major).$($version.minor).$($version.build)-beta" + "$($version.revision)".PadLeft(4, '0')
    }
    if ($branchType -eq "integration") {
        $versionJson.LegacySemVer = "$($version.major).$($version.minor).$($version.build)-beta-$integrationName$($version.revision)"
        $versionJson.AssemblySemVer = "$($version.major).$($version.minor).$($version.build).$($version.revision)"
        $versionJson.LegacySemVerPadded = "$($version.major).$($version.minor).$($version.build)-beta-$integrationName" + "$($version.revision)".PadLeft(4, '0')
    }
    if ($branchType -eq "rc") {
         $versionJson.LegacySemVer = "$($version.major).$($version.minor).$($version.build)-rc-$integrationName$($version.revision)"
        $versionJson.AssemblySemVer = "$($version.major).$($version.minor).$($version.build).$($version.revision)"
        $versionJson.LegacySemVerPadded = "$($version.major).$($version.minor).$($version.build)-rc-$integrationName" + "$($version.revision)".PadLeft(4, '0')
    }
    if ($branchType -eq "release") {
        $versionJson.LegacySemVer = "$($version.major).$($version.minor).$($version.build)"
        $versionJson.AssemblySemVer = "$($version.major).$($version.minor).$($version.build).0"
        $versionJson.LegacySemVerPadded = "$($version.major).$($version.minor).$($version.build)"
    }
    if ($branchType -eq "master") {
        $versionJson.LegacySemVer = "$($version.major).$($version.minor).$($version.build)"
        $versionJson.AssemblySemVer = "$($version.major).$($version.minor).$($version.build).0"
        $versionJson.LegacySemVerPadded = "$($version.major).$($version.minor).$($version.build)"
    }
    return $versionJson
}

write-host "STARTED"
write-host $PWD
$currentBranch = (git symbolic-ref HEAD)
$currentBranchType = getBranchType $currentBranch;
$currentTagVersion = getCurrentTagVersion;

if ($currentTagVersion) {
    $integrationName = getIntegrationName $currentBranch
    $returnVar = outputVersion $currentTagVersion $currentBranchType $integrationName | ConvertTo-Json
    return $returnVar
}
elseIf ($currentBranchType -eq "master") {
    $returnVar = outputVersion (findMasterVersion) $currentBranchType | ConvertTo-Json
    return $returnVar   
}

elseIf ($currentBranchType -eq "develop" ) {
    $returnVar = outputVersion (findDevelopVersion) $currentBranchType | ConvertTo-Json
    return $returnVar
}

elseIf ($currentBranchType -eq "seed" ) {
    $returnVar = outputVersion (findDevelopVersion) $currentBranchType | ConvertTo-Json
    return $returnVar
}

elseIf (($currentBranchType -eq "integration") -or ($currentBranchType -eq "rc" )) {
    $integrationName = getIntegrationName $currentBranch
    $returnVar = outputVersion (findDevelopVersion $integrationName) $currentBranchType $integrationName | ConvertTo-Json
    return $returnVar
}

elseIf ($currentBranchType -eq "release") {
    $null = $currentBranch -match $releaseBranchExpression
    $major = $matches[1]
    $minor = $matches[2]
    $returnVar = outputVersion (findReleaseVersion $major $minor) $currentBranchType | ConvertTo-Json
    return $returnVar
}

else {
    Write-Host "You must be in master, develop, integration, seed, rc, or release branches to run GitVersion"
}