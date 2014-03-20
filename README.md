lcxl-iocp-for-delphi
====================

IOCP控件for Delphi版，集成了自己的一些通信小协议和其他协议（HTTP）

使用中需要注意的一些情况：

Socket对象引用计数和自动释放
-----------------------------------
LCXL IOCP中所使用的Socket对象的释放是基于引用计数的，当引用计数为0时此Socket对象会被自动释放。Socket类维护了两个引用计数，一个是系统引用计数，一个是用户引用计数。当两个引用计数都为0时，此Socket对象所在的IOCPList将触发ieDelSocket事件，然后此Socket对象将被自动释放。

### 系统引用计
系统引用计数的算法为：（1+发送数据队列长度）：每次发送数据时系统引用计数+1，当发送完毕时系统引用计数-1，当连接被关闭时，系统引用计数-1。系统引用计数由LCXL IOCP所维护。用户无法直接对系统引用计数进行修改。
当系统引用计数为0时，会触发ieCloseSocket事件，说明此socket已经无效，此时应该尽快将用户引用计数释放掉。

### 用户引用计数
用户引用计数为用户自己所维护的引用计数，增加此引用计数的目的是为了防止Socket对象在用户一系列操作期间不会因为链接被关闭等原因而被自动释放。例如使用Socket类中的ConnectSer函数建立连接时，参数IncRefNumber即为用户要增加的用户引用计数，如果你在ConnectSer之后不做任何事情，则可以设置为0，但如果在ConnectSer之后想要SendData之类的，需要将IncRefNumber置为1，然后SendData之后，使用DecRefCount函数来释放用户引用计数。

### 什么时候不会被自动释放
* IOCPList的OnIOCPEvent事件中的参数SockObj在事件执行期间不会被自动释放；
* 当执行了IOCPList.LockSockList函数之后一直到UnLockSockList之前，这个IOCPList所维护的每个Socket对象都将不会被自动释放；
* 当新的Socket对象执行了ConnectSer函数并且IncRefNumber大于0的情况时，此Socket不会被自动释放；
* 当“有效”的Socket对象从IncRefNumber函数执行之后，一直到DecRefCount函数执行之前，此Socket不会被自动释放；
    
