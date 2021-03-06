#ifndef _IO_H
#define _IO_H
#include "type.h"
#include "graph.h"

void putchar(char c);
void putchar_color(char c, uint32 BackColor, uint32 ForeColor);
void puts(char *str);
void puts_color(char *str, uint32 BackColor, uint32 ForeColor);
void printf(char *str, ...);
void printf_color(uint32 BackColor, uint32 ForeColor, char *str, ...);
void puti(int n, int align, int zero);
void puti_color(int n, uint32 BackColor, uint32 ForeColor, int align, int zero);
void putl(long n, int align, int zero);
void putl_color(long n, uint32 BackColor, uint32 ForeColor, int align, int zero);
void putx(long n, int isuper, int align, int zero);
void putx_color(long n, uint32 BackColor, uint32 ForeColor, int isuper, int align, int zero);

void putui(unsigned int n, int align, int zero);
void putui_color(unsigned int n, uint32 BackColor, uint32 ForeColor, int align, int zero);
void putul(unsigned long n, int align, int zero);
void putul_color(unsigned long n, uint32 BackColor, uint32 ForeColor, int align, int zero);
void putux(unsigned long n, int isuper, int align, int zero);
void putux_color(unsigned long n, uint32 BackColor, uint32 ForeColor, int isuper, int align, int zero);

char getchar();
void getstr(char* str, int n);

void memset(void *str, unsigned char c, long size);

unsigned char input_buffer[256];
unsigned char input_head, input_tail;
char curcmd[256];
char cmd;

#endif
