# This script can be used to runs a given SQL query and checks if the output returns any error flag. 
For example if you want to check if the SQL database application returns NULL that means some issue with the application 
or if you want to check if the SQL database application returns NOTNULL or more than n. rows that means some issue with the application  else application is working fine.
This scipt is useful for creating SCOM alerts for monitoring applications based on SQL query it can be Oracle or MS SQL dababase.
It returns Sucess or Failure (save in property bag) and can be used in SCOM MP or SCORCH runbook.
Again I have not documented the logic etc. But I will once I get some time :

# Version 1.1  Added ($strDesc.Length -eq 0) -or ($strDesc -eq $null) -or ($strDesc.Trim() -eq 0))
# Version 1.2  Added feature to allow NON-SQL 32bit ODBC connetion and query.
# Version 1.3  Added feature to allow NON-SQL 64bit ODBC connetion and query. Added username and password to connectionstring. Returns alert if ODBC or SQL syntax is not correct.
# Version 1.32 Added   code to replace query variables with override values 
# Version 1.4  Added   variable pStrValue2 and $pStrValue and pStrComareExpression1. e.g. "$strValue1 -eq $strValue2" . This will compare given variables
# Version 1.5. Added condition feature in pStrToCompare .\GetSQLQueryResult.ps1 -pConnectionString $pConnectionString  -pQuery $pQuery1  -pStrToCompare  '(($ValueofSQLDataSet -ge 0) -and ($ValueofSQLDataSet  -le 2))'  -pState0 "UNHEALTHY"  -pState1 "HEALTHY"     -pDebug "TRUE" -pUsername $pUserName  -pPassword $pPassword -pValueOfSQLDataSet ' $ds.Tables[0].Number_of_Files'   -pStrValue0 "NULL" -pStrValue1 "NULL"
#
#
#

Param 
(
[Parameter(Mandatory=$false)] [string]$pUsername,
[Parameter(Mandatory=$false)] [string]$pPassword,
[Parameter(Mandatory=$false)] [string]$pEventName,
[Parameter(Mandatory=$true)] [string]$pConnectionString,
[Parameter(Mandatory=$true)] [string]$pQuery,
[Parameter(Mandatory=$true)] [string]$pStrToCompare,
[Parameter(Mandatory=$true)] [string]$pState0,
[Parameter(Mandatory=$true)] [string]$pStrValue0,
[Parameter(Mandatory=$true)] [string]$pState1,
[Parameter(Mandatory=$true)] [string]$pStrValue1,
[Parameter(Mandatory=$false)] $pDebug,
[Parameter(Mandatory=$false)] $pODBC32bitDSN,
[Parameter(Mandatory=$false)] [string]$pValueOfSQLDataSet,
[Parameter(Mandatory=$false)] [string]$pStrValue2,
[Parameter(Mandatory=$false)] [string]$pstrCompareExpression1
)



