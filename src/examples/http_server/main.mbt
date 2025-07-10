///|
fn main {
  (try? run_http_server())
  .map_err(e => println("Error running TCP server: \{e}"))
  .unwrap()
}

///|
fn run_http_server() -> Unit raise @io.IOError {
  let addr = @io.SocketAddr::V4("127.0.0.1", 18080)
  let listener = @tcp.TcpListener::bind(addr)
  while true {
    let stream = listener.accept() catch {
      e => {
        println("Error accepting connection: \{e}")
        continue
      }
    }
    handle_connection(stream) catch {
      e => println("Error handling connection: \{e}")
    }
    stream.close()
  }
  let _ = listener.close()
  println("TCP server running on \{addr}")
}

///|
fn handle_connection(stream : @tcp.TcpStream) -> Unit raise @io.IOError {
  println("Accepted a connection from: ")
  let (method, path, headers, remain_lines) = parse_http(stream) catch {
    e => raise @io.IOError("Failed to parse HTTP request: \{e}")
  }
  println("===================================================")
  println("Received HTTP request:")
  println("Method: \{method}")
  println("Path: \{path}")
  println("Headers: \{headers}")
  match remain_lines {
    Some(lines) => println("Body: \{lines}")
    None => println("No body in request.")
  }
  println("===================================================")
  let status_line = "HTTP/1.1 200 OK"
  let body = html_reply()
  let length = body.length()
  let reply =
    $|\{status_line}\r\nContent-Length: \{length}\r\n\r\n\{body}
  println("Replying with: \{reply}")
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
    #| <title>MoonBit HTTP Server</title>
    #| </head>
    #| <body>
    #| <h1>Welcome to the MoonBit HTTP Server!</h1>
    #| <p>This is a simple HTTP server written in MoonBit.</p>
    #| </br>
    #| </body>
    #| </html>
  b
}

///|
fn[R : @io.Read] parse_http(
  reader : R,
) -> (String, String, Map[String, String], String?) raise @io.IOError {
  let buf_reader = @io.BufReader::new(reader)
  let iter : Iter[Result[String, @io.IOError]] = buf_reader.lines().iter()
  // First line, eg: "GET / HTTP/1.1"
  guard iter.peek() is Some(Ok(first_line)) else {
    raise @io.IOError("Failed to read first line from stream.")
  }
  let (method, path, _version) = match
    first_line.split(" ").map(@string.View::to_string).collect() {
    [pa, pb, pc] => (pa, pb, pc)
    _ => raise @io.IOError("Invalid HTTP request line format.")
  }

  // Read the parts of the header
  let header_lines = iter
    .map(l => l.or(""))
    .take_while(l => !l.is_empty())
    .map(fn(l) {
      let arr = l
        .split(":")
        .map(r => r.trim_space().to_lower())
        .map(@string.View::to_string)
        .collect()
      (arr[0], arr[1])
    })
    .collect()
  let headers = Map::from_array(header_lines)
  let content_length = headers
    .get("content-length")
    .map(s => BigInt::from_string(s).to_int())
    .unwrap_or(0)
  let remain_lines = if content_length > 0 {
    println("Content-Length: " + content_length.to_string())
    let buf = FixedArray::make(content_length, Byte::default())
    buf_reader.read_exact(buf)
    let lines = @io.utf8_bytes_to_mbt_string(Bytes::from_fixedarray(buf)) catch {
      e => raise @io.IOError("Failed to decode request body: " + e.to_string())
    }
    Some(lines)
  } else {
    None
  }
  (method, path, headers, remain_lines)
}
