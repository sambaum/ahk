#NoEnv                      ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn                     ; Enable warnings to assist with detecting common errors.
#SingleInstance FORCE       ; Skip invocation dialog box and silently replace previously executing instance of this script.
SendMode Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


;================================================================================================
;  CapsLock processing.  Must double tap CapsLock to toggle CapsLock mode on or off.
;================================================================================================
; Must double tap CapsLock to toggle CapsLock mode on or off.
CapsLock::
    KeyWait, CapsLock                                                   ; Wait forever until Capslock is released.
    KeyWait, CapsLock, D T0.2                                           ; ErrorLevel = 1 if CapsLock not down within 0.2 seconds.
    if ((ErrorLevel = 0) && (A_PriorKey = "CapsLock") )                 ; Is a double tap on CapsLock?
        {
        SetCapsLockState, % GetKeyState("CapsLock","T") ? "Off" : "On"  ; Toggle the state of CapsLock LED
        }
return


;================================================================================================
; Hot keys with CapsLock modifier.  See https://autohotkey.com/docs/Hotkeys.htm#combo
;================================================================================================

; Navigation
CapsLock & j::SendInput, {Left}
CapsLock & k::SendInput, {Down}
CapsLock & i::SendInput, {Up}
CapsLock & l::SendInput, {Right}

; Enpass
CapsLock & o::SendInput, ^!o
CapsLock & p::SendInput, ^+p
CapsLock & u::SendInput, ^+u

; Catch-all
CapsLock & a:: return
CapsLock & b:: return
CapsLock & c:: return
CapsLock & e:: return
CapsLock & f:: return
CapsLock & h:: return
CapsLock & m:: return
CapsLock & n:: return
CapsLock & q:: return
CapsLock & r:: return
CapsLock & s:: return
CapsLock & t:: return
CapsLock & w:: return
CapsLock & x:: return
CapsLock & y:: return
CapsLock & z:: return


;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++


;================================================================================================
; Other Hot keys
;================================================================================================
; Clip Board
CapsLock & v::SendInput, {Raw}%Clipboard%

; Alt esc
sc029::SendInput, {Escape}
