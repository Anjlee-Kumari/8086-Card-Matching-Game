org 100h

jmp start

; ==========================================
; CARD MATCHING GAME
; 8086 / EMU8086
; 4 x 4 BOARD
; 8 PAIRS
; 12 ATTEMPTS
; ==========================================

board db 1,5,3,8
      db 6,2,7,4
      db 8,3,1,6
      db 4,7,5,2

matched db 16 dup(0)

curRow db 0
curCol db 0

firstCard db 0FFh
secondCard db 0FFh

attempts db 0
pairs db 0

tempIndex db 0
tempRow db 0
tempCol db 0

; Used to remember selected cards
savedFirst db 0
savedSecond db 0


; ==========================================
; MESSAGES
; ==========================================

msgTitle db 13,10
db ' CARD MATCHING GAME',13,10
db ' ==================',13,10,13,10,'$'

msgAttempts db ' Attempts: $'
msgPairs db '    Pairs: $'

msgControls db 13,10,13,10
db ' Arrow Keys = Move   R = Restart',13,10
db ' ENTER = Select      ESC = Exit',13,10,'$'

msgWin db 13,10,13,10
db ' =====================',13,10
db ' CONGRATULATIONS! YOU WIN :)',13,10
db ' =====================',13,10
db ' All 8 pairs found!',13,10,13,10
db ' Press R to restart',13,10
db ' Press ESC to exit',13,10,'$'

msgLose db 13,10,13,10
db ' =====================',13,10
db ' GAME OVER! :(',13,10
db ' =====================',13,10
db ' You used 12 attempts.',13,10,13,10
db ' Press R to restart',13,10
db ' Press ESC to exit',13,10,'$'


; ==========================================
; START
; ==========================================

start:

call initGame

; Draw complete screen only once
call drawScreen


; ==========================================
; MAIN LOOP
; ==========================================

mainLoop:

    ; Wait for keyboard key
    mov ah,00h
    int 16h


    ; ======================================
    ; ARROW KEYS
    ; ======================================

    cmp ah,48h
    je moveUp

    cmp ah,50h
    je moveDown

    cmp ah,4Bh
    je moveLeft

    cmp ah,4Dh
    je moveRight


    ; ======================================
    ; ESC
    ; ======================================

    cmp al,27
    je exitGame


    ; ======================================
    ; R / r
    ; ======================================

    cmp al,'r'
    je restartGame

    cmp al,'R'
    je restartGame


    ; ======================================
    ; ENTER
    ; ======================================

    cmp al,13
    je selectCard

    ; Other keys do nothing
    jmp mainLoop


; ==========================================
; MOVE UP
; ==========================================

moveUp:

    cmp curRow,0
    je mainLoop

    ; Save old position
    mov al,curRow
    mov tempRow,al

    mov al,curCol
    mov tempCol,al

    ; Move logical cursor
    dec curRow

    call updateCursor

    jmp mainLoop


; ==========================================
; MOVE DOWN
; ==========================================

moveDown:

    cmp curRow,3
    je mainLoop

    ; Save old position
    mov al,curRow
    mov tempRow,al

    mov al,curCol
    mov tempCol,al

    ; Move logical cursor
    inc curRow

    call updateCursor

    jmp mainLoop


; ==========================================
; MOVE LEFT
; ==========================================

moveLeft:

    cmp curCol,0
    je mainLoop

    ; Save old position
    mov al,curRow
    mov tempRow,al

    mov al,curCol
    mov tempCol,al

    ; Move logical cursor
    dec curCol

    call updateCursor

    jmp mainLoop


; ==========================================
; MOVE RIGHT
; ==========================================

moveRight:

    cmp curCol,3
    je mainLoop

    ; Save old position
    mov al,curRow
    mov tempRow,al

    mov al,curCol
    mov tempCol,al

    ; Move logical cursor
    inc curCol

    call updateCursor

    jmp mainLoop


; ==========================================
; UPDATE CURSOR
;
; Only removes old >
; and places new >
;
; No screen redraw
; ==========================================

