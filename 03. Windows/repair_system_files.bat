@echo off

:: Guide :
:: https://www.windowscentral.com/how-use-dism-command-line-utility-repair-windows-10-image

sfc /scannow
DISM /Online /Cleanup-Image /CheckHealth
DISM /Online /Cleanup-Image /ScanHealth
DISM /Online /Cleanup-Image /RestoreHealth
