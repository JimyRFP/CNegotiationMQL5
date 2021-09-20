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
struct struct_position_info
  {
   ulong             ticket;
   datetime          entry_time;
   double            min_price;
   double            max_price;
   double            last_partial_price;
   double            breakeven_price;
   double            trailing_stop_last_price;
  };


namespace NSNegotiation
{
double GetMarketPriceByAction(ENUM_NEGOTIATION_ACTION action,const string symbol)
  {
   switch(action)
     {
      case NEGOTIATION_ACTION_BUY:
         return SymbolInfoDouble(symbol,SYMBOL_ASK);
      case NEGOTIATION_ACTION_SELL:
         return SymbolInfoDouble(symbol,SYMBOL_BID);
     }
   return 0;
  }
double GetSLPriceByAction(ENUM_NEGOTIATION_ACTION action,double entry_price,double sl_distance)
  {
   switch(action)
     {
      case NEGOTIATION_ACTION_BUY:
         return entry_price-sl_distance;
      case NEGOTIATION_ACTION_SELL:
         return entry_price+sl_distance;
     }
   return -1;
  }
double GetMarketPriceByPositionType(ENUM_POSITION_TYPE position_type,const string symbol)
  {
   switch(position_type)
     {
      case POSITION_TYPE_BUY:
         return GetMarketPriceByAction(NEGOTIATION_ACTION_BUY,symbol);
      case POSITION_TYPE_SELL:
         return GetMarketPriceByAction(NEGOTIATION_ACTION_SELL,symbol);
     }
   return 0;

  }


}


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
   int               GetOrdersTotal(const string symbol=NULL);
   int               GetOrdersAndPositionsTotal(const string symbol=NULL) {return (GetPositionsTotal(symbol)+GetOrdersTotal(symbol));}
   void              VerifyPartial(double descrease_volume,double distance_price,const string symbol=NULL);
   void              PrintActivePositions();
   int               UpdateActivePositions();
   bool              DecreasePositionVolume(ulong ticket,double decrease_volume);
   void              VerifyBreakEven(double distance_price,const string symbol=NULL);
   void              VerifyTrailingStop(double trigger_distance,double move_distance,double pass_distance);
