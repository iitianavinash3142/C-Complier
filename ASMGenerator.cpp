
#include "ASMGenerator.h"
ofstream myfile ("mips_code.s");
ASMGenerator::ASMGenerator(){
  this->isMain = false;
  this->param = 0;
  this->func_name = "";
}
bool is_float( string myString ) {
    std::istringstream iss(myString);
    float f;
    iss >> noskipws >> f; // noskipws considers leading whitespace invalid
    // Check the entire string was consumed and if either failbit or badbit is set
    return iss.eof() && !iss.fail();
}
int iffalse_counter = 0;
void ASMGenerator::build(){
  makeDataSegment();
  AssignReg();
  // showLines(this->threeAddress);
  // std::cout<<"\n\n";
  // showLines(this->tempLines);
  buildASM();
  writeASM();
}
vector<string> split (const string &s, char delim) {
    vector<string> result;
    stringstream ss (s);
    string item;

    while (getline (ss, item, delim)) {
        result.push_back (item);
    }

    return result;
}
void ASMGenerator::makeDataSegment(){
  // make data segment:
  // 1. labeling .data
  // 2. declaring or initializing global variables at memory
  // 3. labeling .text
  int line;
  int space;
  std::stringstream ss;
  myfile << ".data\n";

  for(line = 0; line < this->threeAddress.size(); line++){

      quadruple* q = this->threeAddress[line];
      vector<string> tmp;
      if(q->op[1] == "VAR_DECL"){
        this->asmWriter.debug("#" + q->op[0]);
        tmp = split(q->op[0] , ',');
        myfile << q->op[3] << ": .space " << tmp[1] << "\n";
        this->asmWriter.debug(ss.str()+"\n");
        ss.str("");
      }
      else if(q->op[1] == "ARR_DECL"){
        this->asmWriter.debug("#" + q->op[0]);
        tmp = split(q->op[0] , ',');
        myfile << q->op[3] << ": .space " << tmp[1] << "\n";
        this->asmWriter.debug(ss.str()+"\n");
        ss.str("");
      }
    } // end decl case
    // end for loop
  myfile <<"newline: .asciiz \"\\n\"\n";
  myfile <<".text\n";
}

bool flag = false;
bool flag2 = false;

