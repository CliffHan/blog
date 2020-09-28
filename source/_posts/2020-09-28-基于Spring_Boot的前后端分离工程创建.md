---
title: 基于Spring Boot的前后端分离工程创建
date: 2020-09-28 09:53:36
categories:
  - 开发
tags:
  - Spring Boot
  - Java
  - 前端
  - 后端
---

过去以java为基础做web应用的时候，大家的习惯是用Spring搞定所有事情。前端部分并没有特别独立出来，一般都是用freemarker模板语言，做到Spring MVC里面。

现在，浏览器变得比以往更加强大；前端工程的独立开发，对界面的实现非常有帮助。因此在开发阶段，现代web应用通常会把前端独立出来做一个工程。这时spring的部分就会变成纯粹的后端。

不过，在实际部署的时候，前端输出的部分仍然需要跟后端整合在一起，最终成为一个jar或war文件来运行或部署。这样子，工程的管理就成为一个小小的问题。

理想状况下，我们希望**前端和后端能够分别开发**，但整合的时候也可以通过一个命令**简单的整合**在一起。这里介绍一种创建工程的方法。

## 问题分析

首先来看问题的本质，实际上，后端是个Spring Boot工程，前端是个web应用工程。这两部分天然就是分开的。那么问题关键就是这两部分如何在编译时整合的问题。

两部分整合时，前端输出的是一组静态资源（html/css/js），后端也只需要将其作为静态资源处理。因此对于前端来说，重要的是指定其输出路径到一个特定位置。而对于Spring Boot工程而言，默认会处理resource目录下的几个子目录，将其中的内容作为资源加入编译档。可以参考[这篇文章](https://spring.io/blog/2013/12/19/serving-static-web-content-with-spring-boot)。这里我打算采用`src/main/resources/static/`作为前端的输出路径。

另外一个问题是两个工程的相对位置。前端和后端可以作为平级的两个子工程；也可以将前端作为后端的子工程。这要看整体工程的复杂度和设计。这里因为只有一个前端和一个后端，我把前端作为后端的子工程，也就是前端工程放到后端的子目录中。

## 准备工作

创建工程需要以下一系列工具：

* [sdkman](https://sdkman.io/install)，用来安装其他部分工具
* [Spring Boot CLI](https://docs.spring.io/spring-boot/docs/current/reference/html/spring-boot-cli.html)，用来初始化Spring Boot工程
* 编译工具，这里用[Gradle](https://gradle.org/install/)，也可以用[Maven](https://maven.apache.org/install.html)
* 前端框架CLI用以创建前端工程，这里用[Vue CLI](https://cli.vuejs.org/guide/installation.html)，也可换成[create-react-app](https://zh-hans.reactjs.org/docs/create-a-new-react-app.html)或者[Angular CLI](https://cli.angular.io/)，使用方法类似
* 前端编译工具，这里用[Yarn](https://yarnpkg.com/getting-started/install)，也可以用npm
* 源码管理，这里用[git](https://git-scm.com/)

## 创建工程

执行下列脚本，将创建名为app-name的完整应用：

```shell
## 创建SpringBoot应用
spring init -a app-name --build gradle -d lombok,web --description "demo description" -g com.cliff.app -j 1.8 -n app-name app-name
## 将已有工程加入git
cd app-name
git init .
git commit -m "springboot initial commit"
## 创建webapp子目录
vue create -d -m yarn -n webapp
## 将webapp工程加入git
git add webapp
git commit -m "webapp initial commit"
```

> 在执行`spring init`和`vue create`命令时，可以修改参数来调整工程的配置。除应用名外，spring的依赖也是常常需要调整的部分，可以参考`spring init --list`的输出。

## 整合工程

现在工程创建完成，但前后端还没有完成整合，需要做以下一些修改。

### 后端工程配置

这部分需要修改的文件都在工程根目录下，包括以下文件：

#### .gitignore

需要加入`src/main/resources/static/`。避免前端生成的文件被提交到git。

#### build.gradle

需要添加下面一段代码：

```groovy
// Enable skip yarn_build via command line when frontend code not changed
if (!project.hasProperty('skip.yarn_build')) {
	processResources.dependsOn ':webapp:yarn_build'
}
else {
	println 'skip.yarn_build set, will NOT build webapp'
}
```

这段代码涉及编译依赖问题。默认情况下，没有定义`skip.yarn_build`时，编译前端工程；有定义时，可以跳过前端工程的编译，节约时间。

#### settings.gradle

需要添加`include 'webapp'`，将webapp目录加入root工程。



### 前端工程配置

这部分需要修改的文件都在webapp目录下，包括以下文件：

#### build.gradle

此文件为新建，其目的是允许gradle可以使用yarn编译前端工程。内容如下：

```groovy
// FILE：webapp/build.gradle
// Use com.moowork.node for build tasks
plugins {
	id 'com.moowork.node' version '1.3.1'
}
// Should execute "yarn install" before "yarn build"
yarn_build.dependsOn(yarn_install)
```

#### vue.config.js

此文件为新建，其目的有以下两点：

* 使得vue工程编译时，直接输出到`src/main/resources/static/`
* 前端和后端分离调试时，使得webpack-dev-server将API请求转发到后端，参考[这里](https://cli.vuejs.org/zh/config/#devserver-proxy)

```javascript
// FILE：webapp/vue.config.js
const path = require("path")

module.exports = {
    outputDir: path.resolve(__dirname, "../src/main/resources/static"),
    devServer: {
        proxy: 'http://localhost:8080'
    }
}
```

> 注1：输出路径是以webapp目录为基础的相对路径
>
> 注2：后端工程默认端口为8080



以上工作完成后，需要将修改commit到git。



## 工程使用方式

目前工程基础已经完成，在这个工程下，可以执行如下操作：

### 整合

```shell
# 生成可运行的jar
gradle bootJar
```

此命令会生成可运行的jar，放在`build/libs/`，可以直接使用`java -jar`命令运行。



### 前后端独立运行

```shell
# 后端
gradle bootRun -Pskip.yarn_build
# 前端
cd webapp && yarn serve
```

几个注意事项：

* 后端独立运行时，会跳过前端的编译以节省时间。
* 后端默认运行于8080端口，如果先运行前端，会造成端口冲突。
* 启动后端后再启动前端时，前端使用8081端口。

