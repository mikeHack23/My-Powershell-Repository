function Test-ScriptCopRule
{
    [CmdletBinding(DefaultParameterSetName='TestCommandInfo')]
    param(
    [Parameter(ParameterSetName='TestCommandInfo',Mandatory=$true,ValueFromPipeline=$true)]
    [Management.Automation.CommandInfo]
    $CommandInfo
    )
    
    process {
        <# 
        
        Only 3 types of commands can possibly be ScriptCopRules:
        
        - FunctionInfo
        - CmdletInfo
        - ExternalScriptInfo
        
        #>
        
        
        if ($CommandInfo -isnot [Management.Automation.FunctionInfo] -and
            $CommandInfo -isnot [Management.Automation.CmdletInfo] -and
            $CommandInfo -isnot [Management.Automation.ExternalScriptInfo]
        ) {
            Write-Error "$CommandInfo is not a function, cmdlet, or script" 
            return        
        }
        
        
        <# 
        
        The parameter sets must have a specific name.  
        
        The commands may have more than one parameter set.
        
        
        These parameter sets indicate the command can find problems
        
        - TestCommandInfo
        - TestCmdletInfo
        - TestScriptInfo
        - TestFunctionInfo
        - TestApplicationInfo
        - TestModuleInfo
        - TestScriptToken
        - TestHelpContent
        
        These parameter sets indicate the command can fix problems
        
        - RepairScriptCop
        #>
        
        
        $parameterSetNames = 'TestCommandInfo','TestCmdletInfo','TestScriptInfo',
            'TestFunctionInfo','TestApplicationInfo','TestModuleInfo',
            'TestScriptToken','TestHelpContent'
            
        $matchingParameterSets = $CommandInfo.ParameterSets |
            Where-Object {
                $parameterSetNames -contains $_.Name
            }
            
        if (-not $matchingParameterSets) {
            $ofs = ", " 
            Write-Error "$CommandInfo could not be a script cop rule because it does not have any of the correct parameter sets:
$parameterSetNames
"            
            return
        }
        
        foreach ($matchingParameterSet in $matchingParameterSets) {
            switch ($matchingParameterSet.Name) 
            {
                TestCommandInfo {
                    $hasCommandParameter = $matchingParameterSet.Parameters | Where-Object {
                        $_.Name -eq 'CommandInfo' -and
                        $_.ParameterType -eq [Management.Automation.CommandInfo]
                    }
                    if (-not $hasCommandParameter) {
                        Write-Error 'The TestCommandInfo parameter set does not have a CommandInfo parameter, or it is not the correct type'
                        return
                    }
                }
                
                TestFunctionInfo {
                    $hasFunctionParameter = $matchingParameterSet.Parameters | Where-Object {
                        $_.Name -eq 'FunctionInfo' -and
                        $_.ParameterType -eq [Management.Automation.FunctionInfo]
                    }
                    if (-not $hasFunctionParameter) {
                        Write-Error 'The TestFunctionInfo parameter set does not have a FunctionInfo parameter, or it is not the correct type'
                        return
                    }
                }

                TestModuleInfo {
                    $hasModuleParameter = $matchingParameterSet.Parameters | Where-Object {
                        $_.Name -eq 'ModuleInfo' -and
                        $_.ParameterType -eq [Management.Automation.PSModuleInfo]
                    }
                    if (-not $hasModuleParameter) {
                        Write-Error 'The TestModuleInfo parameter set does not have a ModuleInfo parameter, or it is not the correct type'
                        return
                    }
                }

                TestCmdletInfo {
                    $hasCmdletParameter = $matchingParameterSet.Parameters | Where-Object {
                        $_.Name -eq 'CmdletInfo' -and
                        $_.ParameterType -eq [Management.Automation.CmdletInfo]
                    }
                    if (-not $hasCmdletParameter) {
                        Write-Error 'The TestCmdletInfo parameter set does not have a CmdletInfo parameter, or it is not the correct type'
                        return
                    }
                }
                
                TestApplicationInfo {
                    $hasApplicationParameter = $matchingParameterSet.Parameters | Where-Object {
                        $_.Name -eq 'ApplicationInfo' -and
                        $_.ParameterType -eq [Management.Automation.ApplicationInfo]
                    }
                    if (-not $hasApplicationParameter) {
                        Write-Error 'The TestApplicationInfo parameter set does not have a ApplicationInfo parameter, or it is not the correct type'
                        return
                    }
                }

                TestScriptInfo {
                    $hasScriptParameter = $matchingParameterSet.Parameters | Where-Object {
                        $_.Name -eq 'ScriptInfo' -and
                        $_.ParameterType -eq [Management.Automation.ExternalScriptInfo]
                    }
                    if (-not $hasScriptParameter) {
                        Write-Error 'The TestScriptInfo parameter set does not have a ScriptInfo parameter, or it is not the correct type'
                        return
                    }
                }

                TestHelpContent {
                    $hasScriptParameter = $matchingParameterSet.Parameters | Where-Object {
                        $_.Name -eq 'HelpContent'
                    }
                    if (-not $hasScriptParameter) {
                        Write-Error 'The TestHelpContent parameter set does not have a HelpContent parameter, or it is not the correct type'
                        return
                    }
                }

                TestScriptToken {
                    $hasCommandParameter = $matchingParameterSet.Parameters | Where-Object {
                        $_.Name -eq 'ScriptToken' -and
                        $_.ParameterType -eq [Management.Automation.PSToken[]]
                    }
                    if (-not $hasCommandParameter) {
                        Write-Error 'The TestScriptToken parameter set does not have a ScriptToken parameter, or it is not the correct type'
                        return
                    }
                }            
            }
        }
    }
} 

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUyso7Pt9iJp9d7LvJqhBCFu8O
# d4SgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFHhq9qD2f+pXt8Z0
# t9lzSbkQNp1SMA0GCSqGSIb3DQEBAQUABIIBAGzi/hU5UNkp0KEwIOLpVmiD/PLe
# I0jMoEiacWyNJjKnckwocD1L2kADFz7NQFWrbrzmSLWW/aVD5JVKHKYL5rzsEOAB
# ESORcR9hgIn9pHfOFeM968aSt3YT9M8RSOA8HJOhLO46o2IDRZmBVLXVg5k2H7nR
# Hzcz2Vonam4QwBEZqiFQ8vwrb8fhyEctpYGNLLrFnDAT2DgLpHC6MoARWGw1GaFk
# xqIMZNheyPLl7AbFaWmkRlesdcFd7Jg5JwpLKk6D6jvMStjvZ5QwLPEYXq0qxbPn
# Wt7dYKZ1exl66nAZsaIYTsv1Fy9NrrUx0y6BjUFb8FBowECao2RVP1AgJFg=
# SIG # End signature block
