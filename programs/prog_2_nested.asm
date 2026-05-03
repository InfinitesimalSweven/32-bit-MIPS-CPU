# prog_2_nested.asm
# Computes (a^2 + b^2) where a=4, b=6
# Expected: 16 + 36 = 52 stored at address 84

main:
    addi $sp, $zero, 240    # set stack pointer to top of usable memory
    addi $a0, $zero, 4      # a = 4
    addi $a1, $zero, 6      # b = 6
    jal average_of_squares
    sw $v0, 84($zero)       # store result (52)
    sw $zero, 252($zero)    # halt

square:
    mult $a0, $a0
    mflo $v0
    jr $ra

average_of_squares:
    addi $sp, $sp, -12
    sw $ra, 8($sp)          # save return address
    sw $a0, 4($sp)          # save a
    sw $a1, 0($sp)          # save b

    jal square              # square(a), result in $v0
    add $t0, $zero, $v0     # t0 = a^2

    lw $a0, 0($sp)          # load b into $a0 for square
    jal square              # square(b), result in $v0
    add $v0, $t0, $v0       # v0 = a^2 + b^2

    lw $ra, 8($sp)          # restore return address
    addi $sp, $sp, 12       # restore stack pointer
    jr $ra