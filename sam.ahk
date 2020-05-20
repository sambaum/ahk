#NoEnv
#SingleInstance force
#Persistent
#InstallKeybdHook

SetWorkingDir, %A_ScriptDir%

Return

; https://www.autohotkey.com/docs_1.0/commands/Send.htm
; ------------------------------------------------------------------------------

; ^+v::Send, {Raw}%Clipboard% ; overlaps with outlook

; Navigation
CapsLock & j::SendInput, {Left}
CapsLock & k::SendInput, {Down}
CapsLock & i::SendInput, {Up}
CapsLock & l::Send, {Right}

; Enpass
CapsLock & o::SendInput, ^!o
CapsLock & p::SendInput, ^+p
CapsLock & u::SendInput, ^+u

; Alt esc
sc029::SendInput, {Escape}

; Toggle Capslock only on double tap
$CapsLock::
	KeyWait, CapsLock, T0.1
	
	if (ErrorLevel)
		;long, do nothing

	else {
		KeyWait, CapsLock, D T0.1

		if (ErrorLevel)
			; single, do nothing
			return
		
		else
			SetCapsLockState % !GetKeyState("CapsLock", "T")
	}

	KeyWait, CapsLock
return

; ------------------------------------------------------------------------------
; EOF
