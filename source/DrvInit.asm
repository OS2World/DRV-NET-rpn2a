; *** Initial part

include	NDISdef.inc
include	rtl8029.inc
include	devpac.inc
include misc.inc
include	OEMHelp.inc
include	DrvRes.inc
include	HWRes.inc

cfgKeyDesc	struc
NextKey		dw	?
KeyStrPtr	dw	?
KeyStrLen	dw	?
KeyProc		dw	?
cfgKeyDesc	ends

cwRCRD		record  cwRsv:9 = 0,
		cwI15O:1 = 0,
		cwPS:1 = 0,
		cwDPX:1 = 0,
		cwNETADR:1 = 0,
		cwVTXQ:1 = 0,
		cwTXQ:1 = 0,
		cwUnk:1 = 0

cr	equ	0dh
lf	equ	0ah

extern	Dos16Open : far16
extern	Dos16Close : far16
extern	Dos16DevIOCtl : far16
extern	Dos16PutMessage : far16

.386

_DATA	segment	public word use16 'DATA'

DS_Lin		dd	?
HeapEnd		dw	offset HeapStart
HeapStart:

handle_Protman	dw	?
name_Protman	db	'PROTMAN$',0
TmpDrvName	db	'RPN2A$',0,0	; Realtek Pci Ne2000 Another

name_OEMHLP	db	'OEMHLP$',0
handle_OEMHLP	dw	?
P_OEMHLP	db	10 dup (?)
D_OEMHLP	db	6 dup (?)

PMparm		PMBlock	<>

DrvKeyword1	cfgKeyDesc  < offset DrvKeyword2, offset strKeyword1, \
		 lenKeyword1, offset sci_SLOT >
DrvKeyword2	cfgKeyDesc  < offset DrvKeyword3, offset strKeyword2, \
		 lenKeyword2, offset sci_NETADR >
DrvKeyword3	cfgKeyDesc  < offset DrvKeyword4, offset strKeyword3, \
		 lenKeyword3, offset sci_TXQUEUE >
DrvKeyword4	cfgKeyDesc  < offset DrvKeyword5, offset strKeyword4, \
		 lenKeyword4, offset sci_LTXQUEUE >
DrvKeyword5	cfgKeyDesc  < offset DrvKeyword6, offset strKeyword5, \
		 lenKeyword5, offset sci_DPX >
DrvKeyword6	cfgKeyDesc  < offset DrvKeyword7, offset strKeyword6, \
		 lenKeyword6, offset sci_PS >
DrvKeyword7	cfgKeyDesc  < 0, offset strKeyword7, \
		 lenKeyword7, offset sci_IRQ15O >


cfgKeyWarn	cwRCRD	<>


Key_DRIVERNAME	db	'DRIVERNAME',0,0
strKeyword1	db	'SLOT',0
lenKeyword1	equ	$ - offset strKeyword1
strKeyword2	db	'NETADDRESS',0
lenKeyword2	equ	$ - offset strKeyword2
strKeyword3	db	'TXQUEUE',0
lenKeyword3	equ	$ - offset strKeyword3
strKeyword4	db	'LTXQUEUE',0
lenKeyword4	equ	$ - offset strKeyword4
strKeyword5	db	'DUPLEX',0
lenKeyword5	equ	$ - offset strKeyword5
strKeyword6	db	'PAUSE',0
lenKeyword6	equ	$ - offset strKeyword6
strKeyword7	db	'IRQ15OVR',0
lenKeyword7	equ	$ - offset strKeyword7



msg_OSEnvFail	db	'?! Invalid System Information?!',cr,lf,0
msg_ManyInst	db	'Too many module was installed.',cr,lf,0
msg_NoProtman	db	'Protocol manager open failure.',cr,lf,0
msg_ProtIOCtl	db	'Protocol manager IOCtl failure.',cr,lf,0
msg_ProtLevel	db	'Invalid protocol manager level.',cr,lf,0
msg_NoModule	db	'Module not found in PROTOCOL.INI',cr,lf,0

msg_InvSLOT	db	'Invalid SLOT keyword.',cr,lf,0
msg_NoOEMHLP	db	'OEMHLP$ PCI access failure.',cr,lf,0
msg_NoHardware	db	'Device not found.',cr,lf,0
msg_InvIOaddr	db	'I/O Base address detection failure.',cr,lf,0
;msg_InvMEMaddr	db	'Memory Base address detection failure.',cr,lf,0
msg_InvIRQlevel	db	'IRQ detection failure.',cr,lf,0
msg_ChkCmdFail	db	'warning: PCI Command register check failure.',cr,lf,0
msg_ModifyCmd	db	'info: Set Bus Master and/or Memory bits in PCI Command Register.',cr,lf,0

; msg_CtxFail	db	'Context Hook handle allocation failure.',cr,lf,0
msg_NoSel	db	'GDT Selector to copy Tx/Rx buffer allocation failure.',cr,lf,0
msg_RegFail	db	'Module registration to protocol manager failure.',cr,lf,0
Credit		db	cr,lf,' Realtek RTL8029AS OS/2 NDIS Another MAC Driver '
		db	'ver.1.01. (2006-01-13)',cr,lf,0
Copyright	db	0	; Write copyright message here if you want.

Heap		db	( 8*sizeof(vtxd) ) dup (0)

_DATA	ends

_TEXT	segment	public word use16 'CODE'
	assume	ds:_DATA

public	Strategy
Strategy	proc	far
;	int	3		; << debug >>
	mov	al,es:[bx]._RPH.Cmd
	cmp	al,CMDOpen
	jz	short loc_OC
	cmp	al,CMDClose
	jnz	short loc_1
loc_OC:
	mov	es:[bx]._RPH.Status,100h
	retf
loc_E:
	mov	es:[bx]._RPH.Status,8103h
	retf
loc_1:
	cmp	al,CMDInit
	jnz	short loc_E
	push	es
	push	bx
	call	_DrvInit
	pop	bx
	pop	es
	retf
Strategy	endp

_DrvInit		proc	near
	enter	2,0		; -2:error message offset
	les	bx,[bp+4]
	mov	eax,es:[bx]._RPINIT.DevHlpEP
	mov	[DevHelp],eax

	push	offset Credit
	call	_PutMessage
	push	offset Copyright
	call	_PutMessage
	add	sp,2+2

	call	_SetDrvEnv
	or	ax,ax
	jnz	short loc_rnm
	mov	[bp-2],offset msg_OSEnvFail
	jmp	short loc_err1

loc_rnm:
	call	_ResolveName
	or	ax,ax
	jnz	short loc_protop
	mov	[bp-2],offset msg_ManyInst
	jmp	short loc_err1

loc_protop:
	call	_OpenProtman
	or	ax,ax
	jnz	short loc_protcfg
	mov	[bp-2],offset msg_NoProtman
	jmp	short loc_err1

loc_protcfg:
	call	_ScanConfigImage
	or	ax,ax
	jnz	short loc_fndadp
	mov	[bp-2],dx
	jmp	short loc_err2

loc_fndadp:
	mov	al,[cfgSLOT]
	mov	ah,0
	push	ax
	call	_FindHardware
	pop	cx
	or	ax,ax
	jz	short loc_err2

loc_agdt:
	call	_AllocGDT
	or	ax,ax
	jnz	short loc_ctx
	mov	[bp-2],offset msg_NoSel
	jmp	short loc_err2

loc_ctx:
;	call	_AllocCtxHook
;	or	ax,ax
;	jnz	short loc_protreg
;	mov	[bp-2],offset msg_CtxFail
;	jmp	short loc_err3

loc_protreg:
	call	_RegisterModule
	or	ax,ax
	jnz	short loc_OK
	mov	[bp-2],offset msg_RegFail
	jmp	short loc_err4

loc_OK:
	call	_CloseProtman
	call	_InitQueue
	les	bx,[bp+4]
	mov	ax,[HeapEnd]
	mov	es:[bx]._RPINITOUT.CodeEnd,offset _DrvInit
	mov	es:[bx]._RPINITOUT.DataEnd,ax
	mov	es:[bx]._RPH.Status,100h
	leave
	retn

loc_err4:
loc_err3:
	call	_ReleaseGDT
loc_err2:
	call	_CloseProtman
loc_err1:
	push	word ptr [bp-2]
	call	_PutMessage
;	pop	ax
	les	bx,[bp+4]
	mov	es:[bx]._RPINITOUT.CodeEnd,0
	mov	es:[bx]._RPINITOUT.DataEnd,0
	mov	es:[bx]._RPH.Status,8115h	; quiet init fail
	leave
	retn
	
_DrvInit	endp


_FindHardware	proc	near
	call	_OpenOEMPCI
	or	ax,ax
	jnz	short loc_0
	push	offset msg_NoOEMHLP
	call	_PutMessage
	add	sp,2
	xor	ax,ax
	retn

loc_0:
	enter	6,0
FH_s	equ	bp+4	; SLOT
FH_ci	equ	bp-6	; class index
FH_di	equ	bp-5	; device index
FH_bdf	equ	bp-4	; BusDevFunc
FH_cb	equ	bp-2	; capability pointer

	push	si
	push	di
	mov	word ptr [FH_ci],0
	mov	si,offset P_OEMHLP
	mov	di,offset D_OEMHLP
loc_1:
	mov	al,[FH_ci]
	mov	[si].P_PCI_FindClass.Subfunction,PCI_FindClass
	mov	[si].P_PCI_FindClass.ClassCode,020000h	; Ethernet
	mov	[si].P_PCI_FindClass.Index,al
	call	IOCtlOEMPCI
	or	ax,ax
	jnz	short loc_e1
	mov	ax,word ptr [di].D_PCI_FindClass.Bus
	mov	[FH_bdf],ax

	mov	[si].P_PCI_ReadConfigSpace.Subfunction,PCI_ReadConfigSpace
	mov	word ptr [si].P_PCI_ReadConfigSpace.Bus,ax
	mov	[si].P_PCI_ReadConfigSpace.ConfigRegister,0
	mov	[si].P_PCI_ReadConfigSpace.RegSize,4
	call	IOCtlOEMPCI
	or	ax,ax
	jnz	short loc_e1
	mov	eax,[di].D_PCI_ReadConfigSpace.Data
	cmp	eax,802910ECh		; RTL8029
	jnz	short loc_3
loc_2:
	mov	al,[FH_di]
	cmp	al,[FH_s]
	jz	short loc_found
	inc	byte ptr [FH_di]
loc_3:
	inc	byte ptr [FH_ci]
	jmp	short loc_1

loc_e1:
	push	offset msg_NoHardware
loc_ex:
	call	_PutMessage
	add	sp,2
	call	_CloseOEMPCI
	xor	ax,ax
	pop	di
	pop	si
	leave
	retn

loc_e2:
	push	offset msg_InvIOaddr
	jmp	short loc_ex

loc_found:
			; --- get IOaddr
	mov	ax,[FH_bdf]
	mov	[si].P_PCI_ReadConfigSpace.Subfunction,PCI_ReadConfigSpace
	mov	word ptr [si].P_PCI_ReadConfigSpace.Bus,ax
	mov	[si].P_PCI_ReadConfigSpace.ConfigRegister,10h	; IO
	mov	[si].P_PCI_ReadConfigSpace.RegSize,4
	call	IOCtlOEMPCI
	or	ax,ax
	jnz	short loc_e2
	cmp	word ptr [di].D_PCI_ReadConfigSpace.Data[2],0
	jnz	short loc_e2
	mov	ax,word ptr [di].D_PCI_ReadConfigSpace.Data
	test	al,1		; IO indicator
	jz	short loc_e2
	test	al,1eh		; bit 1..4  check alignment
	jnz	short loc_e2
	and	ax,-20h		; 0..1f
	jz	short loc_e2
	mov	IOaddr,ax

			; --- get MEMaddr
IF 0	; memory space does not exist.
	mov	dx,[FH_bdf]
	mov	[si].P_PCI_ReadConfigSpace.Subfunction,PCI_ReadConfigSpace
	mov	word ptr [si].P_PCI_ReadConfigSpace.Bus,dx
	mov	[si].P_PCI_ReadConfigSpace.ConfigRegister,14h	; MEM
	mov	[si].P_PCI_ReadConfigSpace.RegSize,4
	call	IOCtlOEMPCI
	or	ax,ax
	jnz	short loc_e3
	mov	eax,[di].D_PCI_ReadConfigSpace.Data
	test	al,1		; memory indicator
	jnz	short loc_e3
	and	eax,-20h	; 32bytes
	jz	short loc_e3
	mov	MEMaddr,eax
ENDIF
			; --- get IRQlevel
loc_irq:
	mov	dx,[FH_bdf]
	mov	[si].P_PCI_ReadConfigSpace.Subfunction,PCI_ReadConfigSpace
	mov	word ptr [si].P_PCI_ReadConfigSpace.Bus,dx
	mov	[si].P_PCI_ReadConfigSpace.ConfigRegister,3Ch	; IRQ
	mov	[si].P_PCI_ReadConfigSpace.RegSize,1
	call	IOCtlOEMPCI
	or	ax,ax
	jnz	short loc_e4
	mov	al,byte ptr [di].D_PCI_ReadConfigSpace.Data
	test	[drvflags],mask df_i15o
	jnz	short loc_i1
	test	al,-10h
	jnz	short loc_e4
loc_i1:
	mov	IRQlevel,al

	push	word ptr [FH_bdf]
	call	ChkCmdReg
	pop	ax

	call	_CloseOEMPCI
	mov	ax,1
	pop	di
	pop	si
	leave
	retn
IF 0
loc_e3:
	push	offset msg_InvMEMaddr
	jmp	near ptr loc_ex
ENDIF
loc_e4:
	push	offset msg_InvIRQlevel
	jmp	near ptr loc_ex

ChkCmdReg	proc	near
CCR_bdf	equ	bp+4	; BusDevFunc
	push	bp
	mov	bp,sp

			; --- clear status
	mov	dx,[CCR_bdf]
	or	ax,-1			; -1: clear PCI status register
	mov	[si].P_PCI_WriteConfigSpace.Subfunction,PCI_WriteConfigSpace
	mov	word ptr [si].P_PCI_WriteConfigSpace.Bus,dx
	mov	[si].P_PCI_WriteConfigSpace.ConfigRegister,6	; sts
	mov	[si].P_PCI_WriteConfigSpace.RegSize,2
	mov	word ptr [si].P_PCI_WriteConfigSpace.Data,ax
	call	IOCtlOEMPCI
	or	ax,ax
	jnz	short loc_e6

			; --- read command
	mov	ax,[CCR_bdf]
	mov	[si].P_PCI_ReadConfigSpace.Subfunction,PCI_ReadConfigSpace
	mov	word ptr [si].P_PCI_ReadConfigSpace.Bus,ax
	mov	[si].P_PCI_ReadConfigSpace.ConfigRegister,4	; cmd
	mov	[si].P_PCI_ReadConfigSpace.RegSize,2
	call	IOCtlOEMPCI		; read PCI command register
	or	ax,ax
	jnz	short loc_e6

	mov	ax,word ptr [di].D_PCI_ReadConfigSpace.Data
	test	al,1			; I/O enable
	jnz	short loc_1

			; --- write command. set Bus Master/memory bits
;	mov	ax,word ptr [di].D_PCI_ReadConfigSpace.Data
	mov	dx,[CCR_bdf]
	or	al,1
	mov	[si].P_PCI_WriteConfigSpace.Subfunction,PCI_WriteConfigSpace
	mov	word ptr [si].P_PCI_WriteConfigSpace.Bus,dx
	mov	[si].P_PCI_WriteConfigSpace.ConfigRegister,4	; cmd
	mov	[si].P_PCI_WriteConfigSpace.RegSize,2
	mov	word ptr [si].P_PCI_WriteConfigSpace.Data,ax
	call	IOCtlOEMPCI
	or	ax,ax
	jnz	short loc_e6

	push	offset msg_ModifyCmd
	call	_PutMessage
;	pop	ax
loc_1:
	leave
	retn
loc_e6:
	push	offset msg_ChkCmdFail
	call	_PutMessage
;	pop	ax
	leave
	retn
ChkCmdReg	endp


IOCtlOEMPCI	proc	near
	push	si
	push	di

	push	ds
	push	di
	push	ds
	push	si
	push	OEMHLP_PCI
	push	IOCTL_OEMHLP
	push	[handle_OEMHLP]
	call	Dos16DevIOCtl

	neg	ax
	pop	di
	pop	si
	setc	ah
	mov	al,[di]
	retn
IOCtlOEMPCI	endp

_OpenOEMPCI	proc	near
	push	cx
	mov	ax,sp
	push	si
	push	di

	push	ds
	push	offset name_OEMHLP	; file name
	push	ds
	push	offset handle_OEMHLP	; file handle
	push	ss
	push	ax		; action taken
	push	0
	push	0		; File size
	push	0		; File attribute
	push	1		; Open flag (Open if exist)
	push	42h		; Open Mode
	push	0
	push	0		; reserve (NULL)
	call	Dos16Open
	or	ax,ax
	jnz	short loc_e1
	
	mov	si,offset P_OEMHLP
	mov	di,offset D_OEMHLP
	mov	[si].P_PCI_QueryBIOS.Subfunction,PCI_QueryBIOS
	call	IOCtlOEMPCI
	or	ax,ax
	jnz	short loc_e2
	mov	ax,1
loc_ex:
	pop	di
	pop	si
	pop	cx
	retn
loc_e2:
	call	_CloseOEMPCI
loc_e1:
	xor	ax,ax
	jmp	short loc_ex
_OpenOEMPCI	endp

_CloseOEMPCI	proc	near
	push	[handle_OEMHLP]
	call	Dos16Close
	retn
_CloseOEMPCI	endp

_FindHardware	endp


_ResolveName	proc	near
	enter	6,0
	push	si
	push	di
	xor	bx,bx
	mov	si,offset TmpDrvName
loc_1:
	cmp	byte ptr [bx+si],'$'
	jz	short loc_2
	inc	bx
	cmp	bx,8
	jb	short loc_1
loc_e:
	xor	ax,ax		; invalid name
	jmp	near ptr loc_err
loc_2:
	test	bx,bx
	jz	short loc_e
	mov	[bp-2],bx
	mov	byte ptr [bx+si+1],0
loc_3:
	lea	di,[bp-4]
	lea	bx,[bp-6]
	push	ds
	push	si		; name
	push	ss
	push	bx		; handle
	push	ss
	push	di		; action
	push	0
	push	0		; file size
	push	0		; attribute
	push	1		; Open flag
	push	42h		; Open mode
	push	0		; reserve
	push	0
	call	Dos16Open
	or	ax,ax
	jnz	short loc_5	; this name is not used. OK.

	push	word ptr [bp-6]
	call	Dos16Close
	mov	bx,[bp-2]
	cmp	bx,7		; already max length
	jnb	short loc_e
	mov	si,offset TmpDrvName
	cmp	byte ptr [bx+si],'$'
	jz	short loc_4	; first modification
	cmp	byte ptr [bx+si],'9'
	jz	short loc_e	; last modification. failure.
	inc	byte ptr [bx+si]
	jmp	short loc_3
loc_4:
	mov	word ptr [bx+si],'$1'
	mov	byte ptr [bx+si+2],0
	jmp	short loc_3

loc_5:
	mov	cx,8
	mov	si,offset TmpDrvName
	mov	di,offset DrvName
	push	ds
	pop	es
	cld
loc_6:
	lodsb
	cmp	al,0
	jz	short loc_7
	stosb
	dec	cx
	jnz	short loc_6
loc_7:
	jcxz	short loc_8
	mov	al,' '
	rep	stosb

loc_8:
	mov	ax,1
loc_err:
	pop	di
	pop	si
	leave
	retn
_ResolveName	endp


_OpenProtman	proc	near
	enter	2,0
	mov	ax,sp
	push	ds
	push	offset name_Protman	; file name
	push	ds
	push	offset handle_Protman	; file handle
	push	ss
	push	ax		; action taken
	push	0
	push	0		; File size
	push	0		; File attribute
	push	1		; Open flag (Open if exist)
	push	42h		; Open Mode
	push	0
	push	0		; reserve (NULL)
	call	Dos16Open
	mov	dx,ax
	neg	ax
	sbb	ax,ax
	inc	ax
	leave
	retn
_OpenProtman	endp

_CloseProtman	proc	near
	mov	ax,[handle_Protman]
	push	ax
	call	Dos16Close
	retn
_CloseProtman	endp

_RegisterModule	proc	near
	mov	cx,cs
	mov	ax,ds
	and	cl,-8

	mov	CommonChar.moduleDS,ax
	mov	word ptr CommonChar.cctsrd[2],cx
	mov	word ptr CommonChar.cctssc[2],ax
	mov	word ptr CommonChar.cctsss[2],ax
	mov	word ptr CommonChar.cctupd[2],ax
	mov	word ptr MacChar.mcal[2],ax
	mov	word ptr MacChar.mctAdapterDesc[2],ax
	mov	word ptr UpDisp.updpbp[2],ax
	mov	word ptr UpDisp.request[2],cx
	mov	word ptr UpDisp.txchain[2],cx
	mov	word ptr UpDisp.rxdata[2],cx
	mov	word ptr UpDisp.rxrelease[2],cx
	mov	word ptr UpDisp.indon[2],cx
	mov	word ptr UpDisp.indoff[2],cx

	mov	al,IRQlevel
	mov	ah,0
	mov	MacChar.mctIRQ,ax
	mov	al,cfgVTXQUEUE
	mov	dx,cfgMAXFRAMESIZE
	mov	MacChar.mcttqd,ax
	mov	MacChar.mfs,dx
	mov	MacChar.tbs,dx
	mov	MacChar.rbs,dx
	mul	dx
	mov	word ptr MacChar.ttbc,ax
	mov	word ptr MacChar.ttbc[2],dx
	mov	al,cfgRXQUEUE
	mov	ah,0
	mov	dx,1536		; rx fragment size
	mul	dx
	mov	word ptr MacChar.trbc,ax
	mov	word ptr MacChar.trbc[2],dx
	mov	MacChar.linkspeed,10000000

	xor	ax,ax
	mov	PMparm.PMCode,RegisterModule	; opcode 2
	mov	word ptr PMparm.PMPtr1,offset CommonChar
	mov	word ptr PMparm.PMPtr1[2],ds
	mov	word ptr PMparm.PMPtr2,ax
	mov	word ptr PMparm.PMPtr2[2],ax
	mov	PMparm.PMWord,ax

	push	ax
	push	ax
	push	ds
	push	offset PMparm
	push	ProtManCode
	push	LanManCat
	push	[handle_Protman]
	call	Dos16DevIOCtl

	neg	ax
	sbb	ax,ax
	inc	ax
	retn
_RegisterModule	endp


_ScanConfigImage	proc	near
	mov	[PMparm.PMCode],GetProtManInfo	; opcode 1
	push	0
	push	0		; data (NULL)
	push	ds
	push	offset PMparm	; parameter
	push	ProtManCode	; function 58h
	push	LanManCat	; category 81h
	push	word ptr [handle_Protman]
	call	Dos16DevIOCtl
	or	ax,ax
	mov	dx,offset msg_ProtIOCtl
	jnz	short loc_e1
	cmp	[PMparm.PMWord],ProtManLevel	; level 1
	jz	short loc_0
	mov	dx,offset msg_ProtLevel
loc_e1:
	push	dx
	call	_PutMessage
	pop	dx
	xor	ax,ax
	retn


loc_0:
	push	bp
	push	si
	push	di
	push	gs
	cld
			; --- scan driver name ---
			; es:bx = module,  es:bp = keyword
	lgs	bx,[PMparm.PMPtr1]
loc_Module:
	mov	ax,gs
	mov	es,ax
	lea	bp,[bx].ModuleConfig.Keyword1

loc_NameKey:
	mov	si,offset Key_DRIVERNAME	; 'DRIVERNAME'
	mov	cx,12/4
	lea	di,[bp].KeywordEntry.Keyword
	repz	cmpsd
	jnz	short loc_NextNameKey
	lea	di,[bp].KeywordEntry.cmiParam1
	cmp	es:[di].cmiParam.ParamType,1	; type is string?
	jnz	short loc_NextModule
	mov	cx,es:[di].cmiParam.ParamLen
	mov	si,offset TmpDrvName
	lea	di,[di].cmiParam.Param
	repz	cmpsb
	jz	short loc_found_drv

