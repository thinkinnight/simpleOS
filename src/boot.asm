;%define _BOOT_DEBUG_

%ifdef _BOOT_DEBUG_
	org 0100h
%else
	org 07c00h	;load from 0000 7c00
%endif

jmp short LABEL_START
nop

BS_OEMName	DB	'CnyaoGao'
BPB_BytsPerSec	DW	512
BPB_SecPerClus	DB	1
BPB_RsvdSecCnt	DW	1
BPB_NumFATs	DB	2
BPB_RootEntCnt	DW	224
BPB_TotSec16	DW	2880
BPB_Media	DB	0xF0
BPB_FATSz16	DW	9
BPB_SecPerTrk	DW 18		; 每磁道扇区数
BPB_NumHeads	DW 2		; 磁头数(面数)
BPB_HiddSec	DD 0		; 隐藏扇区数
BPB_TotSec32	DD 0		; wTotalSectorCount为0时这个值记录扇区数
BS_DrvNum	DB 0		; 中断 13 的驱动器号
BS_Reserved1	DB 0		; 未使用
BS_BootSig	DB 29h		; 扩展引导标记 (29h)
BS_VolID	DD 0		; 卷序列号
BS_VolLab	DB 'SimpleS0.01'; 卷标, 必须 11 个字节
BS_FileSysType	DB 'FAT12   '	; 文件系统类型, 必须 8个字节  

LABEL_START:
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
