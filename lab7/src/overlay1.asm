PROGRAM SEGMENT
	ASSUME CS:PROGRAM, DS:NOTHING, ES:NOTHING, SS:NOTHING
	
START:
	jmp BEGIN

SEGMENT_ADDRESS_MESSAGE DB "Overlay module 1. Segment address: $"
SEGMENT_ADDRESS DB "    ", 0Dh, 0Ah, "$"
	
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
	
BEGIN:
	push ax
	push dx
	push ds
	push di
	
	mov ax, cs
	mov ds, ax
	mov di, offset SEGMENT_ADDRESS + 3
	call WORD_TO_HEX
	mov dx, offset SEGMENT_ADDRESS_MESSAGE
	call PRINT
	mov dx, offset SEGMENT_ADDRESS
	call PRINT
	
	pop di
	pop ds
	pop dx
	pop ax
	
	retf
PROGRAM ENDS
END START