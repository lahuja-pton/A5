//----------------------------------------------------------------------
// mywc.s
// Author: Lakshit Ahuja 
//----------------------------------------------------------------------
    
        .equ    FALSE, 0
        .equ    TRUE, 1

        .equ    EOF, -1

//----------------------------------------------------------------------
        .section .rodata

formatStr:
        .string "%7ld %7ld %7ld\n"

//----------------------------------------------------------------------
        .section .data

lLineCount:
        .quad   0
lWordCount:
        .quad   0
lCharCount:
        .quad   0
iInWord:
        .word   FALSE

//----------------------------------------------------------------------
        .section .bss

iChar: 
        .skip   4

//----------------------------------------------------------------------
        .section .text
        
        .equ    MAIN_STACK_BYTECOUNT, 16
        .global main 

main:
        // Prolog
        sub     sp, sp, MAIN_STACK_BYTECOUNT
        str     x30, [sp]

readLoop:
        // iChar = getchar()
        bl      getchar
        adr     x1, iChar
        str     w0, [x1]

        // if (iChar == EOF): goto endReadLoop;
        adr     x0, iChar
        ldr     w0, [x0]
        mov     w1, EOF
        cmp     w0, w1
        beq     endReadLoop

        // lCharCount++;
        adr     x0, lCharCount
        ldr     x1, [x0]
        add     x1, x1, 1
        str     x1, [x0]

        // if(!isspace(iChar)) goto elseSpace;
        adr     x0, iChar
        ldr     w0, [x0]
        bl      isspace
        cbz     w0, elseSpace

        // if (!iInWord) goto endIfSpace;
        adr     x0, iInWord
        ldr     w0, [x0]
        cbz     w0, endIfSpace

        // lWordCount++;
        adr     x0, lWordCount
        ldr     x1, [x0]
        add     x1, x1, 1
        str     x1, [x0]

        // iInWord = FALSE;
        adr     x0, iInWord
        mov     w1, FALSE
        str     w1, [x0]

        // goto endIfSpace;
        b endIfSpace

elseSpace:
        // if (iInWord) goto endIfSpace
        adr     x0, iInWord
        ldr     w0, [x0]
        cbnz    w0, endIfSpace

        // iInWord = TRUE;
        adr     x0, iInWord
        mov     w1, TRUE
        str     w1, [x0]

endIfSpace:
        // if (iChar != '\n') goto readLoop
        adr     x0, iChar
        ldr     w0, [x0]
        mov     w1, '\n'
        cmp     w0, w1
        bne     readLoop

        // lLineCount++;
        adr     x0, lLineCount
        ldr     x1, [x0]
        add     x1, x1, 1
        str     x1, [x0]

        // goto readLoop;
        b       readLoop

endReadLoop:
        // if (!iInWord) goto endIfWord
        adr     x0, iInWord
        ldr     w0, [x0]
        cbz     w0, endIfWord

        // lWordCount++;
        adr     x0, lWordCount
        ldr     x1, [x0]
        add     x1, x1, 1
        str     x1, [x0]

endIfWord:
        // printf("%7ld %7ld %7ld\n", 
        //         lLineCount, lWordCount, lCharCount);
        adr     x0, formatStr
        adr     x1, lLineCount
        ldr     x1, [x1]
        adr     x2, lWordCount
        ldr     x2, [x2]
        adr     x3, lCharCount
        ldr     x3, [x3]
        bl printf

        // Epilog and return 0
        ldr     x30, [sp]
        add     sp, sp, MAIN_STACK_BYTECOUNT
        mov     w0, 0
        ret

        .size   main, (. - main)
  