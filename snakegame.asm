;23L2613 & 23L4047


; eating a single apple increases the score ( word 0000 )  by 1 
; W A S D for controls
; dies on self collision and with walls
; starting snake len is 3

[org 0x100]       

jmp start

   
GameOver db 'Game Over!$'
Restart_or_Quit db 0Dh, 0Ah, 'Press R to restart, Q to quit$'
Score db 'Score: $'
Controls db 'Controls: W=Up, A=Left, S=Down, D=Right, Q=Quit$'

; $ → tells DOS where the string ends
   
snake_body db 'o'      
snake_head db 'O'      
FoodSymbol db '@'       
WallSymbol db '*'       
    
    
score dw 0
score_str db '0000$'   
delay_speed dw 0xFFFF  ; snake speed


snakeX times 100 db 0  ; arrays holding the x/y positions of each snake segment ( Reserve 100 bytes )
snakeY times 100 db 0
snake_length db 0
food_x db 0   ; food position
food_y db 0
direction db 0 ; current snake direction ( 0=up , 1=right , 2=down , 3=left )
quit_flag db 0 ; shows if player wants to quit

clear_screen:
    
    mov ax, 0003h   
    int 10h
    ret

start: 

    call GameSet
    call GameLoop
    jmp exitGame

GameSet:
   
    mov ax, 0x0003     ; set video mode
    int 0x10

    mov byte [snake_length], 3 ; starting snake length is 3 
    mov byte [direction], 1    ; starts moving right at start
    

    ; places head at (40,12)
    ; next 2 body segments are behind (39,12) and (38,12)

    ; Snake head initialized at 0
    ; y coordinate is 12 for all kyunke hum 12th row mein hain
    mov byte [snakeX], 40
    mov byte [snakeY], 12
    

    ; second segment of snake
    mov byte [snakeX+1], 39
    mov byte [snakeY+1], 12

    ; third segment of snake
    mov byte [snakeX+2], 38
    mov byte [snakeY+2], 12
    

    ; starting score is 0
    mov word [score], 0

    
    ; clear quit flag
    mov byte [quit_flag], 0

 
    call CreateFood
    call DrawWalls
    call DrawFood
    call DrawSnake
    call show_score
    
    mov ah, 0x02
    mov dx, 0x1701 ; move cursor to bottom of screen so that controls are displayed
    int 0x10
    
    mov ah, 0x09
    mov dx, Controls ; display controls
    int 0x21
    

    ; chota sa wait before game actually starts
    mov cx, 0xFFFF   

InitialDelay:

    nop ; nop means No Operation and it tells CPU to do nothing for 1-cycle
    loop InitialDelay
    ret


GameLoop:

    call ClearOldSnake ; erases snake’s previous position from screen before drawing its new position
    call check_keys   ; if any key pressed for direction
    call move_snake   ; move snake agay one step
    
    call check_collisions
    cmp al, 1
    je near GameOverDisplay  
    
    call check_food
    call DrawFood
    call DrawSnake
    call game_delay
    
    cmp byte [quit_flag], 1
    jne near GameLoop  
    ret


game_delay:

    mov cx, [delay_speed]

DelayLoop:

    nop
    loop DelayLoop
    ret


DrawWalls:

    ; Top Border
    mov ah, 0x02  ; BIOS func to set cursor position
    mov dx, 0x0000 ; row and column
    int 0x10 ; calls BIOS to move cursor there
    
    mov cx, 80 ; width
    mov ah, 0x09  ; write char and attribute multiple times
    mov al, [WallSymbol]
    mov bl, 0x0F
    int 0x10
    
    ; Bottom Border
    mov ah, 0x02
    mov dx, 0x1800
    int 0x10
    
    mov cx, 80
    mov ah, 0x09
    mov al, [WallSymbol]
    mov bl, 0x0F
    int 0x10
    
    ; Side Borders ( starts from row 1 )
    mov dh, 1

