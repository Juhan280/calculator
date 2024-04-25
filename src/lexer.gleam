import gleam/float
import gleam/int
import gleam/iterator.{type Iterator, Done, Next}
import gleam/regex
import gleam/string

pub type Token {
  Integer(Int)
  Float(Float)

  Plus
  Minus
  Asterisk
  Slash
  Caret

  LParen
  RParen

  EOE
  Invalid
}

pub fn lex(source: String) -> Iterator(Token) {
  iterator.unfold(source, fn(buffer) {
    case get_token(buffer) {
      #(EOE, _) -> Done
      #(token, rest) -> Next(token, rest)
    }
  })
}

fn get_token(buffer: String) -> #(Token, String) {
  let buffer = string.trim_left(buffer)
  case string.pop_grapheme(buffer) {
    Ok(#(ch, rest)) if ch == "+" -> #(Plus, rest)
    Ok(#(ch, rest)) if ch == "-" -> #(Minus, rest)
    Ok(#(ch, rest)) if ch == "*" -> #(Asterisk, rest)
    Ok(#(ch, rest)) if ch == "/" -> #(Slash, rest)
    Ok(#(ch, rest)) if ch == "^" -> #(Caret, rest)

    Ok(#(ch, rest)) if ch == "(" -> #(LParen, rest)
    Ok(#(ch, rest)) if ch == ")" -> #(RParen, rest)

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
      let rest =
        string.length(content)
        |> string.drop_left(buffer, _)
      case match.submatches {
        [] -> {
          let assert Ok(int) = int.parse(content)
          #(Integer(int), rest)
        }
        _ -> {
          let assert Ok(float) = float.parse(content)
          #(Float(float), rest)
        }
      }
    }

    Ok(#(_, _)) -> #(Invalid, "")
    Error(_) -> #(EOE, "")
  }
}
