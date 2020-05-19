typedef struct  {
  unsigned int w0; 
  unsigned int w1;
  unsigned int w2;
  unsigned int w3; 
  unsigned int w4;
  unsigned int w5;
  unsigned int w6;
  unsigned int w7;
} ethint256 ;



 ethint256 cons(unsigned int w7, unsigned int w6, unsigned int w5, unsigned int w4 ,unsigned int w3, unsigned int w2, unsigned int w1, unsigned int w0) {
   ethint256 res;
  res.w7 = w7;
  res.w6 = w6;
  res.w5 = w5;
  res.w4 = w4;
  res.w3 = w3;
  res.w2 = w2;
  res.w1 = w1;
  res.w0 = w0;
  return res;
}

void print_eth( ethint256 x) {
    printf("%8x %8x %8x %8x %8x %8x %8x %8x\n",x.w7, x.w6 , x.w5,x.w4, x.w3, x.w2, x.w1, x.w0);
}


ethint256 ADD(ethint256 x, ethint256 y) {
  ethint256 resAdd;
  int carry;
  resAdd.w0 = x.w0 + y.w0;
  carry = (resAdd.w0 < x.w0);  
  resAdd.w1 = x.w1 + y.w1 + carry; 
  carry = (resAdd.w1 < x.w1);
  resAdd.w2 = x.w2 + y.w2 + carry;
  carry = (resAdd.w2 < x.w2);
  resAdd.w3 = x.w3 + y.w3 + carry;
  carry = (resAdd.w3 < x.w3);
  resAdd.w4 = x.w4 + y.w4 + carry;
  carry = (resAdd.w4 < x.w4);
  resAdd.w5 = x.w5 + y.w5 + carry;
  carry = (resAdd.w5 < x.w5);
  resAdd.w6 = x.w6 + y.w6 + carry;
  carry = (resAdd.w6 < x.w6);
  resAdd.w7 = x.w7 + y.w7 + carry;
  carry = (resAdd.w7 < x.w7);
  return resAdd;
}

ethint256 SUB(ethint256 x, ethint256 y) {
  ethint256 resAdd;
  unsigned int carry;
  resAdd.w0 = x.w0 - y.w0; 
  carry = (resAdd.w0 > x.w0);  

  resAdd.w1 = x.w1 - y.w1 - carry; 
  carry = (resAdd.w1 > x.w1);

  resAdd.w2 = x.w2 - y.w2 - carry;
  carry = (resAdd.w2 > x.w2);
  resAdd.w3 = x.w3 - y.w3 - carry;
  carry = (resAdd.w3 > x.w3);
  resAdd.w4 = x.w4 - y.w4 - carry;
  carry = (resAdd.w4 > x.w4);
  resAdd.w5 = x.w5 - y.w5 - carry;
  carry = (resAdd.w5 > x.w5);
  resAdd.w6 = x.w6 - y.w6 - carry;
  carry = (resAdd.w6 > x.w6);
  resAdd.w7 = x.w7 - y.w7 - carry;
  carry = (resAdd.w7 > x.w7);
  return resAdd;
}

 ethint256 AND( ethint256 x,  ethint256 y) {
  ethint256 resAnd;
  resAnd.w0 = x.w0 & y.w0;
  resAnd.w1 = x.w1 & y.w1;
  resAnd.w2 = x.w2 & y.w2;
  resAnd.w3 = x.w3 & y.w3;
  resAnd.w4 = x.w4 & y.w4;
  resAnd.w5 = x.w5 & y.w5;
  resAnd.w6 = x.w6 & y.w6;
  resAnd.w7 = x.w7 & y.w7;
  return resAnd;
}

 ethint256 OR( ethint256 x,  ethint256 y) {
  ethint256 resOr;
  resOr.w0 = x.w0 | y.w0;
  resOr.w1 = x.w1 | y.w1;
  resOr.w2 = x.w2 | y.w2;
  resOr.w3 = x.w3 | y.w3;
  resOr.w4 = x.w4 | y.w4;
  resOr.w5 = x.w5 | y.w5;
  resOr.w6 = x.w6 | y.w6;
  resOr.w7 = x.w7 | y.w7;
  return resOr;
}

 ethint256 XOR( ethint256 x,  ethint256 y) {
  ethint256 res;
  res.w0 = x.w0 ^ y.w0;
  res.w1 = x.w1 ^ y.w1;
  res.w2 = x.w2 ^ y.w2;
  res.w3 = x.w3 ^ y.w3;
  res.w4 = x.w4 ^ y.w4;
  res.w5 = x.w5 ^ y.w5;
  res.w6 = x.w6 ^ y.w6;
  res.w7 = x.w7 ^ y.w7;
  return res;
}

