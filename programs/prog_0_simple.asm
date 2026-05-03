# prog_0_simple.asm
addi $t0, $zero, 5
addi $t1, $zero, 3
add  $t2, $t0, $t1

sw   $t2, 84($zero)   # store result
sw   $zero, 252($zero) #Memory-Mapped Halt