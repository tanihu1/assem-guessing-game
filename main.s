/* 318792801 Yotam Ashman */
.extern printf
.extern scanf
.extern rand
.extern srand

.section .data
    # strings
    fmt_string_no_new_line: .asciz "%s"
    fmt_string: .asciz "%s\n"
    fmt_int: .asciz "%d"
    fmt_chr: .asciz " %c"
    config_msg: .asciz "Enter configuration seed: "
    mode_msg: .asciz "Would you like to play in easy mode? (y/n) "
    guess_msg: .asciz "What is your guess? "
    wrong_hard_retry_msg: .asciz "Incorrect. What is your guess? "
    wrong_above_retry_msg: .asciz "Incorrect. Your guess was above the actual number ... "
    wrong_below_retry_msg: .asciz "Incorrect. Your guess was below the actual number ... "
    wrong_over_msg: .asciz "Incorrect. "
    lose_msg: .asciz "\nGame over, you lost :(. The correct answer was %d\n"
    double_msg: .asciz "Double or nothing! Would you like to continue to another round? (y/n) "
    won_msg: .asciz "Congratz! you won %d rounds!\n"
    # numbers
    n_num: .long 10 
    m_max: .long 5
    m_current: .long 0
    rounds_won: .long 0
.section .bss
    guess_num: .space 4
    secret_num: .space 4
    seed_num: .space 4
    mode_bool: .space 1 # 1 = easy, 0 = hard
    double_bool: .space 1 # 0 = no, 1 = yes

.section .text
.global main

main:
    # config msg
    pushq %rbp
    movq %rsp, %rbp

    leaq fmt_string_no_new_line(%rip), %rdi
    leaq config_msg(%rip), %rsi
    movq $0, %rax
    call printf
    # taking input - int
    leaq fmt_int(%rip), %rdi
    leaq seed_num(%rip), %rsi
    movq $0, %rax
    call scanf
    #seeding
    movl seed_num(%rip), %edi
    call srand
    # setting secret
    call rand
    movl %eax, %edx
    movl %edx, %eax
    movl n_num(%rip), %ecx
    xorl %edx, %edx
    divl %ecx
    incl %edx
    movl %edx, secret_num(%rip)

    # mode msg
    leaq fmt_string_no_new_line(%rip), %rdi
    leaq mode_msg(%rip), %rsi
    movq $0, %rax
    call printf
    # taking input - chr
    leaq fmt_chr(%rip), %rdi
    leaq mode_bool(%rip), %rsi
    movq $0, %rax
    call scanf
    # setting the correct bool value
    movb mode_bool(%rip), %al
    cmpb $'y', %al
    je set_easy_mode
    cmpb $'n', %al
    je set_hard_mode
set_easy_mode:
    movb $1, mode_bool(%rip)
    jmp start
set_hard_mode:
    movb $0, mode_bool(%rip)
    jmp start
double_or_nothing:
    /* pesuedo
    0. inc rounds won 
    1. print double_msg
    2. take input into double_bool
    3. cmp double bool

    4.1. seed_num *= 2
    4.1 m_num *= 2
    4.1 jmp start

    4.0. jmp win
    */
    incl rounds_won(%rip)
    leaq fmt_string_no_new_line(%rip), %rdi
    leaq double_msg(%rip), %rsi
    xorq %rax, %rax
    call printf
    # taking input - chr
    leaq fmt_chr(%rip), %rdi
    leaq double_bool(%rip), %rsi
    movq $0, %rax
    call scanf

    movb double_bool(%rip), %al
    cmpb $'n', %al
    je win 
    # do double or nothing
    sall $1, seed_num(%rip)
    sall $1, n_num(%rip)
    jmp reset_round

reset_round:
    movl $0, m_current(%rip)
    #re-seeding
    movl seed_num(%rip), %edi
    call srand
    # setting secret
    call rand
    movl %eax, %edx
    movl %edx, %eax
    movl n_num(%rip), %ecx
    xorl %edx, %edx
    divl %ecx
    incl %edx
    movl %edx, secret_num(%rip)
    jmp start


start:
    # printing guess msg
    leaq fmt_string_no_new_line(%rip), %rdi
    leaq guess_msg(%rip), %rsi
    xorq %rax, %rax
    call printf

    leaq after_guess(%rip), %rax
    jmp take_guess_coroutine
after_guess:
    movb mode_bool(%rip), %al
    cmpb $1, %al
    je easy
    jmp hard

take_guess_coroutine: #works!
    /* 
    takes guess with scanf and stores in guess_num
    returns back to address stored inside %rax 
    */
    # align stack
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    pushq %rax
    
    leaq fmt_int(%rip), %rdi
    leaq guess_num(%rip), %rsi
    xorq %rax, %rax
    call scanf
    # clean up
    popq %rax
    movq %rbp, %rsp
    popq %rbp

    # return
    jmp *%rax

easy:
    /* pesudeo
    1. cmp guess to secret
    2. equ -> jmp to win
    3. neq:
    4. inc m_current
    5. cmp m_max to m_current
    6. equ -> jmp to loss
    7. show hint
    8. jmp start
    */
    movl secret_num(%rip), %eax
    movl guess_num(%rip), %edx
    cmpl %eax, %edx
    je double_or_nothing
    # on wrong answer
    # setting up hint courotine
    leaq after_hint(%rip), %rax
    jmp show_hint_coroutine

after_hint:
    incl m_current(%rip)
    movl m_max(%rip), %eax
    cmpl %eax, m_current(%rip)
    jge loss
    jmp start

show_hint_coroutine:
    # align stack
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    pushq %rax
    # cmp guess
    movl guess_num(%rip), %eax
    cmpl secret_num(%rip), %eax
    jl guessed_low
    jg gueseed_high
guessed_low:
    # printing high msg
    leaq fmt_string(%rip), %rdi
    leaq wrong_below_retry_msg(%rip), %rsi
    xorq %rax, %rax
    call printf

    jmp hint_go_back

gueseed_high:
    # printing low  msg
    leaq fmt_string(%rip), %rdi
    leaq wrong_above_retry_msg(%rip), %rsi
    xorq %rax, %rax
    call printf

    jmp hint_go_back

hint_go_back:
    # clean up
    popq %rax
    movq %rbp, %rsp
    popq %rbp

    # return
    jmp *%rax

hard:
    /* pesudeo 
    1. take guess - coroutine
    2. cmp guess to secret
    3. equ -> jump to win
    4. neq:
    5. inc m_current
    6. cmp m_max to m_current
    7. equ -> jmp to loss
    8. jmp to hard
    */
    movl secret_num(%rip), %eax
    movl guess_num(%rip), %edx
    cmpl %eax, %edx
    je double_or_nothing
    # on wrong answer
    leaq fmt_string_no_new_line(%rip), %rdi
    leaq wrong_over_msg(%rip), %rsi
    movq $0, %rax
    call printf

    incl m_current(%rip)
    movl m_max(%rip), %eax
    cmpl %eax, m_current(%rip)
    jge loss
    jmp start
loss:
    /* pesudeo 
    1. print lose_msg with secret_num
    2. exit - popq %rbp and ret
    */
    # printing lost msg
    leaq lose_msg(%rip), %rdi
    movl secret_num(%rip), %esi
    xorq %rax, %rax
    call printf

    popq %rbp
    ret
win:
    /*
    1. print win with rounds_won
    2. exit - popq %rbp and ret
    */
    # printing won msg
    leaq won_msg(%rip), %rdi
    movl rounds_won(%rip), %esi
    xorq %rax, %rax
    call printf

    popq %rbp
    ret