int EQ( ethint256 x,  ethint256 y) {
  int res1 = (x.w0 == y.w0);
  int res2 = (x.w1 == y.w1);
  int res3 = (x.w2 == y.w2);
  int res4 = (x.w3 == y.w3);
  int res5 = (x.w4 == y.w4);
  int res6 = (x.w5 == y.w5);
  int res7 = (x.w6 == y.w6);
  int res8 = (x.w7 == y.w7);
  int res = res1 && res2 && res3 && res4 && res5 && res6 && res7 && res8; 
  return res; 
}

int NEQ( ethint256 x,  ethint256 y) {
  int resNEQ;
  int res1 = (x.w0 != y.w0);
  int res2 = (x.w1 != y.w1);
  int res3 = (x.w2 != y.w2);
  int res4 = (x.w3 != y.w3);
  int res5 = (x.w4 != y.w4);
  int res6 = (x.w5 != y.w5);
  int res7 = (x.w6 != y.w6);
  int res8 = (x.w7 != y.w7);
  resNEQ = res1 || res2 || res3 || res4 || res5 || res6 || res7 || res8; 
  return resNEQ; 
}

int GT( ethint256 x,  ethint256 y) {

  if( x.w7 > y.w7 || x.w6 > y.w6 || x.w5 > y.w5 || x.w4 > y.w4 || x.w3 > y.w3 || x.w2 > y.w2 || x.w1 > y.w1 || x.w0 > y.w0 ){ return 1;}
  if( x.w7 < y.w7 || x.w6 < y.w6 || x.w5 < y.w5 || x.w4 < y.w4 || x.w3 < y.w3 || x.w2 < y.w2 || x.w1 < y.w1 || x.w0 < y.w0 ){ return 0;}

  return 0; //igualdad
}

ethint256 gt( ethint256 x,  ethint256 y) {
  ethint256 res0 = cons(0,0,0,0,0,0,0,0);
  ethint256 res1 = cons(0,0,0,0,0,0,0,1);

  if( x.w7 > y.w7 || x.w6 > y.w6 || x.w5 > y.w5 || x.w4 > y.w4 || x.w3 > y.w3 || x.w2 > y.w2 || x.w1 > y.w1 || x.w0 > y.w0 ){ return res1;}
  if( x.w7 < y.w7 || x.w6 < y.w6 || x.w5 < y.w5 || x.w4 < y.w4 || x.w3 < y.w3 || x.w2 < y.w2 || x.w1 < y.w1 || x.w0 < y.w0 ){ return res0;}

  return res0; //caso de todo ceros

}

int GEQ( ethint256 x,  ethint256 y) {
  if( x.w7 > y.w7 || x.w6 > y.w6 || x.w5 > y.w5 || x.w4 > y.w4 || x.w3 > y.w3 || x.w2 > y.w2 || x.w1 > y.w1 || x.w0 > y.w0 ){ return 1;}
  if( x.w7 < y.w7 || x.w6 < y.w6 || x.w5 < y.w5 || x.w4 < y.w4 || x.w3 < y.w3 || x.w2 < y.w2 || x.w1 < y.w1 || x.w0 < y.w0 ){ return 0;}

  return 1; //caso de igualdad
}

