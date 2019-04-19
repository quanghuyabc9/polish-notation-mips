.data
infix: .space 256
postfix: .space 256
prefix: .space 256
number: .space 256 # use for store a number
postfixfile: .asciiz "postfix.txt"
prefixfile: .asciiz "prefix.txt"
.text
.globl main

main:
	la $a0,infix
	li $a1,256
	li $v0,8
	syscall
	jal InfixtoPrefix
	addi $a0,$v0,0
	#jal ReverseString
	#li $v0,4
	#syscall
	#jal Modifie
	li $v0,4
	syscall
	j WriteFile
	j Endmain

# InfixtoPostfix:
# $a0 is our input infix
# $v0 returns the  postfix
InfixtoPostfix:
	addi $sp,$sp,-32
	sw $s0,28($sp)
	sw $s1,24($sp)
	sw $s2,20($sp)
	sw $s3,16($sp)
	sw $s4,12($sp)
	sw $s5,8($sp)
	sw $s6,4($sp)
	sw $s7,0($sp)
	#la $v0,postfix
	addi $s5,$v0,0 # index for saving in postfix
	addi $sp,$sp,-256 # initializing empty stack
	li $s0,0 # index of stack
	li $s1,-1 # index of infix
	li $s4,256 # Const
	# Scanning infix
	Loop_InfixtoPostfix:
		addi $s1,$s1,1
		# $s2 is used for saving char in infix
		add $s2,$s1,$a0
		lb $s2,0($s2)

		beq $s2,'\n',Break_Loop_InfixtoPostfix # Scan end of infix --> pop all operator to postfix
		beq $s2,'(',Case_LeftBracket_ItP
		beq $s2,')',Case_RightBracket_ItP
		ble $s2,'/',Case_Operator_ItP
		bge $s2,'0',Case_Operand_ItP
	Case_LeftBracket_ItP: 
		# Push 
		addi $s0,$s0,1
		sub $s3,$s4,$s0 # $t3 is position to push in stack
		add $s3,$s3,$sp
		sb $s2,0($s3)
		j Loop_InfixtoPostfix
	Case_RightBracket_ItP:
		# Pop until reaching LeftBracket
		Loop_RB_ItP:
			# Pop
			sub $s3,$s4,$s0 
			add $s3,$s3,$sp
			lb $s3,0($s3)
			addi $s0,$s0,-1
			beq $s3,'(',Break_Loop_RB_ItP
			# Save that char to posfix
			
			li $s7,' '
			sb $s7,0($s5)
			add $s5,$s5,1

			
			sb $s3,0($s5)
			add $s5,$s5,1
			
			j Loop_RB_ItP
		Break_Loop_RB_ItP:
			#addi $t0,$t0,-1
			j Loop_InfixtoPostfix
	Case_Operator_ItP:
		li $s7,' '
		sb $s7,0($s5)
		add $s5,$s5,1
		Loop_Operator:
			# if stack is empty
			beq $s0,0,PushOperator
			sub $s3,$s4,$s0 # $s3 is element of top of stack
			add $s3,$s3,$sp
			lb $s3,0($s3)
			
			addi $sp,$sp,-4
			sw $ra,4($sp)

			addi $sp,$sp,-8
			sw $a0,4($sp)
			sw $v0,0($sp)

			addi $a0,$s3,0 # $s3 is element of top of stack
			jal Precedence
			addi $s6,$v0,0 # $s6 is precedence of element of top stack
			  
			addi $a0,$s2,0 # $s2 is token
			jal Precedence
			addi $s7,$v0,0 # $s7 is precedence of token
			
			lw $v0,0($sp)
			lw $a0,4($sp)
			addi $sp,$sp,8

			lw $ra,4($sp)
			addi $sp,$sp,4

			# If token have more Precedence than Element in Top of stack
			bgt $s7,$s6,PushOperator 
			# If token have less or equal Precedence than Element in Top of stack
			sb $s3,0($s5) # Pop and save in Posfix
			add $s5,$s5,1
			addi $s0,$s0,-1
			
			li $s7,' '
			sb $s7,0($s5)
			add $s5,$s5,1

			j Loop_Operator	
			
		PushOperator:			
			addi $s0,$s0,1
		        sub $s3,$s4,$s0 # $t3 is position to push in stack
		        add $s3,$s3,$sp
		        sb $s2,0($s3)
			j Loop_InfixtoPostfix	
	Case_Operand_ItP:
		sb $s2,0($s5)
		add $s5,$s5,1
		j Loop_InfixtoPostfix	
	Break_Loop_InfixtoPostfix:
		Loop_BLI:
			beq $s0,0,Break_Loop_BLI

			li $s7,' '
			sb $s7,0($s5)
			add $s5,$s5,1

			#Pop stack
			sub $s3,$s4,$s0 
			add $s3,$s3,$sp
			lb $s3,0($s3)
			addi $s0,$s0,-1	
			
			sb $s3,0($s5)
			add $s5,$s5,1
			
			j Loop_BLI
		Break_Loop_BLI:
			li $s7,'\n'
			sb $s7,0($s5)
			addi $sp,$sp,256
			lw $s7,0($sp)
			lw $s6,4($sp)	
			lw $s5,8($sp)
			lw $s4,12($sp)
			lw $s3,16($sp)
			lw $s2,20($sp)
			lw $s1,24($sp)
			lw $s0,28($sp)
			addi $sp,$sp,32
			
			jr $ra
