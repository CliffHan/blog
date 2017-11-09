---
title: Cubian X1 on Cubietruck
date: 2015-11-13 14:30:55
categories:
  - 开发
tags:
  - 嵌入式系统
  - 服务器部署
  - Cubian
  - Cubietruck
---
Cubietruck是一个开发板，性能略优于Raspberry。自13年入手以来，在我家作为服务器勤勤恳恳的工作了2年了。之前也有记录过[笔记](/2014/03/27/Cubian-on-Cubietruck/)。近期准备重新发掘一下它的功能。记录一下从零开始的过程。

Cubieboard实际上是一个系列，我手上的是第三代产品。截止到现在（2015年底），[第四代](http://cubieboard.org/2015/03/10/cubieboard4cc-a80-released/)已经在售，[第五代](http://cubieboard.org/2015/07/14/the-prototype-photoes-of-cubieboard5/)原型图也已经出来了，注意第四代产品没有SATA。新产品性能更强价格更高自不必说，不过主板到了700块以上的价格，我觉得就不如Intel N3000系列的无风扇主机划算了，比如AsRock的Beebox之类。这里不多说。

Cubieboard系列在[官方网站](http://cubieboard.org/)和[论坛](http://cubie.cc/forum.php)有购买地址。

Cubietruck板卡和外壳如下图，自己装起来即可。
{% asset_img board.png 板卡 %}
{% asset_img shell.png 外壳 %}

能在Cubietruck上工作的系统很多，常用的就是Android和各种Linux发行版。官方提供了一些版本，但奇怪的是分了两个地址存放（[地址一](http://dl.cubieboard.org/model/cubietruck/Image/)、[地址二](http://dl.cubieboard.org/software/a20-cubietruck/)）。

我用的是Cubian，并非官方提供，但根据两年来使用的经验，感觉比较稳定，而且作者提供的资料也比较齐全。主站在[这里](http://cubian.org/)。下面依次记录一下安装和设置过程。

1. Cubian的安装：简单说就是用ImageWriter（Win）或dd(Linux)把img写到TF卡然后启动，再通过命令写入nand（可选）。原始教程在[这里](https://github.com/cubieplayer/cubian/wiki/Install-Cubian)，但有个[注意事项](http://cn.cubian.org/2014/06/30/troubleshooting-nandinstall-on-a20/)，就是**需要保证nand上的原始版本不是Android**，否则TF也无法启动。我就踩了这个坑。解决办法很简单，用官方提供的PhoenixSuit/LiveSuit把官网提供的Lubuntu刷到nand上即可，记得按住FEL键再通电。
2. 连接Cubian：我使用的headless版本是无显示的。刚装完Cubian以后，有线网卡是可用的，需要使用网线连接路由，DHCP分配IP。Cubian提供了用信号灯摩斯密码的方式告知IP，但我其实没那么geek，直接在路由器管理网页里面看看连接的设备即可。ssh连接36000端口，初始用户名密码都是cubie。
3. 用户切换，将默认cubie用户改为自己的用户。执行以下命令
{% codeblock lang:shell %}
###用cubie用户登录
#切换到root
sudo -i;
#添加一个临时用户
adduser temporary
#临时用户提权到sudo组
usermod -a -G sudo temporary

###用temporary临时用户重新登录
sudo -i
#new_user是新用户名，old_user就是cubie
usermod -l new_user old_user
#修改组名
groupmod -n new_user old_user

###用new_user重新登录
#创建主目录
mkdir /home/new_user
#切换到root
sudo -i
#切换主目录
usermod -d /home/new_user new_user
#删除临时用户
userdel temporary
#删除临时用户主目录
rm -rf /home/temporary
{% endcodeblock %}
接下来就可以改密码了
4. wifi连接需要运行wpa_passphrase命令得到psk，然后修改/etc/network/interfaces中wlan一段，按照这个格式：
{% codeblock lang:shell %}
auto wlan0
iface wlan0 inet dhcp
    wpa-ssid ssid
    wpa-psk psk
{% endcodeblock %}
然后重启网络，
{% codeblock lang:shell %}
sudo ifdown wlan0 && ifup wlan0
{% endcodeblock %}
或重启机器即可
5. PPPOE连接，首先安装pppoe和pppoeconf，接下来运行
{% codeblock lang:shell %}
sudo pppoeconf eth0
{% endcodeblock %}
即可看到ppp0拨号，如果出错，需要去看是不是/etc/ppp/peers/dsl-provider和/etc/network/interfaces中配置有错。
在/etc/ppp/peers/dsl-provider中的defaultroute行下面增加一行
{% codeblock lang:shell %}
replacedefaultroute
{% endcodeblock %}
6. 软件安装设置
{% codeblock lang:shell %}
#cubian新增设置工具，修复Locale报错等问题
sudo cubian-config

#修复apt-get update时的报错
sudo aptitude install debian-keyring debian-archive-keyring

#所有软件升级
#需要先修改/etc/apt/sources.list到中国源, 加入sid源
#也可以顺便把/etc/apt/sources.list中的ajenti屏蔽掉
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install cubian-update
sudo cubian-update

#ss/haproxy/privoxy相关服务配置
sudo apt-get install python-pip
sudo pip install shadowsocks

#编译libev版本ss
git clone https://github.com/shadowsocks/shadowsocks-libev.git
cd shadowsocks-libev
sudo apt-get install build-essential autoconf libtool libssl-dev libevent-dev
./configure && make
make install

#nodejs
curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
sudo apt-get install -y nodejs
{% endcodeblock %}

设置完成，Enjoy
