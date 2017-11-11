---
title: Firefox 2.0 Camera加连拍功能
date: 2014-09-11 15:14:33
categories:
  - 开发
tags:
  - 移动应用
  - Firefox OS
  - Camera
---
最近很懒，由于做的事情太杂，太久没写东西了，今天随便写点。

之前在Camera里面加连拍是一个取巧的做法，也就是直接设置parameter里的连拍参数，好象是burst-num之类，然后下发一个longshot的cmd消息打开连拍，最后改一下返回照片时的指针处理就可以了。很明显，这种方式把事情全部丢给了硬件来做，因此是取巧的做法。现在参考了Android Camera中的连拍功能，打算改一下。

其实Android Camera中的连拍做法思路也很简单，界面上长按拍照键，下层重复发拍照指令即可，只是需要设置一些参数，如zsl等。

对Firefox OS 2.0的Camera代码分析：

* js/views/controls.js   bindEvents->onButtonClick, 拍照按键开始绑定事件->发出click:capture消息
* js/controllers./controls.js bindEvents->onCaptureClick, 接收click:capture消息, 发出capture消息
* js/controllers/camera.js bindEvents->capture, 接收capture消息, 执行capture操作
* js/lib/camera/camera.js capture->takePicture->onSuccess, 调用硬件拍照接口, 异步回调onSuccess, 发出newimage消息
* js/controllers/camera.js bindEvents, 接收newimage消息, 发出camera:newimage消息, 全局可接收

从流程看来,新版本代码基本是消息驱动机制, 由消息触发事件, 各个模块都可以接收和处理消息, 具体细节需继续分析。

目前关于连拍长按的处理，我目前基本是做了以下几件事，供参考：

1. js/views/controls.js
  * 增加了对于capture-button的touchstart和touchend事件的处理,增加isCapturePressing变量表示按键是否被按下
  * 去掉了对于capture-button的默认onButtonClick的操作
  * 在Touchstart事件响应函数触发按键消息
2. js/controllers/controls.js
  * 增加了camera:newimage事件的处理
  * 处理函数中判断isCapturePressing变量值,确定是否要再次拍照

以上改动即可已完成初步功能，当然一些细节还需要处理，比如拍照完成后的闪烁，以及zsl的设置和longshot命令的发送，需要改gecko。
