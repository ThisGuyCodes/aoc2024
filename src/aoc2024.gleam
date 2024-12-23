import day1
import day2
import day3
import day4
import day5
import day6
import day7
import day8
import day9
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/io
import simplifile

pub fn main() {
  do_day(2024, 1, day1.parse, day1.solve1, day1.solve2)
  do_day(2024, 2, day2.parse, day2.solve1, day2.solve2)
  do_day(2024, 3, day3.parse, day3.solve1, day3.solve2)
  do_day(2024, 4, day4.parse, day4.solve1, day4.solve2)
  do_day(2024, 5, day5.parse, day5.solve1, day5.solve2)
  do_day(2024, 6, day6.parse, day6.solve1, day6.solve2)
  do_day(2024, 7, day7.parse, day7.solve1, day7.solve2)
  do_day(2024, 8, day8.parse, day8.solve1, day8.solve2)
  do_day(2024, 9, day9.parse, day9.solve1, day9.solve2)
}

fn do_day(year, day, parse, solve1, solve2) {
  let parsed = input(year, day) |> parse
  let log = log(year, day, _)
  solve1(parsed) |> log
  solve2(parsed) |> log
}

fn log(year, day, num) {
  io.println(
    int.to_string(year)
    <> "-"
    <> int.to_string(day)
    <> ": "
    <> int.to_string(num),
  )
}

fn input_url(year, day) {
  "https://adventofcode.com/"
  <> int.to_string(year)
  <> "/day/"
  <> int.to_string(day)
  <> "/input"
}

fn input(year, day) {
  let file_name = file_name(year, day)
  let result = simplifile.read(file_name)
  case result {
    Ok(contents) -> contents
    Error(_) -> {
      let contents = get_input(year, day)
      let assert Ok(_) = simplifile.write(file_name, contents)
      contents
    }
  }
}

fn file_name(year, day) {
  "input_cache/" <> int.to_string(year) <> "_" <> int.to_string(day) <> ".txt"
}

fn get_input(year, day) {
  let assert Ok(req) =
    input_url(year, day)
    |> request.to

  let assert Ok(resp) =
    req
    |> request.prepend_header("Cookie", get_cookie())
    |> httpc.send

  case resp.status {
    200 -> resp.body
    _ -> panic as "Non-200 response"
  }
}

fn get_cookie() {
  let assert Ok(contents) = simplifile.read("cookie.txt")
  contents
}
