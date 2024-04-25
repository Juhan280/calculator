import gleam/bool.{guard}
import gleam/erlang
import gleam/float
import gleam/io
import gleam/result
import lexer
import parser.{type Tree, Add, Div, Group, Mul, Number, Operation, Pow, Sub}

type CalculationError {
  DivisionByZero
  ComplexNumber
}

pub fn main() {
  loop()
}

fn loop() {
  let assert Ok(source) = erlang.get_line("> ")

  // io.debug(source)
  {
    use <- guard(source == "\n", Nil)

    let tree =
      lexer.lex(source)
      |> parser.parse

    case tree {
      Ok(tree) -> {
        // io.debug(tree)

        case evaluate(tree) {
          Ok(ans) -> {
            ans
            |> io.debug

            Nil
          }
          Error(err) -> {
            err
            |> io.debug

            Nil
          }
        }
      }
      Error(Nil) -> io.println_error("Invalid token")
    }
  }
  loop()
}

fn evaluate(tree: Tree) {
  case tree {
    Number(n) -> Ok(n)
    Operation(op, left, right) -> {
      use left <- result.try(evaluate(left))
      use right <- result.try(evaluate(right))

      case op {
        Add -> Ok(left +. right)
        Sub -> Ok(left -. right)
        Mul -> Ok(left *. right)
        Div ->
          float.divide(left, right)
          |> result.replace_error(DivisionByZero)
        Pow ->
          float.power(left, right)
          |> result.replace_error(ComplexNumber)
      }
    }
    Group(tree) -> evaluate(tree)
  }
}
