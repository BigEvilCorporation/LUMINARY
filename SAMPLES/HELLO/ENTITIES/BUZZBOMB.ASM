; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 1st December 2019
; ============================================================================================
; BUZZBOMB.ASM - Sonic 1 Buzzbomber enemy
; ============================================================================================

; Buzzbomb constants
EBUZZBOMB_WINGS_OFFS_X                  equ 0x00
EBUZZBOMB_WINGS_OFFS_Y                  equ -0x10
EBUZZBOMB_THRUST_OFFS_X                 equ 0x14
EBUZZBOMB_THRUST_OFFS_Y                 equ 0x04
EBUZZBOMB_FIRE_OFFS_X                   equ -0x0E
EBUZZBOMB_FIRE_OFFS_Y                   equ 0x16
EBUZZBOMB_VEL_X                         equ 0x0004
EBUZZBOMB_ATTACK_DIST_X                 equ 0x60

; Timing
EBUZZBOMB_REVERSE_TIME                  equ 128 ; Time to switch direction, reset after attacking
EBUZZBOMB_ATTACK_HOVER_TIME             equ 30  ; Time to stop and hover before attacking
EBUZZBOMB_REVERSE_HOVER_TIME            equ 60  ; Time to stop and hover before changing direction

; State machine
EBUZZBOMB_STATE_FLYING                  equ 0x0 ; Flying, not looking to attack
EBUZZBOMB_STATE_SEARCHING               equ 0x1 ; Searching for Sonic to attack
EBUZZBOMB_STATE_PREPARING               equ 0x2 ; Preparing to fire
EBUZZBOMB_STATE_ATTACKING               equ 0x3 ; Firing
EBUZZBOMB_STATE_REVERSING               equ 0x4 ; Hovering before changing direction

; Buzzbomb spawn data
    ENTITY_SPAWN_DATA_BEGIN EBuzzbomb
    ENTITY_SPAWN_DATA_END

; Buzzbomb entity
    ENTITY_BEGIN EBuzzbomb
EBuzzBomb_Timer                         rs.w 1
EBuzzBomb_VelX                          rs.w 1
EBuzzBomb_State                         rs.b 1
    ENT_COMPONENT_NAMED ECSprite,SpriteBody
    ENT_COMPONENT_NAMED ECSprite,SpriteWings
    ENT_COMPONENT_NAMED ECSprite,SpriteThrust
    ENT_COMPONENT_NAMED ECSprite,SpriteFire
    ENT_COMPONENT ECEnemy
    ENTITY_END

EBuzzbomb_Initialise:
    ; ======================================
    ; EBuzzbomb constructor
    ; ======================================
	; a0   Entity
    ; a1   Entity spawn data
    ; ======================================

    ; Initialise
    move.w #EBUZZBOMB_REVERSE_TIME, EBuzzBomb_Timer(a0)
    move.w #-EBUZZBOMB_VEL_X, EBuzzBomb_VelX(a0)
    move.b #EBUZZBOMB_STATE_SEARCHING, EBuzzBomb_State(a0)

    ; Set palettes
    ; TODO: Better palette management
    ENT_GETCOMPONENT EBuzzbomb,SpriteBody,a0,a1
    move.w #0x2, d0
    SPRITE_COMPONENT_SETPALETTE_REG a1,d0
    ENT_GETCOMPONENT EBuzzbomb,SpriteWings,a0,a1
    move.w #0x2, d0
    SPRITE_COMPONENT_SETPALETTE_REG a1,d0
    ENT_GETCOMPONENT EBuzzbomb,SpriteThrust,a0,a1
    move.w #0x2, d0
    SPRITE_COMPONENT_SETPALETTE_REG a1,d0

    ; Init enemy component
    ENT_GETCOMPONENT EBuzzbomb,ECEnemy,a0,a1
    move.l #EBuzzbomb_OnHit, ECEnemy_CallbackOnHit(a1)

    ; Offset wings
    ENT_GETCOMPONENT EBuzzbomb,SpriteWings,a0,a1
    move.b #EBUZZBOMB_WINGS_OFFS_X, ECSprite_PosX(a1)
    move.b #EBUZZBOMB_WINGS_OFFS_Y, ECSprite_PosY(a1)

    ; Offset thruster
    ENT_GETCOMPONENT EBuzzbomb,SpriteThrust,a0,a1
    move.b #EBUZZBOMB_THRUST_OFFS_X, ECSprite_PosX(a1)
    move.b #EBUZZBOMB_THRUST_OFFS_Y, ECSprite_PosY(a1)

    ; Offset and hide fire, anim not looping
    ENT_GETCOMPONENT EBuzzbomb,SpriteFire,a0,a1
    move.b #EBUZZBOMB_FIRE_OFFS_X, ECSprite_PosX(a1)
    move.b #EBUZZBOMB_FIRE_OFFS_Y, ECSprite_PosY(a1)
    bclr   #ECSPRITE_STATE_FLAG_VISIBLE, ECSprite_StateFlags(a1)
    bclr   #ECSPRITE_STATE_FLAG_LOOPING, ECSprite_StateFlags(a1)

    rts

