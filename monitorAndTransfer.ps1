$sources_destinations_path = "D:\TransferFileFromLocalToShareDrive\sources_destinations_path.txt"
#write start log file
Start-Transcript -Path "D:\TransferFileFromLocalToShareDrive\startLog.txt" 
$destinationPathMap = @{}
$share_drives_config = "D:\TransferFileFromLocalToShareDrive\share_drives_config.txt"

$share_drives = Get-Content $share_drives_config

# foreach for read share_drives_config and map drive 
$LineNumber =0
foreach ($content in $share_drives )  
{   $LineNumber++
    $Arr = $content.Split(',')
    $localDrive = $Arr[0] 
	$shareDrivePath = $Arr[1]
    $user = $Arr[2]
    $password_txt  = $Arr[3]
   
    # Check if have plaintext password from share_drives_config.txt
    if ($password_txt -ne "")
    {   
        # Read password(plaintext) to encrypt and replace old password with ",password_encrypt" on file share_drives_config.txt
        $password_encrypt =  $password_txt | convertto-securestring -asplaintext -force | convertfrom-securestring
        $Read = Get-Content -Path $config_share_drive
        $Read | ForEach-Object { if ($_.ReadCount -eq $LineNumber) { $_ -replace $password_txt,",${password_encrypt}"}   else { $_ } } | Set-Content $config_share_drive
        
      
    }else{
	 # read encrypt password
         $password_encrypt = $Arr[4]
         
    }
	#convert password_encrypt to secure string
    $pass = $password_encrypt | convertto-securestring

    # create a credential
    $credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist $user,$pass
    # Map to drive share drive with local drive from share_drives_config.txt
    New-PSDrive -Name $localDrive -PSProvider FileSystem -Root $shareDrivePath -Credential $credentials
   

}
 function global:copyFile {
  param($sourceFullPath,$destination)
  Copy-Item -Force -Verbose -Path $sourceFullPath -Destination $destination 
  }
 

function CopyFilesToFolder ($fromFolder, $toFolder) {
    $childItems = Get-ChildItem $fromFolder
    $childItems | ForEach-Object {
         $fileName =  $_
         Copy-Item -Path  $_.FullName -Destination $toFolder -Recurse -Force 
    }
}



# foreach for read source and destination folders path to register folder watcher read folder
$i=0 
$paths = Get-Content $sources_destinations_path
foreach ($path in $paths)  
{  
	$Arr = $path.Split(',')
	$sourcePath = $Arr[0]
    $sourceIdentifier = "$i+fileCreated"
    $destinationPathMap.Add( $sourceIdentifier,$Arr[1])
    $filter = '*.*'   
	$fsw = New-Object IO.FileSystemWatcher $sourcePath -Property @{IncludeSubdirectories = $false} 

    $action = { $fileName = $Event.SourceEventArgs.Name 
                $changeType = $Event.SourceEventArgs.ChangeType 
                $source = $Event.SourceEventArgs.FullPath 
                $timeStamp = $Event.TimeGenerated 
                $SI = $Event.SourceIdentifier
                $destination =  $destinationPathMap[$SI]
                $logline = "$(Get-Date), $changeType, $source, $destinationPath"
				global:copyFile $source $destination
             
              }    
    Register-ObjectEvent $fsw Created -SourceIdentifier $sourceIdentifier  -Action $action
   
    $i = $i+1 
}

 while ($true) {
 sleep 5
 }





