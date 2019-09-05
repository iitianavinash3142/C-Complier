%{
	#include <bits/stdc++.h>
	using namespace std;
	extern int yylex();
	extern int yyparse();
	extern int yylineno;
	void yyerror (string error)
	{
	  cout << error << endl;
	}

	/*top*/
	bool sayno = true;
	bool flagfunctioncall = false;
	vector< pair<int , int> > pairs;
	map<int , string> labelmap;
	set<int> labels;
	int label_counter = 0;
	ofstream myfile ("Three_address_code.txt");

	int counter = 0;
	int counter_params = 0;
	int counter_args = 0;
	vector<int> counter_cases;
	int k = -1;
	int counter_tmp = 0;
	int counter_flt = 0;
	int scope = 0;
	bool function_flag = false;
	bool arr_code_generation = true;
	bool func_var_node_flag = false;
	bool case_colon = false;
 bool flag = false;
	int next_quad = 0;
	int offset_counter = 0;
	struct quadruple{
			string addrcode;
			string op1;
			string op2;
			string op3;
			string operator1;
			int pos;
			string type;
			quadruple(){
				op1 = "";
				op2 = "";
				op3 = "";
				addrcode = "";
				operator1 = "";
				pos = 0;
				type = "int";
			}
	};
	struct node{
			string fname;
	    string name;
	    string datatype;
			int valid;
			int scope;
			quadruple* qt;
			int arr = 0;
			int width;
			vector<int> dim_list_num;
			int offset;
	};

	struct func_node{
	    string name;
	    string return_type;
	    vector <node*> param_list;
			map<string , int> param_map;
			map < pair < int , string > , node* >  local_variable;
			int params_count;
			int valid;
	};

	struct list_attr{
	    vector <node*> list_var;
	    int size;
	};

	struct node1 {
			string type;
			int val1;
			double val2;
			node* addr;
			string code;
			node1(){
				type = "Invalid";
				val1 = INT_MIN;
				val2 = FLT_MIN;
				addr = NULL;
				code = "";
			}
	};

	vector<int> falselist;
  vector <int> nextlist;
	vector <int> breaklist;
	vector <int> caselist;
	vector <int> finalbreaklist;
	vector<string> curr_variable;




	func_node* curr_function;
	node* curr_var_node;
	node* curr_temp;
	map < string , func_node* > function_name_table;
	map < pair < int , string > , node* >  global_variable;
	map < string , func_node* > :: iterator itf;
	map < pair < int , string > , node* > :: iterator itg;
	map < pair < int , string > , node* > :: iterator itr;

	char* st1;
	string st;
	node1* tp;

	vector<quadruple*> intermediate_code;

	string variable_datatype(node* var);
	func_node* check_function_exist(string key);
	func_node* delete_var_list(func_node* func_node_ptr , int scope);
	bool check_variable_declared_in_present_scope(map < pair < int , string > , node* > local , int scope , string key);
	node* check_variable_declared_above(func_node* func_node_ptr , int scope , string key);
	void insert_into_symbol_table(func_node* func_node_ptr , node* x);

	void gen(quadruple* s , vector<quadruple*>& v);
	void backpatch(vector<int>& list , vector<quadruple*>& v , int nextquad);
%}
%union{ int num;
        char* strval;
				char* str;
        double floatval;
        struct node1* x;
				struct node* t1;
				struct node* list[1000];
				struct node1* str_list[1000];
}

%token SEMI COLON EQUAL GT LT GE LE EQ NE PLUS MINUS MUL DIV AND OR NOT LB_CURLY RB_CURLY LB_SQUARE RB_SQUARE LB_ROUND RB_ROUND COMMA MAIN INT FLOAT FOR WHILE IF ELSE SWITCH CASE BREAK CONTINUE DEFAULT RETURN VOID
%token <strval> NAME
%token <num> INTNUM
%token <floatval> FINTNUM

%type<x> NUM UNARY_EXPRESSION TERM EXPRESSIONS DIVMUL_EXPRESSION SIMPLE_EXPRESSION LOGICAL_EXPRESSION AND_EXPRESSION RELATIONAL_EXPRESSION FUNCTION_CALL SWITCH_HEADER
%type<num> OPERATOR1 OPERATOR2 OPERATOR3 UNARY_OPERATOR ELSE_HEADER CONDITION IF_HEADER WHILE_LOOP WHILE_LOOP_HEADER LOOP FOR_LOOP FOR_LOOP_HEADER FOR_LOOP_HEADER2 DEFAULT_HEADER CASE_HEADER STATEMENT M N
%type<str> TYPE
%type<t1> VARIABLE PARAMETER IDENTIFIER
%type<list> PARAMETERS PARAMETER_LIST VAR_LIST
%type<str_list > ARGS_LIST ARGS CASES DEFAULT_CASE

%start PROGRAM

%%

PROGRAM : DECL_LIST MAIN_FUNCTION
				;

DECL_LIST :	DECL DECL_LIST
						|
						;

DECL : VAR_DECL
				| FUNC_DECL
				;

FUNC_HEADER : TYPE IDENTIFIER LB_ROUND PARAMETERS RB_ROUND
						{
								scope++;
								curr_function = new func_node;
								curr_function->return_type = $1;
								curr_function->name = $2->name;
								for(int i = 0; i < counter_params; i++){
										if(curr_function->param_map.find($4[i]->name) == curr_function->param_map.end())curr_function->param_map[$4[i]->name] = i;
										else cout<<"error : two parameters have same name\n";
										curr_function->param_list.push_back($4[i]);
								}
								curr_function->params_count = counter_params;
								counter_params = 0;
								function_flag = false;


								quadruple* q  = new quadruple;
								q->operator1 = "FBEG";
								q->op1 = curr_function->name;
								q->op2 = to_string(counter_params);
								q->addrcode = "func begin " + curr_function->name + "," + to_string(counter_params);
								gen(q , intermediate_code);
								next_quad++;
								arr_code_generation = true;
								if(check_function_exist(curr_function->name) == NULL)function_name_table[curr_function->name] = curr_function;
								else cout<<"error : two function with same name exist\n";
						}
						;

