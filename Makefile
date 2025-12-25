K=kernel
U=user
SRC=src

# ===== 并行编译配置 =====
# 默认使用所有可用 CPU 核心进行并行编译
NPROC := $(shell nproc)
MAKEFLAGS += -j$(NPROC)

# ===== 路径定义 =====
SRC_DIRS := boot devs lib linker mm proc proc-h sync trap syscall syscall-h fs fs-h
BUILD_DIR := build

# ===== 文件收集规则 =====
# 仅收集内核相关子目录(见 SRC_DIRS)下的源文件，显式排除 user 目录，避免将用户态程序链接进内核
SRCS := $(foreach d,$(SRC_DIRS),$(shell find $(SRC)/$(d) -type f \( -name "*.c" -o -name "*.S" \) 2>/dev/null))

$(info === SRCS collected (kernel only) ===)
$(info $(SRCS))

# 将源文件路径转换为目标文件路径
OBJS := $(patsubst $(SRC)/%.c, $(BUILD_DIR)/%.o, $(filter %.c, $(SRCS)))
OBJS += $(patsubst $(SRC)/%.S, $(BUILD_DIR)/%.o, $(filter %.S, $(SRCS)))

# 设置 entry.o 作为特殊的入口目标文件
ENTRY_OBJ := $(BUILD_DIR)/boot/entry.o
OBJS_NO_ENTRY := $(filter-out $(ENTRY_OBJ), $(OBJS))
DEPS := $(OBJS:.o=.d)

# riscv64-unknown-elf- or riscv64-linux-gnu-
# perhaps in /opt/riscv/bin
#TOOLPREFIX = 

# Try to infer the correct TOOLPREFIX if not set
ifndef TOOLPREFIX
TOOLPREFIX := $(shell if riscv64-unknown-elf-objdump -i 2>&1 | grep 'elf64-big' >/dev/null 2>&1; \
	then echo 'riscv64-unknown-elf-'; \
	elif riscv64-linux-gnu-objdump -i 2>&1 | grep 'elf64-big' >/dev/null 2>&1; \
	then echo 'riscv64-linux-gnu-'; \
	elif riscv64-unknown-linux-gnu-objdump -i 2>&1 | grep 'elf64-big' >/dev/null 2>&1; \
	then echo 'riscv64-unknown-linux-gnu-'; \
	else echo "***" 1>&2; \
	echo "*** Error: Couldn't find a riscv64 version of GCC/binutils." 1>&2; \
	echo "*** To turn off this error, run 'gmake TOOLPREFIX= ...'." 1>&2; \
	echo "***" 1>&2; exit 1; fi)
endif

QEMU = qemu-system-riscv64

CC = $(TOOLPREFIX)gcc
AS = $(TOOLPREFIX)gas
LD = $(TOOLPREFIX)ld
OBJCOPY = $(TOOLPREFIX)objcopy
OBJDUMP = $(TOOLPREFIX)objdump

CFLAGS = -Wall -Werror -O -fno-omit-frame-pointer -ggdb -gdwarf-2
CFLAGS += -MD
CFLAGS += -mcmodel=medany
CFLAGS += -ffreestanding -fno-common -nostdlib -mno-relax
CFLAGS += -I. -I$(SRC)
CFLAGS += $(shell $(CC) -fno-stack-protector -E -x c /dev/null >/dev/null 2>&1 && echo -fno-stack-protector)

# 包含头文件路径：添加各个源代码子目录
INCLUDES := -I$(SRC) $(foreach dir,$(SRC_DIRS),-I$(SRC)/$(dir))

# Disable PIE when possible (for Ubuntu 16.10 toolchain)
ifneq ($(shell $(CC) -dumpspecs 2>/dev/null | grep -e '[^f]no-pie'),)
CFLAGS += -fno-pie -no-pie
endif
ifneq ($(shell $(CC) -dumpspecs 2>/dev/null | grep -e '[^f]nopie'),)
CFLAGS += -fno-pie -nopie
endif

LDFLAGS = -z max-page-size=4096

# ===== 创建构建目录 =====
dirs:
	@mkdir -p $(BUILD_DIR)
	@for dir in $(SRC_DIRS); do mkdir -p $(BUILD_DIR)/$$dir; done

# ===== 编译规则 =====
$(BUILD_DIR)/%.o: $(SRC)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -MMD -MP -c $< -o $@

$(BUILD_DIR)/%.o: $(SRC)/%.S
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -MMD -MP -c $< -o $@

# 特殊处理 initcode.S，使其依赖于 user/initcode
$(BUILD_DIR)/boot/initcode.o: $(SRC)/boot/initcode.S $U/initcode.bin
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -MMD -MP -c $< -o $@
	rm -f $U/initcode.bin

