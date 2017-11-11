---
title: Firefox OS Camera应用修改(WebIDL)
date: 2014-06-12 16:43:47
categories:
  - 开发
tags:
  - 嵌入式系统
  - Firefox OS
  - Camera
---
近期需要对Firefox OS的Camera做一些修改，主要是增加一些功能实现。由于相对于Android来说， Firefox OS的接口实在是太寒酸了，所以只能通过增加接口的方式实现。从整个功能实现的角度上来说，包含两部分：Gaia<->Gecko之间的接口，Gecko<->HAL之间的接口。这篇文档暂时只讨论Gaia<->Gecko之间的接口，也就是Camera的WebIDL接口的实现。Mozilla官方的WebIDL参考文章在[这里](https://developer.mozilla.org/zh-CN/docs/Mozilla/WebIDL_bindings)。

对于Camera而言，目前增加接口主要有两种情况。Gaia层直接调用Gecko层接口；Gaia层设置回调函数到Gecko层，由Gecko层回调。针对这两种情况的修改分别是这样的。

1. Gaia层调用Gecko层接口，需要添加webidl文件中的函数。具体说来，需要：
  * 增加gecko/dom/webidl/CameraControl.webidl 中的接口，注意[Throws]是有意义的
  * 增加gecko/dom/camera/DOMCameraControl.h 中的函数声明，与webidl对应，需要注意两点：
    第一，如果webidl中的声明有[Throws]定义，那么函数声明里面需要有ErrorResult作为最后一个实参；
    第二，如果webidl中的声明有返回值，那么返回值需要作为倒数第二个实参写在函数声明中（有ErrorResult的情况）
  * 增加gecko/dom/camera/DOMCameraControl.cpp 中的函数实现

  对于webidl来说，只要编译通过，其实这部分已经完了，具体到向下调用，需要修改ICameraControl.h和CameraControlImpl等相关文件，这里就一笔带过了。
2. Gaia层设置回调函数到Gecko层，需要：
  * 增加gecko/dom/webidl/CameraControl.webidl 中的attribute和interface引用
  * 增加interface绑定定义，在gecko/dom/bindings/Bindings.conf中，用addExternalIface引入，注意nativeType就是本地interface类型
  * 增加本地interface类型定义，修改gecko/dom/camera/nsIDOMCameraManager.idl ，可以参考nsICameraRecorderStateChange的写法，也就是里面的handleStateChange函数
  * 增加gecko/dom/camera/DOMCameraControl.h 中的set/get函数声明，与webidl对应
  * 增加gecko/dom/camera/DOMCameraControl.cpp 中的set/get函数实现

  跟上面的情况一样，到这里其实webidl已经完成了，但以attribute这种回调函数而言，做到这里还没有意义，需要再增加handleStateChange函数的回调，因此还需要修改以下几个文件：
  * gecko/dom/camera/ICameraControl.h，这里是虚函数定义，DOMCameraControl.cpp中的set/get函数实现会调到ICameraControl.h中的set/get函数
  * gecko/dom/camera/CameraControlImpl.h & gecko/dom/camera/CameraControlImpl.cpp，这里是上面的虚函数的定义继承和实现，以CameraRecorderStateChange为例，在CameraControlImpl.cpp里面会调用到它的HandleStateChange，也就会触发到Gaia层的onRecorderStateChange。

上面的部分写完后，对于第一种，在gaia层js中加入调用的代码，就能执行到gecko层；对于第二种，在gaia层加上回调函数，再在gecko层通过某个消息回调，就能在gaia层收到回调。

对于整个编译过程而言，其实是这样的，所有修改的webidl/idl/conf文件，在编译过程中作为生成个别.cpp/.h的依据，然后再结合上面修改的.cpp/.h一同编译。因此如果编译无法通过的话，如果是某些定义问题，需要去看对应的webidl/idl/conf文件。例如我在webidl的修改忘了加[Throws]，生成的接口就没有ErrorResult回传的参数，自然就会出问题了。
