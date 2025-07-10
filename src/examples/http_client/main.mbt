///|
fn main {
  (try? run_http_client())
  .map_err(e => println("Error running TCP server: " + e.to_string()))
  .unwrap()
}

///|
fn run_http_client() -> Unit raise @io.IOError {
  let addr = @internal.SocketAddr::V4("127.0.0.1", 18080)
  let client = @tcp.TcpStream::connect(addr)
  let req_line = "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n"
  println("Sending request: " + req_line)
  let req_bytes = FixedArray::from_iter(
    @io.mbt_string_to_utf8_bytes(req_line).iter(),
  )
  let _ = client.write(req_bytes, req_bytes.length()) catch {
    e => {
      client.close()
      raise @io.IOError("Failed to write to stream: " + e.to_string())
    }
  }
  println("Request sent, waiting for response...")
  let (status_code, status, headers, remain_lines) = parse_http(client) catch {
    e => {
      client.close()
      raise @io.IOError("Failed to parse HTTP response: " + e.to_string())
    }
  }
  println("===================================================")
  println("Received HTTP response:")
  println("Status Code: \{status_code}")
  println("Status: \{status}")
  println("Headers: \{headers}")
  match remain_lines {
    Some(lines) => println("Body: \{lines}")
    None => println("No body in response.")
  }
  println("===================================================")
  client.close() catch {
    e => println("Failed to close stream: " + e.to_string())
  }
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
  let (_version, status_code, status) = match
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
  (status_code, status, headers, remain_lines)
}
