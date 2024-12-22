import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

pub opaque type Input {
  Input(tests: List(Test))
}

type Test {
  Test(answer: Int, numerals: List(Int))
}

pub fn parse(input) -> Input {
  let tests =
    string.split(input, "\n")
    |> list.filter(fn(it) { it != "" })
  {
    use test_line <- list.map(tests)
    let assert Ok(#(result, numerals)) =
      test_line
      |> string.split_once(":")
    let assert Ok(numerals) =
      string.split(numerals, " ")
      |> list.filter(fn(it) { it != "" })
      |> list.map(int.parse)
      |> result.all
    let assert Ok(result) = int.parse(result)
    Test(result, numerals)
  }
  |> Input
}

fn can(numerals: List(Int), target: Int) {
  case numerals {
    [] ->
      case target {
        0 -> True
        _ -> False
      }
    [this] -> this == target
    [this, ..] if this > target -> False
    [this, next, ..rest] -> {
      can([this + next, ..rest], target) || can([this * next, ..rest], target)
    }
  }
}

pub fn can2(numerals: List(Int), target: Int) {
  case numerals {
    [] ->
      case target {
        0 -> True
        _ -> False
      }
    [this] -> this == target
    [this, ..] if this > target -> False
    [this, next, ..rest] -> {
      can2([this + next, ..rest], target)
      || can2([this * next, ..rest], target)
      || can2([concat(this, next), ..rest], target)
    }
  }
}

fn concat(a, b) {
  let assert Ok(a_digits) = int.digits(a, 10)
  let assert Ok(b_digits) = int.digits(b, 10)
  let appended = list.append(a_digits, b_digits)
  let assert Ok(res) = int.undigits(appended, 10)
  res
}

pub fn solve1(input: Input) -> Int {
  let valid_tests = {
    use t <- list.filter(input.tests)
    can(t.numerals, t.answer)
  }
  use acc, it <- list.fold(valid_tests, 0)
  acc + it.answer
}

pub fn solve2(input: Input) -> Int {
  let valid_tests = {
    use t <- list.filter(input.tests)
    can2(t.numerals, t.answer)
  }
  use acc, it <- list.fold(valid_tests, 0)
  acc + it.answer
}
