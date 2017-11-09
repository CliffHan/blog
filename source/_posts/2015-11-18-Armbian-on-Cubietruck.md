---
title: Armbian on Cubietruck
date: 2015-11-18 14:33:12
categories:
  - 开发
tags:
  - 嵌入式系统
  - 服务器部署
  - Cubian
  - Cubieboard
  - Cubietruck
  - Debian
---
折腾无止境，之前[在Cubietruck上搞定了Cubian X1](/2015/11/13/Cubian-X1-on-Cubietruck)，虽然Cubian确实不错，但还是有几个缺点：

1. 基于debian wheezy，有点过时
2. 路由重启时，wlan0接口无法自动重连，原因不明

基于以上原因，我找到了[armbian](http://www.armbian.com/)，基于debian jessie，够新。基本上Cubian X1的所有设置都可以用，参考之前笔记即可，这里光说说注意事项：

1. 版本选vanilla kernel，较新的kernel；做server用debian jessie，做电脑用ubuntu trusty
2. 这个版本好象不支持信号灯，没仔细观察
3. armbian初次启动时间会很久，后台会做apt-get update等一系列工作，所以没必要急着ssh连上去
4. 无法安装到nand（但可以安装到sata），不知道是否跟这部分[debian官方wiki说明](https://wiki.debian.org/InstallingDebianOn/Allwinner#Storage_options)有关
5. 要使用wifi，需要下载一个txt？参考这个[debian官方wiki说明](https://wiki.debian.org/InstallingDebianOn/Allwinner#Cubietech_Cubietruck)，我很莫名，但照做了
6. wlan0接口默认没有开启，需要自己修改/etc/network/interfaces
7. 安全起见，sshd默认端口需要在/etc/ssh/sshd_config中修改
8. root账户没禁用，这个我懒得修改了
9. systemd不是默认启动的，暂时也没有折腾的必要

目前看起来一切正常，希望这个版本能稳定撑到我换服务器为止。
