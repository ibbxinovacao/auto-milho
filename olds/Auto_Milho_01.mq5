//+------------------------------------------------------------------+
//|                                                Auto_Milho_01.mq5 |
//|                                            Mateus Salmazo Takaki |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mateus Salmazo Takaki"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>

input ulong INP_VOLUME        = 1;
//input double INP_TAKEPROFIT   = 00.0;
//input double INP_STOPLOSS     = 0.0;

CTrade Trade;

MqlRates    candles[];
MqlTick     tick;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
     //  EventSetTimer(2);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
     // EventKillTimer();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      //Cria as Arrays de preços 
      double MMeRed[];
      double MMeBlue[];
      bool posicao = true;
      
      // Recupera os valores dos ultimos 3 candles.
      int copied = CopyRates(_Symbol, _Period, 0, 3, candles);
      //Define as propriedades da média móvel exponencial de 9 periodos e deslocamento de 1.
      int movingAverageRed = iMA(_Symbol, _Period, 9, 1, MODE_EMA, PRICE_CLOSE);
      //Define as propriedades da média móvel exponencial de 9 periodos sem o deslocamento.
      int movingAverageBlue = iMA(_Symbol, _Period, 9, 0, MODE_EMA, PRICE_CLOSE);
      
      //Inverte a posição do Array para o preço mais recente ficar na posição 0.
      ArraySetAsSeries(MMeRed, true);
      ArraySetAsSeries(MMeBlue, true);
      ArraySetAsSeries(candles, true);
      
      //
      CopyBuffer(movingAverageRed, 0, 0, 3, MMeRed);
      CopyBuffer(movingAverageBlue, 0, 0, 3, MMeBlue);
      
      PositionSelect(_Symbol);      
      ulong type       = PositionGetInteger(POSITION_TYPE);          //type 0: Comprado | 1: Vendido.
      
      if( (MMeRed[1]<MMeBlue[1]) && (MMeRed[2]>MMeBlue[2]) && (candles[0].high > candles[1].high) && type != 0){
         Comment("BUY");
         Print("Compra: ",TimeCurrent());
         Print("Anterior Vermelho: ", MMeRed[1], "Atual Vermelho: ", MMeRed[0], " Anterior Azul: ", MMeBlue[1], " Atual Azul: ", MMeBlue[0] );
         if(PositionsTotal() >= 1){
            posicao   = EliminaPosicao();
         }
         bool ordem     = EliminaOrdem();
         
         Print("posicao: ", posicao ," ordem: ", ordem);

         if(posicao && ordem){
            BuyMarket();
            SellStop(candles[1].low); // Posiciona uma ordem stop na mínima do candle anterior.
            Print("Compra e Stop Inseridos: ", TimeCurrent());
         }
         else{
            Print("Erro: Não foi possível realizar entrada!", GetLastError());
            return;
         }
      }
      
      if( (MMeBlue[0]<MMeRed[0]) && (MMeBlue[1]>MMeRed[1]) && ((candles[0].low < candles[1].low)) && type != 1 ){
         Comment("SELL");
         Print("Venda: ", TimeCurrent());
         Print("Anterior Vermelho: ", MMeRed[1], "Atual Vermelho: ", MMeRed[0], " Anterior Azul: ", MMeBlue[1], " Atual Azul: ", MMeBlue[0] );
         if(PositionsTotal() >= 1){
            posicao   = EliminaPosicao();
         }   
         bool ordem     = EliminaOrdem();
         
         Print("posicao: ", posicao ," ordem: ", ordem);

         if(posicao && ordem){
            SellMarket();
            BuyStop(candles[1].high); //Posiciona uma ordem stop na máxima do candle anterior.
            Print("Venda e Stop Inseridos: ", TimeCurrent());
         }
         else{
            Print("Erro: Não foi possível realizar entrada!", GetLastError());
            return;
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
      Print("BuyMarket: ", errorCode);
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
      Print("SellMarket: ", errorCode);
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
      Print("BuyStop: ", errorCode);
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
      Print("SellStop: ", errorCode);
      ResetLastError();
   }
   return ok;
}
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| Expert Elimina Posição function                                  |
//+------------------------------------------------------------------+
bool EliminaPosicao(){
   //Verifica se está em alguma posição. Em caso positivo elimina a posição
      Print("Remove todas posição !");
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



//+------------------------------------------------------------------+
//| Expert Evolui Stop function                                      |
//+------------------------------------------------------------------+
void OnTimer(){
   // Recupera os valores dos ultimos 3 candles.
   /*
   int copied = CopyRates(_Symbol, _Period, 0, 3, candles);
   ArraySetAsSeries(candles, true);
   Print("Abertura: ", candles[0].open);
   Print("Fechamento: ", candles[0].close);
   Print("Máxima: ",candles[0].high);
   Print("Mínima: ",candles[0].low);
   */
}
//+------------------------------------------------------------------+