$K/kernel: dirs $(ENTRY_OBJ) $(OBJS_NO_ENTRY) $(SRC)/linker/kernel.ld 
	@mkdir -p $K
	$(LD) $(LDFLAGS) -T $(SRC)/linker/kernel.ld -o $K/kernel $(ENTRY_OBJ) $(OBJS_NO_ENTRY)
	$(OBJDUMP) -S $K/kernel > $K/kernel.asm
	$(OBJDUMP) -t $K/kernel | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $K/kernel.sym
	
# # ===== User 程序编译规则 =====
# ===== User 程序编译规则（简化版）=====
ULIB_OBJS=\
	$U/start.o\
	$U/user_lib.o\
	$U/user_syscall.o\

UPROGS=\
	$U/_test\

# 用户程序编译标志
UCFLAGS = $(CFLAGS) -I$U -I. -I$(SRC)

# 通用规则：从.c文件编译.o文件
$U/%.o: $U/%.c
	$(CC) $(UCFLAGS) -c -o $@ $<

# 通用规则：从.S文件编译.o文件（用于 _start 等入口汇编）
$U/%.o: $U/%.S
	$(CC) $(UCFLAGS) -c -o $@ $<

# 通用规则：从.o文件链接成用户程序
$U/_%: $U/%.o $(ULIB_OBJS)
	$(LD) $(LDFLAGS) -T $U/user.ld -o $@ $^

# initcode生成规则
$U/initcode.bin: $U/initcode.c $U/start.S
	$(CC) $(UCFLAGS) -march=rv64g -nostdinc -c $U/initcode.c -o $U/initcode.o
	$(CC) $(UCFLAGS) -march=rv64g -nostdinc -c $U/start.S -o $U/start.o
	$(LD) $(LDFLAGS) -N -e _start -Ttext 0 -o $U/initcode.out $U/start.o $U/initcode.o
	$(OBJCOPY) -S -O binary $U/initcode.out $@
	rm -f $U/initcode.o $U/initcode.out

.PHONY: UPROGS ULIB clean build

build: $(ULIB_OBJS) $(UPROGS)



# tags: $(OBJS) _init
# 	etags *.S *.c

# ===== 磁盘文件系统构建工具  =====
mkfs/mkfs: mkfs/mkfs.c $(SRC)/fs/fs.h $(SRC)/param.h
	gcc -Werror -Wall -I. -I$(SRC) -o mkfs/mkfs mkfs/mkfs.c

# Prevent deletion of intermediate files, e.g. cat.o, after first build, so
# that disk image changes after first build are persistent until clean.  More
# details:
# http://www.gnu.org/software/make/manual/html_node/Chained-Rules.html
.PRECIOUS: %.o

# ===== 磁盘镜像构建 =====
fs.img: mkfs/mkfs README $(UPROGS)
	mkfs/mkfs fs.img README $(UPROGS)

-include $(DEPS)

clean: 
	rm -f *.tex *.dvi *.idx *.aux *.log *.ind *.ilg \
	$K/kernel fs.img \
	mkfs/mkfs .gdbinit
	rm -f $U/initcode $U/initcode.o $U/initcode.asm $U/initcode.sym $U/initcode.d $U/initcode.bin $U/start.o $U/start.d
	rm -f $U/usys.S $U/usys.o $U/usys.d
	rm -f $U/printf.o $U/printf.d
	rm -f $U/*.o $U/*.d $U/_* $U/*.asm  
	rm -rf $(BUILD_DIR)


# try to generate a unique GDB port
GDBPORT = $(shell expr `id -u` % 5000 + 25000)
# QEMU's gdb stub command line changed in 0.11
QEMUGDB = $(shell if $(QEMU) -help | grep -q '^-gdb'; \
	then echo "-gdb tcp::$(GDBPORT)"; \
	else echo "-s -p $(GDBPORT)"; fi)
ifndef CPUS
CPUS := 1
endif

QEMUOPTS = -machine virt -bios none -kernel $K/kernel -m 128M -smp $(CPUS) -nographic
QEMUOPTS += -global virtio-mmio.force-legacy=false
# 磁盘相关的 QEMU 选项 
QEMUOPTS += -drive file=fs.img,if=none,format=raw,id=x0
QEMUOPTS += -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0

# 注意：对 fs.img 的依赖
qemu: $K/kernel fs.img
	$(QEMU) $(QEMUOPTS)

.gdbinit: .gdbinit.tmpl-riscv
	sed "s/:1234/:$(GDBPORT)/" < $^ > $@

# 注意：对 fs.img 的依赖
qemu-gdb: $K/kernel .gdbinit fs.img
	@echo "*** Now run 'gdb' in another window." 1>&2
	$(QEMU) $(QEMUOPTS) -S $(QEMUGDB)

