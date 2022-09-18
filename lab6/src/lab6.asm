.model small
.stack 100h

.data
	KEEP_PSP DW 0h
	KEEP_SS DW 0h
	KEEP_SP DW 0h
	PARAMETERS_BLOCK 	DW 0h 
						DD 0h 
						DD 0h 
						DD 0h
	COMMAND_STRING DB 1h, 0Dh
	PATH DB 128 DUP(0)
	CALLED_MODULE_FINISH_MESSAGE DB "Called program ended with code "
	CALLED_MODULE_FINISH_CODE DB "  .", 0Dh, 0Ah, "$"
	CALLED_MODULE_FINISH_REASON_MESSAGE DB 0Dh, 0Ah, "Reason for called program termination: $"
	CALLED_MODULE_FINISH_REASON_0 DB "Normal termination.", 0Dh, 0Ah, "$"
	CALLED_MODULE_FINISH_REASON_1 DB "Termination by Ctrl-Break.", 0Dh, 0Ah, "$"
	CALLED_MODULE_FINISH_REASON_2 DB "Termination by device error.", 0Dh, 0Ah, "$"
	CALLED_MODULE_FINISH_REASON_3 DB "Termination by function 31h.", 0Dh, 0Ah, "$"
	CALLED_MODULE_FINISH_REASON_UNKNOWN DB "Unknown reason.", 0Dh, 0Ah, "$"
	ERROR_1_MESSAGE DB "Error! Code: 1. Invalid function number.", 0Dh, 0Ah, "$"
	ERROR_2_MESSAGE DB "Error! Code: 2. File not found.", 0Dh, 0Ah, "$"
	ERROR_5_MESSAGE DB "Error! Code: 5. Disk error.", 0Dh, 0Ah, "$"
	ERROR_7_MESSAGE DB "Error! Code: 7. Memory control block is destroyed.", 0Dh, 0Ah, "$"
	ERROR_8_MESSAGE DB "Error! Code: 8. Not enough memory to execute the function.", 0Dh, 0Ah, "$"
	ERROR_9_MESSAGE DB "Error! Code: 9. Invalid memory block address.", 0Dh, 0Ah, "$"
	ERROR_10_MESSAGE DB "Error! Code: 10. Incorrect environment string.", 0Dh, 0Ah, "$"
	ERROR_11_MESSAGE DB "Error! Code: 11. Invalid format.", 0Dh, 0Ah, "$"
	UNKNOWN_ERROR_MESSAGE DB "Unknown error!", 0Dh, 0Ah, "$"
	
.code
; Перевод байта AL в 10-ичную СС и его представление в виде символов
BYTE_TO_DEC PROC NEAR
	push cx
	push dx
	
	xor ah, ah
	xor dx, dx
	mov cx, 10
	
loop_bd:
	div cx
	or dl,30h
	mov [si], dl
	dec si
	xor dx, dx
	cmp ax, 10
	jae loop_bd
	cmp al, 00h
	je end_l
	or al, 30h
	mov [si], al
	
end_l:
	pop dx
	pop cx
	ret
BYTE_TO_DEC ENDP

; Загрузка и вызов дочернего модуля
LOAD_MODULE PROC NEAR
	push ax
	push bx
	push dx
	push si
	push ds
	push es
	
	mov KEEP_SP, sp
	mov KEEP_SS, ss
	
	mov ax, @data
	mov es, ax
	mov bx, offset PARAMETERS_BLOCK
	mov dx, offset PATH
	mov word ptr [bx + 2], offset COMMAND_STRING
	mov word ptr [bx + 4], ds
	
	mov ax, 4B00h 
	int 21h
	
	mov sp, KEEP_SP
	mov ss, KEEP_SS
	pop es
	pop ds
	
	call CHECK_AND_PRINT_ERROR
	
	mov ah, 4Dh
	int 21h 
	
	mov dx, offset CALLED_MODULE_FINISH_REASON_MESSAGE
	call PRINT
	
	cmp ah, 0
	je reason_0
	cmp ah, 1
	je reason_1
	cmp ah, 2
	je reason_2
	cmp ah, 3
	je reason_3
	jmp reason_unknown
	
reason_0:
	mov dx, offset CALLED_MODULE_FINISH_REASON_0
	call PRINT
	
	mov si, offset CALLED_MODULE_FINISH_CODE + 1
	call BYTE_TO_DEC
	mov dx, offset CALLED_MODULE_FINISH_MESSAGE

	jmp reason_print
reason_1:
	mov dx, offset CALLED_MODULE_FINISH_REASON_1
	jmp reason_print
reason_2:
	mov dx, offset CALLED_MODULE_FINISH_REASON_2
	jmp reason_print
