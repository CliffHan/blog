---
title: Eclipse下新建Spring MVC WEB工程
date: 2013-11-13 13:01:46
categories:
  - 开发
tags:
  - 互联网
  - WEB应用
  - Spring
  - Eclipse
---
有点想法，准备做一个Spring工程验证一下。到Spring官网突然发现，已经没有传统的下载了，要通过maven/gradle，不禁感慨这时代变化快。记录一下过程。我自己用的Eclipse juno（4.2），其他的方法应该类似。

1. Eclipse下安装两样东西，其中m2e只需要core，STS也只需要安装Spring IDE core。
  m2e: http://download.eclipse.org/technology/m2e/releases
  Spring Tool Suite: http://dist.springsource.com/release/TOOLS/update/e4.2/
2. 新建Spring project，选Spring MVC Project，我也选了一下“Simple Spring Web Maven”，但发现无法以Web应用方法调试。
3. Project Properties->Deploy Assembly增加Maven Dependencies
4. 如果编译失败，修改pom.xml中的失败的类库版本。比如我的是log4j找不到Class，改了一下log4j版本重新下载就好了。
