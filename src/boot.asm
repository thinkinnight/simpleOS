org 07c00h	;load from 0000 7c00
mov ax, cs	;cs 代码段基地址
mov ds, ax	;ds 数据段基地址=代码段基地址
mov es, ax	;es 附加段基地址=代码段基地址
call DispStr
jmp $

DispStr:
	mov ax, BootMessage	;ax=the start address of string
	mov bp, ax		;es:bp = the start address of string
	mov cx, 16		;cx=the length of string
	mov ax, 01301h		;AH=13, AL=01h
	mov bx, 0043h		;BH=0 BL=0Ch
	mov dl, 0
	int 10h			;call the interupt
	ret

BootMessage:		db	"Hello, OS world!"
times	510-($-$$)	db 	0
dw	0xaa55
