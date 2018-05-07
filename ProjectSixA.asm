TITLE Programming Assignment 6    (ProjectSixA.asm)

; Author: Aalok Borkar
; Email: borkaraa@oregonstate.edu
; Course / Project ID   CS271-400 (Assignment 6A)              Date: 3/18/18
; Description: Write a program that defines the macros getString and displayString (using getstring function) and gets 10 unsigned user-inputted integers and both displays and finds their sums and average.


INCLUDE Irvine32.inc

;-----------------------------------M A C R O S--------------------------------------------------------------------------------------------------------------------------------------------------

LEN = 100	;Constant for defining the lenth of input array
QLEN = 80	;Constant to define LEN minus the max amount of bytes allowed by the program (4)

GetString MACRO	prompt, buffer	;-------------------------------------------------
	pushad
	;prompt the user
	mov edx, prompt
	call CRLF
	call WriteString

	;get string input from user
	mov edx, buffer	;eax has mem @ of the start of reserved space input_string
	mov ecx, LEN
	call ReadString		;input_ptr =aka- num_input now has the user-inputted data
	popad

ENDm


DisplayString MACRO str_add	;-------------------------------------------------
	pushad
		mov edx, str_add	;will be an offset of a string
		call WriteString
	popad
ENDm

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

.data
hello1		BYTE	"Programming Assignment 6: Designing low-level I/O procedures", 13, 10, 0				;Variable to introduce the user (1/6)
hello2		BYTE	"Written by: Aalok Borkar", 13, 10, 0													;Variable to introduce the user (2/6)
hello3		BYTE	"Please provide 10 unsigned decimal integers.", 13, 10, 0								;Variable to introduce the user (3/6)
hello4		BYTE	"Each number needs to be small enough to fit inside a 32 bit register.", 13, 10, 0		;Variable to introduce the user (4/6)
hello5		BYTE	"After you have finished inputting the raw numbers I will display a list", 13, 10, 0	;Variable to introduce the user (5/6)
hello6		BYTE	"of the integers, their sum, and their average value.", 13, 10, 0						;Variable to introduce the user (6/6)
num_input	BYTE	LEN DUP(0)																				;Variable to store the user input (single number)
input_ptr	DWORD	num_input																				;Variable to point to input
prompt		BYTE	"Enter an unsigned integer: ",0															;Variable to prompt user to input a variable
error		BYTE	"The value you entered is either not valid or too large",0								;Variable to inform user of error in input
comma		BYTE	", ",0																					;Variable to display a comma and space
prompt_ptr	DWORD	prompt																					;Variable to point to prompt
numeric		BYTE	LEN DUP(0)																				;Variable to hold the newly translated array of integers
fail		DWORD	0																						;Variale to set if ReadVal fails
array		DWORD	10	DUP(0)																				;Variable to store the 10 user inputted integers
displArray	BYTE	"You inputted: ",0																		;Variable to tell user what they inputted
counter		DWORD	0																						;Variable to track indexing
translate	QWORD	0																						;Variable to hold translated (string -> integer) value during translation proccess
lit			DWORD	0																						;Variable to hold literal value {str[i]-48}
index		DWORD	0																						;Variable to track index of 'array'
sum			DWORD	0																						;Variable to keep track of the sum of all elements in the array
avg			DWORD	0																						;Variable to keep track of the avg of all elements in the array
sum_text	BYTE	"The sum of the values you inputted is: ",0												;Variable to present the user the sum value
avg_text	BYTE	"The average of the values you inputted is: ",0											;Variable to present the user the average value
temp_str	BYTE	12 DUP(0)																				;Variable to store temporary translated string (one single DWORD integer) during 'Backtrack'
count		DWORD	0																						;Variable to keep track of number of BYTES in translated number (in temp_str)
temp_byte	BYTE	1 DUP(0)																				;Varaible to temporarily store ascii version of a digit for printing
ur_string	BYTE	"You entered: ",0																		;Variable to tell the user what 10 integers they entered
byebye		BYTE	"Thanks for playing!", 13, 10, 0														;Variable to say farewell to the user


;----------------------------------- C O D E ----------------------------------------------------------------------------------------------------------------------------------------------