FUNC_DECL : FUNC_HEADER LB_CURLY STATEMENTS RB_CURLY
						{
								curr_function = delete_var_list(curr_function , scope);
								function_name_table[curr_function->name] = curr_function;
								scope--;
								for(int i = 0; i < finalbreaklist.size(); i++)backpatch(finalbreaklist , intermediate_code , next_quad - 1);finalbreaklist.clear();
								quadruple* q  = new quadruple;
								q->operator1 = "FEND";
								q->addrcode = "func end";
								gen(q , intermediate_code);
								next_quad++;
						}
					;


PARAMETERS : PARAMETER_LIST
							{
								for(int i = 0; i < counter_params; i++)$$[i] = $1[i];
							}
						| /*epsilon*/ {
						vector<node*> tmp;
						for(int i = 0; i < tmp.size(); i++)$$[i] = tmp[i];
						}
						;

PARAMETER_LIST : PARAMETER_LIST COMMA PARAMETER
									{
											$$[counter_params++] = $3;
									}
								| PARAMETER
									{
											$$[counter_params++] = $1;
									}
								;
PARAMETER : TYPE VARIABLE{
								arr_code_generation = true;
								if($1 == "void"){
									cout<<"error : void datatype not allowed in parameters\n";
								}
								$2->datatype = $1;
								$2->scope = -1;
								$$ = $2;
								quadruple* q = new quadruple;
								q->op1 = $2->datatype;
								q->op2 = $2->name;
								q->op3 = "";
								q->operator1 = "POPPARAM";
								q->addrcode = $2->datatype + " " + $2->name ;
								gen(q , intermediate_code);
								next_quad++;
					}
					;

MAIN_HEADER : MAIN LB_ROUND RB_ROUND
							{
									scope++;
									curr_function = new func_node;
									curr_function->return_type = "int";
									curr_function->name = "main";
									quadruple* q  = new quadruple;
									q->operator1 = "FBEG";
									q->op1 = curr_function->name;
									q->addrcode = "func begin " + curr_function->name ;
									gen(q , intermediate_code);
									next_quad++;
							}

MAIN_FUNCTION : MAIN_HEADER LB_CURLY STATEMENTS RB_CURLY
							{
									curr_function = delete_var_list(curr_function , scope);
									scope--;
									function_name_table[curr_function->name] = curr_function;
									quadruple* q  = new quadruple;
									q->operator1 = "FEND";
									q->addrcode = "func end";
									gen(q , intermediate_code);
									for(int i = 0; i < finalbreaklist.size(); i++)backpatch(finalbreaklist , intermediate_code , next_quad - 1);finalbreaklist.clear();
									next_quad++;
							}
							;

STATEMENTS : STATEMENTS STATEMENT
							{
							for(int i = 0; i < nextlist.size(); i++)backpatch(nextlist , intermediate_code , next_quad);nextlist.clear();
							}
							| /*epsilon*/
							;

STATEMENT : 	VAR_DECL {$$ = 0;}
							| EXPRESSIONS SEMI {$$ = 1;}
							| RETURN_STATEMENT SEMI {$$ = 2;}
							| LBC STATEMENTS RB_CURLY {if(scope > 0)curr_function = delete_var_list(curr_function , scope);scope--; $$ = 3; }
							| LOOP { nextlist.push_back($1);for(int i = 0; i < breaklist.size(); i++)backpatch(breaklist , intermediate_code , next_quad);breaklist.clear();$$ = 4;}
							| CONDITION
							{
									nextlist.push_back($1);
									$$ = 5;
							}
							| BREAK SEMI
							{
									$$ = 6;
									if(case_colon == false){
											if(scope == 1) finalbreaklist.push_back(next_quad);
											else breaklist.push_back(next_quad);
											quadruple* q  = new quadruple;
											q->operator1 = "GOTO";
											q->addrcode = "go to ";
											gen(q , intermediate_code);
											next_quad++;
									}
							}
							;

LBC : LB_CURLY { scope++; }

