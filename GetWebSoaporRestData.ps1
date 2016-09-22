
<############################################################################################################################################
 New Features:
 
 Version 1.0
 Added paramater to use MSXML2.ServerXMLHTTP.6.0 or MSXML2.ServerXMLHTTP version. Because some Apache websites fails with XMLHTTP.6.0.
 The default it MSXML2.ServerXMLHTTP.6.0. Valid values will be as below
 $pMSXMLObjectName = MSXML2.ServerXMLHTTP.6.0  
 $pMSXMLObjectName = MSXML2.ServerXMLHTTP
 Added RunAsAccount paramater to be passed
 Condition : if the text to search is found then pState1 wins i.e. Healthy else pStart0 wins i.e. unhealthy
 Search text is not case sensitive.
 Added ignore certificate errors option.
#############################################################################################################################################>

Param 
(
[Parameter(Mandatory=$false)] [string]$pUsername,
[Parameter(Mandatory=$false)] [string]$pPassword,
[Parameter(Mandatory=$true)] [string]$pstrWebURL,
[Parameter(Mandatory=$false)] [string]$pstrXMLToSend,
[Parameter(Mandatory=$false)] [string]$pTextToCompare, 
[Parameter(Mandatory=$false)] [string]$pTextToSearch,
[Parameter(Mandatory=$false)] [string]$pstrProxyServerName,
[Parameter(Mandatory=$true)] [string]$pstrSOAPAction,
[Parameter(Mandatory=$true)] [string]$pState0,
[Parameter(Mandatory=$true)] [string]$pStrValue0,
[Parameter(Mandatory=$true)] [string]$pState1,
[Parameter(Mandatory=$true)] [string]$pStrValue1,
[Parameter(Mandatory=$false)] $pDebug,
[Parameter(Mandatory=$false)] [string]$pValueOfComObject,
[Parameter(Mandatory=$false)] [string]$pMSXMLObjectName = "MSXML2.ServerXMLHTTP.6.0"
)





