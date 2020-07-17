TITLE Portfolio Assignment   (program6_boothpat.asm)

;-------------------------------------------------------------------
; Author: Patricia Booth
; Last Modified: 5/26/20
; OSU email address: boothpat@oregonstate.edu
; Course number/section: CS271-400
; Project Number: 6          Due Date: 06/07/20
; Description: This basic function of this program is it takes
; 10 numbers and stores these numbers in an array and calculates
; the sum and average. The results are then displayed for the users.
; Behind the scenes, in-depth integer and string manipulation is done
; to convert between the two using ReadVal and WriteVal. These procedures
; take advantage of stosb and lodsb to perform these actions. In addition,
; Validation is taken into consideration with the 32-bit SIGNED integer
; limit and inserting positive or negative symbols. Aside these symbols,
; special characters are validated against. The general flow of this 
; program is:
; ** Get User Input as String and Make Integer
; ** Place in integer array
; ** Calculate sum and average
; ** Make each integer a string
; ** Print results
; IMPLEMENTATION NOTES: Macros are used in this program.
;-------------------------------------------------------------------

INCLUDE Irvine32.inc

;------------------------------------------------
; MACRO DEFINITIONS
;------------------------------------------------

; ------------------------------------------------------------------
; Macro: getString
; Description: Prints prompt and retrieves user input and stores it
; Receives: Reference to prompt string, where number is stored,
;		    and storage of how long the number is
; Returns: None
; Preconditions: Appropriate prompt string is used so user is aware
;                of what number to enter. Variables for numbers.
; Postconditions: Registers changed: EDX, ECX, EAX
; Note: This procedure uses Irvine's ReadString to receive input.
; ------------------------------------------------------------------


getString			MACRO	promptReference, numLocate, numLength
	pushad
	displayString	promptReference
	mov				edx, numLocate
	mov				ecx, 30
	call			ReadString
	mov				numLength, eax
	popad
ENDM

; ------------------------------------------------------------------
; Macro: displayString
; Description: Prints a string by calling Irvine's WriteString
; Receives: Reference to string
; Returns: None
; Preconditions: Appropriate string reference is used for parameter
; Postconditions: Registers changed: EDX
; ------------------------------------------------------------------

displayString		MACRO	stringReference
	pushad
	mov				edx, stringReference
	call			WriteString
	popad
ENDM

;------------------------------------------------
; END OF MACRO DEFINITIONS
;------------------------------------------------

; Constants used in program

; **Note about limits: The LOWER_LIMIT is set as a positive number
; as I do the comparison on an unsigned number and negate the 
; number at a later point at the program.

	UPPER_LIMIT = 2147483647
	LOWER_LIMIT = 2147483648 ; Used as -2147483648
	ARRAY_SIZE = 10

.data

; Strings used throughout program

	intro_1			BYTE	"Project 6: I/O Procedures and Macros", 0
	intro_2			BYTE	"Programmed by Patricia Booth", 0
	intro_3			BYTE	"You may provide 10 signed decimal integers.", 0
	intro_4			BYTE	"Each number should fit inside a 32-bit ",
							"register.", 0
	intro_5			BYTE	"After input: Integer list, sum, and average ",
							"will be displayed.", 0

	num_prompt		BYTE	"Please enter a signed number: ", 0
	num_tryagain	BYTE	"Please try again: ", 0
	
	err_message		BYTE	"ERROR: Not signed number or ",
							"number too big. ", 0

	result_num		BYTE	"You entered the following numbers: ", 0
	result_sum		BYTE	"The sum of these numbers is: ", 0
	result_avg		BYTE	"The rounded average is: ", 0
	result_com		BYTE	", " , 0

	outro_1			BYTE	"Program completed. Have a good summer!", 0

; User Input Variables

	digit_string	BYTE	31 DUP(0)
	digit_length	DWORD	0

; Arrays
	
	num_list		DWORD	ARRAY_SIZE DUP(?)
	result_str		BYTE	31 DUP(0)
	reset_str		BYTE	31 DUP(0)
	correct_str		BYTE	31 DUP(0)

; Integers

	integer_num		DWORD	0
	array_sum		DWORD	0
	array_avg		DWORD	0

; Boolean

	is_invalid		DWORD	0

.code
main PROC