VAR_DECL : TYPE VAR_LIST SEMI
						{
								arr_code_generation = true;
								if(function_flag){
										cout<<"error : void datatype not allowed for variables\n";
										function_flag = false;
								}
								bool flag = true;
								for(int i = 0 ; i < counter; i++){
										$2[i]->datatype = $1;
									//	cout<<"yasss "<<$2[i]->name<<" "<<$2[i]->datatype<<" "<<$2[i]->arr<<"\n";
										if($2[i]->scope == 0){
												if(global_variable.find(make_pair($2[i]->scope , $2[i]->name)) == global_variable.end()){
														$2[i]->offset = offset_counter;
														if($2[i]->arr == 0){
																if($2[i]->datatype == "int")offset_counter += 4;
																else offset_counter += 8;
														}
														else if($2[i]->arr == 1){
																if($2[i]->datatype  == "int")offset_counter += 4*$2[i]->dim_list_num[0];
																else offset_counter += 8*$2[i]->dim_list_num[0];
														}
														else{
																if($2[i]->datatype  == "int")offset_counter += 4*$2[i]->dim_list_num[0]*$2[i]->dim_list_num[1];
																else offset_counter += 8*$2[i]->dim_list_num[0]*$2[i]->dim_list_num[1];
														}
														quadruple* q  = new quadruple;
														q->operator1 = "VAR_DECL";
														int m = offset_counter - $2[i]->offset;
														$2[i]->name = $2[i]->name + to_string($2[i]->offset);
														if($2[i]->arr == 0)q->addrcode = $2[i]->datatype + " "+  $2[i]->name + "," + to_string(m);
														else if($2[i]->arr == 1) q->addrcode = $2[i]->datatype + " "+ $2[i]->name + "["+ to_string($2[i]->dim_list_num[0]) +"]" + "," + to_string(m);
														else q->addrcode = $2[i]->datatype + " "+ $2[i]->name  + to_string($2[i]->offset) + "["+ to_string($2[i]->dim_list_num[0]) +"]["+ to_string($2[i]->dim_list_num[1]) +"] ," + to_string(m);
														q->op1 = $2[i]->datatype;
														q->op2 = $2[i]->name + to_string($2[i]->offset);
														q->op3 = to_string($2[i]->offset);
														gen(q , intermediate_code);
														next_quad++;

														global_variable[make_pair($2[i]->scope , $2[i]->name)] = $2[i];}
												else{
														cout<<"error : "<<$2[i]->name<<" declared for second time in global scope\n";
												}
										}
										else{
												if(curr_function->local_variable.find(make_pair($2[i]->scope , $2[i]->name)) == curr_function->local_variable.end()){
														$2[i]->offset = offset_counter;
														if($2[i]->arr == 0){
																if($2[i]->datatype  == "int")offset_counter += 4;
																else offset_counter += 4;
														}
														else if($2[i]->arr == 1){
																if($2[i]->datatype  == "int")offset_counter += 4*$2[i]->dim_list_num[0];
																else offset_counter += 4*$2[i]->dim_list_num[0];
														}
														else{
																if($2[i]->datatype  == "int")offset_counter += 4*$2[i]->dim_list_num[0]*$2[i]->dim_list_num[1];
																else offset_counter += 4*$2[i]->dim_list_num[0]*$2[i]->dim_list_num[1];
														}
														curr_function->local_variable[make_pair($2[i]->scope , $2[i]->name)] = $2[i];
														quadruple* q  = new quadruple;
														if($2[i]->arr == 0)q->operator1 = "VAR_DECL";
														else  q->operator1 = "ARR_DECL";
														int m = offset_counter - $2[i]->offset;
													  if($2[i]->arr == 0)q->addrcode = $2[i]->datatype  + " "+ $2[i]->name + "," + to_string(m);
														else if($2[i]->arr == 1) q->addrcode = $2[i]->datatype  + " "+ $2[i]->name + "["+ to_string($2[i]->dim_list_num[0]) +"]" + "," + to_string(m);
														else q->addrcode = $2[i]->datatype  + " "+ $2[i]->name + to_string($2[i]->offset)+ "["+ to_string($2[i]->dim_list_num[0]) +"]["+ to_string($2[i]->dim_list_num[1]) +"] ," + to_string(m);
														q->op1 = $2[i]->datatype;
														q->op2 = $2[i]->name+  to_string($2[i]->offset);
														q->op3 = to_string($2[i]->offset);
														gen(q , intermediate_code);
														next_quad++;
														}
												else{
														cout<<"error : "<<$2[i]->name<<" declared for second time in present scope\n";
												}
										}
								}
								counter = 0;
						}
						;
TYPE : INT {
							arr_code_generation = false;
							counter = 0;
							func_var_node_flag = true;
							char* t1 = (char*)malloc(1000);
							sprintf(t1 , "int");
							$$ = t1;
			}
			| FLOAT{
							counter = 0;
							arr_code_generation = false;
							func_var_node_flag = true;
							char* t1 = (char*)malloc(1000);
							sprintf(t1 , "float");
							$$ = t1;
			}
			| VOID {
							arr_code_generation = false;
							counter = 0;
							func_var_node_flag = true;
							char* t1 = (char*)malloc(1000);
							sprintf(t1 , "void");
							$$ = t1;
							function_flag = true;
			}
			;
VAR_LIST : VAR_LIST COMMA VARIABLE
							{
									$$[counter++] = $3;
							}
						| VARIABLE {
									$$[counter++] = $1;
						}
						;

VARIABLE : IDENTIFIER	{ $$ = $1; }
					| IDENTIFIER LB_SQUARE TERM RB_SQUARE
					{
							if($3->type != "int"){
									cout<<"error : index must be integer\n";
									exit(0);
							}
							if(!arr_code_generation){
										$$ = $1;$$->arr = 1;$$->dim_list_num.push_back($3->val1);
							}
							else{
										if($3->val1 != INT_MIN && $3->val1 >= $1->dim_list_num[0]){
												cout<<"error : index exceeding array limit\n";
												exit(0);
										}
										$$ = new node(*$1);
										quadruple* q  = new quadruple;
										q->operator1 = "ARR_REF";
										q->op1 = $$->name;
										q->op2 = "&" + $1->name;
										q->addrcode = $$->name + " = " + q->op2;
										q->op3 = $3->addr->name;

										quadruple* q1  = new quadruple;
										q1->operator1 = "ASSGN";
										q1->op1 = "_t" + to_string(counter_tmp++);
										q1->op2 = "4";
										q1->addrcode = q1->op1 + " = " + q1->op2;

										quadruple* q2  = new quadruple;
										q2->operator1 = "*";
										q2->op1 = "_t" + to_string(counter_tmp++);
										q2->addrcode = q2->op1 + " = " + q1->op1 + "*" + $3->addr->name;
										q2->op2 = q1->op1;
										q2->op3 = $3->addr->name;

										quadruple* q3  = new quadruple;
										q3->operator1 = "+";
										q3->op1 = "_t" + to_string(counter_tmp++);
										q3->addrcode = q3->op1 + " = " + q->op2 + "+" + q2->op1;
										q3->op2 = q->op2;
										q3->op3 = q2->op1;

										$$->name =  "(" + q3->op1 + ")";

										gen(q1 , intermediate_code);
										next_quad++;
										gen(q2 , intermediate_code);
										next_quad++;
										gen(q3 , intermediate_code);
										next_quad++;
										$$->qt = q3;
										curr_function->local_variable[make_pair($$->scope , $$->name)] = $$;
							}
					}
					| IDENTIFIER LB_SQUARE TERM RB_SQUARE LB_SQUARE TERM RB_SQUARE
					{
							if($3->type != "int" || $6->type != "int"){
									cout<<"error : index must be integer\n";
									exit(0);
							}
							if(!arr_code_generation){$$ = $1;$$->arr = 2;$$->dim_list_num.push_back($3->val1);$$->dim_list_num.push_back($6->val1);}
							else{
										if(($3->val1 != INT_MIN && $3->val1 >= $1->dim_list_num[0]) || ($6->val1 != INT_MIN && $6->val1 >= $1->dim_list_num[1])){
												cout<<"error : index exceeding array limit\n";
												exit(0);
										}

										//------------------------------------------------------------------

										$$ = new node(*$1);
										quadruple* q  = new quadruple;
										q->operator1 = "ARR_REF";
										q->op1 = $$->name;
										q->op2 = "&" + $1->name;
										q->addrcode = $$->name + " = " + q->op2;

										quadruple* q1  = new quadruple;
										q1->operator1 = "ASSGN";
										q1->op1 = "_t" + to_string(counter_tmp++);
										q1->op2 = "4";
										q1->addrcode = q1->op1 + " = " + q1->op2;

										quadruple* q5  = new quadruple;
										q5->operator1 = "*";
										q5->op1 = "_t" + to_string(counter_tmp++);
										q5->addrcode = q5->op1 + " = " + "4" + "*" + to_string($1->dim_list_num[1]);
										q5->op2 = "4";
										q5->op3 = to_string($1->dim_list_num[1]);

										quadruple* q6  = new quadruple;
										q6->operator1 = "*";
										q6->op1 = "_t" + to_string(counter_tmp++);
										q6->addrcode = q6->op1 + " = " + q5->op1 + "*" + $3->addr->name;
										q6->op2 = q5->op1;
										q6->op3 = $3->addr->name;

										quadruple* q2  = new quadruple;
										q2->operator1 = "*";
										q2->op1 = "_t" + to_string(counter_tmp++);
										q2->addrcode = q2->op1 + " = " + q1->op1 + "*" + $6->addr->name;
										q2->op2 = q1->op1;
										q2->op3 = $6->addr->name;

										quadruple* q4  = new quadruple;
										q4->operator1 = "+";
										q4->op1 = "_t" + to_string(counter_tmp++);
										q4->addrcode = q4->op1 + " = " + q6->op1 + "+" + q2->op1;
										q4->op2 = q6->op1;
										q4->op3 = q2->op1;

										quadruple* q3  = new quadruple;
										q3->operator1 = "+";
										q3->op1 = "_t" + to_string(counter_tmp++);
										q3->addrcode = q3->op1 + " = " + q->op2 + "+" + q4->op1;
										q3->op2 = q->op2;
										q3->op3 = q4->op1;

										$$->name =  "(" + q3->op1 + ")";

										gen(q1 , intermediate_code);
										next_quad++;
										gen(q5 , intermediate_code);
										next_quad++;
										gen(q6 , intermediate_code);
										next_quad++;
										gen(q2 , intermediate_code);
										next_quad++;
										gen(q4 , intermediate_code);
										next_quad++;

										gen(q3 , intermediate_code);
										next_quad++;
										curr_function->local_variable[make_pair($$->scope , $$->name)] = $$;
							}
					}
					;


