import gleam/float
import gleam/int
import gleam/iterator.{type Iterator, Done, Next}
import gleam/regex
import gleam/string

pub type Token {
  Integer(value: Int, index: Int)
  Float(value: Float, index: Int)

  Plus(index: Int)
  Minus(index: Int)
  Asterisk(index: Int)
  Slash(index: Int)
  Caret(index: Int)

  LParen(index: Int)
  RParen(index: Int)

  EOE
  Invalid(index: Int)
}

pub fn lex(source: String) -> Iterator(Token) {
  use #(buffer, index) <- iterator.unfold(#(source, 0))
  case get_token(buffer, index) {
    #(EOE, _, _) -> Done
    #(token, rest, index) -> Next(token, #(rest, index))
  }
}

fn get_token(old_buffer: String, index: Int) -> #(Token, String, Int) {
  let buffer = string.trim_left(old_buffer)
  let index = index + string.length(old_buffer) - string.length(buffer)

  case string.pop_grapheme(buffer) {
    Ok(#(ch, rest)) if ch == "+" -> #(Plus(index), rest, index + 1)
    Ok(#(ch, rest)) if ch == "-" -> #(Minus(index), rest, index + 1)
    Ok(#(ch, rest)) if ch == "*" -> #(Asterisk(index), rest, index + 1)
    Ok(#(ch, rest)) if ch == "/" -> #(Slash(index), rest, index + 1)
    Ok(#(ch, rest)) if ch == "^" -> #(Caret(index), rest, index + 1)

    Ok(#(ch, rest)) if ch == "(" -> #(LParen(index), rest, index + 1)
    Ok(#(ch, rest)) if ch == ")" -> #(RParen(index), rest, index + 1)

    Ok(#(ch, _)) if ch == "0"
      || ch == "1"
      || ch == "2"
      || ch == "3"
      || ch == "4"
      || ch == "5"
      || ch == "6"
      || ch == "7"
      || ch == "8"
      || ch == "9" -> {
      let assert Ok(re) = regex.from_string("^\\d+(\\.\\d+)?")
      let assert [match, ..] = regex.scan(re, buffer)

      let content = match.content
      let length = string.length(content)
      let rest = string.drop_left(buffer, length)

      case match.submatches {
        [] -> {
          let assert Ok(int) = int.parse(content)
          #(Integer(int, index), rest, index + length)
        }
        _ -> {
          let assert Ok(float) = float.parse(content)
          #(Float(float, index), rest, index + length)
        }
      }
    }

    Ok(#(_, rest)) -> #(Invalid(index), rest, index + 1)
    Error(_) -> #(EOE, "", index + 1)
  }
}

pub fn token_index(token: Token) {
  case token {
    Integer(_, index) -> index
    Float(_, index) -> index

    Plus(index) -> index
    Minus(index) -> index
    Asterisk(index) -> index
    Slash(index) -> index
    Caret(index) -> index

    LParen(index) -> index
    RParen(index) -> index

    Invalid(index) -> index
    EOE -> -1
  }
}
