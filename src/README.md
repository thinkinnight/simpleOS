使用bximage命令来创建模拟软盘a.img

tag管理：
- chap01 第一个代码，用于实模式下视频的显示
- jmp_protectionmode 代码2，从实模式跳转到保护模式
- write_large_memory 代码3，实验保护模式下，读写大内存地址，并跳回实模式
- ldt 代码4，增加了LDT
- cgate 代码5，调用门，但是没有特权转移
- 06_ring3 进入ring3
- 07_ring3_gatecall 在ring3做调用门,调用ring0
- 08_ldt_backtoreal 使用LDT局部任务返回实模式
- 09_getmemory 这个程序和书上得到的内存分布不同，具体原因不清楚是否是程序问题还是版本不同造成的。


nasm -f elf32 hello.o hello.asm
gcc -c -o bar.o bar.c -m32
ld -s -o foobar hello.o bar.o -m elf_i386

# 重新整理思路 #
这里面第三章和第五章的内容很多，最好是一次性完成，现在看到第五章147页，感觉需要重新整理思路。
同时过了一下书评，发现很多人推荐赵炯的Linux内核剖析，那现在关于操作系统方面：
1. OrangeOS
2. 赵炯
3. 日本人的那本
4. ULK
5. Linux2.6内核上下册，浙大的那本

其他汇编以及Intel CPU参考手册等不提

工具和环境
1. bochs
2. qemu
3. 调试工具

背景知识
1. 保护模式
2. 内存
3. 汇编
4. 中断

