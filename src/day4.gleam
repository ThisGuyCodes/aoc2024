import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

pub type Grid {
  Grid(grid: dict.Dict(Pos, Letter), width: Int, height: Int)
}

pub type Pos {
  Pos(x: Int, y: Int)
}

pub type Letter {
  X
  M
  A
  S
  NA
}

type Direction {
  North
  NorthEast
  East
  SouthEast
  South
  SouthWest
  West
  NorthWest
}

type Progress {
  Progress(pos: Pos, direction: Direction)
}

fn cardinals(pos: Pos) {
  [
    Progress(pos: pos, direction: North),
    Progress(pos: pos, direction: NorthEast),
    Progress(pos: pos, direction: East),
    Progress(pos: pos, direction: SouthEast),
    Progress(pos: pos, direction: South),
    Progress(pos: pos, direction: SouthWest),
    Progress(pos: pos, direction: West),
    Progress(pos: pos, direction: NorthWest),
  ]
}

fn next_letter(letter: Letter) -> Option(Letter) {
  case letter {
    X -> Some(M)
    M -> Some(A)
    A -> Some(S)
    S -> None
    NA -> None
  }
}

fn to_letter(char) {
  case char {
    "X" -> X
    "M" -> M
    "A" -> A
    "S" -> S
    "." -> NA
    _ -> panic as "Invalid letter"
  }
}

pub fn parse(input) -> Grid {
  let rows = string.split(input, "\n")
  let letters = {
    use row <- list.map(rows)
    string.split(row, "")
    |> list.map(to_letter)
  }
  use grid, row, y <- list.index_fold(
    letters,
    Grid(grid: dict.new(), width: 0, height: 0),
  )
  use grid, cell, x <- list.index_fold(row, grid)
  Grid(
    grid: grid.grid |> dict.insert(Pos(x: x, y: y), cell),
    width: int.max(grid.width, x + 1),
    height: int.max(grid.height, y + 1),
  )
}

pub type Entry {
  Entry(pos: Pos, letter: Letter)
}

pub fn solve1(input: Grid) {
  dict.to_list(input.grid)
  |> list.map(fn(it) { Entry(pos: it.0, letter: it.1) })
  |> list.filter(fn(it) { it.letter == X })
  |> list.map(fn(it) { it.pos |> cardinals })
  |> list.flatten
  |> solve_next(input, next_letter(X))
  |> list.length
}

fn solve_next(now, grid: Grid, letter: Option(Letter)) {
  case letter {
    Some(letter) -> {
      get_next(now, grid.grid, letter)
      |> solve_next(grid, next_letter(letter))
    }
    None -> now
  }
}

fn get_next(input: List(Progress), grid, letter) {
  list.map(input, fn(entry) {
    case entry.direction {
      North -> Progress(..entry, pos: Pos(x: entry.pos.x, y: entry.pos.y - 1))
      NorthEast ->
        Progress(..entry, pos: Pos(x: entry.pos.x + 1, y: entry.pos.y - 1))
      East -> Progress(..entry, pos: Pos(x: entry.pos.x + 1, y: entry.pos.y))
      SouthEast ->
        Progress(..entry, pos: Pos(x: entry.pos.x + 1, y: entry.pos.y + 1))
      South -> Progress(..entry, pos: Pos(x: entry.pos.x, y: entry.pos.y + 1))
      SouthWest ->
        Progress(..entry, pos: Pos(x: entry.pos.x - 1, y: entry.pos.y + 1))
      West -> Progress(..entry, pos: Pos(x: entry.pos.x - 1, y: entry.pos.y))
      NorthWest ->
        Progress(..entry, pos: Pos(x: entry.pos.x - 1, y: entry.pos.y - 1))
    }
  })
  |> list.filter_map(fn(it) {
    let new = dict.get(grid, it.pos)
    use new <- result.try(new)
    case new == letter {
      True -> Ok(Progress(pos: it.pos, direction: it.direction))
      False -> Error(Nil)
    }
  })
}

pub fn solve2(input: Grid) {
  input.grid
  |> dict.to_list
  |> list.map(fn(it) { Entry(pos: it.0, letter: it.1) })
  |> list.filter(fn(it) { it.letter == A })
  |> list.map(is_xmas(_, input.grid))
  |> result.values
  |> list.length
}

fn is_xmas(entry: Entry, grid: dict.Dict(Pos, Letter)) {
  use nw <- result.try(dict.get(
    grid,
    Pos(x: entry.pos.x - 1, y: entry.pos.y - 1),
  ))
  use ne <- result.try(dict.get(
    grid,
    Pos(x: entry.pos.x + 1, y: entry.pos.y - 1),
  ))
  use sw <- result.try(dict.get(
    grid,
    Pos(x: entry.pos.x - 1, y: entry.pos.y + 1),
  ))
  use se <- result.try(dict.get(
    grid,
    Pos(x: entry.pos.x + 1, y: entry.pos.y + 1),
  ))
  let one_valid = { nw == M && se == S } || { nw == S && se == M }
  let two_valid = { ne == M && sw == S } || { ne == S && sw == M }
  case one_valid && two_valid {
    True -> Ok(Nil)
    False -> Error(Nil)
  }
}
