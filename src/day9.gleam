import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/order.{Eq, Gt, Lt}
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
  checksum(id_locs)
}

fn checksum(blocks) {
  use acc, #(id, loc) <- yielder.fold(blocks, 0)
  acc + id * loc
}

fn print_segments(segments: List(Segment)) {
  {
    use segment <- list.map(segments)
    case segment {
      FreeSeg(size: size) -> string.repeat(".", size) |> io.print
      FileSeg(size: size, id: id) ->
        string.repeat(int.to_string(id), size) |> io.print
    }
  }
  io.println("")
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
  let file_segments =
    input.segments
    |> list.filter(fn(segment) {
      case segment {
        FreeSeg(..) -> False
        FileSeg(..) -> True
      }
    })
    |> list.reverse
  {
    use acc, segment <- list.fold(file_segments, input.segments)
    // print_segments(acc)
    let #(before, after) = cut_before(acc, segment)
    case move(before, segment) {
      Ok(before) -> {
        let assert Ok(after) = list.rest(after)
        list.append(before, [FreeSeg(size: segment.size), ..after])
      }
      Error(_) -> acc
    }
    |> consolidate_free
  }
  |> segments_to_blocks
  |> yielder.index
  |> yielder.filter_map(fn(i_block) {
    let #(block, i) = i_block
    case block {
      File(id) -> Ok(#(id, i))
      Free -> Error(Nil)
    }
  })
  |> checksum
}

fn consolidate_free(segments: List(Segment)) {
  case segments {
    [] -> []
    [FreeSeg(size: size), FreeSeg(size: size2), ..rest] ->
      consolidate_free([FreeSeg(size: size + size2), ..rest])
    [any, ..rest] -> [any, ..consolidate_free(rest)]
  }
}

fn cut_before(segments: List(Segment), file: Segment) {
  case file {
    FreeSeg(..) -> panic as "free segments have no identifiers"
    FileSeg(..) -> {
      use segment <- list.split_while(segments)
      case segment {
        FileSeg(id: id, ..) if id == file.id -> False
        _ -> True
      }
    }
  }
}

fn move(segments: List(Segment), file: Segment) -> Result(List(Segment), _) {
  case file {
    FreeSeg(..) -> panic as "cannot move free segment"
    FileSeg(..) ->
      case segments {
        [] -> Error("segment not found")
        [FileSeg(..) as old, ..rest] ->
          move(rest, file)
          |> result.try(fn(rest) { Ok([old, ..rest]) })
        [FreeSeg(size: free_size), ..rest] -> {
          case int.compare(file.size, free_size) {
            Eq -> Ok([file, ..rest])
            Gt ->
              move(rest, file)
              |> result.try(fn(rest) { Ok([FreeSeg(size: free_size), ..rest]) })
            Lt -> Ok([file, FreeSeg(size: free_size - file.size), ..rest])
          }
        }
      }
  }
}