ethint256 geq( ethint256 x,  ethint256 y) {
  ethint256 res0 = cons(0,0,0,0,0,0,0,0);
  ethint256 res1 = cons(0,0,0,0,0,0,0,1);

  if( x.w7 > y.w7 || x.w6 > y.w6 || x.w5 > y.w5 || x.w4 > y.w4 || x.w3 > y.w3 || x.w2 > y.w2 || x.w1 > y.w1 || x.w0 > y.w0 ){ return res1;}
  if( x.w7 < y.w7 || x.w6 < y.w6 || x.w5 < y.w5 || x.w4 < y.w4 || x.w3 < y.w3 || x.w2 < y.w2 || x.w1 < y.w1 || x.w0 < y.w0 ){ return res0;}
  
  return res1; //caso de igualdad
}


 int LT( ethint256 x,  ethint256 y) {

  if( x.w7 < y.w7 || x.w6 < y.w6 || x.w5 < y.w5 || x.w4 < y.w4 || x.w3 < y.w3 || x.w2 < y.w2 || x.w1 < y.w1 || x.w0 < y.w0 ){ return 1;}
  if( x.w7 > y.w7 || x.w6 > y.w6 || x.w5 > y.w5 || x.w4 > y.w4 || x.w3 > y.w3 || x.w2 > y.w2 || x.w1 > y.w1 || x.w0 > y.w0 ){ return 0;}
  
  return 0; //caso de igualdad
}

ethint256 lt( ethint256 x,  ethint256 y) {
  ethint256 res0 = cons(0,0,0,0,0,0,0,0);
  ethint256 res1 = cons(0,0,0,0,0,0,0,1);

  if( x.w7 < y.w7 || x.w6 < y.w6 || x.w5 < y.w5 || x.w4 < y.w4 || x.w3 < y.w3 || x.w2 < y.w2 || x.w1 < y.w1 || x.w0 < y.w0 ){ return res1;}
  if( x.w7 > y.w7 || x.w6 > y.w6 || x.w5 > y.w5 || x.w4 > y.w4 || x.w3 > y.w3 || x.w2 > y.w2 || x.w1 > y.w1 || x.w0 > y.w0 ){ return res0;}
  
  return res0; //caso de todo ceros
}

int LEQ( ethint256 x,  ethint256 y) {

  if( x.w7 < y.w7 || x.w6 < y.w6 || x.w5 < y.w5 || x.w4 < y.w4 || x.w3 < y.w3 || x.w2 < y.w2 || x.w1 < y.w1 || x.w0 < y.w0 ){ return 1;}
  if( x.w7 > y.w7 || x.w6 > y.w6 || x.w5 > y.w5 || x.w4 > y.w4 || x.w3 > y.w3 || x.w2 > y.w2 || x.w1 > y.w1 || x.w0 > y.w0 ){ return 0;}

  return 1; //caso de igualdad
}

ethint256 leq( ethint256 x,  ethint256 y) {
  ethint256 res0 = cons(0,0,0,0,0,0,0,0);
  ethint256 res1 = cons(0,0,0,0,0,0,0,1);

  if( x.w7 < y.w7 || x.w6 < y.w6 || x.w5 < y.w5 || x.w4 < y.w4 || x.w3 < y.w3 || x.w2 < y.w2 || x.w1 < y.w1 || x.w0 < y.w0 ){ return res1;}
  if( x.w7 > y.w7 || x.w6 > y.w6 || x.w5 > y.w5 || x.w4 > y.w4 || x.w3 > y.w3 || x.w2 > y.w2 || x.w1 > y.w1 || x.w0 > y.w0 ){ return res0;}
  
  return res1; //caso de igualdad
}

