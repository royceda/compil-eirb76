<<<<<<< .mine
%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "table.h"

/* 
 * %eba sert aux calculs : résultat courant 
 * %ebx sert aux calculs : on y charge les valeurs à utiliser pour eax
 * %ecx sert aux calculs d'adresses
 * %edx sert à rien pour le moment...
 */

  int n;
  char* s;
  extern char yytext[];
  extern int column, yylineno;
  extern FILE *yyin;  
  char *file_name = NULL;
  struct table *T;
  struct type * type;
  enum _type retour;
  FILE *output = NULL;

  int yylex ();
  int yyerror ();
  void *malloc(size_t size);

  void printint(int a){
    printf("%d",a);
  }

  void printfloat(float f){
    printf("%f",f);
  }

void swap(char *a, char *b) {
	char tmp;
	tmp = *a;
	*a = *b;
	*b = tmp;
}

/* A utility function to reverse a string  */
void reverse(char str[], int length)
{
    int start = 0;
    int end = length -1;
    while (start < end)
    {
        swap(str+start, str+end);
        start++;
        end--;
    }
}
char * itoa(int input, char *str, int base) {
    int i = 0;
    int isNegative = 0;
 
    if (input == 0) {
        str[i++] = '0';
        str[i] = '\0';
        return str;
    }
    if (input < 0 && base == 10) {
        isNegative = 1;
        input = -input;
    }
 
    while (input != 0) {
        int rem = input % base;
        str[i++] = (rem > 9)? (rem-10) + 'a' : rem + '0';
        input = input/base;
    }
 
    if (isNegative)
        str[i++] = '-';
 
    str[i] = '\0';
    reverse(str, i);
 
    return str;   
}

char * concat(char * pre, const char * add) {
    if(!pre) {
	perror("pre == NULL");
	 pre = malloc(sizeof(char));
          *(pre)='\0';
	  char* add2 = malloc(strlen(add)+1);
	  strcpy(add2,add);
	  return add2;
 //	exit(EXIT_FAILURE);
    } else if(!add) {
	perror("add == NULL");
	return pre;
	//	exit(EXIT_FAILURE);
    }
    else{
      //printf("pre: \n%s\nadd: \n%s\n\n",pre?pre:"<NULL>",add?add:"<NULL>");
      char * tmp = malloc(sizeof(char) * (strlen(pre) + strlen(add) + 1));
      strcpy(tmp, pre);
      strcat(tmp, add);
      //free(pre);
      pre = tmp;
      return pre;
    }
}

char * nextLabel() {
  static int next = 1;
  char * buff = malloc(11*sizeof(char));
  itoa(next, buff, 16);
  next ++;
  return buff;
}
%}

%token <data.str> IDENTIFIER 
%token <data.val> ICONSTANT
%token <data.valf> FCONSTANT
%token INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP
%token INT FLOAT VOID
%token IF ELSE WHILE RETURN FOR DO

%type<data> primary_expression
%type<data> argument_expression_list
%type<data> unary_expression
%type<data> multiplicative_expression
%type<data> additive_expression
%type<data> comparison_expression
%type<data> expression
%type<data> declaration
%type<data> declarator_list
%type<data> type_name
%type<data> declarator
%type<data> parameter_list
%type<data> parameter_declaration
%type<data> statement
%type<data> compound_statement
%type<data> declaration_list
%type<data> statement_list
%type<data> expression_statement
%type<data> selection_statement
%type<data> iteration_statement
%type<data> jump_statement
%type<data> program
%type<data> external_declaration
%type<data> function_definition

%union {
  struct data{
    int val;
    float valf;
    char *str;
    char *code;
    char *code_out;
    int next_adr;
    struct type{
      enum _type {_INT,_FLOAT,_VOID} t; //0:int,1:float,2:void
      int dimension;//0:primitif,>0: tableau
      struct type * retour;//null sauf pour les fonctions
      int nb_parametres;
      struct type * parametres;//null sauf pour les fonctions
      char * adresse;
    }*type;
    struct symbole{
      char * str;
      char * offset;
      struct type *t;
      struct symbole *suivant;
    }*sym;
  }data;
}

%start program
%%

primary_expression
: IDENTIFIER {
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';
  $$.str = $1;
  struct type *t=cherche_symbole(T,$1);
  if(t == NULL){
    char s[] = "Non déclaré.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  else{
    $$.type = malloc(sizeof(struct type));
    memcpy($$.type,t,sizeof(struct type));
    char addr[10];
    strcpy(addr,itoa($$.next_adr, addr, 10));
   
    $$.code = concat($$.code, "\tmovl\t");
    $$.code = concat($$.code, addr);

    $$.code = concat($$.code, "(%ebp), %ebx\n");
  }
}
| ICONSTANT {
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';
  $$.type=malloc(sizeof(struct type));
  $$.type->t=_INT;
  $$.type->dimension=0;
  $$.type->retour=NULL;
  $$.type->parametres=NULL;
  $$.type->nb_parametres=0;
  
  char addr[10];
  itoa($1, addr, 10);
  $$.code = concat($$.code, "\tmovl\t$");
  $$.code = concat($$.code, addr);
  $$.code = concat($$.code, ", %ebx\n");
}
| FCONSTANT {
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';
  $$.type=malloc(sizeof(struct type));
  $$.type->t=_FLOAT;
  $$.type->dimension=0;
  $$.type->retour=NULL;
  $$.type->parametres=NULL;
  $$.type->nb_parametres=0;
  
  n++;  
}
| '(' expression ')' {
  $$ = $2;
  char * tmp = malloc(sizeof(char));
  *(tmp) = '\0';
//sauvegarde de %eax
  tmp = concat(tmp, "\tpushl\t%eax\n");
  tmp = concat(tmp, $$.code);
  free($$.code);
//restauration finale de %eax
  $$.code = concat(tmp, "\tmovl\t%eax, %ebx\n\tpopl\t%eax\n");
  }
| IDENTIFIER '(' ')' {
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';

  struct type* t= cherche_symbole(T,$1);
  if (NULL==t){    
    char s[] = "Fonction non déclarée.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if(t->retour == NULL){
    char s[] = "Incompatibilité des déclarations.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if(t->nb_parametres!=0){
    char s[] = "Nombre de paramètres incompatible. Attendu : 0.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
   
  $$.code = concat($$.code, "\tcall\t");
  $$.code = concat($$.code, $1);
  $$.code = concat($$.code, "\n");//Potentiellement agir sur esp ici, mais je ne sais pas dans quelles conditions...

  $$.type = t->retour;
  $$.str = $1;
}
| IDENTIFIER '(' argument_expression_list ')' {
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';
  struct type* t= cherche_symbole(T,$1);
  if (NULL==t){    
    char s[] = "Fonction non déclarée.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  int i;
  for (i=0;i<t->nb_parametres;i++){
    if(!compare_type_arguments(&t->parametres[i],&$3.type->parametres[i])){
      char s[] = "Nombre de paramètres incompatible.";
      yyerror(s);
      exit(EXIT_FAILURE);
    }
  }

//calcul adresse à push

//faire push

//Appeler la fonction
  $$.code = concat($$.code, "\tcall\t");   
  $$.code = concat($$.code, $1);
  $$.code = concat($$.code, "\n");//Potentiellement agir sur %esp ici, mais je ne sais pas dans quelles conditions...

  $$.type = t->retour;
  $$.str = $1;
}
| IDENTIFIER INC_OP {
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';
  struct type *t=cherche_symbole(T,$1);
  if (NULL==t){
    char s[] = "Non déclaré.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if (t->t != _INT){
    char s[] = "Type incompatible.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  $$.type=malloc(sizeof(struct type));
  memcpy($$.type,t,sizeof(struct type));
  $$.str = $1;
   
  $$.code = concat($$.code, "\tmovl\t");
  $$.code = concat($$.code, "(%ebp), %ebx\n\tadd\t$1, %ebx\n\tmovl\t%ebx, ");
  $$.code = concat($$.code, $$.type->adresse);
  $$.code = concat($$.code, "(%ebp)\n");
}
| IDENTIFIER DEC_OP {
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';
  struct type *t=cherche_symbole(T,$1);
  if (NULL==t){
    char s[] = "Non déclaré.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if (t->t != _INT){
    char s[] = "Type incompatible.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  $$.type=malloc(sizeof(struct type));
  memcpy($$.type,t,sizeof(struct type));
  $$.str = $1;
  
  $$.code = concat($$.code, "\tmovl\t");
  $$.code = concat($$.code, $$.type->adresse);
  $$.code = concat($$.code, "(%ebp), %ebx\n\tsub\t$1, %ebx\n\tmovl\t%ebx, ");
  $$.code = concat($$.code, $$.type->adresse);
  $$.code = concat($$.code, "(%ebp)\n");
  
}
| IDENTIFIER '[' expression ']' {
  struct type *t=cherche_symbole(T,$1);
  if (NULL==t){
    char s[] = "Non déclaré.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  /* if(t->dimension > 0){ */
  /*   char s[] = "Mauvaise déclaration : attendu tableau."; */
  /*   yyerror(s); */
  /*   exit(EXIT_FAILURE); */
  /* } */
  if( $3.type->t != _INT ){
    char s[] = "Pas un entier.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  //  Extension : tester si expression appartient aux bornes : entre 0 et dimension(inclus pour 0)
  if( ($3.val > t->dimension) || ($3.val < 0) ){
    char s[] = "Débordement de tableau.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  $$.type=malloc(sizeof(struct type));
  memcpy($$.type,t,sizeof(struct type));
  $$.str = $1;
    
  $$.code = concat($3.code, $$.code);

  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';
//calculer adresse dans ecx. utiliser cette adresse pour accéder à la valeur


}
;

argument_expression_list
: expression {
  $$.type = malloc(sizeof(struct type));
  $$.type->nb_parametres = 1;
  $$.type->parametres = $1.type;
//TODO
}
| argument_expression_list ',' expression {
  int k=$1.type->nb_parametres+1;
  struct type *t=malloc(sizeof(struct type)*k);
  memcpy(t,$1.type->parametres,sizeof(struct type)*(k-1));
  t[k-1]=*($3.type);
  $$.type->parametres=t;
  $$.type->nb_parametres=k;
//TODO
  }
;

unary_expression
: primary_expression {
  $$ = $1;

}
| '-' unary_expression {
  if( $2.type->t != _INT && $2.type->t != _FLOAT ){
    char s[] = "Opposé d'un type interdit.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if( $2.type->t == _INT ){
    $2.val = -$2.val;
  }
  else{
    $2.valf = -$2.valf;
  }
  $$ = $2;

  if( $$.type->t == _INT )
      $$.code = concat($$.code, "\tneg\t%ebx\n");
  else
;//à faire... Mais ej ne sais pas comment...
}
| '!' unary_expression{
  if( $2.type->t != _INT && $2.type->t != _FLOAT ){
    char s[] = "Opposé d'un type interdit.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if( $2.type->t == _INT ){
    $2.val = !$2.val;
  }
  else{
    $2.valf = !$2.valf;
  }
  $$ = $2;

  $$.code = concat($$.code, "\tnot\t%ebx\n");

}
;

multiplicative_expression
: unary_expression {
  $$ = $1;

  $$.code = concat($$.code, "\tmovl\t%ebx, %eax\n");
}
| multiplicative_expression '*' unary_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }

  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    //code ?
    $$.val = $1.val * $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $1;
    //code
    $$.valf = $1.valf * $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $3;

    $$.code = $1.code;
    $$.valf = $1.val * $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    //code
    $$.valf = $1.valf * $3.valf;
  }

  $$.code = concat($$.code, "\tmovl\t%ebx, %eax\n");
  $$.code = concat($$.code, $3.code);
  $$.code = concat($$.code, "\tmul\t%ebx\n");
  free($3.code);
}
;

additive_expression
: multiplicative_expression {
  $$ = $1;
}
| additive_expression '+' multiplicative_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }

  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    //code ?
    $$.val = $1.val + $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $1;
    //code
    $$.valf = $1.valf + $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $3;
    $$.code = $1.code;
    //code
    $$.valf = $1.val + $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    //code
    $$.valf = $1.valf + $3.valf;
  }

//sauvegarde de %eax
  $$.code = concat($$.code, "\tpushl\t%eax\n");
  $$.code = concat($$.code, $3.code);
//restauration finale de %eax
  $$.code = concat($$.code, "\tpopl\t%eax\n\tadd\t%ebx, %eax\n");

  free($3.code);
}
| additive_expression '-' multiplicative_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }

  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    //code ?
    $$.val = $1.val - $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $1;
    //code
    $$.valf = $1.valf - $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $3;
    $$.code = $1.code;
    //code
    $$.valf = $1.val - $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    //code
    $$.valf = $1.valf - $3.valf;
  }