IF_HEADER : IF LB_ROUND EXPRESSIONS RB_ROUND
						{
							scope++;
							if($3->type != "Invalid"){
									falselist.push_back( next_quad );
									$$ = next_quad;
									quadruple* q  = new quadruple;
									q->operator1 = "IF";
									q->addrcode = "if( " + $3->addr->name + " ) go to ";
									q->op1 = $3->addr->name;
									gen(q , intermediate_code);
									next_quad++;
							}
						}
						;

ELSE_HEADER : RB_CURLY ELSE LB_CURLY
						{
							if(scope > 0)curr_function = delete_var_list(curr_function , scope);
							quadruple* q  = new quadruple;
							q->operator1 = "GOTO";
							q->addrcode = "go to ";
							gen(q , intermediate_code);
							$$ = next_quad;
							next_quad++;
							backpatch(falselist , intermediate_code , next_quad);
						}
						;

SWITCH_HEADER : SWITCH LB_ROUND TERM RB_ROUND
							{
									$$ = new node1(*$3);
									counter_cases.push_back(0);
									k++;
									curr_variable.push_back($3->addr->name);
							}
							;

CONDITION : IF_HEADER	LB_CURLY STATEMENTS ELSE_HEADER STATEMENTS RB_CURLY
							{
									if(scope > 0)curr_function = delete_var_list(curr_function , scope);
									scope--;
									$$ = $4;
									falselist.pop_back();
							}
 							| IF_HEADER LB_CURLY STATEMENTS RB_CURLY
							{
								if(scope > 0)curr_function = delete_var_list(curr_function , scope);
									$$ = $1;
									falselist.pop_back();
								scope--;
							}
							| SWITCH_HEADER LB_CURLY CASES DEFAULT_CASE RB_CURLY
							{
									for(int i = 0; i < counter_cases[counter_cases.size() - 1]; i++){
											if($1->type != $3[i]->type){
													cout<<"error : switch case datatype not matched\n";
													exit(0);
													break;
											}
									}
									curr_variable.pop_back();
									$$ = caselist[caselist.size() - 1];
									caselist.pop_back();
									counter_cases.pop_back();
							}
							;

CASE_HEADER : CASE TERM COLON
							{
								scope++;
								if(caselist.size() > counter_cases.size() - 1){
										backpatch(caselist , intermediate_code , next_quad);
										caselist.pop_back();
								}
								quadruple* q  = new quadruple;
								q->operator1 = "==";
								q->op1 = "_t" + to_string(counter_tmp++);
								q->op2 = curr_variable[curr_variable.size() - 1];
								q->op3 = $2->addr->name;
								q->pos = -1;
								q->addrcode = q->op1 + " = " + q->op2 + "==" + q->op3;
								gen(q , intermediate_code);
								next_quad++;

								caselist.push_back(next_quad);
								$$ = next_quad;
								quadruple* q1  = new quadruple;
								q1->operator1 = "IF";
								q1->addrcode = "if (" + q->op1  + ") go to ";
								q1->op1 = q->op1;

								gen(q1 , intermediate_code);
								next_quad++;
								tp = new node1(*$2);
								case_colon = true;
							}
						;

DEFAULT_HEADER : DEFAULT COLON
								{
										case_colon = true;
										$$ = next_quad;
										if(caselist.size() > counter_cases.size() - 1){
												backpatch(caselist , intermediate_code , next_quad);
												caselist.pop_back();
										}
										caselist.push_back(next_quad);
										quadruple* q  = new quadruple;
										q->operator1 = "GOTO";
										q->addrcode = "go to ";
										gen(q , intermediate_code);
										next_quad++;
										scope++;
							  }
								;

