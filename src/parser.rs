use std::iter::Peekable;

use crate::lexer::Token;

#[derive(Debug)]
pub enum Oparand {
	Add,
	Sub,
	Mul,
	Div,
	Pow,
}

#[derive(Debug)]
pub enum Tree {
	Operation(Oparand, Box<Tree>, Box<Tree>),
	Integer(String),
	Float(String),
	LastResult,
}

pub fn parse(tokens: &mut impl Iterator<Item = Token>) -> Result<Tree, Token> {
	let mut tokens = tokens.peekable();
	let tree = expression(&mut tokens)?;

	match tokens.next() {
		None => Ok(tree),
		Some(token) => Err(token),
	}
}

/// expression ::= term {( "-" | "+" ) term}
fn expression(tokens: &mut Peekable<impl Iterator<Item = Token>>) -> Result<Tree, Token> {
	let mut tree = term(tokens)?;

	while let Some(token) = tokens.peek() {
		match token {
			Token::Plus(_) => {
				tokens.next();
				let new_tree = term(tokens)?;
				tree = Tree::Operation(Oparand::Add, Box::new(tree), Box::new(new_tree))
			}
			Token::Minus(_) => {
				tokens.next();
				let new_tree = term(tokens)?;
				tree = Tree::Operation(Oparand::Sub, Box::new(tree), Box::new(new_tree))
			}
			_ => break,
		}
	}
	Ok(tree)
}

/// term ::= powered {( "/" | "*" ) powered}
fn term(tokens: &mut Peekable<impl Iterator<Item = Token>>) -> Result<Tree, Token> {
	let mut tree = powered(tokens)?;

	while let Some(token) = tokens.peek() {
		match token {
			Token::Asterisk(_) => {
				tokens.next();
				let new_tree = powered(tokens)?;
				tree = Tree::Operation(Oparand::Mul, Box::new(tree), Box::new(new_tree))
			}
			Token::Slash(_) => {
				tokens.next();
				let new_tree = powered(tokens)?;
				tree = Tree::Operation(Oparand::Div, Box::new(tree), Box::new(new_tree))
			}
			_ => break,
		}
	}
	Ok(tree)
}

/// powered ::= juxtaposed [ "^" powered ]
fn powered(tokens: &mut Peekable<impl Iterator<Item = Token>>) -> Result<Tree, Token> {
	let tree = juxtaposed(tokens)?;

	match tokens.peek() {
		Some(Token::Caret(_)) => {
			tokens.next();
			let new_tree = powered(tokens)?;
			Ok(Tree::Operation(
				Oparand::Pow,
				Box::new(tree),
				Box::new(new_tree),
			))
		}
		_ => Ok(tree),
	}
}

/// juxtaposed ::= unary [ "(" expression ")" ]
fn juxtaposed(tokens: &mut Peekable<impl Iterator<Item = Token>>) -> Result<Tree, Token> {
	let tree = unary(tokens)?;

	match tokens.peek() {
		Some(Token::LParen(i)) => {
			let i = *i;
			tokens.next();
			let new_tree = expression(tokens)?;
			match tokens.next() {
				Some(Token::RParen(_)) => Ok(Tree::Operation(
					Oparand::Mul,
					Box::new(tree),
					Box::new(new_tree),
				)),
				Some(token) => Err(token),
				None => Err(Token::EOE(Some(i))),
			}
		}
		_ => Ok(tree),
	}
}

/// unary ::= ["+" | "-"] number
fn unary(tokens: &mut Peekable<impl Iterator<Item = Token>>) -> Result<Tree, Token> {
	number(tokens).or_else(|token| match token {
		Token::Plus(_) => number(tokens),
		Token::Minus(_) => {
			let token = number(tokens)?;
			Ok(Tree::Operation(
				Oparand::Sub,
				Box::new(Tree::Float("0.0".into())),
				Box::new(token),
			))
		}
		token => Err(token),
	})
}

/// number ::= int | float | last_result | "(" expression ")"
fn number(tokens: &mut Peekable<impl Iterator<Item = Token>>) -> Result<Tree, Token> {
	match tokens.next() {
		Some(Token::Underscore(_)) => Ok(Tree::LastResult),
		Some(Token::Integer(int, _)) => Ok(Tree::Integer(int)),
		Some(Token::Float(int, _)) => Ok(Tree::Float(int)),
		Some(Token::LParen(i)) => {
			let tree = expression(tokens)?;
			match tokens.next() {
				Some(Token::RParen(_)) => Ok(tree),
				Some(token) => Err(token),
				None => Err(Token::EOE(Some(i))),
			}
		}
		Some(token) => Err(token),
		None => Err(Token::EOE(None)),
	}
}
