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


## 部分总结 ##
在重新整理之后，总结：
需要boot.asm是作为引导扇区，也就是MBR (Master Boot Record),中文为主引导记录。
MBR是磁盘的0柱面、0磁道，1扇区（扇区从1开始计数），也就是512个字节。

严格来说，MBR由3个部分组成，具体细节暂时在这里使用不到，不进行深入了解和展开。

由MBR来找到loader.bin，这里使用的是FAT12文件系统格式，并进行相应的加载和最终控制权跳转，将执行跳转至loader的入口。

这里还是比较清晰的，然后进入第五章之后，直接开始介绍ELF格式，中间没有过渡，感觉有些不太好理解。

在第四章的末尾提到
> 不过，我们用引导扇区加载进内存的Loader是个.COM文件，直接把它放入内存就够了，可是将来的内核是在Linux下编译链接出来的ELF格式文件，直接放入内存肯定是不行的。

这里介绍就比较简单。是否是C编译出来的目标文件和汇编文件之间的区别？
还有一个bin文件，可以用objcopy把elf的头去掉，直接变成单纯的bin文件

objcopy -R .comment -R .note -O binary [input_file] [output_file]

感觉第四章的结论有些草率，在网上找到一篇博文讲得不错，“从Bootloader到ELF内核”。
> Bootloader程序是原始可执行文件，如果程序由汇编写成，汇编编译器编译生成的文件就是原始可执行文件，也可以使用C语言编写，编译成可执行文件之后通过objcopy转换成原始可执行文件。
> 那么内核文件是什么格式的呢？跟Bootloader一样的当然可以。内核一般使用C语言编写，每次编译链接完成之后调用objcopy是可以的。我们也可以支持通用的可执行文件格式，例如ELF(Executable and Linkable Format)。
