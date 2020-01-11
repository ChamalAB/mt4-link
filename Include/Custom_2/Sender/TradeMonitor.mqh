//+------------------------------------------------------------------+
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne"
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict


#include <Custom_2\\Porcupine.mqh>
#include <Custom_2\\Logger.mqh>
#include <Custom_2\\Trade.mqh>
#include <Custom_2\\Queues\\Queues.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class TradeMonitor
  {
private:
   Porcupine         disk;
   Logger            logger;
   StringQueue       queue;
   Trade             trade;

   void              checkClosedTrades(void);
public:
                     TradeMonitor(void);
                    ~TradeMonitor(void);
   void              checkUpdates(void);
   bool              popInstruction(string &instruction);


  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
TradeMonitor::TradeMonitor(void)
  {
   logger.setName("TradeMonitor");
   logger.setLevel(LEVEL_DEBUG);
   logger.setLog(false);
   logger.setPrint(true);

   disk.setPath("Files\\TradeMonitor\\");
   if(!disk.filesLoad())
      logger.error("Porcupine","Disk Files load failed");

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
TradeMonitor::~TradeMonitor(void)
  {
   if(!disk.filesDump())
      logger.error("Porcupine","File Dump failed");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeMonitor::checkUpdates(void)
  {
   int num = OrdersTotal();
   int ticket;
   double stoploss,takeprofit;

   for(int i=0; i<num; i++)
     {
      if(OrderSelect(i,SELECT_BY_POS))
        {
         ticket = OrderTicket();

         if(disk.checkKey(TYPE_INT,StringFormat("ORDER_%d",ticket)))
           {
            // check for changes in trades
            if(!disk.getData(StringFormat("SL_%d",ticket),stoploss))
              {
               logger.error(__FUNCTION__,StringFormat("data retrieval failed: SL_%d",ticket));
               continue;
              }

            if(!disk.getData(StringFormat("TP_%d",ticket),takeprofit))
              {
               logger.error(__FUNCTION__,StringFormat("data retrieval failed: TP_%d",ticket));
               continue;
              }

            if(stoploss!=OrderStopLoss())
              {
               disk.setData(StringFormat("SL_%d",ticket),OrderStopLoss());
               queue.push(StringFormat("%d MODIFY SL %.5f",ticket,OrderStopLoss()));
              }

            if(takeprofit!=OrderTakeProfit())
              {
               disk.setData(StringFormat("TP_%d",ticket),OrderTakeProfit());
               queue.push(StringFormat("%d MODIFY TP %.5f",ticket,OrderTakeProfit()));
              }

           }
         else
           {
            logger.debug(__FUNCTION__,StringFormat("new order %d",ticket));
            // new trade save it
            disk.setData(StringFormat("ORDER_%d",ticket),ticket);
            disk.setData(StringFormat("SL_%d",ticket),OrderStopLoss());
            disk.setData(StringFormat("TP_%d",ticket),OrderTakeProfit());


            // 32 OPEN     BUY/SELL    PENDING/MARKET SYMBOL PRICE [EXPIRY IF PENDING] MAGICNUM COMMENT
            // 32 MODIFY   SL          PRICE
            // 32 MODIFY   TP          PRICE
            string instruction = StringFormat("%d OPEN",ticket);
            switch(OrderType())
              {
               case OP_BUY:
                  instruction+=" BUY MARKET" ;
                  break;
               case OP_SELL:
                  instruction+=" SELL MARKET" ;
                  break;
               case OP_BUYLIMIT:
                  instruction+=" BUY PENDING";
                  break;
               case OP_BUYSTOP:
                  instruction+=" BUY PENDING" ;
                  break;
               case OP_SELLLIMIT:
                  instruction+=" SELL PENDING" ;
                  break;
               case OP_SELLSTOP:
                  instruction+=" SELL PENDING" ;
                  break;
               default:
                  logger.error(__FUNCTION__,"Unknown order type");
                  break;
              }

            instruction+= StringFormat(" %s %.5f",OrderSymbol(),OrderOpenPrice());

            queue.push(instruction);
            
            // only send instruction if SL or TP is modified.
            if(OrderStopLoss()!=0.00)
               queue.push(StringFormat("%d MODIFY SL %.5f",ticket,OrderStopLoss()));
               
            if(OrderTakeProfit()!=0.00)
               queue.push(StringFormat("%d MODIFY TP %.5f",ticket,OrderTakeProfit()));
           }
        }
      else
        {
         logger.error(__FUNCTION__,StringFormat("order %d select failed",ticket));
        }
     }
   checkClosedTrades();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TradeMonitor::popInstruction(string &instruction)
  {
   return queue.pop(instruction);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeMonitor::checkClosedTrades(void)
  {
   string results[];
   int ticket;
   disk.searchData("ORDER_",results,TYPE_INT);


   for(int i=0; i<ArraySize(results); i++)
     {
      if(!disk.getData(results[i],ticket))
        {
         logger.error(__FUNCTION__,StringFormat("data retrieval failed: %s",results[i]));
         continue;
        }

      if(!trade.isOrderOpen(ticket))
        {
         // trade is closed delete disk data
         disk.deleteKey(TYPE_INT,results[i]);
         disk.deleteKey(TYPE_DOUBLE,StringFormat("SL_%d",ticket));
         disk.deleteKey(TYPE_DOUBLE,StringFormat("TP_%d",ticket));

         // queue message
         // 32 CLOSE
         queue.push(StringFormat("%d CLOSE",ticket));

        }
     }
  }