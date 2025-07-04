%{

#include <stdio.h>
#include "grammar.tab.h"
#include "lex.yy.h"
#define YYERROR_VERBOSE
void yyerror(YYLTYPE * yylloc_param , yyscan_t yyscanner, const char *yymsgp);
%}
%locations
%pure-parser
%lex-param {void  *scanner}
%parse-param {void *scanner}

%token IDENT HASH_IDENT CT_IDENT CONST_IDENT
%token TYPE_IDENT CT_TYPE_IDENT
%token AT_TYPE_IDENT AT_IDENT CT_INCLUDE
%token STRING_LITERAL INTEGER ALIAS
%token CT_AND_OP CT_OR_OP CT_CONCAT_OP CT_EXEC
%token INC_OP DEC_OP SHL_OP SHR_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token SUB_ASSIGN SHL_ASSIGN SHR_ASSIGN AND_ASSIGN
%token XOR_ASSIGN OR_ASSIGN VAR NUL ELVIS NEXTCASE
%token MODULE IMPORT TYPEDEF ATTRDEF FAULTDEF EXTERN
%token CHAR SHORT INT LONG FLOAT DOUBLE CONST VOID USZ ISZ UPTR IPTR ANY
%token ICHAR USHORT UINT ULONG BOOL INT128 UINT128 FLOAT16 FLOAT128 BFLOAT16
%token TYPEID BITSTRUCT STATIC BANGBANG AT_CONST_IDENT HASH_TYPE_IDENT
%token STRUCT UNION ENUM ELLIPSIS DOTDOT BYTES

%token CT_ERROR
%token CASE DEFAULT IF ELSE SWITCH WHILE DO FOR CONTINUE BREAK RETURN FOREACH_R FOREACH INTERFACE
%token FN FAULT MACRO CT_IF CT_ENDIF CT_ELSE CT_SWITCH CT_CASE CT_DEFAULT CT_FOR CT_FOREACH CT_ENDFOREACH
%token CT_ENDFOR CT_ENDSWITCH BUILTIN IMPLIES CT_ECHO CT_ASSERT CT_EVALTYPE CT_VATYPE
%token TRY CATCH SCOPE DEFER LVEC RVEC OPTELSE CT_TYPEFROM CT_TYPEOF TLOCAL
%token CT_VASPLAT INLINE DISTINCT CT_VACONST CT_NAMEOF CT_VAREF CT_VACOUNT CT_VAARG
%token CT_SIZEOF CT_STRINGIFY CT_QNAMEOF CT_OFFSETOF CT_VAEXPR CT_FEATURE
%token CT_EXTNAMEOF CT_EVAL CT_DEFINED CT_ALIGNOF ASSERT
%token ASM CHAR_LITERAL REAL TRUE FALSE CT_CONST_IDENT
%token HASH_CONST_IDENT CT_ASSIGNABLE CT_AND CT_IS_CONST

%start translation_unit
%%

path
	: IDENT SCOPE
	| path IDENT SCOPE
	;

path_const
	: path CONST_IDENT
	| CONST_IDENT
	;

path_ident
	: path IDENT
	| IDENT
	;

path_at_ident
	: path AT_IDENT
	| AT_IDENT
	;

ident_expr
	: CONST_IDENT
	| IDENT
	| AT_IDENT
	;

local_ident_expr
	: CT_IDENT
	| HASH_IDENT
	;

ct_call
	: CT_ALIGNOF
	| CT_EXTNAMEOF
	| CT_NAMEOF
	| CT_OFFSETOF
	| CT_QNAMEOF
	;

ct_castable
	: CT_ASSIGNABLE
	;

ct_analyse
	: CT_EVAL
	| CT_SIZEOF
	| CT_STRINGIFY
	| CT_IS_CONST
	;

ct_vaarg
	: CT_VACONST
	| CT_VAARG
	| CT_VAREF
	| CT_VAEXPR
	;

