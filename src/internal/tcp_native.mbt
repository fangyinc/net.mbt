///|
pub typealias @socket.Shutdown

///|
fn SocketAddr::to_addr(self : SocketAddr) -> @socket.SocketAddr {
  match self {
    V4(host, port) => @socket.SocketAddr::V4(host, port.to_int())
    V6(host, port) => @socket.SocketAddr::V6(host, port.to_int())
  }
}

///| 
pub(all) struct ITcpListener {
  inner : @socket.Socket
}

///|
pub(all) struct ITcpStream {
  inner : @socket.Socket
}

///|
pub fn ITcpStream::connect(addr : SocketAddr) -> ITcpStream raise @io.IOError {
  let socket = @socket.new(
    @socket.Domain::from_address(addr.to_addr()),
    @socket.Type::Stream,
  ) catch {
    _ => raise @io.IOError("Failed to create socket")
  }
  socket.connect(addr.to_addr()) catch {
    e => raise @io.IOError(e.to_string())
  }
  ITcpStream::{ inner: socket }
}

///|
pub fn ITcpStream::peek(
  self : ITcpStream,
  buffer : FixedArray[Byte],
) -> Int raise @io.IOError {
  ...
}

///|
pub fn ITcpStream::read(
  self : ITcpStream,
  buffer : FixedArray[Byte],
) -> Int raise @io.IOError {
  self.inner.recv(buffer) catch {
    e => raise @io.IOError(e.to_string())
  }
}

///|
pub fn ITcpStream::write(
  self : ITcpStream,
  data : FixedArray[Byte],
  len : Int,
) -> Int raise @io.IOError {
  self.inner.send(data, len) catch {
    e => raise @io.IOError(e.to_string())
  }
}

///|
pub fn ITcpStream::shutdown(
  self : ITcpStream,
  how : @socket.Shutdown,
) -> Unit raise @io.IOError {
  self.inner.shutdown(how) catch {
    e => raise @io.IOError(e.to_string())
  }
}

///|
pub fn ITcpStream::close(self : ITcpStream) -> Unit raise @io.IOError {
  self.inner.close() catch {
    e => raise @io.IOError(e.to_string())
  }
}

///|
pub impl @io.Read for ITcpStream with read(
  self : ITcpStream,
  buf : FixedArray[Byte],
) -> Int raise @io.IOError {
  self.inner.recv(buf) catch {
    e => raise @io.IOError(e.to_string())
  }
}

///|
pub fn ITcpListener::bind(
  addr : SocketAddr,
  backlog~ : Int = 5,
) -> ITcpListener raise @io.IOError {
  let addr = addr.to_addr()
  let socket = @socket.new(
    @socket.Domain::from_address(addr),
    @socket.Type::Stream,
  )
  ..bind(addr)
  ..listen(backlog~) catch {
    e => raise @io.IOError(e.to_string())
  }
  ITcpListener::{ inner: socket }
}

///|
pub fn ITcpListener::accept(
  self : ITcpListener,
) -> ITcpStream raise @io.IOError {
  let socket = self.inner.accept() catch {
    e => raise @io.IOError(e.to_string())
  }
  ITcpStream::{ inner: socket }
}

///|
pub fn ITcpListener::close(self : ITcpListener) -> Unit raise @io.IOError {
  self.inner.close() catch {
    e => raise @io.IOError(e.to_string())
  }
}