//sauvegarde de %eax
  $$.code = concat($$.code, "\tpushl\t%eax\n");
  $$.code = concat($$.code, $3.code);
//restauration finale de %eax
  $$.code = concat($$.code, "\tpopl\t%eax\n\tsub\t%ebx, %eax\n");
  free($3.code);

}
;

comparison_expression
: additive_expression {
  $$ = $1;
}
| additive_expression '<' additive_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  
  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    //code ?
    $$.val = $1.val < $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $3;
    //code
    $$.val = $1.valf < $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    //code
    $$.val = $1.val < $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.type = _INT;
    //code
    $$.val = $1.valf < $3.valf;
  }

  char * vrai = nextLabel(), * end = nextLabel();
  $$.code = concat($1.code, "\tpushl\t%eax\n");
  free($1.code);
  $$.code = concat($$.code, $3.code);
  $$.code = concat($$.code, "\tmovl\t%eax, %ebx\n\tpop\t%eax\n\tcmp\t%eax, %ebx\n\t");
  $$.code = concat($$.code, "jl");
  $$.code = concat($$.code, "\tLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, "\n\tmovl\t$0, %eax\n\tjmp\t");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, ":\n\tmovl\t$1, %eax\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");
}
| additive_expression '>' additive_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  
  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    //code ?
    $$.val = $1.val > $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $3;
    //code
    $$.val = $1.valf > $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    //code
    $$.val = $1.val > $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.val = _INT;
    //code
    $$.val = $1.valf > $3.valf;
  }

  char * vrai = nextLabel(), * end = nextLabel();
  $$.code = concat($1.code, "\tpushl\t%eax\n");
  free($1.code);
  $$.code = concat($$.code, $3.code);
  $$.code = concat($$.code, "\tmovl\t%eax, %ebx\n\tpop\t%eax\n\tcmp\t%eax, %ebx\n\t");
  $$.code = concat($$.code, "jg");
  $$.code = concat($$.code, "\tLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, "\n\tmovl\t$0, %eax\n\tjmp\t");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, ":\n\tmovl\t$1, %eax\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");
}
| additive_expression LE_OP additive_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  
  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    //code ?
    $$.val = $1.val <= $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $3;
    //code
    $$.val = $1.valf <= $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    //code
    $$.val = $1.val <= $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.type = _INT;
    //code
    $$.val = $1.valf <= $3.valf;
  }
  char * vrai = nextLabel(), * end = nextLabel();
  $$.code = concat($1.code, "\tpushl\t%eax\n");
  free($1.code);
  $$.code = concat($$.code, $3.code);
  $$.code = concat($$.code, "\tmovl\t%eax, %ebx\n\tpop\t%eax\n\tcmp\t%eax, %ebx\n\t");
  $$.code = concat($$.code, "jle");
  $$.code = concat($$.code, "\tLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, "\n\tmovl\t$0, %eax\n\tjmp\t");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, ":\n\tmovl\t$1, %eax\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");
}
| additive_expression GE_OP additive_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  
  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    //code ?
    $$.val = $1.val >= $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $3;
    //code
    $$.val = $1.valf >= $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    //code
    $$.val = $1.val >= $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.type = _INT;
    //code
    $$.val = $1.valf >= $3.valf;
  }

  char * vrai = nextLabel(), * end = nextLabel();
  $$.code = concat($1.code, "\tpushl\t%eax\n");
  free($1.code);
  $$.code = concat($$.code, $3.code);
  $$.code = concat($$.code, "\tmovl\t%eax, %ebx\n\tpop\t%eax\n\tcmp\t%eax, %ebx\n\t");
  $$.code = concat($$.code, "jge");
  $$.code = concat($$.code, "\tLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, "\n\tmovl\t$0, %eax\n\tjmp\t");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, ":\n\tmovl\t$1, %eax\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");
}
| additive_expression EQ_OP additive_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  
  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    //code ?
    $$.val = $1.val == $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $3;
    //code
    $$.val = $1.valf == $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    //code
    $$.val = $1.val == $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.type = _INT;
    //code
    $$.val = $1.valf == $3.valf;
  }

  char * vrai = nextLabel(), * end = nextLabel();
  $$.code = concat($1.code, "\tpushl\t%eax\n");
  free($1.code);
  $$.code = concat($$.code, $3.code);
  $$.code = concat($$.code, "\tmovl\t%eax, %ebx\n\tpop\t%eax\n\tcmp\t%eax, %ebx\n\t");
  $$.code = concat($$.code, "jeq");
  $$.code = concat($$.code, "\tLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, "\n\tmovl\t$0, %eax\n\tjmp\t");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, ":\n\tmovl\t$1, %eax\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");
}
| additive_expression NE_OP additive_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  
  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    //code ?
    $$.val = $1.val != $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $3;
    //code
    $$.val = $1.valf != $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    //code
    $$.val = $1.val != $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.type = _INT;
    //code
    $$.val = $1.valf != $3.valf;
  }

  char * vrai = nextLabel(), * end = nextLabel();
  $$.code = concat($1.code, "\tpushl\t%eax\n");
  free($1.code);
  $$.code = concat($$.code, $3.code);
  $$.code = concat($$.code, "\tmovl\t%eax, %ebx\n\tpop\t%eax\n\tcmp\t%eax, %ebx\n\t");
  $$.code = concat($$.code, "jne");
  $$.code = concat($$.code, "\tLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, "\n\tmovl\t$0, %eax\n\tjmp\t");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, ":\n\tmovl\t$1, %eax\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");
}
;