ethint256 sgt(ethint256 x, ethint256 y){ //> con signo
    ethint256 res0 = cons(0,0,0,0,0,0,0,0);
    ethint256 res1 = cons(0,0,0,0,0,0,0,1);
    ethint256 z1 = cons(0,0,0,0,0,0,0,0x10000000);
    ethint256 z2 = cons(0,0,0,0,0,0,0x10000000,0);
    ethint256 z3 = cons(0,0,0,0,0,0x10000000,0,0);
    ethint256 z4 = cons(0,0,0,0,0x10000000,0,0,0);
    ethint256 z5 = cons(0,0,0,0x10000000,0,0,0,0);
    ethint256 z6 = cons(0,0,0x10000000,0,0,0,0,0);
    ethint256 z7 = cons(0,0x10000000,0,0,0,0,0,0);
    ethint256 z8 = cons(0x10000000,0,0,0,0,0,0,0);

    if((x.w7 >= z8.w7 && y.w7 >= z8.w7) || (x.w7 < z8.w7 && y.w7 < z8.w7) ){return gt(x,y); }
    if((x.w7 >= z8.w7 && y.w7 < z8.w7)){return res0; }
    if((x.w7 < z8.w7 && y.w7 >= z8.w7)){ return res1; }

    if((x.w6 >= z7.w6 && y.w6 >= z7.w6) || (x.w6 < z7.w6 && y.w6 < z7.w6 ) ){return gt(x,y); }
    if((x.w6 >= z7.w6 && y.w6 < z7.w6)){ return res0; }
    if((x.w6 < z7.w6 && y.w6 >= z7.w6)){ return res1; }

    if((x.w5 >= z6.w5 && y.w5 >= z6.w5) || (x.w5 < z6.w5 && y.w5 < z6.w5 ) ){ return gt(x,y); }
    if((x.w5 >= z6.w5 && y.w5 < z6.w5)){ return res0; }
    if((x.w5 < z6.w5 && y.w5 >= z6.w5)){ return res1; }

    if((x.w4 >= z5.w4 && y.w4 >= z5.w4) || (x.w4 < z5.w4 && y.w4 < z5.w4 ) ){ return gt(x,y); }
    if((x.w4 >= z5.w4 && y.w4 < z5.w4)){ return res0;}
    if((x.w4 < z5.w4 && y.w4 >= z5.w4)){ return res1; }

    if((x.w3 >= z4.w3 && y.w3 >= z4.w3) || (x.w3 < z4.w3 && y.w3 < z4.w3 ) ){ return gt(x,y); }
    if((x.w3 >= z4.w3 && y.w3 < z4.w3)){ return res0; }
    if((x.w3 < z4.w3 && y.w3 >= z4.w3)){ return res1;}

    if((x.w2 >= z3.w2 && y.w2 >= z3.w2) || (x.w2 < z3.w2 && y.w2 < z3.w2 ) ){ return gt(x,y); }
    if((x.w2 >= z3.w2 && y.w2 < z3.w2)){ return res0; }
    if((x.w2 < z3.w2 && y.w2 >= z3.w2)){ return res1; }

    if((x.w1 >= z2.w1 && y.w1 >= z2.w1) || (x.w1 < z2.w1 && y.w1 < z2.w1 ) ){ return gt(x,y); }
    if((x.w1 >= z2.w1 && y.w1 < z2.w1)){return res0; }
    if((x.w1 < z2.w1 && y.w1 >= z2.w1)){ return res1; }

    if((x.w0 >= z1.w0 && y.w0 >= z1.w0) || (x.w0 < z1.w0 && y.w0 < z1.w0 ) ){ return gt(x,y); }
    if((x.w0 >= z1.w0 && y.w0 < z1.w0)){ return res0; }
    if((x.w0 < z1.w0 && y.w0 >= z1.w0)){ return res1; }

   return res0; //caso de igualdad
}

