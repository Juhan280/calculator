import gleam/int
import gleam/iterator.{type Iterator, Done, Next}
import gleam/list
import gleam/result
import lexer.{
  type Token, Asterisk, Caret, EOE, Float as TFloat, Integer as TInteger, LParen,
  Minus, Plus, RParen, Slash,
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

pub fn parse(tokens: Iterator(Token)) -> Result(Tree, Token) {
  use #(tree, tokens) <- result.try(expression(tokens))

  case iterator.first(tokens) {
    Error(Nil) -> Ok(tree)
    Ok(token) -> Error(token)
  }
}

/// expression ::= term {( "-" | "+" ) term}
fn expression(tokens: Iterator(Token)) {
  use #(tree, tokens) <- result.try(term(tokens))

  repeat(tree, tokens, [Plus(-1), Minus(-1)], term)
}

/// term ::= unary {( "/" | "*" ) unary}
fn term(tokens: Iterator(Token)) {
  use #(tree, tokens) <- result.try(unary(tokens))

  repeat(tree, tokens, [Asterisk(-1), Slash(-1)], unary)
}

/// unary ::= ["+" | "-"] number
fn unary(tokens: Iterator(Token)) {
  use _ <- result.try_recover(powered(tokens))
  case iterator.step(tokens) {
    Next(Plus(_), tokens) -> powered(tokens)
    Next(Minus(_), tokens) -> {
      use #(tree, tokens) <- result.try(powered(tokens))

      Ok(#(Operation(Sub, Number(0.0), tree), tokens))
    }
    Next(token, _) -> Error(token)
    Done -> Error(EOE)
  }
}

/// powered ::= number { "^" number }
fn powered(tokens: Iterator(Token)) {
  use #(tree, tokens) <- result.try(number(tokens))
  use #(tree, tokens) <- result.try(repeat(tree, tokens, [Caret(-1)], number))

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
    Next(TInteger(int, _), tokens) -> {
      let float = int.to_float(int)
      Ok(#(Number(float), tokens))
    }
    Next(TFloat(float, _), tokens) -> {
      Ok(#(Number(float), tokens))
    }
    Next(LParen(_), tokens) -> {
      use #(tree, tokens) <- result.try(expression(tokens))
      case iterator.step(tokens) {
        Next(RParen(_), tokens) -> Ok(#(Group(tree), tokens))
        Next(token, _) -> Error(token)
        Done -> Error(EOE)
      }
    }
    Next(token, _) -> Error(token)
    Done -> Error(EOE)
  }
}

fn op_from_token(token: Token) {
  case token {
    Plus(_) -> Ok(Add)
    Minus(_) -> Ok(Sub)
    Asterisk(_) -> Ok(Mul)
    Slash(_) -> Ok(Div)
    Caret(_) -> Ok(Pow)

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
      case
        list.any(ops, fn(op) {
          case op, token {
            Plus(_), Plus(_)
            | Minus(_), Minus(_)
            | Asterisk(_), Asterisk(_)
            | Slash(_), Slash(_)
            | Caret(_), Caret(_)
            -> True
            _, _ -> False
          }
        })
      {
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