CASES :  CASES CASE_HEADER  LB_CURLY STATEMENTS STATEMENT RB_CURLY
			{
					if($5 != 6){
							cout<<"error ; switch case statement not ending with break\n";
							exit(0);
					}
					case_colon =  false;
					if(scope > 0)curr_function = delete_var_list(curr_function , scope);
					$$[counter_cases[counter_cases.size() - 1]++] = tp;
					scope--;
			}
 			| CASE_HEADER  LB_CURLY STATEMENTS STATEMENT RB_CURLY
			{
					if($4 != 6){
							cout<<"error ; switch case statement not ending with break\n";
							exit(0);
					}
					case_colon =  false;
					if(scope > 0)curr_function = delete_var_list(curr_function , scope);
					scope--;
					$$[counter_cases[counter_cases.size() - 1]++] = tp;
			}
			;


DEFAULT_CASE :DEFAULT_HEADER LB_CURLY  STATEMENTS STATEMENT RB_CURLY
							{
									if($4 != 6){
											cout<<"error ; switch case statement not ending with break\n";
									}
									case_colon =  false;
									if(scope > 0)curr_function = delete_var_list(curr_function , scope);
									scope--;
									$$[counter_cases[counter_cases.size() - 1]] = new node1;
							}
							|/*epsilon*/ { $$[counter_cases[counter_cases.size() - 1]] = new node1; }
							;

LOOP : FOR_LOOP {$$ = $1; }
		 | WHILE_LOOP {$$ = $1;}
		 ;
N : SEMI {$$ = next_quad;}
FOR_LOOP_HEADER2 : FOR LB_ROUND EXPRESSIONS N EXPRESSIONS SEMI
									{
											if($3->type != "Invalid" && $5->type != "Invalid" ){
													$$ = next_quad;
													quadruple* q  = new quadruple;
													q->operator1 = "IF";
													q->addrcode = "if( " + $5->addr->name + " ) go to ";
													q->op1 = $5->addr->name;
													q->pos = $4 - next_quad;
													gen(q , intermediate_code);
													next_quad++;
											}
									}
									;

FOR_LOOP_HEADER : FOR_LOOP_HEADER2 EXPRESSIONS RB_ROUND
								{
									scope++;
									$$ = $1;
								}
FOR_LOOP : FOR_LOOP_HEADER	LB_CURLY STATEMENTS RB_CURLY
					{
							if(scope > 0)curr_function = delete_var_list(curr_function , scope);
							pairs.push_back(make_pair(next_quad , $1));
							quadruple* q  = new quadruple;
							if(labelmap.find($1) == labelmap.end()){
										labelmap.insert(make_pair($1 , "LABEL" + to_string(label_counter++)));
							}
							q->operator1 = "GOTO";
							q->addrcode = "go to ";
							gen(q , intermediate_code);
							$$ = $1;
							next_quad++;
							scope--;
					}
					;

M :  LB_ROUND {$$ = next_quad;}

WHILE_LOOP_HEADER : WHILE M EXPRESSIONS RB_ROUND
									{
											scope++;
											if($3->type != "Invalid"){
													$$ = next_quad;
													quadruple* q  = new quadruple;
													q->operator1 = "IF";
													q->addrcode = "if( " + $3->addr->name + " ) go to ";
													q->op1 = $3->addr->name;
													q->pos = $2 - next_quad;
													gen(q , intermediate_code);
													next_quad++;
											}
								 }
								 ;
WHILE_LOOP : WHILE_LOOP_HEADER LB_CURLY STATEMENTS RB_CURLY
						{
							if(scope > 0)curr_function = delete_var_list(curr_function , scope);
							pairs.push_back(make_pair(next_quad , $1));
							quadruple* q  = new quadruple;
							if(labelmap.find($1) == labelmap.end()){
										labelmap.insert(make_pair($1 , "LABEL" + to_string(label_counter++)));
							}
							q->operator1 = "GOTO";
							q->addrcode = "go to ";
							gen(q , intermediate_code);
							$$ = $1;
							next_quad++;
							scope--;
						}
						;

RETURN_STATEMENT : RETURN
									{
											if(curr_function->return_type != "void"){
													cout<<"error : no return value\n";
											}
											else{
													quadruple* q  = new quadruple;
													q->operator1 = "RETURN";
													q->addrcode = "return";
													gen(q , intermediate_code);
													next_quad++;
											}
									}
									| RETURN EXPRESSIONS
									{
											if($2->type != curr_function->return_type){
													cout<<"error : function return type Invalid\n";
													if(flagfunctioncall == true){
															exit(0);
															sayno = false;
													}
											}
											else {
											quadruple* q  = new quadruple;
											q->operator1 = "RETURN";
											q->addrcode = "return " + $2->addr->name;
											q->op1 = $2->addr->name;
											gen(q , intermediate_code);
											next_quad++;
											}
									}
									;



EXPRESSIONS :	VARIABLE EQUAL EXPRESSIONS
						{
								$$ = new node1(*$3);
								node* tmp = check_variable_declared_above(curr_function , scope , $1->name);
								if(tmp == NULL){
										$$->type = "Invalid";
										cout<<"error : "<<$1->name<<" not declared\n";
								}
								else {
								//cout<<"assn "<<tmp->datatype<<" "<<$3->type<<"\n";
								//cout<<"assn "<<tmp->name<<" "<<$3->addr->name<<"\n";
										if(tmp->datatype == $3->type){


												$$->type = tmp->datatype;

												$$->addr = new node(*$3->addr);
												quadruple* q  = new quadruple;
												if($3->addr->name == "result")q->operator1 = "REF_PARAM_ASSGN";
												else q->operator1 = "ASSGN";
												q->op1 = tmp->name;
												q->op2 = $3->addr->name;
												q->addrcode = tmp->name + " = " + $3->addr->name;
												q->type = tmp->datatype;
												gen(q , intermediate_code);

												next_quad++;
										}
										else{
												$$->type = "Invalid";
												cout<<"error : variable "<<$1->name<<" datatype not matched to rhs expression datatype\n";
										}
								}

						}
						| 	LOGICAL_EXPRESSION
						{
								$$ = $1;
						}
						;