flat_path
	: primary_expr param_path
	| type
	| primary_expr
	;

maybe_optional_type
	: optional_type
	| empty
	;

string_expr
	: STRING_LITERAL
	| string_expr STRING_LITERAL
	;

bytes_expr
	: BYTES
	| bytes_expr BYTES
	;

base_expr
	: string_expr
	| INTEGER
	| bytes_expr
	| NUL
	| CHAR_LITERAL
	| REAL
	| TRUE
	| FALSE
	| base_expr_assignable
	;

base_expr_assignable
	: BUILTIN CONST_IDENT
	| BUILTIN IDENT
	| path ident_expr
	| ident_expr
	| local_ident_expr
	| type '.' access_ident
	| type '.' CONST_IDENT
	| '(' expr ')'
	| ct_call '(' flat_path ')'
	| ct_vaarg '[' expr ']'
	| ct_analyse '(' expression_list ')'
	| CT_DEFINED '(' arg_list ')'
	| CT_VACOUNT
	| CT_FEATURE '(' CONST_IDENT ')'
	| ct_castable '(' expr ',' type ')'
	| lambda_decl compound_statement
	;

primary_expr
	: base_expr
	| initializer_list
	| base_expr generic_expr
	;

range_loc
	: expr
	| '^' expr
	;

range_expr
	: range_loc DOTDOT range_loc
	| range_loc DOTDOT
	| DOTDOT range_loc
	| range_loc ':' range_loc
	| ':' range_loc
	| range_loc ':'
	| DOTDOT
	;

call_inline_attributes
	: AT_IDENT
	| call_inline_attributes AT_IDENT
	;

call_invocation
	: '(' call_arg_list ')'
	| '(' call_arg_list ')' call_inline_attributes
	;

access_ident
	: IDENT
	| AT_IDENT
	| HASH_IDENT
	| CT_EVAL '(' expr ')'
	| TYPEID
	;

opt_compound_statement
	: /* Empty */
	| compound_statement
	;

call_trailing
	: '[' range_loc ']'
	| '[' range_expr ']'
	| call_invocation opt_compound_statement
	| '.' access_ident
	| INC_OP
	| DEC_OP
	| '!'
	| BANGBANG
	;

call_stmt_expr
	: base_expr_assignable
	| call_stmt_expr call_trailing
	;

call_expr
	: primary_expr
	| call_expr call_trailing
	;

unary_expr
	: call_expr
	| unary_op unary_expr
	;

unary_stmt_expr
	: call_stmt_expr
	| unary_op unary_expr
	;

unary_op
	: '&'
	| AND_OP
	| '*'
	| '+'
	| '-'
	| '~'
	| '!'
	| INC_OP
	| DEC_OP
	| '(' type ')'
	;

mult_op
	: '*'
	| '/'
	| '%'
	;

mult_expr
	: unary_expr
	| mult_expr mult_op unary_expr
	;

mult_stmt_expr
	: unary_stmt_expr
	| mult_stmt_expr mult_op unary_expr
	;

shift_op
	: SHL_OP
	| SHR_OP
	;

shift_expr
	: mult_expr
	| shift_expr shift_op mult_expr
	;

shift_stmt_expr
	: mult_stmt_expr
	| shift_stmt_expr shift_op mult_expr
	;

bit_op
	: '&'
	| '^'
	| '|'
	;

bit_expr
	: shift_expr
	| bit_expr bit_op shift_expr
	;

bit_stmt_expr
	: shift_stmt_expr
	| bit_stmt_expr bit_op shift_expr
	;

additive_op
	: '+'
	| '-'
	| CT_CONCAT_OP
	;

additive_expr
	: bit_expr
	| additive_expr additive_op bit_expr
	;

additive_stmt_expr
	: bit_stmt_expr
	| additive_stmt_expr additive_op bit_expr
	;

relational_op
	: '<'
	| '>'
	| LE_OP
	| GE_OP
	| EQ_OP
	| NE_OP
	;

