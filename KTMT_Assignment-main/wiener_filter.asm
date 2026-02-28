.data
buf_size:     .word 32768
buffer:       .space 32768
NUM_SAMPLES:  .word 10
desired:      .space 40
mmse:         .float 0.0
zero_f:       .float 0.0
one_f:        .float 1.0
input:        .space 40
crosscorr:    .space 40
autocorr:     .space 40
R:            .space 400
coeff:        .space 40
ouput:        .space 40
ten:          .float 10.0
hundred:      .float 100.0
half:         .float 0.5
minus_half:   .float -0.5
zero:         .float 0.0
str_buf:      .space 32
temp_str:     .space 32
header_filtered: .asciiz "Filtered output: "
header_mmse:  .asciiz "\nMMSE: "
space_str:    .asciiz " "
newline:      .asciiz "\n"
error_open:   .asciiz "Error: Can not open file"
error_size:   .asciiz "Error: size not match"
input_file:   .asciiz "input.txt"
desired_file: .asciiz "desired.txt"
output_file:  .asciiz "output.txt"

.text
.globl main

main:
    li   $v0, 13
    la   $a0, desired_file
    li   $a1, 0
    li   $a2, 0
    syscall
    bltz $v0, error_open_file
    move $s0, $v0

    li   $v0, 14
    move $a0, $s0
    la   $a1, buffer
    lw   $a2, buf_size
    syscall
    move $s1, $v0

    li   $v0, 16
    move $a0, $s0
    syscall

    la   $a0, buffer
    move $a1, $s1
    la   $a2, desired
    jal  parseFloats
    sw   $v0, NUM_SAMPLES

    li   $v0, 13
    la   $a0, input_file
    li   $a1, 0
    li   $a2, 0
    syscall
    bltz $v0, error_open_file
    move $s0, $v0

    li   $v0, 14
    move $a0, $s0
    la   $a1, buffer
    lw   $a2, buf_size
    syscall
    move $s1, $v0

    li   $v0, 16
    move $a0, $s0
    syscall

    la   $a0, buffer
    move $a1, $s1
    la   $a2, input
    jal  parseFloats
    
    lw   $t0, NUM_SAMPLES
    bne  $v0, $t0, error_size_mismatch

    la   $a0, desired
    la   $a1, input
    la   $a2, crosscorr
    lw   $a3, NUM_SAMPLES
    jal  computeCrosscorrelation

    la   $a0, input
    la   $a1, autocorr
    lw   $a2, NUM_SAMPLES
    jal  computeAutocorrelation

    la   $a0, autocorr
    la   $a1, R
    lw   $a2, NUM_SAMPLES
    jal  createToeplitzMatrix

    la   $a0, R
    la   $a1, crosscorr
    la   $a2, coeff
    lw   $a3, NUM_SAMPLES
    jal  solveLinearSystem

    la   $a0, input
    la   $a1, coeff
    la   $a2, ouput
    lw   $a3, NUM_SAMPLES
    jal  applyWienerFilter

    la   $a0, desired
    la   $a1, ouput
    lw   $a2, NUM_SAMPLES
    jal  computeMMSE
    swc1 $f0, mmse

    li   $v0, 13
    la   $a0, output_file
    li   $a1, 1
    li   $a2, 0
    syscall
    move $s0, $v0

    li   $v0, 15
    move $a0, $s0
    la   $a1, header_filtered
    li   $a2, 17
    syscall

    lw   $s1, NUM_SAMPLES
    la   $s2, ouput
    li   $s3, 0

loop_output:
    beq  $s3, $s1, done_output
    
    lwc1 $f12, 0($s2)
    jal  round_to_1dec
    mov.s $f12, $f0
    
    la   $a0, str_buf
    li   $a1, 1
    jal  float_to_str
    move $s4, $v0
    
    li   $v0, 15
    move $a0, $s0
    la   $a1, str_buf
    move $a2, $s4
    syscall
    
    addi $s3, $s3, 1
    beq  $s3, $s1, skip_space
    
    li   $v0, 15
    move $a0, $s0
    la   $a1, space_str
    li   $a2, 1
    syscall
    