loc_NextModule:
	cmp	gs:[bx].ModuleConfig.NextModule,0
	jz	short loc_NoModule
	lgs	bx,gs:[bx].ModuleConfig.NextModule
	jmp	short loc_Module

loc_NextNameKey:
	cmp	es:[bp].KeywordEntry.NextKeyword,0
	jz	short loc_NextModule
	les	bp,es:[bp].KeywordEntry.NextKeyword
	jmp	short loc_NameKey


loc_found_drv:
	mov	di,offset CommonChar.cctname
	lea	si,[bx].ModuleConfig.ModuleName
	mov	cx,16/4
	push	es
	push	ds
	pop	es
			; set ModuleName in common char. table
	rep	movsd	es:[di],gs:[si]
	pop	es

loc_KeyM:
	cmp	es:[bp].KeywordEntry.NextKeyword,0
	jz	short loc_KeyEnd
	les	bp,es:[bp].KeywordEntry.NextKeyword

	mov	bx,offset DrvKeyword1
loc_KeyD:
	lea	di,[bp].KeywordEntry.Keyword
	mov	si,[bx].cfgKeyDesc.KeyStrPtr
	mov	cx,[bx].cfgKeyDesc.KeyStrLen
	repz	cmpsb
	jnz	short loc_KeyD1
	call	word ptr [bx].cfgKeyDesc.KeyProc
	jnc	short loc_KeyM
	jmp	short loc_BadKey

loc_KeyD1:
	mov	bx,[bx].cfgKeyDesc.NextKey
	or	bx,bx
	jnz	short loc_KeyD
	jmp	short loc_UnknownKey

loc_UnknownKey:
	or	cfgKeyWarn,mask cwUnk	; Warning: Unknown
	jmp	short loc_KeyM

loc_NoModule:
	mov	dx,offset msg_NoModule
loc_BadKey:
;	push	dx
;	call	_PutMessage
;	add	sp,2
	xor	ax,ax
	jmp	short loc_scmExit

loc_KeyEnd:
	mov	ax,1
loc_scmExit:
	pop	gs
	pop	di
	pop	si
	pop	bp
	retn

; --- Keyword check ---  es:bp = KeywordEntry
sci_SLOT	proc	near
	cmp	es:[bp].KeywordEntry.NumParams,1
	jnz	short loc_ce
	cmp	es:[bp].KeywordEntry.cmiParam1.ParamType,0
	jnz	short loc_ce
	mov	al,byte ptr es:[bp].KeywordEntry.cmiParam1.Param
	cmp	al,8
	jnc	short loc_ce
	mov	cfgSLOT,al
	clc
	ret
loc_ce:
	mov	dx,offset msg_InvSLOT
	stc
	retn
sci_SLOT	endp

sci_TXQUEUE	proc	near
	cmp	es:[bp].KeywordEntry.NumParams,1
	jnz	short loc_ce
	cmp	es:[bp].KeywordEntry.cmiParam1.ParamType,0
	jnz	short loc_ce
	mov	al,byte ptr es:[bp].KeywordEntry.cmiParam1.Param
	mov	ah,10
	cmp	al,1
	jb	short loc_w
	cmp	al,4
	ja	short loc_w
	sub	ah,al
	mov	cfgTXQUEUE,al
	mov	cfgRXQUEUE,ah
loc_ex:
	clc
	retn
loc_w:
loc_ce:
	or	cfgKeyWarn,mask cwTXQ	; Warning: out of range.
	jmp	short loc_ex
sci_TXQUEUE	endp

sci_LTXQUEUE	proc	near
	cmp	es:[bp].KeywordEntry.NumParams,1
	jnz	short loc_ce
	cmp	es:[bp].KeywordEntry.cmiParam1.ParamType,0
	jnz	short loc_ce
	mov	al,byte ptr es:[bp].KeywordEntry.cmiParam1.Param
	mov	ah,2
	cmp	al,ah
	jb	short loc_w
	mov	ah,8
	cmp	al,ah
	ja	short loc_w
	mov	cfgVTXQUEUE,al
loc_ex:
	clc
	retn
loc_w:
	mov	al,ah
loc_ce:
	or	cfgKeyWarn,mask cwVTXQ	; Warning: out of range.
	jmp	short loc_ex
sci_LTXQUEUE	endp

sci_DPX		proc	near
	cmp	es:[bp].KeywordEntry.NumParams,1
	jnz	short loc_ce
	cmp	es:[bp].KeywordEntry.cmiParam1.ParamType,1
	jnz	short loc_ce
	mov	al,byte ptr es:[bp].KeywordEntry.cmiParam1.Param
	cmp	al,'H'
	setnz	ah		; 0,1 <- H,F
	jz	short loc_1
	cmp	al,'F'
	jnz	short loc_w
