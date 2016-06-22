;%define _BOOT_DEBUG_

%ifdef _BOOT_DEBUG_
	org 0100h
%else
	org 07c00h	;load from 0000 7c00
%endif

%ifdef _BOOT_DEBUG_
BaseOfStack	equ 0100h
%else
BaseOfStack	equ 07c00h
%endif 

BaseOfLoader		equ	09000h
OffsetOfLoader		equ	0100h
RootDirSectors		equ	14
SectorNoOfRootDirectory	equ	19
SectorNoOfFAT1		equ	1
DeltaSectorNo		equ	17

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
	mov ss, ax
	mov sp, BaseOfStack

	mov ax, 0600h
	mov bx, 0700h
	mov cx, 0
	mov dx, 0184fh
	int 10h

	mov dh, 0
	call DispStr

	xor ah, ah
	xor dl, dl
	int 13h

	mov	word [wSectorNo], SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp	word [wRootDirSizeForLoop], 0	;  `. 判断根目录区是不是已经读完
	jz	LABEL_NO_LOADERBIN		;  /  如果读完表示没有找到 LOADER.BIN
	dec	word [wRootDirSizeForLoop]	; /
	mov	ax, BaseOfLoader
	mov	es, ax			; es <- BaseOfLoader
	mov	bx, OffsetOfLoader	; bx <- OffsetOfLoader
	mov	ax, [wSectorNo]		; ax <- Root Directory 中的某 Sector 号
	mov	cl, 1
	call	ReadSector

	mov	si, LoaderFileName	; ds:si -> "LOADER  BIN"
	mov	di, OffsetOfLoader	; es:di -> BaseOfLoader:0100
	cld
	mov	dx, 10h
LABEL_SEARCH_FOR_LOADERBIN:
	cmp	dx, 0				   ; `. 循环次数控制,
	jz	LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR ;  / 如果已经读完了一个 Sector,
	dec	dx				   ; /  就跳到下一个 Sector
	mov	cx, 11
LABEL_CMP_FILENAME:
	cmp	cx, 0
	jz	LABEL_FILENAME_FOUND	; 如果比较了 11 个字符都相等, 表示找到
	dec	cx
	lodsb				; ds:si -> al
	cmp	al, byte [es:di]
	jz	LABEL_GO_ON
	jmp	LABEL_DIFFERENT		; 只要发现不一样的字符就表明本 DirectoryEntry
					; 不是我们要找的 LOADER.BIN
LABEL_GO_ON:
	inc	di
	jmp	LABEL_CMP_FILENAME	; 继续循环

LABEL_DIFFERENT:
	and	di, 0FFE0h		; else `. di &= E0 为了让它指向本条目开头
	add	di, 20h			;       |
	mov	si, LoaderFileName	;       | di += 20h  下一个目录条目
	jmp	LABEL_SEARCH_FOR_LOADERBIN;    /

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add	word [wSectorNo], 1
	jmp	LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_LOADERBIN:
	mov	dh, 2			; "No LOADER."
	call	DispStr			; 显示字符串
%ifdef	_BOOT_DEBUG_
	mov	ax, 4c00h		; `.
	int	21h			; /  没有找到 LOADER.BIN, 回到 DOS
%else
	jmp	$			; 没有找到 LOADER.BIN, 死循环在这里
%endif

LABEL_FILENAME_FOUND:			; 找到 LOADER.BIN 后便来到这里继续
	mov ax, RootDirSectors
	and di, 0FFE0h
	add di, 01Ah
	mov cx, word [es:di]
	push cx
	add cx, ax
	add cx, DeltaSectorNo
	mov ax, BaseOfLoader
	mov es, ax
	mov bx, OffsetOfLoader
	mov ax, cx

