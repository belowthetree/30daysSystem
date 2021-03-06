global  _start
global  io_hlt, io_sti, io_out8, io_in8, io_cli, io_delay, io_load_eflags, io_store_eflags
global  load_idtr, load_gdtr, load_cr0, store_cr0, load_tr
global  memcpy, register_clock, create_int, memtest_sub, restart
global  isr_common_stub
global  Stack

extern  main, Clock, printi, prints, isr_handler

[section .text]
_start:
    call main

    jmp $

restart:
    ; xor eax, eax
    ; mov ax, 7*8
    ; ltr ax
    ; lldt [esp + 8]
    mov ax, 6*8 + 3
    mov ds, ax
    mov gs, ax
    mov es, ax
    mov eax, esp
    mov esp, [esp + 4]
    add esp, 13 * 4
    retf
    ; mov esp, [esp + 4]

    ; pop gs
    ; pop fs
    ; pop es
    ; pop ds
    ; popad

    ; add esp, 4
    ; iretd

%macro ISR_NOERRCODE 1
[GLOBAL isr%1]
isr%1:
        cli
        push 0
        push %1
        jmp isr_common_stub
%endmacro

%macro ISR_ERRCODE 1
[GLOBAL isr%1]
isr%1:
        cli
        push %1
        jmp isr_common_stub
%endmacro

ISR_NOERRCODE   0   ; 0 #DE 除零异常
ISR_NOERRCODE   1   ; 1 #DB 调试异常
ISR_NOERRCODE   2   ; 2 #NMI
ISR_NOERRCODE   3   ; 3 BP 断点异常
ISR_NOERRCODE   4   ; 4 #OF 溢出
ISR_NOERRCODE   5   ; 5 #BR 对数组的引用超出边界
ISR_NOERRCODE   6   ; 6 #UD 无效或未定义的操作码
ISR_NOERRCODE   7   ; 7 #NM 设备不可用无数学协处理器（）
ISR_ERRCODE     8   ; 8 #DF 双重故障有错误代码
ISR_NOERRCODE   9   ; 9 协处理器跨段操作
ISR_ERRCODE     10  ; 10 #TS 无效TSS有错误代码
ISR_ERRCODE     11  ; 11 #NP 段不存在有错误代码
ISR_ERRCODE     12  ; 12 #SS 栈错误有错误代码
ISR_ERRCODE     13  ; 13 #GP 常规保护有错误代码
ISR_ERRCODE     14  ; 14 #PF 页故障有错误代码
ISR_ERRCODE     15  ; 15 CPU 保留
ISR_ERRCODE     16  ; 16 #MF 浮点处理单元错误
ISR_ERRCODE     17  ; 17 #AC 对齐检查
ISR_ERRCODE     18  ; 18 #MC 机器检查
ISR_ERRCODE     19  ; 19 #XM SIMD单指令多数据（）浮点异常

; INTEL 保留
ISR_NOERRCODE   20
ISR_NOERRCODE   21
ISR_NOERRCODE   22
ISR_NOERRCODE   23
ISR_NOERRCODE   24
ISR_NOERRCODE   25
ISR_NOERRCODE   26
ISR_NOERRCODE   27
ISR_NOERRCODE   28
ISR_NOERRCODE   29
ISR_NOERRCODE   30
ISR_NOERRCODE   31

; 32~255 用户自定义
ISR_NOERRCODE   255

; 构造中断请求的宏
%macro IRQ 2
[GLOBAL irq%1]
irq%1:
    cli
    push byte 0
    push byte %2
    jmp irq_common_stub
%endmacro

IRQ 0, 32 ; 电脑系统计时器
IRQ 1, 33 ; 键盘
IRQ 2, 34 ; 与 IRQ9 相接，MPU 401 MD 使用
IRQ 3, 35 ; 串口设备
IRQ 4, 36 ; 串口设备
IRQ 5, 37 ; 建议声卡使用
IRQ 6, 38 ; 软驱传输控制使用
IRQ 7, 39 ; 打印机传输控制使用
IRQ 8, 40 ; 即时时钟
IRQ 9, 41 ; 与 IRQ2 相接，可设定给其他硬件
IRQ 10, 42 ; 建议网卡使用
IRQ 11, 43 ; 建议 AGP 显卡使用
IRQ 12, 44 ; 接 PS/2 鼠标，也可设定给其他硬件
IRQ 13, 45 ; 协处理器使用
IRQ 14, 46 ; IDE0 传输控制使用
IRQ 15, 47 ; IDE1 传输控制使用

