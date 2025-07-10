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
fn[T] FixedArraySlice::op_set(
  self : FixedArraySlice[T],
  index : Int,
  value : T,
) -> Unit {
  self.array[self.start + index] = value
}

///|
fn[T] FixedArraySlice::swap(
  self : FixedArraySlice[T],
  a : Int,
  b : Int,
) -> Unit {
  self.array.swap(self.start + a, self.start + b)
}

///|
fn[T] FixedArraySlice::rev_inplace(self : FixedArraySlice[T]) -> Unit {
  let len = self.length()
  let mid_len = len / 2
  for i in 0..<mid_len {
    let j = len - i - 1
    self.swap(i, j)
  }
}

///|
fn[T] FixedArraySlice::slice(
  self : FixedArraySlice[T],
  start : Int,
  end : Int,
) -> FixedArraySlice[T] {
  { array: self.array, start: self.start + start, end: self.start + end }
}
