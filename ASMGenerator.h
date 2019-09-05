#ifndef __ASMGENERATOR__H__
#define __ASMGENERATOR__H__
#include "Debugger.h"
#include "Registers.h"
#include <bits/stdc++.h>
#include <iostream>
#include <fstream>
#include <vector>
#include <sstream>
//#include <regex>
#include <map>
using namespace std;

struct quadruple{
    vector<string> op;
};

class ASMGenerator{
public:
  ASMGenerator();
  void build();
  void setTACFileName(std::string filename);
  void setASMFileName(std::string filename);
  void gen_quadArray(quadruple* q);

private:
  void readASM();
  void makeDataSegment();
  void AssignReg();
  void buildASM();
  std::string toASM(quadruple* q);
  std::string makeOp(std::string dest, std::string op1,
    std::string op, std::string op2 , std::string type);
  std::string makeSimpleAssign(std::string dest, std::string op1 , std::string type);
  void writeASM();
  void showLines(std::vector<quadruple*> intermediate_code);
  int typeToSize(std::string type);
  std::string vecToStr(std::vector<std::string> vec);
  // std::vector<std::string> split(std::string line);
  bool is_number(const std::string& str);
  bool replace(std::string& str, const std::string& from, const std::string& to);

  bool isMain;
  int param;
  std::string func_name;
  Registers registers;
  Debugger asmWriter;
  std::string tacFileName;
  std::vector<std::string> tacLines;
  std::vector<quadruple*> tempLines;
  std::vector<std::string> asmLines;

  vector<quadruple*> threeAddress;
  vector<string> assemblycode;
  quadruple* tmp_quad;
};
#endif