; Introduce User to Program

	push			OFFSET intro_1
	push			OFFSET intro_2
	push			OFFSET intro_3
	push			OFFSET intro_4
	push			OFFSET intro_5
	call			userIntro

; Collect User Input. After validating, place into array.

	push			OFFSET is_invalid
	push			OFFSET integer_num
	push			OFFSET digit_length
	push			OFFSET digit_string
	push			UPPER_LIMIT
	push			LOWER_LIMIT
	push			OFFSET num_list
	push			ARRAY_SIZE
	push			OFFSET num_prompt
	push			OFFSET num_tryagain
	push			OFFSET err_message
	call			ReadVal

; Calculate the sum of the array

	push			OFFSET num_list
	push			ARRAY_SIZE
	push			OFFSET array_sum
	call			calcSum

; Calculate the average of the array

	push			ARRAY_SIZE
	push			OFFSET array_sum
	push			OFFSET array_avg
	call			calcAvg

; Display results (calls subprocedure WriteVal within)

	push			OFFSET correct_str
	push			OFFSET reset_str
	push			OFFSET result_str
	push			OFFSET result_num
	push			OFFSET result_sum
	push			OFFSET result_avg
	push			OFFSET result_com
	push			ARRAY_SIZE
	push			OFFSET num_list
	push			OFFSET array_sum
	push			OFFSET array_avg
	call			displayResult

; User Goodbye

	push			OFFSET outro_1
	call			userOutro

	exit

main ENDP

;------------------------------------------------
; PROCEDURE DEFINITIONS
;------------------------------------------------

; ------------------------------------------------------------------
; Procedure: userIntro
; Description: Prints user introduction that includes functionality
;              of program
; Receives: [24] intro_1 (reference), [20] intro_2 (reference),
;          [16] intro_3 (reference), [12] intro_4 (reference),
;          [8] intro_5 (reference)
; Returns: None
; Preconditions: Intro string references are pushed onto stack
; Postconditions: Registers changed: Within displayString, EDX
; ------------------------------------------------------------------

userIntro PROC
	push			ebp
	mov				ebp, esp
	pushad
	
	displayString	[ebp+24]
	call			CrLF
	displayString	[ebp+20]
	call			CrLF
	displayString	[ebp+16]
	call			CrLF
	displayString	[ebp+12]
	call			CrLF
	displayString	[ebp+8]
	call			CrLF
	call			CrLF

	popad
	pop				ebp
	ret				20
userIntro ENDP

; ------------------------------------------------------------------
; Procedure: ReadVal
; Description: ReadVal retrieves user input using getString macro, then
;              converts to integer and validates the input to fill
;              number array (This conversion is done by calling
;              stringToInteger).
; Receives: [48], is_invalid (reference), [44] integer_num (reference)
;           [40] digit_length (reference), [36] digit_string (reference)
;			[32] UPPER_LIMIT (value), [28] LOWER_LIMIT (value)
;			[24] num_list (reference), [20] ARRAY_SIZE (value)
;			[16] num_prompt (reference), [12] num_tryagain (reference)
;           [8] err_message (reference)
; Returns: None
; Preconditions: Neccessary variables are pushed to stack beforehand
; Postconditions: Registers changed: EAX, EBX, ECX, EDX, EDI
; NOTE: Based on pseudocode implementation from Lecture 23,
;       by Paul Paulson
; ------------------------------------------------------------------


ReadVal PROC
	push			ebp
	mov				ebp, esp
	pushad

; Initialize Fill Loop
	mov				ecx, [ebp+20] ; ARRAY_SIZE
	mov				edi, [ebp+24] ; Number Array
FillArray:

; Get number string from user
	getString		[ebp+16], [ebp+36], [ebp+40]

TryAgain:
	mov				ebx, [ebp+48] ; Reset invalid bool
	mov				eax, 0
	mov				[ebx], eax

; Convert String to Integer

	push			[ebp+32] ; UPPER_LIMIT
	push			[ebp+28] ; LOWER_LIMIT
	push			[ebp+48] ; Valid bool indicator
	push			[ebp+40] ; Length of digit string
	push			[ebp+36] ; Digit String
	push			[ebp+44] ; Integer Number
	call			stringToInteger

; Print error message if invalid and request input again
; 1 = INVALID INPUT, 0 = VALID INPUT

	mov				ebx, [ebp+48]
	mov				edx, [ebx]
	cmp				edx, 1
	jne				ValidInteger