ethint256 slt(ethint256 x, ethint256 y){ //< con signo
    ethint256 res0 = cons(0,0,0,0,0,0,0,0);
    ethint256 res1 = cons(0,0,0,0,0,0,0,1);
    ethint256 z1 = cons(0,0,0,0,0,0,0,0x10000000);
    ethint256 z2 = cons(0,0,0,0,0,0,0x10000000,0);
    ethint256 z3 = cons(0,0,0,0,0,0x10000000,0,0);
    ethint256 z4 = cons(0,0,0,0,0x10000000,0,0,0);
    ethint256 z5 = cons(0,0,0,0x10000000,0,0,0,0);
    ethint256 z6 = cons(0,0,0x10000000,0,0,0,0,0);
    ethint256 z7 = cons(0,0x10000000,0,0,0,0,0,0);
    ethint256 z8 = cons(0x10000000,0,0,0,0,0,0,0);

    if((x.w7 >= z8.w7 && y.w7 >= z8.w7) || (x.w7 < z8.w7 && y.w7 < z8.w7) ){return lt(x,y); }
    if((x.w7 >= z8.w7 && y.w7 < z8.w7)){return res1; }
    if((x.w7 < z8.w7 && y.w7 >= z8.w7)){ return res0; }

    if((x.w6 >= z7.w6 && y.w6 >= z7.w6) || (x.w6 < z7.w6 && y.w6 < z7.w6 ) ){return lt(x,y); }
    if((x.w6 >= z7.w6 && y.w6 < z7.w6)){ return res1; }
    if((x.w6 < z7.w6 && y.w6 >= z7.w6)){ return res0; }

    if((x.w5 >= z6.w5 && y.w5 >= z6.w5) || (x.w5 < z6.w5 && y.w5 < z6.w5 ) ){ return lt(x,y); }
    if((x.w5 >= z6.w5 && y.w5 < z6.w5)){ return res1; }
    if((x.w5 < z6.w5 && y.w5 >= z6.w5)){ return res0; }

    if((x.w4 >= z5.w4 && y.w4 >= z5.w4) || (x.w4 < z5.w4 && y.w4 < z5.w4 ) ){ return lt(x,y); }
    if((x.w4 >= z5.w4 && y.w4 < z5.w4)){ return res1;}
    if((x.w4 < z5.w4 && y.w4 >= z5.w4)){ return res0; }

    if((x.w3 >= z4.w3 && y.w3 >= z4.w3) || (x.w3 < z4.w3 && y.w3 < z4.w3 ) ){ return lt(x,y); }
    if((x.w3 >= z4.w3 && y.w3 < z4.w3)){ return res1; }
    if((x.w3 < z4.w3 && y.w3 >= z4.w3)){ return res0;}

    if((x.w2 >= z3.w2 && y.w2 >= z3.w2) || (x.w2 < z3.w2 && y.w2 < z3.w2 ) ){ return lt(x,y); }
    if((x.w2 >= z3.w2 && y.w2 < z3.w2)){ return res1; }
    if((x.w2 < z3.w2 && y.w2 >= z3.w2)){ return res0; }

    if((x.w1 >= z2.w1 && y.w1 >= z2.w1) || (x.w1 < z2.w1 && y.w1 < z2.w1 ) ){ return lt(x,y); }
    if((x.w1 >= z2.w1 && y.w1 < z2.w1)){return res1; }
    if((x.w1 < z2.w1 && y.w1 >= z2.w1)){ return res0; }

    if((x.w0 >= z1.w0 && y.w0 >= z1.w0) || (x.w0 < z1.w0 && y.w0 < z1.w0 ) ){ return lt(x,y); }
    if((x.w0 >= z1.w0 && y.w0 < z1.w0)){ return res1; }
    if((x.w0 < z1.w0 && y.w0 >= z1.w0)){ return res0; }

   return res0; //caso de igualdad
}

 int ISZERO( ethint256 x) {
  int resZero;
  int res1 = (x.w0 == 0);
  int res2 = (x.w1 == 0);
  int res3 = (x.w2 == 0);
  int res4 = (x.w3 == 0);
  int res5 = (x.w4 == 0);
  int res6 = (x.w5 == 0);
  int res7 = (x.w6 == 0);
  int res8 = (x.w7 == 0);
  resZero = res1 && res2 && res3 && res4 && res5 && res6 && res7 && res8; 
  // resZero.w0 = resval;
  // resZero.w1 = resZero.w2 = resZero.w3 = resZero.w4 = resZero.w5 = resZero.w6 = resZero.w7 = 0;
  return resZero;
}