EBuzzbomb_Shutdown:
    rts

EBuzzbomb_Update:
    ; ======================================
    ; EBuzzbomb movement path update
    ; ======================================
	; a0   Entity
    ; ======================================

    move.b EBuzzBomb_State(a0), d0
    cmp.b  #EBUZZBOMB_STATE_FLYING, d0
    beq    @Flying
    cmp.b  #EBUZZBOMB_STATE_SEARCHING, d0
    beq    @Searching
    cmp.b  #EBUZZBOMB_STATE_PREPARING, d0
    beq    @Preparing
    cmp.b  #EBUZZBOMB_STATE_ATTACKING, d0
    beq    @Attacking
    cmp.b  #EBUZZBOMB_STATE_REVERSING, d0
    beq    @Reversing

    ; ======================================
	; FLYING (NOT ATTACKING)
    ; ======================================
    @Flying:
    move.w EBuzzBomb_VelX(a0), d0       ; Move
    add.w  d0, Entity_PosX(a0)
    bra    @CheckChangeDirection        ; Check change direction timer

    ; ======================================
	; FLYING (SEARCHING FOR PLAYER)
    ; ======================================
    @Searching:
    move.w EBuzzBomb_VelX(a0), d0       ; Move
    add.w  d0, Entity_PosX(a0)

    move.l RAM_PLAYER_1, a1             ; If player within range
    move.w Entity_PosX(a0), d0
    move.w Entity_PosX(a1), d1
    sub.w  d1, d0
    ABS.W  d0
    cmp.w  #EBUZZBOMB_ATTACK_DIST_X, d0
    bgt    @CheckChangeDirection        ; Check change direction timer

    PUSH.L a0                           ; Start attack anim
    ENT_GETCOMPONENT EBuzzbomb,SpriteBody,a0,a0
    lea    actor_buzzbomb_spritesheet_attack, a1
    move.l #0x0, a2
    bsr    ECSprite_LoadAnimation
    POP.L  a0

    move.b #EBUZZBOMB_STATE_PREPARING, EBuzzBomb_State(a0)   ; Start prepare to attack state
    move.w #EBUZZBOMB_ATTACK_HOVER_TIME, EBuzzBomb_Timer(a0) ; Start attack timer

    rts

    ; ======================================
	; PREPARING TO FIRE
    ; ======================================
    @Preparing:
    subi.w #0x1, EBuzzBomb_Timer(a0)    ; If timer elapsed
    bgt    @EndPrepare
    PUSH.L a0                           ; Show fire sprite and start fire anim
    ENT_GETCOMPONENT EBuzzbomb,SpriteFire,a0,a0
    lea    actor_buzzbomb_spritesheet_fire, a1
    lea    actor_buzzbomb_sheet_fire_anim_fire, a2
    bsr    ECSprite_LoadAnimation
    bset   #ECSPRITE_STATE_FLAG_VISIBLE, ECSprite_StateFlags(a0)
    bclr   #ECSPRITE_STATE_FLAG_LOOPING, ECSprite_StateFlags(a0)
    POP.L  a0
    move.b #EBUZZBOMB_STATE_ATTACKING, EBuzzBomb_State(a0)   ; Start attacking state
    @EndPrepare:
    rts

    ; ======================================
	; FIRING PROJECTILE
    ; ======================================
    @Attacking:
    ENT_GETCOMPONENT EBuzzbomb,SpriteFire,a0,a1
    btst   #ECSPRITE_STATE_FLAG_PLAYING, ECSprite_StateFlags(a1)
    bne    @EndAttacking
    bclr   #ECSPRITE_STATE_FLAG_VISIBLE, ECSprite_StateFlags(a1)    ; Hide fire sprite
                                                            ; Spawn projectile

    PUSH.L a0                                               ; Start flying anim
    ENT_GETCOMPONENT EBuzzbomb,SpriteBody,a0,a0
    lea    actor_buzzbomb_spritesheet_fly, a1
    move.l #0x0, a2
    bsr    ECSprite_LoadAnimation
    POP.L  a0

    move.b #EBUZZBOMB_STATE_FLYING, EBuzzBomb_State(a0)     ; Start flying state
    move.w #EBUZZBOMB_REVERSE_TIME, EBuzzBomb_Timer(a0)     ; Start reversing timer
    @EndAttacking:
    rts

    ; ======================================
	; HOVERING BEFORE REVERSING
    ; ======================================
    @Reversing:
    subi.w #0x1, EBuzzBomb_Timer(a0)    ; If timer elapsed
    bgt    @EndReverse
    move.b #EBUZZBOMB_STATE_SEARCHING, EBuzzBomb_State(a0)   ; Start searching state
    move.w #EBUZZBOMB_REVERSE_TIME, EBuzzBomb_Timer(a0)      ; Start reversing timer
    @EndReverse:
    rts

    ; ======================================
	; CHECK SWITCH DIRECTION TIMER
    ; ======================================
    @CheckChangeDirection:
    subi.w #0x1, EBuzzBomb_Timer(a0)    ; If timer elapsed
    bgt    @EndChangeDir
    neg.w  EBuzzBomb_VelX(a0)           ; Switch direction
    ENT_GETCOMPONENT EBuzzbomb,SpriteBody,a0,a1
    move.b ECSprite_DrawFlags(a1), d0
    SPRITE_COMPONENT_FLIPX a1
    move.b ECSprite_DrawFlags(a1), d1
    ENT_GETCOMPONENT EBuzzbomb,SpriteWings,a0,a1
    SPRITE_COMPONENT_FLIPX a1
    ENT_GETCOMPONENT EBuzzbomb,SpriteThrust,a0,a1
    SPRITE_COMPONENT_FLIPX a1
    ENT_GETCOMPONENT EBuzzbomb,SpriteFire,a0,a1
    SPRITE_COMPONENT_FLIPX a1
    move.b #EBUZZBOMB_STATE_REVERSING, EBuzzBomb_State(a0)   ; Start reversing state
    move.w #EBUZZBOMB_REVERSE_HOVER_TIME, EBuzzBomb_Timer(a0); Start reverse hover timer
    @EndChangeDir:

    rts