ErrorMessage:
	displayString	[ebp+8]
	getString		[ebp+12], [ebp+36], [ebp+40]
	jmp				TryAgain

; Insert converted integer onto number list
ValidInteger:
	mov				ebx, [ebp+44]
	mov				eax, [ebx]
	mov				[edi], eax
	add				edi, 4
	loop			FillArray

	popad
	pop				ebp
	ret				44
ReadVal ENDP

; ------------------------------------------------------------------
; Procedure: stringToInteger
; Description: This function converts string to integer and 
;              validates. If the number is invalid, it sets 
;              the is_invalid reference bool to false.           
; Receives: [28] UPPER_LIMIT (value),
;			[24] LOWER_LIMIT (value), [20] is_invalid (reference)
;			[16] digit_length (reference), [12], digit_string
;			(reference), [8] integer_num (reference)
; Returns: None
; Preconditions: Necessary variables and constants pushed to stack
; Postconditions: Registers changed: EAX, EBX, ECX, EDX, ESI, AL
; ------------------------------------------------------------------

stringToInteger PROC
	push			ebp
	mov				ebp, esp
	pushad
; Check if string has "+" or "-" at begininning
	mov				esi, [ebp+12]
	mov				edi, 0 ; Negative = 1, Positive = 0
	mov				edx, 0 ; Has begin symbol = 1, Has not = 0
	cld
	lodsb
	cmp				al, 43 ; ++ Positive ++
	je				SetSymbol
	cmp				al, 45 ; -- Negative --
	je				SetNegative
	jmp				BeginConvert
SetNegative:
	mov				edi, 1
SetSymbol:
	mov				edx, 1
; Convert String to Integer
BeginConvert:
	mov				ecx, [ebp+16] ; Digit Length
	mov				esi, [ebp+12] ; Digit String
	mov				eax, 0 ; x = 0
	mov				ebx, 0 ; k = 0
	cld
	cmp				edx, 0
	je				CharToInt
MoveForward: ; Activated if there is +/- symbol in the beginning
	inc				esi
	dec				ecx
CharToInt:
	lodsb
; Check if character is longer than 10 digits, therefore bigger
; than 32-bit integer limit
	cmp				ecx, 11
	jge				SetInvalid			
LastNumberCheck:
; Check if character is a valid number (0 - 9)
; 48 <= character <= 57
	cmp				al, 48
	jl				SetInvalid
	cmp				al, 57
	jg				SetInvalid
; Character is number, continue with conversion
	imul			ebx, 10 ; k * 10
	sub				al, 48 ; Single character modified to integer
	movsx			edx, al ; x = ( k * 10 ) + modified integer
	add				ebx, edx
	mov				eax, ebx
	jmp				EndCharToInt
SetInvalid:
	push			ebx
	mov				edx, [ebp+20]
	mov				ebx, 1
	mov				[edx], ebx
	pop				ebx
EndCharToInt:
	loop			CharToInt
; Change number to negative based on EBX register
	cmp				edi, 0
	je				ValidatePosRange
;	[28] UPPER_LIMIT = 2147483647
;	[24] LOWER_LIMIT = 2147483648 (Checks this if negative bool is set)
ValidateNegRange:
	cmp				eax, [ebp+24]
	ja				SetInvalidRange
	jmp				ChangeToNegative	
ValidatePosRange:
	cmp				eax, [ebp+28]
	ja				SetInvalidRange
	jmp				AssignInteger
SetInvalidRange:
	push			ebx
	mov				edx, [ebp+20]
	mov				ebx, 1
	mov				[edx], ebx
	pop				ebx
ChangeToNegative:
	neg				eax
AssignInteger: ; Assign converted integer
	mov				ebx, [ebp+8] 
	mov				[ebx], eax

	popad
	pop				ebp
	ret				24
stringToInteger ENDP

; ------------------------------------------------------------------
; Procedure: calcSum
; Description: Calculates the sum of a reference to a number array
;              given the size of the array. Stores each number in 
;              accumulator and continually adds until end of array.
; Receives: [16] num_list (reference), [12] ARRAY_SIZE (value),
;           [8] array_sum (reference)
; Returns: None
; Preconditions: Variables and constant are pushed to stack
; Postconditions: Registers changed: EAX, EBX, ECX, ESI
; ------------------------------------------------------------------