skip_space:
    addi $s2, $s2, 4
    j    loop_output

error_open_file:
    li   $v0, 13
    la   $a0, output_file
    li   $a1, 1
    li   $a2, 0
    syscall
    move $s0, $v0
    
    li   $v0, 15
    move $a0, $s0
    la   $a1, error_open
    li   $a2, 25
    syscall
    
    li   $v0, 16
    move $a0, $s0
    syscall
    
    li   $v0, 10
    syscall

done_output:
    li   $v0, 15
    move $a0, $s0
    la   $a1, header_mmse
    li   $a2, 7
    syscall

    lwc1 $f12, mmse
    jal  round_to_1dec
    mov.s $f12, $f0
    
    la   $a0, str_buf
    li   $a1, 1
    jal  float_to_str
    move $s4, $v0
    
    li   $v0, 15
    move $a0, $s0
    la   $a1, str_buf
    move $a2, $s4
    syscall

    li   $v0, 16
    move $a0, $s0
    syscall

    li   $v0, 10
    syscall



computeAutocorrelation:
    li $t0, 0
outer_loop_ac:
    beq $t0, $a2, end_outer_ac
    li $t1, 0
    mtc1 $t1, $f0
    move $t2, $t0
inner_loop_ac:
    beq $t2, $a2, end_inner_ac
    sll $t3, $t2, 2
    add $t3, $t3, $a0
    lwc1 $f1, 0($t3)
    sub $t4, $t2, $t0
    sll $t4, $t4, 2
    add $t4, $t4, $a0
    lwc1 $f2, 0($t4)
    mul.s $f3, $f1, $f2
    add.s $f0, $f0, $f3
    addi $t2, $t2, 1
    j inner_loop_ac
end_inner_ac:
    mtc1 $a2, $f4
    cvt.s.w $f4, $f4
    div.s $f0, $f0, $f4
    sll $t3, $t0, 2
    add $t3, $t3, $a1
    swc1 $f0, 0($t3)
    addi $t0, $t0, 1
    j outer_loop_ac
end_outer_ac:
    jr $ra

error_size_mismatch:
    li   $v0, 13
    la   $a0, output_file
    li   $a1, 1
    li   $a2, 0
    syscall
    move $s0, $v0
    
    li   $v0, 15
    move $a0, $s0
    la   $a1, error_size
    li   $a2, 21
    syscall
    
    li   $v0, 16
    move $a0, $s0
    syscall
    
    li   $v0, 10
    syscall

computeCrosscorrelation:
    li $t0, 0
outer_loop_cc:
    beq $t0, $a3, end_outer_cc
    li $t1, 0
    mtc1 $t1, $f0
    move $t2, $t0
inner_loop_cc:
    beq $t2, $a3, end_inner_cc
    sll $t3, $t2, 2
    add $t3, $t3, $a0
    lwc1 $f1, 0($t3)
    sub $t4, $t2, $t0
    sll $t4, $t4, 2
    add $t4, $t4, $a1
    lwc1 $f2, 0($t4)
    mul.s $f3, $f1, $f2
    add.s $f0, $f0, $f3
    addi $t2, $t2, 1
    j inner_loop_cc
end_inner_cc:
    mtc1 $a3, $f4
    cvt.s.w $f4, $f4
    div.s $f0, $f0, $f4
    sll $t3, $t0, 2
    add $t3, $t3, $a2
    swc1 $f0, 0($t3)
    addi $t0, $t0, 1
    j outer_loop_cc
end_outer_cc:
    jr $ra

createToeplitzMatrix:
    li $t0, 0
outer_loop_ct:
    beq $t0, $a2, end_outer_ct
    li $t1, 0