.code

main PROC
;Introduce User
	push OFFSET hello6
	push OFFSET hello5
	push OFFSET hello4
	push OFFSET hello3
	push OFFSET hello2
	push OFFSET hello1
	call Introduction

;Get User Inputs
	push OFFSET index
	push OFFSET lit
	push OFFSET counter
	push OFFSET array
	push OFFSET fail
	push OFFSET error
	push OFFSET translate
	push OFFSET num_input
	push OFFSET prompt
	call Get_Input

;Display Inputs
	push OFFSET ur_string
	push OFFSET	temp_byte
	push OFFSET count
	push OFFSET temp_str
	push OFFSET displArray
	push OFFSET comma
	push OFFSET array
	call Displayer

;Display Average (including the sum)
	push OFFSET avg_text
	push OFFSET sum_text
	push OFFSET array
	push OFFSET sum
	call DisplayAvg

;Display Farewell
	push OFFSET byebye
	call Farewell

exit	; exit to operating system

main ENDP

;-----------------------------------F U N C T I O N------D E F I N T I O N S----------------------------------------------------------------------------------------------

;Procedure to introduce user to the program ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;receives: @hello1,	@hello1, @hello3, @hello4, @hello5, @hello6
;returns: none
;preconditions: none (however, variables must have been pushed to the stack accordingly)
;registers changed: edx
	Introduction PROC
		push ebp
		mov ebp, esp
		pushad

		DisplayString [ebp+8]
		DisplayString [ebp+12]
		call CRLF
		DisplayString [ebp+16]
		DisplayString [ebp+20]
		DisplayString [ebp+24]
		DisplayString [ebp+28]
		
		popad
		pop ebp
		ret 24
	Introduction ENDP


;Procedure to read user input ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;receives:	@fail, @error, @numeric, @num_input, @prompt, @translate, @array counter, @lit, @index
;returns: none
;preconditions: user inputted value must be a valid integer
;registers changed: eax, ebx, ecx, edx, esi, edi (all restored after)
	ReadVal PROC
		pushad
		Ask:
			mov ebx, [ebp+16]	;reset the numeric translated value
			mov eax, 0
			mov [ebx], eax

			mov ebx, [ebp+36]	;reset the literal value
			mov eax, 0
			mov [ebx], eax

			mov esi, [ebp+12] ;Reset input string (ZERO OUT)
			mov ecx, 100
			mov al, 0
			clear_input:
				mov BYTE PTR [esi], al
				add esi, 1
				loop clear_input

			mov esi, [ebp+16] ;Reset output string (ZERO OUT)
			mov ecx, 100
			mov al, 0
			clear_output:
				mov eax, [ebp+16] ;translate
				mov DWORD PTR [eax], 0			
			
			GetString [ebp+8], [ebp+12]


			Check_zero:
				xor esi, esi
				mov esi, [ebp+12]
				cmp BYTE PTR [esi], 48		;check if the value inputted is 0 (48 in ASCII)
				je Bypass
				jmp Not_Zero
				Bypass:
					mov ebx, [ebp+16]
					mov DWORD PTR [ebx], 0		;If value entered is just 0, then bypass the rest of function and just translate it to 0
					jmp Ender

			Not_Zero:

			;Validate user input
			mov esi, [ebp+12]	;set up our 'in-string'
			mov edi, [ebp+16]	;set our 'out-value' for the integer translated version of the user input
			mov ecx, QLEN ;80
			add esi, 19			;start it at 19 bytes in (max space for 64bit number allowed), the rest of the bytes (20-100) should all be 00000000
			xor eax, eax

			Validate_length:			;Check to see if the input fits in 64 bits for the variable translate [ebp+16]
				mov al, [esi]	;move current bytes worth of data (starting from @) into AL
				cmp al, 0
				jg INVALID		;11th to 100th BYTE should all be 00000000
				add esi, 1		;increment by 1 BYTE
				loop Validate_length
															;now we know this value can fit in QWORD
			jmp next_one	;The value is good size-wise

			INVALID:
				mov edx, [ebp+20]	;value is invalid
				call WriteString
				mov DWORD PTR [esi], 0		;reset our input string
				jmp Ask

			next_one:	;now check if negative or not (is the first byte = 45)
				mov esi, [ebp+12]
				xor eax, eax
				mov al, [esi]
				cmp al, 45
				je INVALID

		After:				;We now know our input is 64 bits or less & positive: we dont yet know if its 32 bits (or less) OR consisting of all numbers
		mov esi, [ebp+12]	;set up our 'in-string' again
		xor edx, edx
		cld
		morph:
			xor eax, eax
			lodsb		;mov al, BYTE PTR [esi] move just one byte of data - auto increments by 1 BYTE?
			cmp al, 0	;if its JE (equal) to 00000000 then exit the loop (matters only after the first BYTE)
			je Size_check
			cmp al, 48
			jl INVALID		;even if a single digit is out of the zone -> redo input (INVALID)
			cmp al, 57
			jg INVALID		;breaks this loop
							;We now know this digit is all good to go on all counts ---> translate	

			sub al, 48	;Literal value (Z)
			mov ebx, [ebp+36]	
			mov [ebx], al			;save literal to stack
			mov ebx, [ebp+16]
			mov eax, [ebx]
			mov ebx, 10				
			mul ebx
			mov ebx, [ebp+36]
			add eax, [ebx]			;updated translate value
			cmp eax, 0				;if eax resets due to overflow...user input is invalid
			je INVALID
			mov ebx, [ebp+16]	
			mov [ebx], eax			;save translated value (push the new updated translate value to the stack)
			jmp morph
		;Check to see if the value can fit into 32 bits:
		Size_check:
			;xor edx, edx
			;mov eax, [ebp+16]
			;mov ebx, 4294967295
			;cmp [eax], ebx

			cmp edx, 0				;If edx has a value then that means that the number -
			jne INVALID				;was too large for eax and was extended to edx
			cmp eax, 0
			jne INVALID

		Ender:
		popad
		ret
	ReadVal ENDP


