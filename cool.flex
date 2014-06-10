%Start COMMENT
%Start STRING

/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <algorithm>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/* STR_CONST helpers */

bool char_is_not_last (int i)
{ return (i != (yyleng -1)); }

bool is_escape (char raw_char)
{ return (raw_char == '\\'); }

char convert_char (int i)
{
  char cur_char = yytext[i];

  if (is_escape(cur_char))
  {
    char next_char = yytext[i+1];

    switch(next_char)
    {
    case '\\' :
      return ('\\');
      break;
    case '\"' :
      return ('\"');
      break;
    case '\n' :
      curr_lineno++;
      return ('\n');
      break;
    case 'n' :
      return ('\n');
      break;
    case 't' :
      return ('\t');
      break;
    case 'b' :
      return ('\b');
      break;
    case 'f' :
      return ('\f');
      break;
    default :
      return (next_char);
      break;
    }
  }
  else
    return (cur_char);
}

int comment_level = 0;
%}

STR_CONST ([^\"\n\0]|\\\0|\\\"|\\\n)*[^\\]\"
OPEN_STRING \"
ESCAPED_NULL_CHAR_IN_STRING [^\"\n\0]*\\\0[^\"(\\\n)]*(\"|\\\n)
NULL_CHAR_IN_STRING [^\"\n\0]*[^\\]\0[^\"(\\\n)]*(\"|\\\n)
EOL_IN_STRING [^\"\n\\]*[^\"\\]\n

LINE_COMMENT --.*
OPEN_COMMENT \(\*
CLOSE_COMMENT \*\)
VALID_COMMENT_CHAR (\\\(|\([^*]|\\\*|\*[^)]|[^\(\*])

CLASS (?i:class)
INHERITS (?i:inherits)
NEW (?i:new)

ISVOID (?i:isvoid)

IF (?i:if)
ELSE (?i:else)
FI (?i:fi)

LOOP (?i:loop)
POOL (?i:pool)

LET (?i:let)
IN (?i:in)

THEN (?i:then)
WHILE (?i:while)

TRUE t(?i:rue)

FALSE f(?i:alse)

NOT (?i:not)

CASE (?i:case)
OF (?i:of)
ESAC (?i:esac)

DARROW =>

ASSIGN (<-)

OPERATOR "-"|"<"|[+/*=\.~,;:\(\)@\{\}]
LE <=

DIGIT [0-9]

INT_CONST {DIGIT}+
UPCASE_LETTER [A-Z]
DOWNCASE_LETTER [a-z]
LETTER {UPCASE_LETTER}|{DOWNCASE_LETTER}
DIGIT_OR_LETTER {LETTER}|{DIGIT}

TYPEID {UPCASE_LETTER}+({DIGIT_OR_LETTER}|_)*
OBJECTID {DOWNCASE_LETTER}+({DIGIT_OR_LETTER}|_)*

%%
<INITIAL>{CLASS} return (CLASS);
<INITIAL>{INHERITS} return (INHERITS);
<INITIAL>{NEW} return (NEW);

<INITIAL>{ISVOID} return (ISVOID);

<INITIAL>{IF} return (IF);
<INITIAL>{ELSE} return (ELSE);
<INITIAL>{FI} return (FI);

<INITIAL>{LET} return (LET);
<INITIAL>{IN} return (IN);

<INITIAL>{LOOP} return (LOOP);
<INITIAL>{POOL} return (POOL);

<INITIAL>{THEN} return (THEN);
<INITIAL>{WHILE} return (WHILE);

<INITIAL>{NOT} return (NOT);

<INITIAL>{TRUE} {
  yylval.boolean = 1;
  return (BOOL_CONST);
}
<INITIAL>{FALSE} {
  yylval.boolean = 0;
  return (BOOL_CONST);
}

<INITIAL>{CASE} return (CASE);
<INITIAL>{OF} return (OF);
<INITIAL>{ESAC} return (ESAC);

<INITIAL>{ASSIGN} return (ASSIGN);
<INITIAL>{OPERATOR} return (yytext[0]);
<INITIAL>{LE} return (LE);

<INITIAL>{LINE_COMMENT} curr_lineno++;
<INITIAL>{OPEN_COMMENT} {
	comment_level++;
  BEGIN(COMMENT);
}
<INITIAL>{CLOSE_COMMENT} {
  cool_yylval.error_msg = "Unmatched *)";
  return (ERROR);
}
<COMMENT><<EOF>> {
  cool_yylval.error_msg = "EOF in comment";
  BEGIN(INITIAL);
  return(ERROR);
}
<COMMENT>{OPEN_COMMENT} comment_level++;
<COMMENT>{CLOSE_COMMENT} {
  comment_level--;

  if (comment_level == 0)
		BEGIN(INITIAL);
}
<COMMENT>{VALID_COMMENT_CHAR}*
<COMMENT>{VALID_COMMENT_CHAR}*\n curr_lineno++;

<INITIAL>{OPEN_STRING} BEGIN(STRING);
<STRING>{NULL_CHAR_IN_STRING} {
  cool_yylval.error_msg = "String contains null character";
  BEGIN  (INITIAL);
  return (ERROR);
}
<STRING>{ESCAPED_NULL_CHAR_IN_STRING} {
  cool_yylval.error_msg = "String contains escaped null character.";
  BEGIN  (INITIAL);
  return (ERROR);
}
<STRING>{EOL_IN_STRING}/. {
  cool_yylval.error_msg = "Unterminated string constant";
  BEGIN  (INITIAL);
  curr_lineno++;
  return (ERROR);
}
<STRING>{EOL_IN_STRING} {
  cool_yylval.error_msg = "EOF in string constant";
  BEGIN  (INITIAL);
  return (ERROR);
}
<STRING>{STR_CONST} {
  char string_for_table[100000] = "";

  for (int i=0; i < yyleng; i++)
  {
    if (yytext[i] == '\n')
    {
			cool_yylval.error_msg = "Unterminated string constant";
			BEGIN  (INITIAL);
			curr_lineno++;
      yyless(yyleng - (yyleng - i));
			return (ERROR);
    }
    else if (char_is_not_last(i))
    {
      int cur_string_len = strlen(string_for_table);
      string_for_table[cur_string_len] = convert_char(i);
      string_for_table[cur_string_len+1] = '\0';

      /* skip next character if current is escape*/
      if (yytext[i] == '\\')
        i++;
    }
  }

  BEGIN (INITIAL);

  if (strlen(string_for_table) <= MAX_STR_CONST)
  {
    cool_yylval.symbol = stringtable.add_string(string_for_table);
    return (STR_CONST);
  }
  else
  {
    cool_yylval.error_msg = "String constant too long";
    return (ERROR);
  }
}
<STRING><<EOF>> {
  cool_yylval.error_msg = "EOF in string constant";
  BEGIN  (INITIAL);
  return (ERROR);
}
<STRING>.
<INITIAL>{INT_CONST} { 
  cool_yylval.symbol = inttable.add_string (yytext);
  return (INT_CONST);
}
<INITIAL>{TYPEID} {
  cool_yylval.symbol = idtable.add_string (yytext);
  return (TYPEID);
}
<INITIAL>{OBJECTID} {
  cool_yylval.symbol = idtable.add_string (yytext);
  return (OBJECTID);
}
<INITIAL>{DARROW} return (DARROW);
<INITIAL>[\t\b\f ]
<INITIAL>\n curr_lineno++;
<INITIAL>. {
  cool_yylval.error_msg = yytext;
  return (ERROR);
}
%%
