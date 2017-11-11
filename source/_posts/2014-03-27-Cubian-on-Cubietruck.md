---
title: Cubian on Cubietruck
date: 2014-03-27 13:57:14
categories:
  - 开发
tags:
  - 嵌入式系统
  - 服务器部署
  - Cubian
  - Cubietruck
---
Cubietruck买来就是为了当服务器用的，所以一开始就想着装命令行系统。试了一下lubuntu server，发现无法识别我的罗技无线键鼠；然后发现Cubian可以，于是今天开始折腾Cubian。

作为Linux初哥，先参考Cubian自己的[教程](http://cn.cubian.org/tutorials/)。安装好说，基本就是用写image的工具把镜像写到SD卡。到了实际运行，Cubian自己的教程有些东西说的不详细，在这里补充一下。

1. 默认情况下Wifi模组没有加载，命令行下使用{% codeblock lang:shell %}sudo modprobe bcmdhd{% endcodeblock %}加载。如果需要每次开机自动加载，将bcmdhd加到/etc/modules文件中。
2. 连接wifi，教程里面的方法我用起来不正常。我的方法是：
  a. 使用{% codeblock lang:shell %}wpa_passphrase ssid password{% endcodeblock %}命令，输出到一个文本文件，如/etc/wpa_supplicant/wpa_supplicant.conf
  b. 修改/etc/network/interfaces，参考教程里面的改法，去掉wpa-ssid和wpa-psk部分，只使用wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
  c. reboot
3. 硬盘在/dev/sda1，分区需要fdisk，我没分区。
  格式化：{% codeblock lang:shell %}sudo mkfs -t ext4 /dev/sda1{% endcodeblock %}
  创建挂载目录：{% codeblock lang:shell %}sudo mkdir /mnt/harddisk{% endcodeblock %}，注意需要{% codeblock lang:shell %}chmod 777{% endcodeblock %}，否则其他用户无法操作

  修改/etc/fstab自动挂载，增加一句：{% codeblock lang:shell %}/dev/sda1 /mnt/harddisk ext4 defaults 1 1{% endcodeblock %}
4. 关于LXDE，按照教程安装好后，如果不希望开机启动，需要卸载lightdm：{% codeblock lang:shell %}sudo apt-get remove lightdm{% endcodeblock %}，然后需要时使用startx启动
  字体安装ttf-wqy-zenhei，主要改Panel/Custom Look&Feel/Browser/Terminal几部分
5. 关于软件源，修改/etc/apt/sources.list首先是使用cn源，把ftp.debian.org改成ftp.cn.debian.org。当然要记得apt-get update部分软件希望用unstable版本，需要添加这一句：
  {% codeblock lang:shell %}deb http://ftp.cn.debian.org/debian sid main contrib non-free{% endcodeblock %}
  然后安装指定软件时，使用{% codeblock lang:shell %}sudo apt-get install soft_name/unstable{% endcodeblock %}或者{% codeblock lang:shell %}sudo apt-get install -t unstable soft_name{% endcodeblock %}
6. 接着上一条，我装了aria2+apache+YAAW，aria2配置文件参考在[这里](http://blog.binux.me/2012/12/aria2-examples/)，自启动设置在[这里](http://wenzhixin.net.cn/2013/10/30/debian_script_init)，apache就不说了，整个设置还是很方便的。
7. 配置时区：{% codeblock lang:shell %}sudo dpkg-reconfigure tzdata{% endcodeblock %}
8. openjdk兼容性不太好，跑tomcat会出现一些莫名其妙的错误，装java7参考[这里](http://www.webupd8.org/2012/06/how-to-install-oracle-java-7-in-debian.html)。注意安装完了还得要修改/usr/lib/jvm/default-java的链接，否则tomcat仍然会使用openjdk。像我这样的强迫症患者可以删除openjdk-7-jre-headless。
9. 关于web服务：
  ajenti用的https，没用apache转接，但性能太弱，平时禁用。
  路由器管理界面用路由转接了一下。
  下载除了aria2还装了迅雷，但迅雷占内存较大，平时禁用。
  ddns用openwrt的似乎有问题，换了本地脚本连dnspod，用start-stop-daemon做了daemon脚本，用insserv命令加入自启动。

最后，实践证明，局域网还是有线好一点，用无线（应该是11n，实际速度未测）的话，1080p视频会卡。
