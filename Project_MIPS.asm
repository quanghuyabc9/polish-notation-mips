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
#--------------------------------------------------------
	# Infix->Postfix->Value
	la $v0,postfix
	jal InfixtoPostfix

	la $a0,postfix
	li $v0,4
	syscall

	jal PostfixtoValue
	addi $a0,$v0,0
	li $v0,1
	syscall

	li $a0,'\n'
	li $v0,11
	syscall
#--------------------------------------------------------
	# Infix->Prefix->Value
	la $a0,infix
	la $v0,prefix

	jal InfixtoPrefix

	la $a0,prefix
	li $v0,4
	syscall
	
	jal PrefixtoValue
	addi $a0,$v0,0
	li $v0,1
	syscall
	j Endmain

#************************FUNCTION*************************


# InfixtoPostfix:
# $a0 is our input infix, $v0 is input postfix
# you should save address of postfix before use this function
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
	# la $v0,postfix
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
			# addi $t0,$t0,-1
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

# Precedence:
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

# InfixtoPrefix:
# $a0 is our input infix, $v0 is input prefix
InfixtoPrefix:
	addi $sp,$sp,-8
	sw $ra,4($sp)
	sw $v0,0($sp)

	jal ReverseString
	jal Modifie

	lw $v0,0($sp)
	jal InfixtoPostfix 
	la $a0,prefix
	jal ReverseString
	jal Modifie

	lw $ra,4($sp)

	addi $sp,$sp,8
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

# Modifie:
# '(' become ')', ')' become '(', reverse number 
# $a0 is our input string and that string will be modified
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

	jr $ra

# PostfixtoValue
# $a0 is input string
# $v0 is result (integer)
PostfixtoValue:
	addi $sp,$sp,-28
	sw $s0,24($sp)
	sw $s1,20($sp)
	sw $s2,16($sp)
	sw $s3,12($sp)
	sw $s4,8($sp)
	sw $s5,4($sp)
	sw $s6,0($sp)

	li $s4, 1024 # const
	addi $sp,$sp,-1024
	li $s0,0 # index of stack, The number of integer in stack
	li $s1,0 # index for scan
	la $s2,number
	Loop_PostfixtoValue:
		add $s3,$s1,$a0
		lb $s3,0($s3)
		beq $s3,'\n',Break_Loop_PostfixtoValue
		bgt $s3,'/',NextCase_Loop_PostfixtoValue
		blt $s3,'*',NextCase_Loop_PostfixtoValue
		j Case_Operator_PtoV
		NextCase_Loop_PostfixtoValue:
		blt $s3,'0',NextCase2_Loop_PostfixtoValue
		bgt $s3,'9',NextCase2_Loop_PostfixtoValue
		j Case_Operand_PtoV
		NextCase2_Loop_PostfixtoValue:
		addi $s1,$s1,1
		j Loop_PostfixtoValue
		# use $s5->
		Case_Operator_PtoV:
			# pop 2 numbers
			sll $s5,$s0,2 # $s5=$s0*4
			sub $s5,$s4,$s5
			add $s5,$s5,$sp
			lw $s5,0($s5)

			addi $s6,$s5,0 # $s6 number 1

			addi $s0,$s0,-1

			sll $s5,$s0,2 # $s5=$s0*4
			sub $s5,$s4,$s5
			add $s5,$s5,$sp
			lw $s5,0($s5) # $s5 numer 2

			addi $s0,$s0,-1

			beq $s3,'+',Case_Operator_PtoV_Add
			beq $s3,'-',Case_Operator_PtoV_Sub
			beq $s3,'*',Case_Operator_PtoV_Mult
			beq $s3,'/',Case_Operator_PtoV_Div
			Case_Operator_PtoV_Add:
				add $s6,$s5,$s6
				# push stack
				addi $s0,$s0,1
				sll $s5,$s0,2 # $s5=$s0*4
				sub $s5,$s4,$s5
				add $s5,$s5,$sp
				sw $s6,0($s5)	
				addi $s1,$s1,1
				j Loop_PostfixtoValue
			Case_Operator_PtoV_Sub:
				sub $s6,$s5,$s6
				# push stack
				addi $s0,$s0,1
				sll $s5,$s0,2 # $s5=$s0*4
				sub $s5,$s4,$s5
				add $s5,$s5,$sp
				sw $s6,0($s5)
				addi $s1,$s1,1
				j Loop_PostfixtoValue		
			Case_Operator_PtoV_Mult:
				mult $s5,$s6
				mflo $s6
				# push stack
				addi $s0,$s0,1
				sll $s5,$s0,2 # $s5=$s0*4
				sub $s5,$s4,$s5
				add $s5,$s5,$sp
				sw $s6,0($s5)
				addi $s1,$s1,1
				j Loop_PostfixtoValue	
			Case_Operator_PtoV_Div:
				div $s5,$s6
				mflo $s6
				# push stack
				addi $s0,$s0,1
				sll $s5,$s0,2 # $s5=$s0*4
				sub $s5,$s4,$s5
				add $s5,$s5,$sp
				sw $s6,0($s5)		
				addi $s1,$s1,1
				j Loop_PostfixtoValue	
		Case_Operand_PtoV:
			li $s5,0
			Loop_Operand_PtoV:
				add $s3,$s1,$a0
				lb $s3,0($s3)
				blt $s3,'0',Break_Loop_Operand_PtoV
				bgt $s3,'9',Break_Loop_Operand_PtoV
				# store in number
				add $s6,$s5,$s2
				sb $s3,0($s6)
				addi $s5,$s5,1
				addi $s1,$s1,1
				j Loop_Operand_PtoV
				Break_Loop_Operand_PtoV:
					
					addi $sp,$sp,-12
					sw $ra,8($sp)
					sw $a0,4($sp)
					sw $v0,0($sp)

					la $a0,number
					li $s6,'\n'
					add $s5,$s5,$a0
					sb $s6,0($s5)
					jal ToInt
					addi $s6,$v0,0

					lw $v0,0($sp)
					lw $a0,4($sp)
					lw $ra,8($sp)
					addi $sp,$sp,12
					# push stack		
					addi $s0,$s0,1	
					sll $s5,$s0,2 # $s5=$s0*4
					sub $s5,$s4,$s5
					add $s5,$s5,$sp
					sw $s6,0($s5)
					
				
					
					
					
					sb $0,0($s2) # clear number
					j Loop_PostfixtoValue
		Break_Loop_PostfixtoValue:
			# Pop stack
			sll $s5,$s0,2 # $s5=$s0*4
			sub $s5,$s4,$s5
			add $s5,$s5,$sp
			lw $s5,0($s5)
			addi $s0,$s0,-1

			addi $v0,$s5,0

			addi $sp,$sp,1024
			
			lw $s6,0($sp)	
			lw $s5,4($sp)
			lw $s4,8($sp)
			lw $s3,12($sp)
			lw $s2,16($sp)
			lw $s1,20($sp)
			lw $s0,24($sp)
			addi $sp,$sp,28

			jr $ra		
	