calcSum PROC
	push			ebp
	mov				ebp, esp
	pushad

	mov				ecx, [ebp+12]
	mov				esi, [ebp+16]
	mov				eax, 0
AddNumbers:
	add				eax, [esi]
	add				esi, 4
	loop			AddNumbers
; Assign sum 
	mov				ebx, [ebp+8]
	mov				[ebx], eax

	popad
	pop				ebp
	ret				12
calcSum ENDP

; ------------------------------------------------------------------
; Procedure: calcAvg
; Description: Given a number list and its sum, this procedure
;              calculates the average of a number array by doing
;              the following: Dividing the sum by array size.
; Receives: [16] ARRAY_SIZE (value), [12] array_sum (reference),
;           [8] array_avg (reference)
; Returns: None
; Preconditions: Variables and constant are pushed to stack.
; Postconditions: Registers changed: EAX, EBX, ECX, EDX (by division)
; NOTE: Average is rounded down for this case.
; ------------------------------------------------------------------

calcAvg PROC
	push			ebp
	mov				ebp, esp
	pushad

	mov				ebx, [ebp+12]
	mov				eax, [ebx]
	cdq
	mov				ecx, [ebp+16]
	idiv			ecx
; Assign average 
	mov				ebx, [ebp+8]
	mov				[ebx], eax

	popad
	pop				ebp
	ret				12
calcAvg ENDP

; ------------------------------------------------------------------
; Procedure: displayResult
; Description: By calling displayString macro and WriteVal procedure,
;              the displayResult prints the list of numbers, the 
;              sum, and the average.
; Receives: [48] correct_str (reference),
;			[44] reset_str (reference), [40] result_str
;			[36] result_num (reference), [32], result_sum (reference),
;			[28] result_avg (reference), [24], result_com (reference)
;			[20] ARRAY_SIZE (value), [16] num_list (reference),
;           [12] array_sum (reference), [8] array_avg (reference)
; Returns: None
; Preconditions: References have appropriate values assigned and
;                are pushed to stack
; Postconditions: Registers changed: ECX, ESI
; ------------------------------------------------------------------

displayResult PROC
	push			ebp
	mov				ebp, esp
	pushad
; Print numbers in Array
	call			CrLF
	displayString	[ebp+36] 
	mov				ecx, [ebp+20]
	mov				esi, [ebp+16]
	call			CrLF
PrintLoop:
	push			[ebp+48]
	push			[ebp+44]
	push			esi
	push			[ebp+40]
	call			WriteVal
; Don't add comma at end of number list
	cmp				ecx, 1
	je				EndPrint
	displayString	[ebp+24]
EndPrint:
	add				esi, 4
	loop			PrintLoop

; Print sum
	call			CrLF
	displayString	[ebp+32]
	push			[ebp+48] ; correct_str
	push			[ebp+44] ; reset_str
	push			[ebp+12] ; array_sum
	push			[ebp+40] ; result_str
	call			WriteVal
; Print average
	call			CrLF
	displayString	[ebp+28]
	push			[ebp+48] 
	push			[ebp+44]
	push			[ebp+8]
	push			[ebp+40]
	call			WriteVal

	popad
	pop				ebp
	ret				44
displayResult ENDP

; ------------------------------------------------------------------
; Procedure: WriteVal
; Description: Converts an integer to string and displays the string
;              using displayString macro
; Receives: [20] correct_str (reference), [16] reset_str (reference)
;			[12] Integer reference, [8] result_str (reference)
; Returns: None
; Preconditions: Appropriate references pushed to stack
; Postconditions: Registers changed: EAX, EBX, EDX, EDI, ESI
; ------------------------------------------------------------------


WriteVal PROC
	push			ebp
	mov				ebp, esp
	pushad

; Clear Numbers so String is Empty again

	push			[ebp+8] 
	push			[ebp+16] ; Reset String
	call			resetNumbers
	push			[ebp+20] 
	push			[ebp+16]
	call			resetNumbers

; Initialize variables and check positive/negative status

	mov				ecx, [ebp+12] ; Integer
	mov				eax, [ecx]
	mov				edx, 0 ; 0 = Positive, 1 = Negative
	mov				ebx, 0 ; 0 = Nonzero, 1 = Is a zero
	cmp				eax, 0
	je				IsZero
	jg				NotNegative