Function GetWebPageStatus(
[Parameter(Mandatory=$false)] [string]$pUsername = "",
[Parameter(Mandatory=$false)] [string]$pPassword = "",
[Parameter(Mandatory=$true)] [string]$pstrWebURL,
[Parameter(Mandatory=$false)] [string]$pstrXMLToSend,
[Parameter(Mandatory=$false)] [string]$pTextToCompare, 
[Parameter(Mandatory=$false)] [string]$pTextToSearch,
[Parameter(Mandatory=$false)] [string]$pstrProxyServerName,
[Parameter(Mandatory=$true)] [string]$pstrSOAPAction,
[Parameter(Mandatory=$true)] [string]$pState0,
[Parameter(Mandatory=$true)] [string]$pStrValue0,
[Parameter(Mandatory=$true)] [string]$pState1,
[Parameter(Mandatory=$true)] [string]$pStrValue1,
[Parameter(Mandatory=$false)] $pDebug,
[Parameter(Mandatory=$false)] [string]$pValueOfComObject = "",
[Parameter(Mandatory=$false)] [string]$pMSXMLObjectName = ""
)
{

    #Create property bag data
    $API = New-Object -comObject 'MOM.ScriptAPI'
    $PropertyBag = $api.CreatePropertyBag()
    $strPSName = "$strPSName"
    $strReturnError = ""
    $strDesc = ""
    $newLine = "`n"
	$blnSiteError = $false

    if ($pDebug)
    {
            $api.LogScriptEvent("$strPSName",993,4," Starting script debugging....")
			$api.LogScriptEvent("$strPSName",993,4, "Condition Detection User Paramaters : ****State0=$pState0******Value0=$pStrValue0****State1=$pState1****Value1=$pStrValue1****"  )
            $api.LogScriptEvent("$strPSName",993,4," pstrUsername =" + $pUsername)
            $api.LogScriptEvent("$strPSName",993,4," pstrWebURL =" + $pstrWebURL)
            $api.LogScriptEvent("$strPSName",993,4," pstrXMLToSend =" + $pstrXMLToSend)
            $api.LogScriptEvent("$strPSName",993,4," pTextToCompare =" + $pTextToCompare)
            $api.LogScriptEvent("$strPSName",993,4," pTextToSearch =" + $pTextToSearch)
            $api.LogScriptEvent("$strPSName",993,4," pstrSOAPAction =" + $pstrSOAPAction)
            $api.LogScriptEvent("$strPSName",993,4," pstrXMLToSend to send\post =" + $pstrXMLToSend)
            $api.LogScriptEvent("$strPSName",993,4," pValueOfComObject=" + $pValueOfComObject)
            $api.LogScriptEvent("$strPSName",993,4," MSXMLHTTP Version or pMSXMLObjectName=" + $pMSXMLObjectName)
    }

    try
    {
        if ($pMSXMLObjectName -eq $null)
            { $objServerXMLHTTP = New-Object -ComObject Msxml2.ServerXMLHTTP.6.0 }
        else
            { $objServerXMLHTTP = New-Object -ComObject $pMSXMLObjectName }
             
             $OSVersion = Get-CimInstance Win32_OperatingSystem | Select-Object  Caption | ForEach{ $_.Caption }
             if ($OSVersion.Contains("Windows 7") -eq $false)
    		    { $objServerXMLHTTP.setOption(2, 13056) } #ignore certificate errors by default. The script will only works on servers and not for desktop. Alternatively comment this line if testing on your desktop VDI PS 
                
    }
    catch
    {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        if ($pMSXMLObjectName -eq $null)
        {
            $strDesc =  "Unable to create Msxml2.ServerXMLHTTP.6.0. Error: $ErrorMessage FailedItem:$FailedItem "
			$api.LogScriptEvent("$strPSName",993,4," Exception error running script=" + $strDesc)
        }
        else
        {
            $strDesc =  "Unable to create " + $pMSXMLObjectName + " Error: $ErrorMessage FailedItem:$FailedItem "
			$api.LogScriptEvent("$strPSName",993,4," Exception error running script=" + $strDesc)
        }
        $blnSiteError = $true
        #Break
    }

    try
    {
    
        if ($pstrProxyServerName.Length -gt 0)
        {
            $objServerXMLHTTP.setProxy(2, $pstrProxyServerName, "")
        }
        #if ($pUsername.Length -gt 0)
        #{
        #    $objServerXMLHTTP.setProxyCredentials($strUserName, $strPassword)
        #}

        if (($pUserName -eq $null) -and ($pPassword -eq $null)) 
        {
            $objServerXMLHTTP.open($pstrSOAPAction, $pstrWebURL, $false)    
        }
        else
        {
            $objServerXMLHTTP.open($pstrSOAPAction, $pstrWebURL, $false, $pUserName, $pPassword)
        }
        $objServerXMLHTTP.setRequestHeader("Content-type", "text/xml; charset=utf-8")
        $objServerXMLHTTP.setRequestHeader("Content-length", $XMLParameters.length)
        $objServerXMLHTTP.setRequestHeader("Connection", "close")
        $objServerXMLHTTP.send($pstrXMLToSend)
    }
    catch
    {
        if ($objServerXMLHTTP.status -eq 300)
        {
          # skip the error. Because we can access the website but the sent header is not valid or it empty.
        }
        else
        {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            if ($pMSXMLObjectName -eq $null)
            {
                $strDesc =  "Unable to create Msxml2.ServerXMLHTTP.6.0."
            }
            else
            {
                $strDesc =  "Unable to create " + $pMSXMLObjectName 
            }
            if ($blnSiteError = $true)
            {
                $strDesc =   "Error: $ErrorMessage FailedItem:$FailedItem for URL $pstrWebURL. Check if proxy server settings if applicable or check and run MSXMLHTTP verion with lower version." + $newLine  + $strDesc
            }
            else
            {
                $strDesc =  "Error: $ErrorMessage FailedItem:$FailedItem for URL $pstrWebURL. Check if proxy server settings if applicable or check and run MSXMLHTTP verion with lower version."
                 $blnSiteError = $true
            }
            if ($pDebug)
            {
    	    	$api.LogScriptEvent("$strPSName",993,4, "strDesc =" + $strDesc )
	        }    
            
           
            #Break
        }

    }
    

        $Status = $objServerXMLHTTP.status
        $StatusText = $objServerXMLHTTP.statusText

       
        # if $pValueOfSQLDataSet is not defined by the user then return the all result set as is
        if ($pValueOfComObject.Length -eq 0)
        {

            if ($blnSiteError = $true)
            {
                $strDesc = $strDesc +  $newLine + $objServerXMLHTTP | Out-String
            }
            else
            {
                $strDesc = $objServerXMLHTTP | Out-String
            }
            
                        
            if ($pDebug)
            {
	            $api.LogScriptEvent("$strPSName",993,4," pValueOfComObject to find is empty.")
			}
        }
        else
        {
            if ($blnSiteError = $true)
            {
                $strDesc = $strDesc +  $newLine +  (Invoke-Expression $pValueOfComObject | Out-String)
            }
            else
            {
                $strDesc =  Invoke-Expression $pValueOfComObject | Out-String
            }
                
			$strDesc = ($strDesc.ToUpper()).Trim()
            if ($pDebug)
            {
	            $api.LogScriptEvent("$strPSName",993,4," pValueOfComObject resloved to text =" +  (Invoke-Expression $pValueOfComObject | Out-String))
			}
        }

	 $pTextToCompare = $pTextToCompare.ToUpper()
     $pTextToSearch = $pTextToSearch.ToUpper()
	
	 if (($pTextToCompare -eq "NULL") -or  ($pTextToCompare -eq "NOTNULL"))
	 {
		$blnTextFound = $false
		 if (($pStrToCompare -eq "NULL") -and ($strDesc.Length -eq 0))
		 {
			$blnTextFound = $true
		 }
		 if (($pTextToCompare -eq "NOTNULL") -and ($strDesc.Length -gt 0))
		 {
			$blnTextFound = $true
		 }

	 }
	 else
	 {
        
		if ($pTextToSearch.Length -gt 0)
		{
            $ATextToSearch = $pTextToSearch.Split(",")


	        $blnTextFound = $false


            for ($lintRow = 0; $lintRow -lt $ATextToSearch.Count;$lintRow++)
    	    {
                if ($strDesc.Trim().Contains($ATextToSearch[$lintRow].ToUpper())    )
			        { $blnTextFound = $true}
            }
		}

	     if ($pTextToCompare.Length -gt 0)
		 {
            $ATextToCompare = $pTextToCompare.Split(",")
			$blnTextFound = $false

            for ($lintRow = 0; $lintRow -lt $ATextToCompare.Count;$lintRow++)
    	    {
    			if ($strDesc.Trim() -eq $ATextToCompare[0].ToUpper()) 
	    		{ $blnTextFound = $true}
            }

		}
	}
    if ($blnTextFound) 
    {
           	   $PropertyBag.AddValue("State0", $pState0)

				if ($pDebug)    {     $api.LogScriptEvent("$strPSName",993,4," Finally returned propertybag value for CD State0=$pState0")	}

				$strDesc = "The website returned : $strDesc  `n Found the alert strings $pTextToCompare $pTextToSearch"
    }
    else
    {
				$PropertyBag.AddValue("State0", $pState1)
				if ($pDebug)    {     $api.LogScriptEvent("$strPSName",993,4," Finally returned propertybag value for CD State0=$pState1")	}

				$strDesc = "The website returned : $strDesc  `n It did not match the expected return string $pTextToCompare $pTextToSearch"
    }
    $strDesc = $strDesc.ToUpper()

    $PropertyBag.AddValue("AlertDescription", "`n" +   $strDesc)
    if ($pDebug)
    {
	    $api.LogScriptEvent("$strPSName",993,4, "Finally the strDesc $strDesc")
	}    

    $PropertyBag

}


$pDebug = [System.Convert]::ToBoolean($pDebug)
$pState0 = $pState0.ToUpper()
$pState1 = $pState1.ToUpper()
$pStrValue0 = $pStrValue0.ToUpper()
$pStrValue1 = $pStrValue1.ToUpper()
GetWebPageStatus -pUsername $pUsername -pPassword $pPassword -pState0 $pState0 -pStrValue0 $pStrValue0 -pState1 $pState1 -pStrValue1 $pStrValue1 -pDebug $pDebug -pstrWebURL $pstrWebURL -pstrXMLToSend $pstrXMLToSend -pstrProxyServerName  $pstrProxyServerName -pTextToCompare $pTextToCompare  -pTextToSearch $pTextToSearch  -pstrSOAPAction $pstrSOAPAction  -pValueOfComObject $pValueOfComObject -pMSXMLObjectName $pMSXMLObjectName