inner_loop_ct:
    beq $t1, $a2, end_inner_ct
    sub $t3, $t0, $t1
    bgez $t3, pos_ct
    neg $t3, $t3
pos_ct:
    sll $t3, $t3, 2
    add $t3, $t3, $a0
    lwc1 $f0, 0($t3)
    mul $t4, $t0, $a2
    add $t4, $t4, $t1
    sll $t4, $t4, 2
    add $t4, $t4, $a1
    swc1 $f0, 0($t4)
    addi $t1, $t1, 1
    j inner_loop_ct
end_inner_ct:
    addi $t0, $t0, 1
    j outer_loop_ct
end_outer_ct:
    jr $ra

solveLinearSystem:
    li $t0, 0
    addi $t7, $a3, -1
forward_loop:
    bge $t0, $t7, end_forward
    addi $t1, $t0, 1
i_loop:
    beq $t1, $a3, end_i_loop
    mul $t2, $t1, $a3
    add $t2, $t2, $t0
    sll $t2, $t2, 2
    add $t2, $t2, $a0
    lwc1 $f0, 0($t2)
    mul $t3, $t0, $a3
    add $t3, $t3, $t0
    sll $t3, $t3, 2
    add $t3, $t3, $a0
    lwc1 $f1, 0($t3)
    div.s $f2, $f0, $f1
    move $t4, $t0
j_loop:
    beq $t4, $a3, end_j_loop
    mul $t5, $t0, $a3
    add $t5, $t5, $t4
    sll $t5, $t5, 2
    add $t5, $t5, $a0
    lwc1 $f3, 0($t5)
    mul.s $f4, $f2, $f3
    mul $t6, $t1, $a3
    add $t6, $t6, $t4
    sll $t6, $t6, 2
    add $t6, $t6, $a0
    lwc1 $f5, 0($t6)
    sub.s $f5, $f5, $f4
    swc1 $f5, 0($t6)
    addi $t4, $t4, 1
    j j_loop
end_j_loop:
    sll $t5, $t0, 2
    add $t5, $t5, $a1
    lwc1 $f3, 0($t5)
    mul.s $f4, $f2, $f3
    sll $t6, $t1, 2
    add $t6, $t6, $a1
    lwc1 $f5, 0($t6)
    sub.s $f5, $f5, $f4
    swc1 $f5, 0($t6)
    addi $t1, $t1, 1
    j i_loop
end_i_loop:
    addi $t0, $t0, 1
    j forward_loop
end_forward:
    addi $t0, $a3, -1
back_loop:
    bltz $t0, end_back
    # sum = b[i]
    sll $t1, $t0, 2
    add $t1, $t1, $a1
    lwc1 $f0, 0($t1)
    addi $t2, $t0, 1 
j_back_loop:
    beq $t2, $a3, end_j_back
    mul $t3, $t0, $a3
    add $t3, $t3, $t2
    sll $t3, $t3, 2
    add $t3, $t3, $a0
    lwc1 $f1, 0($t3)
    sll $t4, $t2, 2
    add $t4, $t4, $a2
    lwc1 $f2, 0($t4)
    mul.s $f3, $f1, $f2
    sub.s $f0, $f0, $f3
    addi $t2, $t2, 1
    j j_back_loop
end_j_back:
    mul $t3, $t0, $a3
    add $t3, $t3, $t0
    sll $t3, $t3, 2
    add $t3, $t3, $a0
    lwc1 $f1, 0($t3)
    div.s $f0, $f0, $f1
    sll $t4, $t0, 2
    add $t4, $t4, $a2
    swc1 $f0, 0($t4)
    addi $t0, $t0, -1
    j back_loop
end_back:
    jr $ra

applyWienerFilter:
    li $t0, 0
outer_aw:
    beq $t0, $a3, end_outer_aw
    li $t1, 0
    mtc1 $t1, $f0
    li $t2, 0
