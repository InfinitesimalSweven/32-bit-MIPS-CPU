# prog_3_recursive.asm
# Computes factorial(4) = 24
# Result stored at address 92

main:
    addi $sp, $zero, 240
    addi $a0, $zero, 4      # n = 4
    jal fact
    sw $v0, 92($zero)
    sw $zero, 252($zero)    # halt

# fact(n):
# if (n == 0) return 1
# else return n * fact(n-1)

fact:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    sw $a0, 0($sp)

    beq $a0, $zero, base_case

    addi $a0, $a0, -1
    jal fact

    lw $a0, 0($sp)          # restore n
    mult $a0, $v0
    mflo $v0
    j end

base_case:
    addi $v0, $zero, 1

end:
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra
    