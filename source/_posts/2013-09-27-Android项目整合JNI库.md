---
title: Android项目整合JNI库
date: 2013-09-27 09:28:47
categories:
  - 开发
tags:
  - Android
  - JNI
---
公司里一个项目，修改了framework，向上放出了JNI接口，并在一个系统应用里调用，整个的编译环境关键点做一下记录，参考文章在此：~~[Android下编译自己的库文件jar并在应用中调用](http://hi.baidu.com/gaogaf/item/cef2285e2372bb444fff2046)~~

整合流程如下：
1. 写JNI工程Android.mk，注意LOCAL_MODULE的名字前面必须有小写的"lib"字样，JNI工程编译输出的lib会被放到system/lib，所以在java工程中直接调用就可以，System.loadLibrary时不需要加"lib"字样
2. 写jar工程Android.mk和permission文件，看参考文章
3. 写android应用工程Android.mk，看参考文章
4. 整个android工程编译
