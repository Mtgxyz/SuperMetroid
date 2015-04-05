.INCLUDE "header.asm"
.BANK 0
.ORG 0
.SECTION "main" SEMIFREE
NMI:
	rti
IRQ:
	rti
Reset:
	
.ENDS