ethint256 __VERIFIER_nondet_256(){
  ethint256 resultado;
  resultado.w0 = __VERIFIER_nondet_uint();
  resultado.w1 = __VERIFIER_nondet_uint();
  resultado.w2 = __VERIFIER_nondet_uint();
  resultado.w3 = __VERIFIER_nondet_uint();
  resultado.w4 = __VERIFIER_nondet_uint();
  resultado.w5 = __VERIFIER_nondet_uint();
  resultado.w6 = __VERIFIER_nondet_uint();
  resultado.w7 = __VERIFIER_nondet_uint();
  return resultado;
}

ethint256 BYTE(ethint256 x, ethint256 y){
    ethint256 res;
    unsigned int w;
    res.w1 = res.w2 = res.w3 = res.w4 = res.w5 = res.w6 = res.w7 = 0; //unicamente interesa el w0 (donde va el resultado)

    if (y.w0 < 8) w = x.w7; //se empieza a contar por la izquierda
    else if (y.w0 < 16 ) w = x.w6;
    else if (y.w0 < 24 ) w = x.w5;
    else if (y.w0 < 32 ) w = x.w4;
    else if (y.w0 < 40 ) w = x.w3;
    else if (y.w0 < 48 ) w = x.w2;
    else if (y.w0 < 56 ) w = x.w1;
    else if (y.w0 < 64 ) w = x.w0;

    int offset = y.w0 % 8;

    if (offset == 0) res.w0 = (w & 0xF0000000) >> 28;
    if (offset == 1) res.w0 = (w & 0x0F000000) >> 24;
    if (offset == 2) res.w0 = (w & 0x00F00000) >> 20;
    if (offset == 3) res.w0 = (w & 0x000F0000) >> 16;
    if (offset == 4) res.w0 = (w & 0x0000F000) >> 12;
    if (offset == 5) res.w0 = (w & 0x00000F00) >> 8;
    if (offset == 6) res.w0 = (w & 0x000000F0) >> 4;
    if (offset == 7) res.w0 = (w & 0x0000000F) >> 0;
    return res;
}