relational_expr
	: additive_expr
	| relational_expr relational_op additive_expr
	;

relational_stmt_expr
	: additive_stmt_expr
	| relational_stmt_expr relational_op additive_expr
	;

try_catch_rhs_expr
	: call_expr
	| lambda_decl IMPLIES relational_expr
	;

try_chain_expr
	: relational_expr
	| lambda_decl IMPLIES relational_expr
	;

and_expr
	: relational_expr
	| and_expr AND_OP relational_expr
	| and_expr CT_AND_OP relational_expr
	;

and_stmt_expr
	: relational_stmt_expr
	| and_stmt_expr AND_OP relational_expr
	| and_stmt_expr CT_AND_OP relational_expr
	;

or_expr
	: and_expr
	| or_expr OR_OP and_expr
	| or_expr CT_OR_OP and_expr
	;

or_stmt_expr
	: and_stmt_expr
	| or_stmt_expr OR_OP and_expr
	| or_stmt_expr CT_OR_OP and_expr
	;

suffix_expr
	: or_expr
	| or_expr '?'
	| or_expr '?' '!'
	;

suffix_stmt_expr
	: or_stmt_expr
	| or_stmt_expr '?'
	| or_stmt_expr '?' '!'
	;

ternary_expr
	: suffix_expr
	| or_expr '?' expr ':' ternary_expr
	| suffix_expr ELVIS ternary_expr
	| suffix_expr OPTELSE ternary_expr
	| lambda_decl implies_body
	;

ternary_stmt_expr
	: suffix_stmt_expr
	| or_stmt_expr '?' expr ':' ternary_expr
	| suffix_stmt_expr ELVIS ternary_expr
	| suffix_stmt_expr OPTELSE ternary_expr
	| lambda_decl implies_body
	;

assignment_op
	: '='
	| ADD_ASSIGN
	| SUB_ASSIGN
	| MUL_ASSIGN
	| DIV_ASSIGN
	| MOD_ASSIGN
	| SHL_ASSIGN
	| SHR_ASSIGN
	| AND_ASSIGN
	| XOR_ASSIGN
	| OR_ASSIGN
	;

empty
	: /*empty*/
	;

assignment_expr
	: ternary_expr
	| unary_expr assignment_op assignment_expr
	;

assignment_stmt_expr
	: ternary_stmt_expr
	| unary_stmt_expr assignment_op assignment_expr
	;

implies_body
	: IMPLIES expr
	;

lambda_decl
	: FN maybe_optional_type fn_parameter_list opt_attributes
	;

expr_no_list
	: assignment_stmt_expr
	;

expr
	: assignment_expr
	;

constant_expr
	: ternary_expr
	;

param_path_element
	: '[' expr ']'
	| '[' expr DOTDOT expr ']'
	| '.' primary_expr
	;

param_path
	: param_path_element
	| param_path param_path_element
	;

arg_name
	: IDENT
	| CT_TYPE_IDENT
	| HASH_IDENT
	| CT_IDENT
	;
arg
	: param_path '=' expr
	| param_path '=' type
	| param_path
	| arg_name ':' expr
	| arg_name ':' type
	| type
	| expr
	| CT_VASPLAT
	| CT_VASPLAT '[' range_expr ']'
	| ELLIPSIS expr
	;

arg_list
	: arg
	| arg_list ',' arg
	| arg_list ','
	;

opt_arg_list
	: arg_list
	| empty
	;

call_arg_list
	: opt_arg_list
	| opt_arg_list ';'
	| opt_arg_list ';' parameters
	;

interfaces
	: TYPE_IDENT opt_generic_parameters
	| interfaces ',' TYPE_IDENT opt_generic_parameters
	;

opt_interface_impl
	: '(' interfaces ')'
	| '(' ')'
	| empty
	;

enum_constants
	: enum_constant
	| enum_constants ',' enum_constant
	;

enum_list
	: enum_constants
	| enum_constants ','
	;

