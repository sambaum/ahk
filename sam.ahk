#NoEnv
#SingleInstance force
#Persistent
#InstallKeybdHook

SetWorkingDir, %A_ScriptDir%

Return

; https://www.autohotkey.com/docs_1.0/commands/Send.htm
; ------------------------------------------------------------------------------

; Navigation
CapsLock & j::SendInput, {Left}
CapsLock & k::SendInput, {Down}
CapsLock & i::SendInput, {Up}
CapsLock & l::SendInput, {Right}

; Enpass
CapsLock & o::SendInput, ^!o
CapsLock & p::SendInput, ^+p
CapsLock & u::SendInput, ^+u

; Clip Board
CapsLock & v::SendInput, {Raw}%Clipboard%

; Alt esc
sc029::SendInput, {Escape}

; Toggle Capslock only on double tap
;$CapsLock::
;	KeyWait, CapsLock, T0.1
;	if (ErrorLevel)
;		;long, do nothing
;		return
;	else {
;		KeyWait, CapsLock, D T0.1
;		if (ErrorLevel)
;			; single, do nothing
;			return
;		else
;			SetCapsLockState % !GetKeyState("CapsLock", "T")
;	}
;	KeyWait, CapsLock
;return

; ------------------------------------------------------------------------------
; EOF
