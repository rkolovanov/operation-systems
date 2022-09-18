PROGRAM SEGMENT

ASSUME CS:PROGRAM, DS:PROGRAM, ES:NOTHING, SS:NOTHING
ORG 100H

; Точка входа
START:
	jmp BEGIN

PC_TYPE_MESSAGE DB 'PC type: $'
PC_TYPE_1 DB 'PC', 0DH, 0AH, '$'
PC_TYPE_2 DB 'PC/XT', 0DH, 0AH, '$'
PC_TYPE_3 DB 'AT', 0DH, 0AH, '$'
PC_TYPE_4 DB 'PS2 model 30', 0DH, 0AH, '$'
PC_TYPE_5 DB 'PS2 model 50 or 60', 0DH, 0AH, '$'
PC_TYPE_6 DB 'PS2 model 80', 0DH, 0AH, '$'
PC_TYPE_7 DB 'PCjr', 0DH, 0AH, '$'
PC_TYPE_8 DB 'PC Convertible', 0DH, 0AH, '$'
PC_TYPE_UNKNOWN DB '  ', 0DH, 0AH, '$'
OS_VERSION_MESSAGE DB 'OS version: $'
OS_VERSION DB '  .  ', 0DH, 0AH, '$'
OEM_NUMBER_MESSAGE DB 'OEM serial number: $'
OEM_NUMBER DB '  ', 0DH, 0AH, '$'
USER_NUMBER_MESSAGE DB 'User serial number: $'
USER_NUMBER DB '      ', 0DH, 0AH, '$'

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

; Вызывает функцию вывода строки на экран
PRINT PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP

; Выводит на экран тип ПК
PRINT_PC_TYPE PROC NEAR
	; Сохраняем значения регистров
	push ax
	push bx
	push dx
	push es
	; Получаем байт, содержащий информацию о типе ПК
	mov ax, 0F000h
	mov es, ax
	mov al, es:[0FFFEh]
	; Выводим на экран первую часть строки с информацией о типе ПК
	mov dx, offset PC_TYPE_MESSAGE
	call PRINT
	; Сравниваем значение байта со значениями известных типов ПК
	cmp al, 0FFh
	je type_1
	cmp al, 0FEh
	je type_2
	cmp al, 0FDh
	je type_2
	cmp al, 0FCh
	je type_3
	cmp al, 0FAh
	je type_4
	cmp al, 0FCh
	je type_5
	cmp al, 0F8h
	je type_6
	cmp al, 0FDh
	je type_7
	cmp al, 0F9h
	je type_8
	jmp type_unknown ; В случае, если значения байта не совпадает со значениями известных типов ПК
	; Помещаем смещение строки с соотвествующим типом в регист dx
type_1:
	mov dx, offset PC_TYPE_1
	jmp print_type
type_2:
	mov dx, offset PC_TYPE_2
	jmp print_type
type_3:
	mov dx, offset PC_TYPE_3
	jmp print_type
type_4:
	mov dx, offset PC_TYPE_4
	jmp print_type
type_5:
	mov dx, offset PC_TYPE_5
	jmp print_type
type_6:
	mov dx, offset PC_TYPE_6
	jmp print_type
type_7:
	mov dx, offset PC_TYPE_7
	jmp print_type
type_8:
	mov dx, offset PC_TYPE_8
	jmp print_type
type_unknown:
	; Получаем значение байта в виде символов и записываем их в строку PC_TYPE_UNKNOWN
	call BYTE_TO_HEX
	mov bx, offset PC_TYPE_UNKNOWN
	mov [bx], al
	mov [bx+1], ah
	mov dx, bx
print_type:
	call PRINT
	; Восстанавливаем значения регистров
	pop es
	pop dx
	pop bx
	pop ax
	ret
PRINT_PC_TYPE ENDP

; Выводит на экран версию ОС, серийные номера OEM и пользователя
PRINT_PC_INFO PROC NEAR
	; Сохраняем значения регистров
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	; Получаем версию ОС и серийные номера OEM и пользователя при помощи функции 30h прерывания 21h
	mov ah, 30h
	int 21h
	; Переводим значения байтов AH и AL в 10-ичную СС в виде символов и сохраняем их в строке OS_VERSION
	mov si, offset OS_VERSION + 1
	mov dl, ah
	call BYTE_TO_DEC
	mov al, dl
	add si, 3
	call BYTE_TO_DEC
	; Выводим на экран версию ОС
	mov dx, offset OS_VERSION_MESSAGE
	call PRINT
	mov dx, offset OS_VERSION
	call PRINT
	; Переводим значение байта BH в 16-ичную СС в виде символов и сохраняем их в строке OEM_NUMBER
	mov al, bh
	call BYTE_TO_HEX
	mov di, offset OEM_NUMBER
	mov [di], al
	mov [di+1], ah
	; Выводим на экран серийный номер OEM
	mov dx, offset OEM_NUMBER_MESSAGE
	call PRINT
	mov dx, offset OEM_NUMBER
	call PRINT
	; Переводим значения байтов BL:CX в 16-ичную СС в виде символов и сохраняем их в строке USER_NUMBER
	mov al, bl
	call BYTE_TO_HEX
	mov di, offset USER_NUMBER
	mov [di], al
	mov [di+1], ah
	mov ax, cx
	add di, 5
	call WORD_TO_HEX
	; Выводим на экран серийный номер пользователя
	mov dx, offset USER_NUMBER_MESSAGE
	call PRINT
	mov dx, offset USER_NUMBER
	call PRINT
	; Восстанавливаем значения регистров
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
PRINT_PC_INFO ENDP

BEGIN:
	call PRINT_PC_TYPE
	call PRINT_PC_INFO
	xor al, al
	mov AH, 4Ch
	int 21H
	
PROGRAM ENDS

END START