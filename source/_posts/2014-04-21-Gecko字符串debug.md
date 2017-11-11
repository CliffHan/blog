---
title: Gecko字符串debug
date: 2014-04-21 15:15:59
categories:
  - 开发
tags:
  - Firefox OS
  - Gecko
---
Gecko中有多种字符串，如nsString/nsCString/nsACString/nsAString等等。打Log时要转成char*处理，几种不同字符串转换方法如下：

* nsString：NS_LossyConvertUTF16toASCII(string).get()
* nsACString：PromiseFlatCString(string).get()
* nsCString：string.get()
* nsAString：ToNewUTF8String(string)
