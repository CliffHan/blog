---
title: Aria2 on Netgear R8500
date: 2017-11-28 11:13:50
categories:
  - 开发
tags:
  - Router
  - Aria2
---
十一月的时候突然有心情，于是买了台R8500，感受了一下传说中的高端路由器。不过实际用起来，也就那么回事。优点是有的，比如：5G速度快太多了，用笔记本局域网无线拷贝数十MB的速度看的我是心花怒放。稳定性和带机量有待观察，但相信肯定比之前的小米Mini好。缺点更不用说，贵成马。

最近开始整理移动硬盘，把旧的降级为下电影专用。正好路由带USB口，就买了个硬盘盒接上了。然后才发现，R8500居然没有下载器？！R7000带而更高端的R8500反而不带，[官方社区里面一个用户吐槽了1年多](https://community.netgear.com/t5/Nighthawk-WiFi-Routers/Nighthawk-X8-R8500-netgear-downloader/td-p/1136132)，可见用户深深的怨念。

本来如果有LEDE或者OpenWRT，我就顺手刷机了。可搜了半天，R8500的自制Firmware只有[Koolshare的Merlin改版](http://firmware.koolshare.cn/merlin_8wan_firmware/R8500/)。虽然我挺喜欢Merlin，不过对这种闭源的非官网改动我一般都是心存疑虑的。指望官网更新加上Downloader也不现实，想想那个等了一年多的用户，我觉得还是自己用Aria2搞定比较好。

首先，打开路由器debug页面（/debug.htm），打开telnet功能。帐号密码就是管理员帐号密码。
telnet连上以后，很明显可以看出，官方固件仍然是一个Linux，只不过是残废版本的，各种工具不凑手。不过没关系，我们就加个应用而已。
telnet命令行下df可以看到，接在usb3.0口的硬盘被mount到/tmp/mnt/usb0/part1，估计如果接usb2.0可能会不一样。

接下来，编译或者下载现成的Aria2的binary。
这一步说麻烦也麻烦，走编译路线的话，需要去[Netgear官网](https://kb.netgear.com/2649/NETGEAR-Open-Source-Code-for-Programmers-GPL)下源码，找工具链/Aria2源码/各种依赖的工具库，一起编译出Aria2。
走下载路线的话，拿不到最新的版本，不过我在Koolshare的github上发现了[这个](https://github.com/koolshare/merlin-aria2/blob/master/aria2/aria2/aria2c)，直接下下来是可以用的。

再接下来，就是写配置文件，放到硬盘上，例如我的是这样的：
{% codeblock lang:shell %}
###########
# General #
###########

dir=/tmp/mnt/usb0/part1/download
ca-certificate=/tmp/mnt/usb0/part1/ca-certificates.crt

# allow-overwrite=true
# disable-ipv6=true
# quiet=true

##############
# RPC Server #
##############

enable-rpc=true

rpc-listen-port=6800
rpc-allow-origin-all=true

rpc-listen-all=true
rpc-secret=password

# rpc-secure=true
# rpc-certificate=
# rpc-private-key=

##############
# Connection #
##############

max-concurrent-downloads=5
max-connection-per-server=10

# timeout=60
# max-tries=5
# retry-wait=0

###########
# Session #
###########

input-file=/tmp/mnt/usb0/part1/download/.aria2.session
save-session=/tmp/mnt/usb0/part1/download/.aria2.session
save-session-interval=60

bt-seed-unverified=true
bt-save-metadata=true


###############
# DHT related #
###############

enable-dht6=false
enable-dht=true
bt-enable-lpd=true
dht-entry-point=router.utorrent.com:6881
dht-file-path=/tmp/mnt/usb0/part1/download/dht.dat
{% endcodeblock %}

具体的参数定义需要去看[Aria2官网](https://aria2.github.io/)的Documentation。
这里有一个小问题需要提一下，就是
{% codeblock lang:shell %}
ca-certificate=/tmp/mnt/usb0/part1/ca-certificates.crt
{% endcodeblock %}
这一句，路由器上是找不到这个证书的，需要从外面拷贝，我自己是从Windows的Lxss环境中拖出来的，是否合适还需要时间验证。

最后就是运行了，在telnet执行aria2c命令，加--conf-path和--daemon参数，会使得Aria2在后台运行，比如我的就是：
{% codeblock lang:shell %}
/tmp/mnt/usb0/part1/aria2c --conf-path=/tmp/mnt/usb0/part1/aria2c.conf --daemon
{% endcodeblock %}
建议先不加--daemon，可以看输出是否正确。不加daemon的话只要Ctrl-C就可以停止应用。

在daemon模式下运行时，通过
{% codeblock lang:shell %}
ps | grep "aria2c"
{% endcodeblock %}
就可以看到应用是否在运行中，用kill命令可以杀掉对应进程。

应用运行之后，默认会监听6800端口，监听地址是类似 http://ip_of_router:6800/jsonrpc 这样的路径。客户端可以使用Web应用，比如我用的[这个](http://ariang.mayswind.net/latest/)，或者[手机端应用](https://play.google.com/store/apps/details?id=net.sf.aria2)，甚至[Chrome插件](https://chrome.google.com/webstore/detail/aria2c-integration/edcakfpjaobkpdfpicldlccdffkhpbfk)。连接的设置无非不过就是监听地址，再加上rpc-secret中设置的密码。连接成功后就可以通过客户端添加下载链接了。

P.S. 之前以为可以用DDNS连接，但后来发现不行，原因我猜测是因为防火墙不开放6800端口，做端口转发也无法使用本机IP。所以现在只能VPN连接后用局域网地址连接。希望R8500的LEDE早日出现吧。
