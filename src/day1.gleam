import gleam/dict
import gleam/int
import gleam/list
import gleam/string

pub fn parse(input) {
  input |> string.split("\n") |> parse_lines([])
}

fn parse_lines(lines, acc) -> List(#(Int, Int)) {
  case lines {
    [first, ..rest] -> {
      case first {
        "" -> parse_lines(rest, acc)
        _ -> {
          let assert [left_s, _, _, right_s] = first |> string.split(" ")
          let assert Ok(left) = int.parse(left_s)
          let assert Ok(right) = int.parse(right_s)
          parse_lines(rest, list.append(acc, [#(left, right)]))
        }
      }
    }
    [] -> acc
  }
}

pub fn solve1(input) {
  let sort = list.sort(_, int.compare)
  let #(left, right) = input |> list.unzip
  list.zip(left |> sort, right |> sort) |> sum_diff(0)
}

fn sum_diff(zipped, acc) {
  case zipped {
    [#(left, right), ..rest] -> {
      let diff = right - left |> int.absolute_value
      sum_diff(rest, acc + diff)
    }
    [] -> acc
  }
}

pub fn solve2(input) {
  let #(left, right) = input |> list.unzip
  let right_counts = right |> get_counts(dict.from_list([]))
  calc_symilarity(left, right_counts, 0)
}

fn get_counts(items, acc) {
  case items {
    [first, ..rest] -> {
      case acc |> dict.get(first) {
        Ok(count) -> rest |> get_counts(acc |> dict.insert(first, count + 1))
        Error(_) -> rest |> get_counts(acc |> dict.insert(first, 1))
      }
    }
    [] -> acc
  }
}

fn calc_symilarity(left, right_counts, acc) {
  case left {
    [first, ..rest] -> {
      case dict.get(right_counts, first) {
        Ok(count) -> calc_symilarity(rest, right_counts, acc + count * first)
        Error(_) -> calc_symilarity(rest, right_counts, acc)
      }
    }
    [] -> acc
  }
}
