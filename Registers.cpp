#include "Registers.h"
#include <iostream>
Registers::Registers(){
  int reg;
  for(reg = 0; reg < 4; reg++){
    this->argPool.push(this->argRegs[reg]);
  }
  for(reg = 0; reg < 10; reg++){
    this->tempPool.push(this->tempRegs[reg]);
  }
  for(reg = 0; reg < 8; reg++){
    this->savedTempPool.push(this->savedTempRegs[reg]);
  }
  for(reg = 0; reg < 32; reg++){
    this->floatingPool.push(this->floatingRegs[reg]);
  }
}
std::string Registers::getRegister(){
  std::string reg = getTempReg();
  if(reg == "n/a"){
    reg = getSavedTempReg();
  }
  // std::cout << "Get " << reg << std::endl;
  return reg;
}

std::string Registers::getFloatingRegister(){
  std::string reg;
  reg = getFloatingReg();

  // std::cout << "Get " << reg << std::endl;
  return reg;
}

void Registers::freeRegister(std::string reg){
  //std::cout << "Free " << reg << std::endl;
  if(reg.empty()){
    return;
  }
  int len = reg.size();

  if(reg[1] == 'a'){
    this->argPool.push(reg);
  }else if(reg[1] == 't'){
    this->tempPool.push(reg);
  }else if(reg[1] == 's'){
    this->savedTempPool.push(reg);
  }else if(reg[1] == 'f'){
    this->floatingPool.push(reg);
  }

}

std::string Registers::getTempReg(){
  std::string reg = "n/a";
  if(!this->tempPool.empty()){
    reg = this->tempPool.front();
    this->tempPool.pop();
  }
  return reg;
}
std::string Registers::getArgReg(){
  std::string reg = "n/a";
  if(!this->argPool.empty()){
    reg = this->argPool.front();
    this->argPool.pop();
  }
  return reg;
}

std::string Registers::getSavedTempReg(){
  std::string reg = "n/a";
  if(!this->savedTempPool.empty()){
    reg = this->savedTempPool.front();
    this->savedTempPool.pop();
  }
  return reg;
}

std::string Registers::getFloatingReg(){
  std::string reg = "n/a";
  if(!this->floatingPool.empty()){
    reg = this->floatingPool.front();
    this->floatingPool.pop();
  }
  return reg;
}
