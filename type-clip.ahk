#NoEnv                      ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance FORCE       ; Skip invocation dialog box and silently replace previously executing instance of this script.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#InstallKeybdHook
#Persistent

; LCtrl + LAlt + LWin + v
<^<!<#v::
  Sleep, 100 ; Maybe helps with the first character sometimes not being sent
  Send, {Text}%Clipboard%

; EOF
