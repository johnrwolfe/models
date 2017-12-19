%{
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
extern int yylex();
extern int yyparse();
extern FILE * yyin;
void yyerror(const char* s);
%}

%union {
  char sval[256];
}

%token<sval> IDENTIFIER
%token ANONYMOUS ARRAY ASSIGN BAG COLON COMMA DELTA DICTIONARY DIGITS END ENUM EQUAL
%token INSTANCE LPAREN LTGT OF PRAGMA RANGE RPAREN SCOPE SEMI SEQUENCE SET STRUCTURE

%type<sval> namedTypeRef
%type<sval> scopedName

%start typeDefinition

%%

typeDefinition                : structureTypeDefinition
                              | enumerationTypeDefinition
                              | constrainedTypeDefinition
                              | typeReferenceWithCA
                              | unconstrainedArrayDefinition
                              ;

structureTypeDefinition       : STRUCTURE
                                  structureComponentDefinition structureComponentDefinitions
                                END STRUCTURE
                              | STRUCTURE
                                  structureComponentDefinition structureComponentDefinitions
                                END
                              ;

structureComponentDefinitions : /* Empty */
                              | structureComponentDefinition structureComponentDefinitions
                              ;

structureComponentDefinition  : IDENTIFIER COLON typeReference
                                initializer
                                SEMI pragmaList
                              ;

initializer                   : /* Empty */
                              | ASSIGN constExpression
                              | EQUAL constExpression
                              ;

enumerationTypeDefinition     : ENUM LPAREN
                                  enumerator enumerators
                                RPAREN
                              ;

enumerators                   : /* Empty */
                              | COMMA enumerator enumerators
                              ;

enumerator                    : IDENTIFIER initializer
                              ;

constrainedTypeDefinition     : namedTypeRef typeConstraint
                              ;

namedTypeRef                  : ANONYMOUS scopedName { strncpy( $$, $2, 256 ); }
                              | scopedName           { strncpy( $$, $1, 256 ); }
                              | ANONYMOUS IDENTIFIER { strncpy( $$, $2, 256 ); }
                              | IDENTIFIER           { strncpy( $$, $1, 256 ); }
                              ;

scopedName                    : IDENTIFIER SCOPE IDENTIFIER { strncpy( $$, $1, 256 ); strncat( $$, $3, 256-strlen($1)); }
                              ;

typeConstraint                : rangeConstraint
                              | deltaConstraint
                              | digitsConstraint
                              ;

rangeConstraint               : RANGE constExpression
                              ;

deltaConstraint               : DELTA constExpression rangeConstraint
                              ;

digitsConstraint              : DIGITS constExpression rangeConstraint
                              ;

typeReferenceWithCA           : typeReference
                              | constrainedArrayTypeRef
                              ;

constrainedArrayTypeRef       : namedTypeRef arrayBounds

arrayBounds                   : LPAREN constExpression RPAREN
                              ;

unconstrainedArrayDefinition  : ARRAY LPAREN
                                  namedTypeRef RANGE LTGT
                                RPAREN
                                OF typeReference
                              ;

typeReference                 : namedTypeRef
                              | instanceTypeRef
                              | collectionTypeRef
                              ;

instanceTypeRef               : ANONYMOUS INSTANCE OF scopedName
                              | INSTANCE OF scopedName
                              | ANONYMOUS INSTANCE OF IDENTIFIER
                              | INSTANCE OF IDENTIFIER
                              ;

collectionTypeRef             : ANONYMOUS SEQUENCE LPAREN constExpression RPAREN OF typeReference
                              | SEQUENCE LPAREN constExpression RPAREN OF typeReference
                              | ANONYMOUS SEQUENCE OF typeReference
                              | SEQUENCE OF typeReference
                              | ANONYMOUS ARRAY arrayBounds OF typeReference
                              | ARRAY arrayBounds OF typeReference
                              | ANONYMOUS SET OF typeReference
                              | SET OF typeReference
                              | ANONYMOUS BAG OF typeReference
                              | BAG OF typeReference
                              | ANONYMOUS DICTIONARY dictKeyType OF typeReference
                              | DICTIONARY dictKeyType OF typeReference
                              | ANONYMOUS DICTIONARY OF typeReference
                              | DICTIONARY OF typeReference
                              | ANONYMOUS DICTIONARY
                              | DICTIONARY
                              ;

dictKeyType                   : namedTypeRef
                              | instanceTypeRef
                              ;

pragmaList                    : /* Empty */
                              | pragma SEMI pragmaList
                              ;

pragma                        : PRAGMA IDENTIFIER
                                LPAREN
                                  pragmaValues
                                RPAREN
                              ;

pragmaValues                  : /* Empty */
                              | constExpression
                              | COMMA constExpression pragmaValues

constExpression               : IDENTIFIER
                              ;

%%
int miner() {
  yyin = stdin;
  do {
    yyparse();
  } while(!feof(yyin));
  return 0;
}
void yyerror(const char* s) {
  fprintf(stderr, "Parse error: %s\n", s);
  exit(1);
}
