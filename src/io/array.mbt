///|
struct FixedArraySlice[T] {
  array : FixedArray[T]
  start : Int
  end : Int
}

///|
fn[T] FixedArraySlice::make(array : FixedArray[T]) -> FixedArraySlice[T] {
  { array, start: 0, end: array.length() }
}

///|
fn[T] FixedArraySlice::length(self : FixedArraySlice[T]) -> Int {
  self.end - self.start
}

///|
fn[T] FixedArraySlice::op_get(self : FixedArraySlice[T], index : Int) -> T {
  self.array[self.start + index]
}

///|
fn[T] FixedArraySlice::slice(
  self : FixedArraySlice[T],
  start : Int,
  end : Int,
) -> FixedArraySlice[T] {
  { array: self.array, start: self.start + start, end: self.start + end }
}
