PROGRAM SEGMENT
	ASSUME CS:PROGRAM, DS:PROGRAM, ES:NOTHING, SS:NOTHING
	ORG 100h

; Точка входа
START:
	jmp BEGIN

AVAILABLE_MEMORY_SIZE_MESSAGE DB "The size of the available memory: $"
AVAILABLE_MEMORY_SIZE DB "     kilobytes      bytes", 0Dh, 0Ah, "$"
EXTENDED_MEMORY_SIZE_MESSAGE DB "The size of the extended memory: $"
EXTENDED_MEMORY_SIZE DB "      kilobytes", 0Dh, 0Ah, "$"
MCB_ADDRESS_MESSAGE DB 0Dh, 0Ah, "MCB address: $"
MCB_ADDRESS DB "    ", 0Dh, 0Ah, "$"
MCB_TYPE_MESSAGE DB "MCB type: $"
MCB_TYPE DB "  ", 0Dh, 0Ah, "$"
MEMORY_BLOCK_OWNER_MESSAGE DB "Block owner: $"
MEMORY_BLOCK_OWNER DB "    ", 0Dh, 0Ah, "$"
MEMORY_BLOCK_OWNER_1 DB "Free", 0Dh, 0Ah, "$"
MEMORY_BLOCK_OWNER_2 DB "OS XMS UMB driver", 0Dh, 0Ah, "$"
MEMORY_BLOCK_OWNER_3 DB "Excluded upper driver memory", 0Dh, 0Ah, "$"
MEMORY_BLOCK_OWNER_4 DB "MS DOS", 0Dh, 0Ah, "$"
MEMORY_BLOCK_OWNER_5 DB "386MAX UMB control block", 0Dh, 0Ah, "$"
MEMORY_BLOCK_OWNER_6 DB "386MAX blocked", 0Dh, 0Ah, "$"
MEMORY_BLOCK_OWNER_7 DB "386MAX UMB", 0Dh, 0Ah, "$"
BLOCK_SIZE_MESSAGE DB "Block size: $"
BLOCK_SIZE DB "     kilobytes      bytes", 0Dh, 0Ah, "$"
RESERVED_MESSAGE DB "Reserved: $"
RESERVED DB "           ", 0Dh, 0Ah, "$"
ERROR_MESSAGE DB "Error! Code:   ", 0Dh, 0Ah, "$"

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

; Перевод слова AX в 10-ичную СС и его представление в виде символов
WORD_TO_DEC PROC NEAR
	push cx
	push dx
	xor dx, dx
	mov cx, 10
loop_bd_2:
	div cx
	or dl, 30h
	mov [si], dl
	dec si
	xor dx, dx
	cmp ax, 10
	jae loop_bd_2
	cmp al, 00h
	je end_l_2
	or al, 30h
	mov [si], al
end_l_2:
	pop dx
	pop cx
	ret
WORD_TO_DEC ENDP

; Вызывает функцию вывода строки на экран
PRINT PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP

; Очистить поле размера MCB блока
CLEAR_BLOCK_SIZE PROC NEAR
	push cx
	push si
	
	mov cx, 4
loop_start:
	mov si, cx
	mov [BLOCK_SIZE + si + 15], ' '
	mov [BLOCK_SIZE + si], ' '
	loop loop_start
	
	pop si
	pop cx
	
	ret
CLEAR_BLOCK_SIZE ENDP

; Вывести размер доступной памяти
PRINT_AVAILABLE_MEMORY_SIZE PROC NEAR
	push ax
	push bx
	push cx
	push dx
	push si

	mov ah, 4Ah
 	mov bx, 0FFFFh
 	int 21h
	
	mov ax, bx
	and bx, 0111111b
	mov cl, 6
	shr ax, cl
	mov cl, 4
	shl bx, cl
	mov si, offset AVAILABLE_MEMORY_SIZE + 3
	call WORD_TO_DEC
	mov ax, bx
	mov si, offset AVAILABLE_MEMORY_SIZE + 18
	call WORD_TO_DEC

	mov dx, offset AVAILABLE_MEMORY_SIZE_MESSAGE
	call PRINT
	mov dx, offset AVAILABLE_MEMORY_SIZE
	call PRINT

	pop si
	pop dx
	pop cx
	pop bx
	pop ax

 	ret
PRINT_AVAILABLE_MEMORY_SIZE ENDP

; Вывести размер расширенной памяти
PRINT_EXTENDED_MEMORY_SIZE PROC NEAR
	push ax
	push bx
	push cx
	push dx
	push si

	mov al, 30h
	out 70h, al
	in al, 71h
	mov bl, al
	mov al, 31h
	out 70h, al
	in al, 71h
	mov ah, al
	mov al, bl

	mov si, offset EXTENDED_MEMORY_SIZE + 4
	call WORD_TO_DEC

	mov dx, offset EXTENDED_MEMORY_SIZE_MESSAGE
	call PRINT
	mov dx, offset EXTENDED_MEMORY_SIZE
	call PRINT
	
	pop si
	pop dx
	pop cx
	pop bx
	pop ax

	ret
PRINT_EXTENDED_MEMORY_SIZE ENDP

