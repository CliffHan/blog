---
title: OpenWRT和mwan3
date: 2014-11-01 01:32:04
categories:
  - 开发
tags:
  - 嵌入式系统
  - OpenWrt
---
家里路由器是Buffalo G450H，因为之前用的ColorBox系统的DDNS有点问题，所以今天来了兴致，刷了OpenWRT最新的BarrierBreaker版本。其他的配置都很明确，就是单线多拨费了点功夫，记录一下。

参考资料在[这里](http://www.right.com.cn/forum/forum.php?mod=viewthread&tid=132875&page=1)。

概念上几个关键点是这样的：

1. 需要装kmod-macvlan，修改启动脚本，在物理接口上增加n-1个虚拟网卡
2. 需要为每个虚拟网卡创建接口，注意要有metric。原来的wan也要注意加上metric。同时将接口加入防火墙中的wan组
3. 需要在mwan3设置中创建对应接口
4. 需要在mwan3设置中创建Member，分配每个接口的权重
5. 需要在mwan3设置中创建policy，将所有member加入
6. 需要在mwan3设置中创建rule，根据各种情况选择policy

实际设置起来还是有点复杂的。所以写个备忘。
