use std::iter::Iterator;

#[derive(Debug)]
pub enum Token {
	Integer(String, i32),
	Float(String, i32),

	Plus(i32),
	Minus(i32),
	Asterisk(i32),
	Slash(i32),
	Caret(i32),

	Underscore(i32),
	LParen(i32),
	RParen(i32),

	EOE,
	Invalid(i32),
}

impl Token {
	pub const fn index(&self) -> i32 {
		match self {
			Token::Integer(_, i) => *i,
			Token::Float(_, i) => *i,

			Token::Plus(i) => *i,
			Token::Minus(i) => *i,
			Token::Asterisk(i) => *i,
			Token::Slash(i) => *i,
			Token::Caret(i) => *i,

			Token::Underscore(i) => *i,
			Token::LParen(i) => *i,
			Token::RParen(i) => *i,

			Token::EOE => -1,
			Token::Invalid(i) => *i,
		}
	}
}

pub fn lex(source: &str) -> impl Iterator<Item = Token> {
	let mut tokens = vec![];
	let mut i = 0;
	let mut chars = source.chars().peekable();

	while let Some(char) = chars.next() {
		match char {
			' ' | '\t' => i += 1,

			'+' => tokens.push(Token::Plus(inc(&mut i))),
			'-' => tokens.push(Token::Minus(inc(&mut i))),
			'*' | '×' => tokens.push(Token::Asterisk(inc(&mut i))),
			'/' => tokens.push(Token::Slash(inc(&mut i))),
			'^' => tokens.push(Token::Caret(inc(&mut i))),

			'_' => tokens.push(Token::Underscore(inc(&mut i))),
			'(' => tokens.push(Token::LParen(inc(&mut i))),
			')' => tokens.push(Token::RParen(inc(&mut i))),

			'0'..='9' => {
				let j = i;
				let mut str = char.to_string();

				i += 1;
				while let Some('0'..='9') = chars.peek() {
					str.push(chars.next().unwrap());
					i += 1;
				}

				let peek = chars.peek();
				if peek != Some(&'.') || peek == None {
					tokens.push(Token::Integer(str, j));
					continue;
				}
				str.push(chars.next().unwrap());

				i += 1;
				while let Some('0'..='9') = chars.peek() {
					str.push(chars.next().unwrap());
					i += 1;
				}
				tokens.push(Token::Float(str, j));
			}

			_ => {
				tokens.push(Token::Invalid(inc(&mut i)));
				break;
			}
		}
	}

	tokens.into_iter()
}

fn inc(i: &mut i32) -> i32 {
	let j = i.to_owned();
	*i += 1;
	j
}
