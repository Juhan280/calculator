use lexer::Token;
use parser::{Oparand, Tree};

mod lexer;
mod parser;

fn main() {
	let a = "(((1+(23*2))-(78.9/6))+1)";

	let mut lexed = lexer::lex(a);
	let parsed = dbg!(parser::parse(&mut lexed)).unwrap();
	let _res = dbg!(evaluate(parsed, 0.));
}

fn evaluate(tree: Tree, last_result: f64) -> Result<f64, bool> {
	match tree {
		Tree::Integer(str) => Ok(parse_int_f(&str)),
		Tree::Float(str) => Ok(parse_float_f(&str)),
		Tree::LastResult => Ok(last_result),
		Tree::Operation(op, left, right) => {
			let left = evaluate(*left, last_result)?;
			let right = evaluate(*right, last_result)?;

			match op {
				Oparand::Add => Ok(left + right),
				Oparand::Sub => Ok(left - right),
				Oparand::Mul => Ok(left * right),
				Oparand::Div => Ok(left / right),
				Oparand::Pow => Ok(left.powf(right)),
			}
		}
	}
}

fn parse_int_f(str: &str) -> f64 {
	str.as_bytes()
		.iter()
		.fold(0u32, |acc, x| acc * 10 + x.to_owned() as u32 - 0x30) as _
}

fn parse_float_f(str: &str) -> f64 {
	let (int_s, float_s) = str.split_once(".").unwrap();

	let int_f = parse_int_f(int_s);
	let float_f = float_s
		.as_bytes()
		.iter()
		.rev()
		.fold(0., |acc, x| (acc + (x - 0x30) as f64) / 10.);

	int_f + float_f
}

fn print_ans(num: f64) {
	println!("\x1b[38;5;138m{}\x1b[0m", num.to_string())
}

fn print_error(token: Token) {
	let padding = " ".repeat(token.index() as usize + 2);
	eprintln!("{}^\n{}Invalid Token", padding, padding)
}
