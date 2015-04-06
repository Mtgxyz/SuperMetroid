.BANK 0 SLOT 0
.ORG 0
.SECTION "Decompression"
;decompReq SRC, DST
;Source must be in ROM, IRAM, BWRAM
;Destination must be in IRAM, BWRAM
.MACRO decompReq
	ldx.W \1
	stx $3011
	lda.B :\1
	sta $3013
	ldx.W \2
	stx $3014
	lda.B :\2
	sta $3016
	lda #$02
	sta $3010
	lda #$0F
	sta $2200
	lda #$01
	jsl WaitForSA1
.ENDM
Decomp:
	php
	phb
	sep #$20
	rep #$10
	lda $13
	pha
	plb
	stz $18
	ldy #$0000
MainDecompLoop:
	phx
	ldx $11
	lda $0000,X
	inx
	bne DC_NoOF1
	jsr SBOF_Correction
DC_NoOF1:
	stx $11
	plx
	sta $19
	cmp #$FF ;End of File?
	bne DC_Cont
	lda #$01
	sta $2209
	plb
	plp
	ply
	plx
	pla
	rtl
DC_Cont:
	and #$E0
	cmp #$E0
	bne DC_NormalCommand
;Command 111: Extended
	lda $19 ;Get Byte Value
	asl
	asl
	asl ;Shift out command
	and #$E0
	pha
	lda $19
	and #$03
	xba ;B=High bits of length
	phx
	ldx $11
	lda $0000,X
	inx
	bne DC_NoOF2
	jsr SBOF_Correction
DC_NoOF2:
	stx $11
	plx
	bra DC_Main
DC_NormalCommand:
	pha
	lda #$00
	xba ;B=0
	lda $19
	and #$1F
DC_Main:
	tax
	inx ;X=Counter+1
	pla ;A=Command
	cmp #$00
	bpl DCC_plus
	jmp DCC_minus
DCC_plus:
	cmp #$20
	beq DCC_Bytefill
	cmp #$40
	beq DCC_Wordfill
	cmp #$60
	beq DCC_Incfill
DCC_Copy:
	phx
	ldx $11
	lda $0000,X
	inx
	bne DC_NoOF3
	jsr SBOF_Correction
DC_NoOF3:
	stx $11
	plx
	sta [$14],Y
	iny ;Destination++=A
	dex
	bne DCC_Copy
	beq MainDecompLoop ;Next!
DCC_Bytefill:
	phx
	ldx $11
	lda $0000,X
	inx
	bne DC_NoOF4
	jsr SBOF_Correction
DC_NoOF4:
	stx $11
	plx
DCC_Bytefill_Loop:
	sta [$14],Y
	iny
	dex
	bne DCC_Bytefill_Loop
	jmp MainDecompLoop
DCC_Wordfill:
	phx
	ldx $11
	lda $0000,X
	inx
	bne DC_NoOF5
	jsr SBOF_Correction
DC_NoOF5:
	xba
	lda $0000,X
	inx
	bne DC_NoOF6
	jsr SBOF_Correction
DC_NoOF6:
	stx $11
	plx
	xba
DCC_Wordfill_Loop:
	sta [$14],Y
	xba
	iny
	dex
	beq DCC_Wordfill_Out
	sta [$14],Y
	xba
	iny
	dex
	bne DCC_Wordfill_Loop
DCC_Wordfill_Out:
	jmp MainDecompLoop
DCC_Incfill:
	phx
	ldx $11
	lda $0000,X
	inx
	bne DC_NoOF7
	jsr SBOF_Correction
DC_NoOF7:
	stx $11
	plx
DCC_Incfill_Loop:
	sta [$14],Y
	ina
	iny
	dex
	bne DCC_Incfill_Loop
	jmp MainDecompLoop
DCC_minus:
	cmp #$C0
	bcs DCC_C0plus
DictionaryCopy:
	and #$20
	sta $18 ;Inverted bit
	phx
	ldx $11
	lda $0000,X
	inx
	bne DC_NoOF8
	jsr SBOF_Correction
DC_NoOF8:
	sta $19
	lda $0000,X
	inx
	bne DC_NoOF9
	jsr SBOF_Correction
DC_NoOF9:
	stx $11
	plx
	sta $1A
DictionaryCopyStart:
	sep #$20
DictionaryCopyLoop:
	phx
	phy
	ldy $19
	lda [$14],Y
	iny
	sty $19
	ply
	xba
	lda $18
	beq DictionaryCopyNoInvert
	xba
	eor #$FF
	xba
DictionaryCopyNoInvert:
	xba
	sta [$14],Y
	iny
	plx
	dex
	bne DictionaryCopyLoop
	jmp MainDecompLoop
DCC_C0plus:
	and #$20
	sta $18 ;Inverted bit
	phx
	ldx $11
	lda $0000,X
	inx
	bne DC_NoOF10
	jsr SBOF_Correction
DC_NoOF10:
	stx $11
	plx
	sta $19
	stz $1A
	rep #$20
	tya
	sec
	sbc $4A
	sta $4A
	bra DictionaryCopyStart

SBOF_Correction:
	pha
	phb
	pla
	cmp #$3F
	bmi BOF_case1
	beq BOF_case2
	cmp #$BF
	bmi BOF_case1
	ina
	ldx #$0000
BOF_back:
	pha
	plb
	pla
	rts
BOF_case1:
	ina
	ldx #$8000
	bra BOF_back
BOF_case2:
	lda #$80
	ldx #$8000
	bra BOF_back
.ENDS
