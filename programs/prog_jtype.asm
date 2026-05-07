main:
    jal leaf
    sw $zero, 252($zero)
leaf:
    jr $ra