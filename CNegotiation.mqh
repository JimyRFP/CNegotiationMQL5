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
   OPENORDER_RESULT_WAITING_BROKER_RESPONSE,

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
enum ENUM_AVERAGEPRICE_DIRECTION
  {
   AVERAGEPRICE_DIRECTION_UP,
   AVERAGEPRICE_DIRECTION_DOWN,
  };
enum ENUM_BROKER_RESPONSE
  {
   BROKER_RESPONSE_WAITING,
   BROKER_RESPONSE_PROCESSED,
  };

struct struct_position_info
  {
   ulong             ticket;
   datetime          entry_time;
   double            min_price;
   double            max_price;
   double            last_partial_price;
   double            breakeven_price;
   double            trailing_stop_start_stop;
  };

struct struct_waiting_position_response
  {
   datetime          set_time;
   MqlTradeResult    result;
  };
namespace NSNegotiation
{
struct struct_cnegotiation_info
  {
   double            last_close_positions_result;
   int               last_deals_total;
   datetime          last_deals_start_time;

  };


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
double GetTPPriceByAction(ENUM_NEGOTIATION_ACTION action,double entry_price,double tp_distance)
  {
   switch(action)
     {
      case NEGOTIATION_ACTION_BUY:
         return entry_price+tp_distance;
      case NEGOTIATION_ACTION_SELL:
         return entry_price-tp_distance;
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

ENUM_NEGOTIATION_ACTION ActionOpposed(ENUM_NEGOTIATION_ACTION action)
  {
   switch(action)
     {
      case NEGOTIATION_ACTION_BUY:
         return NEGOTIATION_ACTION_SELL;
      case NEGOTIATION_ACTION_SELL:
         return NEGOTIATION_ACTION_BUY;
      default:
         return action;
     }
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
   double            GetClosePositionsResult(datetime start_period,datetime end_period=0,const string symbol=NULL);
   double            GetOpenPositionsResult(const string symbol=NULL)const;
   double            GetOACPositionsResult(datetime start_period,datetime end_period=0,const string symbol=NULL) {return (GetClosePositionsResult(start_period,end_period,symbol)+GetOpenPositionsResult(symbol));}
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
   void              VerifyTrailingStop(double trigger_distance,double move_distance,double pass_distance,const string symbol);
   void              SetDesviationMax(ulong desviation) {obj_trade.SetDeviationInPoints(desviation);}
   void              Reset();
   void              VerifyAveragePrice(double distance,double price_entry,double volume_step,double volume_max,double takeprofit_distance,const string symbol=NULL);
   double            GetVolumeOpenPositionsTotal(const string symbol=NULL);
   bool              ThereOrderAtPrice(double price,ENUM_ORDER_TYPE order_type,double tolereance,const string symbol=NULL);
   void              AveragePriceControl(ENUM_AVERAGEPRICE_DIRECTION direction,
                                         ENUM_NEGOTIATION_ACTION action,
                                         double price_base,
                                         double pass,
                                         double volume_entry,
                                         double volume_step,
                                         double volume_max,
                                         double takeprofit_price,
                                         const string symbol
                                        );

   void              AveragePriceSetOrders(ENUM_AVERAGEPRICE_DIRECTION direction,
                                           ENUM_NEGOTIATION_ACTION action,
                                           double price_base,
                                           double pass,
                                           double volume_step,
                                           int price_level,
                                           int volume_opened_level,
                                           int direction_normalize,
                                           const string symbol);
   void              AveragePriceCloseInvalidOrders(ENUM_ORDER_TYPE order_type,double order_price,double tolerance,const string symbol);
   void              ontradetransaction(const MqlTradeTransaction&trans,const MqlTradeRequest&request,const MqlTradeResult&result);
   ENUM_OPENORDER_RESULT OrderDelete(ulong ticket);
   bool              PositionModify(const ulong ticket,const double sl,const double tp);
   bool              PositionClose(const ulong ticket);
   bool              PositionClosePartial(const ulong ticket,const double volume,const ulong deviation=ULONG_MAX);
   void              GetLastResult(MqlTradeResult &r){obj_trade.Result(r);}
   bool              IsEAPosition(ulong ticket,const string symbol)const;
   bool              IsEAOrder(ulong ticket,const string symbol)const;
   bool              IsEADeal(ulong ticket,const string symbol)const;
private:
   //FUNCTIONS
   bool              VerifyOrderMargin(ENUM_ORDER_TYPE order_type,const string symbol,double volume,double price)const;
   int               GetPositionActiveIndexByTicket(ulong ticket)const;
   bool              IsActivePosition(const struct_position_info &position_info)const;
   bool              RegisterNewActivePosition(ulong ticket,struct_position_info &dst)const;
   bool              UpdatePositionActiveData(struct_position_info &position_info)const;
   void              VerifyPositionPartial(struct_position_info &position,double partial_price,double decrease_volume);
   void              VerifyPositionBreakEven(struct_position_info&position,double be_price);
   void              VerifyPositionTrailingStop(struct_position_info&position,double trigger_price,double move_distance,double pass_distance);
   void              AveragePriceCloseProfitPositions(ENUM_NEGOTIATION_ACTION action,
         double takeprofit_price,
         double price_base,
         double pass,
         double volume_step,
         int    volume_level,
         const string symbol);
   void              AveragePriceCloseProfitPositionsHedging(double entry_price,double tolerance,double takeprofit_price,const string symbol);
   void              AveragePriceCloseProfitPositionsNetting(ENUM_NEGOTIATION_ACTION action,
         int volume_level,
         double price_base,
         double price_current,
         double order_pass,
         double takeprofit_price,
         double volume_step,
         const string symbol
                                                            );
   bool              copyMqlTradeResult(MqlTradeResult &dst,const MqlTradeResult &src);
   bool              addWaitingServerTradeResult(struct_waiting_position_response &r);
   bool              removeWatingServerResponseByIndex(int index);
   bool              copyWatingServerResponseStruct(struct_waiting_position_response &dst,const struct_waiting_position_response &src);
   bool              copyWatingServerResponseStructArray(struct_waiting_position_response &dst[],const struct_waiting_position_response &src[]);
   bool              removeWatingServerResponseByOrder(ulong order);
   bool              removeWatingServerResponseByDeal(ulong deal);
   bool              verifyServerResponse(int,int);
   bool              freeWatingServerResponse();
   bool              addNewPaddingServerOrder();
   datetime          getServerResponseStructGreaterDateTime(const struct_waiting_position_response &str[])const;
   //OBJECTS
   CTrade            obj_trade;
   ulong             obj_expert_magic;
   struct_position_info obj_positions_active[];
   NSNegotiation::struct_cnegotiation_info obj_info;
   const ENUM_ACCOUNT_MARGIN_MODE obj_account_margin_mode;
   ENUM_BROKER_RESPONSE obj_broker_resposne;
   int               obj_waiting_server_response_max;
   struct_waiting_position_response obj_waiting_server_positions[];
   const bool        is_mql_tester_mode;

  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CNegotiation::CNegotiation(ulong expert_magic=0):
   obj_account_margin_mode((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE)),
   is_mql_tester_mode((bool)MQLInfoInteger(MQL_TESTER))
  {
   SetExpertMagic(expert_magic);
   Reset();

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
void CNegotiation::Reset()
  {
   ZeroMemory(obj_info);
   obj_broker_resposne=BROKER_RESPONSE_PROCESSED;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::verifyServerResponse(int max=2,int waiting_sec=5)
  {
   if(is_mql_tester_mode)
      return true;
   if(ArraySize(obj_waiting_server_positions)>=max)
     {
      datetime greater_date=getServerResponseStructGreaterDateTime(obj_waiting_server_positions);
      if(TimeCurrent()-greater_date>=waiting_sec)
        {
         freeWatingServerResponse();
         return true;
        }
      return false;
     }
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime CNegotiation::getServerResponseStructGreaterDateTime(const struct_waiting_position_response &str[])const
  {
   datetime last_greater=0;
   for(int i=0; i<ArraySize(str); i++)
     {
      if(str[i].set_time>last_greater)
         last_greater=str[i].set_time;
     }
   return last_greater;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::addNewPaddingServerOrder(void)
  {
   if(is_mql_tester_mode)
      return true;
   struct_waiting_position_response result;
   obj_trade.Result(result.result);
   return addWaitingServerTradeResult(result);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_OPENORDER_RESULT CNegotiation::OrderOpen(ENUM_ORDER_TYPE order_type,const string symbol,double volume,double price=0.0,double sl=0.0,double tp=0.0,const string comment=NULL)
  {
   if(!verifyServerResponse())
     {
      return OPENORDER_RESULT_WAITING_BROKER_RESPONSE;
     }
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
   addNewPaddingServerOrder();
   return OPENORDER_RESULT_OK;
  };
bool CNegotiation::IsEADeal(ulong ticket,const string symbol)const{
  if(HistoryDealGetInteger(ticket,DEAL_MAGIC)!=obj_expert_magic)
         return false;
  if(symbol!=NULL)
     if(HistoryDealGetString(ticket,DEAL_SYMBOL)!=symbol)
         return false;
  return true;       
}  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_OPENORDER_RESULT CNegotiation::OrderDelete(ulong ticket)
  {
   if(!verifyServerResponse())
     {
      return OPENORDER_RESULT_WAITING_BROKER_RESPONSE;
     }
   if(obj_trade.OrderDelete(ticket))
     {
      addNewPaddingServerOrder();
      return OPENORDER_RESULT_OK;
     }
   return OPENORDER_RESULT_TRADEERROR;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::PositionModify(const ulong ticket,const double sl,const double tp)
  {
   if(obj_trade.PositionModify(ticket,sl,tp))
     {
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::PositionClose(const ulong ticket)
  {
   if(!verifyServerResponse())
     {
      return false;
     }
   if(obj_trade.PositionClose(ticket))
     {
      addNewPaddingServerOrder();
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::PositionClosePartial(const ulong ticket,const double volume,const ulong deviation=-1)
  {
   if(!verifyServerResponse())
     {
      return false;
     }
   if(obj_trade.PositionClosePartial(ticket,volume,deviation))
     {
      addNewPaddingServerOrder();
      return true;
     }
   return false;
  }

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
   if(AccountInfoDouble(ACCOUNT_MARGIN_FREE)>need_margin || need_margin<=0)
      return true;
   return false;
  }

//+------------------------------------------------------------------+
double CNegotiation::GetClosePositionsResult(datetime start_period,datetime end_period=0,const string symbol=NULL)
  {
   datetime use_end_period=end_period;
   if(use_end_period==0)
      use_end_period=TimeCurrent();
   if(!HistorySelect(start_period,use_end_period))
      return 0;
   double result=0;
   ulong ticket;
   int deals_total=HistoryDealsTotal();
   if(deals_total==obj_info.last_deals_total && obj_info.last_deals_start_time==start_period)
      return obj_info.last_close_positions_result;
   for(int i=0; i<deals_total; i++)
     {
      ticket=HistoryDealGetTicket(i);
      if(!IsEADeal(ticket,symbol))
        continue;
      result+=HistoryDealGetDouble(ticket,DEAL_PROFIT)+HistoryDealGetDouble(ticket,DEAL_SWAP)+HistoryDealGetDouble(ticket,DEAL_COMMISSION);
     }
   obj_info.last_deals_total=deals_total;
   obj_info.last_close_positions_result=result;
   obj_info.last_deals_start_time=start_period;
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
         OrderDelete(ticket);
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
      return PositionClose(ticket);
     }
   if(!PositionSelectByTicket(ticket))
      return false;
   const double volume=PositionGetDouble(POSITION_VOLUME);
   const string symbol=PositionGetString(POSITION_SYMBOL);
   ENUM_OPENORDER_RESULT result;
   if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
     {
      result=OrderOpen(NEGOTIATION_ACTION_SELL,symbol,volume);
     }
   else
     {
      result=OrderOpen(NEGOTIATION_ACTION_BUY,symbol,volume);
     }
   if(result==OPENORDER_RESULT_OK)
      return true;
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
      printf("Position ts price %f",obj_positions_active[i].trailing_stop_start_stop);
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
   if(decrease_volume<=0)
      return;
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
      return PositionClosePartial(ticket,decrease_volume);
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

   PositionModify(position.ticket,position_entry_price,PositionGetDouble(POSITION_TP));

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNegotiation::VerifyBreakEven(double distance_price,const string symbol=NULL)
  {
   for(int i=0; i<ArraySize(obj_positions_active); i++)
     {
      if(!IsEAPosition(obj_positions_active[i].ticket,symbol))
         continue;
      double be_price=PositionGetDouble(POSITION_PRICE_OPEN);
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         be_price+=distance_price;
        }
      else
        {
         be_price-=distance_price;
        }
      VerifyPositionBreakEven(obj_positions_active[i],be_price);
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNegotiation::VerifyPositionTrailingStop(struct_position_info &position,double trigger_price,double trailing_move,double trailing_pass)
  {
   double new_sl=PositionGetDouble(POSITION_SL);
   if(new_sl<=0)
      return;
   if(trailing_move<=0)
      return;
   double market_price;
   if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
     {
      market_price=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_BID);
      if(market_price<trigger_price)
         return;
      int trailing_level=(int)((market_price-trigger_price)/trailing_move);
      if(position.trailing_stop_start_stop==0)
        {
         position.trailing_stop_start_stop=PositionGetDouble(POSITION_SL);
        }
      new_sl=position.trailing_stop_start_stop+trailing_pass*trailing_level;
      if(PositionGetDouble(POSITION_SL)>=new_sl)
         return;
     }
   else
     {
      market_price=SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_ASK);
      if(market_price>trigger_price)
         return;
      int trailing_level=(int)((trigger_price-market_price)/trailing_move);
      if(position.trailing_stop_start_stop==0)
        {
         position.trailing_stop_start_stop=PositionGetDouble(POSITION_SL);
        }
      new_sl=position.trailing_stop_start_stop-trailing_pass*trailing_level;
      if(PositionGetDouble(POSITION_SL)<=new_sl)
         return;
     }
   PositionModify(position.ticket,new_sl,PositionGetDouble(POSITION_TP));


  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNegotiation::VerifyTrailingStop(double trigger_distance,double move_distance,double pass_distance,const string symbol)
  {
   for(int i=0; i<ArraySize(obj_positions_active); i++)
     {
      if(!IsEAPosition(obj_positions_active[i].ticket,symbol))
         return;
      double trigger_price=PositionGetDouble(POSITION_PRICE_OPEN);
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         trigger_price+=trigger_distance;
        }
      else
        {
         trigger_price-=trigger_distance;
        }
      VerifyPositionTrailingStop(obj_positions_active[i],trigger_price,move_distance,pass_distance);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CNegotiation::GetVolumeOpenPositionsTotal(const string symbol=NULL)
  {
   ulong ticket;
   double volume_total=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ticket=PositionGetTicket(i);
      if(!IsEAPosition(ticket,symbol))
         continue;
      volume_total+=PositionGetDouble(POSITION_VOLUME);
     }
   return volume_total;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNegotiation::AveragePriceControl(ENUM_AVERAGEPRICE_DIRECTION direction,
                                       ENUM_NEGOTIATION_ACTION action,
                                       double price_base,
                                       double pass,
                                       double volume_entry,
                                       double volume_step,
                                       double volume_max,
                                       double takeprofit_price,
                                       const string symbol)
  {
   double volume_current=GetVolumeOpenPositionsTotal(symbol);
   if(pass<=0)
      return;
   int volume_opened_level=(int)((volume_current-volume_entry)/volume_step);
   if(volume_opened_level<0)
      return;
   double price_current=NSNegotiation::GetMarketPriceByAction(action,symbol);
   int price_level=(int)((price_current-price_base)/pass);
   int direction_normalize=1;
   if(direction==AVERAGEPRICE_DIRECTION_DOWN)
      direction_normalize=-1;
   price_level*=direction_normalize;
   if(volume_current+volume_step<volume_max)
      AveragePriceSetOrders(direction,action,price_base,pass,volume_step,price_level,volume_opened_level,direction_normalize,symbol);
   if(takeprofit_price>0)
      AveragePriceCloseProfitPositions(action,takeprofit_price,price_base,pass,volume_step,volume_opened_level,symbol);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNegotiation::AveragePriceSetOrders(ENUM_AVERAGEPRICE_DIRECTION direction,
      ENUM_NEGOTIATION_ACTION action,
      double price_base,
      double pass,
      double volume_step,
      int price_level,
      int volume_opened_level,
      int direction_normalize,
      const string symbol)
  {

   ENUM_ORDER_TYPE order_type;

   if(action==NEGOTIATION_ACTION_BUY)
     {
      if(direction==AVERAGEPRICE_DIRECTION_UP)
        {
         order_type=ORDER_TYPE_BUY_STOP;
        }
      else
        {
         order_type=ORDER_TYPE_BUY_LIMIT;
        }
     }
   else
     {
      if(direction==AVERAGEPRICE_DIRECTION_UP)
        {
         order_type=ORDER_TYPE_SELL_LIMIT;
        }
      else
        {
         order_type=ORDER_TYPE_SELL_STOP;
        }
     }
   double order_price=0;
   if(price_level>=volume_opened_level)
     {
      order_price=price_base+((price_level+1)*pass*direction_normalize);
      if(!ThereOrderAtPrice(order_price,order_type,pass/2,symbol))
         OrderOpen(order_type,symbol,volume_step,order_price);
     }
   if(order_price>0)
      AveragePriceCloseInvalidOrders(order_type,order_price,pass/2,symbol);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::ThereOrderAtPrice(double price,ENUM_ORDER_TYPE order_type,double tolerance,const string symbol=NULL)
  {
   ulong ticket;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      ticket=OrderGetTicket(i);
      if(!IsEAOrder(ticket,symbol))
         continue;
      if(OrderGetInteger(ORDER_TYPE)!=order_type)
         continue;
      if(OrderGetDouble(ORDER_PRICE_OPEN)>price-tolerance && OrderGetDouble(ORDER_PRICE_OPEN)<price+tolerance)
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNegotiation::AveragePriceCloseProfitPositions(ENUM_NEGOTIATION_ACTION action,
      double takeprofit_price,
      double price_base,
      double pass,
      double volume_step,
      int    volume_level,
      const string symbol)
  {
   double price_current=NSNegotiation::GetMarketPriceByAction(action,symbol);
   if(obj_account_margin_mode==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
     {
      AveragePriceCloseProfitPositionsHedging(price_base,pass/2,takeprofit_price,symbol);
     }
   else
     {
      AveragePriceCloseProfitPositionsNetting(action,volume_level,price_base,price_current,pass,takeprofit_price,volume_step,symbol);
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNegotiation::AveragePriceCloseProfitPositionsHedging(double entry_price,double tolerance,double takeprofit_price,const string symbol)
  {
   ulong ticket;
   double position_tp=0;

   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ticket=PositionGetTicket(i);
      if(!IsEAPosition(ticket,symbol))
         continue;
      position_tp=PositionGetDouble(POSITION_TP);
      if(position_tp>0)
         continue;
      double price_open=PositionGetDouble(POSITION_PRICE_OPEN);
      if(price_open<=entry_price+tolerance && price_open>=entry_price-tolerance)
         continue;
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         position_tp=price_open+takeprofit_price;
        }
      else
        {
         position_tp=price_open-takeprofit_price;
        }
      PositionModify(ticket,PositionGetDouble(POSITION_SL),position_tp);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNegotiation::AveragePriceCloseProfitPositionsNetting(ENUM_NEGOTIATION_ACTION action,
      int volume_level,
      double price_base,
      double price_current,
      double order_pass,
      double takeprofit_price,
      double volume_step,
      const string symbol)
  {
   if(volume_level<=0)
      return;
   int action_normalize=1;
   if(action==NEGOTIATION_ACTION_SELL)
      action_normalize=-1;
   double price_close;
   for(int i=volume_level; i>0; i--)
     {
      price_close=price_base-(order_pass*i*action_normalize)+(takeprofit_price*action_normalize);
      if(action==NEGOTIATION_ACTION_BUY)
        {
         if(price_current<price_close)
           {
            if(!ThereOrderAtPrice(price_close,ORDER_TYPE_SELL_LIMIT,order_pass/2,symbol))
              {
               OrderOpen(ORDER_TYPE_SELL_LIMIT,symbol,volume_step,price_close);
              }
            continue;
           }
         if(price_close+order_pass/2>price_current)
            continue;
        }
      else
        {
         if(price_current>price_close)
           {
            if(!ThereOrderAtPrice(price_close,ORDER_TYPE_BUY_LIMIT,order_pass/2,symbol))
              {
               OrderOpen(ORDER_TYPE_BUY_LIMIT,symbol,volume_step,price_close);
              }
            continue;
           }
         if(price_close-order_pass/2<price_current)
            continue;
        }
      OrderOpen(NSNegotiation::ActionOpposed(action),symbol,volume_step);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNegotiation::AveragePriceCloseInvalidOrders(ENUM_ORDER_TYPE order_type,double order_price,double tolerance,const string symbol)
  {
   ulong ticket;
   double order_current_price;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      ticket=OrderGetTicket(i);
      if(!IsEAOrder(ticket,symbol))
         continue;
      if(OrderGetInteger(ORDER_TYPE)!=order_type)
         continue;
      order_current_price=OrderGetDouble(ORDER_PRICE_OPEN);
      if(order_current_price<order_price+tolerance && order_current_price>order_price-tolerance)
         continue;
      OrderDelete(ticket);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::addWaitingServerTradeResult(struct_waiting_position_response &result)
  {
   ArrayResize(obj_waiting_server_positions,ArraySize(obj_waiting_server_positions)+1);
   int index=ArraySize(obj_waiting_server_positions)-1;
   obj_waiting_server_positions[index].set_time=TimeCurrent();
   copyMqlTradeResult(obj_waiting_server_positions[index].result,result.result);
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::copyMqlTradeResult(MqlTradeResult &dst,const MqlTradeResult &src)
  {
   dst.deal=src.deal;
   dst.retcode=src.retcode;
   dst.order=src.order;
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::copyWatingServerResponseStruct(struct_waiting_position_response &dst,const struct_waiting_position_response &src)
  {
   dst.set_time=src.set_time;
   copyMqlTradeResult(dst.result,src.result);
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::copyWatingServerResponseStructArray(struct_waiting_position_response &dst[],const struct_waiting_position_response &src[])
  {
   int size=ArraySize(src);
   if(size<=0)
      return false;
   ArrayResize(dst,size);
   for(int i=0; i<size; i++)
     {
      copyWatingServerResponseStruct(dst[i],src[i]);
     }
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::removeWatingServerResponseByDeal(ulong deal)
  {
   MqlTradeResult result;
   for(int i=0; i<ArraySize(obj_waiting_server_positions); i++)
     {
      result=obj_waiting_server_positions[i].result;
      if(result.deal==deal)
         return removeWatingServerResponseByIndex(i);
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::removeWatingServerResponseByOrder(ulong order)
  {
   MqlTradeResult result;
   for(int i=0; i<ArraySize(obj_waiting_server_positions); i++)
     {
      result=obj_waiting_server_positions[i].result;
      if(result.order==order)
         return removeWatingServerResponseByIndex(i);
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::removeWatingServerResponseByIndex(int index)
  {
   int new_size=ArraySize(obj_waiting_server_positions)-1;
   if(new_size<=0)
     {
      return freeWatingServerResponse();
     }
   struct_waiting_position_response old[];
   copyWatingServerResponseStructArray(old,obj_waiting_server_positions);
   ArrayResize(obj_waiting_server_positions,new_size);
   int current_index=0;
   for(int i=0; i<new_size+1; i++)
     {
      if(i==index)
         continue;
      copyWatingServerResponseStruct(obj_waiting_server_positions[current_index],old[i]);
     }
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNegotiation::freeWatingServerResponse()
  {
   ArrayFree(obj_waiting_server_positions);
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNegotiation::ontradetransaction(const MqlTradeTransaction&trans,const MqlTradeRequest&request,const MqlTradeResult&result)
  {
   if(result.retcode==0)
      return;
   MqlTradeResult local_result;
   for(int i=0; i<ArraySize(obj_waiting_server_positions); i++)
     {
      local_result=obj_waiting_server_positions[i].result;
      if(local_result.deal==result.deal && local_result.deal!=0)
        {
         removeWatingServerResponseByDeal(local_result.deal);
         break;
        }
      if(local_result.order==result.order && local_result.order!=0)
        {
         removeWatingServerResponseByOrder(local_result.order);
         break;
        }
     }

  }
#endif
//+------------------------------------------------------------------+
