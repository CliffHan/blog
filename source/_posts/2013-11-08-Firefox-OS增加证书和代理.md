---
title: Firefox OS增加证书和代理
date: 2013-11-08 16:58:43
categories:
  - 开发
tags:
  - Firefox OS
---
**增加证书**：

1. Ubuntu下安装libnss3-tools，使用里面的certutil
2. 获取手机上的/data/b2g/mozilla/<RANDOMSTRING>.default/cert9.db和key4.db
3. root用户执行以下几个命令：
{% codeblock lang:shell %}
certutil -d sql:. -W   ;不输入密码，直接确认
certutil -A -n "<CAName>" -t "PTCu,PCu,PTuw" -u "V" -d sql:. -i <CAFile>     ;加入证书
certutil -V -n "<CAName>" -u V -d sql:.        ;如果前面操作正常，此命令可以看到结果正确
{% endcodeblock %}
4. 将cert9.db和key4.db两个文件用adb push放回原来的目录

**修改Firefox OS代理**

修改手机上的/system/b2g/defaults/pref/user.js，在最后增加代理信息，如：
{% codeblock lang:javascript %}
pref("network.proxy.type", 2);
{% endcodeblock %}
可以修改的属性包括，其中network.proxy.type的值[参考地址](http://kb.mozillazine.org/Network.proxy.type)：
{% codeblock lang:javascript %}
pref("network.proxy.type",                  5);
pref("network.proxy.ftp",                   "");
pref("network.proxy.ftp_port",              0);
pref("network.proxy.http",                  "");
pref("network.proxy.http_port",             0);
pref("network.proxy.ssl",                   "");
pref("network.proxy.ssl_port",              0);
pref("network.proxy.socks",                 "");
pref("network.proxy.socks_port",            0);
pref("network.proxy.socks_version",         5);
pref("network.proxy.socks_remote_dns",      false);
pref("network.proxy.no_proxies_on",         "localhost, 127.0.0.1");
pref("network.proxy.failover_timeout",      1800); // 30 minutes

// The PAC file to load.  Ignored unless network.proxy.type is 2.
pref("network.proxy.autoconfig_url", "");

// If we cannot load the PAC file, then try again (doubling from interval_min
// until we reach interval_max or the PAC file is successfully loaded).
pref("network.proxy.autoconfig_retry_interval_min", 5);    // 5 seconds
pref("network.proxy.autoconfig_retry_interval_max", 300);  // 5 minutes
{% endcodeblock %}
