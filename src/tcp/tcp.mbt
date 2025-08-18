///|
pub(all) struct TcpListener {
  inner : @internal.ITcpListener
}

///|
pub(all) struct TcpStream {
  inner : @internal.ITcpStream
}

///|
pub(all) struct Incoming {
  listener : TcpListener
}

///|
pub fn TcpStream::connect(addr : @io.SocketAddr) -> TcpStream raise @io.IOError {
  { inner: @internal.ITcpStream::connect(addr) }
}

///|
pub fn TcpStream::peek(
  self : TcpStream,
  buffer : FixedArray[Byte],
) -> Int raise @io.IOError {
  self.inner.peek(buffer)
}

///|
pub fn TcpStream::read(
  self : TcpStream,
  buffer : FixedArray[Byte],
) -> Int raise @io.IOError {
  self.inner.read(buffer)
}

///|
pub fn TcpStream::write(
  self : TcpStream,
  data : FixedArray[Byte],
  len : Int,
) -> Int raise @io.IOError {
  self.inner.write(data, len)
}

///|
pub fn TcpStream::shutdown(
  self : TcpStream,
  how : @internal.Shutdown,
) -> Unit raise @io.IOError {
  self.inner.shutdown(how)
}

///|
pub fn TcpStream::close(self : TcpStream) -> Unit raise @io.IOError {
  self.inner.close()
}

///|
pub fn TcpListener::bind(
  addr : @io.SocketAddr,
) -> TcpListener raise @io.IOError {
  { inner: @internal.ITcpListener::bind(addr) }
}

///|
pub fn TcpListener::accept(self : TcpListener) -> TcpStream raise @io.IOError {
  { inner: self.inner.accept() }
}

///|
pub fn TcpListener::incoming(self : TcpListener) -> Incoming {
  { listener: self }
}

///|
pub fn TcpListener::close(self : TcpListener) -> Unit raise @io.IOError {
  self.inner.close()
}

///|
pub impl @io.Read for TcpStream with read(
  self : TcpStream,
  buf : FixedArray[Byte],
) -> Int raise @io.IOError {
  self.inner.read(buf)
}

///|
pub fn Incoming::iter(self : Incoming) -> Iter[Result[TcpStream, @io.IOError]] {
  Iter::new(fn(
    visit : (Result[TcpStream, @io.IOError]) -> IterResult,
  ) -> IterResult {
    while true {
      match (try? self.listener.accept()) {
        Ok(client) => {
          guard visit(Ok(client)) is IterContinue else { break IterEnd }
        }
        Err(e) => {
          let err = @io.IOError("Failed to accept connection: \{e}")
          guard visit(Err(err)) is IterContinue else { break IterEnd }
        }
      }
    } else {
      IterContinue
    }
  })
}