NegativeNum:
	neg				eax
	mov				edx, 1
	jmp				NotNegative
IsZero:
	mov				ebx, 1
NotNegative:
	push			edx ; Save bool registers, EDX & EBX
	push			ebx

; Convert numbers and insert in string using stosb

	mov				ebx, 10 ; Divisor
	mov				edi, [ebp+8] ; Result String
	cld
ZeroCheck: ; Indicates no more numbers to divide, end of digits reached.
	cmp				eax, 0
	cdq
	je				EndConvert
IntToChar:
	div				ebx
	add				edx, 48 ; ASCII conversion
	push			eax
	mov				eax, edx
	stosb
	pop				eax
	jmp				ZeroCheck
EndConvert:
	pop				ebx ; Restore bool registers, EDX & EBX
	pop				edx

; Add additional symbols based on bool indicator
	cmp				edx, 1
	jne				InsertZero
	mov				eax, 45 ; "-" symbol
	stosb
InsertZero:
	cmp				ebx, 1
	jne				CorrectOrder
	mov				eax, 48 ; "zero"
	stosb
CorrectOrder:
	push			[ebp+8] ; Backward string
	push			[ebp+20] ; Will store correct string after reverse call
	call			reverseString

ShowNumber:
	mov				esi, [ebp+20]
	displayString	esi

	popad
	pop				ebp
	ret				16
WriteVal ENDP

; ------------------------------------------------------------------
; Procedure: resetNumbers
; Description: After each iteration of WriteVal, the strings will
;              need to be reset back to default in order to write
;              more strings. This procedure copies a blank string
;              onto a string reference to clear it up.
; Receives: [12] any 31-length string (reference), 
;           [8] reset_str (reference)
; Returns: None
; Preconditions: Appropriate string references are pushed to stack.
; Postconditions: Registers changed: ECX, EDI, ESI
; ------------------------------------------------------------------

resetNumbers PROC
	push			ebp
	mov				ebp, esp
	pushad

	mov				edi, [ebp+12] ; Result String
	mov				esi, [ebp+8] ; Reset String
	mov				ecx, 31 ; String max length
	cld
LoopReset:
	movsb
	loop			LoopReset

	popad
	pop				ebp
	ret				8
resetNumbers ENDP


; ------------------------------------------------------------------
; Procedure: reverseString
; Description: Takes a string and inserts a reversed version in a 
;               different string
; Receives: [12] Old String (reference), [8] New String (reference)
; Returns: None
; Preconditions: String references are pushed to stack. The new
; string should be empty beforehand for proper conversion.
; Postconditions: Registers changed: EAX, EBX, EDI, ESI
; NOTE: This implementation is based on demo6.asm by Paul Paulson.
; ------------------------------------------------------------------

reverseString PROC
	push			ebp
	mov				ebp, esp
	pushad
	
; Count characters in string
	mov				ebx, 0
	mov				esi, [ebp+12] ; Old String
CountChar:
	mov				eax, [esi]
	cmp				eax, 0 ; Check for 0 character which is end of string
	je				DoneCounting
	add				ebx, 1
	inc				esi
	jmp				CountChar
DoneCounting:
	mov				esi, [ebp+12] ;Old String
	mov				edi, [ebp+8] ;New String
	mov				ecx, ebx ; String length 
	sub				ebx, 1
	add				esi, ebx; End of old string
CreateString:
	std
	lodsb			; Get old string character
	cld
	stosb			; Store in new string
	loop			CreateString

	popad
	pop				ebp
	ret				8
reverseString ENDP

; ------------------------------------------------------------------
; Procedure: userOutro
; Description: Prints the user goodbye at the end of program
; Receives: outro_1 (reference) [8]
; Returns: None
; Preconditions: Outro string reference pushed to stack
; Postconditions: Registers changed: EDX (in displayString)
; ------------------------------------------------------------------

userOutro PROC
	push			ebp
	mov				ebp, esp
	pushad

	call			CrLF
	call			CrLF
	displayString	[ebp+8]

	call			CrLF
	popad
	pop				ebp
	ret				4
userOutro ENDP

;------------------------------------------------
; END OF PROCEDURE DEFINITIONS
;------------------------------------------------

END main
