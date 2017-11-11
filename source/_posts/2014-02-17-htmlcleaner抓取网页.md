---
title: htmlcleaner抓取网页
date: 2014-02-17 10:46:34
categories:
  - 开发
tags:
  - 移动应用
  - Android
  - htmlcleaner
---
htmlcleaner是一个分析网页的库，用起来很方便。抓取网页这事其实有很多想法可以发掘，比如我这次是做了一个下载漫画的工具，放在[这里](https://github.com/CliffHan/comichelper)。这是一个android应用，是我为了配合布卡漫画看本地漫画做的。顺便说一句，下一步的想法是把这类功能放到浏览器插件里面去。

其实这事技术上乏善可陈，就是从html文本中使用XPath抓取到合适的内容，再做进一步处理。[Sample本身](https://github.com/CliffHan/comichelper/blob/master/src/com/cliff/comic/Manhua8ComicParser.java)说明了一切。最多就是异步操作需要做一些处理而已。