#    Function GetSQLData ([string]$Username,[string]$Password,[string]$CuriumEventName,[string]$pConnectionString)
    Function GetSQLData (
    [Parameter(Mandatory=$false)] [string]$pUsername ,
    [Parameter(Mandatory=$false)] [string]$pPassword, 
    [Parameter(Mandatory=$false)] [string]$pEventName, 
    [Parameter(Mandatory=$true)] [string]$pConnectionString, 
    [Parameter(Mandatory=$true)] [string]$pQuery, 
    [Parameter(Mandatory=$true)] [string]$pStrToCompare, 
    [Parameter(Mandatory=$true)] [string]$pState0, 
    [Parameter(Mandatory=$true)] [string]$pStrValue0, 
    [Parameter(Mandatory=$true)] [string]$pState1, 
    [Parameter(Mandatory=$true)] [string]$pStrValue1, 
    [Parameter(Mandatory=$false)] [bool]$pDebug = $false,
    [Parameter(Mandatory=$false)] [bool]$pODBC32bitDSN = $false,
    [Parameter(Mandatory=$false)] [string]$pValueOfSQLDataSet = "",
    [Parameter(Mandatory=$false)] [string]$pStrValue2 = "",
    [Parameter(Mandatory=$false)] [string]$pstrCompareExpression1 = ""
    )
    {
        #Create Discovery Data
        $API = New-Object -comObject 'MOM.ScriptAPI'
    $strPSName = 'GetSQLQueryResults.ps1'
    $strDesc = ""
    $strQuery = $pQuery

    # replace query variables with override values 
    $strQuery = $strQuery.Replace("strValue0", $pStrValue0)
    $pstrToCompare = $pstrToCompare.Replace("ValueofSQLDataSet", "pValueofSQLDataSet")

    if ($pDebug)
    {
        $api.LogScriptEvent("$strPSName",993,4,"Started Monitoring Script GetSQLQueryResult. pConnectionString=$pConnectionString. pstrToCompare = $pstrToCompare pValueOfSQLDataSet = $pValueOfSQLDataSet")
		$api.LogScriptEvent("$strPSName",993,4, "Condition Detection User Paramaters : ****State0=$pState0******Value0=$pStrValue0****State1=$pState1****Value1=$pStrValue1****pstrValue2=$pstrValue2****")
    }


    # $pstrCompareExpression1 will resolve  in the monitor via overides to $strValue5 -eq $strValue1
    if ($pstrCompareExpression1.Length -gt 0)
    {
        if ($pDebug)
        {
            $api.LogScriptEvent("$strPSName",993,4,"Before processing StrComareExpression=$pstrCompareExpression1")

        }

        $pstrCompareExpression1 = $pstrCompareExpression1.Replace("strValue1", "pStrValue1")
        $pstrCompareExpression1 = $pstrCompareExpression1.Replace("strValue2", "pStrValue2")
        

        if ($pDebug)
        {
            $api.LogScriptEvent("$strPSName",993,4,"After processing strCompareExpression=$pstrCompareExpression1")
        }

        if ($pStrValue1.Contains("Target"))
        {
    		Try
	    	{
                if ((Invoke-Expression ($pstrCompareExpression1)) -eq $false)
                {
                    if ($pDebug)
                    {
                        $api.LogScriptEvent("$strPSName",993,4,"Exit script since strCompareExpression did not match.")
                     }
                     break
                }
                else
                {

                     if ($pDebug)
                    {
                        $api.LogScriptEvent("$strPSName",993,4,"Continue script since strCompareExpression was resolved and matched sucessfully.")
                     }
                        
                }

            }
            catch
            {
				$ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
			    $api.LogScriptEvent("$strPSName",993,4,"Error processing $pstrCompareExpression1. Check if the values are defined correctly. $ErrotMessage  $FailedItem")
                break
            }
        }
      }

    # use this variable to error lng only without showing password if any
    $l_Hide_Password_ConnectionString = $pConnectionString

    $PropertyBag = $api.CreatePropertyBag()

    # to debug 32 bit code seperately in PS Run DebugOnly_GetSQLQueryResult32bit.ps1
    if ($pODBC32bitDSN -eq $true)
    {
	    if ($pDebug)
		{
			$api.LogScriptEvent("$strPSName",993,4,"Starting script under 32 bit powershell for connection var = $l_Hide_Password_ConnectionString")
		}
		write-warning "Starting script under 32 bit powershell"

	    # if you want powershell 2.0, add -version 2 *before* -file parameter
	    echo  (join-path ($pshome -replace "system32", "syswow64") powershell.exe)
	    if ($pDebug)
		{
	        $api.LogScriptEvent("$strPSName",993,4, (join-path ($pshome -replace "system32", "syswow64") powershell.exe  ))
		}    
        #$StrDesc  = & (join-path ($pshome -replace "system32", "syswow64") powershell.exe) -file .\GetSQLQueryResult32bit.ps1  -pConnectionString $pConnectionString -pQuery $pQuery| Out-String
    
		$strDesc = (& (join-path ($pshome -replace "system32", "syswow64") powershell.exe) -command { 
		Try
		{
			$pConnectionString = $args[0]
			$strQuery = $args[1]
			$connection = New-Object System.Data.Odbc.OdbcConnection($pConnectionString)
			$connection.Open()
			$cmd = New-Object System.Data.odbc.OdbcCommand($strQuery, $connection)
			$da = New-Object System.Data.Odbc.OdbcDataAdapter($cmd)
			$ds = new-object System.Data.Dataset
			$intNrows = $da.Fill($ds)

            $ds.Tables[0]| Format-Table  -AutoSize | Out-String
            $ds

        }
		Catch
		{	
				$ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
#               $ErrorMessage
#               $FailedItem
			    $strDesc =  "ODBC32bit connection error for ConnectionString=$pConnectionString  SQLQuery= $strQuery Error: $ErrorMessage FailedItem:$FailedItem "
				# cant log to scom eventlog since in 32 bit not supported
		}

		write-host  $strDesc 
		} -args $pConnectionString , $pQuery, $pValueOfSQLDataSet)

	
        #write-warning "Powershell is now running in $env:PROCESSOR_ARCHITECTURE"
        #write-warning "Finally the desc is  $StrDesc "
    }
    else
    {
        #Check if the connectiong string is SQL connection strings else try as  ODBC connection. By default try SQL connection
        $lblnSQL = $true
        if (($pConnectionString.ToUpper().Contains("INTEGRATED"))  -OR ($pConnectionString.ToUpper().Contains("CATALOG")))
        {
            
        }
        else
        {
            $lblnSQL = $false
            # Also see if UserName and Password has been set by the user
            if (($pUsername.Length -gt 0)  -and ($pPassword.Length -gt 0))
            {
              $pConnectionString =  "$pConnectionString;uid=$pUsername;pwd=$pPassword"  
              $l_Hide_Password_ConnectionString =  "$l_Hide_Password_ConnectionString;uid=$pUsername;pwd=*********"  
            }
        }

        if ($lblnSQL)
        {
            $connection = new-object System.Data.SqlClient.SQLConnection($pConnectionString) 
        }
        else
        {
            $connection = New-Object System.Data.Odbc.OdbcConnection($pConnectionString)     
        }

        if ($pDebug)
        {    	
            $api.LogScriptEvent("$strPSName",993,4,"connection var = $l_Hide_Password_ConnectionString")
          	$api.LogScriptEvent("$strPSName",993,4,"SQL Query = $strQuery") }



            if ($lblnSQL)
            {
                #$cmd = new-object System.Data.SqlClient.SqlCommand($strQuery, $connection)
            }
            else
            {
            }
            Try
            {
                if ($lblnSQL)
                { 
                    $connection.Open()
                }
                else
                {
                    $connection.Open()
    			  
                }


            }
            Catch
            {
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                

                $strDesc = "SQL query connection error message:$ErrorMessage   FailedItem:$FailedItem  ConnectionString:$l_Hide_Password_ConnectionString Connection database datasouce:$connection.DataSource  Database=$connection.Database"
                
                if ($pDebug)
                {
                    $api.LogScriptEvent("$strPSName",993,4,$strDesc)
                }


	            $PropertyBag.AddValue("AlertDescription",  $strDesc)

	            $PropertyBag.AddValue("State0", "UNHEALTHY")
              
                if ($pDebug)    {     $api.LogScriptEvent("$strPSName",993,4," Finally returned propertybag value for CD State0=$pState0")	}

	            $PropertyBag
    
                Break
            }

       	    Try
            {
                 if ($lblnSQL)
                 { 
                    $command = New-Object System.Data.SQLClient.SQLCommand
                    $command.Connection = $connection
                    $command.CommandText = $strQuery
                    $da = New-Object System.Data.SqlClient.SqlDataAdapter $command
                    $ds = new-object System.Data.Dataset
                    $intNrows = $da.Fill($ds)
                 }
                 else
                 { 
                     $cmd = New-Object System.Data.odbc.OdbcCommand($strQuery, $connection)
                     $da = New-Object System.Data.Odbc.OdbcDataAdapter($cmd)
			         $ds = new-object System.Data.Dataset
			         $intNrows = $da.Fill($ds)
                 }
            }
            Catch
            {
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName

                $strDesc = "SQL query connection error message:$ErrorMessage   FailedItem:$FailedItem  ConnectionString:$l_Hide_Password_ConnectionString Connection database datasouce:$connection.DataSource  Database=$connection.Database"

                if ($pDebug)
                {
                        $api.LogScriptEvent("$strPSName",993,4,$strDesc)
                }
    
                
                $PropertyBag.AddValue("AlertDescription",  $strDesc)

	            $PropertyBag.AddValue("State0", "UNHEALTHY")

                if ($pDebug)    {     $api.LogScriptEvent("$strPSName",993,4," Finally returned propertybag value for CD State0=$pState0")	}
	            $PropertyBag
    
                Break
            }

            if ($pDebug)
            {
            	$api.LogScriptEvent("$strPSName",993,4,"connection var =$l_Hide_Password_ConnectionString")
                $api.LogScriptEvent("$strPSName",993,4,"connection database datasouce $connection.DataSource   Database=$connection.Database" )
            }


            $strDesc = ""
            if ($pDebug)
            {
                $api.LogScriptEvent("$strPSName",993,4,"Rows.Count=" + $ds.Tables[0].Rows.Count)
            }
    
            #for ($i = 0; $i -lt $ds.Tables[0].Rows.Count;$i++)
            #{
                #$ds.Tables[0].id[$i]
                #$ds.Tables[0].BusinessName[$i] 
                #$ds.Tables[0].max_good[$i]
                #$ds.Tables[0].max_bad[$i]

                #$strDesc = $strDesc  +    $ds.Tables[0].id[$i] + " " + $ds.Tables[0].BusinessName[$i]  + " " + $ds.Tables[0].max_good[$i] +  $ds.Tables[0].max_bad[$i] + " "
            #}

            # create array objects for storing 2 objects.
            $strDesc = @()

            $strDesc += $ds.Tables[0]| Format-Table  -AutoSize | Out-String
            $strDesc += $ds
    	    
    }

	if ($pDebug)
    {
	 $api.LogScriptEvent("$strPSName",993,4, "After running the sql connection cmd and query strDesc=$strDesc")
	}
    # if $pValueOfSQLDataSet is not defined by the user then return the all result set as is
    if ($pValueOfSQLDataSet.Length -eq 0)
    {
		if ($pDebug)
        {  
			$api.LogScriptEvent('GetSQLQueryResult.ps1',993,4," pValueOfSQLDataSet is not defined by the user so return all the result set as is=" + ($strDesc|out-string))
		}
        $strDesc = $strDesc[0]
    }
    else
    {
        if ($pDebug)
        {
             $api.LogScriptEvent("$strPSName",993,4," pValueOfSQLDataSet=" + $pValueOfSQLDataSet)
        }
        $strDesc =    Invoke-Expression $pValueOfSQLDataSet | Out-String
        $pValueofSQLDataSet = $strDesc 
    }
        if ($pDebug)
        {    	
    		$api.LogScriptEvent("$strPSName",993,4,"Finally the desc is $strDesc")
        }

    $PropertyBag.AddValue("AlertDescription", "`n" +   $strDesc)
    
    if ($pDebug)
    {
        $api.LogScriptEvent("$strPSName",993,4," [If 32bit then no data is returned] connection=" +  ($connection| Out-String))
        $api.LogScriptEvent("$strPSName",993,4,"[If 32bit then no data is returned] ds=" +  ($ds | Out-String))
        #$api.LogScriptEvent("$strPSName",993,4,"Ran command=" +  $da.SelectCommand.CommandText)
        $api.LogScriptEvent("$strPSName",993,4,"AlertDescription=$strDesc")
	}

	# read the user paramater to see what state the query is being expected, if its UnHealthyState then check if the SQL query result or number of records retuned somthing oor not.
	# if the query did not return anything that means its success else if it did than its an error heath state
	#if ($pState.ToUpper() -eq "UNHEALTHY")   
	#{
        # if string to find is null i.e. output is zero length 

        if ($pStrToCompare.ToUpper() -eq "NULL")   
        {
        if (($strDesc.Length -eq 0) -or ($strDesc -eq $null) -or ($strDesc.Trim() -eq 0))
            {
                $PropertyBag.AddValue("State0", $pState0)
                if ($pDebug)    {     $api.LogScriptEvent("$strPSName",993,4," Finally returned propertybag value for CD State0=$pState0")	}
            }
            else
            {
            	$PropertyBag.AddValue("State0", $pState1) 
                if ($pDebug)    {     $api.LogScriptEvent("$strPSName",993,4," Finally returned propertybag value for CD State0=$pState1")	}
            }
        }
        

        # if string to find is not-null i.e. output is not empty 
        if ($pStrToCompare.ToUpper() -eq "NOTNULL")	
        {
        if (($strDesc.Length -gt 0) -and ($strDesc.Trim() -ne 0))
            {
            	$PropertyBag.AddValue("State0", $pState0)
                if ($pDebug)    {     $api.LogScriptEvent("$strPSName",993,4," Finally returned propertybag value for CD State0=$pState0")	}
            }
            else
            {
                $PropertyBag.AddValue("State0", $pState1)
                if ($pDebug)    {     $api.LogScriptEvent("$strPSName",993,4," Finally returned propertybag value for CD State0=$pState1")	}
            }
        }

        # if string to find is exact match of the SQL result i.e. output is same as user paramater and if we do not need how many records are in the database etc.
        if (($pStrToCompare.ToUpper() -ne "NOTNULL") -and ($pStrToCompare.ToUpper() -ne "NULL"))
        {
			if (($strDesc -eq $pStrToCompare)  -or ((Invoke-Expression $pStrToCompare) -eq $true ) )
			{
                $PropertyBag.AddValue("State0", $pState0)
                if ($pDebug)    {     $api.LogScriptEvent("$strPSName",993,4," Finally returned propertybag value for CD State0=$pState0")	}
			}
			else
			{

            	$PropertyBag.AddValue("State0", $pState1)
                if ($pDebug)    {     $api.LogScriptEvent("$strPSName",993,4," Finally returned propertybag value for CD State0=$pState1")	}
			}
        }


    if ($pODBC32bitDSN -eq $false)
    {
        $connection.Close()
    }
    if ($pDebug)
    {
	 $api.LogScriptEvent("$strPSName",993,4, "Finally the strDesc $strDesc")
	}

    $PropertyBag

    }

    