void ASMGenerator::buildASM(){
  for(int line = 0; line < this->tempLines.size(); line++){
    //std::cout << this->tacLines[line] << std::endl;
    this->asmLines.push_back("#" + this->threeAddress[line]->op[0] + "\n"
                             + toASM(this->tempLines[line]) + "\n");
  }
}
std::string ASMGenerator::toASM(quadruple* q){
  std::stringstream ss;
  // std::vector<std::string> linevec = split(aTacLine);

  //if(std::regex_match(linevec[1],std::regex("(_LABEL)([0-9]+):"))){
  if(q->op[1].substr(0,5) == "LABEL"){
    ss << q->op[2] << ":";
  }
  else if(q->op[1] == "REF_PARAM"){
      flag = true;
  }
  else if(q->op[1] == "FCALL"){
    if(q->op[2] == "print_int"){
      // called with integer pushed on the stack
      /*
      ss << "li $v0, 1\n"
         << "lw $a0, 0($sp)\n"
         << "addiu $sp, $sp, 4\n"
         << "syscall\n";
      */
     // assume int is loaded into $a0
     string reg = this->registers.getSavedTempReg();

     ss << "move " << reg << ", $a0\n";

     ss << "li $v0, 1\n"
        << "syscall\n";

      ss << "li $v0, 4\n"
         << "la $a0, newline\n"
         << "syscall\n";

      ss << "move $a0 ," << reg <<"\n";
    }
    else if(q->op[2] == "print_float"){
      string reg = this->registers.getFloatingReg();


      ss << "li $v0, 2\n"
         << "mov.s $f12, $f31\n"
         << "syscall\n";

    }
    else{
      //
      ss << "jal " << q->op[2] << "\n";

      // pop out parameters
      if(!this->isMain && flag == false){
       for(int arg = param - 1; arg >= 0; arg--){
          ss << "\nlw $a" << arg << ", " << 0 << "($sp)\n"
             << "addiu $sp, $sp, 4";
        }
      }
    }
    // reset param
    param = 0;
  }
  else if(q->op[1] == "REF_PARAM_ASSGN"){
      string exp_2 , reg2;
      exp_2 = q->op[2];

      if(is_number(exp_2)){
        reg2 = this->registers.getSavedTempReg();
        ss << "li " << reg2 << ", $v0" << "\n";
        exp_2 = reg2;
      }
      else if(exp_2[0] != '$'){
        reg2 = this->registers.getSavedTempReg();
        ss << "la " << reg2 << ", " <<  exp_2 << "\n";
        ss << "lw " << reg2 << ", " <<  "(" << reg2 << ")" << "\n";
        exp_2 = reg2;
        ss << "move " << exp_2  << ", $v0\n";
        ss << "sw " << exp_2 << " , "<< q->op[2];
      }
      flag = false;
      // pop out parameters
      if(!this->isMain ){
       for(int arg = param - 1; arg >= 0; arg--){
          ss << "\nlw $a" << arg << ", " << 0 << "($sp)\n"
             << "addiu $sp, $sp, 4";
        }
      }

  }
  else if(q->op[1] == "PUSHPARAM"){
    if(q->op[5] == "float")ss << "mov.s $f31, " << q->op[2];
    else ss << "move $a" << param << ", " << q->op[2];

    param++;
  }
  else if(q->op[1] == "POPPARAM"){
    // pass
  }
  else if(q->op[1] == "GOTO"){
    ss << "j " << q->op[2];
  }
  // else if(q->op[1] == "Function:"){
  //   // this->func_name = linevec[2];
  //   if(this->func_name == "main"){
  //     this->isMain = true;
  //   }
  //   ss << this->func_name << ":";
  // }
  else if(q->op[1] == "Decl:" || q->op[1] == "Init:"){
    // pass
  }
  else if(q->op[1] == "FBEG" && q->op[2] != "print_int"){
    this->func_name = q->op[2];
    if(this->func_name == "main"){
      this->isMain = true;
    }
    ss << this->func_name << ":";
    if(!this->isMain){
      ss << "sw $fp, -4($sp)\n"
         << "sw $ra, -8($sp)\n"
         << "la $fp, 0($sp)\n"
         << "la $sp, -8($sp)";

      // push parameters
      for(int arg = 0; arg < stoi(q->op[3])/4; arg++){
        ss << "\nsw $a" << arg << ", -" << 4 << "($sp)\n"
           << "la $sp, -4($sp)";
      }
    }
  }
  else if(q->op[1] == "FBEG" && q->op[2] == "print_int")flag2 = true;
  else if(q->op[1] == "FEND" && flag2 == true)flag2 = false;
  else if(q->op[1] == "FEND" && flag2 == false){
    if(this->isMain){
      ss << "_end_" + this->func_name + ":\n"
         << "li $v0, 10     # set up for exit\n"
         << "syscall        # exit";
      this->isMain = false;
    }
    else{
      ss << "_end_" + this->func_name + ":\n"
         << "la $sp, 0($fp)\n"
         << "lw $ra, -8($sp)\n"
         << "lw $fp, -4($sp)\n";
      ss << "jr $ra   # return";
    }
  }
  else if(q->op[1] == "RETURN"){
    if(q->op[2].size() > 0 ){
      // return x
      string exp_1 , reg1;
      exp_1 = q->op[2];
      if(is_number(exp_1)){
        reg1 = this->registers.getSavedTempReg();
        ss << "li " << reg1 << ", " << exp_1 << "\n";
        exp_1 = reg1;
      }
      else if(exp_1[0] != '$'){
        reg1 = this->registers.getSavedTempReg();
        ss << "la " << reg1 << ", " << exp_1 << "\n";
        ss << "lw " << reg1 << ", " <<  "(" << reg1 << ")" << "\n";
        exp_1 = reg1;
      }
      ss << "move $v0, " << exp_1 << "\n";
    }
    ss << "j _end_" + this->func_name;
  }
  else if(q->op[1] == "==" || q->op[1] == "!=" || q->op[1] == ">=" || q->op[1] == "<=" || q->op[1] == ">" || q->op[1] == "<"){
      std::string exp_1, op, exp_2, label, reg1, reg2 , exp_0 , reg0 , reg11 , reg22;
      exp_0 = q->op[2];
      exp_1 = q->op[3];
      exp_2 = q->op[4];
      string label2 = "AFTER" + to_string(iffalse_counter);
      label = "IFFALSE" + to_string(iffalse_counter++);
      if(q->op[5] == "float"){
        if(q->op[1] == "<="){
           op = "c.le.s";
        }else if(q->op[1] == "<"){
           op = "c.lt.s";
        }else if(q->op[1] == "=="){
           op = "c.eq.s";
        }else{
          // assume it is a single condition
           op = "c.eq.s";
        }
        if(is_float(exp_1)){
          reg1 = this->registers.getFloatingReg();
          ss << "li.s " << reg1 << ", " << exp_1 << "\n";
          exp_1 = reg1;
        }
        else if(exp_1[0] != '$'){
          reg1 = this->registers.getSavedTempReg();
          reg11 = this->registers.getFloatingReg();
          ss << "la " << reg1 << ", " << exp_1 << "\n";
          ss << "l.s " << reg11 << ", " <<  "0(" << reg1 << ")" << "\n";
          exp_1 = reg11;
        }
        if(is_float(exp_2)){
          reg2 = this->registers.getFloatingReg();
          ss << "li.s " << reg2 << ", " << exp_2 << "\n";
          exp_2 = reg2;
        }
        else if(exp_2[0] != '$'){
          reg2 = this->registers.getSavedTempReg();
          reg22 = this->registers.getFloatingReg();
          ss << "la " << reg2 << ", " <<  exp_2 << "\n";
          ss << "l.s " << reg22 << ", " <<  "0(" << reg2 << ")" << "\n";
          exp_2 = reg22;
        }
        ss << op <<" " << exp_1 << ", " << exp_2 << "\n";
        ss << "bclf " << label<<"\n";
        ss << "addi " << exp_0 << ", $zero ," << 1 <<"\n";
        ss << "j " << label2 <<"\n";
        ss << label <<":\n";
        ss << "addi " << exp_0 << ", $zero ," << 0 <<"\n";
        ss << label2 << ":\n";
      }
      else{
        if(q->op[1] == "<="){
           op = "ble ";
        }else if(q->op[1] == ">="){
           op = "bge ";
        }else if(q->op[1] == ">"){
           op = "bgt ";
        }else if(q->op[1] == "<"){
           op = "blt ";
        }else if(q->op[1] == "=="){
           op = "beq ";
        }else if(q->op[1] == "!="){
           op = "bne ";
        }else{
          // assume it is a single condition
           op = "beq ";
        }
        if(is_number(exp_1)){
          reg1 = this->registers.getSavedTempReg();
          ss << "li " << reg1 << ", " << exp_1 << "\n";
          exp_1 = reg1;
        }
        else if(exp_1[0] != '$'){
          reg1 = this->registers.getSavedTempReg();
          ss << "la " << reg1 << ", " << exp_1 << "\n";
          ss << "lw " << reg1 << ", " <<  "(" << reg1 << ")" << "\n";
          exp_1 = reg1;
        }

        if(is_number(exp_2)){
          reg2 = this->registers.getSavedTempReg();
          ss << "li " << reg2 << ", " << exp_2 << "\n";
          exp_2 = reg2;
        }
        else if(exp_2[0] != '$'){
          reg2 = this->registers.getSavedTempReg();
          ss << "la " << reg2 << ", " <<  exp_2 << "\n";
          ss << "lw " << reg2 << ", " <<  "(" << reg2 << ")" << "\n";
          exp_2 = reg2;
        }
        ss << op << exp_1 << ", " << exp_2 << ", " << label << "\n";
        ss << "addi " << exp_0 << ", $zero ," << 1 <<"\n";
        ss << "j " << label2 <<"\n";
        ss << label <<":\n";
        ss << "addi " << exp_0 << ", $zero ," << 0 <<"\n";
        ss << label2 << ":\n";
      }
  }
  else if(q->op[1] == "IF"){
    std::string exp_1, op, exp_2, label, reg1, reg2;
    bool single_exp = true;
    op = "beq ";
    exp_1 = q->op[2];exp_2 = "1";label = q->op[3];

    if(is_number(exp_1)){
      reg1 = this->registers.getSavedTempReg();
      ss << "li " << reg1 << ", " << exp_1 << "\n";
      exp_1 = reg1;
    }
    else if(exp_1[0] != '$'){
      reg1 = this->registers.getSavedTempReg();
      ss << "la " << reg1 << ", " << exp_1 << "\n";
      ss << "lw " << reg1 << ", " <<  "(" << reg1 << ")" << "\n";
      exp_1 = reg1;
    }
    if(is_number(exp_2)){
      reg2 = this->registers.getSavedTempReg();
      ss << "li " << reg2 << ", " << exp_2 << "\n";
      exp_2 = reg2;
    }
    else if(exp_2[0] != '$'){
      reg2 = this->registers.getSavedTempReg();
      ss << "la " << reg2 << ", " <<  exp_2 << "\n";
      ss << "lw " << reg2 << ", " <<  "(" << reg2 << ")" << "\n";
      exp_2 = reg2;
    }

    ss << op << exp_1 << ", " << exp_2 << ", " << label;

    registers.freeRegister(reg1);
    registers.freeRegister(reg2);

  } // end if statement
  else if(q->op[1] == "+" ||q->op[1] == "-" || q->op[1] == "*" || q->op[1] == "/" || q->op[1] == "AND" || q->op[1] == "OR"){
    std::string dest, op1, op, op2;
    dest = q->op[2];op1 = q->op[3];op2 = q->op[4];op = q->op[1];
    ss << makeOp(dest,op1,op,op2,q->op[5]);
  }
  else if(q->op[1] == "ASSGN"){
    std::string dest, op1, op, op2;
    // simple assignment XXXX A := B unnecessary ...
    dest = q->op[2];
    op1 = q->op[3];
    ss << makeSimpleAssign(dest,op1 , q->op[5]);
  } // end assignment

  return ss.str();
}