ethint256 SIGNEXTEND(ethint256 v0,  ethint256 y){
  
  int v1 = y.w0; 
  ethint256 aux1; //para el or con v0
  ethint256 byte; //para ver si la palabra tiene signo positivo (LEQ,GT)
  ethint256 bytei;

  if(v1 == 0){
    byte = cons(0,0,0,0,0,0,0,v0.w0 & 0x000000ff);
    int x = v0.w0 & 0x000000ff;
  
    if(x <= 127){ return v0;} 
    else{ 
        return cons(0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffff00 | x); }
  }
  if(v1 == 1){
    bytei = cons(0,0,0,0,0,0,0,60);
    byte = BYTE(v0,bytei); 
    if(byte.w0 == 0){ return v0;} 
    else{ aux1 = cons(0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffff0000); return OR(v0,aux1 );} 
  }
  if(v1 == 2){
    bytei = cons(0,0,0,0,0,0,0,58);
    byte = BYTE(v0,bytei); 
    if(byte.w0 == 0){ return v0;} 
    else{ aux1 = cons(0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xff000000); return OR(v0,aux1 );} 
  }
  if(v1 == 3){
    bytei = cons(0,0,0,0,0,0,0,56);
    byte = BYTE(v0,bytei); 
    if(byte.w0 == 0){ return v0;} 
    else{ aux1 = cons(0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0); return OR(v0,aux1 );} 
  }

  if(v1 == 7){
    bytei = cons(0,0,0,0,0,0,0,48);
    byte = BYTE(v0,bytei); 
    if(byte.w0 == 0){ return v0;}
    else { aux1 = cons(0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0,0); return OR(v0,aux1 );}
  }
 
  if(v1 == 11){
    bytei = cons(0,0,0,0,0,0,0,40);
    byte = BYTE(v0,bytei); 
    if(byte.w0 == 0){ return v0;} 
    else { aux1 = cons(0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0,0,0); return OR(v0,aux1 );}
  }
  
  if(v1 == 15){
    bytei = cons(0,0,0,0,0,0,0,32);
    byte = BYTE(v0,bytei); 
    if(byte.w0 == 0){ return v0;}    
    else{ aux1 = cons(0xffffffff,0xffffffff,0xffffffff,0xffffffff,0,0,0,0); return OR(v0,aux1 );}
  }
  
  if(v1 == 19){
    bytei = cons(0,0,0,0,0,0,0,24);
    byte = BYTE(v0,bytei); 
    if(byte.w0 == 0){ return v0;}  
    else{ aux1 = cons(0xffffffff,0xffffffff,0xffffffff,0,0,0,0,0); return OR(v0,aux1 );}
  }
  
 if(v1 == 23){
    bytei = cons(0,0,0,0,0,0,0,16);
    byte = BYTE(v0,bytei); 
    if(byte.w0 == 0){ return v0;}        
    else{ aux1 = cons(0xffffffff,0xffffffff,0,0,0,0,0,0); return OR(v0,aux1 );}
  }

  if(v1 == 27){
    bytei = cons(0,0,0,0,0,0,0,8);
    byte = BYTE(v0,bytei); 
    if(byte.w0 == 0){ return v0;}   
    else{ aux1 = cons(0xffffffff,0,0,0,0,0,0,0); return OR(v0,aux1 );}
  }
  if(v1 == 30){ return v0; }
}

ethint256 EXP(ethint256 x, ethint256 y){
    ethint256 z = cons(0,0,0,0,0,0,0,1);
    int exp = y.w0; 
    if(exp == 0){
      return z;
    }
    if(exp == 1){
      return x;
    }
    else{
      return __VERIFIER_nondet_256();
    }
}


ethint256 MOD(ethint256 x, ethint256 y){
  return __VERIFIER_nondet_256();
}

ethint256 MODX(ethint256 x, ethint256 y, ethint256 z){
  return __VERIFIER_nondet_256();
}

ethint256 SMOD(ethint256 x, ethint256 y){
  return __VERIFIER_nondet_256();
}

ethint256 MUL(ethint256 x, ethint256 y){
  return __VERIFIER_nondet_256();
}

ethint256 DIV(ethint256 x, ethint256 y){
  return __VERIFIER_nondet_256();
}

ethint256 SDIV(ethint256 x, ethint256 y){
  return __VERIFIER_nondet_256();
}


ethint256 COPY(ethint256 x){
  ethint256 res;
  res.w0 = x.w0;
  res.w1 = x.w1;
  res.w2 = x.w2;
  res.w3 = x.w3;
  res.w4 = x.w4;
  res.w5 = x.w5;
  res.w6 = x.w6;
  res.w7 = x.w7;
  return res;
}

ethint256 ASSIGN(int x0,int x1,int x2,int x3,int x4,int x5,int x6, int x7){
  ethint256 res;
  res.w0 = x7;
  res.w1 = x6;
  res.w2 = x5;
  res.w3 = x4;
  res.w4 = x3;
  res.w5 = x2;
  res.w6 = x1;
  res.w7 = x0; 
  return res;
}