loc_1:
	mov	cfgDUPLEX,ah
loc_ex:
	clc
	retn
loc_w:
	mov	al,ah
loc_ce:
	or	cfgKeyWarn,mask cwDPX	; Warning: invalid duplex mode
	jmp	short loc_ex
sci_DPX		endp

sci_PS		proc	near
	cmp	es:[bp].KeywordEntry.NumParams,1
	jnz	short loc_ce
	cmp	es:[bp].KeywordEntry.cmiParam1.ParamType,1
	jnz	short loc_ce
	mov	al,byte ptr es:[bp].KeywordEntry.cmiParam1.Param
	cmp	al,'Y'
	setz	ah		; 0,1 <- N,Y
	jz	short loc_1
	cmp	al,'N'
	jnz	short loc_w
loc_1:
	mov	cfgPAUSE,ah
loc_ex:
	clc
	retn
loc_w:
	mov	al,ah
loc_ce:
	or	cfgKeyWarn,mask cwPS	; Warning: invalid pause enable
	jmp	short loc_ex
sci_PS		endp

sci_IRQ15O	proc	near
	cmp	es:[bp].KeywordEntry.NumParams,1
	jnz	short loc_ce
	cmp	es:[bp].KeywordEntry.cmiParam1.ParamType,1
	jnz	short loc_ce
	mov	al,byte ptr es:[bp].KeywordEntry.cmiParam1.Param
	cmp	al,'Y'
	setz	ah		; 'Y'->1  'N'->0
	jz	short loc_y
	cmp	al,'N'
	jnz	short loc_w
loc_n:
loc_y:
	mov	al,0
	xchg	al,ah
	shl	ax,df_i15o
	and	[drvflags],not (mask df_i15o)
	or	[drvflags],ax
loc_ex:
	clc
	retn
loc_ce:
loc_w:
	or	cfgKeyWarn,mask cwI15O ; Warning: Invalid IRQ15OVR.
	jmp	short loc_ex
sci_IRQ15O	endp

sci_NETADR	proc	near
	push	si
	push	di
	cmp	es:[bp].KeywordEntry.NumParams,1
	jnz	short loc_ce
	cmp	es:[bp].KeywordEntry.cmiParam1.ParamType,1	; string
	jnz	short loc_ce
	cmp	es:[bp].KeywordEntry.cmiParam1.ParamLen,12
	jc	short loc_ce
	xor	si,si
	xor	di,di
loc_0:
	mov	al,byte ptr es:[bp+si].KeywordEntry.cmiParam1.Param
	sub	al,'0'
	jc	short loc_w
	cmp	al,9
	jna	short loc_1
	and	al,1fh
	sub	al,'A'-'0'-10
	cmp	al,0fh
	ja	short loc_w
loc_1:
	shl	ax,4+8
	mov	al,byte ptr es:[bp+si+1].KeywordEntry.cmiParam1.Param
	sub	al,'0'
	jc	short loc_w
	cmp	al,9
	jna	short loc_2
	and	al,1fh
	sub	al,'A'-'0'-10
	cmp	al,0fh
	ja	short loc_w
loc_2:
	or	al,ah
	mov	MacChar.mctcsa[di],al
	add	si,2
	inc	di
	cmp	si,2*6
	jc	short loc_0

	test	byte ptr MacChar.mctcsa,1
	jnz	short loc_w	; multicast/broadcast
loc_ex:
	pop	di
	pop	si
	clc
	retn
loc_ce:
loc_w:
	xor	ax,ax
	mov	word ptr MacChar.mctcsa,ax
	mov	word ptr MacChar.mctcsa[2],ax
	mov	word ptr MacChar.mctcsa[4],ax
	or	cfgKeyWarn,mask cwNETADR	; Warning: Invalid address.
	jmp	short loc_ex
sci_NETADR	endp

_ScanConfigImage	endp


_AllocGDT	proc	near
	enter	4,0
	push	di
	push	es
	push	ss
	pop	es
	lea	di,[bp-4]
	mov	cx,2
	mov	dl,DevHlp_AllocGDTSelector
	call	dword ptr [DevHelp]
	jc	short loc_err
	mov	ax,[bp-4]
	mov	cx,[bp-2]
	mov	[TxCopySel],ax
	mov	[RxCopySel],cx
loc_err:
	setnc	al
	mov	ah,0
	pop	es
	pop	di
	leave
	retn
_AllocGDT	endp

_ReleaseGDT	proc	near
	mov	ax,[TxCopySel]
	mov	dl,DevHlp_FreeGDTSelector
	call	dword ptr [DevHelp]
	mov	ax,[RxCopySel]
	mov	dl,DevHlp_FreeGDTSelector
	call	dword ptr [DevHelp]
	retn
_ReleaseGDT	endp


_InitQueue	proc	near
	enter	2,0
	mov	bl,[cfgTXQUEUE]
	mov	bh,0
	mov	[TxCount],bx
	mov	al,40h