std::string ASMGenerator::makeSimpleAssign(std::string dest, std::string op1 , std::string type){
  std::string reg1, reg2 ,reg11;
  std::stringstream ss;
  if(type == "int"){
  // integer (immediate)
        if(is_number(op1)){
          reg1 = this->registers.getSavedTempReg();
          ss << "li " << reg1 << ", " << op1 << "\n";
          op1 = reg1;
        }
        // dereference
        else if(op1[0] == '('){
          reg1 = this->registers.getSavedTempReg();
          ss << "lw " << reg1 << ", " <<  op1 << "\n";
          op1 = reg1;
        }
        // variable
        else if(op1[0] != '$'){
          reg1 = this->registers.getSavedTempReg();
          ss << "la " << reg1 << ", " <<  op1 << "\n";
          ss << "lw " << reg1 << ", " <<  "(" << reg1 << ")" << "\n";
          op1 = reg1;
        }

        if(dest[0] == '('){
          // ($temp)
          reg2 = this->registers.getSavedTempReg();
          ss << "move " << reg2 << ", " << op1;
          ss << "\n" << "sw " << reg2 << ", " << dest;
        }
        else if(dest[0] != '$'){
          // variable
          reg2 = this->registers.getSavedTempReg();
          ss << "move " << reg2 << ", " << op1;
          ss << "\n" << "sw " << reg2 << ", " << dest;
        }
        else{
          // register
          ss << "move " << dest << ", " << op1;
        }
  }
  else{
    if(is_float(op1)){
      // std::cout << op1 << std::endl;
      reg1 = this->registers.getFloatingReg();
      ss << "li.s " << reg1 << ", " << op1 << "\n";
      op1 = reg1;
    }
    // variable
    else if(op1[0] != '$'){
      reg1 = this->registers.getSavedTempReg();
      reg11 = this->registers.getFloatingReg();
      ss << "la " << reg1 << ", " <<  op1 << "\n";
      ss << "l.s " << reg11 << ", " <<  "0(" << reg1 << ")" << "\n";
      op1 = reg11;
    }

    if(dest[0] != '$'){
      // variable
      reg2 = this->registers.getFloatingReg();
      ss << "mov.s " << reg2 << ", " << op1;
      ss << "\n" << "s.s " << reg2 << ", " << dest;
    }
    else{
      // register
      ss << "mov.s " << dest << ", " << op1;
    }

  }
  // free registers
  this->registers.freeRegister(reg1);
  this->registers.freeRegister(reg2);

  return ss.str();
}



