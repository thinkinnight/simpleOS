# first need to format b:/ in freedos (in bochs)

nasm boot.asm -o boot.com

# need to enter the password
sudo mount -o loop a.img /mnt
sudo cp boot.com /mnt
sudo umount /mnt

# then can execute b:/boot.com in freedos