LOGICAL_EXPRESSION 	:	LOGICAL_EXPRESSION OR AND_EXPRESSION
										{
												$$ = new node1(*$1);
												if($1->type == "Invalid" || $3->type == "Invalid"){
														$$->type = "Invalid";
												}
												else{

														$$->type = "Valid";
														$$->addr = new node(*$1->addr);
														$$->addr->name = "_t" + to_string(counter_tmp++);
														insert_into_symbol_table(curr_function  , $$->addr);
														quadruple* q  = new quadruple;
														q->operator1 = "OR";
														q->op1 = $$->addr->name;
														q->op2 = $1->addr->name;
														q->op3 = $3->addr->name;
														q->addrcode = $$->addr->name + " = " + $1->addr->name + "||" + $3->addr->name;
														gen(q , intermediate_code);
														next_quad++;
												}
										}
										| 	AND_EXPRESSION
										{
												$$ = $1;
										}
										;

AND_EXPRESSION 	:	AND_EXPRESSION AND RELATIONAL_EXPRESSION
								{
										$$ = new node1(*$1);
										if($1->type == "Invalid" || $3->type == "Invalid"){
												$$->type = "Invalid";
										}
										else{

												$$->type = "Valid";
												$$->addr = new node(*$1->addr);
												$$->addr->name = "_t" + to_string(counter_tmp++);
												insert_into_symbol_table(curr_function  , $$->addr);
												quadruple* q  = new quadruple;
												q->operator1 = "AND";
												q->op1 = $$->addr->name;
												q->op2 = $1->addr->name;
												q->op3 = $3->addr->name;
												q->type = $$->addr->datatype;
												q->addrcode = $$->addr->name + " = " + $1->addr->name + "&&" + $3->addr->name;
												gen(q , intermediate_code);
												next_quad++;
										}
								}
								|	RELATIONAL_EXPRESSION
								{
										$$ = $1;
								}
								;

RELATIONAL_EXPRESSION 	:	RELATIONAL_EXPRESSION OPERATOR3 SIMPLE_EXPRESSION
													{
															$$ = new node1(*$1);
															if($1->type == $3->type && $3->type != "Invalid"){

																	$$->type = $1->type;
																	$$->addr = new node(*$1->addr);
																	$$->addr->name = "_t" + to_string(counter_tmp++);
																	insert_into_symbol_table(curr_function  , $$->addr);
																	quadruple* q  = new quadruple;
																	q->op1 = $$->addr->name;
																	q->op2 = $1->addr->name;
																	q->op3 = $3->addr->name;
																	q->type = $$->type;
																	string xy;
																	if($2 == 0)xy = "==";
																	else if($2 == 1)xy = "!=";
																	else if($2 == 2)xy = ">=";
																	else if($2 == 3)xy = "<=";
																	else if($2 == 4)xy = ">";
																	else if($2 == 5)xy = "<";
																	q->operator1 = xy;
																	q->addrcode = $$->addr->name + " = " + $1->addr->name + xy + $3->addr->name;
																	gen(q , intermediate_code);
																	next_quad++;
															}
															else {
																	$$->type = "Invalid";
															}
													}
												|	SIMPLE_EXPRESSION
													{
															$$ = $1;
													}
												;

SIMPLE_EXPRESSION 	:	SIMPLE_EXPRESSION OPERATOR1 DIVMUL_EXPRESSION
											{
													$$ = new node1(*$1);
													if($1->type == $3->type && $3->type != "Invalid"){

															$$->type = $1->type;
															$$->addr = new node(*$1->addr);
															if($$->addr->datatype == "float")$$->addr->name = "_f" + to_string(counter_flt++);
															else $$->addr->name = "_t" + to_string(counter_tmp++);
															insert_into_symbol_table(curr_function  , $$->addr);
															quadruple* q  = new quadruple;
															q->op1 = $$->addr->name;
															q->op2 = $1->addr->name;
															q->op3 = $3->addr->name;
															q->type = $$->type;
															string xy;
															if($2 == 6)xy = "+";
															else if($2 == 7)xy = "-";
															q->operator1 = xy;
															q->addrcode = $$->addr->name + " = " + $1->addr->name + xy + $3->addr->name;
															gen(q , intermediate_code);
															next_quad++;
													}
													else {
															$$->type = "Invalid";
													}
											}
										|	DIVMUL_EXPRESSION {$$ = $1;}
										;

DIVMUL_EXPRESSION 	: 	DIVMUL_EXPRESSION OPERATOR2 UNARY_EXPRESSION
												{
														//cout<<"yes error\n";
														$$ = new node1(*$1);
														if($2 == 9 && ($3->val1 == 0 ||$3->val2 == 0.0)){
																cout<<"error : division by zero\n";
																$$->type = "Invalid";
														}
														else{
																if($1->type == $3->type && $3->type != "Invalid"){

																		//cout<<"xx "<<$1->type<<" "<<$3->type<<"\n";
																		$$->type = $1->type;
																		$$->addr = new node(*$1->addr);
																		if($$->addr->datatype == "float")$$->addr->name = "_f" + to_string(counter_flt++);
																		else $$->addr->name = "_t" + to_string(counter_tmp++);
																		insert_into_symbol_table(curr_function  , $$->addr);
																		quadruple* q  = new quadruple;
																		q->op1 = $$->addr->name;
																		q->op2 = $1->addr->name;
																		q->op3 = $3->addr->name;
																		q->type = $$->type;
																		string xy;
																		if($2 == 8)xy = "*";
																		else if($2 == 9)xy = "/";
																		q->operator1 = xy;
																		q->addrcode = $$->addr->name + " = " + $1->addr->name + xy + $3->addr->name;
																		gen(q , intermediate_code);
																		next_quad++;
																}
																else {
																		$$->type = "Invalid";
																}
														}

												}
										| 	UNARY_EXPRESSION {$$ = $1;}
										;

