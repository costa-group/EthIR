pragma solidity ^0.4.11;

contract SmallExample{

  int suma = 0;
  int numero = 0;
  
  function multiplica(int a){
    
    for(int i = 0; i<a; i++){
      suma = suma+numero;
    }

  }

  
  //Analogo a nuestro main
  function enter(){
    numero = 5;
    multiplica(3);
    
  }

}
