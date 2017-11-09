---
title: libdmclient代码阅读
date: 2016-11-22 13:23:12
categories:
  - 开发
tags:
  - OMADM
  - 嵌入式系统
  - 移动应用
  - libdmclient
---
[libdmclient](https://github.com/01org/libdmclient) 是oma-dm的客户端库，基于[syncml rtk](https://sourceforge.net/projects/syncml-ctoolkit/)库封装，后者源出自syncml.org，但现在打不开。libdmclient里面充斥着大量的指针强制转换，且缺少文档。虽然代码量不大，但阅读起来比较繁琐。

libdmclient里面包含了一个test的例子，从这个例子里可以看到libdmclient的使用方法，以下对其中的主要函数进行简单分析：

关于omadmclient_session_init，初始化

* 一切开始是从omadmclient_session_init开始，初始化一个session句柄，全局变量是g_session，该句柄对外是dmclt_session类型，也是一个无类型指针；在dmcore内部是internals_t类型的指针，定义在dmcore/src/internals.h。
* 在上面这个internals_t结构体中，InstanceID_t类型的smlH就是在SyncMLRTK（externals/SyncMLRTK/src/sml/inc/smldef.h）中的一个无类型（或short类型）指针，可以理解为syncml Handle。从最上层跟SyncML RTK基本就是靠这个句柄来维持instance的。
* 再说一下internals_t，这是libdmclient自己的session指针，其中有一个链表，放置所有element
* SyncML RTK初始化instance是在smlInitInstance函数，该函数设置了callback和options，输出是上面说到的InstanceID_t。其中callback在dmcore/src/callbacks.c中hard-coded，options仅包含了encoding（xml/wbxml）和workspaceSize（40000）两个值。smlInitInstance位于externals/SyncMLRTK/src/sml/mgr/all/mgrinstancemgr.c，有注释。

关于omadmclient_session_start，启动会话

* 中间UI_Callback和add_mo过程略过，接下来是omadmclient_session_start。这里需要给出serverID。这个过程没做太多事情，主要就是检查serverID，和将状态置为STATE_CLIENT_INIT，应该是用于状态机的初始化状态。
* 从已经看到的代码来看，状态机处理非常简单，只有STATE_IN_SESSION/STATE_SERVER_INIT/STATE_CLIENT_INIT这3个，意思比较明显

关于omadmclient_get_next_packet，获得下一个要发的包

* 这里是根据句柄获得buffer的地方，buffer的类型是dmclt_buffer_t，定义在dmcore/include/omadmclient.h，其中调用到的主要函数有：
    * prvCreatePacket1，非STATE_IN_SESSION状况，也就是CI/SI的情况下，需要在internals_t结构中，增加alert和devinfo element
    * prvComposeMessage，真正组合消息的代码，将internals_t中的链表，依次丢到syncml rtk，以允许底层生成xml buffer
    * smlLockReadBuffer，锁定buffer，得到xml代码

关于omadmclient_process_reply，处理http/https响应，没有例子，暂时不看了，不解释。

关于omadmclient_session_close，关闭会话，不解释。

总体来说，omadmclient的本质就是在一个持续的for循环中，不断地完成这样的循环：
{% mermaid %}
graph LR
  A[发消息给server] --> B[收消息解析]
  B --> C[更新本地数据结构/UI callback等]
  C --> D[生成下一个包]
  D --> A
{% endmermaid %}

而libdmclient的本质就是分层处理，在libdmclient这一层面，通过internals_t结构的全局变量，保存所有元素，并在需要时将所有元素丢到syncml RTK（其函数通常都以sml开头），并从syncml RTK得到最后输出的buffer。处理http/https结果的解析部分没看，但应该类似。

第二部分，omadmclient_session_add_mo，添加plugin

add_mo函数的参数是session句柄和mo接口指针，session句柄和mo的关系是：(internals_t)->dmtreeH(dmtree_t)->MOs(mo_mgr_t)，括号里面是数据结构名。

核心的实现在momgr.c中的momgr_add_plugin函数中，添加mo的主要动作包括：

1. 执行initFunc，此时得到data的回调
2. 将mo plugin的interface/data/container塞到MOs中

每一个mo包含base_uri和以下回调函数：
* initFunc
* closeFunc
* isNodeFunc
* findURNFunc
* getFunc
* setFunc
* getACLFunc
* setACLFunc
* renameFunc
* deleteFunc
* execFunc

不需要全部实现，但initFunc必须要有，否则无法加到session中。
这些函数的定义在dmcore/include/omadmtree_mo.h中