std::string ASMGenerator::makeOp(std::string dest, std::string op1,
  std::string op, std::string op2 , std::string type ){

  std::stringstream ss;
  std::string reg1, reg2, reg3 , reg11 , reg22 , reg33;
    if(type == "int")
    {

      if(op == "*"){op = "mul";}
      else if(op == "/"){op = "div";}
      else if(op == "+"){op = "add";}
      else if(op == "-"){op = "sub";}


        // integer (immediate)
        if(is_number(op1)){
          // std::cout << op1 << std::endl;
          reg1 = this->registers.getSavedTempReg();
          ss << "li " << reg1 << ", " << op1 << "\n";
          op1 = reg1;
        }
        // dereference
        else if(op1[0] == '('){
          reg1 = this->registers.getSavedTempReg();
          ss << "lw " << reg1 << ", " <<  op1 << "\n";
          op1 = reg1;
        }
        // address
        else if(op1[0] == '&'){
          reg1 = this->registers.getSavedTempReg();
          op1.erase(0,1);
          ss << "la " << reg1 << ", " <<  op1 << "\n";
          op1 = reg1;
        }
        // variable
        else if(op1[0] != '$'){
          reg1 = this->registers.getSavedTempReg();
          ss << "la " << reg1 << ", " <<  op1 << "\n";
          ss << "lw " << reg1 << ", " <<  "(" << reg1 << ")" << "\n";
          op1 = reg1;
        }

        // integer (immediate)
        if(is_number(op2)){
          reg2 = this->registers.getSavedTempReg();
          ss << "li " << reg2 << ", " << op2 << "\n";
          op2 = reg2;
        }
        // dereference
        else if(op2[0] == '('){
          reg2 = this->registers.getSavedTempReg();
          ss << "lw " << reg2 << ", " <<  op2 << "\n";
          op2 = reg2;
        }
        // address
        else if(op2[0] == '&'){
          reg2 = this->registers.getSavedTempReg();
          op2.erase(0,1);
          ss << "la " << reg2 << ", " <<  op2 << "\n";
          op2 = reg2;
        }
        // variable
        else if(op2[0] != '$'){
          reg2 = this->registers.getSavedTempReg();
          ss << "la " << reg2 << ", " <<  op2 << "\n";
          ss << "lw " << reg2 << ", " <<  "(" << reg2 << ")" << "\n";
          op2 = reg2;
        }

        if(dest[0] == '('){
          // ($temp)
          reg3 = this->registers.getSavedTempReg();
          ss << op << " " << reg3 << ", " << op1 << ", " << op2;
          ss << "\n" << "sw " << reg3 << ", " << dest;
        }
        else if(dest[0] != '$'){
          // variable
          reg3 = this->registers.getSavedTempReg();
          ss << op << " " << reg3 << ", " << op1 << ", " << op2;
          ss << "\n" << "sw " << reg3 << ", " << dest;
        }
        else{
          // register
          ss << op << " " << dest << ", " << op1 << ", " << op2;
        }

    }
    else
    {
      if(op == "*"){op = "mul.s";}
      else if(op == "/"){op = "div.s";}
      else if(op == "+"){op = "add.s";}
      else if(op == "-"){op = "sub.s";}

      if(is_float(op1)){
        // std::cout << op1 << std::endl;
        reg1 = this->registers.getFloatingReg();
        ss << "li.s " << reg1 << ", " << op1 << "\n";
        op1 = reg1;
      }
      // variable
      else if(op1[0] != '$'){
        reg1 = this->registers.getSavedTempReg();
        reg11 = this->registers.getFloatingReg();
        ss << "la " << reg1 << ", " <<  op1 << "\n";
        ss << "l.s " << reg11 << ", " <<  "0(" << reg1 << ")" << "\n";
        op1 = reg11;
      }
      if(is_float(op2)){
        // std::cout << op1 << std::endl;
        reg2 = this->registers.getFloatingReg();
        ss << "li.s " << reg2 << ", " << op2 << "\n";
        op2 = reg2;
      }
      // variable
      else if(op2[0] != '$'){
        reg2 = this->registers.getSavedTempReg();
        reg22 = this->registers.getFloatingReg();
        ss << "la " << reg2 << ", " <<  op2 << "\n";
        ss << "l.s " << reg22 << ", " <<  "0(" << reg2 << ")" << "\n";
        op2 = reg22;
      }

      if(dest[0] != '$'){
        // variable
        reg3 = this->registers.getFloatingReg();
        ss << op << " " << reg3 << ", " << op1 << ", " << op2;
        ss << "\n" << "s.s " << reg3 << ", " << dest;
      }
      else{
        // register
        ss << op << " " << dest << ", " << op1 << ", " << op2;
      }
    }




  // free registers
  this->registers.freeRegister(reg1);
  this->registers.freeRegister(reg2);
  this->registers.freeRegister(reg3);

  return ss.str();
}
void ASMGenerator::writeASM(){
  int asmIdx;
  for(asmIdx = 0; asmIdx < this->asmLines.size(); asmIdx++){
    this->asmWriter.debug(this->asmLines[asmIdx]);
    myfile << this->asmLines[asmIdx]<<"\n";
  }
}
void ASMGenerator::setTACFileName(std::string filename){
  this->tacFileName = filename;
}
void ASMGenerator::setASMFileName(std::string filename){
  this->asmWriter.setFileName(filename);
  this->asmWriter.setDebug(true);
}
void ASMGenerator::showLines(std::vector<quadruple*> intermediate_code)
{
    string x = "-------------------------------------------------------------------------------------------------------------------------------------";

    printf("\n\n");
    printf("Quadruple form\n");
    cout<<x<<endl;
    printf("| %-63s | %-15s| %-15s| %-15s| %-15s|\n", "Three-Address-Code" ,"Operator", "Op1", "Op2","Op3");
    cout<<x<<endl;

    for(int i=0;i<intermediate_code.size();i++)
    {
        printf("| %-48s", intermediate_code[i]->op[0].c_str());
				printf("| %-15s",intermediate_code[i]->op[1].c_str());
				printf("| %-15s",intermediate_code[i]->op[2].c_str());
				printf("| %-15s",intermediate_code[i]->op[3].c_str());
				printf("| %-15s",intermediate_code[i]->op[4].c_str());
        printf("| %-15s",intermediate_code[i]->op[5].c_str());
        printf("|");
        cout<<endl;
    }
    cout<<x<<endl;
}