enum_constant
	: CONST_IDENT opt_attributes
	| CONST_IDENT opt_attributes '=' constant_expr
	;

identifier_list
	: IDENT
	| identifier_list ',' IDENT
	;

enum_param_decl
	: type IDENT
	| INLINE type IDENT
	;

base_type_no_user_defined
	: VOID
	| BOOL
	| CHAR
	| ICHAR
	| SHORT
	| USHORT
	| INT
	| UINT
	| LONG
	| ULONG
	| INT128
	| UINT128
	| FLOAT
	| DOUBLE
	| FLOAT16
	| BFLOAT16
	| FLOAT128
	| IPTR
	| UPTR
	| ISZ
	| USZ
	| FAULT
	| ANY
	| TYPEID
	| CT_TYPE_IDENT
	| CT_TYPEOF '(' expr ')'
	| CT_TYPEFROM '(' constant_expr ')'
	| CT_VATYPE '[' constant_expr ']'
	| CT_EVALTYPE '(' constant_expr ')'
	;
base_type
	: base_type_no_user_defined
	| TYPE_IDENT opt_generic_parameters
        | path TYPE_IDENT opt_generic_parameters
	;

base_type_no_generics
	: base_type_no_user_defined
	| TYPE_IDENT
        | path TYPE_IDENT
	;

type_no_generics
	: base_type_no_generics
	| type_no_generics type_suffix
	;

type_suffix
	: '*'
	| '[' constant_expr ']'
        | '[' ']'
        | '[' '*' ']'
        | LVEC constant_expr RVEC
        | LVEC '*' RVEC
        ;
type
	: base_type
	| type type_suffix;

optional_type
	: type
	| type '?'
	;

local_decl_after_type
	: CT_IDENT
	| CT_IDENT '=' constant_expr
	| IDENT opt_attributes
	| IDENT opt_attributes '=' expr
	;

local_decl_storage
	: STATIC
	| TLOCAL
	;

decl_or_expr
	: var_decl
	| optional_type local_decl_after_type
	| expr
	;

var_decl
	: VAR IDENT '=' expr
	| VAR CT_IDENT '=' expr
	| VAR CT_IDENT
	| VAR CT_TYPE_IDENT '=' type
	| VAR CT_TYPE_IDENT
	;

initializer_list
	: '{' opt_arg_list '}'
	;

ct_case_stmt
	: CT_CASE constant_expr ':' opt_stmt_list
	| CT_CASE type ':' opt_stmt_list
	| CT_DEFAULT ':' opt_stmt_list
	;

ct_switch_body
	: ct_case_stmt
	| ct_switch_body ct_case_stmt
	;

ct_for_stmt
	: CT_FOR for_cond ':' opt_stmt_list CT_ENDFOR
	;

ct_foreach_stmt
	: CT_FOREACH CT_IDENT ':' expr ':' opt_stmt_list CT_ENDFOREACH
	| CT_FOREACH CT_IDENT ',' CT_IDENT ':' expr ':' opt_stmt_list CT_ENDFOREACH
	;
ct_switch
	: CT_SWITCH constant_expr ':'
	| CT_SWITCH type ':'
	| CT_SWITCH ':'
	;

ct_switch_stmt
	: ct_switch ct_switch_body CT_ENDSWITCH
	;

var_stmt
	: var_decl ';'
	;

decl_stmt_after_type
	: local_decl_after_type
	| decl_stmt_after_type ',' local_decl_after_type
	;

declaration_stmt
	: const_declaration
	| local_decl_storage optional_type decl_stmt_after_type ';'
	| optional_type decl_stmt_after_type ';'
	;

return_stmt
	: RETURN expr ';'
	| RETURN ';'
	;

catch_unwrap_list
	: relational_expr
	| catch_unwrap_list ',' relational_expr
	;

catch_unwrap
	: CATCH catch_unwrap_list
	| CATCH IDENT '=' catch_unwrap_list
	| CATCH type IDENT '=' catch_unwrap_list
	;

