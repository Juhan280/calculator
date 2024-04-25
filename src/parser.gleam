import gleam/int
import gleam/io
import gleam/iterator.{type Iterator, Done, Next}
import gleam/list
import gleam/result
import lexer.{
  type Token, Asterisk, Caret, Float as TFloat, Integer as TInteger,
  Invalid as TInvalid, LParen, Minus, Plus, RParen, Slash,
}

pub type Operand {
  Add
  Sub
  Mul
  Div
  Pow
}

pub type Tree {
  Operation(operand: Operand, left: Tree, right: Tree)
  Number(Float)
  Group(Tree)
}

/// it should return Result(Tree, Int)
pub fn parse(tokens: Iterator(Token)) {
  use #(tree, tokens) <- result.try(
    expression(tokens)
    |> result.nil_error,
  )

  case iterator.first(tokens) {
    Error(Nil) -> Ok(tree)
    Ok(TInvalid) -> Error(Nil)
    Ok(t) -> {
      io.print("found token")
      io.debug(t)
      panic as "this might be some edge case i am unware of"
    }
  }
}

/// expression ::= term {( "-" | "+" ) term}
fn expression(tokens: Iterator(Token)) {
  use #(tree, tokens) <- result.try(term(tokens))

  repeat(tree, tokens, [Plus, Minus], term)
}

/// term ::= unary {( "/" | "*" ) unary}
fn term(tokens: Iterator(Token)) {
  use #(tree, tokens) <- result.try(unary(tokens))

  repeat(tree, tokens, [Asterisk, Slash], unary)
}

/// unary ::= ["+" | "-"] number
fn unary(tokens: Iterator(Token)) {
  use _ <- result.try_recover(powered(tokens))
  case iterator.step(tokens) {
    Next(Plus, tokens) -> powered(tokens)
    Next(Minus, tokens) -> {
      use #(tree, tokens) <- result.try(powered(tokens))

      Ok(#(Operation(Sub, Number(0.0), tree), tokens))
    }
    Next(token, _) -> Error(token)
    Done -> Error(TInvalid)
  }
}

/// powered ::= number { "^" number }
fn powered(tokens: Iterator(Token)) {
  use #(tree, tokens) <- result.try(number(tokens))
  use #(tree, tokens) <- result.try(repeat(tree, tokens, [Caret], number))

  case tree {
    // for power the right most term has higher precedence
    Operation(Pow, left, right) -> {
      Ok(#(reverse_tree(left, right), tokens))
    }
    _ -> Ok(#(tree, tokens))
  }
}

/// number ::= int | float | "(" expression ")"
fn number(tokens: Iterator(Token)) {
  case iterator.step(tokens) {
    Next(TInteger(int), tokens) -> {
      let float = int.to_float(int)
      Ok(#(Number(float), tokens))
    }
    Next(TFloat(float), tokens) -> {
      Ok(#(Number(float), tokens))
    }
    Next(LParen, tokens) -> {
      use #(tree, tokens) <- result.try(expression(tokens))
      case iterator.step(tokens) {
        Next(RParen, tokens) -> Ok(#(Group(tree), tokens))
        Next(token, _) -> Error(token)
        Done -> Error(TInvalid)
      }
    }
    _ -> Error(TInvalid)
  }
}

fn op_from_token(token: Token) {
  case token {
    Plus -> Ok(Add)
    Minus -> Ok(Sub)
    Asterisk -> Ok(Mul)
    Slash -> Ok(Div)
    Caret -> Ok(Pow)

    _ -> Error(Nil)
  }
}

fn reverse_tree(tree: Tree, new_tree: Tree) -> Tree {
  case tree {
    Operation(op, left, right) -> {
      Operation(op, right, new_tree)
      |> reverse_tree(left, _)
    }
    _ -> Operation(Pow, tree, new_tree)
  }
}

fn repeat(
  tree: Tree,
  tokens: Iterator(Token),
  ops: List(Token),
  func: fn(Iterator(Token)) -> Result(#(Tree, Iterator(Token)), Token),
) {
  case iterator.step(tokens) {
    Next(token, next_tokens) ->
      case list.any(ops, fn(op) { op == token }) {
        True -> {
          use #(new_tree, tokens) <- result.try(func(next_tokens))
          let assert Ok(op) = op_from_token(token)

          Operation(op, tree, new_tree)
          |> repeat(tokens, ops, func)
        }
        False -> Ok(#(tree, tokens))
      }
    Done -> Ok(#(tree, tokens))
  }
}