updateCursor:

    ; --------------------------------------
    ; Remove > from old position
    ; --------------------------------------

    call setCardPosition

    mov dl,' '
    mov ah,02h
    int 21h


    ; --------------------------------------
    ; Put > at new position
    ; --------------------------------------

    mov al,curRow
    mov tempRow,al

    mov al,curCol
    mov tempCol,al

    call setCardPosition

    mov dl,'>'
    mov ah,02h
    int 21h

    ret


; ==========================================
; SELECT CARD
; ==========================================

selectCard:

    call getIndex


    ; ======================================
    ; Check if card is already matched
    ; ======================================

    xor bx,bx
    mov bl,tempIndex

    cmp matched[bx],1
    je mainLoop


    ; ======================================
    ; FIRST CARD
    ; ======================================

    cmp firstCard,0FFh
    je selectFirst


    ; ======================================
    ; DON'T SELECT SAME CARD
    ; ======================================

    mov al,firstCard
    cmp al,tempIndex
    je mainLoop


    ; ======================================
    ; SECOND CARD
    ; ======================================

    mov al,tempIndex
    mov secondCard,al


    ; Save both card indexes
    mov al,firstCard
    mov savedFirst,al

    mov al,secondCard
    mov savedSecond,al


    ; One attempt completed
    inc attempts


    ; --------------------------------------
    ; Show second selected card
    ; --------------------------------------

    call drawCurrentCard


    ; --------------------------------------
    ; Update Attempts only
    ; --------------------------------------

    call updateAttempts


    ; --------------------------------------
    ; Give player time to see both cards
    ; --------------------------------------

    call delay


    ; --------------------------------------
    ; Check match
    ; --------------------------------------

    call checkMatch


    ; --------------------------------------
    ; Clear selections
    ; --------------------------------------

    mov firstCard,0FFh
    mov secondCard,0FFh


    ; --------------------------------------
    ; Redraw first card
    ;
    ; Matched = number
    ; Wrong    = ?
    ; --------------------------------------

    mov al,savedFirst
    call drawIndexCard


    ; --------------------------------------
    ; Redraw second card
    ; --------------------------------------

    mov al,savedSecond
    call drawIndexCard


    ; --------------------------------------
    ; Update Pairs only
    ; --------------------------------------

    call updatePairs


    ; --------------------------------------
    ; IMPORTANT:
    ; Restore screen cursor to current card
    ; --------------------------------------

    mov al,curRow
    mov tempRow,al

    mov al,curCol
    mov tempCol,al

    call setCardPosition


    ; ======================================
    ; CHECK WIN
    ; ======================================

    cmp pairs,8
    je winGame


    ; ======================================
    ; CHECK GAME OVER
    ; ======================================

    cmp attempts,12
    jae loseGame

    jmp mainLoop


; ==========================================
; SELECT FIRST CARD
; ==========================================

selectFirst:

    mov al,tempIndex
    mov firstCard,al

    ; Show selected card only
    call drawCurrentCard

    jmp mainLoop


; ==========================================
; GET CARD INDEX
;
; index = row * 4 + column
; ==========================================

getIndex:

    mov al,curRow
    mov ah,0

    mov bl,4
    mul bl

    add al,curCol

    mov tempIndex,al

    ret


; ==========================================
; CHECK MATCH
; ==========================================

checkMatch:

    ; Get first card value

    xor bx,bx
    mov bl,firstCard

    mov al,board[bx]


    ; Get second card index

    xor bx,bx
    mov bl,secondCard


    ; Compare values

    cmp al,board[bx]
    jne noMatch


    ; ======================================
    ; MATCH FOUND
    ; ======================================

    xor bx,bx
    mov bl,firstCard

    mov matched[bx],1


    xor bx,bx
    mov bl,secondCard

    mov matched[bx],1

    inc pairs

noMatch:

    ret


; ==========================================
; DRAW SCREEN
;
; Complete screen is drawn only at:
; START / RESTART
; ==========================================

