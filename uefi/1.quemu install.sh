mkdir -p $(pwd)/uefi_security_lab && cd $(pwd)/uefi_security_lab

sudo apt update
sudo apt install -y qemu-system-x86 \
					ovmf \
					gnu-efi \
					build-essential \
					binutils-mingw-w64

sudo apt install -y ghidra || sudo snap install ghidra --classic