DrawVertical:

    cmp dh, 24 ; since 25 rows so check if all done
    jge near DrawWallsCompleted

    ; Left Border
    mov ah, 0x02
    mov dl, 0
    int 0x10
    
    mov ah, 0x09
    mov al, [WallSymbol]
    mov bl, 0x0F
    mov cx, 1
    int 0x10
    
    ; Right Border
    mov ah, 0x02
    mov dl, 79
    int 0x10
    
    mov ah, 0x09
    mov al, [WallSymbol]
    mov bl, 0x0F
    mov cx, 1
    int 0x10

    inc dh
    jmp DrawVertical

DrawWallsCompleted:

    ret

CreateFood:

    mov ah, 0x00    ; get random position thru system timer
    int 0x1A        ; BIOS timer interrupt
     
    ; X-coordinate (1-78) (horizontal position of food)
    mov ax, dx  ; use lower part of timer ticks
    xor dx, dx
    mov bx, 78
    div bx
    inc dl ; inc remainder
    mov [food_x], dl
    
    ; Calculate Y (1-23) ( vertical position of food )
    mov ax, cx
    xor dx, dx
    mov bx, 23
    div bx
    inc dl
    mov [food_y], dl
    
    ; Ensure food is not on snake
    movzx cx, [snake_length]
    cmp cx, 0
    je CreateFoodCompleted
    
CheckSnake: ; check if foods position overlaps wid segment of snakes body

    dec cx ; len of snake ko dec
    cmp cx, 0
    jl CreateFoodCompleted
    
    mov si, cx
    mov al, [snakeX + si]
    cmp al, [food_x]
    jne CheckNext
    mov al, [snakeY+ si]
    cmp al, [food_y]
    je CreateFood
    
CheckNext:

    jmp CheckSnake

CreateFoodCompleted:

    ret

DrawFood:
 
    mov ah, 0x02      ; move cursor to specific pos
    mov dl, [food_x]
    mov dh, [food_y]
    int 0x10
    
    mov ah, 0x09      ; display char at current cursor pos
    mov al, [FoodSymbol]
    mov bl, 0x0C   
    mov cx, 1
    int 0x10
    ret


DrawSnake:

    movzx cx, [snake_length]
    mov si, 0
    cmp cx, 0
    je DrawSnakeCompleted
    
DrawSegment:
   
    mov ah, 0x02
    mov dl, [snakeX + si]
    mov dh, [snakeY+ si]
    int 0x10
    
    mov ah, 0x09
    cmp si, 0
    jne bodyy
    mov al, [snake_head]
    mov bl, 0x09   
    jmp Draww

bodyy:

    mov al, [snake_body]
    mov bl, 0x01   

Draww:

    push cx
    mov cx, 1
    int 0x10
    pop cx
    
    inc si
    cmp si, cx
    jb DrawSegment

DrawSnakeCompleted:

    ret

ClearOldSnake:
    
    movzx cx, [snake_length]
    mov si, 0
    cmp cx, 0
    je ClearOldSnakeCompleted
    
clearr:

    mov ah, 0x02
    mov dl, [snakeX + si]
    mov dh, [snakeY+ si]
    int 0x10
    
    mov ah, 0x09
    mov al, ' '
    mov bl, 0x00
    push cx
    mov cx, 1
    int 0x10
    pop cx
    
    inc si
    cmp si, cx
    jb clearr

ClearOldSnakeCompleted:

    ret


check_keys:

    mov ah, 0x01    
    int 0x16
    jz check_keys_done     ; no key
    
    mov ah, 0x00    
    int 0x16
    
    ; check input
    cmp al, 'w'
    je up
    cmp al, 's'
    je down
    cmp al, 'a'
    je left
    cmp al, 'd'
    je right
    cmp al, 'q'
    je quit
    jmp check_keys_done
    

;  ( 0=up , 1=right , 2=down , 3=left )

up:

    cmp byte [direction], 2  
    je check_keys_done
    mov byte [direction], 0
    jmp check_keys_done

