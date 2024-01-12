pragma solidity ^0.8.0;

/* contract A { */
/*   uint num; */
/*   uint n1; */

/*   function f (uint a) public{ */
/*     if (a<5){ */
/*       num = 7; */
/*       for(uint i = 0; i< a; i++){ */
/*         if (num % 2 == 1){ */
/*           n1 = n1-3; */
/*         } */
/*       } */
/*     }else { */
/*       num = 2; */

/*       if (num % 2 == 1){ */
/*         n1 = n1-3; */
/*       } */
/*       else if (num %2 == 0){ */
/*         n1 = n1 +3; */
/*       } */

/*       else if (num+n1 == 0){ */
/*         n1 = 0; */
/*       } */
/*     } */

/*     n1 = num+6; */

/*     if(n1 %2 == 0){ */
/*       n1 = n1*2; */
/*     }else{ */
/*       n1 = n1+1; */
/*     } */

/*     uint total = n1+num; */
    
/*   } */
  
  
/* } */


/* contract B { */
/*   uint num; */
/*   uint n1; */

/*   function f(uint a)  public { */

/*      if (a<5){  */
/*       num = 7; */
/*      }else{ */
/*        num = 8; */
/*      } */

/*      n1 = n1+1; */
      
/*   } */


/* } */


contract C {

  uint number;
  
  function f(uint a) public {
    for(uint i = 0;i < a; i++){
      number = number+1;
    }
    
  }

  function ff() public returns (uint){

    uint b = 5;
    return b;
  }
  
}

/* contract D { */

/*   uint number; */
/*   uint num1; */
/*   uint num2; */

  
/*   function f(uint a) public { */
/*     if (a == 0){ */
/*       num1 = a; */
/*     } */
/*     else{ */
/*       number = a; */
/*     } */

/*     //    num2 = num1+number; */

/*   } */
  
/* } */
