%macro Descriptor 3
	dw	%2 & 0FFFFh
	dw	%1 & 0FFFFh
	db	(%1>>16)&0FFh
	dw	((%2>>8)&0F00h)|(%3&0F0FFh)
	db	(%1>>24)&0FFh
%endmacro

%macro Gate 4
	dw (%2 & 0FFFFh)
	dw %1
	dw (%3 & 1Fh) | ((%4<<8) & 0FF00h)
	dw ((%2>>16) & 0FFFFh)
%endmacro

DA_32	equ 4000h

DA_DPL0	equ 00h
DA_DPL1	equ 20h
DA_DPL3	equ 60h

DA_C	equ 98h
DA_DRW	equ 92h
DA_DRWA equ 93h

DA_LDT	equ 82h
DA_386CGate	equ 8Ch
DA_386TSS	equ 89h

SA_RPL1 equ 1
SA_RPL3	equ 3

SA_TIL	equ 4

;org 07c00h	;load from 0000 7c00
org 0100h	;load from 0000 0100
	jmp	LABEL_BEGIN

[SECTION .gdt]
LABEL_GDT:		Descriptor	0,	0,	0
LABEL_DESC_NORMAL:	Descriptor	0, 0ffffh, DA_DRW
LABEL_DESC_CODE32:	Descriptor	0,SegCode32Len-1, DA_C+DA_32
LABEL_DESC_CODE16:	Descriptor	0, 0ffffh, DA_C
LABEL_DESC_DATA:	Descriptor	0, DataLen-1, DA_DRW
LABEL_DESC_STACK:	Descriptor	0, TopOfStack, DA_DRWA+DA_32
LABEL_DESC_TEST:	Descriptor 0500000h, 0ffffh, DA_DRW
LABEL_DESC_VIDEO:	Descriptor 0B8000h, 0ffffh, DA_DRW+DA_DPL3
LABEL_DESC_LDT:		Descriptor 	0, LDTLen-1, DA_LDT
LABEL_DESC_CODE_DEST:	Descriptor	0, SegCodeDestLen-1, DA_C+DA_32
LABEL_DESC_CODE_RING3:	Descriptor	0, SegCodeRing3Len-1, DA_C+DA_32+DA_DPL3
LABEL_DESC_STACK3:	Descriptor	0, TopOfStack3, DA_DRWA+DA_32+DA_DPL3
LABEL_CALL_GATE_TEST:	Gate 		SelectorCodeDest,	0,	0,	DA_386CGate+DA_DPL3
LABEL_DESC_TSS:		Descriptor	0, TSSLen-1,	DA_386TSS

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
SelectorLDT	equ	LABEL_DESC_LDT - LABEL_GDT
SelectorCodeDest equ	LABEL_DESC_CODE_DEST - LABEL_GDT
SelectorCodeRing3 equ	LABEL_DESC_CODE_RING3 - LABEL_GDT+SA_RPL3
SelectorStack3	equ	LABEL_DESC_STACK3 - LABEL_GDT+SA_RPL3
SelectorTSS	equ	LABEL_DESC_TSS - LABEL_GDT

SelectorCallGateTest equ	LABEL_CALL_GATE_TEST - LABEL_GDT + SA_RPL3


[SECTION .data1]
ALIGN 32
[BITS 32]
LABEL_DATA:
SPValueInRealMode	dw	0
PMMessage:		db	"In Protect Mode now.", 0
OffsetPMMessage		equ	PMMessage - $$
StrTest:		db	"ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0
OffsetStrTest		equ	StrTest-$$
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

	; 初始化TSS描述符
	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_TSS
	mov word [LABEL_DESC_TSS+2], ax
	shr eax, 16
	mov byte [LABEL_DESC_TSS+4], al
	mov byte [LABEL_DESC_TSS+7], ah

	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_LDT
	mov word [LABEL_DESC_LDT+2], ax
	shr eax, 16
	mov byte [LABEL_DESC_LDT+4], al
	mov byte [LABEL_DESC_LDT+7], ah

	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_CODE_A
	mov word [LABEL_LDT_DESC_CODEA+2], ax
	shr eax, 16
	mov byte [LABEL_LDT_DESC_CODEA+4], al
	mov byte [LABEL_LDT_DESC_CODEA+7], ah

	xor eax, eax
	mov ax, cs
	shl eax, 4
	add eax, LABEL_SEG_CODE_DEST
	mov word [LABEL_DESC_CODE_DEST+2], ax
	shr eax, 16
	mov byte [LABEL_DESC_CODE_DEST+4], al
	mov byte [LABEL_DESC_CODE_DEST+7], ah

	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_CODE_RING3
	mov word [LABEL_DESC_CODE_RING3+2], ax
	shr eax, 16
	mov byte [LABEL_DESC_CODE_RING3+4], al
	mov byte [LABEL_DESC_CODE_RING3+7], ah

	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_STACK3
	mov word [LABEL_DESC_STACK3+2], ax
	shr eax, 16
	mov byte [LABEL_DESC_STACK3+4], al
	mov byte [LABEL_DESC_STACK3+7], ah

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
	mov ax, SelectorTest
	mov es, ax
	mov ax, SelectorVideo
	mov gs, ax

	mov ax, SelectorStack
	mov ss, ax

	mov esp, TopOfStack

	mov ah, 43h
	xor esi, esi
	xor edi, edi
	mov esi, OffsetPMMessage
	mov edi, (80*10+0)*2
	cld
