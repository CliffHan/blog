---
title: 怎么看Spring4的Demo
date: 2015-02-04 16:51:14
categories:
  - 开发
tags:
  - 互联网
  - 服务器部署
  - Spring
  - WEB应用
---
前几天看到一篇文章，[Web研发模式演变](https://github.com/lifesinger/lifesinger.github.com/issues/184)，对于前端后端的看法跟我最近的一些思考很搭。为了向全栈发展，借前几天做完了WebRTC前端的动力，打算再去看看后端。当然是熟悉的Java，熟悉的Spring。一看吓了一跳，Spring现在完全不是以前的Spring了，所有的Demo一概看不懂。那么几行代码，完成那么多功能，这是怎么回事？

看了两天，总算小有理解，原来事情是这样的：

1. Spring现在是一个完善的framework。也就是说，按照Spring的想法，不管应用开发者打算开发什么样的应用，只要是java语言的，spring都可以帮忙。
2. 按之前的观点，要做一个Java应用，要写一个class，有main方法，然后处理classpath，ant编译打包什么的。现在Spring告诉我，这些全都不用了。你下一个gradle，写一个build.gradle，把一些dependencies写在里面，然后再抄一个Spring例子里的Application类，写个main方法，放到src/main/java/目录下，执行，搞定。
3. 上面那个看起来没什么改变，现在假设我要做一个Web应用，传统的方法，我就必须按照Sun的标准，写index.jsp，写WEB-INF下的配置，找个Application Server比如Tomcat，上传，然后启动Server，blahblah 。现在Spring说，这些也不用了，你跟上面的做法一样，再把静态资源放到src/main/webapp/，动态资源写个java类，加上@Controller标签，写好对应url和response，搞定。
4. 至于配置，一样，放到src/main/resources/application.properties，搞定。
5. 最夸张是我按照Spring Data REST的做法，按照JPA写了一个Entity类，对应到数据库的表，然后写了一个Repository接口，再在配置里加了数据库的参数。然后启动。我就可以通过URL以REST方式访问数据库里的数据了。总共不超100行，搞定。

于是我就没话说了，这就是framework啊。
