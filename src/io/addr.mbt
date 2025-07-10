///|
pub(all) enum SocketAddr {
  V4(String, UInt16) // IPv4 address and port
  V6(String, UInt16) // IPv6 address and port
} derive(Show)

