;; ----------------------------------------------------------------------------
;; lowb
;;
;; This work is free. You can redistribute it and/or modify it under the
;; terms of the Do What The Fuck You Want To Public License, Version 2,
;; as published by Sam Hocevar. See the COPYING file for more details.
;;
;; 2017/10/02 - smattie <https://github.com/smattie>
;; ----------------------------------------------------------------------------

format ELF executable 3
entry start

define exit      1
define fork      2
define read      3
define open      5
define waitpid   7
define execve    11
define lseek     19
define nanosleep 162

define O_RDONLY 0
define SEEK_SET 0

define statFD ebp
define capFD  edi
define envp   esi

define SLEEPSEC 181

segment readable executable
start:
	mov  eax, [esp]
	xor  ebx, ebx
	inc  ebx
	cmp  eax, 2
	jl   theend

	lea  ebx, [esp + 8] ;; argv[1]
	lea  ecx, [esp + eax*4 + 8]
	sub  esp, 64
	mov  envp, ecx
	mov  [esp + 40], ebx

	mov  eax, open
	mov  ebx, statFile
	xor  ecx, ecx
	xor  edx, edx
	int  0x80
	mov  statFD, eax

	mov  eax, open
	mov  ebx, capFile
	int  0x80

	xor  ebx, ebx
	inc  ebx
	test eax, eax
	mov  capFD, eax
	js   theend

	mov  dword [esp + 0], SLEEPSEC
	mov  dword [esp + 4], 0

	mainloop:
	mov  eax, nanosleep
	mov  ebx, esp
	xor  ecx, ecx
	int  0x80

	mov  ebx, statFD
	lea  ecx, [esp + 8]
	mov  edx, 8
	call readfd

	movzx eax, byte [esp + 8]
	cmp  eax, 'C'
	je   mainloop

	mov  ebx, capFD
	call readfd

	cmp  eax, 2
	jg   mainloop

notify:
	mov  eax, fork
	xor  ebx, ebx
	int  0x80

	test eax, eax
	jz   child
	js   error

	parent:
	mov  ebx, eax
	xor  ecx, ecx
	xor  edx, edx
	mov  eax, waitpid
	int  0x80

	error:
	jmp  mainloop

	child:
	mov  eax, execve
	mov  ecx, [esp + 40] ;; argv
	mov  ebx, [ecx]      ;; argv[0]
	mov  edx, envp
	xor  esi, esi
	int  0x80

theend: ;; ebx status
	xor  eax, eax
	inc  eax
	int  0x80

readfd: ;; ebx fd, ecx dst, edx dstLen
	push edx
	push ecx

	mov  eax, lseek
	xor  ecx, ecx
	xor  edx, edx
	int  0x80

	mov  eax, read
	pop  ecx
	pop  edx
	int  0x80

	ret

segment readable
	capFile  db CAPACITYFILE, 0
	statFile db STATUSFILE, 0

;; vim: set ft=fasm:
