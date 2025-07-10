///|
pub(all) struct ITcpListener {
  inner : JSTcpListener
}

///|
pub(all) struct ITcpStream {
  inner : JSTcpStream
}

///|
pub(all) enum Shutdown {
  Read // SHUT_RD
  Write // SHUT_WR
  Both // SHUT_RDWR
} derive(Show)

///|
#external
type JSTcpListener

///|
#external
type JSTcpStream

///|
extern "js" fn create_tcp_listener_ffi(
  host : String,
  port : Int,
  is_server : Bool,
) -> JSTcpListener =
  #| function(host, port, is_server) {
  #|     const deasync = require('deasync');
  #|     const net = require('net');
  #|     const { EventEmitter } = require('events');
  #| 
  #|     function makeSync(fn) {
  #|         return deasync(function (...args) {
  #|             // deasync needed callback is the last parameter, we pop it from args
  #|             const callback = args.pop();
  #|             // Invoke the async function with the remaining arguments
  #|             fn(...args)
  #|                 .then(result => callback(null, result)) 
  #|                 .catch(error => callback(error, null));
  #|         });
  #|     }
  #| 
  #|     class JSTcpStream extends EventEmitter {
  #|         constructor(socket) {
  #|             super();
  #|             this.socket = socket;
  #|             this.closed = false;
  #| 
  #|             // 绑定事件
  #|             this.socket.on('data', (data) => {
  #|                 this.emit('data', data);
  #|             });
  #| 
  #|             this.socket.on('error', (err) => {
  #|                 this.emit('error', err);
  #|             });
  #| 
  #|             this.socket.on('close', () => {
  #|                 this.closed = true;
  #|                 this.emit('close');
  #|             });
  #| 
  #|             this.socket.on('end', () => {
  #|                 this.emit('end');
  #|             });
  #|         }
  #| 
  #|         // 静态方法：连接到指定地址
  #|         static connect(address, port) {
  #|             return new Promise((resolve, reject) => {
  #|                 const socket = new net.Socket();
  #| 
  #|                 socket.connect(port, address, () => {
  #|                     resolve(new JSTcpStream(socket));
  #|                 });
  #| 
  #|                 socket.on('error', reject);
  #|             });
  #|         }
  #| 
  #|         // 异步读取数据
  #|         async read(size) {
  #|             if (this.closed) {
  #|                 throw new Error('Stream is closed');
  #|             }
  #|             return new Promise((resolve, reject) => {
  #|                 const onData = (data) => {
  #|                     this.socket.removeListener('data', onData);
  #|                     this.socket.removeListener('error', onError);
  #|                     this.socket.removeListener('close', onClose);
  #| 
  #|                     if (size && data.length > size) {
  #|                         // 如果数据超过请求大小，将剩余数据推回
  #|                         this.socket.unshift(data.slice(size));
  #|                         resolve(data.slice(0, size));
  #|                     } else {
  #|                         resolve(data);
  #|                     }
  #|                 };
  #| 
  #|                 const onError = (err) => {
  #|                     this.socket.removeListener('data', onData);
  #|                     this.socket.removeListener('error', onError);
  #|                     this.socket.removeListener('close', onClose);
  #|                     reject(err);
  #|                 };
  #| 
  #|                 const onClose = () => {
  #|                     this.socket.removeListener('data', onData);
  #|                     this.socket.removeListener('error', onError);
  #|                     this.socket.removeListener('close', onClose);
  #|                     resolve(null); // 连接关闭
  #|                 };
  #| 
  #|                 this.socket.on('data', onData);
  #|                 this.socket.on('error', onError);
  #|                 this.socket.on('close', onClose);
  #|             });
  #|         }
  #| 
  #|         // 同步读取（使用 readline 或 buffer）
  #|         readSync(size) {
  #|             if (this.closed) {
  #|                 throw new Error('Stream is closed');
  #|             }
  #| 
  #|             const data = this.socket.read(size);
  #|             return data;
  #|         }
  #| 
  #|         // 写入数据
  #|         write(data) {
  #|             if (this.closed) {
  #|                 throw new Error('Stream is closed');
  #|             }
  #| 
  #|             return new Promise((resolve, reject) => {
  #|                 this.socket.write(data, (err) => {
  #|                     if (err) {
  #|                         reject(err);
  #|                     } else {
  #|                         resolve();
  #|                     }
  #|                 });
  #|             });
  #|         }
  #| 
  #|         // 同步写入
  #|         writeSync(data) {
  #|             if (this.closed) {
  #|                 throw new Error('Stream is closed');
  #|             }
  #| 
  #|             return this.socket.write(data);
  #|         }
  #| 
  #|         // 刷新缓冲区
  #|         flush() {
  #|             return new Promise((resolve) => {
  #|                 this.socket.end(() => {
  #|                     resolve();
  #|                 });
  #|             });
  #|         }
  #| 
  #|         // 关闭连接
  #|         close() {
  #|             if (!this.closed) {
  #|                 this.socket.end();
  #|                 this.closed = true;
  #|             }
  #|         }
  #| 
  #|         // 获取本地地址
  #|         localAddr() {
  #|             return {
  #|                 address: this.socket.localAddress,
  #|                 port: this.socket.localPort
  #|             };
  #|         }
  #| 
  #|         // 获取远程地址
  #|         peerAddr() {
  #|             return {
  #|                 address: this.socket.remoteAddress,
  #|                 port: this.socket.remotePort
  #|             };
  #|         }
  #| 
  #|         // 设置超时
  #|         setTimeout(timeout, callback) {
  #|             this.socket.setTimeout(timeout, callback);
  #|         }
  #| 
  #|         // 设置保持连接
  #|         setKeepAlive(enable, initialDelay) {
  #|             this.socket.setKeepAlive(enable, initialDelay);
  #|         }
  #| 
  #|         // 禁用 Nagle 算法
  #|         setNoDelay(noDelay = true) {
  #|             this.socket.setNoDelay(noDelay);
  #|         }
  #|     }
  #|     class JSTcpListener extends EventEmitter {
  #|         constructor(server) {
  #|             super();
  #|             this.server = server;
  #|             this.listening = false;
  #| 
  #|             // 绑定事件
  #|             this.server.on('connection', (socket) => {
  #|                 const stream = new JSTcpStream(socket);
  #|                 this.emit('connection', stream);
  #|             });
  #| 
  #|             this.server.on('error', (err) => {
  #|                 this.emit('error', err);
  #|             });
  #| 
  #|             this.server.on('close', () => {
  #|                 this.listening = false;
  #|                 this.emit('close');
  #|             });
  #| 
  #|             this.server.on('listening', () => {
  #|                 this.listening = true;
  #|                 this.emit('listening');
  #|             });
  #|         }
  #| 
  #|         // 静态方法：绑定到指定地址
  #|         static bind(address, port) {
  #|             return new Promise((resolve, reject) => {
  #|                 const server = net.createServer();
  #|                 const listener = new JSTcpListener(server);
  #| 
  #|                 server.listen(port, address, () => {
  #|                     resolve(listener);
  #|                 });
  #| 
  #|                 server.on('error', reject);
  #|             });
  #|         }
  #| 
  #|         // 异步接受连接
  #|         async accept() {
  #|             if (!this.listening) {
  #|                 throw new Error('Listener is not listening');
  #|             }
  #| 
  #|             return new Promise((resolve, reject) => {
  #|                 const onConnection = (stream) => {
  #|                     this.removeListener('connection', onConnection);
  #|                     this.removeListener('error', onError);
  #|                     this.removeListener('close', onClose);
  #|                     resolve(stream);
  #|                 };
  #| 
  #|                 const onError = (err) => {
  #|                     this.removeListener('connection', onConnection);
  #|                     this.removeListener('error', onError);
  #|                     this.removeListener('close', onClose);
  #|                     reject(err);
  #|                 };
  #| 
  #|                 const onClose = () => {
  #|                     this.removeListener('connection', onConnection);
  #|                     this.removeListener('error', onError);
  #|                     this.removeListener('close', onClose);
  #|                     reject(new Error('Listener closed'));
  #|                 };
  #| 
  #|                 this.on('connection', onConnection);
  #|                 this.on('error', onError);
  #|                 this.on('close', onClose);
  #|             });
  #|         }
  #| 
  #|         // 获取本地地址
  #|         localAddr() {
  #|             const addr = this.server.address();
  #|             return {
  #|                 address: addr.address,
  #|                 port: addr.port
  #|             };
  #|         }
  #| 
  #|         // 关闭监听器
  #|         close() {
  #|             return new Promise((resolve) => {
  #|                 this.server.close(() => {
  #|                     resolve();
  #|                 });
  #|             });
  #|         }
  #| 
  #|         // 设置最大连接数
  #|         setMaxConnections(max) {
  #|             this.server.maxConnections = max;
  #|         }
  #| 
  #|         // 获取当前连接数
  #|         getConnections() {
  #|             return new Promise((resolve, reject) => {
  #|                 this.server.getConnections((err, count) => {
  #|                     if (err) {
  #|                         reject(err);
  #|                     } else {
  #|                         resolve(count);
  #|                     }
  #|                 });
  #|             });
  #|         }
  #|     }
  #| 
  #|     if (is_server) {
  #|         sync_listener = makeSync(JSTcpListener.bind);
  #|         return sync_listener(host, port);
  #|     } else {
  #|         sync_stream = makeSync(JSTcpStream.connect);
  #|         return sync_stream(host, port);
  #|     }
  #| }

///|
extern "js" fn create_tcp_stream_client_ffi(
  host : String,
  port : Int,
  is_server : Bool,
) -> JSTcpStream =
  #| function(host, port, is_server) {
  #|     const deasync = require('deasync');
  #|     const net = require('net');
  #|     const { EventEmitter } = require('events');
  #| 
  #|     function makeSync(fn) {
  #|         return deasync(function (...args) {
  #|             // deasync needed callback is the last parameter, we pop it from args
  #|             const callback = args.pop();
  #|             // Invoke the async function with the remaining arguments
  #|             fn(...args)
  #|                 .then(result => callback(null, result)) 
  #|                 .catch(error => callback(error, null));
  #|         });
  #|     }
  #| 
  #|     class JSTcpStream extends EventEmitter {
  #|         constructor(socket) {
  #|             super();
  #|             this.socket = socket;
  #|             this.closed = false;
  #| 
  #|             // 绑定事件
  #|             this.socket.on('data', (data) => {
  #|                 this.emit('data', data);
  #|             });
  #| 
  #|             this.socket.on('error', (err) => {
  #|                 this.emit('error', err);
  #|             });
  #| 
  #|             this.socket.on('close', () => {
  #|                 this.closed = true;
  #|                 this.emit('close');
  #|             });
  #| 
  #|             this.socket.on('end', () => {
  #|                 this.emit('end');
  #|             });
  #|         }
  #| 
  #|         // 静态方法：连接到指定地址
  #|         static connect(address, port) {
  #|             return new Promise((resolve, reject) => {
  #|                 const socket = new net.Socket();
  #| 
  #|                 socket.connect(port, address, () => {
  #|                     resolve(new JSTcpStream(socket));
  #|                 });
  #| 
  #|                 socket.on('error', reject);
  #|             });
  #|         }
  #| 
  #|         // 异步读取数据
  #|         async read(size) {
  #|             if (this.closed) {
  #|                 throw new Error('Stream is closed');
  #|             }
  #| 
  #|             return new Promise((resolve, reject) => {
  #|                 const onData = (data) => {
  #|                     this.socket.removeListener('data', onData);
  #|                     this.socket.removeListener('error', onError);
  #|                     this.socket.removeListener('close', onClose);
  #| 
  #|                     if (size && data.length > size) {
  #|                         // 如果数据超过请求大小，将剩余数据推回
  #|                         this.socket.unshift(data.slice(size));
  #|                         resolve(data.slice(0, size));
  #|                     } else {
  #|                         resolve(data);
  #|                     }
  #|                 };
  #| 
  #|                 const onError = (err) => {
  #|                     this.socket.removeListener('data', onData);
  #|                     this.socket.removeListener('error', onError);
  #|                     this.socket.removeListener('close', onClose);
  #|                     reject(err);
  #|                 };
  #| 
  #|                 const onClose = () => {
  #|                     this.socket.removeListener('data', onData);
  #|                     this.socket.removeListener('error', onError);
  #|                     this.socket.removeListener('close', onClose);
  #|                     resolve(null); // 连接关闭
  #|                 };
  #| 
  #|                 this.socket.on('data', onData);
  #|                 this.socket.on('error', onError);
  #|                 this.socket.on('close', onClose);
  #|             });
  #|         }
  #| 
  #|         // 同步读取（使用 readline 或 buffer）
  #|         readSync(size) {
  #|             if (this.closed) {
  #|                 throw new Error('Stream is closed');
  #|             }
  #| 
  #|             const data = this.socket.read(size);
  #|             return data;
  #|         }
  #| 
  #|         // 写入数据
  #|         write(data) {
  #|             if (this.closed) {
  #|                 throw new Error('Stream is closed');
  #|             }
  #| 
  #|             return new Promise((resolve, reject) => {
  #|                 this.socket.write(data, (err) => {
  #|                     if (err) {
  #|                         reject(err);
  #|                     } else {
  #|                         resolve();
  #|                     }
  #|                 });
  #|             });
  #|         }
  #| 
  #|         // 同步写入
  #|         writeSync(data) {
  #|             if (this.closed) {
  #|                 throw new Error('Stream is closed');
  #|             }
  #| 
  #|             return this.socket.write(data);
  #|         }
  #| 
  #|         // 刷新缓冲区
  #|         flush() {
  #|             return new Promise((resolve) => {
  #|                 this.socket.end(() => {
  #|                     resolve();
  #|                 });
  #|             });
  #|         }
  #| 
  #|         // 关闭连接
  #|         close() {
  #|             if (!this.closed) {
  #|                 this.socket.end();
  #|                 this.closed = true;
  #|             }
  #|         }
  #| 
  #|         // 获取本地地址
  #|         localAddr() {
  #|             return {
  #|                 address: this.socket.localAddress,
  #|                 port: this.socket.localPort
  #|             };
  #|         }
  #| 
  #|         // 获取远程地址
  #|         peerAddr() {
  #|             return {
  #|                 address: this.socket.remoteAddress,
  #|                 port: this.socket.remotePort
  #|             };
  #|         }
  #| 
  #|         // 设置超时
  #|         setTimeout(timeout, callback) {
  #|             this.socket.setTimeout(timeout, callback);
  #|         }
  #| 
  #|         // 设置保持连接
  #|         setKeepAlive(enable, initialDelay) {
  #|             this.socket.setKeepAlive(enable, initialDelay);
  #|         }
  #| 
  #|         // 禁用 Nagle 算法
  #|         setNoDelay(noDelay = true) {
  #|             this.socket.setNoDelay(noDelay);
  #|         }
  #|     }
  #|     class JSTcpListener extends EventEmitter {
  #|         constructor(server) {
  #|             super();
  #|             this.server = server;
  #|             this.listening = false;
  #| 
  #|             // 绑定事件
  #|             this.server.on('connection', (socket) => {
  #|                 const stream = new JSTcpStream(socket);
  #|                 this.emit('connection', stream);
  #|             });
  #| 
  #|             this.server.on('error', (err) => {
  #|                 this.emit('error', err);
  #|             });
  #| 
  #|             this.server.on('close', () => {
  #|                 this.listening = false;
  #|                 this.emit('close');
  #|             });
  #| 
  #|             this.server.on('listening', () => {
  #|                 this.listening = true;
  #|                 this.emit('listening');
  #|             });
  #|         }
  #| 
  #|         // 静态方法：绑定到指定地址
  #|         static bind(address, port) {
  #|             return new Promise((resolve, reject) => {
  #|                 const server = net.createServer();
  #|                 const listener = new JSTcpListener(server);
  #| 
  #|                 server.listen(port, address, () => {
  #|                     resolve(listener);
  #|                 });
  #| 
  #|                 server.on('error', reject);
  #|             });
  #|         }
  #| 
  #|         // 异步接受连接
  #|         async accept() {
  #|             if (!this.listening) {
  #|                 throw new Error('Listener is not listening');
  #|             }
  #| 
  #|             return new Promise((resolve, reject) => {
  #|                 const onConnection = (stream) => {
  #|                     this.removeListener('connection', onConnection);
  #|                     this.removeListener('error', onError);
  #|                     this.removeListener('close', onClose);
  #|                     resolve(stream);
  #|                 };
  #| 
  #|                 const onError = (err) => {
  #|                     this.removeListener('connection', onConnection);
  #|                     this.removeListener('error', onError);
  #|                     this.removeListener('close', onClose);
  #|                     reject(err);
  #|                 };
  #| 
  #|                 const onClose = () => {
  #|                     this.removeListener('connection', onConnection);
  #|                     this.removeListener('error', onError);
  #|                     this.removeListener('close', onClose);
  #|                     reject(new Error('Listener closed'));
  #|                 };
  #| 
  #|                 this.on('connection', onConnection);
  #|                 this.on('error', onError);
  #|                 this.on('close', onClose);
  #|             });
  #|         }
  #| 
  #|         // 获取本地地址
  #|         localAddr() {
  #|             const addr = this.server.address();
  #|             return {
  #|                 address: addr.address,
  #|                 port: addr.port
  #|             };
  #|         }
  #| 
  #|         // 关闭监听器
  #|         close() {
  #|             return new Promise((resolve) => {
  #|                 this.server.close(() => {
  #|                     resolve();
  #|                 });
  #|             });
  #|         }
  #| 
  #|         // 设置最大连接数
  #|         setMaxConnections(max) {
  #|             this.server.maxConnections = max;
  #|         }
  #| 
  #|         // 获取当前连接数
  #|         getConnections() {
  #|             return new Promise((resolve, reject) => {
  #|                 this.server.getConnections((err, count) => {
  #|                     if (err) {
  #|                         reject(err);
  #|                     } else {
  #|                         resolve(count);
  #|                     }
  #|                 });
  #|             });
  #|         }
  #|     }
  #| 
  #|     if (is_server) {
  #|         sync_listener = makeSync(JSTcpListener.bind);
  #|         return sync_listener(host, port);
  #|     } else {
  #|         sync_stream = makeSync(JSTcpStream.connect);
  #|         return sync_stream(host, port);
  #|     }
  #| }

