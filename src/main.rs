use std::io::{self, IsTerminal};

use lexer::Token;
use parser::{Oparand, Tree};

mod lexer;
mod parser;

fn main() {
	let mut last_result = 0.0;
	let is_tty_in = io::stdin().is_terminal();
	let is_tty_out = io::stdout().is_terminal();

	prompt(is_tty_in);
	for line in io::stdin().lines() {
		let source = line.unwrap();
		if source.trim().is_empty() {
			prompt(is_tty_in);
			continue;
		}

		let mut lexed = lexer::lex(&source);
		let parsed = parser::parse(&mut lexed);
		match parsed {
			Err(token) => {
				print_error(is_tty_in, token, source.len());
			}
			Ok(parsed) => {
				last_result = evaluate(parsed, last_result);
				print_ans(is_tty_out, last_result);
			}
		};
		prompt(is_tty_in);
	}
	if is_tty_in {
		eprint!("\r");
	}
}

fn evaluate(tree: Tree, last_result: f64) -> f64 {
	match tree {
		Tree::Integer(str) | Tree::Float(str) => parse(&str),
		Tree::LastResult => last_result,
		Tree::Operation(op, left, right) => {
			let left = evaluate(*left, last_result);
			let right = evaluate(*right, last_result);

			match op {
				Oparand::Add => left + right,
				Oparand::Sub => left - right,
				Oparand::Mul => left * right,
				Oparand::Div => left / right,
				Oparand::Pow => left.powf(right),
			}
		}
	}
}

fn parse(str: &str) -> f64 {
	str.parse::<f64>()
		.expect("this should already be validated by the lexer")
}

fn prompt(is_tty: bool) {
	if is_tty {
		eprint!("> ");
	}
}

fn print_ans(is_tty: bool, num: f64) {
	let ans = num.to_string();
	match is_tty {
		true => println!("\x1b[33m{ans}\x1b[0m"),
		false => println!("{ans}"),
	}
}

fn print_error(is_tty: bool, token: Token, len: usize) {
	if !is_tty {
		return;
	}

	let padding = " ".repeat(token.index(len) + 2);
	match token {
		Token::EOE(o) => {
			let default = format!("\x1b[31m{padding}^\n  Unexpected end of input");
			match o {
				Some(i) if i != len => eprintln!("{default}: Expexted closing RParen\x1b[0m"),
				_ => eprintln!("{default}\x1b[0m"),
			}
		}
		_ => eprintln!(
			"\x1b[31m{padding}^\n{padding}Invalid Token: {:?}\x1b[0m",
			token
		),
	}
}