#Precedence:
# $a0 is input character
# $v0 is the precedence of $a0
Precedence:
	beq $a0,'(',Prece0
	beq $a0,'+',Prece1
	beq $a0,'-',Prece1
	beq $a0,'*',Prece2
	beq $a0,'/',Prece2
	Prece0: li $v0,0
	jr $ra
	Prece1:	li $v0,1
	jr $ra
	Prece2: li $v0,2
	jr $ra
# InfixtoPostfix:
# $a0 is our input infix
# $v0 returns the prefix
InfixtoPrefix:
	la $v0,prefix
	addi $sp,$sp,-8
	sw $ra,4($sp)
	sw $v0,0($sp)
	jal ReverseString
	jal Modifie
	lw $v0,0($sp)
	addi $sp,$sp,4
	jal InfixtoPostfix 
	addi $a0,$v0,0
	jal ReverseString
	jal Modifie
	addi $v0,$a0,0
	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra
#Strlen:
# $a0 is our input string
# $v0 returns the length
Strlen:
	addi $sp,$sp,-8
	sw $s0,4($sp)
	sw $s1,0($sp)
	li $s0,0 
	Loop_Strlen:
		addi $s1,$s0,0
		add $s1,$s1,$a0
		lb $s1,0($s1)
		beq $s1,'\n',Break_Loop_Strlen
		addi $s0,$s0,1
		j Loop_Strlen
	Break_Loop_Strlen:
		addi $v0,$s0,0
		lw $s1,0($sp)
		lw $s0,4($sp)
		addi $sp,$sp,8
		jr $ra
# ReverseString:
# $a0 is our input string and that string will be reversed
ReverseString:
      	addi $sp,$sp,-24
	sw $s0,20($sp)
	sw $s1,16($sp)
	sw $s2,12($sp)
	sw $s3,8($sp)
	sw $s4,4($sp)
	sw $s5,0($sp)

	addi $sp,$sp,-4
	sw $ra,0($sp)

	jal Strlen

	addi $s0,$v0,-1 # $s0: last = length(str)-1
	li $v0,2
	div $s0,$v0
	mflo $s1 # $s1: mid = (length(str)-1)/2
	
	lw $ra,0($sp)
	addi $sp,$sp,4
	
	li $s2,0 # $s2: index
	Loop_ReverseStr:
		bgt $s2,$s1,Break_Loop_ReverseStr # index > mid
		# Swap
		add $s3,$s2,$a0
		lb $s3,0($s3) # $s3: str[index]

		
		sub $s4,$s0,$s2 # last - index

		add $s5,$s4,$a0
		lb $s5,0($s5)  # $s5: str[last-index]
		
		add $s4,$s4,$a0
		sb $s3,0($s4) # str[last-index]=str[index]

		add $s4,$s2,$a0 
		sb $s5,0($s4) # str[index]=str[last-index]	
	
		addi $s2,$s2,1
		j Loop_ReverseStr
	Break_Loop_ReverseStr:

		lw $s5,0($sp)
		lw $s4,4($sp)
		lw $s3,8($sp)
		lw $s2,12($sp)
		lw $s1,16($sp)
		lw $s0,20($sp)
		addi $sp,$sp,24		

		jr $ra
