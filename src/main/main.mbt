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
  for stream in listener.incoming().iter() {
    match stream {
      Ok(client) => {
        handle_connection(client) catch {
          e => println("Error handling connection: \{e}")
        }
        client.close()
      }
      Err(e) => println("Error accepting connection: \{e}")
    }
  }
  let _ = listener.close()

}

///|
fn handle_connection(stream : @tcp.TcpStream) -> Unit raise @io.IOError {
  println("Accepted a connection from: ")
  let buf_reader = @io.BufReader::new(stream)
  let lines = buf_reader
    .lines()
    .iter()
    .map(l => l.or(""))
    .take_while(l => !l.is_empty())
    .collect()
  println("===================================================")
  println("Received HTTP request:")
  for line in lines {
    println("\{line}")
  }
  println("===================================================")
  let status_line = "HTTP/1.1 200 OK"
  let body = "<html>\n<head>\n<title>Test Page</title>\n</head>\n<body>\n<h1>Hello, World!</h1>\n</body>\n</html>"
  let length = body.length()
  let reply =
    $|\{status_line}\r\nContent-Length: \{length}\r\n\r\n\{body}
  println("Replying with: \{reply}")
  let cstr = @io.mbt_string_to_utf8_bytes(reply)
  let reply = FixedArray::from_iter(cstr.iter())
  let _ = stream.write(reply, reply.length())

}