///|
extern "js" fn accept_ffi(handle : JSTcpListener) -> JSTcpStream =
  #| function(handle) {
  #|     const deasync = require('deasync');
  #|     const net = require('net');
  #|     const { EventEmitter } = require('events');
  #| 
  #|     function makeSync(fn) {
  #|         return deasync(function (...args) {
  #|             // deasync needed callback is the last parameter, we pop it from args
  #|             const callback = args.pop();
  #|             // Invoke the async function with the remaining arguments
  #|             fn(...args)
  #|                 .then(result => callback(null, result)) 
  #|                 .catch(error => callback(error, null));
  #|         });
  #|     }
  #|     // const stream = await handle.accept();
  #|     const sync_accept = makeSync(async () =>{
  #|         return handle.accept()
  #|     });
  #|     return sync_accept();
  #| }

///|
extern "js" fn read_ffi(handle : JSTcpStream, n : Int) -> Bytes =
  #| function(handle, n) {
  #|     const deasync = require('deasync');
  #| 
  #|     function makeSync(fn) {
  #|         return deasync(function (...args) {
  #|             // deasync needed callback is the last parameter, we pop it from args
  #|             const callback = args.pop();
  #|             // Invoke the async function with the remaining arguments
  #|             fn(...args)
  #|                 .then(result => callback(null, result)) 
  #|                 .catch(error => callback(error, null));
  #|         });
  #|     }
  #|     // const stream = await handle.accept();
  #|     const sync_read = makeSync(async (n) =>{
  #|         return handle.read(n)
  #|     });
  #|     return sync_read(n);
  #| }

///|
extern "js" fn write_ffi(
  handle : JSTcpStream,
  bytes : FixedArray[Byte],
  n : Int,
) -> Int =
  #| function(handle, bytes, n) {
  #|     const deasync = require('deasync');
  #| 
  #|     function makeSync(fn) {
  #|         return deasync(function (...args) {
  #|             // deasync needed callback is the last parameter, we pop it from args
  #|             const callback = args.pop();
  #|             // Invoke the async function with the remaining arguments
  #|             fn(...args)
  #|                 .then(result => callback(null, result)) 
  #|                 .catch(error => callback(error, null));
  #|         });
  #|     }
  #|     const sync_write = makeSync(async (data) =>{
  #|         return handle.write(data)
  #|     });
  #|     const uint8Array = new Uint8Array(bytes);
  #|     sync_write(uint8Array);
  #|     return n;
  #| }

///|
extern "js" fn close_ffi(handle : JSTcpStream) -> Int =
  #| function(handle) {
  #|     // Close
  #|     const deasync = require('deasync');
  #|     function makeSync(fn) {
  #|         return deasync(function (...args) {
  #|             // deasync needed callback is the last parameter, we pop it from args
  #|             const callback = args.pop();
  #|             // Invoke the async function with the remaining arguments
  #|             fn(...args)
  #|                 .then(result => callback(null, result)) 
  #|                 .catch(error => callback(error, null));
  #|         });
  #|     }
  #|     const sync_close = makeSync(async () =>{
  #|         return handle.close()
  #|     });
  #|     sync_close();
  #|     return 0;
  #| }

///|
extern "js" fn close_listener_ffi(handle : JSTcpListener) -> Int =
  #| function(handle) {
  #|     // Close
  #|     const deasync = require('deasync');
  #|     function makeSync(fn) {
  #|         return deasync(function (...args) {
  #|             // deasync needed callback is the last parameter, we pop it from args
  #|             const callback = args.pop();
  #|             // Invoke the async function with the remaining arguments
  #|             fn(...args)
  #|                 .then(result => callback(null, result)) 
  #|                 .catch(error => callback(error, null));
  #|         });
  #|     }
  #|     const sync_close = makeSync(async () =>{
  #|         return handle.close()
  #|     });
  #|     sync_close();
  #|     return 0;
  #| }

///|
fn create_tcp_listener(host : String, port : Int) -> ITcpListener {
  let inner = create_tcp_listener_ffi(host, port, true)
  ITcpListener::{ inner, }
}

///|
fn create_tcp_stream_client(host : String, port : Int) -> ITcpStream {
  let inner = create_tcp_stream_client_ffi(host, port, false)
  ITcpStream::{ inner, }
}

///|
pub fn ITcpStream::connect(addr : SocketAddr) -> ITcpStream raise @io.IOError {
  let (host, port) = match addr {
    SocketAddr::V4(host, port) => (host, port)
    SocketAddr::V6(host, port) => raise @io.IOError("IPv6 not supported in JS")
  }
  create_tcp_stream_client(host, port.to_int())
}

