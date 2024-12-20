import gleam/dict.{type Dict}
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

pub fn solve1(input: Input) -> Int {
  let assert Ok(guard_loc) =
    dict.to_list(input.map)
    |> list.find(fn(it) {
      case it.1 {
        Guard(_) -> True
        _ -> False
      }
    })
  let assert Ok(result) = walk(input.map, guard_loc.0, N)
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

pub fn solve2(input: Input) -> Int {
  0
}