drawScreen:

    call clearScreen


    ; ======================================
    ; Title
    ; ======================================

    mov dx,offset msgTitle
    call printString


    ; ======================================
    ; ATTEMPTS
    ; ======================================

    mov dx,offset msgAttempts
    call printString

    mov al,attempts
    call printNumber
    
    mov dl,' '
    mov ah,02h
    int 21h 
   
    mov dl,'/'
    mov ah,02h
    int 21h

    mov dl,'1'
    mov ah,02h
    int 21h

    mov dl,'2'
    mov ah,02h
    int 21h 
    


    ; ======================================
    ; PAIRS
    ; ======================================

    mov dx,offset msgPairs
    call printString

    mov al,pairs
    call printNumber  
    
    mov dl,' '
    mov ah,02h
    int 21h 

    mov dl,'/'
    mov ah,02h
    int 21h

    mov dl,'8'
    mov ah,02h
    int 21h

    call newLine
  


    ; ======================================
    ; Draw board
    ; ======================================

    call drawBoard


    ; ======================================
    ; Controls
    ; ======================================

    mov dx,offset msgControls
    call printString

    ret


; ==========================================
; DRAW BOARD
; ==========================================

drawBoard:

    mov tempRow,0

drawRow:

    mov tempCol,0

drawColumn:

    call drawCard

    inc tempCol

    cmp tempCol,4
    jb drawColumn

    call newLine

    inc tempRow

    cmp tempRow,4
    jb drawRow

    ret


; ==========================================
; DRAW ONE CARD
; ==========================================

drawCard:

    ; Calculate index

    mov al,tempRow
    mov ah,0

    mov bl,4
    mul bl

    add al,tempCol

    mov tempIndex,al


    ; ======================================
    ; CHECK MATCHED
    ; ======================================

    xor bx,bx
    mov bl,tempIndex

    cmp matched[bx],1
    je showCard


    ; ======================================
    ; CHECK FIRST CARD
    ; ======================================

    mov al,firstCard
    cmp al,tempIndex
    je showCard


    ; ======================================
    ; CHECK SECOND CARD
    ; ======================================

    mov al,secondCard
    cmp al,tempIndex
    je showCard


    ; ======================================
    ; HIDDEN CARD
    ; ======================================

    ; Check cursor position

    mov al,curRow
    cmp al,tempRow
    jne hiddenNormal

    mov al,curCol
    cmp al,tempCol
    jne hiddenNormal


    ; Cursor

    mov dl,'>'
    mov ah,02h
    int 21h

    jmp hiddenCard


hiddenNormal:

    mov dl,' '
    mov ah,02h
    int 21h


hiddenCard:

    mov dl,'['
    mov ah,02h
    int 21h

    mov dl,'?'
    mov ah,02h
    int 21h

    mov dl,']'
    mov ah,02h
    int 21h

    mov dl,' '
    mov ah,02h
    int 21h

    ret


; ==========================================
; SHOW CARD
; ==========================================

showCard:

    ; Check cursor

    mov al,curRow
    cmp al,tempRow
    jne showNormal

    mov al,curCol
    cmp al,tempCol
    jne showNormal


    ; Cursor

    mov dl,'>'
    mov ah,02h
    int 21h

    jmp showNumber


showNormal:

    mov dl,' '
    mov ah,02h
    int 21h


showNumber:

    mov dl,'['
    mov ah,02h
    int 21h


    ; Get card number

    xor bx,bx
    mov bl,tempIndex

    mov dl,board[bx]

    add dl,'0'

    mov ah,02h
    int 21h


    mov dl,']'
    mov ah,02h
    int 21h

    mov dl,' '
    mov ah,02h
    int 21h

    ret


; ==========================================
; DRAW CURRENT CARD
;
; Used when ENTER is pressed
; ==========================================

drawCurrentCard:

    mov al,curRow
    mov tempRow,al

    mov al,curCol
    mov tempCol,al

    call setCardPosition

    call drawCard

    ret


; ==========================================
; DRAW CARD USING INDEX
;
; AL = card index 0-15
; ==========================================

drawIndexCard:

    mov tempIndex,al

    ; index / 4
    ; AL = row
    ; AH = column

    mov ah,0
    mov bl,4
    div bl

    mov tempRow,al
    mov tempCol,ah

    call setCardPosition

    call drawCard

    ret