expression
: IDENTIFIER '=' comparison_expression {
  struct type *t=cherche_symbole(T,$1);
  if (NULL==t){
    char s[] = "Non déclaré.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if(t->t == _VOID){
    char s[] = "Type VOID non compatible avec affectation.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  /* if( $3.type->dimension > 0 ){ */
  /*   char s[] = "Assignation invalide (tableau)."; */
  /*   yyerror(s); */
  /*   exit(EXIT_FAILURE); */
  /* } */

  $$.type = malloc(sizeof(struct type));
  memcpy($$.type,t,sizeof(struct type));

  if( t->t == _INT ){
    $$.val = $3.val;
  }
  else if( t->t == _FLOAT ){
    $$.valf = $3.val;
  }

  $$.code = concat($$.code, $3.code);
  free($3.code);
  $$.code = concat($$.code, "\tmovl\t%eax, ");
  $$.code = concat($$.code, $3.type->adresse);
  $$.code = concat($$.code, "\n");
}
| IDENTIFIER '[' expression ']' '=' comparison_expression {
  struct type *t=cherche_symbole(T,$1);
  if (NULL==t){
    char s[] = "Non déclaré.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if(t->t == _VOID){
    char s[] = "Type VOID non compatible avec comparaison.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if( t->dimension == 0 ){
    char s[] = "Pas un tableau.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  /* if( $6.type->dimension > 0 ){ */
  /*   char s[] = "Assignation invalide (tableau)."; */
  /*   yyerror(s); */
  /*   exit(EXIT_FAILURE); */
  /* } */
  //EXTENSION expression doit être compris entre 0 et dimension, 0 inclus
  if( ($3.val > t->dimension) || ($3.val < 0) ){
    char s[] = "Débordement de tableau.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }

  if( t->t == _INT ){
    $$.type = malloc(sizeof(struct type));
    memcpy($$.type,t,sizeof(struct type));
    //code
    $$.val = $3.val;
  }
  else if( t->t == _FLOAT ){
    $$.type = malloc(sizeof(struct type));
    memcpy($$.type,t,sizeof(struct type));
    //code
    $$.valf = $3.val;
  }

//Calcul de l'adresse. 
  $$.code = concat($$.code, $3.code);
  free($3.code);
  $$.code = concat($$.code, "\tmovl\t%eax, ");
  $$.code = concat($$.code, $3.type->adresse);
  $$.code = concat($$.code, "\n");
}
| comparison_expression {
  $$ = $1;
}
;

declaration
: type_name declarator_list ';' {
  //code
  struct symbole *s=$2.sym;
  enum _type type_name;
   
  type_name = $1.type->t;
  
  while(s!=NULL){
    s->t->t=type_name;
    ajout_symbole(T,s->str,s->t);
    s = s->suivant;
  }

  $$.code = $2.code;
}
;

declarator_list
: declarator {
  //code
  $$.sym=malloc(sizeof(struct symbole));
  $$.sym->str=$1.str;
  $$.sym->t=$1.type;
  $$.sym->suivant=NULL;
  $$.code = $1.code;
}
| declarator_list ',' declarator {
  $$.sym=malloc(sizeof(struct symbole));
  $$.sym->str=$3.str;
  $$.sym->t=$3.type; 
  $$.sym->suivant=$1.sym;
  //code
  $$.code = concat($1.code, $3.code);
  free($3.code);
}
;

type_name
: VOID {
  $$.type = malloc(sizeof(struct type));
  $$.type->t = _VOID;
  $$.type->dimension = 0;

  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
}
| INT {
  $$.type = malloc(sizeof(struct type));
  $$.type->t = _INT;
  $$.type->dimension = 0;

  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
}
| FLOAT {
  $$.type = malloc(sizeof(struct type));
  $$.type->t = _FLOAT;
  $$.type->dimension = 0;

  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
}
;

declarator
: IDENTIFIER {
  $$.type = malloc(sizeof(struct type));
  $$.type->dimension = 0;
  $$.type->retour = NULL;
  $$.type->parametres = NULL;
  $$.type->nb_parametres = 0; 
  $$.str = $1;

  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
}
| '*' IDENTIFIER {
  $$.type = malloc(sizeof(struct type));
  $$.type->dimension = 42; //Ceci est un pointeur. Nous ne savons pas gérer les malloc
  $$.type->retour = NULL;
  $$.type->parametres = NULL;
  $$.type->nb_parametres = 0;
  $$.str = $2;

  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
}
| IDENTIFIER '[' ICONSTANT ']' {
  $$.type = malloc(sizeof(struct type));
  $$.type->dimension = $3; //Là on peut !
  $$.type->retour = NULL;
  $$.type->parametres = NULL;
  $$.type->nb_parametres = 0;
  $$.str = $1;

  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
}
| declarator '(' parameter_list ')' {
  $$.type = malloc(sizeof(struct type));
  $$.type->dimension = 0;
  $$.type->retour = NULL;
  $$.type->parametres = $3.type->parametres;
  $$.type->nb_parametres = $3.type->nb_parametres;
  $$.str = $1.str;

  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
}
| declarator '(' ')' {
  $$.type = malloc(sizeof(struct type));
  $$.type->dimension = 0;
  $$.type->retour = NULL;
  $$.type->parametres = NULL;
  $$.type->nb_parametres = 0;
  $$.str = $1.str;

  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
}
;

parameter_list
: parameter_declaration {
  struct type *param = malloc(sizeof(struct type));
  param->t = $1.type->t;
  param->dimension = 0;
  param->retour = NULL;
  param->parametres = NULL;
  param->nb_parametres = 0;
  $$.type->parametres = param;
}
| parameter_list ',' parameter_declaration {
  int k = $1.type->nb_parametres+1;
  struct type *t = malloc(sizeof(struct type)*k);
  memcpy(t,$1.type->parametres,sizeof(struct type)*(k-1));
  t[k-1] = *($3.type);
  $$.type->parametres = t;
  $$.type->nb_parametres = k;
  //code
}
;

parameter_declaration
: type_name declarator {
  $$ = $2;
  $$.type->t = $1.type->t;
  ajout_symbole(T,$2.str,$$.type);

  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
}
;

statement
: compound_statement{  //A voir en fonction de la suite
  $$ = $1;
  }
| expression_statement{ 
  $$ = $1;
  }
| selection_statement{
  $$ = $1;
  }
| iteration_statement{
  $$ = $1;
  }
| jump_statement{
  $$ = $1;
  }
;

compound_statement
: '{' '}' {  
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
 } 
| '{' { T = nouvelle_table(T);} statement_list '}' { 
  T = T->englobante;
  $$.code = $3.code;
 }
| '{'{T = nouvelle_table(T);} declaration_list statement_list '}'{
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  T = T->englobante;  
  $$.code = concat($3.code, $4.code);
  free($4.code);
  }
;

declaration_list
: declaration{
  $$ = $1; //TODO
 }
| declaration_list declaration{
  $$ = $1;//TODO
 }
;

statement_list
: statement {
  $$ = $1;//TODO
}
| statement_list statement {
$$ = $1;//TODO
}
;

expression_statement
: ';' {
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
 }
| expression ';' {
  $$ = $1;
}
;

selection_statement
: IF '(' expression ')' statement {
  if( $3.val != 0 )
    $$ = $5;
  //Extension : return
  char * jmp = nextLabel();
  $$.code = concat($3.code, "\tjz\tLBL");
  $$.code = concat($$.code, jmp);
  $$.code = concat($$.code, "\n");
  $$.code = concat($$.code, $5.code);
  $$.code = concat($$.code, "LBL");
  $$.code = concat($$.code, jmp);
  $$.code = concat($$.code, ":\n");
  free(jmp);
  free($5.code);
}
| IF '(' expression ')' statement ELSE statement {
  if( $3.val != 0 )
    $$ = $5;
  else
    $$ = $7;

  char * jmp = nextLabel();
  $$.code = concat($3.code, "\tjz\tLBL");
  $$.code = concat($$.code, jmp);
  $$.code = concat($$.code, "\n");
  $$.code = concat($$.code, $5.code);
  $$.code = concat($$.code, "LBL");
  $$.code = concat($$.code, jmp);
  $$.code = concat($$.code, ":\n");
  $$.code = concat($$.code, $7.code);
  free(jmp);
  free($5.code);
  free($7.code);
}
;

iteration_statement
: WHILE '(' expression ')' statement {
  if( $3.val != 0 )
    $$ = $5;

  char * begin = nextLabel();
  char * end = nextLabel();
  $$.code = malloc(sizeof(char));
  *($$.code) = '\0';
  $$.code = concat($$.code, "LBL");
  $$.code = concat($$.code, begin);
  $$.code = concat($$.code, ":\n");
  $$.code = concat($$.code, $3.code);
  $$.code = concat($$.code, "\tjz\tLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\n");
  $$.code = concat($$.code, $5.code);
  $$.code = concat($$.code, "\tjmp\tLBL");
  $$.code = concat($$.code, begin);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");
  free(begin);
  free(end);
  free($5.code);
  free($3.code);
}
| FOR '(' expression_statement expression_statement expression ')' statement {
  if( $4.val != 0 )
    $$ = $7;

  char * begin = nextLabel();
  char * end = nextLabel();
  $$.code = $3.code;
  $$.code = concat($$.code, "LBL");
  $$.code = concat($$.code, begin);
  $$.code = concat($$.code, ":\n");
  $$.code = concat($$.code, $5.code);
  $$.code = concat($$.code, "\tjz\tLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\n");
  $$.code = concat($$.code, $7.code);
  $$.code = concat($$.code, $5.code);
  $$.code = concat($$.code, "\tjmp\tLBL");
  $$.code = concat($$.code, begin);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");
  free(begin);
  free(end);
  free($5.code);
  free($7.code);
}
| FOR '(' expression_statement expression_statement expression ')' expression {
  //Règle de grammaire ajoutée pour gérer les for sans accolades
  if( $4.val != 0 )
    $$ = $7;

  char * begin = nextLabel();
  char * end = nextLabel();
  $$.code = $3.code;
  $$.code = concat($$.code, "LBL");
  $$.code = concat($$.code, begin);
  $$.code = concat($$.code, ":\n");
  $$.code = concat($$.code, $5.code);
  $$.code = concat($$.code, "\tjz\tLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\n");
  $$.code = concat($$.code, $7.code);
  $$.code = concat($$.code, $5.code);
  $$.code = concat($$.code, "\tjmp\tLBL");
  $$.code = concat($$.code, begin);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");
  free(begin);
  free(end);
  free($5.code);
  free($7.code);
}
| DO statement WHILE '(' expression ')' {
  $$ = $2;

  char * begin = nextLabel();
  char * end = nextLabel();
  $$.code = malloc(sizeof(char));
  *($$.code) = '\0';
  $$.code = concat($$.code, "LBL");
  $$.code = concat($$.code, begin);
  $$.code = concat($$.code, ":\n");
  $$.code = concat($$.code, $2.code);
  $$.code = concat($$.code, $5.code);
  $$.code = concat($$.code, "\tjz\tLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\n\tjmp\tLBL");
  $$.code = concat($$.code, begin);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");
  free(begin);
  free(end);
  free($5.code);
  free($2.code);
}
;

jump_statement
: RETURN ';' {
  if( retour != _VOID ){
    char s[] = "Type de retour faux : VOID attendu.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  $$.code = malloc(sizeof(char));
  *($$.code) = '\0';
  $$.code = concat($$.code, "\tleave\n\tret\n");
}
| RETURN expression ';' {
  if( ($2.type->t != retour) && ($2.type->t == _VOID) ){
    char s[] = "Type de retour faux.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  $$.code = concat($2.code, "\tleave\n\tret\n");
}
;

program
: external_declaration {
  s=malloc(sizeof(char)*999999);
  n=0;
  fprintf(output,"%s",s);
  //code remonté à écrire

  fprintf(output, "%s%s", $1.code, $1.code_out?$1.code_out:"");
 }
| program external_declaration {
  //code remonté à écrire
  fprintf(output, "%s%s", $2.code, $2.code_out?$1.code_out:"");
}
;

external_declaration
: function_definition {
  $$ = $1;//  ajout_symbole(T,$1.str,$1.type->retour);

  $$.code = malloc(sizeof(char));
  *($$.code) = '\0';
  $$.code = concat($$.code, "\t.globl\t");
  printf("Salut les amis voici le str %s", $1.str);
  $$.code = concat($$.code, $1.str);
  $$.code = concat($$.code, "\n\t.type\t");
  $$.code = concat($$.code, $1.str);
  $$.code = concat($$.code, ", @function\n");
  $$.code = concat($$.code, $1.str);
  $$.code = concat($$.code, ":\n");
  $$.code = concat($$.code, $1.code);
  $$.code = concat($$.code, "\t.size\t");
  $$.code = concat($$.code, $1.str);
  $$.code = concat($$.code, ", .-");
  $$.code = concat($$.code, $1.str);
  $$.code = concat($$.code, "\n");

  free($1.code);
}
| declaration {
  $$ = $1;

  $$.code = malloc(sizeof(char));
  *($$.code) = '\0';
  $$.code = concat($$.code, "\t.globl\t");
  $$.code = concat($$.code, $1.str);
  $$.code = concat($$.code, "\n\t.type\t");
  $$.code = concat($$.code, $1.str);
  $$.code = concat($$.code, ", @object\n");
  $$.code = concat($$.code, $1.str);
  $$.code = concat($$.code, ":\n");
  $$.code = concat($$.code, $1.code);

  free($1.code);
}
;

function_definition
: type_name declarator { 
  retour = $1.type->t;
  
  if ($1.type->dimension > 0) {
    char s[] = "Retour de tableau invalide";
    yyerror(s);
    exit(EXIT_FAILURE);
  } 
} compound_statement {
   $$.str = $2.str; 
   $$.type = $2.type;
   $$.type->retour = malloc(sizeof(struct type));
   $$.type->retour->dimension = 0;
   $$.type->retour->retour = NULL;
   $$.type->retour->nb_parametres = 0;
   $$.type->retour->parametres = NULL;
   $$.type->retour->t = retour;
   ajout_symbole(T,$2.str,$$.type);

   $$.code = $4.code;
}
;

%%
int yyerror (char *s) {
  fflush (stdout);
  fprintf (stderr, "%s:%d:%d: %s\n", file_name, yylineno, column, s);
  return 0;
}


int main (int argc, char *argv[]) {
  FILE *input = NULL;
  T=nouvelle_table(NULL);
  if (argc==2) {
    input = fopen (argv[1], "r");
    file_name = strdup (argv[1]);
    if (input) {
      char *output_file_name = strdup (argv[1]);
      yyin = input;
      output_file_name[strlen(output_file_name)-1] = 's';
      output = fopen (output_file_name, "w");
      if (output){
	yyparse();
	fclose(output);
      }
      else{
	fprintf (stderr, "%s: Could not open %s.\n", *argv, output_file_name);
	return 1;
      }
      free(output_file_name);
      fclose(input);
    }
    else {
      fprintf (stderr, "%s: Could not open %s.\n", *argv, argv[1]);
      return 1;
    }
    free(file_name);
  }
  else {
    fprintf (stderr, "%s: error: no input file\n", *argv);
    return 1;
  }
  return 0;
}
=======
%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "table.h"

/* 
 * %eba sert aux calculs : résultat courant 
 * %ebx sert aux calculs : on y charge les valeurs à utiliser pour eax
 * %ecx sert aux saut conditionnels
 * %edx sert aux calculs d'adresses
 */

  char* s;
  extern char yytext[];
  extern int column, yylineno;
  extern FILE *yyin;  
  char *file_name = NULL;
  struct table *T;
  struct type * type;
  enum _type retour;
  FILE *output = NULL;
  int offset = -4;

  int yylex ();
  int yyerror ();
  void *malloc(size_t size);

  void swap(char *a, char *b) {
	char tmp;
	tmp = *a;
	*a = *b;
	*b = tmp;
  }

/* A utility function to reverse a string  */
void reverse(char str[], int length)
{
    int start = 0;
    int end = length -1;
    while (start < end){
        swap(str+start, str+end);
        start++;
        end--;
    }
}

char * itoa(int input, char *str, int base) {
    int i = 0;
    int isNegative = 0;
 
    if (input == 0) {
        str[i++] = '0';
        str[i] = '\0';
        return str;
    }
    if (input < 0 && base == 10) {
        isNegative = 1;
        input = -input;
    } 

    while (input != 0) {
        int rem = input % base;
        str[i++] = (rem > 9)? (rem-10) + 'a' : rem + '0';
        input = input/base;
    }
 
    if (isNegative)
        str[i++] = '-';
 
    str[i] = '\0';
    reverse(str, i);
    return str;   
}

char * concat(char * pre, char * add) {
  char * tmp = malloc(sizeof(char) * (strlen(pre) + strlen(add) + 1));
  strcpy(tmp, pre);
  strcat(tmp, add);
  //free(pre);
  pre = tmp;
  return pre;
}

void ftoa(float n, char *res, int afterpoint){
    int ipart = (int)n;
    float fpart = n - (float)ipart;
    itoa(ipart, res, 0);
    int i = strlen(res);
 
    int nbdec = 1;
    for(;afterpoint>0;afterpoint--)
	nbdec *= 10;

    if (afterpoint != 0){
        res[i] = '.';
        fpart *= nbdec;
        itoa((int)fpart, res + i + 1, afterpoint);
    }
}

char * nextLabel() {
  static int next = 1;
  char * buff = malloc(11*sizeof(char));
  itoa(next, buff, 16);
  next ++;
  return buff;
}
%}

%token <data.str> IDENTIFIER 
%token <data.val> ICONSTANT
%token <data.valf> FCONSTANT
%token INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP
%token INT FLOAT VOID
%token IF ELSE WHILE RETURN FOR DO

%type<data> primary_expression
%type<data> argument_expression_list
%type<data> unary_expression
%type<data> multiplicative_expression
%type<data> additive_expression
%type<data> comparison_expression
%type<data> expression
%type<data> declaration
%type<data> declarator_list
%type<data> type_name
%type<data> declarator
%type<data> parameter_list
%type<data> parameter_declaration
%type<data> statement
%type<data> compound_statement
%type<data> declaration_list
%type<data> statement_list
%type<data> expression_statement
%type<data> selection_statement
%type<data> iteration_statement
%type<data> jump_statement
%type<data> program
%type<data> external_declaration
%type<data> function_definition

%union {
  struct data{
    int val;
    float valf;
    char *str;
    char *code;
    char *code_out;
    struct type{
      enum _type {_INT,_FLOAT,_VOID} t; //0:int,1:float,2:void
      int dimension;//0:primitif,>0: tableau
      struct type * retour;//null sauf pour les fonctions
      int nb_parametres;
      struct type * parametres;//null sauf pour les fonctions
      char * adresse;
      int isExtern;
    }*type;
    struct symbole{
      char * str;
      struct type *t;
      struct symbole *suivant;
    }*sym;
  }data;
}

%start program
%%

primary_expression
: IDENTIFIER {
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';
  $$.str = $1;
  struct type *t=cherche_symbole(T,$1);
  
  if(t == NULL){
    char s[] = "Non déclaré.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }

  $$.type = malloc(sizeof(struct type));
  memcpy($$.type,t,sizeof(struct type));
  $$.code = concat($$.code, "\tmovl\t");   
  $$.code = concat($$.code, t->adresse);
  $$.code = concat($$.code, "(%ebp), %ebx\n");
}
| ICONSTANT {
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';
  $$.type=malloc(sizeof(struct type));
  $$.type->t=_INT;
  $$.type->dimension=0;
  $$.type->retour=NULL;
  $$.type->parametres=NULL;
  $$.type->nb_parametres=0;

  char val[10];
  itoa($1, val, 10);
  $$.code = concat($$.code, "\tmovl\t$");
  $$.code = concat($$.code, val);
  $$.code = concat($$.code, ", %ebx\n");
}
| FCONSTANT {
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';
  $$.type=malloc(sizeof(struct type));
  $$.type->t=_FLOAT;
  $$.type->dimension=0;
  $$.type->retour=NULL;
  $$.type->parametres=NULL;
  $$.type->nb_parametres=0;

  char * floatlbl = nextLabel();
  $$.code = concat($$.code, "\tmovl\t$LBL");
  $$.code = concat($$.code, floatlbl);
  $$.code = concat($$.code, ", %ebx\n");

  char val[30];
  itoa($1, val, 10);
  $$.code_out = concat($$.code_out, "LBL");
  $$.code_out = concat($$.code_out, floatlbl);
  $$.code_out = concat($$.code_out, ":\n.float\t");
  $$.code_out = concat($$.code_out, val);
  $$.code_out = concat($$.code_out, "\n");

}
| '(' expression ')' {
  $$ = $2;
  char * tmp = malloc(sizeof(char));
  *(tmp) = '\0';
  //sauvegarde de %eax
  tmp = concat(tmp, "\tpushl\t%eax\n");
  tmp = concat(tmp, $$.code);
  free($$.code);
  //restauration finale de %eax
  $$.code = concat(tmp, "\tmovl\t%eax, %ebx\n\tpopl\t%eax\n");
  }
| IDENTIFIER '(' ')' {
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';

  struct type* t= cherche_symbole(T,$1);
  if (NULL==t){    
    char s[] = "Fonction non déclarée.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if(t->retour == NULL){
    char s[] = "Incompatibilité des déclarations.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if(t->nb_parametres!=0){
    char s[] = "Nombre de paramètres incompatible. Attendu : 0.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if( t->isExtern ){
    $$.code = concat($$.code, "\textern\t");
    $$.code = concat($$.code, $1);
  }
  $$.code = concat($$.code, "\tcall\t");
  $$.code = concat($$.code, $1);
  $$.code = concat($$.code, "\n");

  $$.type = t->retour;
  $$.str = $1;
}
| IDENTIFIER '(' argument_expression_list ')' {
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';
  struct type* t= cherche_symbole(T,$1);
  if (NULL==t){    
    char s[] = "Fonction non déclarée.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  int i;
  for (i=0;i<t->nb_parametres;i++){
    if(!compare_type_arguments(&t->parametres[i],&$3.type->parametres[i])){
      char s[] = "Nombre de paramètres incompatible.";
      yyerror(s);
      exit(EXIT_FAILURE);
    }
  }

//Appeler la fonction
  if( t->isExtern ){
    $$.code = concat($$.code, "\textern\t");
    $$.code = concat($$.code, $1);
  }
  $$.code = concat($$.code, "\tcall\t");   
  $$.code = concat($$.code, $1);
  $$.code = concat($$.code, "\n\taddl\t$");
  char *buffer = malloc(sizeof(char)*11);
  itoa(t->nb_parametres, buffer, 10);
  $$.code = concat($$.code, buffer);
  $$.code = concat($$.code, ", %esp\n");
  free(buffer);
  $$.code_out = concat($$.code_out, $3.code_out);
  free($3.code_out);

  $$.type = t->retour;
  $$.str = $1;
}
| IDENTIFIER INC_OP {
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';
  struct type *t=cherche_symbole(T,$1);
  if (NULL==t){
    char s[] = "Non déclaré.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if (t->t != _INT){
    char s[] = "Type incompatible.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  $$.type=malloc(sizeof(struct type));
  memcpy($$.type,t,sizeof(struct type));
  $$.str = $1;
  $$.code = concat($$.code, "\tmovl\t");
  $$.code = concat($$.code, $$.type->adresse);
  $$.code = concat($$.code, "(%ebp), %ebx\n\tadd\t$1, %ebx\n\tmovl\t%ebx, ");
  $$.code = concat($$.code, $$.type->adresse);
  $$.code = concat($$.code, "(%ebp)\n");
}
| IDENTIFIER DEC_OP {
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';
  struct type *t=cherche_symbole(T,$1);
  if (NULL==t){
    char s[] = "Non déclaré.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if (t->t != _INT){
    char s[] = "Type incompatible.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  $$.type=malloc(sizeof(struct type));
  memcpy($$.type,t,sizeof(struct type));
  $$.str = $1;
  $$.code = concat($$.code, "\tmovl\t");
  $$.code = concat($$.code, $$.type->adresse);
  $$.code = concat($$.code, "(%ebp), %ebx\n\tsub\t$1, %ebx\n\tmovl\t%ebx, ");
  $$.code = concat($$.code, $$.type->adresse);
  $$.code = concat($$.code, "(%ebp)\n");
  
}
| IDENTIFIER '[' expression ']' {
  struct type *t=cherche_symbole(T,$1);
  if (NULL==t){
    char s[] = "Non déclaré.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  /* if(t->dimension > 0){ */
  /*   char s[] = "Mauvaise déclaration : attendu tableau."; */
  /*   yyerror(s); */
  /*   exit(EXIT_FAILURE); */
  /* } */
  if( $3.type->t != _INT ){
    char s[] = "Pas un entier.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  //  Extension : tester si expression appartient aux bornes : entre 0 et dimension(inclus pour 0)
  if( ($3.val > t->dimension) || ($3.val < 0) ){
    char s[] = "Débordement de tableau.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  $$.type=malloc(sizeof(struct type));
  memcpy($$.type,t,sizeof(struct type));
  $$.str = $1;

  $$.code = $3.code;
  $$.code = concat($$.code, "\tmovl\t%eax, %edx\n");//Sauvegarde du décallage
  //Calcul adresse debut de tableau
  $$.code = concat($$.code, "\tleal\t");
  $$.code = concat($$.code, $$.type->adresse);
  $$.code = concat($$.code, "(%ebp), %eax\n\tmovl\t(%eax, %edx, 4), %eax\n");
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';
  $$.code_out = concat($$.code_out, $3.code_out);
  free($3.code_out);
}
;

argument_expression_list
: expression {
  $$.type = malloc(sizeof(struct type));
  $$.type->nb_parametres = 1;
  $$.type->parametres = $1.type;
  $$.code = concat($$.code, $1.code);
  $$.code = concat($$.code, "\tpush\t%eax\n");

  $$.code_out = $1.code_out;
}
| argument_expression_list ',' expression {
  int k=$1.type->nb_parametres+1;
  struct type *t=malloc(sizeof(struct type)*k);
  memcpy(t,$1.type->parametres,sizeof(struct type)*(k-1));
  t[k-1]=*($3.type);
  $$.type->parametres=t;
  $$.type->nb_parametres=k;
  $$.code = concat($$.code, $3.code);
  $$.code = concat($$.code, "\tpush\t%eax\n");
  $$.code = concat($$.code, $1.code);

  $$.code_out = concat($1.code_out, $3.code_out);
  free($3.code_out);
}
;

unary_expression
: primary_expression {
  $$ = $1;

}
| '-' unary_expression {
  if( $2.type->t != _INT && $2.type->t != _FLOAT ){
    char s[] = "Opposé d'un type interdit.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if( $2.type->t == _INT ){
    $2.val = -$2.val;
  }
  else{
    $2.valf = -$2.valf;
  }
  $$ = $2;

  if( $$.type->t == _INT ){
    $$.code = concat($$.code, "\tneg\t%ebx\n");
  }
  else
    ;//à faire... Mais je ne sais pas comment...
}
| '!' unary_expression{
  if( $2.type->t != _INT && $2.type->t != _FLOAT ){
    char s[] = "Opposé d'un type interdit.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if( $2.type->t == _INT ){
    $2.val = !$2.val;
  }
  else{
    $2.valf = !$2.valf;
  }
  $$ = $2;
  $$.code = concat($$.code, "\tnot\t%ebx\n");
}
;

multiplicative_expression
: unary_expression {
  $$ = $1;
  $$.code = concat($$.code, "\tmovl\t%ebx, %eax\n");
}
| multiplicative_expression '*' unary_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }

  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    $$.val = $1.val * $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $1;
    $$.valf = $1.valf * $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $3;

    $$.code = $1.code;
    $$.valf = $1.val * $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.valf = $1.valf * $3.valf;
  }
  $$.code = concat($$.code, "\tmovl\t%ebx, %eax\n");
  $$.code = concat($$.code, $3.code);
  $$.code = concat($$.code, "\tmul\t%ebx\n");
  free($3.code);

  $$.code_out = concat($1.code_out, $3.code_out);
  free($3.code_out);
}
;

additive_expression
: multiplicative_expression {
  $$ = $1;
}
| additive_expression '+' multiplicative_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }

  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    $$.val = $1.val + $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $1;
    $$.valf = $1.valf + $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $3;
    $$.code = $1.code;
    $$.valf = $1.val + $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.valf = $1.valf + $3.valf;
  }

//sauvegarde de %eax
  $$.code = concat($$.code, "\tpushl\t%eax\n");
  $$.code = concat($$.code, $3.code);
//restauration finale de %eax
  $$.code = concat($$.code, "\tpopl\t%eax\n\tadd\t%ebx, %eax\n");
  free($3.code);

  $$.code_out = concat($1.code_out, $3.code_out);
  free($3.code_out);
}
| additive_expression '-' multiplicative_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }

  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    $$.val = $1.val - $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $1;
    $$.valf = $1.valf - $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $3;
    $$.code = $1.code;
    $$.valf = $1.val - $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.valf = $1.valf - $3.valf;
  }

//sauvegarde de %eax
  $$.code = concat($$.code, "\tpushl\t%eax\n");
  $$.code = concat($$.code, $3.code);
//restauration finale de %eax
  $$.code = concat($$.code, "\tpopl\t%eax\n\tsub\t%ebx, %eax\n");
  free($3.code);

  $$.code_out = concat($1.code_out, $3.code_out);
  free($3.code_out);
}
;

comparison_expression
: additive_expression {
  $$ = $1;
}
| additive_expression '<' additive_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  
  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    $$.val = $1.val < $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $3;
    $$.val = $1.valf < $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.val = $1.val < $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.type = _INT;
    $$.val = $1.valf < $3.valf;
  }

  char * vrai = nextLabel(), * end = nextLabel();
  $$.code = concat($1.code, "\tpushl\t%eax\n");
  free($1.code);
  $$.code = concat($$.code, $3.code);
  $$.code = concat($$.code, "\tmovl\t%eax, %ebx\n\tpop\t%eax\n\tcmp\t%eax, %ebx\n\t");
  $$.code = concat($$.code, "jl");
  $$.code = concat($$.code, "\tLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, "\n\tmovl\t$0, %eax\n\tjmp\tLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, ":\n\tmovl\t$1, %eax\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");

  $$.code_out = concat($1.code_out, $3.code_out);
  free($3.code_out);
}
| additive_expression '>' additive_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  
  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    $$.val = $1.val > $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $3;
    $$.val = $1.valf > $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.val = $1.val > $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.val = _INT;
    $$.val = $1.valf > $3.valf;
  }

  char * vrai = nextLabel(), * end = nextLabel();
  $$.code = concat($1.code, "\tpushl\t%eax\n");
  free($1.code);
  $$.code = concat($$.code, $3.code);
  $$.code = concat($$.code, "\tmovl\t%eax, %ebx\n\tpop\t%eax\n\tcmp\t%eax, %ebx\n\t");
  $$.code = concat($$.code, "jg");
  $$.code = concat($$.code, "\tLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, "\n\tmovl\t$0, %eax\n\tjmp\tLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, ":\n\tmovl\t$1, %eax\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");

  $$.code_out = concat($1.code_out, $3.code_out);
  free($3.code_out);
}
| additive_expression LE_OP additive_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  
  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    $$.val = $1.val <= $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $3;
    $$.val = $1.valf <= $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.val = $1.val <= $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.type = _INT;
    $$.val = $1.valf <= $3.valf;
  }
  char * vrai = nextLabel(), * end = nextLabel();
  $$.code = concat($1.code, "\tpushl\t%eax\n");
  free($1.code);
  $$.code = concat($$.code, $3.code);
  $$.code = concat($$.code, "\tmovl\t%eax, %ebx\n\tpop\t%eax\n\tcmp\t%eax, %ebx\n\t");
  $$.code = concat($$.code, "jle");
  $$.code = concat($$.code, "\tLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, "\n\tmovl\t$0, %eax\n\tjmp\tLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, ":\n\tmovl\t$1, %eax\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");

  $$.code_out = concat($1.code_out, $3.code_out);
  free($3.code_out);
}
| additive_expression GE_OP additive_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  
  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    $$.val = $1.val >= $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $3;
    $$.val = $1.valf >= $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.val = $1.val >= $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.type = _INT;
    $$.val = $1.valf >= $3.valf;
  }

  char * vrai = nextLabel(), * end = nextLabel();
  $$.code = concat($1.code, "\tpushl\t%eax\n");
  free($1.code);
  $$.code = concat($$.code, $3.code);
  $$.code = concat($$.code, "\tmovl\t%eax, %ebx\n\tpop\t%eax\n\tcmp\t%eax, %ebx\n\t");
  $$.code = concat($$.code, "jge");
  $$.code = concat($$.code, "\tLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, "\n\tmovl\t$0, %eax\n\tjmp\tLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, ":\n\tmovl\t$1, %eax\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");

  $$.code_out = concat($1.code_out, $3.code_out);
  free($3.code_out);
}
| additive_expression EQ_OP additive_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  
  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    $$.val = $1.val == $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $3;
    $$.val = $1.valf == $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.val = $1.val == $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.type = _INT;
    $$.val = $1.valf == $3.valf;
  }

  char * vrai = nextLabel(), * end = nextLabel();
  $$.code = concat($1.code, "\tpushl\t%eax\n");
  free($1.code);
  $$.code = concat($$.code, $3.code);
  $$.code = concat($$.code, "\tmovl\t%eax, %ebx\n\tpop\t%eax\n\tcmp\t%eax, %ebx\n\t");
  $$.code = concat($$.code, "jeq");
  $$.code = concat($$.code, "\tLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, "\n\tmovl\t$0, %eax\n\tjmp\tLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, ":\n\tmovl\t$1, %eax\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");

  $$.code_out = concat($1.code_out, $3.code_out);
  free($3.code_out);
}
| additive_expression NE_OP additive_expression {
  if( ($1.type->t == _VOID) || ($3.type->t == _VOID)){
    char s[] = "Multiplication de VOID interdite.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  
  if( ($1.type->t == _INT) && ($3.type->t == _INT) ){
    $$ = $1;
    $$.val = $1.val != $3.val;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _INT) ){
    $$ = $3;
    $$.val = $1.valf != $3.val;
  }
  else if( ($1.type->t == _INT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.val = $1.val != $3.valf;
  }
  else if( ($1.type->t == _FLOAT) && ($3.type->t == _FLOAT) ){
    $$ = $1;
    $$.type = _INT;
    $$.val = $1.valf != $3.valf;
  }

  char * vrai = nextLabel(), * end = nextLabel();
  $$.code = concat($1.code, "\tpushl\t%eax\n");
  free($1.code);
  $$.code = concat($$.code, $3.code);
  $$.code = concat($$.code, "\tmovl\t%eax, %ebx\n\tpop\t%eax\n\tcmp\t%eax, %ebx\n\t");
  $$.code = concat($$.code, "jne");
  $$.code = concat($$.code, "\tLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, "\n\tmovl\t$0, %eax\n\tjmp\tLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, vrai);
  $$.code = concat($$.code, ":\n\tmovl\t$1, %eax\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");

  $$.code_out = concat($1.code_out, $3.code_out);
  free($3.code_out);
}
;

expression
: IDENTIFIER '=' comparison_expression {
  struct type *t=cherche_symbole(T,$1);
  if (NULL==t){
    char s[] = "Non déclaré.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if(t->t == _VOID){
    char s[] = "Type VOID non compatible avec affectation.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  /* if( $3.type->dimension > 0 ){ */
  /*   char s[] = "Assignation invalide (tableau)."; */
  /*   yyerror(s); */
  /*   exit(EXIT_FAILURE); */
  /* } */

  $$.type = malloc(sizeof(struct type));
  memcpy($$.type,t,sizeof(struct type));

  if( t->t == _INT ){
    $$.val = $3.val;
  }
  else if( t->t == _FLOAT ){
    $$.valf = $3.val;
  }

  $$.code = malloc(sizeof(char));
  *($$.code) = '\0';
  $$.code = concat($$.code, $3.code);
  free($3.code);
  $$.code = concat($$.code, "\tmovl\t%eax, ");
  $$.code = concat($$.code, $$.type->adresse);
  $$.code = concat($$.code, "(%ebp)\n");

  $$.code_out = $3.code_out;
}
| IDENTIFIER '[' expression ']' '=' comparison_expression {
  struct type *t=cherche_symbole(T,$1);
  if (NULL==t){
    char s[] = "Non déclaré.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if(t->t == _VOID){
    char s[] = "Type VOID non compatible avec comparaison.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  if( t->dimension == 0 ){
    char s[] = "Pas un tableau.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  /* if( $6.type->dimension > 0 ){ */
  /*   char s[] = "Assignation invalide (tableau)."; */
  /*   yyerror(s); */
  /*   exit(EXIT_FAILURE); */
  /* } */
  //EXTENSION expression doit être compris entre 0 et dimension, 0 inclus
  if( ($3.val > t->dimension) || ($3.val < 0) ){
    char s[] = "Débordement de tableau.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }

  $$.type = malloc(sizeof(struct type));
  memcpy($$.type,t,sizeof(struct type));

  if( t->t == _INT ){
    $$.val = $3.val;
  }
  else if( t->t == _FLOAT ){
    $$.valf = $3.val;
  }

  $$.code = malloc(sizeof(char));
  *($$.code) = '\0';
  //Calcul du decallage
  $$.code = concat($$.code, $3.code);
  free($3.code);
  //Sauvegarde du décallage
  $$.code = concat($$.code, "\tmovl\t%eax, %edx\n");
  $$.code = concat($$.code, $6.code);
  //Calcul adresse debut de tableau
  $$.code = concat($$.code, "\tleal\t");
  $$.code = concat($$.code, $$.type->adresse);
  $$.code = concat($$.code, "(%ebp), %ebx\n");
  $$.code = concat($$.code, "\tmovl\t%eax, (%ebx, %edx, 4)\n");

  $$.code_out = concat($3.code_out, $6.code_out);
  free($6.code_out);
}
| comparison_expression {
  $$ = $1;
}
;

declaration
: type_name declarator_list ';' {
  struct symbole *s=$2.sym;
  enum _type type_name;
   
  type_name = $1.type->t;

  while(s!=NULL){
    s->t->t=type_name;
    char * adr;
    /* if (s->t->t!= _FLOAT) { */
    adr = malloc(sizeof(char) * 11);
    itoa(offset, adr, 10);
    /* } else { */
    /*   adr = malloc(sizeof(char) * 3); */
    /*   adr[0] = 'F'; */
    /*   adr[1] = 'L'; */
    /*   adr[2] = '\0'; */
    /*   adr = concat(adr, s->str); */
    /* } */
    s->t->adresse = adr;
    offset -= 4;
    ajout_symbole(T,s->str,s->t);
    s = s->suivant;
  }

  $$.code = $2.code;
  $$.code_out = $2.code_out;
}
;

declarator_list
: declarator {
  $$.sym=malloc(sizeof(struct symbole));
  $$.sym->str=$1.str;
  $$.sym->t=$1.type;
  $$.sym->suivant=NULL;
  $$.code = $1.code;
  $$.code_out = $1.code_out;
}
| declarator_list ',' declarator {
  $$.sym=malloc(sizeof(struct symbole));
  $$.sym->str=$3.str;
  $$.sym->t=$3.type; 
  $$.sym->suivant=$1.sym;
  $$.code = concat($1.code, $3.code);
  free($3.code);
  $$.code_out = concat($1.code_out, $3.code_out);
  free($3.code_out);
}
;

type_name
: VOID {
  $$.type = malloc(sizeof(struct type));
  $$.type->t = _VOID;
  $$.type->dimension = 0;

  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
}
| INT {
  $$.type = malloc(sizeof(struct type));
  $$.type->t = _INT;
  $$.type->dimension = 0;

  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
}
| FLOAT {
  $$.type = malloc(sizeof(struct type));
  $$.type->t = _FLOAT;
  $$.type->dimension = 0;

  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
}
;

declarator
: IDENTIFIER {
  $$.type = malloc(sizeof(struct type));
  $$.type->dimension = 0;
  $$.type->retour = NULL;
  $$.type->parametres = NULL;
  $$.type->nb_parametres = 0; 
  $$.str = $1;

  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';
}
| '*' IDENTIFIER {
  $$.type = malloc(sizeof(struct type));
  $$.type->dimension = 42; //Ceci est un pointeur. Nous ne savons pas gérer les malloc
  $$.type->retour = NULL;
  $$.type->parametres = NULL;
  $$.type->nb_parametres = 0;
  $$.str = $2;

  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';
}
| IDENTIFIER '[' ICONSTANT ']' {
  $$.type = malloc(sizeof(struct type));
  $$.type->dimension = $3; //Là on peut !
  $$.type->retour = NULL;
  $$.type->parametres = NULL;
  $$.type->nb_parametres = 0;
  $$.str = $1;

  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  $$.code_out=malloc(sizeof(char));
  *($$.code_out)='\0';
}
| declarator '(' parameter_list ')' {
  $$.type = malloc(sizeof(struct type));
  $$.type->dimension = 0;
  $$.type->retour = NULL;
  $$.type->parametres = $3.type->parametres;
  $$.type->nb_parametres = $3.type->nb_parametres;
  $$.str = $1.str;
  $$.type->isExtern = 0;

  int offset_adr = ($3.type->nb_parametres + 1) * 4;
  char * buffer;
  struct type * p;
  for(p = $3.type->parametres; p; p = p->parametres){
    buffer = malloc(sizeof(char) * 11);
    itoa(offset_adr, buffer, 10);
    p->adresse = buffer;
    offset_adr -= 4;
  }

  $$.code=malloc(sizeof(char));
  *($$.code)='\0';

  $$.code_out = concat($1.code_out, $3.code_out);
  free($3.code_out);
}
| declarator '(' ')' {
  $$.type = malloc(sizeof(struct type));
  $$.type->dimension = 0;
  $$.type->retour = NULL;
  $$.type->parametres = NULL;
  $$.type->nb_parametres = 0;
  $$.str = $1.str;
  $$.type->isExtern = 0;

  $$.code=malloc(sizeof(char));
  *($$.code)='\0';

  $$.code_out = $1.code_out;
}
;

parameter_list
: parameter_declaration {
  struct type *param = malloc(sizeof(struct type));
  param->t = $1.type->t;
  param->dimension = 0;
  param->retour = NULL;
  param->parametres = NULL;
  param->nb_parametres = 0;
  $$.type->parametres = param;
  $$.code_out = $1.code_out;
}
| parameter_list ',' parameter_declaration {
  int k = $1.type->nb_parametres+1;
  struct type *t = malloc(sizeof(struct type)*k);
  memcpy(t,$1.type->parametres,sizeof(struct type)*(k-1));
  t[k-1] = *($3.type);
  $$.type->parametres = t;
  $$.type->nb_parametres = k;
  
  $$.code_out = concat($1.code_out, $3.code_out);
  free($3.code_out);
}
;

parameter_declaration
: type_name declarator {
  $$ = $2;
  $$.type->t = $1.type->t;
  ajout_symbole(T,$2.str,$$.type);
}
;

statement
: compound_statement{
  $$ = $1;
  }
| expression_statement{ 
  $$ = $1;
  }
| selection_statement{
  $$ = $1;
  }
| iteration_statement{
  $$ = $1;
  }
| jump_statement{
  $$ = $1;
  }
;

compound_statement
: '{' '}' {  
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
 } 
| '{' { T = nouvelle_table(T);} statement_list '}' { 
  T = T->englobante;
  $$.code = $3.code;
  $$.code_out = $3.code_out;
 }
| '{'{T = nouvelle_table(T);} declaration_list statement_list '}'{
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
  T = T->englobante;  
  $$.code = concat($3.code, $4.code);
  free($4.code);
  $$.code_out = concat($3.code_out, $4.code_out);
  free($4.code_out);
  }
;

declaration_list
: declaration{
  $$ = $1; //TODO
 }
| declaration_list declaration{
  $$ = $1;//TODO
  $$.code = concat($1.code, $2.code);
  free($2.code);
  $$.code_out = concat($1.code_out, $2.code_out);
  free($2.code_out);
 }
;

statement_list
: statement {
  $$ = $1;//TODO
}
| statement_list statement {
 $$ = $1;//TODO
 $$.code = concat($1.code, $2.code);
 free($2.code);
 $$.code_out = concat($1.code_out, $2.code_out);
 free($2.code_out);
}
;

expression_statement
: ';' {
  $$.code=malloc(sizeof(char));
  *($$.code)='\0';
 }
| expression ';' {
  $$ = $1;
}
;

selection_statement
: IF '(' expression ')' statement {
  if( $3.val != 0 )
    $$ = $5;
  //Extension : return
  char * jmp = nextLabel();
  $$.code = concat($3.code, "\tmovl\t%eax, %ecx\n\tjecxz\tLBL");
  $$.code = concat($$.code, jmp);
  $$.code = concat($$.code, "\n");
  $$.code = concat($$.code, $5.code);
  $$.code = concat($$.code, "LBL");
  $$.code = concat($$.code, jmp);
  $$.code = concat($$.code, ":\n");
  free(jmp);
  free($5.code);

  $$.code_out = concat($3.code_out, $5.code_out);
  free($5.code_out);
}
| IF '(' expression ')' statement ELSE statement {
  if( $3.val != 0 )
    $$ = $5;
  else
    $$ = $7;

  char * jmp = nextLabel();
  char * end = nextLabel();
  $$.code = concat($3.code, "\tmovl\t%eax, %ecx\n\tjecxz\tLBL");
  $$.code = concat($$.code, jmp);
  $$.code = concat($$.code, "\n");
  $$.code = concat($$.code, $5.code);
  $$.code = concat($$.code, "\tjmp\tLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, jmp);
  $$.code = concat($$.code, ":\n");
  $$.code = concat($$.code, $7.code);
  $$.code = concat($$.code, "LBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");
  free(jmp);
  free(end);
  free($5.code);
  free($7.code);

  $$.code_out = concat($3.code_out, $5.code_out);
  $$.code_out = concat($$.code_out, $7.code_out);
  free($5.code_out);
  free($7.code_out);
}
;

iteration_statement
: WHILE '(' expression ')' statement {
  if( $3.val != 0 )
    $$ = $5;

  char * begin = nextLabel();
  char * end = nextLabel();
  $$.code = malloc(sizeof(char));
  *($$.code) = '\0';
  $$.code = concat($$.code, "LBL");
  $$.code = concat($$.code, begin);
  $$.code = concat($$.code, ":\n");
  $$.code = concat($$.code, $3.code);
  $$.code = concat($$.code, "\t\tmovl\t%eax, %ecx\n\tjecxz\tLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\n");
  $$.code = concat($$.code, $5.code);
  $$.code = concat($$.code, "\tjmp\tLBL");
  $$.code = concat($$.code, begin);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");
  free(begin);
  free(end);
  free($5.code);
  free($3.code);

  $$.code_out = concat($3.code_out, $5.code_out);
  free($5.code_out);
}
| FOR '(' expression_statement expression_statement expression ')' statement {
  if( $4.val != 0 )
    $$ = $7;

  char * begin = nextLabel();
  char * end = nextLabel();

  $$.code = $3.code;
  $$.code = concat($$.code, "LBL");
  $$.code = concat($$.code, begin);
  $$.code = concat($$.code, ":\n");
  $$.code = concat($$.code, $7.code);
  $$.code = concat($$.code, $4.code);
  $$.code = concat($$.code, "\tmovl\t%eax, %ecx\n\tjecxz\tLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\n");
  $$.code = concat($$.code, $5.code);
  $$.code = concat($$.code, "\tjmp\tLBL");
  $$.code = concat($$.code, begin);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");
  free(begin);
  free(end);
  free($4.code);
  free($5.code);
  free($7.code);

  $$.code_out = concat($3.code_out, $4.code_out);
  $$.code_out = concat($$.code_out, $5.code_out);
  $$.code_out = concat($$.code_out, $7.code_out);
  free($4.code_out);
  free($5.code_out);
  free($7.code_out);
}
| FOR '(' expression_statement expression_statement expression ')' expression {
  //Règle de grammaire ajoutée pour gérer les for sans accolades
  if( $4.val != 0 )
    $$ = $7;

  char * begin = nextLabel();
  char * end = nextLabel();
  $$.code = $3.code;
  $$.code = concat($$.code, "LBL");
  $$.code = concat($$.code, begin);
  $$.code = concat($$.code, ":\n");
  $$.code = concat($$.code, $7.code);
  $$.code = concat($$.code, $4.code);
  $$.code = concat($$.code, "\tmovl\t%eax, %ecx\n\tjecxz\tLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\n");
  $$.code = concat($$.code, $5.code);
  $$.code = concat($$.code, "\tjmp\tLBL");
  $$.code = concat($$.code, begin);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");
  free(begin);
  free(end);
  free($5.code);
  free($7.code);

  $$.code_out = concat($3.code_out, $4.code_out);
  $$.code_out = concat($$.code_out, $5.code_out);
  $$.code_out = concat($$.code_out, $7.code_out);
  free($4.code_out);
  free($5.code_out);
  free($7.code_out);
}
| DO statement WHILE '(' expression ')' {
  $$ = $2;

  char * begin = nextLabel();
  char * end = nextLabel();
  $$.code = malloc(sizeof(char));
  *($$.code) = '\0';
  $$.code = concat($$.code, "LBL");
  $$.code = concat($$.code, begin);
  $$.code = concat($$.code, ":\n");
  $$.code = concat($$.code, $2.code);
  $$.code = concat($$.code, $5.code);
  $$.code = concat($$.code, "\tmovl\t%eax, %ecx\n\tjecxz\tLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, "\n\tjmp\tLBL");
  $$.code = concat($$.code, begin);
  $$.code = concat($$.code, "\nLBL");
  $$.code = concat($$.code, end);
  $$.code = concat($$.code, ":\n");
  free(begin);
  free(end);
  free($5.code);
  free($2.code);

  $$.code_out = concat($2.code_out, $5.code_out);
  free($5.code_out);
}
;

jump_statement
: RETURN ';' {
  if( retour != _VOID ){
    char s[] = "Type de retour faux : VOID attendu.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  $$.code = malloc(sizeof(char));
  *($$.code) = '\0';
  $$.code = concat($$.code, "\tleave\n\tret\n");

  $$.code_out = malloc(sizeof(char));
  *($$.code_out) = '\0';
}
| RETURN expression ';' {
  if( ($2.type->t != retour) && ($2.type->t == _VOID) ){
    char s[] = "Type de retour faux.";
    yyerror(s);
    exit(EXIT_FAILURE);
  }
  $$.code = concat($2.code, "\tleave\n\tret\n");
  $$.code_out = $2.code_out;
}
;

program
: external_declaration {
  s=malloc(sizeof(char)*999999);
  fprintf(output,"%s",s);
  //code remonté à écrire

  fprintf(output, "%s%s", $1.code, $1.code_out?$1.code_out:"");
 }
| program external_declaration {
  //code remonté à écrire
  fprintf(output, "%s%s", $2.code, $2.code_out?$1.code_out:"");
}
;

external_declaration
: function_definition {
  $$ = $1;//  ajout_symbole(T,$1.str,$1.type->retour);

  $$.code = malloc(sizeof(char));
  *($$.code) = '\0';
  $$.code = concat($$.code, "\t.globl\t");
  $$.code = concat($$.code, $1.str);
  $$.code = concat($$.code, "\n\t.type\t");
  $$.code = concat($$.code, $1.str);
  $$.code = concat($$.code, ", @function\n");
  $$.code = concat($$.code, $1.str);
  $$.code = concat($$.code, ":\n");
  $$.code = concat($$.code, $1.code);
  $$.code = concat($$.code, "\t.size\t");
  $$.code = concat($$.code, $1.str);
  $$.code = concat($$.code, ", .-");
  $$.code = concat($$.code, $1.str);
  $$.code = concat($$.code, "\n");

  free($1.code);
}
| declaration {
  $$ = $1;

  $$.code = malloc(sizeof(char));
  *($$.code) = '\0';
  $$.code = concat($$.code, "\t.globl\t");
  $$.code = concat($$.code, $1.str);
  $$.code = concat($$.code, "\n\t.type\t");
  $$.code = concat($$.code, $1.str);
  $$.code = concat($$.code, ", @object\n");
  $$.code = concat($$.code, $1.str);
  $$.code = concat($$.code, ":\n");
  $$.code = concat($$.code, $1.code);

  free($1.code);
}
;

function_definition
: type_name declarator {
  retour = $1.type->t;
  if ($1.type->dimension > 0) {
    char s[] = "Retour de tableau invalide";
    yyerror(s);
    exit(EXIT_FAILURE);
  }

} compound_statement {
   $$.str = $2.str; 
   $$.type = $2.type;
   $$.type->retour = malloc(sizeof(struct type));
   $$.type->retour->dimension = 0;
   $$.type->retour->retour = NULL;
   $$.type->retour->nb_parametres = 0;
   $$.type->retour->parametres = NULL;
   $$.type->retour->t = retour;
   ajout_symbole(T,$2.str,$$.type);

   $$.code = $4.code;

   //Réinitialisation de offset
   offset = -4;

  $$.code_out = $4.code_out;
}
;

%%
int yyerror (char *s) {
  fflush (stdout);
  fprintf (stderr, "%s:%d:%d: %s\n", file_name, yylineno, column, s);
  return 0;
}


int main (int argc, char *argv[]) {
  FILE *input = NULL;
  T=nouvelle_table(NULL);

  struct type retvoid;
  retvoid.t = _VOID;
  struct type paramint;
  paramint.t = _INT;
  paramint.dimension = 0;
  paramint.retour = NULL;
  paramint.nb_parametres = 0;
  paramint.parametres = NULL;
  paramint.adresse = NULL;
  paramint.isExtern = 0;
  struct type paramfloat;
  paramfloat.t = _FLOAT;
  paramfloat.dimension = 0;
  paramfloat.retour = NULL;
  paramfloat.nb_parametres = 0;
  paramfloat.parametres = NULL;
  paramfloat.adresse = NULL;
  paramfloat.isExtern = 0;
  struct type printint;
  printint.t = _VOID;
  printint.dimension = 0;
  printint.retour = &retvoid;
  printint.nb_parametres = 1;
  printint.parametres = &paramint;
  printint.adresse = "printint";
  printint.isExtern = 1;
  struct type printfloat;
  printfloat.t = _VOID;
  printfloat.dimension = 0;
  printfloat.retour = &retvoid;
  printfloat.nb_parametres = 1;
  printfloat.parametres = &paramfloat;
  printfloat.adresse = "printfloat";
  printfloat.isExtern = 1;

  ajout_symbole(T,"printint",&printint);
  ajout_symbole(T,"printfloat",&printfloat);

  if (argc==2) {
    input = fopen (argv[1], "r");
    file_name = strdup (argv[1]);
    if (input) {
      char *output_file_name = strdup (argv[1]);
      yyin = input;
      output_file_name[strlen(output_file_name)-1] = 's';
      output = fopen (output_file_name, "w");
      if (output){
	yyparse();
	fclose(output);
      }
      else{
	fprintf (stderr, "%s: Could not open %s.\n", *argv, output_file_name);
	return 1;
      }
      free(output_file_name);
      fclose(input);
    }
    else {
      fprintf (stderr, "%s: Could not open %s.\n", *argv, argv[1]);
      return 1;
    }
    free(file_name);
  }
  else {
    fprintf (stderr, "%s: error: no input file\n", *argv);
    return 1;
  }
  return 0;
}
>>>>>>> .r34
