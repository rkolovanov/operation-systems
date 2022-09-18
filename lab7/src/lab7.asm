.model small
.stack 100h

.data
	KEEP_PSP DW 0h
	PARAMETERS_BLOCK DD 0h 
	DTA_BUFFER DB 43 DUP(0)
	PATH DB 128 DUP(0)
	FREE_MEMORY_MESSAGE DB "Freeing up memory...", 0Dh, 0Ah, "$"
	START_OVERLAY1_MESSAGE DB "Starting the first overlay...", 0Dh, 0Ah, "$"
	START_OVERLAY2_MESSAGE DB "Starting the second overlay...", 0Dh, 0Ah, "$"
	ERROR_1_MESSAGE DB "Error! Code: 1. Invalid function number.", 0Dh, 0Ah, "$"
	ERROR_2_MESSAGE DB "Error! Code: 2. File not found.", 0Dh, 0Ah, "$"
	ERROR_3_MESSAGE DB "Error! Code: 3. Route not found.", 0Dh, 0Ah, "$"
	ERROR_4_MESSAGE DB "Error! Code: 4. Too many open files.", 0Dh, 0Ah, "$"
	ERROR_5_MESSAGE DB "Error! Code: 5. No access.", 0Dh, 0Ah, "$"
	ERROR_8_MESSAGE DB "Error! Code: 8. Not enough memory to execute the function.", 0Dh, 0Ah, "$"
	ERROR_10_MESSAGE DB "Error! Code: 10. Incorrect environment.", 0Dh, 0Ah, "$"
	UNKNOWN_ERROR_MESSAGE DB "Unknown error!", 0Dh, 0Ah, "$"
	
.code

; Загрузка и вызов оверлейного модуля
LOAD_AND_RUN_MODULE PROC NEAR
	push ax
	push bx
	push cx
	push dx
	push si
	push es
	
	mov dx, offset DTA_BUFFER
	mov ah, 1Ah
	int 21h
	
	mov cx, 0h
	mov dx, offset PATH
	mov ah, 4Eh
	int 21h
	call CHECK_AND_PRINT_ERROR
	
	mov si, offset DTA_BUFFER
	mov ax, DS:[si + 1Ch]
	mov bx, DS:[si + 1Ah]
	mov cl, 4
	shr bx, cl
	mov cl, 12
	shl ax, cl
	add bx, ax
	add bx, 1
	mov ah, 48h
	int 21h
	call CHECK_AND_PRINT_ERROR
	
	mov word ptr PARAMETERS_BLOCK, ax
	
	mov ax, @data
	mov es, ax
	mov bx, offset PARAMETERS_BLOCK
	mov ax, 4B03h 
	int 21h
	call CHECK_AND_PRINT_ERROR
	
	mov ax, word ptr PARAMETERS_BLOCK
	mov es, ax
	mov word ptr PARAMETERS_BLOCK, 0
	mov word ptr PARAMETERS_BLOCK + 2, ax
	call PARAMETERS_BLOCK
	
	mov ah, 49h
	int 21h
	
	pop es
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	
	ret
LOAD_AND_RUN_MODULE ENDP

; Формирование строки с путем до вызываемого модуля
SET_PATH_STRING PROC NEAR
	push ax
	push bx
	push si
	push di
	push ds
	push es
	push ax
	
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
	
	pop ax
	mov byte ptr ES:[di], 'O'
	mov byte ptr ES:[di + 1], 'V'
	mov byte ptr ES:[di + 2], 'E'
	mov byte ptr ES:[di + 3], 'R'
	mov byte ptr ES:[di + 4], 'L'
	mov byte ptr ES:[di + 5], 'A'
	mov byte ptr ES:[di + 6], 'Y'
	cmp ax, 2h
	je overlay2
overlay1:
	mov byte ptr ES:[di + 7], '1'
	jmp overlay_end
overlay2:
	mov byte ptr ES:[di + 7], '2'
overlay_end:
	mov byte ptr ES:[di + 8], '.'
	mov byte ptr ES:[di + 9], 'O'
	mov byte ptr ES:[di + 10], 'V'
	mov byte ptr ES:[di + 11], 'L'
	mov byte ptr ES:[di + 12], 0h
	
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
	cmp ax, 03h
	je error_code_3
	cmp ax, 04h
	je error_code_4
	cmp ax, 05h
	je error_code_5
	cmp ax, 08h
	je error_code_8
	cmp ax, 0Ah
	je error_code_10
	jmp unknown_error

error_code_1:
	mov dx, offset ERROR_1_MESSAGE
	jmp print_error
error_code_2:
	mov dx, offset ERROR_2_MESSAGE
	jmp print_error
error_code_3:
	mov dx, offset ERROR_3_MESSAGE
	jmp print_error
error_code_4:
	mov dx, offset ERROR_4_MESSAGE
	jmp print_error
error_code_5:
	mov dx, offset ERROR_5_MESSAGE
	jmp print_error
error_code_8:
	mov dx, offset ERROR_8_MESSAGE
	jmp print_error
error_code_10:
	mov dx, offset ERROR_10_MESSAGE
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
	
	mov dx, offset FREE_MEMORY_MESSAGE
	call PRINT
	
	call FREE_MEMORY
	
	mov dx, offset START_OVERLAY1_MESSAGE
	call PRINT
	
	mov ax, 1
	call SET_PATH_STRING
	
	call LOAD_AND_RUN_MODULE
	
	mov dx, offset START_OVERLAY2_MESSAGE
	call PRINT
	
	mov ax, 2
	call SET_PATH_STRING
	call LOAD_AND_RUN_MODULE

	xor al, al
	mov ah, 4Ch
	int 21h
	
END BEGIN