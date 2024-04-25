import gleam/erlang
import gleam/float
import gleam/io
import gleam/result
import lexer
import parser.{type Tree, Add, Div, Leaf, Mul, Node, Pow, Sub}

type CalculationError {
  DivisionByZero
  ComplexNumber
}

pub fn main() {
  let assert Ok(source) = erlang.get_line("> ")

  case
    lexer.lex(source)
    |> parser.parse
  {
    Ok(tree) ->
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
    Error(Nil) -> io.println_error("Invalid token")
  }

  main()
}

fn evaluate(tree: Tree) {
  case tree {
    Leaf(n) -> Ok(n)
    Node(op, left, right) -> {
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
  }
}
