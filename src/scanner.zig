const std = @import("std");

const Allocator = std.mem.Allocator;

fn isDigit(char: u8) bool {
    return char >= '0' and char <= '9';
}

fn isAlpha(char: u8) bool {
    return (char >= 'a' and char <= 'z') or (char >= 'A' and char <= 'Z') or char == '_';
}

pub const Scanner = struct {
    start: []const u8,
    current: usize,
    line: usize,

    pub fn init(source: []const u8) Scanner {
        return Scanner{
            .start = source,
            .current = 0,
            .line = 1,
        };
    }

    pub fn deinit() void {}

    pub fn scanToken(self: *Scanner) Token {
        self.start = self.start[self.current..];
        self.current = 0;

        if (self.isAtEnd()) {
            return self.makeToken(TokenType.EOF);
        }

        const c = self.advance();

        switch (c) {
            '(' => return makeToken(TokenType.LEFT_PAREN),
            ')' => return makeToken(TokenType.RIGHT_PAREN),
            '{' => return makeToken(TokenType.LEFT_BRACE),
            '}' => return makeToken(TokenType.RIGHT_BRACE),
            ';' => return makeToken(TokenType.SEMICOLON),
            ',' => return makeToken(TokenType.COMMA),
            '.' => return makeToken(TokenType.DOT),
            '-' => return makeToken(TokenType.MINUS),
            '+' => return makeToken(TokenType.PLUS),
            '/' => return makeToken(TokenType.SLASH),
            '*' => return makeToken(TokenType.STAR),
            '!' => return makeToken(if (self.match('=')) TokenType.BANG_EQUAL else TokenType.BANG),
            '=' => return makeToken(if (self.match('=')) TokenType.EQUAL_EQUAL else TokenType.EQUAL),
            '<' => return makeToken(if (self.match('=')) TokenType.LESS_EQUAL else TokenType.LESS),
            '>' => return makeToken(if (self.match('=')) TokenType.GREATER_EQUAL else TokenType.GREATER),
            '"' => return self.scanString(),
            else => {
                if (isDigit(c)) return self.scanNumber();
                if (isAlpha(c)) return self.scanIdentifier();
                if (c == 0) return self.makeToken(TokenType.EOF);
                return errorToken("Unexpected character");
            },
        }
    }

    fn advance(self: *Scanner) u8 {
        const char = self.start[self.current];
        self.current += 1;

        return char;
    }

    fn peek(self: *Scanner) u8 {
        return self.start[self.current];
    }

    fn peekNext(self: *Scanner) u8 {
        if (self.current + 1 >= self.start.len) return 0;
        return self.start[self.current + 1];
    }

    fn match(self: *Scanner, expected: u8) bool {
        if (self.isAtEnd()) {
            return false;
        }

        if (self.start[self.current] != expected) {
            return false;
        }

        self.current += 1;
        return true;
    }

    fn scanString(self: *Scanner) Token {
        while (self.peek() != '"' and !self.isAtEnd()) {
            if (self.peek() == '\n') self.line += 1;
            _ = self.advance();
        }

        if (self.isAtEnd()) return errorToken("Unterminated string.");

        _ = self.advance();
        return self.makeToken(TokenType.STRING);
    }

    fn scanNumber(self: *Scanner) Token {
        while (isDigit(self.peek())) _ = self.advance();

        if (self.peek() == '.' and isDigit(self.peekNext())) {
            _ = self.advance();
            while (isDigit(self.peek())) _ = self.advance();
        }

        return self.makeToken(TokenType.NUMBER);
    }

    fn scanIdentifier(self: *Scanner) Token {
        while (isAlpha(self.peek()) or isDigit(self.peek())) _ = self.advance();

        return self.makeToken(self.identifierType());
    }

    fn identifierType(self: *Scanner) TokenType {
        return switch (self.start[0]) {
            'a' => return self.checkKeyword(1, "nd", TokenType.AND),
            'c' => return self.checkKeyword(1, "lass", TokenType.CLASS),
            'e' => return self.checkKeyword(1, "lse", TokenType.ELSE),
            'i' => return self.checkKeyword(1, "f", TokenType.IF),
            'n' => return self.checkKeyword(1, "il", TokenType.NIL),
            'o' => return self.checkKeyword(1, "r", TokenType.OR),
            'p' => return self.checkKeyword(1, "rint", TokenType.PRINT),
            'r' => return self.checkKeyword(1, "eturn", TokenType.RETURN),
            's' => return self.checkKeyword(1, "uper", TokenType.SUPER),
            'v' => return self.checkKeyword(1, "ar", TokenType.VAR),
            'w' => return self.checkKeyword(1, "hile", TokenType.WHILE),
            'f' => {
                if (self.start[0..self.current].len == 1) return TokenType.IDENTIFIER;
                return switch (self.start[1]) {
                    'a' => checkKeyword(2, "lse", TokenType.FALSE),
                    'o' => checkKeyword(2, "or", TokenType.FOR),
                    'u' => checkKeyword(2, "un", TokenType.FUN),
                    else => TokenType.IDENTIFIER,
                };
            },
            't' => {
                if (self.start[0..self.current].len == 1) return TokenType.IDENTIFIER;
                return switch (self.start[1]) {
                    'h' => self.checkKeyword(2, "is", TokenType.THIS),
                    'r' => self.checkKeyword(2, "rue", TokenType.TRUE),
                    else => TokenType.IDENTIFIER,
                };
            },
        };
    }

    fn checkKeyword(self: *Scanner, offset: usize, str: []const u8, tokenType: TokenType) TokenType {
        if (self.current != str.len + offset) return TokenType.IDENTIFIER;

        const sourceSlice = self.start[offset..self.current];
        std.debug.assert(sourceSlice.len == str.len);
        return if (std.mem.eql(u8, sourceSlice, str)) tokenType else TokenType.IDENTIFIER;
    }

    fn skipWhitespace(self: *Scanner) void {
        while (true) {
            c = self.peek();

            switch (c) {
                ' ', '\r', '\t' => _ = self.advance(),
                '\n' => {
                    self.line += 1;
                    _ = self.advance();
                },
                '/' => {
                    if (self.peekNext() == '/') {
                        while (self.peek() != '\n' and !self.isAtEnd()) {
                            self.advance();
                        }
                    }
                },
                else => return,
            }
        }
    }

    fn makeToken(self: *Scanner, t: TokenType) Token {
        return Token{
            .tokenType = t,
            .lexeme = self.start[0..self.current],
            .line = self.line,
        };
    }

    fn errorToken(self: *Scanner, msg: []const u8) Token {
        return Token{
            .tokenType = TokenType.ERROR,
            .lexeme = msg,
            .line = self.line,
        };
    }

    fn isAtEnd(self: *Scanner) bool {
        return self.current >= self.start.len;
    }
};

pub const Token = struct {
    tokenType: TokenType, lexeme: []const u8, line: usize
};

pub const TokenType = enum {
    LEFT_PAREN, RIGHT_PAREN, LEFT_BRACE, RIGHT_BRACE, COMMA, DOT, MINUS, PLUS, SEMICOLON, SLASH, STAR, BANG, BANG_EQUAL, EQUAL, EQUAL_EQUAL, GREATER, GREATER_EQUAL, LESS, LESS_EQUAL, IDENTIFIER, STRING, NUMBER, AND, CLASS, ELSE, FALSE, FOR, FUN, IF, NIL, OR, PRINT, RETURN, SUPER, THIS, TRUE, VAR, WHILE, ERROR, EOF
};
