---
title: Developing on WSL
date: 2019-11-06 20:14:40
categories:
  - 开发
tags:
  - WSL
---

WSL就是Windows Subsystem for Linux，也就是Windows下的Linux子环境。

至于为什么要用WSL开发？实在是因为Windows环境太奇葩了。比如我有时候做前端，vue或ng的cli下作serve。在Linux下毫无问题，Windows下经常出现文件改动后，服务crash的情况。

WSL的安装很简单，在“启用与关闭Windows功能”中打开“适用于Linux的Windows子系统”。然后在商店里安装Ubuntu即可。注意这里的Ubuntu只有一个Bash可用。通过Bash已经可以用apt安装Ubuntu应用。

虽然开发不是必须要用IDE，不过有IDE还是会方便些。在Windows上装好微软自己的vscode，然后在Bash下执行code命令，就可以在Windows环境下打开vscode，并编辑WSL中的文件。这里注意，vscode对应WSL环境的插件要重新装一遍。

回到开始的例子，如果做前端应用，开一个Bash做serve，然后在vscode中修改文件，浏览器里能立刻看到效果，总算不会crash了。

如果要直接访问WSL中的文件，可以打开%LOCALAPPDATA%\Packages\ CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc \LocalState\rootfs\home\，明显这就是home目录。需要注意两点，一是拷贝到home目录的文件，可能需要chmod来修改文件权限；二是通过Windows修改的文件名，在Linux下可能没有及时改变。