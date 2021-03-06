; *** RTL8029AS (NE2000 compatible) definition ***

; +++ registers +++
; Page0  PS0=0, PS1=0
CR	equ	0	; rw Command
CLDA0	equ	1	; r  Current Local DMA Address 0
PSTART	equ	1	; w  Page Start Register
CLDA1	equ	2	; r  Current Local DMA Address 2
PSTOP	equ	2	; w  Page Stop Register
BNRY	equ	3	; rw Boundary Pointer
TSR	equ	4	; r  Transmit Status Register
TPSR	equ	4	; w  Transmit Page Start Address
NCR	equ	5	; r  Number of Collisions Register
TBCR0	equ	5	; w  Transmit Byte Counter 0
FIFO	equ	6	; r  FIFO
TBCR1	equ	6	; w  Transmit Byte Counter 1
ISR	equ	7	; rw Interrupt Status Register
CRDA0	equ	8	; r  Current Remote DMA Address 0
RSAR0	equ	8	; w  Remote Start Address 0
CRDA1	equ	9	; r  Current Remote DMA Address 1
RSAR1	equ	9	; w  Remote Start Address 1
_8029ID0 equ	0ah	; r  8029 Chip ID0  50h 'P'
RBCR0	equ	0ah	; w  Remote Byte Count Register 0
_8029ID1 equ	0bh	; r  8029 Chip ID1  43h 'C'
RBCR1	equ	0bh	; w  Remote Byte Count Register 1
RSR	equ	0ch	; r  Recieve Status Register
RxCR	equ	0ch	; w  Recieve Configuration Register
CNTR0	equ	0dh	; r  Tally Counter 0 (Frame Alignment errors)
TCR	equ	0dh	; w  Transmit Configuration Register
CNTR1	equ	0eh	; r  Tally Counter 1 (CRC errors)
DCR	equ	0eh	; w  Data Configuration Register
CNTR2	equ	0fh	; r  Tally Counter 2 (Missed Packet errors)
IMR	equ	0fh	; w  Interrupt Mask Register
DataPort equ	10h	; rw Data Port

; Page1  PS0=1, PS1=0
; CR	equ	0	; rw
PAR0	equ	1	; rw Physical Address Register 0
PAR1	equ	2	; rw Physical Address Register 1
PAR2	equ	3	; rw Physical Address Register 2
PAR3	equ	4	; rw Physical Address Register 3
PAR4	equ	5	; rw Physical Address Register 4
PAR5	equ	6	; rw Physical Address Register 5
CURR	equ	7	; rw Current Page Register
MAR0	equ	8	; rw Multicast Address Register 0
MAR1	equ	9	; rw Multicast Address Register 1
MAR2	equ	0ah	; rw Multicast Address Register 2
MAR3	equ	0bh	; rw Multicast Address Register 3
MAR4	equ	0ch	; rw Multicast Address Register 4
MAR5	equ	0dh	; rw Multicast Address Register 5
MAR6	equ	0eh	; rw Multicast Address Register 6
MAR7	equ	0fh	; rw Multicast Address Register 7

; Page3  PS0=1, PS1=1
CR9346	equ	1	; rw 9346 Command Register
CONFIG0	equ	3	; r  RTL8029AS Configuration Register 0
CONFIG2	equ	5	; rw RTL8029AS Configuration Register 2
CONFIG3	equ	6	; rw RTL8029AS Configuration Register 3
HLTCLK	equ	9	;  w Halt Clock Register  'R' or 'H'
_8029ASID0 equ	0eh	; r  RTL8029AS chip ID0 29h
_8029ASID1 equ	0fh	; r  RTL8029AS chip ID1 80h


; +++ Command 00h +++
STP	equ	1	; Stop
STA	equ	2	; Start
TXP	equ	4	; Transmit Packet
RD0	equ	8	; Remote DMA Command
RD1	equ	10h	; RD0: Read, RD1: Write, RD0+RD1: Send, 
RD2	equ	20h	; RD2: Abort/Complete
PS0	equ	40h	; Page Select
PS1	equ	80h	; 00b: page0, 01b: page1, 11:page3

