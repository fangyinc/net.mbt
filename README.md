# Cross-target network abstractions for MoonBit

## Usage

### Installation

To use a package from this repository, add module `fangyinc/net` dependencies by command
```bash
moon add fangyinc/net
```

And import module in your `moon.pkg.json` file.
```json
{
    "import": [
        "fangyinc/net/io",
        "fangyinc/net/tcp"
    ]
}
```

### Examples

#### Simple HTTP Server


```moonbit
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
  let lines = buf_reader.lines().iter()
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
```

You can run this on code on js target or native target.

**Native Target**

```bash
moon run src/main/main.mbt --target native
```


**JS Target**

First install deasync on local development environment:
```bash
npm install deasync
```

Then run the code:
```bash
moon run src/main/main.mbt --target js
```

Finally, open your browser and navigate to `http://127.0.0.1:18080/` to see the "Hello, World!" message.

And you can also use `curl` to test the server:
```bash
curl http://127.0.0.1:18080
```

#### Complete Example

You can find a complete example of a simple HTTP server in the `src/examples/http_server` directory and a HTTP client in the `src/examples/http_client` directory.

