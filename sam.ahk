#NoEnv
#SingleInstance force
#Persistent
#InstallKeybdHook
 
SetWorkingDir, %A_ScriptDir%
 
Return
 
; ------------------------------------------------------------------------------
 
CapsLock & j::Send, {Left}
CapsLock & k::Send, {Down}
CapsLock & i::Send, {Up}
CapsLock & l::Send, {Right}
 
; ------------------------------------------------------------------------------
; EOF