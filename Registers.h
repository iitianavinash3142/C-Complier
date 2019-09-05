

#ifndef __REGISTERS__H__
#define __REGISTERS__H__
#include <queue>
#include <string>
class Registers{
public:
  Registers();
  std::string getRegister();
  void freeRegister(std::string reg);
  std::string getTempReg();
  std::string getArgReg();
  std::string getSavedTempReg();
  std::string getFloatingReg();
  std::string getFloatingRegister();

private:
  const std::string argRegs[4] = {"$a0","$a1","$a2","$a3"};
  const std::string tempRegs[10] = {"$t0","$t1","$t2","$t3","$t4","$t5","$t6","$t7","$t8","$t9"};
  const std::string savedTempRegs[8] = {"$s0","$s1","$s2","$s3","$s4","$s5","$s6","$s7"};
  const std::string floatingRegs[31] = {"$f0","$f1","$f2","$f3","$f4","$f5","$f6","$f7","$f8","$f9","$f10","$f13","$f14","$f16","$f17","$f18","$f20","$f21","$f22","$f23","$f24"
                                ,"$f25","$f26","$f27","$f28","$f29","$f30" };

  std::queue<std::string> argPool, tempPool, savedTempPool, floatingPool;
};
#endif
