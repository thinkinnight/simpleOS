%macro Descriptor 3
	dw	%2 & 0FFFFh
	dw	%1 & 0FFFFh
	db	(%1>>16)&0FFh
	dw	((%2>>8)&0F00h)|(%3&0F0FFh)
	db	(%1>>24)&0FFh
%endmacro

DA_32	equ 4000h
DA_C	equ 98h
DA_DRW	equ 92h
DA_DRWA equ 93h
DA_LIMIT_4K equ 8000h

PG_P	equ 1
PG_USU	equ 4
PG_RWW	equ 2

;org 07c00h	;load from 0000 7c00
org 0100h	;load from 0000 0100
	jmp	LABEL_BEGIN

PageDirBase	equ	200000h
PageTblBase	equ	201000h

[SECTION .gdt]
LABEL_GDT:		Descriptor	0,	0,	0
LABEL_DESC_NORMAL:	Descriptor	0, 0ffffh, DA_DRW
LABEL_DESC_CODE32:	Descriptor	0,SegCode32Len-1, DA_C+DA_32
LABEL_DESC_CODE16:	Descriptor	0, 0ffffh, DA_C
LABEL_DESC_DATA:	Descriptor	0, DataLen-1, DA_DRW
LABEL_DESC_STACK:	Descriptor	0, TopOfStack, DA_DRWA+DA_32
LABEL_DESC_TEST:	Descriptor 0500000h, 0ffffh, DA_DRW
LABEL_DESC_VIDEO:	Descriptor 0B8000h, 0ffffh, DA_DRW
LABEL_DESC_PAGE_DIR:	Descriptor PageDirBase, 4095, DA_DRW
LABEL_DESC_PAGE_TBL:	Descriptor PageTblBase, 1023, DA_DRW|DA_LIMIT_4K

GdtLen	equ	$-LABEL_GDT
GdtPtr  dw	GdtLen-1
	dd	0

SelectorNormal	equ	LABEL_DESC_NORMAL - LABEL_GDT
SelectorCode32	equ	LABEL_DESC_CODE32 - LABEL_GDT
SelectorCode16	equ	LABEL_DESC_CODE16 - LABEL_GDT
SelectorData	equ	LABEL_DESC_DATA - LABEL_GDT
SelectorStack	equ	LABEL_DESC_STACK - LABEL_GDT
SelectorTest	equ	LABEL_DESC_TEST - LABEL_GDT
SelectorVideo	equ	LABEL_DESC_VIDEO - LABEL_GDT
SelectorPageDir	equ	LABEL_DESC_PAGE_DIR - LABEL_GDT
SelectorPageTbl	equ	LABEL_DESC_PAGE_TBL - LABEL_GDT

[SECTION .data1]
ALIGN 32
[BITS 32]
LABEL_DATA:
SPValueInRealMode	dw	0
PMMessage:		db	"In Protect Mode now.", 0
OffsetPMMessage		equ	PMMessage - $$
szReturn		equ	_szReturn - $$
StrTest:		db	"ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0
OffsetStrTest		equ	StrTest-$$

MemChkBuf		equ	_MemChkBuf - $$
dwMCRNumber		equ	_dwMCRNumber - $$
dwMemSize		equ	_dwMemSize - $$
dwDispPos		equ	_dwDispPos - $$
szRAMSize		equ	_szRAMSize - $$
szPMMessage		equ	_szPMMessage - $$
szMemChkTitle		equ	_szMemChkTitle - $$
ARDStruct		equ	_ARDStruct - $$
	dwBaseAddrLow	equ	_dwBaseAddrLow - $$
	dwBaseAddrHigh	equ	_dwBaseAddrHigh - $$
	dwLengthLow	equ	_dwLengthLow - $$
	dwLengthHigh	equ	_dwLengthHigh - $$
	dwType		equ	_dwType - $$