; ==========================================
; SET SCREEN POSITION OF CARD
;
; Board starts at screen row 5
;
; Each card takes 5 columns:
;
; 0, 5, 10, 15
; ==========================================

setCardPosition:

    ; Screen row = tempRow + 5

    mov dh,tempRow
    add dh,5


    ; Screen column = tempCol * 5

    mov al,tempCol
    mov ah,0

    mov bl,5
    mul bl

    mov dl,al


    ; Set cursor position
    ; BH = video page 0

    mov bh,0
    mov ah,02h
    int 10h

    ret


; ==========================================
; UPDATE ATTEMPTS
; ==========================================

updateAttempts:

    mov dh,4
    mov dl,11

    mov bh,0
    mov ah,02h
    int 10h
    
    ; Clear old number
    mov dl,' '
    mov ah,02h
    int 21h 
    
    mov dl,' '
    mov ah,02h
    int 21h 
    
    
    ; Go back to number position
    mov dl,11
    mov bh,0
    mov ah,02h
    int 10h

    mov al,attempts
    call printNumber

    ret


; ==========================================
; UPDATE PAIRS
; ==========================================

updatePairs:

    mov dh,4
    mov dl,27

    mov bh,0
    mov ah,02h
    int 10h  
    
    ; Clear old number
    mov dl,' '
    mov ah,02h
    int 21h 
    
    mov dl,' '
    mov ah,02h
    int 21h 
    
    
    ; Go back to number position
    mov dl,27
    mov bh,0
    mov ah,02h
    int 10h

    mov al,pairs
    call printNumber

    ret


; ==========================================
; PRINT STRING
; ==========================================

printString:

    mov ah,09h
    int 21h

    ret


; ==========================================
; PRINT NUMBER
; AL = 0 to 99
; ==========================================

printNumber:

    mov ah,0

    cmp al,10
    jb printSingle


    mov bl,10
    div bl

    mov bh,ah

    add al,'0'

    mov dl,al
    mov ah,02h
    int 21h

    mov dl,bh
    add dl,'0'

    mov ah,02h
    int 21h

    ret


printSingle:

    add al,'0'

    mov dl,al
    mov ah,02h
    int 21h

    ret


; ==========================================
; NEW LINE
; ==========================================

newLine:

    mov dl,13
    mov ah,02h
    int 21h

    mov dl,10
    mov ah,02h
    int 21h

    ret


; ==========================================
; CLEAR SCREEN
; ==========================================

clearScreen:

    mov ax,0003h
    int 10h

    ret


; ==========================================
; DELAY
; ==========================================

delay:

    mov cx,1

delayOuter:

    mov dx,50h

delayInner:

    dec dx
    jnz delayInner

    loop delayOuter

    ret


; ==========================================
; INITIALIZE GAME
; ==========================================

initGame:

    mov curRow,0
    mov curCol,0

    mov firstCard,0FFh
    mov secondCard,0FFh

    mov attempts,0
    mov pairs,0


    ; Reset matched array

    mov cx,16
    mov bx,0

resetMatched:

    mov matched[bx],0

    inc bx

    loop resetMatched

    ret


; ==========================================
; WIN SCREEN
; ==========================================

winGame:

    call clearScreen

    mov dx,offset msgWin
    call printString


winWait:

    mov ah,00h
    int 16h

    cmp al,27
    je exitGame

    cmp al,'r'
    je restartGame

    cmp al,'R'
    je restartGame

    jmp winWait


; ==========================================
; GAME OVER SCREEN
; ==========================================

loseGame:

    call clearScreen

    mov dx,offset msgLose
    call printString


loseWait:

    mov ah,00h
    int 16h

    cmp al,27
    je exitGame

    cmp al,'r'
    je restartGame

    cmp al,'R'
    je restartGame

    jmp loseWait


; ==========================================
; RESTART
; ==========================================

restartGame:

    call initGame

    ; Complete screen redraw only on restart
    call drawScreen

    jmp mainLoop


; ==========================================
; EXIT
; ==========================================

exitGame:

    mov ax,0003h
    int 10h

    mov ax,4C00h
    int 21h