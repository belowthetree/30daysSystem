#include "desc.h"
#include "main.h"
#include "tool.h"
#include "process.h"

void InitPIC()
{
    io_out8(0x20, ICW1);
    io_delay();
    io_out8(0xa0, ICW1);
    io_delay();

    io_out8(0x21, MICW2);
    io_delay();
    io_out8(0xa1, CICW2);
    io_delay();

    io_out8(0x21, MICW3);
    io_delay();
    io_out8(0xa1, CICW3);
    io_delay();

    io_out8(0x21, ICW4);
    io_delay();
    io_out8(0xa1, ICW4);
    io_delay();

    io_out8(0x21, 0xfd);
    io_delay();
    io_out8(0xa1, 0xff);
    io_delay();

    return;
}

void InitGDT()
{
    int i;
    gdt = (struct SEGMENT_DESCRIPTOR *) GDTBASE;
    Code32      = gdt + 1;
    KernelVRAM  = gdt + 2;
    KernelData  = gdt + 3;
    LDTCode     = gdt + 4;
    LDTVRAM     = gdt + 5;
    LDTData     = gdt + 6;
    Seg_TSS     = gdt + 7;

    tss.ss0 = SelectorKernelData;

    for (i = 0;i < 16;i++){
        SetGDT(&gdt[i], 0, 0, 0);
    }
    SetGDT(Code32, 0x0, 0xffffffff, DA_32 | DA_DPL0 | DA_CR);
    SetGDT(KernelVRAM, 0xb8000, 0xffff, DA_DRW | DA_DPL0);
    SetGDT(KernelData, 0x0, 0xffffffff, DA_DRW | DA_32 | DA_DPL0);
    SetGDT(LDTCode, 0x0, 0xffffffff, DA_LDT | DA_DPL1);
    SetGDT(LDTVRAM, 0xb8000, 0xffff, DA_DRW | DA_DPL1);
    SetGDT(LDTData, 0x0, 0xffffffff, DA_DRW | DA_DPL1);
    SetGDT(Seg_TSS, (int) &tss, sizeof(tss) - 1, DA_386TSS);

    InitTSS();

    load_gdtr(0x77, gdt);

    return;
}

void InitIDT()
{
    int i;
    memset(interrupt_handlers, 0, sizeof(interrupt_handlers)*256);

    for (i = 0;i < 256;i++){
        SetGate(idt + i, (int) register_clock, 8, DA_386IGate);
    }
    SetGate(idt + IRQ0, irq0, 1*8, DA_386IGate);
    SetGate(idt + IRQ1, irq1, 1*8, DA_386IGate);
    SetGate(idt + IRQ2, irq2, 1*8, DA_386IGate);
    SetGate(idt + IRQ3, irq3, 1*8, DA_386IGate);
    SetGate(idt + IRQ4, irq4, 1*8, DA_386IGate);
    SetGate(idt + IRQ5, irq5, 1*8, DA_386IGate);
    SetGate(idt + IRQ6, irq6, 1*8, DA_386IGate);
    SetGate(idt + IRQ7, irq7, 1*8, DA_386IGate);
    SetGate(idt + IRQ8, irq8, 1*8, DA_386IGate);
    SetGate(idt + IRQ9, irq9, 1*8, DA_386IGate);
    SetGate(idt + IRQ10, irq10, 1*8, DA_386IGate);
    SetGate(idt + IRQ11, irq11, 1*8, DA_386IGate);
    SetGate(idt + IRQ12, irq12, 1*8, DA_386IGate);
    SetGate(idt + IRQ13, irq13, 1*8, DA_386IGate);
    SetGate(idt + IRQ14, irq14, 1*8, DA_386IGate);
    SetGate(idt + IRQ15, irq15, 1*8, DA_386IGate);
    
    load_idtr(0x7ff, idt);
    return;
}

void InitTSS()
{
    memset((char*) &tss, 0, sizeof(tss));

    tss.ss0 = SelectorKernelData;
    tss.iobase = sizeof(tss);
}

void SetGate(struct GATE_DESCRIPTOR *gd, int offset, int selector, int ar)
{
    gd->offset_low = offset & 0xffff;
    gd->selector = selector;
    gd->dw_count = 0;
    gd->access_right = ar & 0xff;
    gd->offset_high = (offset >> 16) & 0xffff;
    
    return;
}

void SetGDT(struct SEGMENT_DESCRIPTOR *sd, int addr, int limit, int ar)
{
    if (limit > 0xfffff)
    {
        ar |= 0x8000;
        limit /= 0x1000;
    }
    sd->limit_low = limit & 0xffff;
    sd->base_low = addr & 0xffff;
    sd->base_mid = (addr >> 16) & 0xf;
    sd->access_right = ar & 0xff;
    sd->limit_high = ((limit >> 16) & 0x0f) | ((ar >> 8) & 0xf0);
    sd->base_high = (addr >> 24) & 0xff;

    return;
}

void SetLDT(int selector)
{
    // TODO
}

void isr_handler(pt_regs *regs)
{
    if (interrupt_handlers[regs->int_num]){
        interrupt_handlers[regs->int_num](regs);
    } else {
        char msg[] = "Unhandle interrupt: ";
        prints(msg);
        printi(regs->int_num, 1);
    }
    // 发送中断结束信号给 PICs
    // 按照我们的设置，从 32 号中断起为用户自定义中断
    // 因为单片的 Intel 8259A 芯片只能处理 8 级中断 
    // 故大于等于 40 的中断号是由从片处理的
    if (regs->int_num >= 40) {
        // 发送重设信号给从片
        io_out8(0xa0, 0x20);
    }
    // 发送重设信号给主片
    io_out8(0x20, 0x20);
}