[GLOBAL irq_common_stub]
[EXTERN irq_handler]
irq_common_stub:
    pushad ; pushes edi, esi, ebp, esp, ebx, edx, ecx, eax

    mov ax, ds
    push eax ; 保存数据段描述符
    mov ax, 3*8 ; 加载内核数据段描述符
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    push esp
    call irq_handler
    add esp, 4

    pop ebx ; 恢复原来的数据段描述符
    mov ds, bx
    mov es, bx
    mov fs, bx
    mov gs, bx
    mov ss, bx

    popa ; Pops edi,esi,ebp...
    add esp, 8 ; 清理压栈的错误代码和 ISR 编号
    iret ; 出栈 CS, EIP, EFLAGS, SS, ESP

isr_common_stub:
    pusha
    mov ax, ds
    push eax

    mov ax, 3*8     ; 内核数据段选择子
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    push esp
    call isr_handler
    add esp, 4

    pop ebx
    mov ds, bx
    mov es, bx
    mov fs, bx
    mov gs, bx
    mov ss, bx

    popa
    add esp, 8
    iret

io_hlt:
    hlt
    ret

memcpy:     ; void memcpy(char *str, short value, int len)
    xor eax, eax
    xor edi, edi
    xor ecx, ecx
    mov edi, [esp + 4]
    mov ax,  word [esp + 8]
    mov ecx, [esp + 12]
.membg:
    mov [edi], ax
    inc edi
    dec ecx
    jnz .membg
    ret

io_out8:      ; void io_out8(int port, int data);
    mov edx, [esp + 4]
    mov al, [esp + 8]
    out dx, al
    ret

io_in8:       ; int io_in8(int port)
    mov     edx, [esp + 4]
    mov     eax, 0
    in      al, dx
    ret

io_cli:      ; void io_cli()
    cli
    ret

io_sti:
    sti
    ret

io_load_eflags:      ; int io_load_eflags()
    pushfd
    pop eax
    ret

io_store_eflags:      ; void io_store_eflags()
    mov     eax, [esp + 4]
    push    eax
    popfd
    ret

load_cr0:
    mov eax, cr0
    ret

store_cr0:
    mov eax, [esp + 4]
    mov cr0, eax
    ret

io_delay:
    nop
    nop
    nop
    nop
    ret

load_idtr:  ; void load_idtr(int limit, int addr)
    mov     ax, [esp + 4]
    mov     [esp + 6], ax
    lidt    [esp + 6]
    ret

load_gdtr:      ; void load_gdtr(int limit, int addr)
    mov     ax, [esp + 4]
    mov     [esp + 6], ax
    lgdt    [esp + 6]
    mov ax, ds
    mov fs, ax
    mov es, ax
    ret

load_tr:    ; void load_tr(short tss)
    mov ax, [esp + 4]
    ltr ax

create_int:
    int 0x80
    ret

register_clock:
    call Clock
    iretd


memtest_sub:	; unsigned int memtest_sub(unsigned int start, unsigned int end)
		PUSH	EDI						; �iEBX, ESI, EDI ���g�������̂Łj
		PUSH	ESI
		PUSH	EBX
		MOV		ESI,0xaa55aa55			; pat0 = 0xaa55aa55;
		MOV		EDI,0x55aa55aa			; pat1 = 0x55aa55aa;
		MOV		EAX,[ESP+12+4]			; i = start;
mts_loop:
		MOV		EBX,EAX
		ADD		EBX,0xffc				; p = i + 0xffc;
		MOV		EDX,[EBX]				; old = *p;
		MOV		[EBX],ESI				; *p = pat0;
		XOR		DWORD [EBX],0xffffffff	; *p ^= 0xffffffff;
		CMP		EDI,[EBX]				; if (*p != pat1) goto fin;
		JNE		mts_fin
		XOR		DWORD [EBX],0xffffffff	; *p ^= 0xffffffff;
		CMP		ESI,[EBX]				; if (*p != pat0) goto fin;
		JNE		mts_fin
		MOV		[EBX],EDX				; *p = old;
		ADD		EAX,0x1000				; i += 0x1000;
		CMP		EAX,[ESP+12+8]			; if (i <= end) goto mts_loop;
		JBE		mts_loop
		POP		EBX
		POP		ESI
		POP		EDI
		RET
mts_fin:
		MOV		[EBX],EDX				; *p = old;
		POP		EBX
		POP		ESI
		POP		EDI
		RET

[section .data]
welcome:
    db "Here in kernel", 0

Stack:
    times 1024 db 0