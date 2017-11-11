---
title: Firefox OS 多媒体调试备忘录(AMR)
date: 2014-04-02 17:16:42
categories:
  - 开发
tags:
  - Firefox OS
  - Gecko
---
问题起源于一个Bug，为什么Firefox OS的音乐播放器可以播放amr，而Firefox OS浏览器里面打开amr文件链接却无法播放呢？

抓了一堆Log，正常的Log应该是这样的：

{% codeblock %}
I/nsURILoader( 1270): DispatchContent
I/nsURILoader( 1270): forceExternalHandling: no
I/nsURILoader( 1270): TryContentListener mContentType=video/3gpp
I/nsURILoader( 1270): call aListener->IsPreferred
I/nsWebNavigationInfo( 1270): IsTypeSupported, aType=video/3gpp
I/nsWebNavigationInfo( 1270): IsTypeSupportedInternal, aType=video/3gpp
I/nsWebNavigationInfo( 1270): nsContentUtils::TYPE_CONTENT
I/nsWebNavigationInfo( 1270): nsIWebNavigationInfo::OTHER
I/nsURILoader( 1270): got typeToUse=(null)
I/nsContentDLF( 1270): CreateInstance, aCommand=view, aContentType=video/3gpp
I/DecoderTraits( 1270): ShouldHandleMediaType, aMIMEType=video/3gpp
I/DecoderTraits( 1270): CanHandleMediaType, aMIMEType=video/3gpp
D/MediaExtractor( 1270): MediaExtractor::Create, mime=(null)
I/nsURILoader( 1270): First step: Success! Our default listener likes this type
{% endcodeblock %}

不正常的amr流程是这样的。

{% codeblock %}
I/nsURILoader( 1270): DispatchContent
I/nsURILoader( 1270): forceExternalHandling: no
I/nsURILoader( 1270): TryContentListener mContentType=audio/amr
I/nsURILoader( 1270): call aListener->IsPreferred
I/nsWebNavigationInfo( 1270): IsTypeSupported, aType=audio/amr
I/nsWebNavigationInfo( 1270): IsTypeSupportedInternal, aType=audio/amr
I/nsWebNavigationInfo( 1270): nsContentUtils::TYPE_UNSUPPORTED
I/nsWebNavigationInfo( 1270): IsTypeSupportedInternal, aType=audio/amr
I/nsWebNavigationInfo( 1270): nsContentUtils::TYPE_UNSUPPORTED
I/nsURILoader( 1270): got typeToUse=(null)
I/nsURILoader( 1270): !listenerWantsContent, Listener is not interested
I/nsURILoader( 1270): Second step
I/nsURILoader( 1270): Third step
I/nsURILoader( 1270): Fourth step
I/nsURILoader( 1270): Fifth step
I/nsURILoader( 1270): Sixth step
I/nsURILoader( 1270):?? Passing load off to helper app service
I/nsExternalHelperAppService( 1270): DoContent, aMimeContentType=audio/amr
I/nsExternalHelperAppService( 1270): XRE_GetProcessType() == GeckoProcessType_Content
I/nsExternalHelperAppService( 301): DoContent, aMimeContentType=audio/amr
I/nsExternalHelperAppService( 301): if (channel)
I/nsExternalHelperAppService( 301): GetFilenameAndExtensionFromChannel: Found extension 'amr' (filename is 'San.amr', handling attachment: 0)
I/nsExternalHelperAppService( 301): amr
I/nsExternalHelperAppService( 301): GetFromTypeAndExtension, aMIMEType=audio/amr, aFileExt=amr
I/nsExternalHelperAppService( 301): FillMIMEInfoForMimeTypeFromExtras, aContentType=audio/amr
I/nsExternalHelperAppService( 301): mMimeType=audio/amr, mFileExtensions=amr, mDescription=Adaptive Multi-Rate Audio
{% endcodeblock %}


废话不多说，直接写结论。

1. 整个流程是这样的：
  nsURILoader::DispatchContent()
  nsURILoader::TryContentListener()
  nsDSURIContentListener::IsPreferred()
  nsDSURIContentListener::CanHandleContent()
  nsWebNavigationInfo::IsTypeSupported()
  nsWebNavigationInfo::IsTypeSupportedInternal()
  nsContentUtils::FindInternalContentViewer()
  DecoderTraits::IsSupportedInVideoDocument()
  ……
  DecoderTraits::InstantiateDecoder()
2. 从流程可以看出，这部分是浏览器/gecko从后缀获得文件mime type，并试图确定是否可以解析文件。正常的情况下，比如3gpp，立刻得到了返回；而amr没有得到返回。
3. 代码里可以看到，DecoderTraits中的两个函数，都以硬编码方式去掉了audio/amr的支持。去掉这两部分实验了一下，amr就正常了。Mozilla的说法是因为版权问题才限制amr的。
