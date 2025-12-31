grammar scdsk;

file: stmt* EOF;

stmt: 'PLACEHOLDER' ;

real: INT '.' INT? (E_DIGITS | E ('+'|'-') INT)?
    | '.' INT (E_DIGITS | E ('+'|'-') INT)?
    | INT (E_DIGITS | E ('+'|'-') INT)
    ;

id: ID | E | E_DIGITS;

string: STRING_KW;

WS: [ \t\r\n]+ -> skip;

// Comments
LINE_COMMENT: '//' .*? ('\n' | EOF) -> skip;
BLOCK_COMMENT: '/*' .*? '*/' -> skip;

// Parentheses
PARL: '(';
PARR: ')';

// Operators
MUL: '*';
DTP: '**';
DIV: '/';
REM: '%';
ADD: '+';
SUB: '-';
GT: '>';
LT: '<';
GE: '>=';
LE: '<=';
EE: '==';
NE: '!=';
DOTDOT: '..';

// Keywords
AND_KW: 'and';
AS_KW: 'as';
BOOLEAN_KW: 'boolean';
BREAK_KW: 'break';
BY_KW: 'by';
CALL_KW: 'call';
CHARACTER_KW: 'character';
COLUMNS_KW: 'columns';
CONST_KW: 'const';
CONTINUE_KW: 'continue';
ELSE_KW: 'else';
FALSE_KW: 'false';
FORMAT_KW: 'format';
FUNCTION_KW: 'function';
IF_KW: 'if';
IN_KW: 'in';
INTEGER_KW: 'integer';
LENGTH_KW: 'length';
LOOP_KW: 'loop';
NOT_KW: 'not';
OR_KW: 'or';
PROCEDURE_KW: 'procedure';
REAL_KW: 'real';
RETURN_KW: 'return';
RETURNS_KW: 'returns';
REVERSE_KW: 'reverse';
ROWS_KW: 'rows';
SHAPE_KW: 'shape';
STD_INPUT_KW: 'std_input';
STD_OUTPUT_KW: 'std_output';
STREAM_STATE_KW: 'stream_state';
STRUCT_KW: 'struct';
STRING_KW: 'string';
TRUE_KW: 'true';
TUPLE_KW: 'tuple';
TYPEALIAS_KW: 'typealias';
VAR_KW: 'var';
VECTOR_KW: 'vector';
WHILE_KW: 'while';
XOR_KW: 'xor';

// Literals
STRING_LITERAL: '"' CHAR*? '"';
CHAR_LITERAL: '\'' CHAR '\'';
fragment CHAR: (~["\\] | '\\' ('0' | 'a' | 'b' | 't' | 'n' | 'r' | '"' | '\'' | '\\') );

E_DIGITS: E INT; 
E: [Ee];
ID: (UNDERSCORE | LETTER)(UNDERSCORE | LETTER | DIGIT)*;
INT: DIGIT+;
fragment UNDERSCORE: '_';
fragment LETTER: [a-zA-Z];
fragment DIGIT: [0-9];
