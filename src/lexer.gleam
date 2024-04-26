import gleam/iterator.{type Iterator, Done, Next}
import gleam/regex
import gleam/string

pub type Token {
  Integer(value: String, index: Int)
  Float(value: String, index: Int)

  Plus(index: Int)
  Minus(index: Int)
  Asterisk(index: Int)
  Slash(index: Int)
  Caret(index: Int)

  Underscore(index: Int)
  LParen(index: Int)
  RParen(index: Int)

  EOE
  Invalid(index: Int)
}

pub fn lex(source: String) -> Iterator(Token) {
  use #(buffer, offset) <- iterator.unfold(#(source, 0))
  case get_token(buffer, offset) {
    #(EOE, _, _) -> Done
    #(token, rest, index) -> Next(token, #(rest, index))
  }
}

fn get_token(old_buffer: String, offset: Int) -> #(Token, String, Int) {
  let buffer = string.trim_left(old_buffer)
  let index = offset + string.length(old_buffer) - string.length(buffer)

  case buffer {
    "+" <> rest -> #(Plus(index), rest, index + 1)
    "-" <> rest -> #(Minus(index), rest, index + 1)
    "*" <> rest -> #(Asterisk(index), rest, index + 1)
    "/" <> rest -> #(Slash(index), rest, index + 1)
    "^" <> rest -> #(Caret(index), rest, index + 1)

    "_" <> rest -> #(Underscore(index), rest, index + 1)
    "(" <> rest -> #(LParen(index), rest, index + 1)
    ")" <> rest -> #(RParen(index), rest, index + 1)

    "0" <> _
    | "1" <> _
    | "2" <> _
    | "3" <> _
    | "4" <> _
    | "5" <> _
    | "6" <> _
    | "7" <> _
    | "8" <> _
    | "9" <> _ -> {
      let assert Ok(re) = regex.from_string("^\\d+(\\.\\d+)?")
      let assert [match, ..] = regex.scan(re, buffer)

      let content = match.content
      let length = string.length(content)
      let rest = string.drop_left(buffer, length)

      case match.submatches {
        [] -> #(Integer(content, index), rest, index + length)
        _ -> #(Float(content, index), rest, index + length)
      }
    }

    "" -> #(EOE, "", index + 1)
    _ -> #(Invalid(index), "", index + 1)
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

    Underscore(index) -> index
    LParen(index) -> index
    RParen(index) -> index

    Invalid(index) -> index
    EOE -> -1
  }
}