Function IIf($If, $Right, $Wrong)
    {If ($If) {$Right} Else {$Wrong}}


#Create Discovery Data
#$API = New-Object -comObject 'MOM.ScriptAPI'
#$PropertyBag = $api.CreatePropertyBag()
#$strDesc = "This is just a  test mesg testing if PS has reached."
#$PropertyBag.AddValue("AlertDescription",  $strDesc)
#$PropertyBag


$pDebug = [System.Convert]::ToBoolean($pDebug)
$pODBC32bitDSN = [System.Convert]::ToBoolean($pODBC32bitDSN)
$pState0 = $pState0.ToUpper()
$pState1 = $pState1.ToUpper()
$pStrValue0 = $pStrValue0.ToUpper()
$pStrValue1 = $pStrValue1.ToUpper()


GetSQLData  -pUsername $pUsername -pPassword $pPassword -pConnectionString $pConnectionString   -pQuery $pQuery -pStrToCompare $pStrToCompare   -pState0 $pState0  -pStrValue0  $pStrValue0 -pState1 $pState1  -pStrValue1  $pStrValue1 -pDebug $pDebug -pODBC32bitDSN $pODBC32bitDSN  -pValueOfSQLDataSet  $pValueOfSQLDataSet  -pstrValue2 $pStrValue2 -pStrCompareExpression1 $pstrCompareExpression1

