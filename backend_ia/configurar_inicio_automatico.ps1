# Crear acceso directo en la carpeta de Inicio de Windows para iniciar el backend silenciosamente
$WshShell = New-Object -ComObject WScript.Shell
$StartupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$ShortcutPath = Join-Path $StartupPath "FonoSaludBackend.lnk"

$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "c:\Users\David\Documents\app_fono\flutter_application_1\backend_ia\iniciar_servidor_silencioso.vbs"
$Shortcut.WorkingDirectory = "c:\Users\David\Documents\app_fono\flutter_application_1\backend_ia"
$Shortcut.Save()

Write-Host "¡Acceso directo de inicio automático creado con éxito en la carpeta de Inicio de Windows!" -ForegroundColor Green