loc_1:
	mov	[TxPageStart][bx-1],al
	add	al,6
	dec	bx
	jnz	short loc_1

	mov	[RxPageStart],al
	mov	[RxPageStop],80h
	mov	al,[cfgVTXQUEUE]
	xchg	ax,bx
	mov	[bp-2],bl
	
	mov	[TxPageMask],ax
	mov	[VTxFreeHead],ax
	mov	[VTxHead],ax
	mov	[VTxCopyHead],ax
	mov	[VTxInProg],ax

	push	0
	push	sizeof(vtxd)
loc_2:
	call	_AllocHeap
	cmp	[VTxFreeHead],0
	jnz	short loc_3
	mov	[VTxFreeHead],ax
	jmp	short loc_4
loc_3:
	mov	bx,[VTxFreeTail]
	mov	[bx].vtxd.vlink,ax
loc_4:
	mov	[VTxFreeTail],ax
	dec	byte ptr [bp-2]
	jnz	short loc_2

	leave
	mov	ax,1
	retn

; pheap AllocHeap( ushort size, ushort align);
_AllocHeap	proc	near
	push	bp
	mov	bp,sp
	push	cx
	push	dx
	mov	cx,[bp+4]	; size
	mov	bp,[bp+6]	; alignment
	bsf	ax,bp
	jz	short loc_ok	; no alignment
	bsr	dx,bp
	sub	ax,dx
	jnz	short loc_e	; alignment error
	cmp	cx,4096
	ja	short loc_e	; > page size
	mov	ax,[HeapEnd]
	mov	dx,bp
	add	ax,word ptr [DS_Lin]
	dec	dx
	and	ax,dx
	jz	short loc_1	; alignment ok
	sub	ax,bp
	sub	[HeapEnd],ax	; alignment adjust
loc_1:
	mov	ax,[HeapEnd]
	mov	dx,cx
	add	ax,word ptr [DS_Lin]
	dec	dx
	mov	bp,ax
	add	ax,dx
	xor	ax,bp
	test	ax,-1000h	; in a page
	jz	short loc_ok
	and	bp,0fffh
	sub	bp,1000h
	sub	[HeapEnd],bp	; page top
loc_ok:
	mov	ax,[HeapEnd]
	add	[HeapEnd],cx

	push	cx
	push	ds
	push	ax
	call	_ClearMemBlock
	pop	ax
	add	sp,4
	clc
loc_ex:
	pop	dx
	pop	cx
	pop	bp
	retn
loc_e:
	xor	ax,ax
	stc
	jmp	short loc_ex
_AllocHeap	endp

_ClearMemBlock	proc	near
	push	bp
	mov	bp,sp
	push	eax
	push	cx
	push	dx
	push	di
	push	es

	cld
	les	di,[bp+4]
	mov	cx,[bp+8]
	mov	dx,cx
	xor	eax,eax
	shr	cx,2
	jz	short loc_1
	rep	stosd
loc_1:
	mov	cx,dx
	and	cx,3
	jz	short loc_2
	rep	stosb
loc_2:
	pop	es
	pop	di
	pop	dx
	pop	cx
	pop	eax
	pop	bp
	retn
_ClearMemBlock	endp
_InitQueue	endp

;_AllocCtxHook	proc	near
;	mov	eax,offset CtxEntry
;	or	ebx,-1
;	mov	dl,DevHlp_AllocateCtxHook
;	call	dword ptr [DevHelp]
;	jc	short loc_e
;	mov	[CtxHandle],eax
;	mov	ax,1
;	retn
;loc_e:
;	xor	ax,ax
;	retn
;_AllocCtxHook	endp

_SetDrvEnv	proc	near
	push	esi
	xor	cx,cx
	mov	al,DHGETDOSV_SYSINFOSEG
	mov	dl,DevHlp_GetDOSVar
	call	dword ptr [DevHelp]
	jc	short loc_e
	mov	es,ax
	mov	ax,es:[bx]
	mov	[SysSel],ax

	xor	esi,esi
	mov	ax,ds
	mov	dl,DevHlp_VirtToLin
	call	dword ptr [DevHelp]
	jc	short loc_e
	mov	[DS_Lin],eax
	mov	ax,1
loc_ex:
	pop	esi
	retn
loc_e:
	xor	ax,ax
	jmp	short loc_ex
_SetDrvEnv	endp

_PutMessage	proc	near
	mov	bx,sp
	xor	ax,ax
	mov	bx,ss:[bx+2]
	mov	cx,256
	mov	dx,bx
loc_1:
	cmp	al,[bx]
	jz	short loc_3
	inc	bx
	dec	cx
	jnz	short loc_1
loc_2:
	retn
loc_3:
	sub	bx,dx
	jz	short loc_2
	push	1	; file handle (STDOUT)
	push	bx	; message length
	push	ds
	push	dx	; message buffer
	call	Dos16PutMessage
	retn
_PutMessage	endp

_TEXT	ends
end
