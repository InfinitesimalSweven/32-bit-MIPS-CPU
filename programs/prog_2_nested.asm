# prog_2_nested.asm
# Computes (a^2 + b^2) where a=4, b=6
# Expected: 16 + 36 = 52 stored at address 88

main:
    addi $sp, $zero, 240
    addi $a0, $zero, 4
    addi $a1, $zero, 6
    jal sum_of_squares
    sw $v0, 88($zero)
    sw $zero, 252($zero)    # halt

sum_of_squares:
    addi $sp, $sp, -16
    sw $ra, 12($sp)
    sw $a0, 8($sp)
    sw $a1, 4($sp)

    jal square
    sw $v0, 0($sp)
    lw $a0, 4($sp)
    jal square
    
    lw $t0, 0($sp)
    add $v0, $t0, $v0
    lw $ra, 12($sp)
    addi $sp, $sp, 16
    jr $ra

square:
    mult $a0, $a0
    mflo $v0
    jr $ra