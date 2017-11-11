---
title: Firefox OS Camera应用修改(Gecko)
date: 2014-06-30 11:21:45
categories:
  - 开发
tags:
  - 嵌入式系统
  - Firefox OS
  - Camera
  - Gecko
  - Qualcomm
---
Gecko层跟HAL层通过消息交互，控制Camera硬件。所谓控制Camera硬件，其实就是向Camera硬件设置参数或发送命令以及接收响应。对应的几类做法如下：

1. SetParameter/GetParameter相关功能，这类功能只需要写参数就可以使用。根据参数的不同， 功能可能立即生效或重启camera硬件后生效。
  具体说来，以scene-mode为例，有两种做法：
  第一种，向上暴露setParameter接口，从js直接调用setParameter("scene-mode", "auto")这样的模式；
  第二种，向上暴露一个attribute为scene-mode，然后在gecko层增加get/set函数，并在set函数中setParameter；
  理论上第二种安全一些，但如果每一个都这么做，工作量多了不少。
2. SendCommand方式，这类功能需要发送命令给Camera硬件。Camera硬件接到命令后，可能会通过消息机制通知Gecko层。Gecko层需要将信息送回Gaia，然后在js中操作应用界面。
  具体说来，与上面setParameter做法相同，两种做法：
  要么向上暴露sendCommand接口，从js直接调用；
  要么向上暴露具体命令接口(如startFaceDetection/stopFaceDetection)，然后在Gecko层实现具体功能。

下面以人脸识别功能为例详细说明一下。

几个关键文件：
system/core/include/system/camera.h: CAMERA_MSG的定义（来自android）
hardware/qcom/camera/QCamera2/HAL/QCamera2HWI.cpp: HAL层发送CAMERA_MSG及处理CAMERA_CMD
gecko/dom/camera/GonkCameraHwMgr.cpp: Gecko层接收CAMERA_MSG及发送CAMERA_CMD

Face Recognition的实现，首先在GonkCameraHwMgr.cpp中增加发送命令接口， 由应用发送CAMERA_CMD_START_FACE_DETECTION，此时人脸识别功能打开。

接下来，在GonkCameraHwMgr.cpp中可以看到postData函数回调，在这里接收CAMERA_MSG_PREVIEW_METADATA消息，可以收到识别到的人脸信息（在metadata中，可以在camera.h查看数据结构）。

将识别到的人脸信息送到Gaia层，这里我用了简单的字符串来传递信息。在Gecko层将需要传上去的信息组成JSON字符串。在js解析。

需要停止人脸识别功能时，发送CAMERA_CMD_STOP_FACE_DETECTION命令即可。

另外，由于送上来的是相机坐标系的数据，要根据屏幕坐标系换算才能得到正确的数据。
