---
title: Firefox OS Camera
date: 2014-02-17 09:31:45
categories:
  - 开发
tags:
  - Firefox OS
  - Camera
  - Gecko
  - Qualcomm
---
为了调整rotation问题，周末跟了一天半时间，跟的很散，简单记一下。

Firefox os版本是1.3，板子是msm8210/8610共用配置。代码位置如下：
* 应用层（Gaia）部分：gaia/apps/camera
* 框架层（Gecko）部分：gecko/dom/camera; 还有android的一部分在frameworks/av/camera
* HAL部分：hardware/qcom/camera/QCamera2
* library：vendor/qcom/proprietary/mm-camera/mm-camera2
* kernel：
  配置在kernel/arch/arm/boot/dts;
  驱动在kernel/drivers/media/platform/msm/camera_v2

整个的流程，从上往下：
1. 应用启动Camera sensor，读取kernel配置
2. 应用/框架设置Camera参数
3. 上层有需要时往底层发命令，如拍照，Preview，开始录像等
4. Preview时底层驱动直接写内存，上层显示内存，可能会加Overlay；
  其他操作跟显示不直接相关

悲哀的是，虽然成功的将rotation转对了，但是由于是90度偏转，取景框跟最后照片对不上，还是要重新打板。所以这一天半的工作白做了。
