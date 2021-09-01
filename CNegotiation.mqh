//+------------------------------------------------------------------+
//|                                                 CNegotiation.mqh |
//|                                            Rafael Floriani Pinto |
//|                           https://www.mql5.com/en/users/rafaelfp |
//+------------------------------------------------------------------+
#property copyright "Rafael Floriani Pinto"
#property link      "https://www.mql5.com/en/users/rafaelfp"
#include<Trade/Trade.mqh>
enum ENUM_OPENORDER_RESULT
  {
   OPENORDER_RESULT_OK=0,
   OPENORDER_RESULT_INSUFFICIENTMARGIN,
   OPENORDER_RESULT_TRADEERROR,

  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CNegotiation
  {
public:
                     CNegotiation(ulong expert_magic);
   void              SetExpertMagic(ulong expert_magic);
   ENUM_OPENORDER_RESULT OrderOpen(ENUM_ORDER_TYPE order_type,const string symbol,double volume,double price=0.0,double sl=0.0,double tp=0.0,const string comment=NULL);
private:
   //FUNCTIONS
   bool              VerifyOrderMargin(ENUM_ORDER_TYPE order_type,const string symbol,double volume,double price)const;

   //OBJECTS
   CTrade            obj_trade;


  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CNegotiation::CNegotiation(ulong expert_magic)
  {
   SetExpertMagic(expert_magic);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNegotiation::SetExpertMagic(ulong expert_magic)
  {
   obj_trade.SetExpertMagicNumber(expert_magic);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_OPENORDER_RESULT CNegotiation::OrderOpen(ENUM_ORDER_TYPE order_type,const string symbol,double volume,double price=0.0,double sl=0.0,double tp=0.0,const string comment=NULL)
  {
   if(!VerifyOrderMargin(order_type,symbol,volume,price))
      return OPENORDER_RESULT_INSUFFICIENTMARGIN;
   bool openorder_result=false;
   switch(order_type)
     {
      case ORDER_TYPE_BUY:
         openorder_result=obj_trade.Buy(volume,symbol,price,sl,tp,comment);
         break;
      case ORDER_TYPE_SELL:
         openorder_result=obj_trade.Sell(volume,symbol,price,sl,tp,comment);
         break;
      default:
         openorder_result=obj_trade.OrderOpen(symbol,order_type,volume,0.0,price,sl,tp,ORDER_TIME_GTC,0,comment);
     }
   if(!openorder_result)
     return OPENORDER_RESULT_TRADEERROR;
   return OPENORDER_RESULT_OK;
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::VerifyOrderMargin(ENUM_ORDER_TYPE order_type,const string symbol,double volume,double price)const
  {
   double need_margin;
   if(!OrderCalcMargin(order_type,symbol,volume,price,need_margin))
      return false;
   if(AccountInfoDouble(ACCOUNT_MARGIN_FREE)>need_margin)
      return true;
   return false;
  }

//+------------------------------------------------------------------+
