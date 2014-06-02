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
      return ('\0');
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
    }
  }
  else
    return (cur_char);
}

bool prev_char_is_not_escape (int i)
{ return (!is_escape(yytext[i - 1])); }
%}

BAD_STRING \"[^\"\n\0]*[\n\0]
STR_CONST \"([^\"\n\0]|\\\"|\\\n)*\"
INT_CONST [0-9]+
TYPEID [A-Z]+[0-9a-zA-Z_]+
OBJECTID [0-9a-zA-Z_]+
DARROW =>

%%
{BAD_STRING} return (ERROR);
{STR_CONST} {
  char string_for_table[] = "";

  for (int i=1; i < yyleng; i++)
  {
    if (char_is_not_last(i))
    {
      int cur_string_len = strlen(string_for_table);
      string_for_table[cur_string_len] = convert_char(i);
      string_for_table[cur_string_len+1] = '\0';

      /* skip next character if current is escape*/
      if (yytext[i] == '\\')
        i++;
    }
  }

  cool_yylval.symbol = stringtable.add_string(string_for_table);
  return (STR_CONST);
}
{INT_CONST} { 
  cool_yylval.symbol = inttable.add_string (yytext);
  return (INT_CONST);
}
{TYPEID} {
  cool_yylval.symbol = idtable.add_string (yytext);
  return (TYPEID);
}
{OBJECTID} {
  cool_yylval.symbol = idtable.add_string (yytext);
  return (OBJECTID);
}
{DARROW} return (DARROW);
\n curr_lineno++;
[\t\b\f ]
%%
