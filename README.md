# lcxl-iocp-for-delphi

IOCP控件for Delphi版，集成了自己的一些通信小协议（主要是处理粘包问题和发送简单命令的协议）和其他协议（HTTP）且支持IPv6的连接（用来支持IPv6监听模式）；

本控件在Delphi XE5下运行正常，正常情况下D2009及以上版本的delphi都能支持本控件；

自带测试工程，在test目录下；

一些原理和功能的介绍参见Wiki:<https://github.com/LCXL/lcxl-iocp-for-delphi/wiki/_pages>；

> **注意**：此控件使用了Windows特有的功能（IOCP），因此不支持跨平台，不支持移动应用；因为工作原因，代码更新缓慢，欢迎对本代码进行完善。