int ASMGenerator::typeToSize(std::string type){
  if(type == "int"){
    return 4;
  }
  return 0;
}
std::string ASMGenerator::vecToStr(std::vector<std::string> vec ){
  int tok;
  std::string result;
  for(tok = 0; tok < vec.size(); tok++){
    result += vec[tok];
  }
  return result;
}
//
// std::vector<std::string> ASMGenerator::split(std::string line){
//   std::string tok;
//   std::stringstream ss(line);
//   std::vector<std::string> linevec;
//   while(getline(ss, tok,' ')) {
//       linevec.push_back(tok);
//   }
//   return linevec;
// }
bool ASMGenerator::is_number(const std::string& str)
{
    std::string::const_iterator it = str.begin();
    while (it != str.end() && std::isdigit(*it)) ++it;
    return !str.empty() && it == str.end();
}
bool ASMGenerator::replace(std::string& str, const std::string& from, const std::string& to) {
    size_t pos = str.find(from);
    if(pos == std::string::npos)
        return false;
    str.replace(pos, from.length(), to);
    return true;
}

void ASMGenerator::AssignReg(){
  std::string reg, repStr, tempStr;
  std::vector<std::string> dump_regs;
  std::map<std::string,std::string> used_regs;
  std::map<std::string,std::string>::iterator iter;
  std::map<std::string,std::string> arg_regs;
  bool inLocal = false;
  int paramNum = 0;

  for(int line = 0; line < this->threeAddress.size(); line++){
    // std::cout << temp << std::endl;
    quadruple* q = new quadruple(*this->threeAddress[line]);
    // replace argument with register
    if(q->op[1] == "POPPARAM"){
      std::string reg = "$a" + std::to_string(paramNum);
      paramNum++;
      arg_regs[q->op[3]] = reg;
      inLocal = true;
    }
    else if(q->op[1] == "FEND" && inLocal){
      paramNum = 0;
      inLocal = false;
    }

    for(int i = 2; i <= 4; i++){
      if(q->op[i].substr(0,2) == "_t" || q->op[i].substr(0,3) == "(_t"){
          tempStr = q->op[i];
          if(tempStr[0] == '('){
            tempStr.erase(tempStr.begin(), tempStr.begin()+1);
            tempStr.erase(tempStr.end()-1, tempStr.end());
          }
          iter = used_regs.find(tempStr);
          if (iter != used_regs.end()){
            repStr =  used_regs[tempStr];
            dump_regs.push_back(used_regs[tempStr]);
          }
          else{
            reg = this->registers.getRegister(); // hopefully get next register
            used_regs[tempStr] = reg;
            repStr = reg;
          }
          if(q->op[i][0] == '('){
            repStr = "(" + repStr + ")";
          }
          replace(q->op[0] , q->op[i] , repStr);
          q->op[i] = repStr;
      }
      else if(q->op[i].substr(0,2) == "_f"){
          tempStr = q->op[i];
          iter = used_regs.find(tempStr);
          if (iter != used_regs.end()){
            repStr =  used_regs[tempStr];
            dump_regs.push_back(used_regs[tempStr]);
          }
          else{
            reg = this->registers.getFloatingRegister(); // hopefully get next register
            used_regs[tempStr] = reg;
            repStr = reg;
          }
          replace(q->op[0] , q->op[i] , repStr);
          q->op[i] = repStr;
      }
      else{
        if(inLocal){
          // if match with any argument, replace it with its register
          for(iter = arg_regs.begin(); iter != arg_regs.end(); ++iter){
            std::string key = iter->first;
            if(key == q->op[i]){
              replace(q->op[0] , q->op[i] , arg_regs[key]);
              q->op[i] = arg_regs[key];
            }
          }
        } // end argument replacement
      }
    }
    // free registers
    for(int reg = 0; reg < dump_regs.size(); reg++){
      this->registers.freeRegister(dump_regs[reg]);
    }
    dump_regs.clear();

    // add new line
    this->tempLines.push_back(q);
  } // end whole lines
}

void ASMGenerator::gen_quadArray(quadruple* q){
    this->threeAddress.push_back(q);
}

int main() {
  ifstream myfile("Three_address_code.txt");
  string line;
  ASMGenerator* asmgen = new ASMGenerator();
  asmgen->setASMFileName("assembly.s");
  if (myfile.is_open())
  {
    while ( getline (myfile,line) )
    {
      quadruple* q = new quadruple;
      vector <string> tmp = split(line , '$');
      string x = tmp[tmp.size() - 1];
      tmp.pop_back();
      while (tmp.size() != 5) {
          tmp.push_back("");
      }
      tmp.push_back(x);
      q->op = tmp;
      asmgen->gen_quadArray(q);
    }

    asmgen->build();
    myfile.close();
  }

  else cout << "Unable to open file";
  return 0;
}
