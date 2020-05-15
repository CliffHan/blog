---
title: TP-Link WDN5200h Ubuntu
date: 2020-05-15 16:34:59
categories:
  - 开发
tags:
  - WDN5200H
  - Ubuntu
---

小米Wifi在公司用的时候，可能是发热太高，偶尔会出现无法使用的情况。但拔下来过一会再插上就OK了。

不想跟自己过不去，就申请了一个Wifi Dongle。不过公司有限制，大约就100块，多了不好批。

挑了一下，有两个选择，**Edimax**的**EW-7811UN**和**TP-Link**的**WDN5200H**。前者Ubuntu下免驱，不折腾，但只支持2.4G；后者支持5G网络，但需要自己编驱动。作为一个闲的无聊的程序员，我毅然选择了后者。不就是折腾嘛，哥有时间。

今天拿到WDN5200H，插上一看，果然不认。四处找驱动源码，结果各种不能编译。仔细一看才发现，我的Ubuntu18.04的Kernel已经升到5.3了，跟4.X的header定义有点冲突。找了多个源，总算找到一个[最新的驱动](https://github.com/brektrou/rtl8821CU)。

不过呢，这个源码在Ubuntu上直接编译是不过的，可能是作者犯了一个小小的错误。在作者修改之前，代码需要做一点小小的改动。即是在`os_dep/linux/ioctl_cfg80211.h`中，增加这么一段：

```c
#ifndef RHEL_RELEASE_VERSION
#define RHEL_RELEASE_VERSION(a,b) (((a) << 8) + (b))
#endif

#ifndef RHEL_RELEASE_CODE
#define RHEL_RELEASE_CODE 0
#endif
```

按照Readme里面的做法，做完之后，驱动已经加载了。但是还需要多做一步。

```shell
sudo usb_modeswitch -KW -v 0bda -p 1a2b
```

这是怎么回事？研究了一下，原来是这么回事。WDN5200H默认带了一个USB光盘，也就是说，插入USB时，系统优先把默认的`0bda:1a2b`当成那个USB光盘了。执行这条命令，会使得系统自动弹出`0bda:1a2b`，重新插入真正的网卡`0bda:c811`，也就是真正的8811cu网卡。

上面那句，在每次插入Dongle时，都要执行一次，太繁琐了。要让它自动执行，还需要做下面两件事：

1. 在`/lib/udev/rules.d/40-usb_modeswitch.rules`中，增加这么一句：

```properties
# Tp-Link WDN5200H
ATTR{idVendor}=="0bda", ATTR{idProduct}=="1a2b", RUN+="usb_modeswitch '/%k'"
```

2. 在`/etc/usb_modeswitch.d/`目录下，增加一个名为`0bda:1a2b`的文件，内容是

```properties
DefaultVendor=  0x0bda
DefaultProduct= 0x1a2b
StandardEject=1
```

重启udev服务后，只要插上Dongle，就可以自动识别了。