---
title: ActionbarSherlock与ViewPageIndicator组合使用
date: 2014-02-14 10:14:13
categories:
  - 开发
tags:
  - 移动应用
  - Android
---
这俩工具都是为了在旧版android上支持类似4.0的界面。这文章也是以前做小游戏时候写的，现在基本用不到了。权作纪念。关于这篇文章一个完整的示例在~~Google Code~~ Github上，是自己写的一个小游戏，参考地址：[北京浮生记](https://github.com/CliffHan/beijing-fushengji)。

**ActionbarSherlock：**在android低版本(2.2/2.3)设备上增加4.0的Actionbar
**ViewpageIndicator：**在android低版本(2.2/2.3)设备上增加4.0的Viewpager

**使用流程如下**

**ActionbarSherlock单独使用**
1. 作为library方式添加进eclipse工程，或以自动生成的project.properties形式加入ant脚本
2. 修改AndroidManifest.xml，包括：
  修改uses-sdk，android:minSdkVersion="8"，android:targetSdkVersion="15"
  修改Application，将android.theme修改为Theme.Sherlock或其派生theme
3. Activity派生自SherlockActivity
4. Activity中派生onCreateOptionsMenu和onOptionsItemSelected

**ViewpageIndicator单独使用**

1. 作为library方式添加进eclipse工程，或以自动生成的project.properties形式加入ant脚本
2. 修改AndroidManifest.xml
3. Activity派生自FragmentActivity，需要android-support的jar包里提供的版本
4. Activity对应的layout的xml中增加Pager和Indicator
5. onCreate中实现Fragment创建Pager和Indicator绑定

**混合使用**，除去两者相同的部分和各自必须实现的部分，还有：

1. 注意Viewpageindicator对应的Activity必须派生自SherlockFragmentActivity
2. 注意AndroidManifest.xml中的android:theme必须派生自Theme.Sherlock及其派生theme，因此需要在style.xml中自定义theme，加入ViewpageIndicator中的theme