;Procedure to store user input into array ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;receives:	@fail, @error, @numeric, @num_input, @prompt, @translate, @array counter, @lit, @index
;returns: none
;preconditions: user inputted value must be a valid integer, the value must be on the stack at [ebp+16]
;registers changed: eax, ebx, ecx, edx, esi, edi (all restored after)
	FillArray PROC
	;We currently know our converted value is on the stack saved at [ebp+16]:
	pushad
	mov esi, [ebp+28]
	mov eax, 4
	mov ebx, [ebp+40]	
	mul DWORD PTR [ebx] 
	add esi, eax		;move to current index (add 4*index amount of BYTES into the array) then store
	fill:
		xor eax, eax
		mov ebx, [ebp+16]
		mov eax, [ebx]
		mov [esi], eax
		mov eax, [esi]
		mov eax, [ebp+40]
		add BYTE PTR [eax], 1 ;increment index
	popad
	ret
	FillArray ENDP

;Procedure to get user input ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;receives:	@fail, @error, @numeric, @num_input, @prompt, @translate, @array counter, @lit, @index
;returns: none
;preconditions: user inputted value must be a valid integer
;registers changed: eax, ebx, ecx, edx, esi, edi (all restored after)
	Get_Input PROC
	push ebp
	mov ebp, esp

	mov ecx, 10
	mov esi, [ebp+28]
	Ask:
		call ReadVal
		call FillArray
		loop Ask
	pop ebp
	ret 36
	Get_Input ENDP


