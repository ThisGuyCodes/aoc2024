import day1
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/io
import simplifile

pub fn main() {
  do_day(2024, 1, day1.parse, day1.solve1, day1.solve2)
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
