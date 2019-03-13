---
title: Web Push With VAPID
date: 2019-03-13 16:16:45
categories:
  - 开发
tags:
  - Push
---

开发的Client有用到Push，之前一切都好好的，突然之间就不能收Push消息了，了解了一下，居然是Push Server临时加了VAPID验证，知道这个原因后我心里默默说了一句MMP。

说归说，事情还是得做。Server端声称已经做好了跟Push Server之间的交互，只需要Client端将Server端提供的Key加进去就能跑了。我花了几分钟写完代码，花了几小时编译，然后又花了十几分钟刷机和设置，最后通知Server端发Push消息。Server端告诉我已经发啦，我等了半小时没收到，这是什么鬼？今天花了一天，总算了解了一点VAPID相关知识。

首先，Push的原理非常简单，一共有4个角色参与，Client, Push Client, Push Server, Server，为了简单点说，换成C/PC/PS/S。执行顺序是：

1. C调用PC，PC从PS获取endpoint交给C，endpoint实际是一个http/https URL
2. C拿到endpoint后，将其发送给S
3. S打算发push消息时，发一个POST请求到endpoint，PS就会收到这个请求
4. PS将push消息交给PC，PC交给C，完成

> 注意：  
>     第3步中，有可能S跟PS之间有其他的大批量处理接口  
>     如果需要VAPID，则在第1步中，C调用PC时就需要提供Key（公钥）

其次，VAPID的目的是为了解决以下几点问题：

1. PS可能为很多S服务，在Push出现问题时，PS需要找到引起问题的S，并且确认是这个S引起的，这就意味着需要身份认证
2. S需要消息被认证的C收到，也就是说不能出现随便一个C就能拿到endpoint的情况
3. S和C之间传递的消息不能被PS和PC看到

因此引入了非对称加密，也就是公钥私钥对。简单说一句，就是公钥加密的数据私钥解密，反之亦然。既可以用于身份认证，也可以用于防止消息被篡改。

使用VAPID时，由于不同接口实现，公钥私钥可能以3种形式出现：文件/二进制数组/字符串。

* 文件：即公钥私钥所在的证书文件，可能有很多种格式，比如PEM/DER等等
* 二进制数组：即公钥私钥的二进制形态，在VAPID使用的ec方法下，公钥65 byte，私钥16 byte
* 字符串：即二进制数组作base64编码后的字符串，公钥88字符，私钥44字符，都包括结尾的等号

这里详细说明一下这三种公钥私钥在命令行下的转换方法。

```shell

#生成pem格式证书，公钥私钥都在里面  
openssl ecparam -name prime256v1 -genkey -noout -out vapid_private.pem

#从证书中提取出公钥的pem格式证书  
openssl ec -in vapid_private.pem -pubout -out vapid_public.pem

#以文本方式显示公钥私钥的16进制数据  
openssl ec -in vapid_private.pem -text -noout

#将公钥和私钥的16进制数据存到文本文件，这两个文件可以修改后直接放到源码中  
openssl ec -in vapid_private.pem -text -noout | awk 'NR >=3 && NR <= 5' > vapid_private_hex.txt  
openssl ec -in vapid_private.pem -text -noout | awk 'NR >=7 && NR <= 11' > vapid_public_hex.txt

#将公钥和私钥的16进制数据文本转换为二进制文件  
xxd -r -p vapid_private_hex.txt > vapid_private.bin  
xxd -r -p vapid_public_hex.txt > vapid_public.bin

#将公钥和私钥的二进制文件做base64编码生成字符串  
base64 vapid_private.bin  
base64 vapid_public.bin

```

最后，就是发送push消息的方法。下一个[web-push](https://www.npmjs.com/package/web-push)工具。

```shell
npm install web-push --save
```

```shell
Usage:

  web-push send-notification --endpoint=<url> [--key=<browser key>] [--auth=<auth secret>] [--payload=<message>] [--encoding=<aesgcm | aes128gcm>] [--ttl=<seconds>] [--vapid-subject=<vapid subject>] [--vapid-pubkey=<public key url base64>] [--vapid-pvtkey=<private key url base64>] [--gcm-api-key=<api key>]

  web-push generate-vapid-keys [--json]
```

发送，然后收到，剩下的事就是Server和Push Server之间的问题了。