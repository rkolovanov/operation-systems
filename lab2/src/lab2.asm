PROGRAM SEGMENT
	ASSUME CS:PROGRAM, DS:PROGRAM, ES:NOTHING, SS:NOTHING
	ORG 100h

; Точка входа
START:
	jmp BEGIN

; Данные
INVALID_MEMORY_ADDRESS_MESSAGE DB 'Segment address of invalid memory: $'
INVALID_MEMORY_ADDRESS DB '    ', 0Dh, 0Ah, '$'
ENVIRONMENT_ADDRESS_MESSAGE DB 'Segment address of the environment: $'
ENVIRONMENT_ADDRESS DB '    ', 0Dh, 0Ah, '$'
COMMAND_PROMPT_TAIL_MESSAGE DB 'The tail command prompt:$'
ENVIRONMENT_AREA_CONTENT_MESSAGE DB 'Content of the environment area:', 0Dh, 0Ah, '$'
MODULE_PATH_MESSAGE DB 'Path of loaded module: $'
INFORMATION_STRING DB 256 DUP('$')

; Перевод тетрады (4-ех младших байтов AL) в 16-ичную СС и ее представление в виде символа
TETR_TO_HEX PROC NEAR
	and al, 0Fh
	cmp al, 09
	jbe next
	add al, 07
next:
	add al, 30h
	ret
TETR_TO_HEX ENDP

; Перевод байта AL в 16-ичную СС и его представление в виде символов
BYTE_TO_HEX PROC NEAR
	push cx
	mov ah, al
	call TETR_TO_HEX
	xchg al, ah
	mov cl, 4
	shr al, cl
	call TETR_TO_HEX
	pop cx
	ret
BYTE_TO_HEX ENDP

; Перевод слова AX в 16-ичную СС и его представление в виде символов
WORD_TO_HEX PROC NEAR
	push bx
	mov bh, ah
	call BYTE_TO_HEX
	mov [di], ah
	dec di
	mov [di], al
	dec di
	mov AL, bh
	call BYTE_TO_HEX
	mov [di], ah
	dec di
	mov [di], al
	pop bx
	ret
WORD_TO_HEX ENDP

; Вызывает функцию вывода строки на экран
PRINT PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP

; Вывод на экран сегментного адреса первого байта недоступной памяти
PRINT_INVALID_MEMORY_ADDRESS PROC NEAR
	mov ax, DS:[0002h]
	mov di, offset INVALID_MEMORY_ADDRESS + 3
	call WORD_TO_HEX
	mov dx, offset INVALID_MEMORY_ADDRESS_MESSAGE
	call PRINT
	mov dx, offset INVALID_MEMORY_ADDRESS
	call PRINT
	ret
PRINT_INVALID_MEMORY_ADDRESS ENDP

; Вывод на экран сегментного адреса среды, передаваемой программе
PRINT_ENVIRONMENT_ADDRESS PROC NEAR
	mov ax, DS:[002Ch]
	mov di, offset ENVIRONMENT_ADDRESS + 3
	call WORD_TO_HEX
	mov dx, offset ENVIRONMENT_ADDRESS_MESSAGE
	call PRINT
	mov dx, offset ENVIRONMENT_ADDRESS
	call PRINT
	ret
PRINT_ENVIRONMENT_ADDRESS ENDP

; Вывод на экран хвоста командной строки
PRINT_COMMAND_PROMPT_TAIL PROC NEAR
	mov si, 0081h
	mov di, offset INFORMATION_STRING
	mov cl, DS:[0080h]
	xor ch, ch
	rep movsb
	mov byte ptr [di], 0Dh
	mov byte ptr [di+1], 0Ah
	mov byte ptr [di+2], '$'
	mov dx, offset COMMAND_PROMPT_TAIL_MESSAGE
	call PRINT
	mov dx, offset INFORMATION_STRING
	call PRINT
	ret
PRINT_COMMAND_PROMPT_TAIL ENDP

; Вывод на экран содержимого области среды и путя загружаемого модуля
PRINT_ENVIRONMENT_AREA_CONTENT_AND_MODULE_PATH PROC NEAR
	mov ax, DS:[002Ch]
	mov ds, ax
	xor si, si
	mov di, offset INFORMATION_STRING
loop1_start:
	mov al, 09h
	stosb
	lodsb
	cmp al, 0h
	je loop1_end
	stosb
loop2_start:
	lodsb
	cmp al, 0h
	je loop2_end
	stosb
	jmp loop2_start
loop2_end:
	mov al, 0Ah
	stosb
	jmp loop1_start
loop1_end:
	mov byte ptr ES:[di], 0Dh
	mov byte ptr ES:[di+1], '$'
	mov bx, ds
	mov ax, es
	mov ds, ax
	mov dx, offset ENVIRONMENT_AREA_CONTENT_MESSAGE
	call PRINT
	mov dx, offset INFORMATION_STRING
	call PRINT
	mov di, offset INFORMATION_STRING
	mov ds, bx
	lodsb
	lodsb
loop3_start:
	lodsb
	cmp al, 0h
	je loop3_end
	stosb
	jmp loop3_start
loop3_end:
	mov byte ptr ES:[di], 0Ah
	mov byte ptr ES:[di+1], 0Dh
	mov byte ptr ES:[di+2], '$'
	mov ax, es
	mov ds, ax
	mov dx, offset MODULE_PATH_MESSAGE
	call PRINT
	mov dx, offset INFORMATION_STRING
	call PRINT
	ret
PRINT_ENVIRONMENT_AREA_CONTENT_AND_MODULE_PATH ENDP

BEGIN:
	call PRINT_INVALID_MEMORY_ADDRESS
	call PRINT_ENVIRONMENT_ADDRESS
	call PRINT_COMMAND_PROMPT_TAIL
	call PRINT_ENVIRONMENT_AREA_CONTENT_AND_MODULE_PATH
	xor al, al
	mov AH, 4Ch
	int 21H
	
PROGRAM ENDS

END START