try_unwrap
	: TRY try_catch_rhs_expr
	| TRY IDENT '=' try_chain_expr
	| TRY type IDENT '=' try_chain_expr
	;

try_unwrap_chain
	: try_unwrap
	| try_unwrap_chain AND_OP try_unwrap
	| try_unwrap_chain AND_OP try_chain_expr
	;

default_stmt
	: DEFAULT ':' opt_stmt_list
	;

case_stmt
	: CASE expr ':' opt_stmt_list
	| CASE expr DOTDOT expr ':' opt_stmt_list
	| CASE type ':' opt_stmt_list
	;

switch_body
	: case_stmt
	| default_stmt
	| switch_body case_stmt
	| switch_body default_stmt
	;

cond_repeat
	: decl_or_expr
	| cond_repeat ',' decl_or_expr
	;

cond
	: try_unwrap_chain
	| catch_unwrap
	| cond_repeat
	| cond_repeat ',' try_unwrap_chain
	| cond_repeat ',' catch_unwrap
	;

else_part
	: ELSE if_stmt
	| ELSE compound_statement
	;

if_stmt
	: IF optional_label paren_cond '{' switch_body '}'
	| IF optional_label paren_cond '{' switch_body '}' else_part
	| IF optional_label paren_cond statement
	| IF optional_label paren_cond compound_statement else_part
	;

expr_list_eos
	: expression_list ';'
	| ';'
	;

cond_eos
	: cond ';'
	| ';'
	;

for_cond
	: expr_list_eos cond_eos expression_list
	| expr_list_eos cond_eos
	;

for_stmt
	: FOR optional_label '(' for_cond ')' statement
	;

paren_cond
	: '(' cond ')'
	;

while_stmt
	: WHILE optional_label paren_cond statement
	;

do_stmt
	: DO optional_label compound_statement WHILE '(' expr ')' ';'
	| DO optional_label compound_statement ';'
	;

optional_label_target
	: CONST_IDENT
	| empty
	;

continue_stmt
	: CONTINUE optional_label_target ';'
	;

break_stmt
	: BREAK optional_label_target ';'
	;

nextcase_stmt
	: NEXTCASE CONST_IDENT ':' expr ';'
	| NEXTCASE expr ';'
	| NEXTCASE CONST_IDENT ':' type ';'
	| NEXTCASE type ';'
	| NEXTCASE CONST_IDENT ':' DEFAULT ';'
	| NEXTCASE DEFAULT ';'
	| NEXTCASE ';'
	;

foreach_var
	: optional_type '&' IDENT
	| optional_type IDENT
	| '&' IDENT
	| IDENT
	;

foreach_vars
	: foreach_var
	| foreach_var ',' foreach_var
	;

foreach_stmt
	: FOREACH optional_label '(' foreach_vars ':' expr ')' statement
	| FOREACH_R optional_label '(' foreach_vars ':' expr ')' statement
	;

defer_stmt
	: DEFER statement
	| DEFER TRY statement
	| DEFER CATCH statement
	| DEFER '(' CATCH IDENT ')' statement
	;

ct_if_stmt
	: CT_IF constant_expr ':' opt_stmt_list CT_ENDIF
	| CT_IF constant_expr ':' opt_stmt_list CT_ELSE opt_stmt_list CT_ENDIF
	;

assert_expr_list
	: expr
	| expr ',' assert_expr_list
	;

assert_stmt
	: ASSERT '(' expr ')' ';'
	| ASSERT '(' expr ',' assert_expr_list ')' ';'
	;

asm_stmts
	: asm_stmt
	| asm_stmts asm_stmt
	;

asm_instr
	: INT
	| IDENT
	| INT '.' IDENT
	| IDENT '.' IDENT
	;

asm_addr
	: asm_expr
	| asm_expr additive_op asm_expr
	| asm_expr additive_op asm_expr '*' INTEGER
	| asm_expr additive_op asm_expr '*' INTEGER additive_op INTEGER
	| asm_expr additive_op asm_expr shift_op INTEGER
	| asm_expr additive_op asm_expr additive_op INTEGER
	;