down:

    cmp byte [direction], 0
    je check_keys_done
    mov byte [direction], 2
    jmp check_keys_done

left:

    cmp byte [direction], 1
    je check_keys_done
    mov byte [direction], 3
    jmp check_keys_done

right:

    cmp byte [direction], 3
    je check_keys_done
    mov byte [direction], 1
    jmp check_keys_done
    
quit:

    mov byte [quit_flag], 1
    ret

check_keys_done:

    ret

move_snake:

    movzx cx, [snake_length]
    dec cx
    jz MoveHeadOnly  ; skip if only head exists
    
MoveBody:

    mov si, cx
    mov al, [snakeX + si - 1]
    mov [snakeX + si], al
    mov al, [snakeY+ si - 1]
    mov [snakeY+ si], al
    loop MoveBody

MoveHeadOnly: ; ( move head based on direction )


    cmp byte [direction], 0   ; Up
    je up_move
    cmp byte [direction], 2   ; Down
    je down_move
    cmp byte [direction], 1   ; Right
    je right_move
    cmp byte [direction], 3   ; Left
    je left_move
    ret

up_move:

    dec byte [snakeY]
    ret

down_move:

    inc byte [snakeY]
    ret

right_move:

    inc byte [snakeX]
    ret

left_move:

    dec byte [snakeX]
    ret

check_collisions:

    cmp byte [snakeX], 0
    je collision_detected
    cmp byte [snakeX], 79
    je collision_detected
    cmp byte [snakeY], 0
    je collision_detected
    cmp byte [snakeY], 24
    je collision_detected

    movzx cx, [snake_length]
    cmp cx, 1
    je check_collisions_done
    mov si, 1
    
CheckSelf:

    mov al, [snakeX + si]
    cmp al, [snakeX]
    jne NextSegment
    mov al, [snakeY+ si]
    cmp al, [snakeY]
    je collision_detected
    
NextSegment:

    inc si
    cmp si, cx
    jb CheckSelf

check_collisions_done:

    xor al, al
    ret

collision_detected:

    mov al, 1  
    ret


check_food:

    mov al, [snakeX]
    cmp al, [food_x]
    jne check_food_done
    mov al, [snakeY]
    cmp al, [food_y]
    jne check_food_done
    
    inc word [score]
    inc byte [snake_length]
    
    call show_score     
    call CreateFood
    
check_food_done:

    ret


GameOverDisplay:
    
    call clear_screen 

    mov ah, 0x02
    mov bh, 0       ; page 0
    mov dh, 2       ; row 2
    mov dl, 3       ; col 3
    int 0x10

    mov ah, 0x09
    mov dx, GameOver
    int 0x21

    call show_score
    call restart_or_quit
    
    ret

show_score:

    ;top line
    mov ah, 0x02
    mov bh, 0
    mov dh, 0        ; row 0
    mov dl, 2        ; column 2
    int 0x10

    
    mov ax, [score]
    mov bx, 10
    mov cx, 4
    mov di, score_str+3
    
convertLoop:

    xor dx, dx
    div bx
    add dl, '0'
    mov [di], dl
    dec di
    loop convertLoop

    mov byte [score_str + 4], '$'

    
    mov ah, 0x09
    mov dx, Score
    int 0x21
    
    mov ah, 0x09
    mov dx, score_str
    int 0x21
    
    ret


restart_or_quit:
     
    mov ah, 0x02
    mov bh, 0
    mov dh, 3
    mov dl, 5
    int 0x10

    mov ah, 0x09
    mov dx, Restart_or_Quit
    int 0x21
    
    mov ah, 0x00
    int 0x16
    cmp al, 'r'
    je restart_game
    cmp al, 'q'
    je quit_game
    jmp restart_or_quit
    
restart_game:
   
    call GameSet
    call GameLoop
    jmp exitGame

quit_game:

    mov byte [quit_flag], 1

exitGame:

    mov ax, 0x4c00
    int 0x21