# this is for using distribution provided bpftool
BPFTOOL=$(shell which bpftool)

CFLAGS:=-O3 -iquote out/include

CFLAGS+=$(shell pkg-config --cflags libbpf)
CFLAGS+=$(shell pkg-config --cflags fmt)
LDFLAGS=$(shell pkg-config --libs libbpf)
LDFLAGS+=$(shell pkg-config --libs fmt)

BPFFLAGS:=${CFLAGS} -g
BPFFLAGS+=-target bpf
BPFFLAGS+=-fno-stack-protector -Wno-unused-command-line-argument

.PHONY: all
all: out/cgroup_monitor

out/include:
	@mkdir --parent $@

vmlinux.h: Makefile
	@echo "[VMLINUX] $@"
	@${BPFTOOL} btf dump file /sys/kernel/btf/vmlinux format c > $@

out/%.bpf.o: %.bpf.c event.h vmlinux.h out/include
	@echo "[BPF]     $@"
	@clang ${BPFFLAGS} -c -o $@ $<

out/include/cgroup_monitor.skel.h: out/cgroup_monitor.bpf.o
	@echo "[SKEL]    $@"
	@${BPFTOOL} gen skeleton $< name exec > $@

out/%.o: %.cpp out/include/cgroup_monitor.skel.h event.h
	@echo "[CC]      $@"
	@clang++ ${CFLAGS} -std=c++20 -c -o $@ $<

out/cgroup_monitor: out/cgroup_monitor.o out/poller.o out/cgroup.o
	@echo "[LD]      $@"
	@clang++ $^ ${LDFLAGS} -o $@

run: out/cgroup_monitor
	@echo "[RUN]     $<"
	@sudo $<

install:
	install -d $(out)/bin
	install out/cgroup_monitor $(out)/bin

clean:
	@echo "[CLEAN] out"
	@-rm -rf out