; +++ Interrupt Status 0.07h / Mask 0.0fh +++
PRX	equ	1	; Packet Recieved
PTX	equ	2	; Packet Transmitted
RXE	equ	4	; Recieve Error
TXE	equ	8	; Transmit Error
OVW	equ	10h	; Overwrite Warning
CNT	equ	20h	; Counter Overflow
RDC	equ	40h	; Remote DMA Complete
RST	equ	80h	; Reset Status

; +++ Data Configuration 0.0eh
WTS	equ	1	; Word Transfer Select 0:byte, 1:word
BOS	equ	2	; Byte Order Select
LAS	equ	4	; Long Address Select
LS	equ	8	; Loopback Select 0:loopback, 1:normal operation
ARM	equ	10h	; Auto Initialize Remote (use Send Command)
FT0	equ	20h	; FIFO Threshold Select 00:1word, 01:2words
FT1	equ	40h	; 10:4words, 11:6words

; +++ Transmit Configuration 0.0dh +++
ICRC	equ	1	; Inhibit CRC  0:CRC appended, 1:inhibited
LB0	equ	2	; Encoded Loopback Control 00:normal, 
LB1	equ	4	; 01:NIC, 10:ENDEC, 11:external
ATD	equ	8	; Auto Transmit Disable
OFSR	equ	10h	; Collision Offset Enable

; +++ Transmit Status 0.04h +++
PTXOK	equ	1	; Packet Transmitted (without error)
COL	equ	4	; Transmit Collided
ABT	equ	8	; Transmit Aborted
CRS	equ	10h	; Carrier Sense Lost
;FU	equ	20h	; FIFO Underrun
CDH	equ	40h	; CD Heartbeat Failure
OWC	equ	80h	; Out of Window Collision

; +++ Recieve Configuration 0.0ch +++
SEP	equ	1	; Save Errored Packets
AR	equ	2	; Accept Runt Packets
AB	equ	4	; Accept Broadcast
AM	equ	8	; Accept Multicast
PRO	equ	10h	; Promiscuous Physical
MON	equ	20h	; Monitor Mode

; +++ Recieve Status 0.0ch +++
PRXOK	equ	1	; Packet Recieve Intact
CRCE	equ	2	; CRC Error
FAE	equ	4	; Frame Alignment Error
;FO	equ	8	; FIFO Overrun
MPA	equ	10h	; Missed Packet
PHY	equ	20h	; Physical/Multicast Address
DIS	equ	40h	; Reciever Disabled
DFR	equ	80h	; Deferring

; +++ 9346 Command 3.01h +++
EEDO	equ	1	; out
EEDI	equ	2	; in
EESK	equ	4	; clock
EECS	equ	8	; chip select
EEM0	equ	40h	; operating mode
EEM1	equ	80h	; 

EEM_NORMAL	equ	0		; normal operation
EEM_AUTOLOAD	equ	EEM0		; auto-load
EEM_PROGRAM	equ	EEM1		; 9346 programming
EEM_CONFIG	equ	EEM1 or EEM0	; config register 2,3 write enable

; +++ Configration 0  3.03h +++
BNC	equ	4	; using 10BASE2

; +++ Configration 2  3.05h +++
BS0	equ	1	; boot rom size  00:none  01:8K
BS1	equ	2	;  10:16K  11:32K
PF	equ	10h	; pause flag
FCE	equ	20h	; pause control enable
PL0	equ	40h	; select network medium types 00:Auto-Detect
PL1	equ	80h	; 01:10BaseT 10:10Base5 11:10Base2

; +++ Configration 3  3.06h +++
PWRDN	equ	2	; power down mode
SLEEP	equ	4	; sleep mode
LEDS0	equ	10h	; select LED pins
LEDS1	equ	20h	; 
FUDUP	equ	40h	; full-duplex mode


; +++ Receive Buffer Header +++
RxHeader	struc
RxStatus	db	?	; copy of recieve status
RxNextPtr	db	?	; next packet pointer
RxLength	dw	?	; frame length received
RxHeader	ends

; +++ Virtual Transmit Descriptor +++
vtxd		struc
vlink		dw	?	; virtual link
framelen	dw	?	; frame length
cnt		db	?	; number of buffer fragments
startpage	db	?	; transmit start page
reqhandle	dw	?	; request handle
protid		dw	?	; protocol id
txbd		TxBufDesc 9 dup(<>)	; copy of TxBufDesc
immedbuf	db	64 dup(?)	; immediate data buffer
vtxd		ends
