.global main
main:

    @ Output welcome message
    ldr r0, =welcome
    bl printf

    @ Generate random number
    mov r0, #0
    bl time
    bl srand
    bl rand

    and r0, r0, #15     @ Limits to first 4 bits (up to 15)
    @ Compares random number to 9 and if greater than, minus 9
    cmp r0, #9          
    subgt r0, r0, #9

    @ Load address of answer and array of answers into r3 and r1
    ldr r1, =answers    
    ldr r3, =answer
    cmp r0, #0
    beq write_to_answer @ If random number is 0 go to write_to_answer

possible_answers:
@ Loops through possible answers until at the answer selected by the random number
    ldrb r2, [r1], #1   @ Load next character from answers into r2 (and increment r1)
    cmp r2, #0
    subeq r0, r0, #1    @ If at the end of a string, take 1 off of random number
    cmp r0, #0
    bne possible_answers    @ Go back to start of possible_answers if not at the selected word yet

    
    ldr r0, =answer
    ldr r6, =blank_answer
    mov r4, #0
    mov r5, #0      @ Misses counter
    mov r8, #0		@ Counter for length

    @ Reset misses to being empty
    ldr r9, =misses
    str r4, [r9], #4
    str r4, [r9]
    @ Load underscore into r9 to write to blank_answer
    ldr r9, =underscore
    ldrb r9, [r9]


write_to_answer:
@ Writes the string from the answers array to answer and puts underscores into blank_answer
    ldrb r2, [r1], #1   @ Load next character from answers into r2
    cmp r2, #0          @ Check if at the end of the string
    strneb r2, [r3], #1 @ Store character in r2 into r3 (and increment r3) for each letter
    strneb r9, [r6]     @ Put an underscore into blank_answer for each letter
    addne r8, r8, #1	@ Increment length counter
    streqb r4, [r3]		@ Load 0 into answer at end of string
    streqb r4, [r6]		@ Load 0 into blank_answer at end of string
    add r6, r6, #1      @ Increment r6 on to next character
    bne write_to_answer @ Go to write_to_answer if not at the end of the string


game_loop:

    @ Call functions for output between guesses and to take user input
    bl output_between
    bl scanf_function

    @ Makes sure processed input is A-Z, if not print invalid_input and go back to game_loop
    ldr r0, =invalid_input
    mov r6, #0      @ Keeps track of whether input was invalid as comparison isn't saved through printf function
    cmp r1, #65		@ Compares input with 60 (ASCII for A)
    movlt r6, #1
    bllt printf
    cmp r1, #90		@ Compares input with 90 (ASCII for Z)
    movgt r6, #1
    blgt printf
    @ If input was invalid, go to game_loop
    cmp r6, #1
    beq game_loop


    @ Loading required addresses into registers
    ldr r3, =answer
    ldr r6, =blank_answer
    mov r2, #0		        @ Keeps track of if letters replaced
    mov r9, #0		        @ Keeps track of total letters replaced


answer_loop:

    ldrb r4, [r3], #1	@ Load value at next character from answer into r4
    cmp r4, #0		    @ Check if at end of string
    cmpeq r2, #1		@ If at end of string, check if guess has replaced anything
    bmi misses_add		@ If at end, and none replaced go to misses_add
    beq game_loop		@ If at end and at least 1 replaced, go to game_loop
    
    cmp r4, r1		    @ Compare character in answer with user input
    moveq r2, #1		@ Increment tracker for if underscore in blank_answer replaced (Done before replacing in case of repeats)
    ldreqb r9, [r6]		@ Load value from blank_answer to r9
    cmpeq r9, #0x5f		@ Check if value in blank_answer is an underscore
    streqb r1, [r6]		@ If equal, store input to place in blank_answer
    add r6, r6,  #1		@ Increment offset of blank_answer

    subeq r8, #1		@ Take 1 off of length for when letter successfully guessed
    cmpeq r8, #0		@ Compare number left to guess with 0
    bleq output_between
    ldreq r0, =win		@ Load string for victory into r0
    bleq printf		    @ Print victory string
    beq play_again		@ Go to play again loop
    b answer_loop		@ Go to answer_loop if not equal


misses_add:

    push {r5}
    mov r5, #0		    @ Counter for length of misses
    ldr r0, =misses		@ Load address of missed guesses into r8

