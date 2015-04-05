#!/bin/bash
wla-65816 -o main.asm main.o
wlalink -vr proj.lnk sm.smc
printf '\x23' | dd of=sm.smc bs=1 seek=32725 count=1 conv=notrunc
dd if=sm.smc bs=32768 count=64 > tmp
dd if=sm.smc bs=192 skip=171 count=32768 >> tmp
mv tmp sm.smc