;Procedure to convert numeric into string of digits and display ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;receives: @array, @comma, @displArray, @temp_str, @count, @temp_byte, @ur_string
;returns: none
;preconditions: user inputted value must be a valid integer, the value must be on the stack at [ebp+16]
;registers changed: eax, ebx, ecx, edx, esi, edi (all restored after)
	WriteVal PROC
		pushad
		DisplayString [ebp+32]
		mov ecx, 11
		cld
		mov edi, [ebp+20]			; we want to first clear our the temp string so we dont have leftover data
		mov al, 0

		clear_input:
			stosb
			loop clear_input

		xor eax, eax
		xor ebx, ebx
		mov eax, DWORD PTR [esi]
		mov ebx, 10
		mov edi, [ebp+20]			;temp_str for holding translated value
		cld
		Backtrack:
			xor edx, edx
			mov ebx, 10
			div ebx			;eax/ebx -> remainder in edx
			add edx, 48		;convert to ASCII
			mov ebx, eax
			mov eax, edx
			stosb			;store into temp_str (going to be inputting backwards)
			mov eax, ebx
			cmp eax, 0
			jne Backtrack

		Reverse:			;temp_str now contains backwards version of the number
			xor esi, esi
			xor eax, eax
			xor ebx, ebx
			mov esi, [ebp+20]
			mov ebx, [ebp+24]
			mov DWORD PTR [ebx], 0
			count_loop:						;track the number of number of BYTES in translated number (in temp_str)
				mov al, BYTE PTR [esi]
				cmp al, 0
				je finished
				add esi, 1
				add DWORD PTR [ebx], 1
				jmp count_loop
			
			finished:	;we now know the count stored in [ebp+24]
				mov eax, [ebp+24]
				mov ecx, [eax]
				xor esi, esi
				mov esi, [ebp+20]
				mov ebx, [eax]
				sub ebx, 1
				add esi, ebx		;start the pointer to the string at the number of elements (minus 1) to account for addressing

				display_reverse:
					xor ebx, ebx
					xor eax, eax
					mov ebx, [ebp+28]
					mov al, BYTE PTR [esi]
					mov [ebx], eax
					DisplayString ebx
					sub esi, 1
					loop display_reverse

			mov edx, [ebp+12] ;comma
			call WriteString
		popad
		ret
	WriteVal ENDP

;Procedure to display the user array ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;receives: @array, @comma, @displArray, @temp_str, @count, @temp_byte, @ur_string
;returns: none
;preconditions: user inputted value must be a valid integer, the value must be on the stack at [ebp+16]
;registers changed: eax, ebx, ecx, edx, esi, edi (all restored after)
	Displayer PROC
	push ebp
	mov ebp, esp
	pushad
		call CRLF
		mov ecx, 10
		mov esi, [ebp+8]
		display:
			call WriteVal
			add esi, 4			;increment array
			loop display
		call CRLF
		call CRLF
	popad
	pop ebp
	ret 28
	Displayer ENDP

;Procedure to display the sum of user array ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;receives: @array, @sum, @sum_text
;returns: none
;preconditions: array must contain all valid integers (10), @sum must be pushed to the stack
;registers changed: eax, ebx, esi, edx (all restored after)
	DisplaySum PROC
	pushad
	mov esi, [ebp+12]	;array
	mov ecx, 10
		;sum

	Summer:					;Sum up all of the elements in the array (for loop)
		mov ebx, [esi]
		mov eax, [ebp+8]
		add [eax], ebx
		add esi, 4
		loop Summer

	DisplayString [ebp+16]	;Displays the sum value	
	mov ebx, [ebp+8]
	mov eax, [ebx]
	call WriteDec
	call CRLF

	popad
	ret
	DisplaySum ENDP

;Procedure to display the avg of user array ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;receives: @array, @sum, @sum_text, @avg_text
;returns: none
;preconditions: array must contain all valid integers (10)
;registers changed: eax, ebx, esi, edx (all restored after)
	DisplayAvg PROC
	push ebp
	mov ebp, esp
	pushad

	call DisplaySum			;Display the sum
	DisplayString [ebp+20]
	xor edx, edx
	mov ebx, [ebp+8]
	mov eax, [ebx]			;Divide by 10 (num_elements) to get average
	mov ebx, 10
	div ebx
	call WriteDec			;Display the average

	call CRLF
	call CRLF
	popad
	pop ebp
	ret 16
	DisplayAvg ENDP

;Procedure to display farewell message to user ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;receives: @byebye
;returns: none
;preconditions: byebye must be valid string
;registers changed: edx (all restored after)
	Farewell PROC
	push ebp
	mov ebp, esp
	pushad
	call CRLF
	DisplayString [ebp+8]	;Say farewell to user
	call CRLF
	popad
	pop ebp
	ret 4
	Farewell ENDP

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
END main