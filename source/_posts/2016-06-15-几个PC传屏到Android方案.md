---
title: 几个PC传屏到Android方案
date: 2016-06-15 10:44:31
categories:
  - 开发
tags:
  - 移动应用
  - Android
  - Windows
  - 传屏
---
朋友的软件公司，客户要求提供一个PC(Windows)传屏到Android的解决方案。

1. 一开始需求不明确，当然是VNC最省力。TightVNC的Windows版本源码可用，MultiVNC的Android版本源码可用。联调可以连上。唯一可惜的是MultiVNC的Discover功能不可用。不过这个功能只是用mDNS查找_rfb._tcp类型的设备，在Windows上结合Bonjour SDK for Windows开发就可以很简单的实现。
2. 客户要求在Windows上录屏，想到的解决方案就比较复杂。首先用[screen-capture-recorder](https://github.com/rdp/screen-capture-recorder-to-video-windows-free)做录屏设备；然后用ffmpeg抓屏做流输出，参考[这里](https://trac.ffmpeg.org/wiki/StreamingGuide)；接下来需要一个中转server，接收ffmpeg的流输出，并转化成rtmp流；然后就是android上的设备查找与播放器了。虽然可以实现，但涉及的范围确实有点大。
3. 最后一个想法，Miracast。Windows做Source(Sender)，Android做Sink(Receiver)。参考在[这里](https://github.com/kensuke/How-to-Miracast-on-AOSP)。

虽然提出了这些解决方案并且简单验证了一下，但考虑到成本收益问题，基本是做不成的。软件这活不好干就在这里，需求方和提供方的鸿沟，基本不可弥补，sigh。
