import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/set
import gleam/string

pub opaque type Input {
  Input(map: Dict(#(Int, Int), Cell))
}

type Cell {
  Empty
  Antenna(String)
}

pub fn parse(input) -> Input {
  let lines = string.split(input, "\n")
  {
    use line, y <- list.index_map(lines)
    let cells = string.split(line, "")
    use cell, x <- list.index_map(cells)
    case cell {
      "." -> #(#(x, y), Empty)
      _ -> #(#(x, y), Antenna(cell))
    }
  }
  |> list.flatten
  |> dict.from_list
  |> Input
}

pub fn antinodes(pair: #(#(Int, Int), #(Int, Int))) -> List(#(Int, Int)) {
  let #(a, b) = pair
  let distance = #(a.0 - b.0, a.1 - b.1)
  [#(a.0 + distance.0, a.1 + distance.1), #(b.0 - distance.0, b.1 - distance.1)]
}

pub fn antinodes2(
  pair: #(#(Int, Int), #(Int, Int)),
  bounds: #(Int, Int),
) -> List(#(Int, Int)) {
  let #(a, b) = pair
  let distance = #(a.0 - b.0, a.1 - b.1)
  let distances = gen_distances(distance, 1, [], bounds)
  list.map(distances, fn(distance) {
    [
      #(a.0 - distance.0, a.1 - distance.1),
      #(b.0 + distance.0, b.1 + distance.1),
    ]
    |> list.filter(fn(node) { in_bounds(node, bounds) })
  })
  |> list.flatten
}

fn gen_distances(distance: #(Int, Int), mul, acc, bounds: #(Int, Int)) {
  let new_distance = #(distance.0 * mul, distance.1 * mul)
  let new_distance_abs = #(
    int.absolute_value(new_distance.0),
    int.absolute_value(new_distance.1),
  )
  case in_bounds(new_distance_abs, bounds) {
    True -> gen_distances(distance, mul + 1, [new_distance, ..acc], bounds)
    False -> acc
  }
}

fn in_bounds(loc: #(Int, Int), bounds: #(Int, Int)) {
  loc.0 >= 0 && loc.0 <= bounds.0 && loc.1 >= 0 && loc.1 <= bounds.1
}

fn get_tower_groups(map) {
  map
  |> dict.to_list
  |> list.filter_map(fn(cell) {
    case cell.1 {
      Antenna(freq) -> Ok(#(cell.0, freq))
      _ -> Error(Nil)
    }
  })
  |> list.group(fn(cell) { cell.1 })
  |> dict.map_values(fn(_, towers) {
    use tower <- list.map(towers)
    tower.0
  })
  |> dict.to_list
}

pub fn solve1(input: Input) {
  let bounds = get_bounds(input.map)
  let tower_groups =
    get_tower_groups(input.map)
    |> list.map(fn(tg) { tg.1 })

  let pairings =
    list.map(tower_groups, fn(tg) { list.combination_pairs(tg) })
    |> list.flatten
  {
    use pair <- list.map(pairings)
    use node <- list.filter(antinodes(pair))
    in_bounds(node, bounds)
  }
  |> list.flatten
  |> set.from_list
  |> set.size
}

fn get_bounds(map) {
  map
  |> dict.keys
  |> list.fold(#(0, 0), fn(acc, loc: #(Int, Int)) {
    #(int.max(acc.0, loc.0), int.max(acc.1, loc.1))
  })
}

pub fn solve2(input: Input) -> Int {
  let bounds = get_bounds(input.map)
  let tower_groups =
    get_tower_groups(input.map)
    |> list.map(fn(tg) { tg.1 })

  let pairings =
    list.map(tower_groups, fn(tg) { list.combination_pairs(tg) })
    |> list.flatten
  {
    use pair <- list.map(pairings)
    antinodes2(pair, bounds)
  }
  |> list.flatten
  |> set.from_list
  |> set.size
}
