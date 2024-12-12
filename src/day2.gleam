import gleam/dict
import gleam/function
import gleam/int
import gleam/list
import gleam/order
import gleam/string

pub fn parse(input) {
  let reports =
    input
    |> string.split("\n")
    |> list.filter(fn(report) { report |> string.length > 0 })
  use report <- list.map(reports)
  let levels = report |> string.split(" ")
  use level <- list.map(levels)
  let assert Ok(level) = int.parse(level)
  level
}

pub fn solve1(input: List(List(Int))) {
  input |> list.filter(safe) |> list.length
}

fn safe(level) {
  let comps =
    level
    |> list.window_by_2
    |> list.group(fn(window) {
      let diff = int.absolute_value(window.0 - window.1)
      case diff >= 1 && diff <= 3 {
        True -> int.compare(window.0, window.1)
        False -> order.Eq
      }
    })
    |> dict.map_values(fn(_, value) { list.length(value) })
    |> dict.filter(fn(_, length) { length != 0 })
    |> dict.keys

  case comps {
    [order.Eq] -> False
    [_] -> True
    _ -> False
  }
}

pub fn solve2(input) {
  input
  |> list.map(make_safe)
  |> list.filter_map(function.identity)
  |> list.length
}

fn make_safe(report) {
  let report_length = list.length(report)
  let counts = count(report_length, [])

  let removed_options =
    report
    |> list.repeat(report_length)
    |> list.zip(counts)
    |> list.map(fn(to_remove) {
      to_remove.0
      |> list.index_map(fn(level, i) {
        case i == to_remove.1 {
          True -> Error(Nil)
          False -> Ok(level)
        }
      })
      |> list.filter_map(function.identity)
    })
  case [report, ..removed_options] |> list.any(safe) {
    True -> Ok(report)
    False -> Error(report)
  }
}

fn count(n, acc) {
  case n {
    0 -> acc
    _ -> count(n - 1, [n - 1, ..acc])
  }
}