private:
   //FUNCTIONS
   bool              VerifyOrderMargin(ENUM_ORDER_TYPE order_type,const string symbol,double volume,double price)const;
   bool              IsEAPosition(ulong ticket,const string symbol)const;
   bool              IsEAOrder(ulong ticket,const string symbol)const;
   int               GetPositionActiveIndexByTicket(ulong ticket)const;
   bool              IsActivePosition(const struct_position_info &position_info)const;
   bool              RegisterNewActivePosition(ulong ticket,struct_position_info &dst)const;
   bool              UpdatePositionActiveData(struct_position_info &position_info)const;
   void              VerifyPositionPartial(struct_position_info &position,double partial_price,double decrease_volume);
   void              VerifyPositionBreakEven(struct_position_info&position,double be_price);
   void              VerifyPositionTrailingStop(struct_position_info&position,double trigger_price,double move_distance,double pass_distance);
   //OBJECTS
   CTrade            obj_trade;
   ulong             obj_expert_magic;
   struct_position_info obj_positions_active[];


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
int CNegotiation::GetOrdersTotal(const string symbol=NULL)
  {
   int orders_total=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(IsEAOrder(OrderGetTicket(i),symbol))
         orders_total++;
     }
   return orders_total;

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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CNegotiation::GetPositionActiveIndexByTicket(ulong ticket)const
  {
   for(int i=0; i<ArraySize(obj_positions_active); i++)
     {
      if(obj_positions_active[i].ticket!=ticket)
         continue;
      if(IsActivePosition(obj_positions_active[i]))
         return i;
     }
   return -1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::IsActivePosition(const struct_position_info &position_info)const
  {
   if(!PositionSelectByTicket(position_info.ticket))
      return false;
   if(position_info.entry_time!=PositionGetInteger(POSITION_TIME))
      return false;
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CNegotiation::UpdateActivePositions(void)
  {
   struct_position_info new_positions[];
   int positions_total=PositionsTotal();
   if(ArrayResize(new_positions,positions_total)!=positions_total)
      return -1;
   int positions_added=0;
   int position_registered_index;
   ulong ticket;
   for(int i=positions_total-1; i>=0; i--)
     {
      ticket=PositionGetTicket(i);
      if(!IsEAPosition(ticket,NULL))
         continue;
      position_registered_index=GetPositionActiveIndexByTicket(ticket);
      if(position_registered_index<0)
        {
         RegisterNewActivePosition(ticket,new_positions[positions_added]);
        }
      else
        {
         new_positions[positions_added]=obj_positions_active[position_registered_index];
        }
      UpdatePositionActiveData(new_positions[positions_added]);
      positions_added++;
     }
   if(positions_added==0)
      return 0;
   ArrayCopy(obj_positions_active,new_positions);
   if(ArraySize(obj_positions_active)!=positions_added)
      ArrayResize(obj_positions_active,positions_added);
   return positions_added;
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::RegisterNewActivePosition(ulong ticket,struct_position_info &dst)const
  {
   ZeroMemory(dst);
   dst.ticket=ticket;
   dst.entry_time=(datetime)PositionGetInteger(POSITION_TIME);
   dst.min_price=dst.max_price=PositionGetDouble(POSITION_PRICE_CURRENT);

   return true;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::UpdatePositionActiveData(struct_position_info &position_info)const
  {
   if(!PositionSelectByTicket(position_info.ticket))
      return false;
   double current_price=PositionGetDouble(POSITION_PRICE_CURRENT);
   if(current_price>position_info.max_price)
      position_info.max_price=current_price;
   if(current_price<position_info.min_price)
      position_info.min_price=current_price;
   return true;
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNegotiation::PrintActivePositions(void)
  {
   for(int i=0; i<ArraySize(obj_positions_active); i++)
     {
      printf("Index %d",i);
      printf("Position Ticket %d",obj_positions_active[i].ticket);
      printf("Position Time %s",TimeToString(obj_positions_active[i].entry_time));
      printf("Position MinPrice %f",obj_positions_active[i].min_price);
      printf("Position MaxPrice %f",obj_positions_active[i].max_price);
      printf("Position Partial Price %f",obj_positions_active[i].last_partial_price);
      printf("Position ts price %f",obj_positions_active[i].trailing_stop_last_price);
      printf("Positions be price %f",obj_positions_active[i].breakeven_price);
     };
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNegotiation::VerifyPartial(double decrease_volume,double price_distance,const string symbol=NULL)
  {
   for(int i=ArraySize(obj_positions_active)-1; i>=0; i--)
     {

      if(!IsEAPosition(obj_positions_active[i].ticket,symbol))
         continue;
      double partial_price=PositionGetDouble(POSITION_PRICE_OPEN);
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         partial_price+=price_distance;
        }
      else
        {
         partial_price-=price_distance;
        }
      VerifyPositionPartial(obj_positions_active[i],partial_price,decrease_volume);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNegotiation::VerifyPositionPartial(struct_position_info &position,double partial_price,double decrease_volume)
  {
   double market_price;
   if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
     {
      if(position.last_partial_price>=partial_price)
         return;
      market_price=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_BID);
      if(market_price<partial_price)
         return;

     }
   else
     {
      if(position.last_partial_price!=0 && position.last_partial_price<=partial_price)
         return;
      market_price=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_ASK);
      if(market_price>partial_price)
         return;
     }
   if(DecreasePositionVolume(position.ticket,decrease_volume))
      position.last_partial_price=market_price;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::DecreasePositionVolume(ulong ticket,double decrease_volume)
  {
   if(!PositionSelectByTicket(ticket))
      return false;
   if(PositionGetDouble(POSITION_VOLUME)<decrease_volume)
      return false;
   if(AccountInfoInteger(ACCOUNT_MARGIN_MODE)==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
     {
      return obj_trade.PositionClosePartial(ticket,decrease_volume);
     }
   else
     {
      ENUM_NEGOTIATION_ACTION action;
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         action=NEGOTIATION_ACTION_SELL;
        }
      else
        {
         action=NEGOTIATION_ACTION_BUY;
        }
      if(OrderOpen(action,PositionGetString(POSITION_SYMBOL),decrease_volume)==OPENORDER_RESULT_OK)
         return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNegotiation::VerifyPositionBreakEven(struct_position_info &position,double be_price)
  {
   double position_sl=PositionGetDouble(POSITION_SL);
   double position_entry_price=PositionGetDouble(POSITION_PRICE_OPEN);
   if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
     {
      if(position_sl>=position_entry_price)
         return;
      double market_price=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_BID);
      if(market_price<be_price)
         return;
     }
   else
     {
      if(position_sl!=0 && position_sl<=position_entry_price)
         return;
      double market_price=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_ASK);
      if(market_price>be_price)
         return;
     }

   obj_trade.PositionModify(position.ticket,position_entry_price,PositionGetDouble(POSITION_TP));

  }
  
void CNegotiation::VerifyBreakEven(double distance_price,const string symbol=NULL){
  for(int i=0;i<ArraySize(obj_positions_active);i++){
    if(!IsEAPosition(obj_positions_active[i].ticket,symbol))
      continue;
    double be_price=PositionGetDouble(POSITION_PRICE_OPEN);
    if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
      be_price+=distance_price;
    }else{
      be_price-=distance_price;
    }    
    VerifyPositionBreakEven(obj_positions_active[i],be_price);
  }
}  


void CNegotiation::VerifyPositionTrailingStop(struct_position_info &position,double trigger_price,double trailing_move,double trailing_pass){
  double new_sl=PositionGetDouble(POSITION_SL);
  if(new_sl<=0)
    return;  
  double market_price;  
  if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
    market_price=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_BID);
    if(position.trailing_stop_last_price>=market_price)
      return;
    if(trigger_price>market_price)
      return;  
    if(market_price-position.trailing_stop_last_price<trailing_move)
      return;    
    new_sl+=trailing_pass;  
  }else{  
    market_price=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_ASK);
    if(position.trailing_stop_last_price!=0 && position.trailing_stop_last_price<=market_price)
      return;
    if(trigger_price<market_price)
      return;
    if(position.trailing_stop_last_price!=0)  
      if(position.trailing_stop_last_price-market_price<trailing_move)
        return;    
    new_sl-=trailing_pass;    
  }
  if(obj_trade.PositionModify(position.ticket,new_sl,PositionGetDouble(POSITION_TP)))
    position.trailing_stop_last_price=market_price;

}
#endif
//+------------------------------------------------------------------+
