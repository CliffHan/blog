---
title: 如何将rust库封装为Android AAR
date: 2021-02-08 09:05:45
categories:
  - 开发
tags:
  - Android
  - AAR
  - JNI
  - Rust
---

前一段时间用Rust实现了一些功能，最近需要将这些实现搬到Android上来跑。这种问题，说简单也简单，就是用JNI（Java Native Interface）实现。但实际做起来，从来就没有那么简单。

# 工程相关问题

这里希望的是在Android App中使用Rust代码，因此Rust代码必须是library。虽然binary方式也可以运行，但Java只能通过exec调用binary，这种方式只能通过输入输出流来与binary交互，效率低且容易出错，没有太大意义。

## 工程组织方式

先考虑一下工程应该如何组织。基本上，JNI就是包括两部分：Java实现和对应的lib封装。在Android上，直接调用缺乏灵活性，因此考虑通过jar或aar方式来封装JNI库。这两种方式的区别是：

1. jar方式可以在普通Java工程（非Android工程）中使用，但通常JNI的Java实现和对应的lib封装是分开来打包的。如果要考虑将lib封装打进jar的话，虽然[不是不可行](https://stackoverflow.com/questions/26652014/load-so-file-from-a-jar)，但是非常麻烦。另外，在我的场景中，由于lib封装的编译必须使用ndk工具链，因此这样的封装也没有太大实际意义（如果lib是ndk编译的，在普通Java工程中也就无法使用了）。
2. aar方式是Android库的标准实现方式，lib封装可以作为资源打包进去；但这种方式是不能在普通Java工程中使用的。

考虑以上两种方式的区别，aar方式比较适用于我的使用场景。而jar场景比较适用于普通的Java项目，在jar场景下，lib和jar需要分别提交。这里不做深入讨论。

## Android AAR独立工程的创建

Android Developers官网上关于AAR工程的创建文档在[这里](https://developer.android.com/studio/projects/android-library?hl=zh-cn)。

需要理解的一点是，AAR工程和app工程都是Module。Android Studio创建app工程时，实际是创建了一个根工程，然后创建了一个app module。而AAR module必须在根工程中新增，不能直接创建。

因此，如果想要创建独立的AAR工程，需要先创建一个app工程，然后将`app`目录删掉，并修改对应的工程根目录下的`settings.gradle`。

## Rust库的整合

下一步是创建Rust库并整合进入工程。创建库当然是使用`cargo new --lib`命令。

由于Rust库是根工程的一部分，我将Rust库放在工程根目录下，跟aar module同级。

整合部分依赖于[Mozilla提供的plugin](https://github.com/mozilla/rust-android-gradle)，使用方法参考其README中的Usage，照做即可。

需要注意的一点是，如果需要在emulator上运行，那么可能需要对应的target。例如如果emulator上跑的是x86-64版本的img，那么target需要增加`x86-64`。另外，考虑到后面可能会使用单元测试，建议加上desktop的target，比如`linux-x86-64`。

## Rust库的实现

目前我们有了一个工程，工程里面包含一个AAR Module，和一个rust库。编译之后，rust库会被打包进入生成的aar文件。但目前还没有完成从java到rust的调用。这里需要参考[jni crate](https://docs.rs/jni)。

文档中主要就注意下面几点：

1. 实现Java类，需要在rust中实现的方法用`native`关键字修饰
2. 通过`javah`生成c语言header文件，获取其中的函数名定义
3. 参考jni crate文档实现rust库中的函数，使用第2步获得的函数名定义，`crate_type`需要是`cdylib`

为方便下一步进行测试，这里最好先简单实现一个可以调用的接口。

## 测试代码

在这里测试的目的，是为了使用简单的命令行，来确认工程整体是可以编译和运行的。

Android有两种测试方式，`UnitTest`和`InstrumentTest`。前者是单元测试，直接在Java虚拟机中运行，不需要Android环境，也不能使用Android API（如果有需求，需要Mock）。后者需要配合Android环境运行（需要虚拟机或实体设备），可以使用Android API。

如果Java部分代码对于Android依赖较多的话，只能使用`InstrumentTest`。但我这里只有简单使用`android.util.Log`。因此我选择`UnitTest`方式。需要以下几部分工作。

### Mock实现

在单元测试中，android.jar是空的，所以用到的Android功能都需要Mock。这里是一个简单的`android.util.Log`实现，放到aar module的`src/test/java/android/util/Log.java`。

```java
package android.util;

import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

public class Log {
    public static final String ANSI_RESET = "\u001B[0m";
    public static final String ANSI_BLACK = "\u001B[30m";
    public static final String ANSI_RED = "\u001B[31m";
    public static final String ANSI_GREEN = "\u001B[32m";
    public static final String ANSI_YELLOW = "\u001B[33m";
    public static final String ANSI_BLUE = "\u001B[34m";
    public static final String ANSI_PURPLE = "\u001B[35m";
    public static final String ANSI_CYAN = "\u001B[36m";
    public static final String ANSI_WHITE = "\u001B[37m";

    public static int d(String tag, String msg) {
        ZonedDateTime now = ZonedDateTime.now(ZoneOffset.UTC);
        System.out.println("[" + now.format(DateTimeFormatter.ISO_INSTANT) + " " + ANSI_BLUE + "DEBUG" + ANSI_RESET + " " + tag + "] " + msg);
        System.out.flush();
        return 0;
    }

    public static int i(String tag, String msg) {
        ZonedDateTime now = ZonedDateTime.now(ZoneOffset.UTC);
        System.out.println("[" + now.format(DateTimeFormatter.ISO_INSTANT) + " " + ANSI_BLUE + "INFO" + ANSI_RESET + " " + tag + "] " + msg);
        System.out.flush();
        return 0;
    }

    public static int w(String tag, String msg) {
        ZonedDateTime now = ZonedDateTime.now(ZoneOffset.UTC);
        System.out.println("[" + now.format(DateTimeFormatter.ISO_INSTANT) + " " + ANSI_BLUE + "WARN" + ANSI_RESET + " " + tag + "] " + msg);
        System.out.flush();
        return 0;
    }

    public static int e(String tag, String msg) {
        ZonedDateTime now = ZonedDateTime.now(ZoneOffset.UTC);
        System.out.println("[" + now.format(DateTimeFormatter.ISO_INSTANT) + " " + ANSI_BLUE + "ERROR" + ANSI_RESET + " " + tag + "] " + msg);
        System.out.flush();
        return 0;
    }
}
```

### 编译问题

在单元测试时，由于运行环境不是android，因此不能使用ndk编译。换句话说，在前面提到的Mozilla插件所涉及的修改中，需要在target中增加对应的desktop的target。我这里对应的是`linux-x86-64`。这样会在lib库目录下的target/debug生成so文件。

但是，现在有两个问题。第一是测试时不会自动编译rust库；第二是运行时java部分无法加载rust库。前者需要增加task之间的依赖关系，后者需要将编译出来的so所在目录添加到`LD_LIBRARY_PATH`。具体一点，参考下面对aar目录下的`build.gradle`的修改，增加了这些内容：

```kotlin
tasks.whenTaskAdded { task ->
    if ((task.name == 'javaPreCompileDebug' || task.name == 'javaPreCompileRelease')) {
        task.dependsOn 'cargoBuild'
    }
    if ((task.name == 'testDebugUnitTest' || task.name == 'testReleaseUnitTest')) {
        // For unit test, we need to add target path to LD_LIBRARY_PATH
        def libpath = '' + projectDir + '/../jni/target/debug/'
        environment 'LD_LIBRARY_PATH', libpath
    }
}
```

> 注意：其中的libpath需要根据具体情况修改

### 运行测试

现在，在aar目录下的`src/test`中的对应测试代码中加入测试，就可以使用`gradle testDebug`进行测试了。

### JavaDoc

由于这样暴露出来的库看起来是Java库的形式，因此要生成文档的话，可以使用javadoc，具体一点，在aar工程的`build.gradle`中，加几个task和配置，例如：

```groovy
// 由于增加的任务都需要classpath，因此加一个配置，将对应的dependency加入这个配置
configurations {
    javadocClasspath
}
dependencies {
    //……
	// 这个例子里，我加入了lombok和jackson的依赖
    javadocClasspath 'org.projectlombok:lombok:1.18.18'
    javadocClasspath group: 'com.fasterxml.jackson.core', name: 'jackson-databind', version: '2.12.1'
}

// delombok是将lombok部分展开成为新的源码
task delombok {
    def srcOriginal = 'src/main/java'
    def srcTarget = 'build/intermediates/src_delombok'
    def classpath = configurations.javadocClasspath + project.files(android.getBootClasspath().join(File.pathSeparator))

    inputs.files file( srcOriginal )
    outputs.dir file( srcTarget )

    doLast {
        println "Delombok source from ${srcOriginal} to ${srcTarget}"
        ant.taskdef(name: 'delombok', classname: 'lombok.delombok.ant.Tasks$Delombok', classpath: classpath.asPath)
        ant.delombok(verbose: false, from:srcOriginal, to:srcTarget, classpath: classpath.asPath)
    }
}

// 生成javadoc之前，要先做delombok，否则一些通过lombok生成的方法是不会被加入javadoc的
task javadoc(type: Javadoc, dependsOn: delombok) {
    failOnError false
    def srcDelomboked = 'build/intermediates/src_delombok'
    source = srcDelomboked
    // Default output dir is "build/docs/javadoc", change destinationDir if needed
    classpath = configurations.javadocClasspath + project.files(android.getBootClasspath().join(File.pathSeparator))
    doFirst {
        println "Generate javadoc from delomboked source at ${srcDelomboked}"
    }
}
```

加入上面配置后，通过`gradle javadoc`命令，就可以将html版本的javadoc文档输出到`build/docs/javadoc`目录。

### Log问题

关于测试时的Log问题，Java部分需要修改aar工程的`build.gradle`，允许应用输出，这里给出参考：

```kotlin
android {
      //...
      testOptions {
        unitTests.all {
            testLogging {
                events "passed", "skipped", "failed", "standardOut", "standardError"
                outputs.upToDateWhen {false}
                showStandardStreams = true
            }
        }
    }
}
```

> 注意：这里只是android配置中的一段，省略了其他部分

Rust库部分要配合log crate和其他log库实现。由于log只是facade，所以还是需要一个显式的初始化动作。我把初始化放在了一个initLogging函数中，交给Java部分的调用者来决定何时启用库中的log；当然，也可以考虑放在JNI_OnLoad函数中。代码例子如下：

```rust
#[cfg(target_os = "android")]
fn initLogging() {
    android_logger::init_once(Config::default().with_min_level(Level::Debug));
}

#[cfg(not(target_os = "android"))]
fn initLogging() {
    Builder::new().filter(None, LevelFilter::Debug).init();
}
```

基本的工程相关问题，这一部分就已经说完了。剩下的就是实现过程中的一些细节问题了。

# 实现细节问题

## Java -> Rust 的调用/传参/返回

Java部分的调用跟普通类没什么区别。这里仅仅建议做成singleton模式以简化模型。

从java传参到rust时，考虑尽量使用基本数据类型。复杂数据考虑采用json转换成String对象传递。如果是基础类型，那么在rust库中获得的类型是`jni::sys::jboolean`等基础类型，可以直接使用。如果是String类型，在rust中获得的是`jni::objects::JString`类型，需要通过`jni::JNIEnv`转换成rust中的`String`。参考下面的宏：

```rust
macro_rules! try_convert_java_string {
    ($var:ident, $env:ident) => {
        if let Ok(v) = $env.get_string($var) {
            Into::<String>::into(v)
        } else {
            debug!("Failed to convert \"{}\", return false", stringify!($var));
            return false as jboolean;
        }
    };
}
```

返回时情况类似，如果需要返回java String，需要用`env.new_string()`生成对象再返回。

## Rust -> Java 的调用/传参/返回

有时在rust库中，需要通过回调Java函数来获取一些信息。此时就需要按照以下步骤进行：

1. 在java实现中，定义用于回调的方法。这里无需考虑方法是public、protected还是private；但static和non-static稍有不同。
2. 在rust实现中，通过`env.call_method()`或`env.call_static_method`查询到目标方法并执行，获得返回对象。
3. 返回对象和Java->Rust调用时传入的参数是一样的处理方式。

## 多线程问题

在Java -> rust和rust -> Java部分，都存在需要注意的多线程问题。

当Java -> rust时，如果在java vm的子线程中调用，那么rust中拿到的env指针是一个不同的指针。因此不要试图去保存env指针。

当rust -> java时，由于回调必须拥有env指针，而rust中创建的子线程中是没有env指针的，所以必须按照如下顺序操作：

1. 在JNI_OnLoad函数中，保存获取的JavaVM指针
2. 在合适的时机，保存回调使用的Java对象
3. 在需要回调时，先获取保存的JavaVM指针和Java对象，然后：
   1. 通过`JavaVM::attach_current_thread()`系列函数（建议使用`attach_current_thread_as_daemon`，细节自查文档）获取env指针。
   2. 按照前面所说的`env.call_method()`方式回调

## Json String在Java和rust代码中的解析方式

都是一句话问题。

Java代码中用Jackson的ObjectMapper。

rust代码中用serde_json::Value。