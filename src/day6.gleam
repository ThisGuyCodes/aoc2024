import gleam/dict.{type Dict}
import gleam/function
import gleam/io
import gleam/list
import gleam/string

pub opaque type Input {
  Input(map: Dict(#(Int, Int), Tile))
}

type Tile {
  Guard(List(Direction))
  Obstacle
  Open
}

type Direction {
  N
  E
  S
  W
}

pub fn parse(input) -> Input {
  let grid =
    string.split(input, "\n")
    |> list.map(string.split(_, ""))
  {
    use row, y <- list.index_map(grid)
    use cell, x <- list.index_map(row)
    case cell {
      "#" -> #(#(x, y), Obstacle)
      "." -> #(#(x, y), Open)
      "^" -> #(#(x, y), Guard([N]))
      tile -> {
        io.debug(tile)
        panic as "Unknown tile"
      }
    }
  }
  |> list.flatten
  |> dict.from_list
  |> Input
}

fn get_guard_loc(map: Dict(#(Int, Int), Tile)) {
  let assert Ok(guard_loc) =
    dict.to_list(map)
    |> list.find(fn(it) {
      case it.1 {
        Guard(_) -> True
        _ -> False
      }
    })
  guard_loc.0
}

pub fn solve1(input: Input) -> Int {
  let guard_loc = get_guard_loc(input.map)
  let assert Ok(result) = walk(input.map, guard_loc, N)
  result
  |> dict.to_list
  |> list.filter(fn(it) {
    case it.1 {
      Guard(_) -> True
      _ -> False
    }
  })
  |> list.length
}

fn walk(map: Dict(#(Int, Int), Tile), loc: #(Int, Int), dir: Direction) {
  let step = next_loc(loc, dir)
  case dict.get(map, step) {
    Error(_) -> Ok(map)
    Ok(Guard(dirs)) -> {
      case list.contains(dirs, dir) {
        True -> Error("loop")
        False ->
          dict.insert(map, step, Guard(list.append(dirs, [dir])))
          |> walk(step, dir)
      }
    }
    Ok(Open) -> {
      dict.insert(map, step, Guard([dir]))
      |> walk(step, dir)
    }
    Ok(Obstacle) -> {
      let new_dir = turn_right(dir)
      walk(map, loc, new_dir)
    }
  }
}

fn next_loc(loc: #(Int, Int), dir: Direction) {
  case dir {
    N -> #(loc.0, loc.1 - 1)
    E -> #(loc.0 + 1, loc.1)
    S -> #(loc.0, loc.1 + 1)
    W -> #(loc.0 - 1, loc.1)
  }
}

fn turn_right(dir: Direction) {
  case dir {
    N -> E
    E -> S
    S -> W
    W -> N
  }
}

fn has_loop(map: Dict(#(Int, Int), Tile), guard_loc: #(Int, Int)) {
  case walk(map, guard_loc, N) {
    Error("loop") -> True
    Error(_) -> panic as "Unexpected error"
    Ok(_) -> False
  }
}

pub fn solve2(input: Input) {
  let guard_loc = get_guard_loc(input.map)
  let assert Ok(map) = walk(input.map, get_guard_loc(input.map), N)
  map
  |> dict.to_list
  |> list.filter(fn(it) {
    case it.1 {
      Guard(_) -> True
      _ -> False
    }
  })
  |> list.filter(fn(it) { it.0 != guard_loc })
  |> list.map(fn(it) { it.0 })
  |> list.map(fn(it) {
    dict.insert(input.map, it, Obstacle)
    |> has_loop(guard_loc)
  })
  |> list.count(function.identity)
}
