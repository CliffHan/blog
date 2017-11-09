---
title: Intellij IDEA的Gradle Android Module
date: 2016-05-24 16:13:35
categories:
  - 开发
tags:
  - 移动应用
  - Android
---
浪费两年半时间，终于回到Android的项目，sigh…

用IDEA新建一个Gradle的Android Module，但是编译不过。其实都是一些很小的问题。

1. build.gradle有两个，根目录下和app目录下
2. 需要把根目录下的android段删掉
3. 需要使用com.android.tools.build:gradle:2.1.0的dependencies
4. 命令行下需要设置JAVA_HOME为1.7以上的JDK