misses_loop:

    ldrb r2, [r0]		@ Load next value of misses into r2
    cmp r2, r1		    @ Compare value of misses with guess

    ldreq r0, =already_guessed
    bleq printf

    popeq {r5}              @ If equal, put the previous value back into r5
    beq game_loop		    @ If equal, go to game_loop

    cmp r2, #0		        @ Check if at end of misses
    streqb r1, [r0]		    @ If at the end, add guess to misses
    addeq r5, r5, #1	    @ Add 1 to counter for length of misses

    cmpeq r5, #6		    @ Compare counter to 6
    bleq output_between     @ Print the output once more before displaying loss
    ldreq r0, =lose
    ldreq r1, =answer
    bleq printf
    beq play_again		    @ Exit if length of misses is 6
    
    cmp r2, #0
    beq game_loop		    @ If at end of string go to game_loop
    add r0, r0, #1		    @ Increment offset
    add r5, r5, #1		    @ Add 1 to counter for length of misses
    
    b misses_loop


play_again:

    ldr r0, =again_message	    @ Load again_message into r0
    bl printf		            @ Print out again_message
    bl scanf_function           @ Call function to take user input
    cmp r1, #89		            @ Compare user input to 89 (ASCII for Y)
    beq main		            @ If input was Y go back to start of program
    cmp r1, #78		            @ Compare user input to 78 (ASCII for N)
    ldrne r0, =invalid_input    @ If not Y or N load invalid input into r0
    ldreq r0, =goodbye	        @ If N load goodbye message into r0
    push {r1}
    blne printf		            @ Print r0
    pop {r1}
    cmp r1, #78		            @ Compare to N again as printf resets
    bne play_again		        @ If invalid input go to play_again

exit:

    mov r7, #1		@ Exit service call code
    svc #0			@ Service call

scanf_function:

    @ Takes user input
    ldr r0, =scan_format	@ Format of input
    ldr r1, =input		    @ Where to store input
    push {r1, lr}		    @ Store values in stack
    bl scanf		        @ Take input C function
    pop {r1, lr}		    @ Get values back from stack
    ldrb r1, [r1]		    @ Load value of user input into r1

    @ Go to exit if user inputs 0
    cmp r1, #48		    @ Compare value of user input with 48 (ASCII for 0)
    beq exit

    @ Change user input to upper case if lower case
    cmp r1, #90		    @ Compares user input with 90 (ASCII for Z)
    subgt r1, r1, #32	@ Lower case to upper case

    bx lr       @ Return to where called from

output_between:
    push {lr}
    ldr r0, =output1		@ Load output string for into r0
    ldr r1, =blank_answer	@ Underscored answer to r1
    ldr r2, =misses		    @ Missed guesses to r2
    mov r6, #61
    mul r4, r5, r6          @ Multiply length of misses by 61 to get to next string
    ldr r3, =missed_output
    add r3, r3, r4
    bl printf		        @ Output C function
    pop {lr}
    bx lr       @ Return to where called from

.data
welcome: .asciz "\nHangman by Zac Faulks\nType the letter you want to guess or 0 to exit.\n"
output1: .asciz "  |-----|  Word: %s\n  |     |  Misses: %s\n%s"
missed_output: .asciz "        |\n        |\n        |\n        |\n        |\n---------\n", "  0     |\n        |\n        |\n        |\n        |\n---------\n", "  0     |\n  |     |\n  |     |\n        |\n        |\n---------\n", "  0     |\n \\|     |\n  |     |\n        |\n        |\n---------\n", "  0     |\n \\|/    |\n  |     |\n        |\n        |\n---------\n", "  0     |\n \\|/    |\n  |     |\n /      |\n        |\n---------\n", "  0     |\n \\|/    |\n  |     |\n / \\    |\n        |\n---------\n"
invalid_input: .asciz "Please enter a valid option.\n"
win: .asciz "Congratulations, you win.\n"
lose: .asciz "The word was %s, better luck next time.\n"
again_message: .asciz "Play again? (Y/N)\n"
answer: .space 19
answers: .asciz "TESTS", "CHALLENGE", "UNIVERSITY", "STUDENTS", "BALANCE", "FEEDBACK", "BINARY", "INTELLIGENCE", "CARTOGRAPHERS", "CHARACTERISTICALLY"
goodbye: .asciz "Goodbye.\n"
underscore: .asciz "_"
already_guessed: .asciz "Letter already guessed.\n"
blank_answer: .space 19
scan_format: .asciz "%s" @ String
misses: .space 7
input: .byte 1