asm_expr
	: CT_IDENT
	| CT_CONST_IDENT
	| IDENT
	| '&' IDENT
	| CONST_IDENT
	| REAL
	| INTEGER
	| '(' expr ')'
	| '[' asm_addr ']'
	;

asm_exprs
	: asm_expr
	| asm_exprs ',' asm_expr
	;

asm_stmt
	: asm_instr asm_exprs ';'
	| asm_instr ';'
	;

asm_block_stmt
	: ASM '(' constant_expr ')' ';'
	| ASM '(' constant_expr ')' AT_IDENT ';'
	| ASM '{' asm_stmts '}'
	| ASM AT_IDENT '{' asm_stmts '}'
	| ASM '{' '}'
	| ASM AT_IDENT '{' '}'
	;

/* Order here matches compiler */
statement
	: compound_statement
	| var_stmt
	| CT_TYPE_IDENT '=' type ';'
	| declaration_stmt
	| return_stmt
	| if_stmt
	| while_stmt
	| defer_stmt
	| switch_stmt
	| do_stmt
	| for_stmt
	| foreach_stmt
	| continue_stmt
	| break_stmt
	| nextcase_stmt
	| asm_block_stmt
	| ct_echo_stmt
	| ct_assert_stmt
	| ct_if_stmt
	| ct_switch_stmt
	| ct_foreach_stmt
	| ct_for_stmt
	| expr_no_list ';'
	| assert_stmt
	| ';'
	;

compound_statement
	: '{' opt_stmt_list '}'
	;

statement_list
	: statement
	| statement_list statement
	;

opt_stmt_list
	: statement_list
	| empty
	;

switch_stmt
	: SWITCH optional_label '{' switch_body '}'
	| SWITCH optional_label '{' '}'
	| SWITCH optional_label paren_cond  opt_attributes '{' switch_body '}'
	| SWITCH optional_label paren_cond  opt_attributes '{' '}'
	;

expression_list
	: decl_or_expr
	| expression_list ',' decl_or_expr
	;

optional_label
	: CONST_IDENT ':'
	| empty
	;

ct_assert_stmt
	: CT_ASSERT constant_expr ':' constant_expr ';'
	| CT_ASSERT constant_expr ';'
	| CT_ERROR constant_expr ';'
	;

ct_include_stmt
	: CT_INCLUDE string_expr ';'
	;

ct_echo_stmt
	: CT_ECHO constant_expr ';'
	;

bitstruct_declaration
	: BITSTRUCT TYPE_IDENT opt_interface_impl ':' type_no_generics opt_attributes bitstruct_body
	;

bitstruct_body
	: '{' '}'
	| '{' bitstruct_defs '}'
	| '{' bitstruct_simple_defs '}'
	;

bitstruct_defs
	: bitstruct_def
	| bitstruct_defs bitstruct_def
	;

bitstruct_simple_defs
	: base_type IDENT ';'
	| bitstruct_simple_defs base_type IDENT ';'
	;

bitstruct_def
	: base_type IDENT ':' constant_expr DOTDOT constant_expr ';'
	| base_type IDENT ':' constant_expr ';'
	;

attribute_name
	: AT_IDENT
	| AT_TYPE_IDENT
	| path AT_TYPE_IDENT
	;

attribute_operator_expr
	: '&' '[' ']'
	| '[' ']' '='
	| '[' ']'
	;

attr_param
	: attribute_operator_expr
	| constant_expr
	;

attribute_param_list
	: attr_param
	| attribute_param_list ',' attr_param
	;

attribute
	: attribute_name
	| attribute_name '(' attribute_param_list ')'
	;

attribute_list
	: attribute
	| attribute_list attribute
	;

opt_attributes
	: attribute_list
	| empty
	;