# ToInt
# $a0 is input number(string)
# $v0 is output number (integer) (32 bits)
ToInt:
	# Backup
	addi $sp,$sp,-12
	sw $s0,8($sp)
	sw $s1,4($sp)
	sw $s2,0($sp)

	li $v0,0
	li $s0,0
	li $s1,10 # const
	Loop_ToInt:
		add $s2,$s0,$a0
		lb $s2,0($s2)
		beq $s2,'\n',Break_Loop_ToInt
		addi $s2,$s2,-48

		mult $v0,$s1
		mflo $v0
		add $v0,$v0,$s2
		addi $s0,$s0,1
		j Loop_ToInt
	Break_Loop_ToInt:
		# Recover
		lw $s2,0($sp)
		lw $s1,4($sp)
		lw $s0,8($sp)
		addi $sp,$sp,12
		jr $ra

# PrefixtoValue
# $a0 is input prefix
# $v0 is value integer
PrefixtoValue:
	addi $sp,$sp,-4
	sw $ra,0($sp)

	# reverse prefix
	jal ReverseString
	jal Modifie

	lw $ra,0($sp)
	addi $sp,$sp,4
	
	addi $sp,$sp,-28
	sw $s0,24($sp)
	sw $s1,20($sp)
	sw $s2,16($sp)
	sw $s3,12($sp)
	sw $s4,8($sp)
	sw $s5,4($sp)
	sw $s6,0($sp)

	li $s4, 1024 # const
	addi $sp,$sp,-1024
	li $s0,0 # index of stack, The number of integer in stack
	li $s1,0 # index for scan
	la $s2,number
	Loop_PrefixtoValue:
		add $s3,$s1,$a0
		lb $s3,0($s3)
		beq $s3,'\n',Break_Loop_PrefixtoValue
		bgt $s3,'/',NextCase_Loop_PrefixtoValue
		blt $s3,'*',NextCase_Loop_PrefixtoValue
		j Case_Operator_PrtoV
		NextCase_Loop_PrefixtoValue:
		blt $s3,'0',NextCase2_Loop_PrefixtoValue
		bgt $s3,'9',NextCase2_Loop_PrefixtoValue
		j Case_Operand_PrtoV
		NextCase2_Loop_PrefixtoValue:
		addi $s1,$s1,1
		j Loop_PrefixtoValue
		# use $s5->
		Case_Operator_PrtoV:
			# pop 2 numbers
			sll $s5,$s0,2 # $s5=$s0*4
			sub $s5,$s4,$s5
			add $s5,$s5,$sp
			lw $s5,0($s5)

			addi $s6,$s5,0 # $s6 number 1

			addi $s0,$s0,-1

			sll $s5,$s0,2 # $s5=$s0*4
			sub $s5,$s4,$s5
			add $s5,$s5,$sp
			lw $s5,0($s5) # $s5 numer 2

			addi $s0,$s0,-1

			beq $s3,'+',Case_Operator_PrtoV_Add
			beq $s3,'-',Case_Operator_PrtoV_Sub
			beq $s3,'*',Case_Operator_PrtoV_Mult
			beq $s3,'/',Case_Operator_PrtoV_Div
			Case_Operator_PrtoV_Add:
				add $s6,$s6,$s5
				# push stack
				addi $s0,$s0,1
				sll $s5,$s0,2 # $s5=$s0*4
				sub $s5,$s4,$s5
				add $s5,$s5,$sp
				sw $s6,0($s5)	
				addi $s1,$s1,1
				j Loop_PrefixtoValue
			Case_Operator_PrtoV_Sub:
				sub $s6,$s6,$s5
				# push stack
				addi $s0,$s0,1
				sll $s5,$s0,2 # $s5=$s0*4
				sub $s5,$s4,$s5
				add $s5,$s5,$sp
				sw $s6,0($s5)
				addi $s1,$s1,1
				j Loop_PrefixtoValue		
			Case_Operator_PrtoV_Mult:
				mult $s6,$s5
				mflo $s6
				# push stack
				addi $s0,$s0,1
				sll $s5,$s0,2 # $s5=$s0*4
				sub $s5,$s4,$s5
				add $s5,$s5,$sp
				sw $s6,0($s5)
				addi $s1,$s1,1
				j Loop_PrefixtoValue	
			Case_Operator_PrtoV_Div:
				div $s6,$s5
				mflo $s6
				# push stack
				addi $s0,$s0,1
				sll $s5,$s0,2 # $s5=$s0*4
				sub $s5,$s4,$s5
				add $s5,$s5,$sp
				sw $s6,0($s5)		
				addi $s1,$s1,1
				j Loop_PrefixtoValue	
		Case_Operand_PrtoV:
			li $s5,0
			Loop_Operand_PrtoV:
				add $s3,$s1,$a0
				lb $s3,0($s3)
				blt $s3,'0',Break_Loop_Operand_PrtoV
				bgt $s3,'9',Break_Loop_Operand_PrtoV
				# store in number
				add $s6,$s5,$s2
				sb $s3,0($s6)
				addi $s5,$s5,1
				addi $s1,$s1,1
				j Loop_Operand_PrtoV
				Break_Loop_Operand_PrtoV:
					
					addi $sp,$sp,-12
					sw $ra,8($sp)
					sw $a0,4($sp)
					sw $v0,0($sp)

					la $a0,number
					li $s6,'\n'
					add $s5,$s5,$a0
					sb $s6,0($s5)
					jal ToInt
					addi $s6,$v0,0

					lw $v0,0($sp)
					lw $a0,4($sp)
					lw $ra,8($sp)
					addi $sp,$sp,12
					# push stack		
					addi $s0,$s0,1	
					sll $s5,$s0,2 # $s5=$s0*4
					sub $s5,$s4,$s5
					add $s5,$s5,$sp
					sw $s6,0($s5)
					
				
					
					
					
					sb $0,0($s2) # clear number
					j Loop_PrefixtoValue
		Break_Loop_PrefixtoValue:
			# Pop stack
			sll $s5,$s0,2 # $s5=$s0*4
			sub $s5,$s4,$s5
			add $s5,$s5,$sp
			lw $s5,0($s5)
			addi $s0,$s0,-1

			addi $v0,$s5,0

			addi $sp,$sp,1024
			
			lw $s6,0($sp)	
			lw $s5,4($sp)
			lw $s4,8($sp)
			lw $s3,12($sp)
			lw $s2,16($sp)
			lw $s1,20($sp)
			lw $s0,24($sp)
			addi $sp,$sp,28

			jr $ra		
	
Endmain:



