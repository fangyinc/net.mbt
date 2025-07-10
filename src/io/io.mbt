///|
pub(all) suberror IOError String derive(Show)

///|
pub(open) trait Read {
  read(Self, buf : FixedArray[Byte]) -> Int raise IOError
  read_exact(Self, buf : FixedArray[Byte]) -> Unit raise IOError = _
}

///|
pub trait BufRead: Read {
  fill_buf(Self) -> FixedArraySlice[Byte] raise IOError
  consume(Self, amt : Int) -> Unit
  lines(Self) -> Lines[Self] = _
  read_until(Self, delim : Byte, buf : Array[Byte]) -> Int raise IOError = _
  read_line(Self, buf : Array[Byte]?) -> (String, Int) raise IOError = _
}

///|
pub struct Lines[B] {
  buf : B
} derive(Show)

///|
pub struct Buffer {
  buf : FixedArraySlice[Byte]
  mut pos : Int
  mut filled : Int
}

///|
pub struct BufReader[T] {
  buf : Buffer
  inner : T
}

///|
impl Read with read_exact(self, buf : FixedArray[Byte]) -> Unit raise IOError {
  let mut total_read = 0
  let len_to_read = buf.length()
  let tmp_buf = FixedArray::make(len_to_read, Byte::default())
  while total_read < len_to_read {
    let bytes_read = self.read(tmp_buf) catch {
      e => raise IOError("Failed to read from stream: " + e.to_string())
    }
    if bytes_read == 0 {
      break
    }
    for i in 0..<bytes_read {
      buf[total_read + i] = tmp_buf[i]
    }
    total_read += bytes_read
  }
  guard total_read == len_to_read else {
    raise IOError(
      "Failed to read exact number of bytes, expected: " +
      len_to_read.to_string() +
      ", got: " +
      total_read.to_string(),
    )
  }
}

///|
impl BufRead with lines(self) {
  Lines::{ buf: self }
}

///|
impl BufRead with read_until(self, delim : Byte, buf : Array[Byte]) -> Int raise IOError {
  read_until(self, delim, buf)
}

///|
impl BufRead with read_line(self, buf : Array[Byte]?) -> (String, Int) raise IOError {
  let buf = match buf {
    Some(b) => b
    None => Array::new(capacity=8 * 1024)
  }
  let total_read = self.read_until(b'\n', buf)
  let bytes = Bytes::from_array(buf[0:total_read].to_array())
  let str = utf8_bytes_to_mbt_string(bytes) catch {
    e => raise IOError("Failed to decode line: " + e.to_string())
  }
  (str, total_read)
}

///|
pub fn Buffer::capacity(self : Buffer) -> Int {
  self.buf.length()
}

///|
fn Buffer::discard_buffer(self : Buffer) -> Unit {
  // Reset the buffer position and filled size
  self.pos = 0
  self.filled = 0
}

///|
pub fn[B : Read] BufReader::new(buf : B) -> BufReader[B] {
  BufReader::{ buf: Buffer::make(1024), inner: buf }
}

///|
pub impl[B : Read] BufRead for BufReader[B] with fill_buf(self) -> FixedArraySlice[
  Byte,
] raise IOError {
  self.buf.fill_buf(self.inner)
}

///|
pub impl[B : Read] BufRead for BufReader[B] with consume(self, amt : Int) -> Unit {
  self.buf.consume(amt)
}

///|
pub impl[B : Read] Read for BufReader[B] with read(self, buf : FixedArray[Byte]) -> Int raise IOError {
  if self.buf.pos == self.buf.filled && buf.length() >= self.buf.capacity() {
    self.buf.discard_buffer()
    return self.inner.read(buf)
  } else {
    // Fill the buffer and get available data
    let rem = self.fill_buf()
    let nread = min(rem.length(), buf.length())
    for i = 0; i < nread; i = i + 1 {
      buf[i] = rem[i]
    }
    // Update the buffer read position
    self.consume(nread)
    nread
  }
}

///|
fn min(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
pub fn Buffer::make(size : Int) -> Buffer {
  Buffer::{
    buf: FixedArraySlice::make(FixedArray::make(size, Byte::default())),
    pos: 0,
    filled: 0,
  }
}

///|
pub fn Buffer::buffer(self : Buffer) -> FixedArraySlice[Byte] {
  self.buf.slice(self.pos, self.filled)
}

///|
pub fn[R : Read] Buffer::fill_buf(
  self : Buffer,
  reader : R,
) -> FixedArraySlice[Byte] raise IOError {
  if self.pos >= self.filled {
    // Buffer is empty, fill it
    let bytes_read = reader.read(self.buf.array)
    self.filled = bytes_read
    self.pos = 0
  }
  self.buffer()
}

///|
pub fn Buffer::consume(self : Buffer, amt : Int) -> Unit {
  let new_pos = if self.pos + amt < self.filled {
    self.pos + amt
  } else {
    self.filled
  }
  self.pos = new_pos
}

///|
pub fn[R : BufRead] Lines::iter(
  self : Lines[R],
) -> Iter[Result[String, IOError]] {
  Iter::new(fn(visit : (Result[String, IOError]) -> IterResult) -> IterResult {
    while true {
      let (str, total_read) = self.buf.read_line(None) catch {
        e => {
          let _ = visit(
            Err(
              IOError(
                "Failed to read line from buffer, raw error: " + e.to_string(),
              ),
            ),
          )
          break IterEnd
        }
      }
      if total_read == 0 {
        let _ = visit(Err(IOError("End of stream reached.")))
        break IterEnd
      }
      let str = match str.view() {
        [.. rest, b, c] if b == '\r' && c == '\n' => rest
        [.. rest, c] if c == '\r' || c == '\n' => rest
        _ => str
      }
      guard visit(Ok(str.to_string())) is IterContinue else { break IterEnd }
    } else {
      IterContinue
    }
  })
}

///|
fn[R : BufRead] read_until(
  reader : R,
  delim : Byte,
  buf : Array[Byte],
) -> Int raise IOError {
  let mut total_read = 0
  while true {
    let (done, used) = {
      let available = reader.fill_buf()
      match memchr(delim, available) {
        Some(index) => {
          for i in 0..<(index + 1) {
            buf.push(available[i])
          }
          (true, index + 1)
        }
        None => {
          for i in 0..<available.length() {
            buf.push(available[i])
          }
          (false, available.length())
        }
      }
    }
    reader.consume(used)
    total_read += used
    if done || used == 0 {
      break
    }
  }
  total_read
}

///|
fn memchr(x : Byte, buf : FixedArraySlice[Byte]) -> Int? {
  for i in 0..<buf.length() {
    if buf[i] == x {
      return Some(i)
    }
  }
  None
}

///|
pub fn mbt_string_to_utf8_bytes(
  str : String,
  is_filename~ : Bool = false,
) -> Bytes {
  let buf = @buffer.new()
  @encoding.encode_to(str, buf, encoding=UTF8)
  if is_filename {
    buf.write_byte((0).to_byte())
  }
  buf.to_bytes()
}

///|
pub fn utf8_bytes_to_mbt_string(bytes : Bytes) -> String raise {
  let decoder = @encoding.decoder(UTF8)
  decoder.consume(bytes)
}
