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
   ulong             GetExpertMagic()const {return obj_expert_magic;};
   ENUM_OPENORDER_RESULT OrderOpen(ENUM_ORDER_TYPE order_type,const string symbol,double volume,double price=0.0,double sl=0.0,double tp=0.0,const string comment=NULL);
   double            GetClosePositionsResult(datetime start_period,datetime end_period=0,const string symbol=NULL)const;
   double            GetOpenPositionsResult(const string symbol=NULL)const;
private:
   //FUNCTIONS
   bool              VerifyOrderMargin(ENUM_ORDER_TYPE order_type,const string symbol,double volume,double price)const;
   ulong             obj_expert_magic;
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
   obj_expert_magic=expert_magic;
   obj_trade.SetExpertMagicNumber(obj_expert_magic);
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
   double used_price=price;
   if(used_price==0)
     {
      if(order_type==ORDER_TYPE_BUY)
         used_price=SymbolInfoDouble(symbol,SYMBOL_ASK);
      if(order_type==ORDER_TYPE_SELL)
         used_price=SymbolInfoDouble(symbol,SYMBOL_BID);
     }
   double need_margin;
   if(!OrderCalcMargin(order_type,symbol,volume,used_price,need_margin))
     {
      return false;
     }
   if(AccountInfoDouble(ACCOUNT_MARGIN_FREE)>need_margin)
      return true;
   return false;
  }

//+------------------------------------------------------------------+
double CNegotiation::GetClosePositionsResult(datetime start_period,datetime end_period=0,const string symbol=NULL)const
  {
   datetime use_end_period=end_period;
   if(use_end_period==0)
      use_end_period=TimeCurrent();
   if(!HistorySelect(start_period,end_period))
      return 0;
   double result=0;
   ulong ticket;
   for(int i=0; i<HistoryDealsTotal(); i++)
     {
      ticket=HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(ticket,DEAL_MAGIC)!=obj_expert_magic)
         continue;
      if(symbol!=NULL)
         if(HistoryDealGetString(ticket,DEAL_SYMBOL)!=symbol)
            continue;
      result+=HistoryDealGetDouble(ticket,DEAL_PROFIT);
     }
   return result;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CNegotiation::GetOpenPositionsResult(const string symbol=NULL)const
  {
   double result=0;
   for(int i=0; i<PositionsTotal(); i++)
     {
      if(!PositionSelectByTicket(PositionGetTicket(i)))
         continue;
      if(PositionGetInteger(POSITION_MAGIC)!=obj_expert_magic)
         continue;
      if(symbol!=NULL)
         if(PositionGetString(POSITION_SYMBOL)!=symbol)
            continue;
      result+=PositionGetDouble(POSITION_PROFIT);
     }
   return result;
  }
//+------------------------------------------------------------------+