UNARY_EXPRESSION 	: 	UNARY_OPERATOR TERM
									{
											$$ = new node1(*$2);
											$$->type = $2->type;
											if($2->val1 != INT_MIN){
													$$->val1 = $1*$2->val1;
											}
											if($2->val2 != FLT_MIN){
													$$->val2 = $1*$2->val2;
											}
											if($2->addr != NULL){
													$$->addr = new node(*$2->addr);
													if($$->addr->datatype == "float") $$->addr->name = "_f" + to_string(counter_flt++);
													else $$->addr->name = "_t" + to_string(counter_tmp++);
													insert_into_symbol_table(curr_function  , $$->addr);
													quadruple* q  = new quadruple;
													q->op1 = $$->addr->name;
													q->op2 = $2->addr->name;
													q->operator1 = "MINUS";
													q->type == $$->addr->datatype;
													q->addrcode = $$->addr->name + " = " + "MINUS " + $2->addr->name;
													gen(q , intermediate_code);
													next_quad++;
											}
									}
									|		TERM
									{
											$$ = $1;
									}
									;

UNARY_OPERATOR 	:	MINUS {$$ = -1;}
								|	PLUS  {$$ = 1;}
								;

TERM 	:	LB_ROUND EXPRESSIONS RB_ROUND
				{
						$$ = $2;
				}
			| FUNCTION_CALL
				{
						flagfunctioncall = true;
						//cout<<"complete\n";
						$$ = $1;
						$$ = new node1(*$1);
						$$->addr = new node;
						if($1->type != "void")$$->addr->name = "result";
				}
			|	NUM
				{
						$$ = $1;
						quadruple* q = new quadruple;
						q->operator1 = "ASSGN";
						if($$->type == "float") q->op1 = "_f" + to_string(counter_flt++);
						else q->op1 = "_t" + to_string(counter_tmp++);
						q->op2 = $1->addr->name;
						q->addrcode = q->op1 + "=" + q->op2;
						q->type = $$->type;
						gen(q,intermediate_code);
						next_quad++;
						$$->addr->name = q->op1;
				}
			|	VARIABLE
			{
					$$ = new node1;
					//cout<<$1->name<<"\n";
					node* tmp = check_variable_declared_above(curr_function , scope , $1->name);
					if(tmp != NULL){
							 $$->type = tmp->datatype;
							 $$->addr = tmp;
							 $$->code = "";
					}
					else{
							$$->type = "Invalid";
							cout<<"error : "<<$1->name<<" not declared\n";
					 }
			}
			;

FUNCTION_CALL 	:	IDENTIFIER LB_ROUND ARGS RB_ROUND
								{

										$$ = new node1;
										map <string , func_node*> :: iterator it;
										it = function_name_table.find($1->name);

										if(it != function_name_table.end()){
												if(counter_args == it->second->params_count){
														bool pflag = true;
														for(int i = 0; i < counter_args; i++){
																if(it->second->param_list[i]->datatype != $3[i]->type){
																		//cout<<it->second->param_list[i]->datatype<<" "<<$3[i]->type<<"\n";
																		$$->type = "Invalid";
																		pflag = false;
																		cout<<"error : arguments datatype not mateched to parameter datatype of function\n";
																}
																else{
																		quadruple* q  = new quadruple;
																		quadruple* q1  = new quadruple;
																		if($3[i]->addr->name[0] != '_'){
																				if($3[i]->addr->datatype == "float")q->op1 = "_f" + to_string(counter_flt++);
																				else q->op1 = "_t" + to_string(counter_tmp++);
																				q->op2 = $3[i]->addr->name;
																				q->operator1 = "ASSGN";
																				q->addrcode = q->op1 + "=" + q->op2;
																				q->type = $3[i]->addr->datatype;
																				gen(q , intermediate_code);
																				next_quad++;
																				q1->op1 = q->op1;
																		}
																		else q1->op1 = $3[i]->addr->name;

																		q1->operator1 = "PUSHPARAM";
																		q1->addrcode = "pushparam " + q1->op1;
																		q1->type = $3[i]->addr->datatype;
																		gen(q1 , intermediate_code);
																		next_quad++;
																}
														}
														if(pflag){
																$$->type = it->second->return_type;
																if($$->type != "void"){
																		quadruple* q  = new quadruple;
																		q->operator1 = "REF_PARAM";
																		q->addrcode = "refparam result";
																		q->op1 = "result";
																		gen(q , intermediate_code);
																		next_quad++;
																}
																quadruple* q  = new quadruple;
																q->operator1 = "FCALL";
																q->op1 = it->second->name;
																q->op2 = to_string(counter_args);
																q->addrcode = "call " + it->second->name + " , " + to_string(counter_args);
																gen(q , intermediate_code);
																next_quad++;
														}
												}
												else{
												 $$->type = "Invalid";
												 	cout<<"error : no of arguments not equal to no of parameters\n";
												 }
										}
										else{
												$$->type = "Invalid";
										}
										counter_args = 0;

								}
								;

ARGS 	:  	ARGS_LIST
			{
					for(int i = 0; i < counter_args; i++)$$[i] = $1[i];
			}
			|/*epsilon*/
			{
					vector<node1*> tmp;
					for(int i = 0; i < tmp.size(); i++)$$[i] = tmp[i];
			}
			;

ARGS_LIST	:	ARGS_LIST COMMA SIMPLE_EXPRESSION
					{
							$$[counter_args] = new node1(*$3);
							$$[counter_args]->type = $3->type;
							counter_args++;
					}
					|	SIMPLE_EXPRESSION
					{
							$$[counter_args] = new node1(*$1);
							$$[counter_args]->type = $1->type;
							counter_args++;
					}
					;

OPERATOR1 	: 	PLUS {$$ = 6;}
						| 	MINUS {$$ = 7;}
						;

OPERATOR2 	: 	MUL {$$ = 8;}
						| 	DIV {$$ = 9;}
						;

OPERATOR3 	: 	GT {$$ = 4;}
						| 	LT {$$ = 5;}
						| 	GE {$$ = 2;}
						| 	LE {$$ = 3;}
						| 	EQ {$$ = 0;}
						| 	NE {$$ = 1;}
						;

