nasm boot.asm -o boot.bin
dd if=boot.bin of=a.img bs=512 count=1 conv=notrunc
sudo mount -o loop a.img /mnt
sudo cp loader.bin /mnt
sudo umount