.1:
	lodsb
	test al, al
	jz .2
	mov [gs:edi], ax
	add edi, 2
	jmp .1

.2:
	call DispReturn

	mov ax, SelectorTSS
	ltr ax

	push SelectorStack3
	push TopOfStack3
	push SelectorCodeRing3
	push 0
	retf

	call SelectorCallGateTest:0

	mov ax, SelectorLDT
	lldt ax
	jmp SelectorLDTCodeA:0

DispReturn:
	push eax
	push ebx
	mov eax, edi
	mov bl, 160
	div bl
	and eax, 0FFh
	inc eax
	mov bl, 160
	mul bl
	mov edi, eax
	pop ebx
	pop eax

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
	and al, 11111110b
	mov cr0, eax

LABEL_GO_BACK_TO_REAL:
	jmp 0:LABEL_REAL_ENTRY

Code16Len	equ $-LABEL_SEG_CODE16

[SECTION .ldt]
ALIGN 32
LABEL_LDT:
LABEL_LDT_DESC_CODEA:	Descriptor	0, CodeALen-1, DA_C+DA_32

LDTLen	equ	$-LABEL_LDT

SelectorLDTCodeA	equ	LABEL_LDT_DESC_CODEA - LABEL_LDT+SA_TIL

[SECTION .la]
ALIGN 32
[BITS 32]
LABEL_CODE_A:
	mov ax, SelectorVideo
	mov gs, ax

	mov edi, (80*13+0)*2
	mov ah, 0ch
	mov al, 'L'
	mov [gs:edi], ax

	jmp SelectorCode16:0

CodeALen	equ	$-LABEL_CODE_A

[SECTION .sdest]
[BITS 32]

LABEL_SEG_CODE_DEST:
	mov ax, SelectorVideo
	mov gs, ax

	mov edi, (80*12+0)*2
	mov ah, 0ch
	mov al, 'C'
	mov [gs:edi], ax

	retf

SegCodeDestLen equ $-LABEL_SEG_CODE_DEST

[SECTION .s3]
ALIGN 32
[BITS 32]
LABEL_STACK3:
	times 512 db 0
TopOfStack3 equ $-LABEL_STACK3-1

[SECTION .ring3]
ALIGN 32
[BITS 32]
LABEL_CODE_RING3:
	mov ax, SelectorVideo
	mov gs, ax

	mov edi, (80*14+0)*2
	mov ah, 0ch
	mov al, '3'
	mov [gs:edi], ax

	call SelectorCallGateTest:0

	jmp $
SegCodeRing3Len equ $-LABEL_CODE_RING3

[SECTION .tss]
ALIGN 32
[BITS 32]
LABEL_TSS:
	DD 0
	DD TopOfStack		;ring 0 stack
	DD SelectorStack
	DD 0			;ring 1 stack
	DD 0
	DD 0			;ring 2 stack
	DD 0
	DD 0			;CR3
	DD 0			;EIP
	DD 0			;EFLAGS
	DD 0			;EAX
	DD 0			;ECX
	DD 0			;EDX
	DD 0			;EBX
	DD 0			;ESP
	DD 0			;EBP
	DD 0			;ESI
	DD 0			;EDI
	DD 0			;ES
	DD 0			;CS
	DD 0			;SS
	DD 0			;DS
	DD 0			;FS
	DD 0			;GS
	DD 0			;LDT
	DW 0			;
	DW $-LABEL_TSS+2	;I/O
	DB 0ffh			;
TSSLen	equ	$-LABEL_TSS
	
