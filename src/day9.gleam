import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/yielder.{type Yielder, Done, Next}

pub opaque type Input {
  Input(segments: List(Segment))
}

type Segment {
  FreeSeg(size: Int)
  FileSeg(size: Int, id: Int)
}

type Block {
  Free
  File(id: Int)
}

pub fn parse(input) -> Input {
  let assert Ok(numerals) =
    input
    |> string.trim
    |> string.split("")
    |> list.map(int.parse)
    |> result.all
  numerals
  |> list.index_map(fn(num, i) {
    case num {
      0 -> None
      _ ->
        Some(case i % 2 == 0 {
          True -> FileSeg(size: num, id: i / 2)
          False -> FreeSeg(size: num)
        })
    }
  })
  |> option.values
  |> Input(segments: _)
}

pub fn solve1(input: Input) {
  let length = input.segments |> segments_to_blocks |> yielder.length
  let blocks = input.segments |> segments_to_blocks |> yielder.index
  let rev_file_blocks = {
    let with_index =
      input.segments |> list.reverse |> segments_to_blocks |> yielder.index
    use #(block, i) <- yielder.filter_map(with_index)
    case block {
      File(id) -> Ok(#(id, length - 1 - i))
      Free -> Error(Nil)
    }
  }
  let id_locs = {
    use #(rev_file_blocks, j), #(block, i) <- yielder.transform(blocks, #(
      rev_file_blocks,
      length - 1,
    ))
    case j <= i {
      True -> Done
      False ->
        case block {
          File(id: id) -> Next(#(id, i), #(rev_file_blocks, j))
          Free -> {
            case yielder.step(rev_file_blocks) {
              Done -> panic as "reverse iterator exhausted?!"
              Next(#(id, j), rev_file_blocks) -> {
                case j <= i {
                  True -> Done
                  False -> Next(#(id, i), #(rev_file_blocks, j))
                }
              }
            }
          }
        }
    }
  }
  use acc, #(id, loc) <- yielder.fold(id_locs, 0)
  acc + id * loc
}

fn segments_to_blocks(blocks: List(Segment)) -> Yielder(Block) {
  let segments = blocks |> yielder.from_list
  use block <- yielder.flat_map(segments)
  case block {
    FreeSeg(size: size) -> yielder.repeat(Free) |> yielder.take(size)
    FileSeg(size: size, id: id) ->
      yielder.repeat(File(id)) |> yielder.take(size)
  }
}

pub fn solve2(input: Input) -> Int {
  0
}