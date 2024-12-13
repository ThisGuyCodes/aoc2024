import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/regexp

pub type Op {
  Mul(Int, Int)
  Do
  Dont
}

pub fn parse(input) {
  let assert Ok(re) =
    regexp.from_string(
      "(?:(mul)\\((\\d{1,3}),(\\d{1,3})\\)|(do)\\(\\)|(don't)\\(\\))",
    )
  re
  |> regexp.scan(input)
  |> list.map(fn(match) {
    case match.submatches {
      [Some("mul"), Some(left), Some(right)] -> {
        let assert Ok(left) = int.parse(left)
        let assert Ok(right) = int.parse(right)
        Mul(left, right)
      }
      [None, None, None, Some("do")] -> Do
      [None, None, None, None, Some("don't")] -> Dont
      _ -> {
        io.debug(match.submatches)
        panic as "Invalid match"
      }
    }
  })
}

pub fn solve1(input: List(Op)) {
  use acc, op <- list.fold(input, 0)
  case op {
    Mul(left, right) -> acc + left * right
    _ -> acc
  }
}

type OpState {
  Enabled(Int)
  Disabled(Int)
}

pub fn solve2(input) {
  case input |> solve2_inner {
    Enabled(acc) -> acc
    Disabled(acc) -> acc
  }
}

fn solve2_inner(input) {
  use acc, op <- list.fold(input, Enabled(0))
  case acc {
    Enabled(acc) -> {
      case op {
        Mul(left, right) -> Enabled(acc + left * right)
        Do -> Enabled(acc)
        Dont -> Disabled(acc)
      }
    }
    Disabled(acc) -> {
      case op {
        Mul(_, _) -> Disabled(acc)
        Do -> Enabled(acc)
        Dont -> Disabled(acc)
      }
    }
  }
}
