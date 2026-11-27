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
        .equ    oldX22, 32
        .equ    oldX23, 40
        .equ    oldX24, 48
        .equ    oldX25, 56

        //-------------------------------------------------------------
        // Return the larger of lLength1 and lLength2.
        // static long BigInt_larger(long lLength1, long lLength2)
        //-------------------------------------------------------------

        // multiple of 16
        .equ    BIG_INT_LARGER_STACK_BYTECOUNT, 32

        // Registers for parameters:
        LLENGTH1    .req x19
        LLENGTH2    .req x20

        // Registers for local variables:
        LLARGER     .req x21

BigInt_larger:
        // Prolog
        sub     sp, sp, BIG_INT_LARGER_STACK_BYTECOUNT
        str     x30, [sp]
        str     x19, [sp, oldX19]
        str     x20, [sp, oldX20]
        str     x21, [sp, oldX21]
        mov     LLENGTH1, x0
        mov     LLENGTH2, x1

        // if (lLength1 <= lLength2) goto elseBigIntLarger1
        cmp     LLENGTH1, LLENGTH2
        ble     elseBigIntLarger1

        // lLarger = lLength1;
        mov     LLARGER, LLENGTH1

        // goto endifBigIntLarger1
        b       endifBigIntLarger1

elseBigIntLarger1:
        // lLarger = lLength2;
        mov     LLARGER, LLENGTH2

endifBigIntLarger1:
        // Epilog and return lLarger
        mov     x0, LLARGER
        ldr     x30, [sp]
        ldr     x19, [sp, oldX19]
        ldr     x20, [sp, oldX20]
        ldr     x21, [sp, oldX21]
        add     sp, sp, BIG_INT_LARGER_STACK_BYTECOUNT
        ret

        .size   BigInt_larger, (. - BigInt_larger)

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
        ULCARRY     .req x22
        ULSUM       .req x23
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
        str     x22, [sp, oldX22]
        str     x23, [sp, oldX23]
        str     x24, [sp, oldX24]
        str     x25, [sp, oldX25]
        mov     OADDEND1, x0
        mov     OADDEND2, x1
        mov     OSUM, x2

        // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
        ldr     x0, [OADDEND1, LLENGTH]
        ldr     x1, [OADDEND2, LLENGTH]
        bl      BigInt_larger
        mov     LSUMLENGTH, x0


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
        // ulCarry = 0;
        mov     ULCARRY, 0

        // lIndex = 0;
        mov     LINDEX, 0

loopBigIntAdd1:
        // if (lIndex >= lSumLength) goto endLoopBigIntAdd1;
        cmp     LINDEX, LSUMLENGTH
        bge     endLoopBigIntAdd1

        // ulSum = ulCarry;
        mov     ULSUM, ULCARRY

        // ulCarry = 0;
        mov     ULCARRY, 0

        // ulSum += oAddend1->aulDigits[lIndex];
        add     x0, OADDEND1, AULDIGITS
        ldr     x0, [x0, LINDEX, lsl 3]
        add     ULSUM, ULSUM, x0

        // if (ulSum >= oAddend1->aulDigits[lIndex]) goto endifBigIntAdd2;
        cmp     ULSUM, x0
        bhs     endifBigIntAdd2

        // ulCarry = 1;
        mov     ULCARRY, 1

endifBigIntAdd2:
        // ulSum += oAddend2->aulDigits[lIndex];
        add     x0, OADDEND2, AULDIGITS
        ldr     x0, [x0, LINDEX, lsl 3]
        add     ULSUM, ULSUM, x0

        // if (ulSum >= oAddend2->aulDigits[lIndex]) goto endifBigIntAdd3;
        cmp     ULSUM, x0
        bhs     endifBigIntAdd3

        // ulCarry = 1;
        mov     ULCARRY, 1

endifBigIntAdd3:
        // oSum->aulDigits[lIndex] = ulSum;
        add     x0, OSUM, AULDIGITS
        str     ULSUM, [x0, LINDEX, lsl 3]

        // lIndex++;
        add     LINDEX, LINDEX, 1

        // goto loopBigIntAdd1;
        b       loopBigIntAdd1

endLoopBigIntAdd1:
        // if (ulCarry != 1) goto endifBigIntAdd4;
        cmp     ULCARRY, 1
        bne     endifBigIntAdd4

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
        ldr     x22, [sp, oldX22]
        ldr     x23, [sp, oldX23]
        ldr     x24, [sp, oldX24]
        ldr     x25, [sp, oldX25]
        add     sp, sp, BIG_INT_ADD_STACK_BYTECOUNT
        ret

        .size   BigInt_add, (. - BigInt_add)
        