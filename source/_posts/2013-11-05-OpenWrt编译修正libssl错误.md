---
title: OpenWrt编译修正libssl错误
date: 2013-11-05 17:08:00
categories:
  - 开发
tags:
  - OpenWrt
  - libssl
---
拿公司买的Buffalo G450H装了OpenWrt，跑某python应用的时候出现
{% codeblock lang:shell %}
python: md_rand.c: 316: ssleay_rand_add: Assertion `md_c[1] == md_count[1]' failed
{% endcodeblock %}
然后应用崩溃退出，查了一下是这个原因：[参考地址](http://xuguang.info/blog/2013/02/solve-openwrt-python-md-rand-error/)。

既然确定是libopenssl问题，那就解决吧，按照OpenWRT[官网教程](http://wiki.openwrt.org/doc/howto/easy.build)，完整的做一遍，除了最后一步“make V=s”暂时不做。

进入OpenWrt源码目录，编辑package/openssl/Makefile，将114行从
{% codeblock lang:makefile %}
TARGET_CFLAGS += $(FPIC)
{% endcodeblock %}
修改为
{% codeblock lang:makefile %}
TARGET_CFLAGS += $(FPIC) -DOPENSSL_THREADS -pthread -D_REENTRANT -D_THREAD_SAFE -D_THREADSAFE
{% endcodeblock %}

然后make menuconfig，修改目标平台和package，增加openssl，整个编译，这是我的笨办法。

最后把编译出来的两个文件libssl.so.1.0.0和libcrypt.so.1.0.0拷贝到G450H的/user/lib目录，当然记得把原来的两个备份一下，重启该python应用，一切正常，搞定收工。