; Вывести список MCB
PRINT_MCB_LIST PROC NEAR
	push ax
	push bx
	push dx
	push es
	
	mov ah, 52h
	int 21h
	call CHECK_AND_PRINT_ERROR
	
	mov ax, es:[bx-2]
	mov es, ax

read_block:
	call READ_AND_PRINT_MCB

	mov al, es:[0]
	mov bx, es
	mov dx, es:[3]
	add dx, 1
	add bx, dx
	mov es, bx
	
	cmp al, 4Dh
	je read_block

	pop es
	pop dx
	pop bx
	pop ax

	ret
PRINT_MCB_LIST ENDP

; Вывести MCB на экран
READ_AND_PRINT_MCB PROC NEAR
	push ax
	push cx
	push dx
	push di
	push si

	mov ax, es
	mov di, offset MCB_ADDRESS + 3
	call WORD_TO_HEX

	mov dx, offset MCB_ADDRESS_MESSAGE
	call PRINT
	mov dx, offset MCB_ADDRESS
	call PRINT

	xor ah, ah
	mov al, es:[0]
	call BYTE_TO_HEX
	mov ds:[MCB_TYPE], al
	mov ds:[MCB_TYPE+1], ah

 	mov dx, offset MCB_TYPE_MESSAGE
	call PRINT
	mov dx, offset MCB_TYPE
	call PRINT

	mov dx, offset MEMORY_BLOCK_OWNER_MESSAGE
	call PRINT

	mov ax, es:[1]
	cmp ax, 0000h
	je owner1
	cmp ax, 0006h
	je owner2
	cmp ax, 0007h
	je owner3
	cmp ax, 0008h
	je owner4
	cmp ax, 0FFFAh
	je owner5
	cmp ax, 0FFFDh
	je owner6
	cmp ax, 0FFFEh
	je owner7
	jmp owner_default
owner1:
	mov dx, offset MEMORY_BLOCK_OWNER_1
	jmp print_owner
owner2:
	mov dx, offset MEMORY_BLOCK_OWNER_2
	jmp print_owner
owner3:
	mov dx, offset MEMORY_BLOCK_OWNER_3
	jmp print_owner
owner4:
	mov dx, offset MEMORY_BLOCK_OWNER_4
	jmp print_owner
owner5:
	mov dx, offset MEMORY_BLOCK_OWNER_5
	jmp print_owner
owner6:
	mov dx, offset MEMORY_BLOCK_OWNER_6
	jmp print_owner
owner7:
	mov dx, offset MEMORY_BLOCK_OWNER_7
	jmp print_owner
owner_default:
	mov di, offset MEMORY_BLOCK_OWNER + 3
	call WORD_TO_HEX
	mov dx, offset MEMORY_BLOCK_OWNER

print_owner:
	call PRINT

	mov ax, es:[3]
	mov bx, ax
	and bx, 0111111b
	mov cl, 6
	shr ax, cl
	mov cl, 4
	shl bx, cl
	mov si, offset BLOCK_SIZE + 3
	call WORD_TO_DEC
	mov ax, bx
	mov si, offset BLOCK_SIZE + 18
	call WORD_TO_DEC
	
	mov dx, offset BLOCK_SIZE_MESSAGE
	call PRINT
	mov dx, offset BLOCK_SIZE
	call PRINT
	
	call CLEAR_BLOCK_SIZE

	mov si, offset RESERVED
	mov di, 5
	mov cx, 11

read_reserved_bytes:
	mov al, es:[di]
	mov byte ptr ds:[si], al

	add si, 1
	add di, 1
	loop read_reserved_bytes

	mov dx, offset RESERVED_MESSAGE
	call PRINT
	mov dx, offset RESERVED
	call PRINT

	pop si
	pop di
	pop dx
	pop cx
	pop ax

	ret
READ_AND_PRINT_MCB ENDP

; Выводит ошибку на экран и выходит из программы
CHECK_AND_PRINT_ERROR PROC NEAR
	push ax
	
	lahf
	and ah, 01b
	cmp ah, 0
	je no_error
	
	pop ax
	mov si, offset ERROR_MESSAGE + 14
	call WORD_TO_DEC
	
	mov dx, offset ERROR_MESSAGE
	call PRINT
	
	xor al, al
	mov ah, 4Ch
	int 21h
	
no_error:
	pop ax 
	ret
CHECK_AND_PRINT_ERROR ENDP

; Освобождает свободную память
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

; Выделяет для программы 64 КБ памяти
ALLOC_MEMORY PROC NEAR
	push ax
	push bx
	
	mov ah, 48h
 	mov bx, 1000h
 	int 21h
	call CHECK_AND_PRINT_ERROR
	
	pop bx
	pop ax
	
	ret
ALLOC_MEMORY ENDP

BEGIN:
	call PRINT_AVAILABLE_MEMORY_SIZE
	call PRINT_EXTENDED_MEMORY_SIZE
	call ALLOC_MEMORY
	call FREE_MEMORY
	call PRINT_MCB_LIST

EXIT:
	xor al, al
	mov ah, 4Ch
	int 21h
	
PROGRAM ENDS

END START