_MemChkBuf:	times 256 db 0
_szRAMSize:	db "RAM size:", 0
_szReturn:	db 0Ah, 0
_dwMCRNumber:	dd 0
_dwMemSize:	dd 0
_dwDispPos:	dd 0
_szPMMessage:	db "In Protect Mode now. ^-^", 0Ah, 0Ah, 0
_szMemChkTitle:	db "BaseAddrL BaseAddrH LengthLow LengthHigh    Type", 0Ah, 0
_ARDStruct:
	_dwBaseAddrLow:		dd 0
	_dwBaseAddrHigh:	dd 0
	_dwLengthLow:		dd 0
	_dwLengthHigh:		dd 0
	_dwType:		dd 0

DataLen			equ	$-LABEL_DATA

[SECTION .gs]
ALIGN 32
[BITS 32]
LABEL_STACK:
	times 512 db 0

TopOfStack	equ	$-LABEL_STACK-1


[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0100h

	mov [LABEL_GO_BACK_TO_REAL+3], ax
	mov [SPValueInRealMode], sp

	mov ebx, 0
	mov di, _MemChkBuf
.loop:
	mov eax, 0E820h
	mov ecx, 20
	mov edx, 0534D4150h
	int 15h
	jc LABEL_MEM_CHK_FAIL
	add di, 20
	inc dword [_dwMCRNumber]
	cmp ebx, 0
	jne .loop
	jmp LABEL_MEM_CHK_OK
LABEL_MEM_CHK_FAIL:
	mov dword [_dwMCRNumber], 0
LABEL_MEM_CHK_OK:

	mov ax, cs
	movzx eax, ax
	shl eax, 4
	add eax, LABEL_SEG_CODE16
	mov word [LABEL_DESC_CODE16+2], ax
	shr eax, 16
	mov byte [LABEL_DESC_CODE16+4], al
	mov byte [LABEL_DESC_CODE16+7], ah

	xor eax, eax
	mov ax, cs
	shl eax, 4
	add eax, LABEL_SEG_CODE32
	mov word [LABEL_DESC_CODE32+2], ax
	shr eax, 16
	mov byte [LABEL_DESC_CODE32+4], al
	mov byte [LABEL_DESC_CODE32+7], ah

	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_DATA
	mov	word [LABEL_DESC_DATA + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_DATA + 4], al
	mov	byte [LABEL_DESC_DATA + 7], ah

	; 初始化堆栈段描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_STACK
	mov	word [LABEL_DESC_STACK + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_STACK + 4], al
	mov	byte [LABEL_DESC_STACK + 7], ah

	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_GDT
	mov dword [GdtPtr+2], eax

	lgdt [GdtPtr]

	cli

	in al, 92h
	or al, 00000010b
	out 92h, al

	mov eax, cr0
	or eax, 1
	mov cr0, eax

	jmp dword SelectorCode32:0

LABEL_REAL_ENTRY:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	
	mov sp, [SPValueInRealMode]
	
	in al, 92h
	and al, 11111101b
	out 92h, al

	sti

	mov ax, 4c00h
	int 21h

[SECTION .s32]
[BITS 32]
LABEL_SEG_CODE32:
	mov ax, SelectorData
	mov ds, ax
	mov ax, SelectorData
	mov es, ax
	mov ax, SelectorVideo
	mov gs, ax

	mov ax, SelectorStack
	mov ss, ax

	mov esp, TopOfStack

	;xchg bx, bx

	push szPMMessage
	call DispStr
	add esp, 4
	
	push szMemChkTitle
	call DispStr
	add esp, 4

	;xchg bx, bx

	call DispMemSize
	call SetupPaging

	jmp SelectorCode16:0

DispInt:
	mov eax, [esp+4]
	shr eax, 24
	call DispAL

	mov eax, [esp+4]
	shr eax, 16
	call DispAL

	mov eax, [esp+4]
	shr eax, 8
	call DispAL

	mov eax, [esp+4]
	call DispAL

	mov ah, 07h
	mov al, 'h'
	push edi
	mov edi, [dwDispPos]
	mov [gs:edi], ax
	add edi, 4
	mov [dwDispPos], edi
	pop edi

	ret

DispStr:
	push ebp
	mov ebp, esp
	push ebx
	push esi
	push edi

	mov esi, [ebp+8]
	mov edi, [dwDispPos]
	mov ah, 0Fh
.1:
	lodsb
	test al, al
	jz .2
	cmp al, 0Ah
	jnz .3
	push eax
	mov eax, edi
	mov bl, 160
	div bl
	and eax, 0FFh
	inc eax
	mov bl, 160
	mul bl
	mov edi, eax
	pop eax
	jmp .1
.3:
	mov [gs:edi], ax
	add edi, 2
	jmp .1

.2:
	mov [dwDispPos], edi

	pop edi
	pop esi
	pop ebx
	pop ebp
	ret

SetupPaging:
	mov ax, SelectorPageDir
	mov es, ax
	mov ecx, 1024
	xor edi, edi
	xor eax, eax
	mov eax, PageTblBase | PG_P | PG_USU | PG_RWW
.1:
	stosd
	add eax, 4096
	loop .1

	mov ax, SelectorPageTbl
	mov es, ax
	mov ecx, 1024*1024
	xor edi, edi
	xor eax, eax
	mov eax, PG_P | PG_USU | PG_RWW

.2:
	stosd
	add eax, 4096
	loop .2

	mov eax, PageDirBase
	mov cr3, eax
	mov eax, cr0
	or eax, 80000000h
	mov cr0, eax
	jmp short .3

.3:
	nop

	ret

TestRead:
	xor esi, esi
	mov ecx, 26
.loop:
	mov al, [es:esi]
	call DispAL
	inc esi
	loop .loop

	call DispReturn
	ret

TestWrite:
	push esi
	push edi
	xor esi, esi
	xor edi, edi
	mov esi, OffsetStrTest
	cld
.1:
	lodsb
	test al, al
	jz .2
	mov [es:edi],al
	inc edi
	jmp .1
.2:
	pop edi
	pop esi
	ret

DispAL:
	push ecx
	push edx
	push edi

	mov edi, [dwDispPos]
	
	mov ah, 0Fh
	mov dl, al
	shr al, 4
	mov ecx, 2
.begin:
	and al, 01111b
	cmp al, 9
	ja .1
	add al, '0'
	jmp .2
.1:
	sub al, 0Ah
	add al, 'A'
.2:
	mov [gs:edi], ax
	add edi, 2

	mov al, dl
	loop .begin
	;add edi, 2

	mov [dwDispPos], edi

	pop edi
	pop edx
	pop ecx

	ret

DispReturn:
	push szReturn
	call DispStr
	add esp, 4

	ret

DispMemSize:
	push esi
	push edi
	push ecx

	mov esi, MemChkBuf
	mov ecx, [dwMCRNumber]
.loop:
	mov edx, 5
	mov edi, ARDStruct
.1:
	push dword [esi]
	call DispInt
	pop eax
	stosd
	add esi, 4
	dec edx
	cmp edx, 0
	jnz .1
	call DispReturn
	cmp dword [dwType], 1
	jne .2
	mov eax, [dwBaseAddrLow]
	add eax, [dwLengthLow]
	cmp eax, [dwMemSize]
	jb .2
	mov [dwMemSize], eax
.2:
	loop .loop
	call DispReturn
	push szRAMSize
	call DispStr
	add esp, 4

	push dword [dwMemSize]
	call DispInt
	add esp, 4

	pop ecx
	pop edi
	pop esi
	ret

SegCode32Len equ $-LABEL_SEG_CODE32

[SECTION .s16code]
ALIGN 32
[BITS 16]
LABEL_SEG_CODE16:
	mov ax, SelectorNormal
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov eax, cr0
	and eax, 7FFFFFFEh
	mov cr0, eax

LABEL_GO_BACK_TO_REAL:
	jmp 0:LABEL_REAL_ENTRY

Code16Len	equ $-LABEL_SEG_CODE16

