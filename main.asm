.INCLUDE "header.asm"
.INCLUDE "decompression.asm"
.INCLUDE "gfx.asm"
.BANK 0
.ORG 0
.SECTION "main" SEMIFREE
NMI:
	rti
IRQ:
	rti
Reset:
	;This code is a optimized copy from Kirby Super Star
	sei
	clc
	xce
	sep #$20
.ACCU 8
	rep #$10
.INDEX 16
	ldx #$1FFF
	ldy #$0000
	txs
	phk
	plb
	lda #$01
	sta $4200
	rep #$20
	lda #$2100
	tcd
	sep #$20
	ldx #$038F
	stx $00
	ldx #$8000
	stx $02
	stz $04
	stz $04
	lda #$01
	sta $05
	stz $06
	sty $0D
	sty $0D
	sty $0F
	sty $0F
	sty $11
	sty $11
	sty $13
	sty $13
	lda #$80
	sta $15
	sty $16
	stz $1A
	sty $1B
	iny
	sty $1B
	dey
	sty $1D
	sty $1D
	sty $1F
	sty $1F
	stz $21
	sty $23
	sty $25
	sty $27
	sty $29
	ldx #$1000
	stx $2B
	sty $2E
	ldx #$0030
	stx $30
	ldx #$00E0
	stx $32
	rep #$20
	lda #$4200
	tcd
	ldx #$FF00
	stx $00
	sty $02
	sty $04
	sty $06
	sty $08
	sty $0A
	sty $0C
	lda #$2200
	tcd
	sep #$20
	ldx #$0020
	stx $00 ;Reset SA1 and disable SA1-Ints
	lda #$A0
	sta $02 ;Clear all sa1 ints
	lda #$04
	sta $20
	ina
	sta $21
	ina
	sta $22
	ina
	sta $23 ;Mapped banks
	stz $24
	dea
	dea
	sta $28
	lda #$80
	sta $26
	lda #$FF
	sta $29
	sty $3000 ;3000=Command
	stz $3002 ;3001-3002=Argument
.INDEX 16
	ldx.w SA1Reset
	stx $03 ;Reset addr
	stz $00 ;Release SA1
	;That section is widely undocumented. What it does is, that every register is cleared and the write protection is turned off
	;MB1 is mapped to $00-$1F:$8000-$FFFF
	;MB2 is mapped to $20-$3F:$8000-$FFFF
	;MB3 is mapped to $80-$9F:$8000-$FFFF
	;MB4 is mapped to $A0-$BF:$8000-$FFFF
	;MB5 is mapped to $C0-$CF:$0000-$FFFF
	;MB6 is mapped to $D0-$DF:$0000-$FFFF
	;MB7 is mapped to $E0-$EF:$0000-$FFFF
	;MB8 is mapped to $F0-$FF:$0000-$FFFF
	lda #$FF
loop:
	dea
	bne loop
	ldx #$80D8
	stx $3011
	lda #$15
	sta $3013
	ldx #$0000
	stx $3014
	lda #$60
	sta $3016
	lda #$02
	sta $3010
	lda #$0F
	sta $2200
	lda #$01
	jsl WaitForSA1
deadloop:
	bra deadloop
SA1Reset:
	sei
	clc
	xce
	rep #$30
	lda #$0000
	tcd
	stz $00
	stz $02
	stz $04
	stz $06
	stz $2209 ;Clear the snes control register
	stz $2225 ;Map area 0 of bwram
	lda #$80
	sta $2227 ;Turn off bwram protection
	stz $222A ;Turn off IRAM-Protection
	stz $2230 ;Turn off DMA
	rep #$30
	;Init Game Variables
	stz $0590
	jsl ClearOAMXSize
	jsl ClearUnusedOAM
	stz $071D
	stz $071F
	stz $0721
	stz $00
	stz $01
	stz $85
	lda #$0003
	sta $52
	lda #$0180
	sta $54
	stz $57
	stz $59
	stz $5C
	stz $5E
	stz $60
	stz $62
	stz $64
	stz $66
	lda #$1000
	sta $68
	sta $6B
	sta $6D
	stz $71
	lda #$4020
	sta $74
	lda #$0095
	sta $76
	sep #$20
	;Sync CPU with SA1
	lda #$0F
	jsl WaitForSNES
	jmp deadloop ;Write code for it later!
ClearOAMXSize: ;Going to be SA1
	phx
	php
	rep #$30
	ldx #$001E
	stz $0570
OAMXSizeClearLoop:
	stz $0570,X
	dex
	dex
	bne OAMXSizeClearLoop
	plp
	plx
	rtl
ClearUnusedOAM: ;Going to be SA1
	php
	rep #$30
	lda $0590
	cmp.W #$0200
	bcs ClearUnusedOAMDone
	adc #$0370
	tax
ClearUnusedOAMLoop:
	stz $00,X
	inx
	inx
	inx
	inx
	cmp.W #$0571
	bne ClearUnusedOAMLoop
ClearUnusedOAMDone:
	stz $0590
	plp
	rtl
WaitForSNES:;SA1
	pha
	phx
	phy
	sep #$20
	rep #$10
WaitForSNES_Loop:
	cmp $2301 ;Wait until message for SA1 equals
	bne WaitForSNES_Loop
	ldy $3011
	lda $3010
	tax
	jmp (CommandList,X) ;Sadly only in bank 0
WaitForSA1: ;This routine will be copied to wram $7E:0000
;The RAM variant is for actions that the sa1 should to with full 10 mhz
;Calling this function directly is for 5MHz (or 10MHz if SA1 is in IRAM or BWRAM)
	pha
	phx
	phy
	php
	sep #$20
	rep #$10
WaitForSA1_Loop:
	cmp $2300 ;Wait until message for SNES equals to F
	bne WaitForSA1_Loop
	ldy $3001
	lda $3000
	asl
	tax
	jmp (CommandList,X) ;Sadly only in bank 0
Return:
	plp
	plx
	plx
	pla
	rtl
Jumpto:
	jmp ($3001)
CommandList:
.dw Return
.dw Jumpto
.dw Decomp
.ENDS
