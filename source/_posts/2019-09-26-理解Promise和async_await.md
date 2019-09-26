---
title: 理解Promise和async/await
date: 2019-09-26 15:26:48
categories:
  - 开发
tags:
  - Javascript
  - Promise
  - async
  - await
---

随便写点side project的时候，遇到了一个问题。才发现原来我没真正理解Promise。

问题很简单，用nodejs做dns解析的时候，通常是callback模式，如下：

```javascript
var dns = require('dns');
var options = {all: true};
dns.lookup('httpbin.org', options, function(err, address){
    if(err) throw err;
    console.log('httpbin.org: ' + JSON.stringify(address));
});
```

那么，如何将这个模式的代码，改写成Promise方式，甚至更漂亮的async/await方式呢？

可能是用的太少的缘故，之前我理解Promise就是Promise，但让我改写callback模式的时候，就发现这个理解方式不够深刻。实际上Promise的本质很简单，就是延迟返回。先写一个函数，代码是这样的：
```javascript
// 注意：lookup函数返回的只是一个Promise，且这个函数是立即返回的
function lookup(domain) {
    return new Promise((resolve, reject) => {
        dns.lookup(domain, options, (err, address, family) => {
            // 这里是回调函数，此时，函数持有resolve/reject和lookup的结果
            // 所以这里的本质即是用resolve/reject将lookup结果通知Promise持有者
            if(err)
                throw reject(err);
            resolve(address);
        });
    });
}
```

从这个函数就可以看出来，其实Promise的本质，就是使用了闭包，在原来的回调函数中，调用新生成的resolve/reject函数。从而**在回调函数指定的时间点，将回调函数的参数（即原始函数的结果），通知给了Promise的持有者**。

在这种情况下，async/await就很好理解了。async用来指定这个函数是异步执行的，await用来**在异步函数中**，**等待一个Promise完成**。下面是一个完整的例子：

```javascript
var dns = require('dns');
var options = {all: true};
// lookup函数本身不是异步的，只是立即返回一个Promise，在Promise内部给出通知
function lookup(domain){
    return new Promise((resolve, reject) => {
        dns.lookup(domain, options, (err, address, family) => {
            if(err) throw reject(err);
            resolve(address);
        });
    });
};
// 注意：这里的main函数是异步的，即是说，main函数之后的代码未必在main函数之后执行
async function main() {
    // 只有在异步函数中才能await，这里await的lookup函数实际有两种返回：
    // 即resolve的结果，或是exception，后者会被catch捕获
    // resolve只有一个参数，结果如果是多个的话，可以用类似模式匹配的方法获取
    // 如: let [a, b, c] = await Promise.resolve(['a', 'b', 'c']);
    const address = await lookup('httpbin.org');
    // 因为await的原因，下面的执行就在lookup函数之后了
    console.log(JSON.stringify(address));
    console.log('execution complete');
}
// 主代码段仅仅执行异步的main函数，以减轻复杂度
try {
    main();
} 
catch(err){
    console.error(err);
}  
```

回到原始问题，callback模式的函数改造成async/await模式的要点很简单：

1. 需要构建一个Promise，在Promise中执行原callback模式的函数，在其callback实现中，调用resolve/reject返回结果
2. 需要构建一个async函数，在其中用await Promise.resolve等待结果
3. 在await之后再执行，即会等待前一个结果完成，也就是异步变同步
4. 注意async函数本身仍然是异步的，其后的代码不会等待async函数完成再执行