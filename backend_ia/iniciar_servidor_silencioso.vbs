Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = "c:\Users\David\Documents\app_fono\flutter_application_1\backend_ia"
WshShell.Run "python api_prediccion.py", 0, False
