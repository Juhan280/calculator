use std::io;

use lexer::Token;
use parser::{Oparand, Tree};

mod lexer;
mod parser;

fn main() {
	let mut last_result = 0.0;

	eprint!("> ");
	for line in io::stdin().lines() {
		let source = line.unwrap();
		if source.trim().is_empty() {
			eprint!("> ");
			continue;
		}

		let mut lexed = lexer::lex(&source);
		let parsed = parser::parse(&mut lexed);
		match parsed {
			Err(token) => {
				print_error(token, source.len());
			}
			Ok(parsed) => {
				last_result = evaluate(parsed, last_result);
				print_ans(last_result);
			}
		};
		eprint!("> ");
	}
	print!("\r");
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

fn print_ans(num: f64) {
	println!("\x1b[38;5;138m{}\x1b[0m", num.to_string())
}

fn print_error(token: Token, len: usize) {
	let padding = " ".repeat(token.index(len) + 2);
	match token {
		Token::EOE(_) => eprintln!("{padding}^\n  Unexpected end of input: Expexted closing RParen"),
		_ => eprintln!("{padding}^\n{padding}Invalid Token: {:?}", token),
	}
}
