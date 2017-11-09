---
title: SpringBoot应用开发
date: 2016-08-09 13:33:54
categories:
  - 开发
tags:
  - 互联网
  - 服务器部署
  - WEB应用
  - Spring
  - WEB应用
---
需要写一个基于SpringBoot的Web应用作为后续项目基础，这里记录一下。

应用目标：一个Web应用，使用H2做数据库（后续可以方便的替换），flywaydb做数据库版本管理，Spring Security做登录认证和授权。

准备工作：需要maven/h2/gradle等，下载安装完成后要加到path中，方便调用。

初始化项目，要点：

1. 初始化项目办法很多，如使用Spring Boot Cli（用spring init命令）， start.spring.io，或者IDE的SpringBoot工具等。
2. 如果是maven工程，可以暂时把pom.xml中不需要的依赖去掉，避免编译时下载时间太长，maven运行目标是mvn spring-boot:run。这个项目用maven，不用gradle。

flywaydb整合，参考[这个工程](https://github.com/spring-projects/spring-boot/tree/master/spring-boot-samples/spring-boot-sample-flyway)，要点：

1. pom.xml中需要加入flyway-core的dependency
2. resources/db/migration目录下放置类似V1__init.sql命名方式的sql，参考[这里](https://flywaydb.org/getstarted/how)
3. 实现JPA entity和Repository，这个可选，需要时再实现也可以
4. application.properties设置，可加可不加
5. 例子中的Application中的CommandLineRunner部分，测试用，可加可不加

h2整合，默认情况下只需要在pom里面加上h2依赖即可使用h2做mem数据库，当application.properties中spring.h2.console.enabled=true时，可以通过/h2-console访问url为jdbc:h2:mem:testdb的数据源，连接内存数据库。

Spring Security整合，参考[这里](http://docs.spring.io/spring-security/site/docs/current/guides/html5/helloworld-boot.html)，要点：

1. 在pom.xml里加入security依赖
2. 规划Web应用路径，将需要保护的页面放到特定目录
3. 参考例子中的SecurityConfig设计
4. 由于默认开启CSRF，导致GET请求的logout不可用，参考[这里](http://docs.spring.io/spring-security/site/docs/4.0.1.RELEASE/reference/htmlsingle/#csrf-logout)
5. 用户表和权限表参考Spring官方文档的[Appendix](http://docs.spring.io/spring-security/site/docs/current/reference/htmlsingle/#user-schema)，其中权限表要映射，需加id主键
6. Entity的映射参考[这里](https://docs.jboss.org/hibernate/stable/annotations/reference/en/html/entity.html)

完成的例子参考[这里](https://github.com/CliffHan/webbase)，接下来HTML5前端的部分就不属于这篇文章了。
