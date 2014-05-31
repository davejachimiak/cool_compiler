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

/*
 *  Add Your own definitions here
 */

%}

STR_CONST \"([^\n]*(\\\n)*)*\"
INT_CONST [0-9]+
TYPEID [A-Z]+[0-9a-zA-Z_]+
OBJECTID [0-9a-zA-Z_]+
DARROW =>

%%
{STR_CONST} {
  /* convert yytext, which is of type *char, to string to manipulate it more easily */
  std::string str = yytext;

  /* erase quotes captured from regexp */
  str.erase(0, 1);
  str.erase(str.size() - 1);

  /* remove escape character from string */
  char escape = '\\';
  str.erase (std::remove(str.begin(), str.end(), escape), str.end());

  /* convert string back to *char */
  char * strang = new char[str.size() + 1];
  std::copy(str.begin(), str.end(), strang);
  strang[str.size()] = '\0';

  cool_yylval.symbol = stringtable.add_string (strang);
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
