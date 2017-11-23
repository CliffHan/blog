---
title: libxml2的XPath解析
date: 2017-11-23 22:13:23
categories:
  - 开发
tags:
  - libxml2
  - XPath
---
libxml2里面，xml的解析有dom方式，还有就是xpath方式。前者是对整个tree的遍历，后者是直接定点查找。对于我自己来说，后者使用比较频繁。其实libxml2官网上例子写的已经很清晰，但注释太少，每次进入状态花的时间有点长。所以这个笔记只是写了一些注释，方便自己需要时能快速进入状态而已。
{% codeblock lang:cpp %}
//include的部分，可能引用多了
#include <libxml/parser.h>
#include <libxml/tree.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>

xmlDocPtr doc = NULL; //doc指针，需要释放
xmlXPathContextPtr xpathCtx = NULL; //xpath context指针，需要释放
xmlXPathObjectPtr xpathObj = NULL;  //xpath object指针，需要释放
xmlNodeSetPtr xpathNodes = NULL;  //xpath nodes指针，指向xpath object中的变量，不需要释放

//解析xml字符串，也可用xmlParseFile解析文件，得到doc指针
doc = xmlParseMemory(xml.c_str(), xml.length());  
if (doc == NULL) {
   LOG("Error: unable to parse xml");
   goto end;
}

//从doc指针得到xpath context指针
xpathCtx = xmlXPathNewContext(doc);
  if(xpathCtx == NULL) {
    LOG("Error: unable to create new XPath context");
    goto end;
}

//从xpath context指针中获得xpath object，第一个参数就是xpath字符串，用BAD_CAST宏进行转换
xpathObj = xmlXPathEvalExpression(BAD_CAST("//root/example"), xpathCtx);
if(xpathObj == NULL) {
  LOG("Error: unable to evaluate xpath");
  goto end;
}

xpathNodes = xpathObj->nodesetval; //从xpath object中得到node set
if ((xpathNodes) && (xpathNodes->nodeNr > 0)) { //node set是节点集合，可能为空，也可能有多个
  for (int i = 0; i < xpathNodes->nodeNr, i++) {
    //xpathNodes->nodeTab[i]就是单个节点
    //从xmlNode类型的节点struct中直接获取content为空，需要用xmlNodeGetContent
    //其他函数就可以参考libxml2中定义
    LOG("node[%d]=%s", i, (char*)xmlNodeGetContent(xpathNodes->nodeTab[i]));
  }
}

end:
//释放所有变量
if (xpathObj) { xmlXPathFreeObject(xpathObj); }
if (xpathCtx) { xmlXPathFreeContext(xpathCtx); }
if (doc) { xmlFreeDoc(doc); }
{% endcodeblock %}