inner_aw:
    beq $t2, $a3, end_inner_aw
    sub $t3, $t0, $t2
    bltz $t3, end_inner_aw
    sll $t4, $t2, 2
    add $t4, $t4, $a1
    lwc1 $f1, 0($t4)
    sll $t5, $t3, 2
    add $t5, $t5, $a0
    lwc1 $f2, 0($t5)
    mul.s $f3, $f1, $f2
    add.s $f0, $f0, $f3
    addi $t2, $t2, 1
    j inner_aw
end_inner_aw:
    sll $t4, $t0, 2
    add $t4, $t4, $a2
    swc1 $f0, 0($t4)
    addi $t0, $t0, 1
    j outer_aw
end_outer_aw:
    jr $ra

computeMMSE:
    li $t0, 0
    mtc1 $t0, $f0
mmse_loop:
    beq $t0, $a2, end_mmse_loop
    sll $t1, $t0, 2
    add $t1, $t1, $a0
    lwc1 $f1, 0($t1)
    sll $t2, $t0, 2
    add $t2, $t2, $a1
    lwc1 $f2, 0($t2)
    sub.s $f3, $f1, $f2
    mul.s $f4, $f3, $f3
    add.s $f0, $f0, $f4
    addi $t0, $t0, 1
    j mmse_loop
end_mmse_loop:
    mtc1 $a2, $f5
    cvt.s.w $f5, $f5
    div.s $f0, $f0, $f5
    jr $ra

parseFloats:
    addi $sp, $sp, -32
    sw   $ra, 28($sp)
    sw   $s0, 24($sp)
    sw   $s1, 20($sp)
    sw   $s2, 16($sp)
    sw   $s3, 12($sp)
    
    move $s0, $a0
    add  $s1, $a0, $a1
    move $s2, $a2
    li   $s3, 0

parse_loop:
    bge  $s0, $s1, parse_done
    
skip_ws:
    bge  $s0, $s1, parse_done
    lb   $t4, 0($s0)
    beq  $t4, 32, skip_ws_inc
    beq  $t4, 9, skip_ws_inc
    beq  $t4, 10, skip_ws_inc
    beq  $t4, 13, skip_ws_inc
    j    start_parse
skip_ws_inc:
    addi $s0, $s0, 1
    j    skip_ws

start_parse:
    move $a0, $s0
    move $a1, $s1
    jal  parse_one_float
    
    swc1 $f0, 0($s2)
    addi $s2, $s2, 4
    addi $s3, $s3, 1
    
    move $s0, $v0
    j    parse_loop

parse_done:
    move $v0, $s3
    
    lw   $ra, 28($sp)
    lw   $s0, 24($sp)
    lw   $s1, 20($sp)
    lw   $s2, 16($sp)
    lw   $s3, 12($sp)
    addi $sp, $sp, 32
    jr   $ra

parse_one_float:
    move $t0, $a0  
    li   $t1, 0    
    li   $t2, 0 
    li   $t3, 0 
    li   $t4, 0 
    
    lb   $t5, 0($t0)
    bne  $t5, 45, parse_int    # '-'
    li   $t1, 1
    addi $t0, $t0, 1

parse_int:
    bge  $t0, $a1, convert_float
    lb   $t5, 0($t0)
    
    blt  $t5, 48, check_dot
    bgt  $t5, 57, check_dot
    
    li   $t6, 10
    mul  $t2, $t2, $t6
    addi $t5, $t5, -48
    add  $t2, $t2, $t5
    addi $t0, $t0, 1
    j    parse_int

check_dot:
    bne  $t5, 46, convert_float
    addi $t0, $t0, 1

parse_frac:
    bge  $t0, $a1, convert_float
    lb   $t5, 0($t0)
    
    blt  $t5, 48, convert_float
    bgt  $t5, 57, convert_float
    
    li   $t6, 10
    mul  $t3, $t3, $t6
    addi $t5, $t5, -48
    add  $t3, $t3, $t5
    addi $t4, $t4, 1
    addi $t0, $t0, 1
    j    parse_frac

