使用bximage命令来创建模拟软盘a.img

tag管理：
- chap01 第一个代码，用于实模式下视频的显示
- jmp_protectionmode 代码2，从实模式跳转到保护模式
- write_large_memory 代码3，实验保护模式下，读写大内存地址，并跳回实模式
- ldt 代码4，增加了LDT
- cgate 代码5，调用门，但是没有特权转移
- 06_ring3 进入ring3
- 07_ring3_gatecall 在ring3做调用门,调用ring0



