---
title: OpenWrt上编译redsocks
date: 2013-11-06 14:22:09
categories:
  - 开发
tags:
  - OpenWrt
  - redsocks
---
一开始以为编译for OpenWrt的应用很难搞，看懂了文档之后发现也挺简单的。

1. 下载redsocks改版，从这个[github地址](https://github.com/semigodking/redsocks)
2. 写一个脚本build.sh
  {% codeblock lang:shell %}
  !/bin/bash
  PATH=$PATH:~/workspace/openwrt/attitude_adjustment/staging_dir/toolchain-mips_r2_gcc-4.6-linaro_uClibc-0.9.33.2/bin/
  export PATH
  STAGING_DIR=~/workspace/openwrt/attitude_adjustment/staging_dir/toolchain-mips_r2_gcc-4.6-linaro_uClibc-0.9.33.2/
  export STAGING_DIR
  make CC=mips-openwrt-linux-uclibc-gcc LD=mips-openwrt-linux-ulibc-ld
  {% endcodeblock%}
  3. 修改Makefile中的CFLAGS，将其中的路径改为正确的include和lib路径
  4. 执行build.sh，获取redsocks2可执行程序

整体参考[OpenWrt官方教程](http://wiki.openwrt.org/doc/devel/crosscompile)

P.S. 从实际运行的效果来看，这个版本感觉不太稳定。https好像也不通。
