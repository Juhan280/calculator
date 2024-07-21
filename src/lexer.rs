use std::iter::{self, Iterator};

#[derive(Debug)]
pub enum Token {
	Integer(String, usize),
	Float(String, usize),

	Plus(usize),
	Minus(usize),
	Asterisk(usize),
	Slash(usize),
	Caret(usize),

	Underscore(usize),
	LParen(usize),
	RParen(usize),

	// TODO: visit https://rust-lang.github.io/rust-clippy/master/index.html#upper_case_acronyms
	EOE(Option<usize>),
	Unknown(usize),
}

impl Token {
	pub const fn index(&self, length: usize) -> usize {
		match self {
			Token::Integer(_, i)
			| Token::Float(_, i)
			| Token::Plus(i)
			| Token::Minus(i)
			| Token::Asterisk(i)
			| Token::Slash(i)
			| Token::Caret(i)
			| Token::Underscore(i)
			| Token::LParen(i)
			| Token::RParen(i)
			| Token::Unknown(i)
			| Token::EOE(Some(i)) => *i,
			Token::EOE(None) => length - 1,
		}
	}
}

pub fn lex(source: &str) -> impl Iterator<Item = Token> + Clone + '_ {
	let mut chars = source.chars().enumerate().peekable();

	iter::from_fn(move || {
		while let Some(&(_, ' ' | '\t')) = chars.peek() {
			chars.next();
		}

		let (i, char) = chars.next()?;
		match char {
			'+' => Some(Token::Plus(i)),
			'-' => Some(Token::Minus(i)),
			'*' | '×' => Some(Token::Asterisk(i)),
			'/' => Some(Token::Slash(i)),
			'^' => Some(Token::Caret(i)),

			'_' => Some(Token::Underscore(i)),
			'(' => Some(Token::LParen(i)),
			')' => Some(Token::RParen(i)),

			'0'..='9' => {
				let mut str = char.to_string();

        // Accumulate all the trailing digits in `str`
				while let Some(&(_, '0'..='9')) = chars.peek() {
					str.push(chars.next().unwrap().1);
				}

        // If the next char is not '.', then return Integer
				match chars.peek() {
					Some((_, '.')) => (),
					_ => return Some(Token::Integer(str, i)),
				}

				str.push(chars.next().expect("this should be a '.'").1);

        // Accumulate all the trailing digits in `str`
				while let Some(&(_, '0'..='9')) = chars.peek() {
					str.push(chars.next().unwrap().1);
				}
				Some(Token::Float(str, i))
			}
			'.' => {
				let mut str = char.to_string();

        // If the next char is not a digit, then return Invalid
				match chars.peek() {
					Some((_, '0'..='9')) => (),
					_ => return Some(Token::Unknown(i)),
				}

        // Accumulate all the trailing digits in `str`
				while let Some(&(_, '0'..='9')) = chars.peek() {
					str.push(chars.next().unwrap().1);
				}
				Some(Token::Float(str, i))
			}

			_ => Some(Token::Unknown(i)),
		}
	})
}
