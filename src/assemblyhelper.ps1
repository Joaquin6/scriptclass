# Copyright 2019, Adam Edwards
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


function FindAssembly($assemblyRoot, $assemblyName, $platformSpec) {
    write-verbose "Looking for matching assembly for '$assemblyName' under path '$assemblyRoot' with platform '$platformSpec'"
    # For OS compatibility, canonicalize path separators below by replacing '\' with '/'
    $matchingAssemblyPaths = get-childitem -r $assemblyRoot -Filter $assemblyName | sort-object -descending lastwritetime | where {$components = $_.fullname.replace("\\", "/") -split "//"; $components[$components.length - 2] -eq $platformSpec }

    if ($matchingAssemblyPaths -eq $null -or $matchingAssemblyPaths.length -lt 1) {
        throw "Unable to find assembly '$assemblyName' under root directory '$assemblyRoot'. Please re-run the installation command for this application and retry."
    }

    $matchingAssemblyPaths | foreach { write-verbose "Found possible assembly match for '$assemblyName' in '$_'" }

    $matchingAssemblyPaths[0].fullname
}

function LoadAssemblyFromRoot($assemblyRoot, $assemblyName, $platformSpec) {
    $assemblyPath = FindAssembly $assemblyRoot $assemblyName $platformSpec
    write-verbose "Requested assembly '$assemblyName', loading assembly '$assemblyPath'"
    [System.Reflection.Assembly]::LoadFrom($assemblyPath) | Out-Null
}

function Import-Assembly($AssemblyName, $AssemblyRoot = $null, $TargetFrameworkMoniker = 'net45') {
    $searchRoot = if ( $assemblyRoot -ne $null ) {
        $assemblyRoot
    } else {
        split-path -parent (get-pscallstack)[1].scriptname
    }
    write-verbose "Using assembly root '$searchRoot'..."

    $assemblyNameParent = split-path -parent $assemblyName
    $assemblyFile = split-path -leaf $assemblyName
    $searchRootDirectory = join-path $searchRoot $assemblyNameParent
    $searchRootItem = get-item $searchRootDirectory 2>$null

    if ( $searchRootItem -eq $null ) {
        throw "Unable to find assembly '$assemblyName' because given search directory '$searchRootDirectory' was not accessible"
    }

    $searchRootFullyQualified = $searchRootItem.fullname

    write-verbose "Using fully qualified assembly root '$searchRootFullyQualified' to find assembly '$assemblyFile'..."

    LoadAssemblyFromRoot $searchRootFullyQualified  $assemblyFile $TargetFrameworkMoniker
}