IDENTIFIER : NAME {

										if(!arr_code_generation){
													node* tmp = new node;
													tmp->name = $1;
													tmp->valid = 1;
													tmp->scope = scope;
													$$ = tmp;
										}
										else{
												node* curr_var_node1 = check_variable_declared_above(curr_function , scope , $1);
												if(curr_var_node1 == NULL){
														$$ = new node;
														$$->datatype = "Invalid";
														$$->name = $1;
												}
												else $$ = curr_var_node1;
										}
									}
						;

NUM :	INTNUM {	$$ = new node1;
								$$->type = "int";
                $$->val1 = $1;
								$$->addr = new node;
								$$->addr->name = to_string($1);
							}
		| FINTNUM {
										$$ = new node1;
										$$->type = "float";
                    $$->val2 = $1;
										$$->addr = new node;
										$$->addr->name = to_string($1);
							}
		;

%%
/*functions*/

void backpatch(vector<int>& list , vector<quadruple*>& v , int nextquad){
		if(list.size() == 0){
				return;
		}
		int number = list[list.size() - 1];
		pairs.push_back(make_pair(number , nextquad));
		if(labelmap.find(nextquad) == labelmap.end()){
					labelmap.insert(make_pair(nextquad , "LABEL" + to_string(label_counter++)));
		}
		return;
}


void gen(quadruple* s , vector<quadruple*>& v){
   v.push_back(s);
   return;
}

func_node* delete_var_list(func_node* func_node_ptr , int scope){
			map < pair < int , string > , node* > :: iterator it;
			map < pair < int , string > , node* >  m = func_node_ptr->local_variable;
			for(it = m.begin(); it != m.end(); it++){
					if(it->first.first == scope){
							m.erase(it);
					}
			}
			func_node_ptr->local_variable = m;
			return func_node_ptr;
}

void insert_into_symbol_table(func_node* func_node_ptr , node* x){
			map < pair < int , string > , node* > :: iterator it;
			map < pair < int , string > , node* >  m = func_node_ptr->local_variable;
			if(m.find(make_pair(scope , x->name)) != m.end()){
					m.insert(make_pair(make_pair(scope , x->name) , x));
			}
			func_node_ptr->local_variable = m;
			return;
}

func_node* check_function_exist(string key){
			if (function_name_table.find(key) == function_name_table.end())return NULL;
			else return function_name_table[key];
}

bool check_variable_declared_in_present_scope(map < pair < int , string > , node* > local , int scope , string key){
		if(local.find(make_pair(scope , key)) == local.end())return false;
		else return true;
}

node* check_variable_declared_above(func_node* func_node_ptr , int scope , string key){
		for(int i = scope; i > 0; i--){
				if(func_node_ptr->local_variable.find(make_pair(i , key)) != func_node_ptr->local_variable.end())return func_node_ptr->local_variable.find(make_pair(i , key))->second;
		}
		for(int i = 0; i < func_node_ptr->param_list.size(); i++){
				if(func_node_ptr->param_list[i]->name == key)return func_node_ptr->param_list[i];
		}
		if(global_variable.find(make_pair(0 , key)) != global_variable.end()){return global_variable.find(make_pair(0 , key))->second;}
		return NULL;
}

string variable_datatype(node* var){
		return var->datatype;
}

void printQuadTable()
{
    string x = "--------------------------------------------------------------------------------------------------------------------------------------";

    printf("\n\n");
    printf("Quadruple form\n");
    cout<<x<<endl;
    printf("| %-63s | %-15s| %-15s| %-15s| %-15s|\n", "Three-Address-Code" ,"Operator", "Op1", "Op2","Op3");
    cout<<x<<endl;

    for(int i=0;i<intermediate_code.size();i++)
    {
				myfile<<intermediate_code[i]->addrcode;
        printf("| %-48s", intermediate_code[i]->addrcode.c_str());
				myfile<<"$";
				myfile<<intermediate_code[i]->operator1;
				printf("| %-15s",intermediate_code[i]->operator1.c_str());
				myfile<<"$";
				myfile<<intermediate_code[i]->op1;
				printf("| %-15s",intermediate_code[i]->op1.c_str());
				myfile<<"$";
				myfile<<intermediate_code[i]->op2;
				printf("| %-15s",intermediate_code[i]->op2.c_str());
				myfile<<"$";
				myfile<<intermediate_code[i]->op3;
				printf("| %-15s",intermediate_code[i]->op3.c_str());
        printf("|");
				printf("| %-15s",intermediate_code[i]->type.c_str());
        printf("|");
				myfile<<"$";
				myfile<<intermediate_code[i]->type;
				myfile << "\n";
        cout<<endl;
    }
    cout<<x<<endl;
}

bool compare(pair<int , int>& a ,pair<int , int>& b){
		if(a.second <= b.second)return true;
		else return false;
}


int main(){
	int res = yyparse();
    if (res==1 || sayno == false){
				cout<<"\n ----------------------Syntax analysis---------------------------\n";
        printf("Invalid Syntax\n");
    }
    else{
				cout<<"\n ----------------------Syntax analysis---------------------------\n";
        printf("Valid Syntax\n");
				cout<<"\n ----------------------intermediate code---------------------------\n";
				for(int i = 0; i < pairs.size(); i++){
						quadruple* q = intermediate_code[pairs[i].first];
						if(q->op1 == ""){
								q->op1 = labelmap[pairs[i].second];
						}
						else if(q->op2 == ""){
							 q->op2 = labelmap[pairs[i].second];
						}
						else{
								q->op3 = labelmap[pairs[i].second];
						}
						q->addrcode += labelmap[pairs[i].second];;
				}
				sort(pairs.begin() , pairs.end() , compare);
				for(int i = pairs.size() - 1; i >= 0; i--){
						if(i < pairs.size() - 1 && pairs[i].second == pairs[i+1].second)continue;
						quadruple* q = new quadruple;
						q->addrcode = labelmap[pairs[i].second] + " :";
						q->op1 = labelmap[pairs[i].second];
						q->operator1 = "LABEL";
						intermediate_code.insert( intermediate_code.begin() + pairs[i].second + intermediate_code[pairs[i].second]->pos , q);
				}
				printQuadTable();
				cout<<"\n ----------------------intermediate code end---------------------------\n";
    }
		return 0;
}
