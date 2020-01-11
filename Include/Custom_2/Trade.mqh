//+------------------------------------------------------------------+
//|                                                        Trade.mq4 |
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne."
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict

#include <Custom_2\\Logger.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Trade
  {
private:
   Logger            logger;
   int               slippage;

   // check price is within slippage/2 range
   bool              check_deviation(string symbol,string order_type,double open_price);

public:
                     Trade();
   int               tradeCount(int magic_number); // Get open trade count by magic number
   bool              checkTradeAccess(string symbol_); // Check full access is given to a symbol
   double            getLatestPrice(string symbol_,string price_mode); // Get the latest price for BUY/SELL
   int               openOrderAuto(string symbol_,int operation,double lotsize,double price,string comment,int magic,int exp_minutes); // Automatically open orders whther market or pending
   int               openOrderMarket(string symbol_,int operation,double lotsize,string comment,int magic); // Open Market order
   int               openOrderPending(string symbol_,int operation,double lotsize,
                                       double price,string comment,int magic,int exp_minutes); // Open Pending order automatic STOP/LIMIT selection
   bool              modifyStopLoss(int ticket,double stoploss); // Modify stop loss
   bool              modifyTakeProfit(int ticket,double takeprofit); // Modify Take profit
   bool              orderClose(int ticket); // close any order
   bool              isOrderOpen(int ticket);
   bool              isOrderExist(int ticket);
   bool              trade_context(void);
   bool              marketOpen(string symbol="CURRENT_CHART");
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Trade::Trade(void)
  {
   slippage = 1;

   logger.setName("Trade");
   logger.setLevel(LEVEL_DEBUG);
   logger.setLog(false);
   logger.setPrint(true);
   logger.setPath("Files\\Logs\\log.log");
  }
//+------------------------------------------------------------------+
//| Count trades by magic number                                     |
//+------------------------------------------------------------------+
int Trade::tradeCount(int magic_number)
  {
   int count = 0;

   for(int x = OrdersTotal() - 1; x >= 0; x--)
     {
      if(OrderSelect(x, SELECT_BY_POS, MODE_TRADES))
        {
         if(OrderMagicNumber()==magic_number && OrderCloseTime()==0)
           {
            count++;
           }
        }
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Check full trade access                                          |
//+------------------------------------------------------------------+
bool Trade::checkTradeAccess(string symbol_)
  {
   long result = SymbolInfoInteger(symbol_,SYMBOL_TRADE_MODE);

   if(result==SYMBOL_TRADE_MODE_DISABLED)
     {
      logger.debug(__FUNCTION__," SYMBOL_TRADE_MODE_DISABLED");
     }
   if(result==SYMBOL_TRADE_MODE_LONGONLY)
     {
      logger.debug(__FUNCTION__," SYMBOL_TRADE_MODE_LONGONLY");
     }
   if(result==SYMBOL_TRADE_MODE_SHORTONLY)
     {
      logger.debug(__FUNCTION__," SYMBOL_TRADE_MODE_SHORTONLY");
     }
   if(result==SYMBOL_TRADE_MODE_CLOSEONLY)
     {
      logger.debug(__FUNCTION__," SYMBOL_TRADE_MODE_CLOSEONLY");
     }
   if(result==SYMBOL_TRADE_MODE_FULL)
     {
      logger.debug(__FUNCTION__," SYMBOL_TRADE_MODE_FULL");
      return true;
     }
   logger.debug(__FUNCTION__,StringFormat("Symbol %s does not have full access to trade",symbol_));
   return false;
  }

//+------------------------------------------------------------------+
//| Get latest price            MODE_BID-SELL / MODE_ASK-BUY         |
//+------------------------------------------------------------------+
double Trade::getLatestPrice(string symbol_,string price_mode)
  {
   if(price_mode=="BUY")
      return MarketInfo(symbol_,MODE_ASK);
   else
      if(price_mode=="SELL")
         return MarketInfo(symbol_,MODE_BID);
      else
        {
         logger.error(__FUNCTION__,StringFormat("Unsupported operation: %s",price_mode));
         return 0.0;
        }
  }



//+------------------------------------------------------------------+
//| Open Market Order                                                |
//+------------------------------------------------------------------+
int Trade::openOrderMarket(string symbol_,int operation,double lotsize,string comment,int magic)
  {
   int result;
   if(operation==OP_BUY)
     {
      result = OrderSend(symbol_,operation,lotsize,MarketInfo(symbol_,MODE_ASK),slippage,0,0,comment,magic);
     }
   else
      if(operation==OP_SELL)
        {
         result = OrderSend(symbol_,operation,lotsize,MarketInfo(symbol_,MODE_BID),slippage,0,0,comment,magic);
        }
      else
        {
         logger.error(__FUNCTION__,StringFormat("Unsupported operation: %d",operation));
         result = -1;
        }
   if(result==-1)
      logger.error(__FUNCTION__,StringFormat("%s %d %.2f",symbol_,operation,lotsize));

   return result;
  }

//+------------------------------------------------------------------+
//| Open Pending order Automatic Limit/Stop                          |
//+------------------------------------------------------------------+
int Trade::openOrderPending(string symbol_,int operation,double lotsize,double price,string comment,int magic,int exp_minutes)
  {
   int order_type;
   if(operation==OP_BUY)
     {
      if(price>getLatestPrice(symbol_,"BUY"))
         order_type=OP_BUYSTOP;
      else
         order_type=OP_BUYLIMIT;
     }
   else
      if(operation==OP_SELL)
        {
         if(price>getLatestPrice(symbol_,"SELL"))
            order_type=OP_SELLLIMIT;
         else
            order_type=OP_SELLSTOP;
        }
      else
        {
         logger.error(__FUNCTION__,StringFormat("Unsupported operation: %d",operation));
         return -1;
        }
        
   // calculate expiration
   int expiration = (int) MathMax(660,exp_minutes*60);

   int ticket = OrderSend(symbol_,order_type,lotsize,price,slippage,0,0,comment,magic,TimeCurrent()+expiration);
   if(ticket==-1)
      logger.error(__FUNCTION__,StringFormat("%s %d %.2f @ %.5f",symbol_,operation,lotsize,price));

   return ticket;
  }


//+------------------------------------------------------------------+
//| Open trade - Auto pending or Market                              |
//+------------------------------------------------------------------+
int Trade::openOrderAuto(string symbol_,int operation,double volume,double price,string comment,int magic,int exp_minutes)
  {
   string op;
   int ticket;
   if(operation==OP_BUY)
      op="BUY";
   else
      if(operation==OP_SELL)
         op="SELL";

   if(check_deviation(symbol_,op,price))
     {
      // price within reasonable range/ open market order
      ticket = openOrderMarket(symbol_,operation,volume,comment,magic);
     }
   else
     {
      // place pending order
      ticket = openOrderPending(symbol_,operation,volume,price,comment,magic,exp_minutes);
     }
   return ticket;
  }

//+------------------------------------------------------------------+
//| Modify SL                                                        |
//+------------------------------------------------------------------+
bool Trade::modifyStopLoss(int ticket,double stoploss)
  {
// gather details of the trade
   if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
     {
      double open = OrderOpenPrice();
      double takeprofit = OrderTakeProfit();
      if(OrderModify(ticket,open,stoploss,takeprofit,0))
        {
         return true;
        }
      else
        {
         logger.error(__FUNCTION__,StringFormat("Order SL Modify Fail %d at %.5f",ticket,stoploss));
         return false;
        }
     }
   else
     {
      logger.error(__FUNCTION__,StringFormat("Order Select Fail %d",ticket));
      return false;
     }
  }

//+------------------------------------------------------------------+
//| Modify TP                                                        |
//+------------------------------------------------------------------+
bool Trade::modifyTakeProfit(int ticket,double takeprofit)
  {
// gather details of the trade
   if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
     {
      double open = OrderOpenPrice();
      double stoploss = OrderStopLoss();
      if(OrderModify(ticket,open,stoploss,takeprofit,0))
        {
         return true;
        }
      else
        {
         logger.error(__FUNCTION__,StringFormat("Order TP Modify Fail %d at %.5f",ticket,takeprofit));
         return false;
        }
     }
   else
     {
      logger.error(__FUNCTION__,StringFormat("Order Select Fail %d",ticket));
      return false;
     }
  }

//+------------------------------------------------------------------+
//| Check price is in reasonable range(+-spread/2)                   |
//+------------------------------------------------------------------+
bool Trade::check_deviation(string symbol,string order_type,double open_price)
  {
//--enable symbol in market watch
   SymbolSelect(symbol,true);
   ResetLastError();
   MqlTick last_tick;
   double last_price=0;
   int digits = (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);

   if(SymbolInfoTick(symbol,last_tick))
     {
      if(order_type=="BUY")
        {
         last_price = last_tick.ask;
        }
      else
         if(order_type=="SELL")
           {
            last_price = last_tick.bid;
           }
      //-- Calculate pip value based on digits
      double max_dev_points = 0.0;
      int spread_halved = MathMax((int)SymbolInfoInteger(symbol,SYMBOL_SPREAD),1)/2; // math max is used to avoid zero divide error
      double point = SymbolInfoDouble(symbol,SYMBOL_POINT);

      if(digits==2 || digits==4)
        {
         spread_halved = MathMax(spread_halved,1); // min halved spread should be 1 point in 4/2 digits
         max_dev_points = spread_halved*point;
        }
      else
         if(digits==3 || digits==5)
           {
            spread_halved = MathMax(spread_halved,2); // min halved spread should be 2 points in 5/3 digits
            max_dev_points = spread_halved*point;
           }

      //-- now check whther price is out of band
      double diff_in_price = MathAbs(last_price-open_price);

      if(max_dev_points>=diff_in_price)
        {
         return true;
        }
      else
        {
         return false;
        }
     }
   else
     {
      logger.error(__FUNCTION__,StringFormat("Symbol %s not available",symbol));
      return false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Trade::orderClose(int ticket)
  {
   if(OrderSelect(ticket,SELECT_BY_TICKET))
     {
      int o_type = OrderType();
      if(o_type==OP_BUY || o_type==OP_SELL)
        {
         string o_type_str = "";
         // for opened orders
         if(o_type==OP_BUY)
            o_type_str="BUY";
         else
            o_type_str="SELL";


         if(OrderClose(OrderTicket(),OrderLots(),getLatestPrice(OrderSymbol(),o_type_str),slippage))
           {
            return true;
           }
         else
           {
            logger.error(__FUNCTION__,StringFormat("Order Close error %d",OrderTicket()));
            return false;
           }
        }
      else
        {
         // pending orders
         if(OrderDelete(OrderTicket()))
           {
            return true;
           }
         else
           {
            logger.error(__FUNCTION__,StringFormat("Pending Order Close error %d",OrderTicket()));
            return false;
           }

        }
     }
   else
     {
      logger.error(__FUNCTION__,StringFormat("Order Select Fail %d",OrderTicket()));
      return false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Trade::isOrderOpen(int ticket)
  {
   if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
     {
      if(OrderCloseTime()!=0)
         return false;
      else
         return true;
     }
   else
     {
      return false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Trade::isOrderExist(int ticket)
  {
   return OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Trade::trade_context(void)
  {
   if(!IsTradeAllowed())
      return false;

   if(!IsConnected())
      return false;

   for(int i=0; i<3; i++)
     {
      if(!IsTradeContextBusy())
         return true;
      Sleep(200);
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Trade::marketOpen(string symbol="CURRENT_CHART")
  {
   string temp;

   if(symbol=="CURRENT_CHART")
      temp = Symbol();
   else
      temp = symbol;

   if(MarketInfo(temp,MODE_TRADEALLOWED)==1)
      return true;
   else
      return false;
  }
//+------------------------------------------------------------------+
