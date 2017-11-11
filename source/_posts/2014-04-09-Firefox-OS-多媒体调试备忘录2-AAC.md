---
title: Firefox OS 多媒体调试备忘录2(AAC)
date: 2014-04-09 16:03:54
categories:
  - 开发
tags:
  - Firefox OS
  - Gecko
---
还是从Bug开始，为什么AAC这种格式Mozilla号称支持，却扫不出来？先说改法：

1. gaia/apps/music/manifest.webapp，需要加入audio/aac格式。
2. gecko/toolkit/content/devicestorage.properties，需要加入*.aac。
3. gecko/netwerk/mime/nsMimeTypes.h，需要加入AUDIO_AAC定义。
4. gecko/uriloader/exthandler/nsExternalHelperAppService.cpp，在defaultMimeEntries和extraMimeEntries数组中，需要加上AUDIO_AAC的对应项目。
5. gecko/toolkit/components/mediasniffer/nsMediaSniffer.cpp，在nsMediaSniffer::GetMIMETypeFromContent函数中，需要加上AUDIO_AAC的特征判断。简单说一下，AAC有两种，ADIF和ADTS，前者特征是文件开头有ADIF的4个ASCII字符；后者有7个byte的头信息，以12bit的1开头，也就是0xFFF。至于具体的信息，需要去看ISO/IEC 13818-7。
6. gecko/content/media/DecoderTraits.cpp，需要修改gOmxTypes数组，增加audio/aac。

Mozilla对于多媒体类型处理的做法是基本一致的，不管是图片/音频还是视频，下面是调试过程中的一些副产品，或者说看到的相同点：

1. gaia/apps下的具体应用（music/gallery/video）调用gaia/shared/js/mediadb.js，通过回调函数扫描文件并加入mediadb对象。
2. mediadb会通过回调调用各个应用的一些函数，比如music会回调gaia/apps/music/js/metadata_scripts.js来处理metadata，如果metadata找不到的话，就通过gecko下的HTMLMediaElement::CanPlayType调用到DecoderTraits::CanHandleMediaType函数，去猜测这个文件是否能播放。我在这里卡了一阵子。
3. 无论是图片还是音频，在gecko中都有代码去试图根据文件内容确定文件的MIME格式，估计是为了安全性。音乐的话就是上面提到的nsMediaSniffer，图片的话之前WBMP部分提过。
4. 无论是图片还是音频，都会找到实际的解码器，才算是真正承认这个文件可播放。

最后，Mozilla之前加入AMR codec和WMV/AVI的例子在这里：
[https://bugzilla.mozilla.org/show_bug.cgi?id=847809](https://bugzilla.mozilla.org/show_bug.cgi?id=847809)
[https://bugzilla.mozilla.org/show_bug.cgi?id=992756](https://bugzilla.mozilla.org/show_bug.cgi?id=847809)