trailing_block_param
	: AT_IDENT
	| AT_IDENT '(' ')'
	| AT_IDENT '(' parameters ')'
	;

macro_params
	: parameters
	| parameters ';' trailing_block_param
	| ';' trailing_block_param
	| empty
	;

macro_func_body
	: implies_body ';'
	| compound_statement
	;

macro_declaration
	: MACRO macro_header '(' macro_params ')' opt_attributes macro_func_body
	;

struct_or_union
	: STRUCT
	| UNION
	;

struct_declaration
	: struct_or_union TYPE_IDENT opt_interface_impl opt_attributes struct_body
	;

struct_body
	: '{' struct_declaration_list '}'
	;

struct_declaration_list
	: struct_member_decl
	| struct_declaration_list struct_member_decl
	;

enum_params
	: enum_param_decl
	| enum_params ',' enum_param_decl
	;

struct_member_decl
	: type identifier_list opt_attributes ';'
	| struct_or_union IDENT opt_attributes struct_body
	| struct_or_union opt_attributes struct_body
	| BITSTRUCT ':' type_no_generics opt_attributes bitstruct_body
	| BITSTRUCT IDENT ':' type_no_generics opt_attributes bitstruct_body
	| INLINE type IDENT opt_attributes ';'
	| INLINE type opt_attributes ';'
	;


enum_spec
	: ':' base_type_no_generics '(' enum_params ')'
	| ':' INLINE base_type_no_generics '(' enum_params ')'
        | ':' base_type_no_generics
        | ':' INLINE base_type_no_generics
        | ':' '(' enum_params ')'
	;

enum_declaration
	: ENUM TYPE_IDENT opt_interface_impl enum_spec opt_attributes '{' enum_list '}'
	| ENUM TYPE_IDENT opt_interface_impl opt_attributes '{' enum_list '}'
	;

faults
	: CONST_IDENT opt_attributes
	| faults ',' CONST_IDENT opt_attributes
	;

fault_declaration
	: FAULTDEF faults ';'
	;

func_macro_name
	: IDENT
	| AT_IDENT
	;

func_header
	: optional_type type '.' func_macro_name
	| optional_type func_macro_name
	;

macro_header
	: func_header
	| type '.' func_macro_name
	| func_macro_name
	;

fn_parameter_list
	: '(' parameters ')'
	| '(' ')'
	;

parameter_default
	: parameter
	| parameter '=' expr
	| parameter '=' type
	;

parameters
	: parameter_default
	| parameters ',' parameter_default
	| parameters ','
	;

parameter
	: type IDENT opt_attributes
	| type ELLIPSIS IDENT opt_attributes
	| type ELLIPSIS CT_IDENT
	| type CT_IDENT
	| type ELLIPSIS opt_attributes
	| type HASH_IDENT opt_attributes
	| type '&' IDENT opt_attributes
	| type opt_attributes
	| '&' IDENT opt_attributes
	| HASH_IDENT opt_attributes
	| ELLIPSIS
	| IDENT opt_attributes
	| IDENT ELLIPSIS opt_attributes
	| CT_IDENT
	| CT_IDENT ELLIPSIS
	;

func_defintion_decl
	: FN func_header fn_parameter_list opt_attributes ';'
	;

func_definition
	: func_defintion_decl
	| FN func_header fn_parameter_list opt_attributes macro_func_body
	;

const_declaration
	: CONST CONST_IDENT opt_attributes '=' expr ';'
	| CONST optional_type CONST_IDENT opt_attributes '=' expr ';'
	| CONST optional_type CONST_IDENT opt_attributes ';'
	;

func_typedef
	: FN optional_type fn_parameter_list
	;

opt_inline
	: INLINE
	| empty
	;

generic_parameters
	: expr
	| type
	| generic_parameters ',' expr
	| generic_parameters ',' type
	;

typedef_type
	: func_typedef
	| type
	;

multi_declaration
	: ',' IDENT
	| multi_declaration ',' IDENT
	;

