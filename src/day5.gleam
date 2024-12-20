import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None}
import gleam/order.{Eq, Gt, Lt}
import gleam/string

type Rule {
  Rule(page: Int, come_before: Int)
}

type Update {
  Update(pages: List(Int))
}

pub opaque type Input {
  Input(rules: List(Rule), updates: List(Update))
}

pub fn parse(input) -> Input {
  let assert Ok(#(rules, updates)) = string.split_once(input, "\n\n")
  Input(parse_rules(rules), parse_updates(updates))
}

fn parse_rules(input) {
  use line <- list.map(string.split(input, "\n"))
  let assert Ok(#(page, before)) = string.split_once(line, "|")
  let assert Ok(page) = int.parse(page)
  let assert Ok(before) = int.parse(before)
  Rule(page, before)
}

fn parse_updates(input) {
  let lines =
    string.split(input, "\n")
    |> list.filter(fn(it) { it != "" })
  use line <- list.map(lines)
  string.split(line, ",")
  |> list.map(fn(it) {
    let assert Ok(page) = int.parse(it)
    page
  })
  |> Update
}

fn is_ordered(update: Update, rules: List(Rule), seen) {
  case list.first(update.pages) {
    Error(_) -> True
    Ok(page) -> {
      let passed_rules =
        list.filter(rules, fn(it) { it.page == page })
        |> list.map(fn(it) { it.come_before })
        |> list.all(fn(page) { !dict.has_key(seen, page) })
      case passed_rules {
        False -> False
        True -> {
          let assert Ok(rest) = list.rest(update.pages)
          is_ordered(Update(rest), rules, dict.insert(seen, page, None))
        }
      }
    }
  }
}

pub fn solve1(input: Input) {
  input.updates
  |> list.filter(is_ordered(_, input.rules, dict.new()))
  |> sum_middle
}

fn sum_middle(updates: List(Update)) {
  use acc, update <- list.fold(updates, 0)
  acc + get_middle(update)
}

fn get_middle(update: Update) {
  let length = list.length(update.pages)
  let #(_, remain) = list.split(update.pages, length / 2)
  let assert Ok(middle) = list.first(remain)
  middle
}

pub fn solve2(input: Input) {
  let unordered_updates =
    input.updates
    |> list.filter(fn(update) { !is_ordered(update, input.rules, dict.new()) })
  list.map(unordered_updates, fix_update(_, input.rules))
  |> sum_middle
}

fn fix_update(update: Update, rules) {
  list.sort(update.pages, fn(left, right) { rule_compare(left, right, rules) })
  |> Update
}

fn rule_compare(left, right, rules: List(Rule)) {
  let assert Ok(res) =
    list.map(rules, fn(rule) {
      case rule.page == left && rule.come_before == right {
        True -> Lt
        False ->
          case rule.page == right && rule.come_before == left {
            True -> Gt
            False -> Eq
          }
      }
    })
    |> list.find(fn(it) { it != Eq })
  res
}