convert_float:
    mtc1 $t2, $f0
    cvt.s.w $f0, $f0
    
    beqz $t4, apply_sign
    mtc1 $t3, $f1
    cvt.s.w $f1, $f1
    
    li   $t5, 10
    mtc1 $t5, $f2
    cvt.s.w $f2, $f2
    
frac_div_loop:
    beqz $t4, frac_div_done
    div.s $f1, $f1, $f2
    addi $t4, $t4, -1
    j    frac_div_loop

frac_div_done:
    add.s $f0, $f0, $f1

apply_sign:
    beqz $t1, parse_float_done
    neg.s $f0, $f0

parse_float_done:
    move $v0, $t0
    jr   $ra

round_to_1dec:
    lwc1 $f1, ten
    mul.s $f3, $f12, $f1
    
    lwc1 $f4, zero_f
    lwc1 $f5, half
    
    c.lt.s $f12, $f4
    bc1f  pos_round
    neg.s $f5, $f5
    add.s $f3, $f3, $f5
    trunc.w.s $f4, $f3
    cvt.s.w $f4, $f4
    div.s $f0, $f4, $f1
    jr   $ra
    
pos_round:
    add.s $f3, $f3, $f5
    trunc.w.s $f4, $f3
    cvt.s.w $f4, $f4
    div.s $f0, $f4, $f1
    jr   $ra

float_to_str:
    move $t0, $a0
    move $t1, $a1
    mov.s $f20, $f12
    lwc1 $f4, zero_f
    c.lt.s $f20, $f4
    bc1f  not_negative
    
    li   $t2, 45 
    sb   $t2, 0($t0)
    addi $t0, $t0, 1
    
    # Make positive
    neg.s $f20, $f20
    
not_negative:
    cvt.w.s $f4, $f20
    mfc1 $t2, $f4
    move $t3, $t0 
    li   $t4, 0
    
    beq  $t2, $zero, zero_int
    
convert_int:
    beq  $t2, $zero, reverse_int
    
    li   $t5, 10
    div  $t2, $t5
    mfhi $t6
    mflo $t2 
    
    addi $t6, $t6, 48
    sb   $t6, 0($t0)
    addi $t0, $t0, 1
    addi $t4, $t4, 1
    j    convert_int
    
zero_int:
    li   $t6, 48
    sb   $t6, 0($t0)
    addi $t0, $t0, 1
    addi $t4, $t4, 1
    j    after_reverse
    
reverse_int:
    move $t5, $t3
    addi $t6, $t0, -1
    
reverse_loop:
    bge  $t5, $t6, after_reverse
    
    lb   $t7, 0($t5)
    lb   $t8, 0($t6)
    sb   $t8, 0($t5)
    sb   $t7, 0($t6)
    
    addi $t5, $t5, 1
    addi $t6, $t6, -1
    j    reverse_loop
    
after_reverse:
    li   $t2, 46               # '.'
    sb   $t2, 0($t0)
    addi $t0, $t0, 1
    
    cvt.w.s $f4, $f20
    cvt.s.w $f5, $f4
    sub.s $f6, $f20, $f5      
    lwc1 $f4, zero_f
    c.lt.s $f6, $f4
    bc1f  pos_frac_part
    neg.s $f6, $f6
    
pos_frac_part:
    lwc1 $f7, ten
    mul.s $f6, $f6, $f7
    
    lwc1 $f8, half
    add.s $f6, $f6, $f8
    
    trunc.w.s $f6, $f6
    mfc1 $t2, $f6
    
    bgez $t2, pos_frac
    neg  $t2, $t2
    
pos_frac:
    addi $t6, $t2, 48
    sb   $t6, 0($t0)
    addi $t0, $t0, 1

done_str:
    # Calculate length
    sub  $v0, $t0, $a0
    jr   $ra
