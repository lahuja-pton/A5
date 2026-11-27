//----------------------------------------------------------------------
// bigintadd.s
// Author: Lakshit Ahuja 
//----------------------------------------------------------------------

        .equ    MAX_DIGITS, 32768

        .equ    FALSE, 0
        .equ    TRUE, 1
        
//----------------------------------------------------------------------
        .section .rodata

//----------------------------------------------------------------------
        .section .data

//----------------------------------------------------------------------
        .section .bss

//----------------------------------------------------------------------
        .section .text

        // Structure field offsets:
        .equ    LLENGTH, 0
        .equ    AULDIGITS, 8

        // Offset sizes to save registers:
        .equ    oldX19, 8
        .equ    oldX20, 16
        .equ    oldX21, 24
        .equ    oldX24, 48
        .equ    oldX25, 56

        //--------------------------------------------------------------
        // Assign the sum of oAddend1 and oAddend2 to oSum.  oSum should 
        // be distinct from oAddend1 and oAddend2.  Return 0 (FALSE) if 
        // an overflow occurred, and 1 (TRUE) otherwise.
        // int BigInt_add(BigInt_T oAddend1, BigInt_T oAddend2, BigInt_T oSum)
        //--------------------------------------------------------------

        // multiple of 16
        .equ    BIG_INT_ADD_STACK_BYTECOUNT, 64

        // Registers for parameters:
        OADDEND1    .req x19
        OADDEND2    .req x20
        OSUM        .req x21

        // Registers for local variables:
        LINDEX      .req x24
        LSUMLENGTH  .req x25

        .global BigInt_add

BigInt_add:
        // Prolog
        sub     sp, sp, BIG_INT_ADD_STACK_BYTECOUNT
        str     x30, [sp]
        str     x19, [sp, oldX19]
        str     x20, [sp, oldX20]
        str     x21, [sp, oldX21]
        str     x24, [sp, oldX24]
        str     x25, [sp, oldX25]
        mov     OADDEND1, x0
        mov     OADDEND2, x1
        mov     OSUM, x2

        // if (oAddend1->lLength > oAddend2->lLength) goto elseL1Bigger;
        ldr     x0, [OADDEND1, LLENGTH]
        ldr     x1, [OADDEND2, LLENGTH]
        cmp     x0, x1
        bgt     elseL1Bigger

        // lSumLength = oAddend2->lLength
        mov     LSUMLENGTH, x1

        // goto endifL1Bigger
        b       endifL1Bigger

elseL1Bigger:
        // lSumLength = oAddend1->lLength
        mov     LSUMLENGTH, x0

endifL1Bigger:
        // if (oSum->lLength <= lSumLength) goto endifBigIntAdd1
        ldr     x0, [OSUM, LLENGTH]
        cmp     x0, LSUMLENGTH
        ble     endifBigIntAdd1
      
        // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
        add     x0, OSUM, AULDIGITS
        mov     x1, 0
        mov     x2, MAX_DIGITS
        lsl     x2, x2, 3
        bl      memset

endifBigIntAdd1:
        // lIndex = 0;
        mov     LINDEX, 0

        // set carry flag to 0
        adds    xzr, xzr, xzr

        // if (lSumLength == 0) goto endLoopBigIntAdd1;
        cbz     LSUMLENGTH, endLoopBigIntAdd1

        // remaining digit counter
        mov     x4, LSUMLENGTH

loopBigIntAdd1:
        // oSum->aulDigits[lIndex] = oAddend1->aulDigits[lIndex] + oAddend2->aulDigits[lIndex];
        add     x0, OADDEND1, AULDIGITS
        ldr     x0, [x0, LINDEX, lsl 3]
        add     x1, OADDEND2, AULDIGITS
        ldr     x1, [x1, LINDEX, lsl 3]
        adcs    x2, x0, x1
        add     x3, OSUM, AULDIGITS
        str     x2, [x3, LINDEX, lsl 3]

        // lIndex++;
        add     LINDEX, LINDEX, 1
        sub     x4, x4, 1

        // if (loop counter != 0) goto loopBigIntAdd1
        cbnz    x4, loopBigIntAdd1

endLoopBigIntAdd1:
        // if (carry == 0) goto endifBigIntAdd4;
        bcc     endifBigIntAdd4

        // if (lSumLength != MAX_DIGITS) goto endifBigIntAdd5;
        cmp     LSUMLENGTH, MAX_DIGITS
        bne     endifBigIntAdd5

        // set return value to FALSE and go to Epilog
        mov     x0, FALSE
        b       Epilog

endifBigIntAdd5:
        // oSum->aulDigits[lSumLength] = 1;
        add     x0, OSUM, AULDIGITS
        mov     x1, 1
        str     x1, [x0, LSUMLENGTH, lsl 3]

        // lSumLength++;
        add     LSUMLENGTH, LSUMLENGTH, 1

endifBigIntAdd4:
        // oSum->lLength = lSumLength;
        str     LSUMLENGTH, [OSUM, LLENGTH]

        // set return value to TRUE
        mov     x0, TRUE

Epilog:
        ldr     x30, [sp]
        ldr     x19, [sp, oldX19]
        ldr     x20, [sp, oldX20]
        ldr     x21, [sp, oldX21]
        ldr     x24, [sp, oldX24]
        ldr     x25, [sp, oldX25]
        add     sp, sp, BIG_INT_ADD_STACK_BYTECOUNT
        ret

        .size   BigInt_add, (. - BigInt_add)
        