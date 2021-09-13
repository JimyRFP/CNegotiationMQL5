//+------------------------------------------------------------------+
//|                                                 CNegotiation.mqh |
//|                                            Rafael Floriani Pinto |
//|                           https://www.mql5.com/en/users/rafaelfp |
//+------------------------------------------------------------------+
#ifndef CNEGOTIATIONJIMYRFP
#define CNEGOTIATIONJIMYRFP
#property copyright "Rafael Floriani Pinto"
#property link      "https://www.mql5.com/en/users/rafaelfp"
#include<Trade/Trade.mqh>
enum ENUM_OPENORDER_RESULT
  {
   OPENORDER_RESULT_OK=0,
   OPENORDER_RESULT_INSUFFICIENTMARGIN,
   OPENORDER_RESULT_TRADEERROR,

  };
enum ENUM_NEGOTIATION_ACTION
  {
   NEGOTIATION_ACTION_NONE,
   NEGOTIATION_ACTION_BUY,
   NEGOTIATION_ACTION_SELL,
   NEGOTIATION_ACTION_BUY_LIMIT,
   NEGOTIATION_ACTION_BUY_STOP,
   NEGOTIATION_ACTION_SELL_LIMIT,
   NEGOTIATION_ACTION_SELL_STOP,
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CNegotiation
  {
public:
                     CNegotiation(ulong expert_magic=0);
   void              SetExpertMagic(ulong expert_magic);
   ulong             GetExpertMagic()const {return obj_expert_magic;};
   ENUM_OPENORDER_RESULT OrderOpen(ENUM_ORDER_TYPE order_type,const string symbol,double volume,double price=0.0,double sl=0.0,double tp=0.0,const string comment=NULL);
   ENUM_OPENORDER_RESULT OrderOpen(ENUM_NEGOTIATION_ACTION negotiation_action,const string symbol,double volume,double price=0.0,double sl=0.0,double tp=0.0,const string comment=NULL);
   double            GetClosePositionsResult(datetime start_period,datetime end_period=0,const string symbol=NULL)const;
   double            GetOpenPositionsResult(const string symbol=NULL)const;
   double            GetOACPositionsResult(datetime start_period,datetime end_period=0,const string symbol=NULL)const {return (GetClosePositionsResult(start_period,end_period,symbol)+GetOpenPositionsResult(symbol));}
   bool              CloseOrders(const string symbol=NULL);
   bool              ClosePositions(const string symbol=NULL);
   bool              PositionCloseByTicket(ulong ticket);
   ENUM_ORDER_TYPE   NegotiationActionToOrderType(ENUM_NEGOTIATION_ACTION negotiation_action);
   bool              CloseOrdersAndPositions(const string symbol=NULL) {return (CloseOrders(symbol)&&ClosePositions(symbol));}
   int               GetPositionsTotal(const string symbol=NULL);
private:
   //FUNCTIONS
   bool              VerifyOrderMargin(ENUM_ORDER_TYPE order_type,const string symbol,double volume,double price)const;

   bool              IsEAPosition(ulong ticket,const string symbol)const;
   bool              IsEAOrder(ulong ticket,const string symbol)const;
   //OBJECTS
   CTrade            obj_trade;
   ulong             obj_expert_magic;

  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CNegotiation::CNegotiation(ulong expert_magic=0)
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
ENUM_OPENORDER_RESULT CNegotiation::OrderOpen(ENUM_NEGOTIATION_ACTION negotiation_action,const string symbol,double volume,double price=0.000000,double sl=0.000000,double tp=0.000000,const string comment=NULL)
  {
   ENUM_ORDER_TYPE order_type=NegotiationActionToOrderType(negotiation_action);
   return OrderOpen(order_type,symbol,volume,price,sl,tp,comment);
  }


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
   if(!HistorySelect(start_period,use_end_period))
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
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(IsEAPosition(PositionGetTicket(i),symbol))
         result+=PositionGetDouble(POSITION_PROFIT);
     }
   return result;
  }
//+------------------------------------------------------------------+
bool CNegotiation::CloseOrders(const string symbol=NULL)
  {
   ulong ticket;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      ticket=OrderGetTicket(i);
      if(IsEAOrder(ticket,symbol))
         obj_trade.OrderDelete(ticket);
     }
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::ClosePositions(const string symbol=NULL)
  {
   ulong ticket;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ticket=PositionGetTicket(i);
      if(IsEAPosition(ticket,symbol))
         PositionCloseByTicket(ticket);
     };
   return true;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::PositionCloseByTicket(ulong ticket)
  {
   if(AccountInfoInteger(ACCOUNT_MARGIN_MODE)==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
     {
      return obj_trade.PositionClose(ticket);
     }
   if(!PositionSelectByTicket(ticket))
      return false;
   const double volume=PositionGetDouble(POSITION_VOLUME);
   const string symbol=PositionGetString(POSITION_SYMBOL);
   if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
     {
      return obj_trade.Sell(volume,symbol);
     }
   else
     {
      return obj_trade.Buy(volume,symbol);
     }

   return false;

  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE CNegotiation::NegotiationActionToOrderType(ENUM_NEGOTIATION_ACTION negotiation_action)
  {
   switch(negotiation_action)
     {
      case NEGOTIATION_ACTION_BUY:
         return ORDER_TYPE_BUY;
      case NEGOTIATION_ACTION_SELL:
         return ORDER_TYPE_SELL;
      case NEGOTIATION_ACTION_BUY_LIMIT:
         return ORDER_TYPE_BUY_LIMIT;
      case NEGOTIATION_ACTION_BUY_STOP:
         return ORDER_TYPE_BUY_STOP;
      case NEGOTIATION_ACTION_SELL_LIMIT:
         return ORDER_TYPE_SELL_LIMIT;
      case NEGOTIATION_ACTION_SELL_STOP:
         return ORDER_TYPE_SELL_STOP;
     }
   return -1;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CNegotiation::GetPositionsTotal(const string symbol=NULL)
  {
   int total_positions=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(IsEAPosition(PositionGetTicket(i),symbol))
         total_positions++;
     }
   return total_positions;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::IsEAPosition(ulong ticket,const string symbol)const
  {
   if(!PositionSelectByTicket(ticket))
      return false;
   if(PositionGetInteger(POSITION_MAGIC)!=obj_expert_magic)
      return false;
   if(symbol!=NULL)
      if(PositionGetString(POSITION_SYMBOL)!=symbol)
         return false;
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::IsEAOrder(ulong ticket,const string symbol)const
  {
   if(!OrderSelect(ticket))
      return false;
   if(OrderGetInteger(ORDER_MAGIC)!=obj_expert_magic)
      return false;
   if(symbol!=NULL)
      if(OrderGetString(ORDER_SYMBOL)!=symbol)
         return false;
   return true;
  }
#endif
//+------------------------------------------------------------------+
