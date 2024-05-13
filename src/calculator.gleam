import exception
import gleam/bool.{guard}
import gleam/erlang
import gleam/float
import gleam/int
import gleam/io
import gleam/result
import gleam/string
import lexer
import parser.{
  type Tree, Add, Div, Float, Integer, LastResult, Mul, Operation, Pow, Sub,
}

type CalculationError {
  DivisionByZero
  ComplexNumber
  NumberTooLarge
}

pub fn main() {
  loop(0.0)
}

fn loop(last_result: Float) {
  use source <- result.then(
    erlang.get_line("> ")
    |> result.map_error(fn(_) { io.print("\r") }),
  )

  let last_result = {
    use <- guard(source == "\n", last_result)

    let tree =
      lexer.lex(source)
      |> parser.parse

    case tree {
      Ok(tree) -> {
        // io.debug(tree)

        case evaluate(tree, last_result) {
          Ok(ans) -> print_ans(ans)

          Error(err) -> {
            io.debug(err)

            last_result
          }
        }
      }
      Error(token) -> {
        let padding = string.repeat(" ", lexer.token_index(token) + 2)
        io.println_error(padding <> "^\n" <> padding <> "Invalid Token")

        last_result
      }
    }
  }
  loop(last_result)
}

fn evaluate(tree: Tree, last_result: Float) {
  case tree {
    Integer(int) -> {
      let assert Ok(int) = int.parse(int)
      // int.to_float fails if the int is too large to fit in a float
      exception.rescue(fn() { Ok(int.to_float(int)) })
      |> result.unwrap(Error(NumberTooLarge))
    }
    Float(float) ->
      float.parse(float)
      |> result.replace_error(NumberTooLarge)

    LastResult -> Ok(last_result)
    Operation(op, left, right) -> {
      use left <- result.try(evaluate(left, last_result))
      use right <- result.try(evaluate(right, last_result))

      case op {
        Add -> Ok(left +. right)
        Sub -> Ok(left -. right)
        Mul -> Ok(left *. right)
        Div ->
          float.divide(left, right)
          |> result.replace_error(DivisionByZero)
        Pow ->
          exception.rescue(fn() {
            float.power(left, right)
            |> result.map_error(fn(_) {
              case left == 0.0 && right <. 0.0 {
                True -> DivisionByZero
                False -> ComplexNumber
              }
            })
          })
          |> result.unwrap(Error(NumberTooLarge))
      }
    }
  }
}

fn print_ans(num: Float) {
  io.println("\u{1b}[38;5;138m" <> float.to_string(num) <> "\u{1b}[0m")
  num
}
