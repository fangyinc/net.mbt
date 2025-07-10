///|
fn main {
  // println("Moonbit Net Library");
  (try? run_tcp_server())
  .map_err(e => println("Error running TCP server: " + e.to_string()))
  .unwrap()
}

///|
fn run_tcp_server() -> Unit raise @io.IOError {
  let addr = @internal.SocketAddr::V4("127.0.0.1", 18181)
  let listener = @tcp.TcpListener::bind(addr)
  while true {
    // let stream = listener.accept().unwrap()
    let stream = listener.accept() catch {
      e => {
        println("Error accepting connection: " + e.to_string())
        return
      }
    }
    handle_connection(stream) catch {
      e => println("Error handling connection: " + e.to_string())
    }
    stream.close()
    // handle_connection_one_line(stream)
  }
  let _ = listener.close()
  println("TCP server running on " + addr.to_string())
}

///|
fn handle_connection(stream : @tcp.TcpStream) -> Unit raise @io.IOError {
  println("Accepted a connection from: ")
  let buf_reader = @io.BufReader::new(stream)
  //  read_line 
  // let lines = buf_reader.lines();
  let buf = @buffer.new(size_hint=1024)
  let lines = buf_reader
    .lines()
    .iter()
    .take_while(fn(line) {
      guard line is Ok(line) else {
        println("Failed to read line from stream.")
        return false
      }
      if line.is_empty() || line == "\r\n" || line == "\r" {
        false
      } else {
        true
      }
    })
    .collect()
  println("Received lines: ")
  for line in lines {
    println(line)
  }
  let status_line = "HTTP/1.1 200 OK"
  let body = html_reply()
  let length = body.length()
  let reply =
    $|\{status_line}\r\nContent-Length: \{length}\r\n\r\n\{body}
  println("Replying with: " + reply)
  let cstr = @io.mbt_string_to_utf8_bytes(reply)
  let reply = FixedArray::from_iter(cstr.iter())
  let _ = stream.write(reply, reply.length())
  println("Handled connection and sent reply to client.")
}

///|
fn html_reply() -> String {
  let b =
    #| <html>
    #| <head>
    #| <title>MoonBit TCP Server</title>
    #| </head>
    #| <body>
    #| <h1>Welcome to the MoonBit TCP Server!</h1>
    #| <p>This is a simple TCP server written in MoonBit.</p>
    #| </body>
    #| </html>
  b
}
