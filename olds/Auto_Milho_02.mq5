//+------------------------------------------------------------------+
//|                                                Auto_Milho_02.mq5 |
//|                                            Mateus Salmazo Takaki |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mateus Salmazo Takaki"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>

input ulong INP_VOLUME        = 1;
//input double INP_TAKEPROFIT   = 00.0;
input double INP_STOPLOSS     = 1.1;
//input double INP_BRACKEVEN;

CTrade Trade;

MqlRates    candles[];
MqlTick     tick;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
      
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      // Cria as Arrays de preços 
      double MMeRed[];
      double MMeBlue[];
      bool posicao = true;
      double breakeven = 0.0;
      
      PositionSelect(_Symbol);      
      ulong type     = PositionGetInteger(POSITION_TYPE);          // type 0: Comprado | 1: Vendido.
      double preco   = PositionGetDouble(POSITION_PRICE_OPEN);     // Recupera o preço de entrada.
      double precoStop = 0.0;
      
      int ordensTotal   =   OrdersTotal();
      ulong orderTicket = 0;
      orderTicket = OrderGetTicket(0);
      /*
      if(OrderSelect(orderTicket)){
         Print("Order Type: ", OrderGetInteger(ORDER_TYPE),":", EnumToString((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)));
      }
      Print("Position Type: ", PositionGetInteger(POSITION_TYPE),":", EnumToString((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)));
      */      
      // Recupera os valores dos ultimos 3 candles.
      int copied = CopyRates(_Symbol, _Period, 0, 3, candles);
      // Define as propriedades da média móvel exponencial de 9 periodos e deslocamento de 1.
      int movingAverageRed = iMA(_Symbol, _Period, 9, 1, MODE_EMA, PRICE_HIGH);
      // Define as propriedades da média móvel exponencial de 9 periodos sem o deslocamento.
      int movingAverageBlue = iMA(_Symbol, _Period, 9, 1, MODE_EMA, PRICE_LOW);
      
      //Recupera o valor do preço corrente (tick).
      SymbolInfoTick(_Symbol, tick);         // a variável tick definida no top do código possui o preço corrente.
      
      // Inverte a posição do Array para o preço mais recente ficar na posição 0.
      ArraySetAsSeries(MMeRed, true);
      ArraySetAsSeries(MMeBlue, true);
      ArraySetAsSeries(candles, true);
      
      //
      CopyBuffer(movingAverageRed, 0, 0, 3, MMeRed);
      CopyBuffer(movingAverageBlue, 0, 0, 3, MMeBlue);
      
      //Teste do tick:
      //Print("Tick: ", tick.last);
      

      if(candles[1].close > MMeRed[1] && (tick.last > candles[1].high) && type != 0) {
         if(PositionsTotal() >= 1){
            posicao   = EliminaPosicao();
         }
         bool ordem     = EliminaOrdem();

         if(posicao && ordem){
            if(BuyMarket()){
               Print("COMPRA EM: ", preco, " ", TimeCurrent());
            }
            //Posiciona uma ordem stop respeitando a gestão de risco de INP_STOPLOSS.
            precoStop = preco - INP_STOPLOSS;
            if(SellStop(precoStop)){ 
               Print("Stop Venda Inserido", TimeCurrent());
               breakeven = preco + INP_STOPLOSS;
            }
         }
         else{
            Print("Erro: Problema na Posição ou na Ordem !", GetLastError());
            return;
         }
      }
      if(candles[1].close < MMeBlue[1] && (tick.last < candles[1].low) && type != 1){
         if(PositionsTotal() >= 1){
            posicao   = EliminaPosicao();
         }   
         bool ordem     = EliminaOrdem();

         if(posicao && ordem){
            if(SellMarket()){
               Print("VENDA EM: ", preco," ", TimeCurrent());
            }
            //Posiciona uma ordem stop respeitando a gestão de risco de INP_STOPLOSS.
            precoStop = preco + INP_STOPLOSS;
            if(BuyStop(precoStop)){ 
               Print("Stop Compra Inserido: ", TimeCurrent());
               breakeven = preco - INP_STOPLOSS;
            }
         }
         else{
            Print("Erro: Problema na Posição ou na Ordem !", GetLastError());
            return;
         }
         if(tick.last == breakeven)
         {
            //Se estiver aberta uma operação de stop compra:
            if(OrderSelect(orderTicket) && OrderGetInteger(ORDER_TYPE) == 4){
               if(EliminaOrdem()){
                  
               }
            }
            // Se aberta uma operação de stop venda: 
            else if(OrderSelect(orderTicket) && OrderGetInteger(ORDER_TYPE) == 5){
               if(EliminaOrdem()){
                  
               }
            }
         }
      }   
  }
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//| Expert Buy function                                              |
//+------------------------------------------------------------------+
bool BuyMarket(){
   
   bool ok = Trade.Buy(INP_VOLUME, _Symbol);
   if(!ok){
      int errorCode = GetLastError();
      Print("Falha BuyMarket: ERRO: ", errorCode);
      ResetLastError();
   }
   return ok;
}
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| Expert Sell function                                             |
//+------------------------------------------------------------------+
bool SellMarket(){
   
   bool ok = Trade.Sell(INP_VOLUME, _Symbol);
   if(!ok){
      int errorCode = GetLastError();
      Print("Falha SellMarket ERRO: ", errorCode);
      ResetLastError();
   }
   return ok;
}
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| Expert BuyStop function                                          |
//+------------------------------------------------------------------+
bool BuyStop(double _price_stop){
   
   bool ok = Trade.BuyStop(INP_VOLUME, _price_stop,_Symbol );
   if(!ok){
      int errorCode = GetLastError();
      Print("Falha BuyStop ERRO: ", errorCode);
      ResetLastError();
   }
   return ok;
}
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| Expert SellStop function                                         |
//+------------------------------------------------------------------+
bool SellStop(double _price_stop){
   
   bool ok = Trade.SellStop(INP_VOLUME, _price_stop,_Symbol );
   if(!ok){
      int errorCode = GetLastError();
      Print(" Falha SellStop ERRO: ", errorCode);
      ResetLastError();
   }
   return ok;
}
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| Expert Elimina Posição function                                  |
//+------------------------------------------------------------------+
bool EliminaPosicao(){
   //Print("Remove todas posição !");
   return Trade.PositionClose(_Symbol);
}
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//| Expert Elimina Posição function                                  |
//+------------------------------------------------------------------+
bool EliminaOrdem(){
   
   ulong orderTicket = 0;
   int index = 0;
   int flagOrdem = 0;
   bool boolOrder = true;
   
   //Verifica se existe alguma ordem pendente. Em caso positivo elimina a ordem.
   while(OrdersTotal() != 0){
      orderTicket = OrderGetTicket(0);
      boolOrder = Trade.OrderDelete(orderTicket);
      if(boolOrder == false)
         flagOrdem++;
   }
   
   if(flagOrdem > 0)
      return false;
   else
      return true;

}
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//| Expert Evolui Stop function                                      |
//+------------------------------------------------------------------+
void EvoluiStop(){
   //Essa função é responsável por elevar o stop para garantir a gestão de risco da estratégia.
   Print("Função EvoluiStop Ativada !"); 
}
//+------------------------------------------------------------------+


