main:
    addi $t0, $zero, 5
    addi $t1, $zero, 3
    jal leaf_add
    sw $t2, 84($zero)
    sw $zero, 252($zero)

leaf_add:
    add $t2, $t0, $t1
    jr $ra