# Modifie:'(' become ')', ')' become '(', reverse number 
# $a0 is our input string and that string will be modified, a1 is string number
Modifie:
	addi $sp,$sp,-32
	sw $s0,28($sp)
	sw $s1,24($sp)
	sw $s2,20($sp)
	sw $s3,16($sp)
	sw $s4,12($sp)
	sw $s5,8($sp)
	sw $s6,4($sp)
	sw $s7,0($sp)

	li $s0,0 # s0: index
	la $a1,number # $a1: address of number
	Loop_Modifie:
		add $s1,$s0,$a0
		lb $s1,0($s1)
		beq $s1,'\n',Break_Loop_Modifie
		blt $s1,'0',Case_LeftBracket_Modifie
		bgt $s1,'9',Case_LeftBracket_Modifie
		addi $s2,$s0,0 # index for load from string to number
		li $s5,0 # index of number
		Loop_Number:
			add $s4,$s2,$a0
			lb $s4,0($s4)
			blt $s4,'0',Break_Loop_Number_Modifie
			bgt $s4,'9',Break_Loop_Number_Modifie
			add $s6,$s5,$a1
			sb $s4,0($s6)
			addi $s5,$s5,1
			addi $s2,$s2,1
			j Loop_Number
		Break_Loop_Number_Modifie:
			li $s4,'\n'
			add $s6,$s5,$a1
			sb $s4,0($s6)

			addi $sp,$sp,-8
			sw $ra,4($sp)
			sw $a0,0($sp)

			# Reverse number
			addi $a0,$a1,0
			jal ReverseString
			addi $a1,$a0,0

			lw $a0,0($sp)
			lw $ra,4($sp)
			addi $sp,$sp,8

			# Store number to string
			li $s6,0
			addi $s3,$s0,0 # index for store from number to string
			Loop_StoreNumber:	
				bge $s3,$s2,Exit_Loop_StoreNumber

				add $s7,$s6,$a1
				lb $s7,0($s7) 

				add $s4,$s3,$a0
				sb $s7,0($s4)

				addi $s6,$s6,1
				addi $s3,$s3,1
				j Loop_StoreNumber
			Exit_Loop_StoreNumber:
				add $s0,$s0,$s5
				sb $0,0($a1) # Clear Number
				j Loop_Modifie
		Case_LeftBracket_Modifie:
			bne $s1,'(',Case_RightBracket_Modifie
			add $s2,$s0,$a0
			li $s1,')'
			sb $s1,0($s2)
			addi $s0,$s0,1
			j Loop_Modifie
		Case_RightBracket_Modifie:
			bne $s1,')',Case_Operator_Modifie
			add $s2,$s0,$a0
			li $s1,'('
			sb $s1,0($s2)	
			addi $s0,$s0,1
			j Loop_Modifie	
		Case_Operator_Modifie:	
			addi $s0,$s0,1
			j Loop_Modifie
	Break_Loop_Modifie:	
		lw $s7,0($sp)
		lw $s6,4($sp)	
		lw $s5,8($sp)
		lw $s4,12($sp)
		lw $s3,16($sp)
		lw $s2,20($sp)
		lw $s1,24($sp)
		lw $s0,28($sp)
		addi $sp,$sp,32

		jr $ra	

WriteFile:
#write postfix file

	la $a0, postfixfile

	#open file for write-only
	li $v0, 13
	addi $a1, $0, 1
	addi $a2, $0, 0
	syscall

	add $s0, $v0, $0

	#write file
	li $v0, 15
	add $a0, $s0, $0
	la $a1, postfix
	li $a2, 256
	syscall

	#close file
	li $v0, 16
	move $a0, $s0
	syscall

#write prefix file

	la $a0, prefixfile

	#open file for write-only
	li $v0, 13
	addi $a1, $0, 1
	addi $a2, $0, 0
	syscall

	add $s0, $v0, $0

	#write file
	li $v0, 15
	add $a0, $s0, $0
	la $a1, prefix
	li $a2, 256
	syscall

	#close file
	li $v0, 16
	move $a0, $s0
	syscall
#
	jr $ra
Endmain:



