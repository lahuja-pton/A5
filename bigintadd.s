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

        //-------------------------------------------------------------
        // Return the larger of lLength1 and lLength2.
        // static long BigInt_larger(long lLength1, long lLength2)
        //-------------------------------------------------------------

        // multiple of 16
        .equ    BIG_INT_LARGER_STACK_BYTECOUNT, 32

        // Parameter stack offsets:
        .equ    LLENGTH1, 8
        .equ    LLENGTH2, 16

        // Local variable stack offsets:
        .equ    LLARGER, 24

BigInt_larger:
        // Prolog
        sub     sp, sp, BIG_INT_LARGER_STACK_BYTECOUNT
        str     x30, [sp]
        str     x0, [sp, LLENGTH1]
        str     x1, [sp, LLENGTH2]

        // if (lLength1 <= lLength2) goto elseBigIntLarger1
        ldr     x0, [sp, LLENGTH1]
        ldr     x1, [sp, LLENGTH2]
        cmp     x0, x1
        ble     elseBigIntLarger1

        // lLarger = lLength1;
        str     x0, [sp, LLARGER]

        // goto endifBigIntLarger1
        b       endifBigIntLarger1

elseBigIntLarger1:
        // lLarger = lLength2;
        str     x1, [sp, LLARGER]

endifBigIntLarger1:
        // Epilog and return lLarger
        ldr     x0, [sp, LLARGER]
        ldr     x30, [sp]
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

        // Parameter stack offsets:
        .equ    OADDEND1, 8
        .equ    OADDEND2, 16
        .equ    OSUM, 24

        // Local variable stack offsets:
        .equ    ULCARRY, 32
        .equ    ULSUM, 40
        .equ    LINDEX, 48
        .equ    LSUMLENGTH, 56

        .global BigInt_add

BigInt_add:
        // Prolog
        sub     sp, sp, BIG_INT_ADD_STACK_BYTECOUNT
        str     x30, [sp]
        str     x0, [sp, OADDEND1]
        str     x1, [sp, OADDEND2]
        str     x2, [sp, OSUM]

        // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
        ldr     x0, [sp, OADDEND1]
        ldr     x0, [x0, LLENGTH]
        ldr     x1, [sp, OADDEND2]
        ldr     x1, [x1, LLENGTH]
        bl      BigInt_larger
        str     x0, [sp, LSUMLENGTH]

        // if (oSum->lLength <= lSumLength) goto endifBigIntAdd1
        ldr     x0, [sp, OSUM]
        ldr     x0, [x0, LLENGTH]
        ldr     x1, [sp, LSUMLENGTH]
        cmp     x0, x1
        ble     endifBigIntAdd1
      
        // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
        ldr     x0, [sp, OSUM]
        add     x0, x0, AULDIGITS
        mov     x1, 0
        mov     x2, MAX_DIGITS
        lsl     x2, x2, 3
        bl      memset

endifBigIntAdd1:
        // ulCarry = 0;
        mov     x0, 0
        str     x0, [sp, ULCARRY]

        // lIndex = 0;
        mov     x0, 0
        str     x0, [sp, LINDEX]

loopBigIntAdd1:
        // if (lIndex >= lSumLength) goto endLoopBigIntAdd1;
        ldr     x0, [sp, LINDEX]
        ldr     x1, [sp, LSUMLENGTH]
        cmp     x0, x1
        bge     endLoopBigIntAdd1

        // ulSum = ulCarry;
        ldr     x0, [sp, ULCARRY]
        str     x0, [sp, ULSUM]

        // ulCarry = 0;
        mov     x0, 0
        str     x0, [sp, ULCARRY]

        // ulSum += oAddend1->aulDigits[lIndex];
        ldr     x0, [sp, OADDEND1]
        add     x0, x0, AULDIGITS
        ldr     x1, [sp, LINDEX]
        ldr     x2, [x0, x1, lsl 3]
        ldr     x0, [sp, ULSUM]
        add     x0, x0, x2
        str     x0, [sp, ULSUM]

        // if (ulSum >= oAddend1->aulDigits[lIndex]) goto endifBigIntAdd2;
        ldr     x0, [sp, OADDEND1]
        add     x0, x0, AULDIGITS
        ldr     x1, [sp, LINDEX]
        ldr     x2, [x0, x1, lsl 3]
        ldr     x0, [sp, ULSUM]
        cmp     x0, x2
        bhs     endifBigIntAdd2

        // ulCarry = 1;
        mov     x0, 1
        str     x0, [sp, ULCARRY]

endifBigIntAdd2:
        // ulSum += oAddend2->aulDigits[lIndex];
        ldr     x0, [sp, OADDEND2]
        add     x0, x0, AULDIGITS
        ldr     x1, [sp, LINDEX]
        ldr     x2, [x0, x1, lsl 3]
        ldr     x0, [sp, ULSUM]
        add     x0, x0, x2
        str     x0, [sp, ULSUM]

        // if (ulSum >= oAddend2->aulDigits[lIndex]) goto endifBigIntAdd3;
        ldr     x0, [sp, OADDEND2]
        add     x0, x0, AULDIGITS
        ldr     x1, [sp, LINDEX]
        ldr     x2, [x0, x1, lsl 3]
        ldr     x0, [sp, ULSUM]
        cmp     x0, x2
        bhs     endifBigIntAdd3

        // ulCarry = 1;
        mov     x0, 1
        str     x0, [sp, ULCARRY]

endifBigIntAdd3:
        // oSum->aulDigits[lIndex] = ulSum;
        ldr     x0, [sp, OSUM]
        add     x0, x0, AULDIGITS
        ldr     x1, [sp, LINDEX]
        ldr     x2, [sp, ULSUM]
        str     x2, [x0, x1, lsl 3]

        // lIndex++;
        ldr     x0, [sp, LINDEX]
        add     x0, x0, 1
        str     x0, [sp, LINDEX]

        // goto loopBigIntAdd1;
        b       loopBigIntAdd1

endLoopBigIntAdd1:
        // if (ulCarry != 1) goto endifBigIntAdd4;
        ldr     x0, [sp, ULCARRY]
        mov     x1, 1
        cmp     x0, x1
        bne     endifBigIntAdd4

        // if (lSumLength != MAX_DIGITS) goto endifBigIntAdd5;
        ldr     x0, [sp, LSUMLENGTH]
        mov     x1, MAX_DIGITS
        cmp     x0, x1
        bne     endifBigIntAdd5

        // Epilog and return FALSE
        mov     x0, FALSE
        ldr     x30, [sp]
        add     sp, sp, BIG_INT_ADD_STACK_BYTECOUNT
        ret

endifBigIntAdd5:
        // oSum->aulDigits[lSumLength] = 1;
        ldr     x0, [sp, OSUM]
        add     x0, x0, AULDIGITS
        ldr     x1, [sp, LSUMLENGTH]
        mov     x2, 1
        str     x2, [x0, x1, lsl 3]

        // lSumLength++;
        ldr     x0, [sp, LSUMLENGTH]
        add     x0, x0, 1
        str     x0, [sp, LSUMLENGTH]

endifBigIntAdd4:
        // oSum->lLength = lSumLength;
        ldr     x0, [sp, OSUM]
        ldr     x1, [sp, LSUMLENGTH]
        str     x1, [x0, LLENGTH]

        // Epilog and return TRUE
        mov     x0, TRUE
        ldr     x30, [sp]
        add     sp, sp, BIG_INT_ADD_STACK_BYTECOUNT
        ret

        .size   BigInt_add, (. - BigInt_add)
        