LABEL_GOON_LOADING_FILE:
	push ax
	push bx
	mov ah, 0Eh
	mov al, '.'
	mov bl, 0Fh
	int 10h
	pop bx
	pop ax

	mov cl, 1
	call ReadSector
	pop ax
	call GetFATEntry
	cmp ax, 0FFFh
	jz LABEL_FILE_LOADED
	push ax
	mov dx, RootDirSectors
	add ax, dx
	add ax, DeltaSectorNo
	add bx, [BPB_BytsPerSec]
	jmp LABEL_GOON_LOADING_FILE

LABEL_FILE_LOADED:
	mov dh, 1
	call DispStr

	jmp BaseOfLoader:OffsetOfLoader

DispStr:
	mov	ax, MessageLength
	mul	dh
	add	ax, BootMessage
	mov	bp, ax			; ES:BP = 串地址
	mov 	ax, ds
	mov	es, ax
	mov	cx, MessageLength	; CX = 串长度
	mov	ax, 01301h		; AH = 13,  AL = 01h
	mov	bx, 0007h		; 页号为0(BH = 0) 黑底红字(BL = 0Ch,高亮)
	mov	dl, 0
	int	10h			; int 10h
	ret

ReadSector:
	push bp
	mov bp, sp
	sub esp, 2

	mov byte [bp-2], cl
	push bx
	mov bl, [BPB_SecPerTrk]
	div bl
	inc ah
	mov cl, ah
	mov dh, al
	shr al, 1
	mov ch, al
	and dh, 1
	pop bx
	mov dl, [BS_DrvNum]
.GoOnReading:
	mov ah, 2
	mov al, byte [bp-2]
	int 13h
	jc .GoOnReading

	add esp, 2
	pop bp

	ret

GetFATEntry:
	push	es
	push	bx
	push	ax
	mov	ax, BaseOfLoader; `.
	sub	ax, 0100h	;  | 在 BaseOfLoader 后面留出 4K 空间用于存放 FAT
	mov	es, ax		; /
	pop	ax
	mov	byte [bOdd], 0
	mov	bx, 3
	mul	bx			; dx:ax = ax * 3
	mov	bx, 2
	div	bx			; dx:ax / 2  ==>  ax <- 商, dx <- 余数
	cmp	dx, 0
	jz	LABEL_EVEN
	mov	byte [bOdd], 1
LABEL_EVEN:;偶数
	; 现在 ax 中是 FATEntry 在 FAT 中的偏移量,下面来
	; 计算 FATEntry 在哪个扇区中(FAT占用不止一个扇区)
	xor	dx, dx			
	mov	bx, [BPB_BytsPerSec]
	div	bx ; dx:ax / BPB_BytsPerSec
		   ;  ax <- 商 (FATEntry 所在的扇区相对于 FAT 的扇区号)
		   ;  dx <- 余数 (FATEntry 在扇区内的偏移)。
	push	dx
	mov	bx, 0 ; bx <- 0 于是, es:bx = (BaseOfLoader - 100):00
	add	ax, SectorNoOfFAT1 ; 此句之后的 ax 就是 FATEntry 所在的扇区号
	mov	cl, 2
	call	ReadSector ; 读取 FATEntry 所在的扇区, 一次读两个, 避免在边界
			   ; 发生错误, 因为一个 FATEntry 可能跨越两个扇区
	pop	dx
	add	bx, dx
	mov	ax, [es:bx]
	cmp	byte [bOdd], 1
	jnz	LABEL_EVEN_2
	shr	ax, 4
LABEL_EVEN_2:
	and	ax, 0FFFh

LABEL_GET_FAT_ENRY_OK:

	pop	bx
	pop	es
	ret

wRootDirSizeForLoop	dw	RootDirSectors
wSectorNo		dw	0
bOdd			db	0

LoaderFileName		db	"LOADER  BIN", 0
MessageLength		equ	9
BootMessage:		db	"Booting  "
Message1:		db	"Ready.   "
Message2:		db	"No LOADER"

times 	510-($-$$)	db	0	; 填充剩下的空间，使生成的二进制代码恰好为512字节
dw 	0xaa55				; 结束标志
