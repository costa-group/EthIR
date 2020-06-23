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

 ethint256 NOT( ethint256 x) {
  ethint256 res;
  res.w0 = ~x.w0;
  res.w1 = ~x.w1;
  res.w2 = ~x.w2;
  res.w3 = ~x.w3;
  res.w4 = ~x.w4;
  res.w5 = ~x.w5;
  res.w6 = ~x.w6;
  res.w7 = ~x.w7;
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

ethint256 equals( ethint256 x,  ethint256 y) {
  ethint256 res0 = cons(0,0,0,0,0,0,0,0);
  ethint256 res1 = cons(0,0,0,0,0,0,0,1);

  if( (x.w7 == y.w7) && (x.w6 == y.w6) && (x.w5 == y.w5) && (x.w4 == y.w4) && (x.w3 == y.w3) && (x.w2 == y.w2) && (x.w1 == y.w1) && (x.w0 == y.w0) ){ return res1;}

  else {
    return res0; //distinto
  }
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

  if( x.w7 > y.w7) return 1;
  if( x.w7 < y.w7) return 0;
  if( x.w6 > y.w6) return 1;
  if( x.w6 < y.w6) return 0;
  if( x.w5 > y.w5) return 1;
  if( x.w5 < y.w5) return 0;
  if( x.w4 > y.w4) return 1;
  if( x.w4 < y.w4) return 0;
  if( x.w3 > y.w3) return 1;
  if( x.w3 < y.w3) return 0;
  if( x.w2 > y.w2) return 1;
  if( x.w2 < y.w2) return 0;
  if( x.w1 > y.w1) return 1;
  if( x.w1 < y.w1) return 0;
  if( x.w0 > y.w0) return 1;
  if( x.w0 < y.w0) return 0;
  return 0; 
}

ethint256 gt( ethint256 x,  ethint256 y) {
  ethint256 res0 = cons(0,0,0,0,0,0,0,0);
  ethint256 res1 = cons(0,0,0,0,0,0,0,1);

  if( x.w7 > y.w7) return res1;
  if( x.w7 < y.w7) return res0;
  if( x.w6 > y.w6) return res1;
  if( x.w6 < y.w6) return res0;
  if( x.w5 > y.w5) return res1;
  if( x.w5 < y.w5) return res0;
  if( x.w4 > y.w4) return res1;
  if( x.w4 < y.w4) return res0;
  if( x.w3 > y.w3) return res1;
  if( x.w3 < y.w3) return res0;
  if( x.w2 > y.w2) return res1;
  if( x.w2 < y.w2) return res0;
  if( x.w1 > y.w1) return res1;
  if( x.w1 < y.w1) return res0;
  if( x.w0 > y.w0) return res1;
  if( x.w0 < y.w0) return res0;
  return res0; 
}

int GEQ( ethint256 x,  ethint256 y) {
  if (LT(x,y) == 1) return 0;
  return 1; 
}

ethint256 geq( ethint256 x,  ethint256 y) {
  ethint256 res0 = cons(0,0,0,0,0,0,0,0);
  ethint256 res1 = cons(0,0,0,0,0,0,0,1);

  if (LT(x,y) == 1) return res0;
  return res1; 
}


 int LT( ethint256 x,  ethint256 y) {
  if( x.w7 < y.w7) return 1;
  if( x.w7 > y.w7) return 0;
  if( x.w6 < y.w6) return 1;
  if( x.w6 > y.w6) return 0;
  if( x.w5 < y.w5) return 1;
  if( x.w5 > y.w5) return 0;
  if( x.w4 < y.w4) return 1;
  if( x.w4 > y.w4) return 0;
  if( x.w3 < y.w3) return 1;
  if( x.w3 > y.w3) return 0;
  if( x.w2 < y.w2) return 1;
  if( x.w2 > y.w2) return 0;
  if( x.w1 < y.w1) return 1;
  if( x.w1 > y.w1) return 0;
  if( x.w0 < y.w0) return 1;
  if( x.w0 > y.w0) return 0;
  return 0; 
}

ethint256 lt( ethint256 x,  ethint256 y) {
  ethint256 res0 = cons(0,0,0,0,0,0,0,0);
  ethint256 res1 = cons(0,0,0,0,0,0,0,1);

  if( x.w7 < y.w7) return res1;
  if( x.w7 > y.w7) return res0;
  if( x.w6 < y.w6) return res1;
  if( x.w6 > y.w6) return res0;
  if( x.w5 < y.w5) return res1;
  if( x.w5 > y.w5) return res0;
  if( x.w4 < y.w4) return res1;
  if( x.w4 > y.w4) return res0;
  if( x.w3 < y.w3) return res1;
  if( x.w3 > y.w3) return res0;
  if( x.w2 < y.w2) return res1;
  if( x.w2 > y.w2) return res0;
  if( x.w1 < y.w1) return res1;
  if( x.w1 > y.w1) return res0;
  if( x.w0 < y.w0) return res1;
  if( x.w0 > y.w0) return res0;
  return res0; 
}

int LEQ( ethint256 x,  ethint256 y) {

  if (GT(x,y) == 1) return 0;
  return 1; 
}

ethint256 leq( ethint256 x,  ethint256 y) {
  ethint256 res0 = cons(0,0,0,0,0,0,0,0);
  ethint256 res1 = cons(0,0,0,0,0,0,0,1);

  if (GT(x,y) == 1) return res0;
  return res1; 
}

ethint256 sgt(ethint256 x, ethint256 y){ //> con signo
    ethint256 res0 = cons(0,0,0,0,0,0,0,0);
    ethint256 res1 = cons(0,0,0,0,0,0,0,1);
    unsigned int sx = x.w7 & 0x80000000; 
    unsigned int sy = y.w7 & 0x80000000; 

    if (sy > sx) return res1; // x positive - y negative 
    if (sx > sy) return res0; // x negative - y positive 

    return gt(x,y);
}

ethint256 slt(ethint256 x, ethint256 y){ //< con signo
    ethint256 res0 = cons(0,0,0,0,0,0,0,0);
    ethint256 res1 = cons(0,0,0,0,0,0,0,1);
    unsigned int sx = x.w7 & 0x80000000; 
    unsigned int sy = y.w7 & 0x80000000; 

    if (sy < sx) return res1; // x negative - y positive 
    if (sx < sy) return res0; // x positive - y negative 

    return lt(x,y);
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

    if (y.w0 < 4) w = x.w7; //se empieza a contar por la izquierda
    else if (y.w0 < 8 ) w = x.w6;
    else if (y.w0 < 12 ) w = x.w5;
    else if (y.w0 < 16 ) w = x.w4;
    else if (y.w0 < 20 ) w = x.w3;
    else if (y.w0 < 24 ) w = x.w2;
    else if (y.w0 < 28 ) w = x.w1;
    else if (y.w0 < 32 ) w = x.w0;
    else w = 0;

    int offset = y.w0 % 4;

    if (offset == 0) res.w0 = (w & 0xFF000000) >> 24;
    if (offset == 1) res.w0 = (w & 0x00FF0000) >> 16;
    if (offset == 2) res.w0 = (w & 0x0000FF00) >> 8;
    if (offset == 3) res.w0 = (w & 0x000000FF);
    return res;
}

ethint256 SIGNEXTEND(ethint256 v0,  ethint256 y){
  ethint256 res; 
  int v1 = y.w0; 

  if(v1 == 0){
   unsigned int x = v0.w0 & 0x000000ff;
    unsigned int sx = x & 0x80;
    if(sx == 0){
       res = cons(0,0,0,0,0,0,0,x);
    } 
    else{
      res = cons(0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffff00 | x);
    }
  }
  
  else if(v1 == 1){
    unsigned int x = v0.w0 & 0x0000ffff;
    unsigned int sx = x & 0x8000;
    if(sx == 0){
      res = cons(0,0,0,0,0,0,0,x);
    } 
    else{
      res = cons(0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffff0000 | x);
    }
  }
  
  else if(v1 == 2){
    unsigned int x = v0.w0 & 0x00ffffff;
    unsigned int sx = x & 0x800000;
    if(sx == 0){
      res = cons(0,0,0,0,0,0,0,0xff000000 | x);
    }
    else{
      res = cons(0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xff000000 | x);
    }
  }
  
  else if(v1 == 3){
    unsigned int x = v0.w0;
    unsigned int sx = x & 0x80000000;
    if(sx == 0){
      res = cons(0,0,0,0,0,0,0,x);
    } 
    else{
      res = cons(0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,x);
    }
  }
  
  else if(v1 == 7){
    unsigned int x = v0.w1;
    unsigned int sx = x & 0x80000000;
    if(sx == 0){
      res = cons(0,0,0,0,0,0,v0.w1,v0.w0);
    } 
    else{
      res = cons(0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,v0.w1,v0.w0);
    }
  }
  else if(v1 == 11){
    unsigned int x = v0.w2;
    unsigned int sx = x & 0x80000000;
    if(sx == 0){
      res = cons(0,0,0,0,0,v0.w2,v0.w1,v0.w0);
    } 
    else{
      res = cons(0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,v0.w2,v0.w1,v0.w0);
     
    }
  }
  else if(v1 == 15){
    unsigned int x = v0.w3;
    unsigned int sx = x & 0x80000000;
    if(sx == 0){
      res = cons(0,0,0,0,v0.w3,v0.w2,v0.w1,v0.w0);
     
    } 
    else{
      res = cons(0xffffffff,0xffffffff,0xffffffff,0xffffffff,v0.w3,v0.w2,v0.w1,v0.w0);
     
    }
  }
  
  else if(v1 == 19){
    unsigned int x = v0.w4;
    unsigned int sx = x & 0x80000000;
    if(sx == 0){      
      res =  cons(0,0,0,v0.w4,v0.w3,v0.w2,v0.w1,v0.w0);
  
    } 
    else{
      res = cons(0xffffffff,0xffffffff,0xffffffff,v0.w4,v0.w3,v0.w2,v0.w1,v0.w0);
  
    }
  }
  else if(v1 == 23){
    unsigned int x = v0.w5;
    unsigned int sx = x & 0x80000000;
    if(sx == 0){
      res = cons(0,0,v0.w5,v0.w4,v0.w3,v0.w2,v0.w1,v0.w0);
  
    } 
    else{
      res = cons(0xffffffff,0xffffffff,v0.w5,v0.w4,v0.w3,v0.w2,v0.w1,v0.w0);
  
    }
  }
  else if(v1 == 27){
    unsigned int x = v0.w6;
    unsigned int sx = x & 0x80000000;
    if(sx == 0){
      res = cons(0,v0.w6,v0.w5,v0.w4,v0.w3,v0.w2,v0.w1,v0.w0);

    } 
    else{
      res = cons(0xffffffff,v0.w6,v0.w5,v0.w4,v0.w3,v0.w2,v0.w1,v0.w0);

    }
  }

  else if(v1 == 31){ res =  v0; }

  else{
    res = __VERIFIER_nondet_256();
  }
  
  return res; 
}

ethint256 EXP(ethint256 x, ethint256 y){
  ethint256 res;
  
  int exp = y.w0; 
  if(exp == 0 && y.w1 == 0 && y.w2 == 0 &&  y.w3 == 0 && y.w4 == 0 && y.w5 == 0 && y.w6 == 0 && y.w7 == 0){
    res = cons(0,0,0,0,0,0,0,1);
   }
  if(exp == 1 && y.w1 == 0 && y.w2 == 0 &&  y.w3 == 0 && y.w4 == 0 && y.w5 == 0 && y.w6 == 0 && y.w7 == 0){
    res = cons(x.w7,x.w6,x.w5,x.w4, x.w3,x.w2,x.w1,x.w0);
  }
  else{
    res = __VERIFIER_nondet_256();
  }
  return res;
}


ethint256 MOD(ethint256 x, ethint256 y){
  ethint256 res;
  res = __VERIFIER_nondet_256();
   return res;
}

ethint256 MODX(ethint256 x, ethint256 y, ethint256 z){
  ethint256 res;
  res = __VERIFIER_nondet_256();
   return res;
}

ethint256 SMOD(ethint256 x, ethint256 y){
  ethint256 res;
  res = __VERIFIER_nondet_256();
   return res;
}

ethint256 MUL(ethint256 x, ethint256 y){
  ethint256 res;
  res = __VERIFIER_nondet_256();
   return res;
}

ethint256 DIV(ethint256 x, ethint256 y){
  ethint256 res;
  res = __VERIFIER_nondet_256();
   return res;
}

ethint256 SDIV(ethint256 x, ethint256 y){
  ethint256 res;
  res = __VERIFIER_nondet_256();
   return res;
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

//OVERFLOWS
/* if ((b > 0 && a <= INT_MAX / b && a >= INT_MIN / b) || */
/*     (b == 0) || */
/*     (b == -1 && a >= -INT_MAX) || */
/*     (b < -1 && a >= INT_MAX / b && a <= INT_MIN / b)) */
/* { */
/*     result = a * b; */
/* } */
/* else */
/* { */
/*     /\* calculation would overflow *\/ */
/* } */