EBuzzbomb_OnHit:
    ; ======================================
    ; EBuzzbomb on player hit callback from
    ; ECEnemy_CheckHit
    ; ======================================
    ; In:
	;   a0    Entity
    ;   a1    ECEnemy component
    ;   a2    Player
    ;   d1.ww Player top left bounds
    ;   d2.ww Player bottom right bounds
    ;   d3.ww Player top left bounds
    ;   d4.ww Player bottom right bounds
    ; Out:
    ;   d5.b  Damage taken from player
    ;   d6.b  Damage dealt to player
    ; ======================================

    PUSH.L a1

    ; If player spinning, take damage
    btst   #PLAYER_FLAG_SPINNING, EPlayer_StateFlags(a2)
    bne    @Spinning

    ; If player jumping, take damage and rebound player
    btst   #PLAYER_FLAG_JUMPING, EPlayer_StateFlags(a2)
    beq    @NotJumping
    ENT_GETCOMPONENT EPlayer,ECPhysBodyChar,a2,a1
    move.l ECPhysBodyChar_VelY(a1), d0
    neg.l  d0
    move.l d0, ECPhysBodyChar_VelY(a1)

    @Spinning:

    ; Despawn
    bsr    ENT_DespawnEntity

    ; Spawn explosion
    VFX_SPAWN VFXExplosion2,Entity_PosX(a0),Entity_PosY(a0)

    ; Spawn critter
    PUSHM.L a0-a2
    move.w Entity_PosX(a0), d0
    move.w Entity_PosY(a0), d1
    subi.w #EFLICKY_HEIGHT, d1
    move.w #EFLICKY_WIDTH, d2
    move.w #EFLICKY_HEIGHT, d3
    lea    EFlicky_TypeDesc, a0
    lea    EFlicky_Default_SpawnData, a1
    bsr    ENT_SpawnEntity
    POPM.L a0-a2
    
    @NotJumping:

    ; If player not spinning, deal damage to player

    POP.L  a1

    rts