reason_3:
	mov dx, offset CALLED_MODULE_FINISH_REASON_3
	jmp reason_print
reason_unknown:
	mov dx, offset CALLED_MODULE_FINISH_REASON_UNKNOWN

reason_print:
	call PRINT

	pop si
	pop dx
	pop bx
	pop ax
	
	ret
LOAD_MODULE ENDP

; Формирование строки с путем до вызываемого модуля
SET_PATH_STRING PROC NEAR
	push ax
	push bx
	push si
	push di
	push ds
	push es
	
	mov ax, ds
	mov es, ax
	mov ax, KEEP_PSP
	mov ds, ax
	mov ax, DS:[002Ch]
	mov ds, ax
	mov di, offset PATH
	
	xor si, si
	
loop_find_path_start:
	mov al, DS:[si]
	inc si
	cmp al, 0h
	jne loop_find_path_start
	mov al, DS:[si]
	cmp al, 0h
	jne loop_find_path_start
	jmp loop_find_path_end
	
loop_find_path_end:
	add si, 3h
	xor bx, bx
	push si
	
loop_find_end_path_1:
	mov al, DS:[si]
	cmp al, 0h
	je loop_find_end_path_2
	inc si
	inc bx
	jmp loop_find_end_path_1
	
loop_find_end_path_2:
	mov al, DS:[si]
	cmp al, '\'
	je loop_copy_path_start_1
	dec si
	dec bx
	jmp loop_find_end_path_2

loop_copy_path_start_1:
	inc bx
	pop si
loop_copy_path_start_2:
	mov al, DS:[si]
	mov ES:[di], al
	inc di
	inc si
	dec bx
	cmp bx, 0h
	jne loop_copy_path_start_2
	
	mov byte ptr ES:[di], 'L'
	mov byte ptr ES:[di + 1], 'A'
	mov byte ptr ES:[di + 2], 'B'
	mov byte ptr ES:[di + 3], '2'
	mov byte ptr ES:[di + 4], '.'
	mov byte ptr ES:[di + 5], 'C'
	mov byte ptr ES:[di + 6], 'O'
	mov byte ptr ES:[di + 7], 'M'
	mov byte ptr ES:[di + 8], 0h
	
	pop es
	pop ds
	pop di
	pop si
	pop bx
	pop ax
	
	ret
SET_PATH_STRING ENDP

; Проверка ошибок при вызове прерываний
CHECK_AND_PRINT_ERROR PROC NEAR
	push ax
	jnc check_error_exit
		
	cmp ax, 01h
	je error_code_1
	cmp ax, 02h
	je error_code_2
	cmp ax, 05h
	je error_code_5
	cmp ax, 07h
	je error_code_7
	cmp ax, 08h
	je error_code_8
	cmp ax, 09h
	je error_code_9
	cmp ax, 0Ah
	je error_code_10
	cmp ax, 0Bh
	je error_code_11
	jmp unknown_error

error_code_1:
	mov dx, offset ERROR_1_MESSAGE
	jmp print_error
error_code_2:
	mov dx, offset ERROR_2_MESSAGE
	jmp print_error
error_code_5:
	mov dx, offset ERROR_5_MESSAGE
	jmp print_error
error_code_7:
	mov dx, offset ERROR_7_MESSAGE
	jmp print_error
error_code_8:
	mov dx, offset ERROR_8_MESSAGE
	jmp print_error
error_code_9:
	mov dx, offset ERROR_9_MESSAGE
	jmp print_error
error_code_10:
	mov dx, offset ERROR_10_MESSAGE
	jmp print_error
error_code_11:
	mov dx, offset ERROR_11_MESSAGE
	jmp print_error
unknown_error:
	mov dx, offset UNKNOWN_ERROR_MESSAGE
	
print_error:
	call PRINT
	xor al, al
	mov ah, 4Ch
	int 21h
	
check_error_exit:
	pop ax 
	ret
CHECK_AND_PRINT_ERROR ENDP

; Очистка памяти
FREE_MEMORY PROC NEAR
	push ax
	push bx
	
	mov ah, 4Ah
 	mov bx, 100h
 	int 21h
	call CHECK_AND_PRINT_ERROR
	
	pop bx
	pop ax
	ret
FREE_MEMORY ENDP

; Печать строки
PRINT PROC NEAR
	push ax
	
	mov ah, 09h
	int 21h
	
	pop ax
	ret
PRINT ENDP


BEGIN:
	mov ax, @data
	mov ds, ax
	mov KEEP_PSP, es
	
	call FREE_MEMORY
	call SET_PATH_STRING
	call LOAD_MODULE

	xor al, al
	mov ah, 4Ch
	int 21h
	
END BEGIN