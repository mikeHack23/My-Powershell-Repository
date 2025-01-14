function Add-UIModule {
    #.Synopsis
    #   Generate a Module with commands for creating UI Elements
    #.Description
    #   Generate a PowerShell Module from one or more assemblies (or types)
    [CmdletBinding()]
    param(
    # The Path to an assembly to generate a UIModule for
    [Parameter(ParameterSetName='Path', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('PSPath')]
    [string[]]
    $Path,        
    # The name of a GAC assembly to generate a UI module for
    [Parameter(ParameterSetName='Assembly', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('AN')]
    [string[]]
    $AssemblyName,    
    # The full name(s) of one or more types to generate into a UI module
    [Parameter(ParameterSetName='Type', Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [Type[]]
    $Type,
    # A whitelist for types that you want to generate cmdlets for *in addition* to types that pass Select-UIType
    [Parameter()]
    [String[]]
    $TypeNameWhiteList,
    # A blacklist for types that you do not want to generate cmdlets for even if they pass Select-UIType
    [Parameter()]
    [String[]]
    $TypeNameBlackList,
    # The name of the module to create (either a simple name, or a full path to the psd1)
    [string]
    $Name,
    # Additional assemblies (assembly names, or full paths) that are required as references for the module
    [string[]]
    $RequiredAssemblies,
    # Generate CSharp Cmdlets instead of script functions
    [switch]
    $AsCmdlet,
    # If set, don't generate the psd1 metadata file
    [switch]
    $AssemblyOnly,
    # Override the default placement of the source code output
    [string]
    $SourceCodePath,
    # Import the module after generating it
    [switch]
    $Import,
    # Output the module info after generating it
    [switch]
    $Passthru,
    # A scriptblock to run whenever the module is imported
    [ScriptBlock]
    $On_ImportModule,
    # A scriptblock to run whenever the module is removed
    [ScriptBlock]
    $On_RemoveModule,
    # The Write-Progress id for nesting with other calls to Write-Progress
    [Int]
    $ProgressId = $(Get-Random),
    # The Write-Progress parent id for nesting with other calls to Write-Progress
    [Int]
    $ProgressParentId = -1
    )
    begin {
        $typeCounter = 0
        $ConstructorCmdletNames = New-Object Collections.Generic.List[String]
        $resultList = New-Object Collections.Generic.List[String]
    }
    process {
        if ($psCmdlet.ParameterSetName -eq 'Type') {
            $filteredTypes = $type
        } else {
            for($p=0;$p -lt $Path.Count;$p++){
                $Path[$p] = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath(($Path[$p]))
            }
            $RequiredAssemblies += @($Path) + @($AssemblyName)
            Write-Progress "Filtering Types" " " -ParentId $ProgressParentId -Id $ProgressId
            $filteredTypes = Select-UIType -Path @($Path) -AssemblyName @($AssemblyName) -TypeNameWhiteList @($TypeNameWhiteList) -TypeNameBlackList @($TypeNameBlackList)
        }
        $ofs = [Environment]::NewLine
        $count = @($filteredTypes).Count
        foreach ($type in $filteredTypes) 
        {
            if (-not $type) { continue }
            if (-not $type.Fullname -and $type[0].fullName) {
                $t = $type[0]
            } else {
                $t = $type
            }
            
            $typeCounter++
            if($count -gt 1) {
                $perc = $typeCounter * 100/ $count 
                Write-Progress "Generating Code" $t.Fullname -PercentComplete $perc -Id $ProgressId -ParentId $ProgressParentId
            } else {
                Write-Progress "Generating Code" $t.Fullname -Id $ProgressId -ParentId $ProgressParentId
            }
            $typeCode = ConvertFrom-TypeToScriptCmdlet -Type $t -AsScript:(!$AsCmdlet) `
                        -ConstructorCmdletNames ([ref]$ConstructorCmdletNames)  -ErrorAction SilentlyContinue
            $null = $resultList.Add( "$typeCode" )
        }
    }
    end {
        Write-Progress "Code Generation Complete" " " -PercentComplete 100 -Id $ProgressId -ParentId $ProgressParentId

        $resultList = $resultList | Where-Object { $_ }
        $ConstructorCmdletNames = $ConstructorCmdletNames | Where-Object { $_ }
        $code = "$resultList"
        
        if ($name.Contains("\")) {
            # It's definitely a path
            $semiResolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Name)
            if ($semiResolved -like "*.psd1") {
                $moduleMetadataPath = $semiResolved
            } elseif ($semiResolved -like "*.psm1") {
                $moduleMetadataPath = $semiResolved.Replace(".psm1", ".psd1")
            } elseif ($semiResolved -like "*.dll") {
                $AssemblyPath = $SemiResolved
                $moduleMetadataPath = $semiResolved.replace(".dll",".psd1")
            } else {
                $leaf = Split-Path -Path $semiResolved -Leaf 
                $moduleMetadataPath = Join-Path $semiResolved "${leaf}.psd1" 
            }
            
        } elseif ($name -like "*.dll") {
            $moduleMetadataPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($name.replace(".dll",".psd1"))
        } elseif ($name -like "*.psd1") {
            $moduleMetadataPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($name)
        } elseif ($name -like ".psm1" ) {
            $moduleMetadataPath = $moduleMetadataPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($name.Replace(".psm1",".psd1"))
        } else {
            # It's just a name, figure out what the real manifest path will be
            $moduleMetadataPath = "$env:UserProfile\Documents\WindowsPowerShell\Modules\$Name\$Name.psd1"
        }
        
        $moduleroot = Split-Path $moduleMetadataPath
        
        if (-not (Test-Path $moduleroot)) {
            New-Item -ItemType Directory -Path $moduleRoot | Out-Null
        }
        
        $psm1Path = $moduleMetadataPath.Replace(".psd1", ".psm1")
           
        if ($AsCmdlet) {
            if(!$SourceCodePath) {
                $SourceCodePath = $moduleMetadataPath.Replace(".psd1","Commands.cs")
            }
            Set-Content -LiteralPath $SourceCodePath -Value $Code
            if(!$AssemblyPath) {
                $AssemblyPath = $moduleMetadataPath.Replace(".psd1","Commands.dll")
            }
        } else {
            $modulePath = $moduleMetadataPath.Replace(".psd1", ".psm1")
        }

        if(!$AssemblyOnly) {
    # Ok, build the module scaffolding
@"
@{
    ModuleVersion = '1.0'
    RequiredModules = 'ShowUI'
    RequiredAssemblies = '$($RequiredAssemblies -Join "','")'
    ModuleToProcess = '$psm1Path'
    GUID = '$([GUID]::NewGuid())' 
    $( if($AsCmdlet) { 
    "NestedModules = '$AssemblyPath'
    CmdletsToExport = "
    } else { "FunctionsToExport = " }
    )@('New-$($ConstructorCmdletNames -join ''',''New-' ) ' ) 
    AliasesToExport = @( '$($ConstructorCmdletNames -join ''',''')' )
}
"@ | 
            Set-Content -Path $moduleMetadataPath -Encoding Unicode
        }

        if(!$AssemblyOnly -or !$AsCmdlet) {
"
$On_ImportModule
$(
    if(!$AsCmdlet) {
        $code
    }
    if($On_RemoveModule) {"
`$myInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    $On_RemoveModule
}
"   }
    foreach($n in $ConstructorCmdletNames) {"
Set-Alias -Name $n -Value New-$n "
    }
)
Export-ModuleMember -Cmdlet * -Function * -Alias *
" | 
            Set-Content -Path $psm1Path -Encoding Unicode
    
        }
    
        if ($AsCmdlet) {
            #  if(!$RequiredAssemblies) {
                #  $RequiredAssemblies = 
                    #  [Reflection.Assembly]::Load("WindowsBase, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"),
                    #  [Reflection.Assembly]::Load("PresentationFramework, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"),
                    #  [Reflection.Assembly]::Load("PresentationCore, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35")
            #  }
            if($PSVersionTable.CLRVersion -ge "4.0") {
                $RequiredAssemblies += [Reflection.Assembly]::Load("System.Xaml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089"), 
                                       [Reflection.Assembly]::Load("System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
            }

        
            $AddTypeParameters = @{
                TypeDefinition       = $code
                IgnoreWarnings       = $true
                Language             = 'CSharpVersion3'
                ReferencedAssemblies = Get-AssemblyName -RequiredAssemblies $RequiredAssemblies -ExcludedAssemblies "MSCorLib","System","System.Core"
            }
            # If we're running in .Net 4, we shouldn't specify the Language, because it'll use CSharp4
            if ($PSVersionTable.ClrVersion.Major -ge 4) {
                $AddTypeParameters.Remove("Language")
            }
            # Check to see if the outputpath can be written to: we don't *have* to save it as a dll
            $TestPath = "$(Split-Path $AssemblyPath)\test.write"
            if (Set-Content $TestPath -Value "1" -ErrorAction SilentlyContinue -PassThru) {
                Remove-Item $TestPath -ErrorAction SilentlyContinue
                $AddTypeParameters.OutputAssembly = $AssemblyPath
            }
            Write-Debug "Type Parameters:`n$($addTypeParameters | Out-String)"
            Add-Type @addTypeParameters
        }

        if($Import) {
            Import-Module $moduleMetadataPath -Passthru:$Passthru
        } elseif($Passthru) {
            Get-Module $Name -ListAvailable
        }
    }    
} 

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUojmy14i+6foZXJcroz03P0J4
# VY6gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKc0LZQcRbrEaUxn
# Fvur2/8QUrVVMA0GCSqGSIb3DQEBAQUABIIBAD+6sGqDM+z3pkYWWeex0xqVY3qp
# B6K/YpSSZQ52fR3OzH+zvz07I5nTkajYGagTL58qRD2VwRsU2vJMzl3h2su1tt1k
# tzCygV4K452VbEcdgvFjt/I8tClaorMkWUanrraaQE3eyskfDJ2mm6DLt853AOJx
# HfeJrd1LkhLAGPtckcSEpyHg5NekFRJ1JAOCGai5fzS6Y2FRSV44VTa6hF89Obz2
# M9yjcL8c5rnXl62hRVibnZAplID0aAyufMZsEKkZvrKywAMeopF+1ni2jJh9Gm0K
# 0rxwVtU6takfqC9whGdzXjl+OY7WyXKro8PRFmwUqPmDHlUmMR58UzqFB6Y=
# SIG # End signature block