///|
pub fn ITcpStream::peek(
  self : ITcpStream,
  buffer : FixedArray[Byte],
) -> Int raise @io.IOError {
  raise @io.IOError("Peek not supported in JS target")
}

///|
pub fn ITcpStream::read(
  self : ITcpStream,
  buffer : FixedArray[Byte],
) -> Int raise @io.IOError {
  let bytes = read_ffi(self.inner, buffer.length())
  let buf = FixedArray::from_iter(bytes.iter())
  if buf.length() == 0 {
    raise @io.IOError("Failed to read from ITcpStream")
  }
  for i in 0..<buf.length() {
    buffer[i] = buf[i]
  }
  buf.length()
}

///|
pub fn ITcpStream::write(
  self : ITcpStream,
  data : FixedArray[Byte],
  len : Int,
) -> Int raise @io.IOError {
  let res = write_ffi(self.inner, data, len)
  if res < 0 {
    raise @io.IOError("Failed to write to ITcpStream")
  }
  res
}

///|
pub fn ITcpStream::shutdown(
  self : ITcpStream,
  how : Shutdown,
) -> Unit raise @io.IOError {
  raise @io.IOError("Shutdown not supported in JS target")
}

///|
pub fn ITcpStream::close(self : ITcpStream) -> Unit raise @io.IOError {
  guard close_ffi(self.inner) is 0 else {
    raise @io.IOError("Failed to close ITcpStream")
  }
}

///|
pub impl @io.Read for ITcpStream with read(
  self : ITcpStream,
  buf : FixedArray[Byte],
) -> Int raise @io.IOError {
  self.read(buf)
}

///|
pub fn ITcpListener::bind(
  addr : SocketAddr,
  backlog~ : Int = 5,
) -> ITcpListener raise @io.IOError {
  let (host, port) = match addr {
    SocketAddr::V4(host, port) => (host, port)
    SocketAddr::V6(host, port) => raise @io.IOError("IPv6 not supported in JS")
  }
  create_tcp_listener(host, port.to_int())
}

///|
pub fn ITcpListener::accept(
  self : ITcpListener,
) -> ITcpStream raise @io.IOError {
  println("Accepting connection on ITcpListener")
  let inner = accept_ffi(self.inner)
  println("Accepted connection on ITcpListener")
  if 1 != 1 {
    raise @io.IOError("Failed to accept connection")
  }
  ITcpStream::{ inner, }
}

///|
pub fn ITcpListener::close(self : ITcpListener) -> Unit raise @io.IOError {
  guard close_listener_ffi(self.inner) is 0 else {
    raise @io.IOError("Failed to close ITcpListener")
  }
}