global_storage
	: TLOCAL
	| empty
	;

global_declaration
	: global_storage optional_type IDENT opt_attributes ';'
	| global_storage optional_type IDENT multi_declaration opt_attributes ';'
	| global_storage optional_type IDENT opt_attributes '=' expr ';'
	;

attribute_comma_list
	: attribute
	| attribute_comma_list ',' attribute
	;

opt_comma
	: ','
	| empty
	;

define_attribute_body
	: empty
	| '=' attribute_comma_list opt_comma
	;

define_attribute
	: AT_TYPE_IDENT '(' parameters ')' opt_attributes define_attribute_body
	| AT_TYPE_IDENT opt_attributes define_attribute_body
	;

generic_expr
	: '{' generic_parameters '}'
	;

opt_generic_parameters
	: generic_expr
	| empty
	;

define_ident
	: IDENT opt_attributes '=' path_ident opt_generic_parameters
	| CONST_IDENT  opt_attributes '=' path_const opt_generic_parameters
	| AT_IDENT opt_attributes '=' path_at_ident opt_generic_parameters
	;

define_declaration
	: ALIAS define_ident ';'
	| ATTRDEF define_attribute ';'
	| ALIAS TYPE_IDENT opt_attributes '=' typedef_type opt_attributes ';'
	;

interface_body
	: func_defintion_decl
	| interface_body func_defintion_decl
	;

interface_declaration
	: INTERFACE interface_declaration_name '{' '}'
	| INTERFACE interface_declaration_name '{' interface_body '}'
	;

interface_parents
	: TYPE_IDENT
	| interface_parents ',' TYPE_IDENT
	;

interface_declaration_name
	: TYPE_IDENT
	| TYPE_IDENT ':' interface_parents
	;

distinct_declaration
	: TYPEDEF TYPE_IDENT opt_interface_impl opt_attributes '=' opt_inline type ';'
	;

module_param
	: CONST_IDENT
	| TYPE_IDENT
	;

module_params
	: module_param
	| module_params ',' module_param
	;

module
	: MODULE path_ident opt_attributes ';'
	| MODULE path_ident '{' module_params '}' opt_attributes ';'
	;

import_paths
	: path_ident
	| import_paths ',' path_ident
	;

import_decl
	: IMPORT import_paths opt_attributes ';'
	;

translation_unit
	: top_level_statements
	| empty
	;

top_level_statements
	: top_level
	| top_level_statements top_level
	;

opt_extern
	: EXTERN
	| empty
	;

exec_decl
	: CT_EXEC '(' expr ')' opt_attributes ';'
	| CT_EXEC '(' expr ',' initializer_list ')' opt_attributes ';'
	| CT_EXEC '(' expr ',' initializer_list ',' expr ')' opt_attributes ';'
	;

top_level
	: module
	| import_decl
	| exec_decl
	| opt_extern func_definition
	| opt_extern const_declaration
	| opt_extern global_declaration
	| ct_assert_stmt
	| ct_echo_stmt
	| ct_include_stmt
	| struct_declaration
	| fault_declaration
	| enum_declaration
	| macro_declaration
	| define_declaration
	| bitstruct_declaration
	| distinct_declaration
	| interface_declaration
	;

%%

void yyerror(YYLTYPE * yylloc_param , yyscan_t yyscanner, const char *yymsgp)
{
	fflush(stdout);
	printf(":%d:%d:\n%*s\n%*s\n", yylloc_param->first_line,
		yylloc_param->first_column,
		yylloc_param->first_column, "^", yylloc_param->first_column, yymsgp);
}

int main(int argc, char *argv[])
{
	int rc;
	yyscan_t scanner;
	rc = yylex_init (&scanner);
	if(rc) {
		printf(" Failed to initialize the scanner: %d\n", rc);
		return rc;
	}
	rc = yyparse (scanner);
	yylex_destroy (scanner);
	printf(" -> yyparse return %d\n", rc);
	return rc;
}
