import gleam/iterator.{type Iterator, Done, Next}
import gleam/list
import gleam/result
import lexer.{
  type Token, Asterisk, Caret, EOE, Float as TFloat, Integer as TInteger, LParen,
  Minus, Plus, RParen, Slash, Underscore,
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
  Integer(String)
  Float(String)
  LastResult
}

pub fn parse(tokens: Iterator(Token)) -> Result(Tree, Token) {
  use #(tree, tokens) <- result.try(expression(tokens))

  case iterator.first(tokens) {
    Error(Nil) -> Ok(tree)
    Ok(token) -> Error(token)
  }
}

/// expression ::= term {( "-" | "+" ) term}
/// expression ::= expression {( "-" | "+" ) term | term
fn expression(tokens: Iterator(Token)) {
  use #(tree, tokens) <- result.try(term(tokens))

  repeat(tree, tokens, [Plus(-1), Minus(-1)], term)
  // case iterator.step(tokens) {
  //   Next(Plus(_), tokens) -> {
  //     use #(new_tree, tokens) <- result.try(term(tokens))
  //
  //     Ok(#(Operation(Add, tree, new_tree), tokens))
  //   }
  //   _ -> Ok(#(tree, tokens))
  // }
}

/// term ::= powered {( "/" | "*" ) powered}
/// term ::= term ( "/" | "*" ) powered | powered
fn term(tokens: Iterator(Token)) {
  use #(tree, tokens) <- result.try(powered(tokens))

  repeat(tree, tokens, [Asterisk(-1), Slash(-1)], powered)
}

/// powered ::= unary "^" powered | unary 
fn powered(tokens: Iterator(Token)) {
  use #(tree, tokens) <- result.try(unary(tokens))

  case iterator.step(tokens) {
    Next(Caret(_), tokens) -> {
      use #(new_tree, tokens) <- result.try(powered(tokens))

      Ok(#(Operation(Pow, tree, new_tree), tokens))
    }
    _ -> Ok(#(tree, tokens))
  }
}

/// unary ::= ["+" | "-"] number
fn unary(tokens: Iterator(Token)) {
  use _ <- result.try_recover(number(tokens))
  case iterator.step(tokens) {
    Next(Plus(_), tokens) -> number(tokens)
    Next(Minus(_), tokens) -> {
      use #(tree, tokens) <- result.try(number(tokens))

      Ok(#(Operation(Sub, Float("0.0"), tree), tokens))
    }
    Next(token, _) -> Error(token)
    Done -> Error(EOE)
  }
}

/// number ::= int | float | last_result | "(" expression ")"
fn number(tokens: Iterator(Token)) {
  case iterator.step(tokens) {
    Next(TInteger(int, _), tokens) -> Ok(#(Integer(int), tokens))
    Next(TFloat(float, _), tokens) -> Ok(#(Float(float), tokens))
    Next(Underscore(_), tokens) -> Ok(#(LastResult, tokens))
    Next(LParen(_), tokens) -> {
      use #(tree, tokens) <- result.try(expression(tokens))
      case iterator.step(tokens) {
        Next(RParen(_), tokens) -> Ok(#(tree, tokens))
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
