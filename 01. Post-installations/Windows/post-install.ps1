# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $Command = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList $Command
        Exit
 }
}

# Update Microsoft Store apps
Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod -MethodName UpdateScanMethod

winget install Microsoft.WindowsTerminal
winget install Microsoft.PowerShell
winget install Mozilla.Firefox
winget install TheDocumentFoundation.LibreOffice
winget install VideoLAN.VLC
winget install 7zip.7zip

#regedit /s .\favourites.reg
reg import .\favourites.reg
reg import .\show_file_extensions.reg

# Set default browser

#Set-ExecutionPolicy Restricted
