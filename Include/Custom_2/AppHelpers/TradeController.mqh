//+------------------------------------------------------------------+
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne"
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict

#include <Custom_2\\Trade.mqh>
#include <Custom_2\\Porcupine.mqh>
#include <Custom_2\\Logger.mqh>
#include <Custom_2\\Misc\\StringHelpers.mqh>
#include <Custom_2\\AppHelpers\\CacheCommands.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class TradeController
  {
private:
   double            lots;
   Trade             trade;
   Porcupine         disk;
   Logger            logger;
   CacheCommands     cache;

   void              openCommand(string id,string command);
   void              modifyCommand(string id,string command);
   void              closeCommand(string id);


public:
                     TradeController(void);
                    ~TradeController(void);
   void              setLots(double value);
   void              parseCommand(string command);
   void              runCachedCommands(void);

  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
TradeController::TradeController(void)
  {
   logger.setName("TradeController");
   logger.setLevel(LEVEL_DEBUG);
   logger.setLog(false);
   logger.setPrint(true);
   logger.setPath("Files\\Logs\\log.log");

   disk.setPath("Files\\tradecontroller\\disk\\");

   if(!disk.filesLoad())
      logger.error("Porcupine","Disk Files load failed");

   lots = 0.01;

   cache.setInterval(15);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
TradeController::~TradeController(void)
  {
   disk.filesDump();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeController::setLots(double value)
  {
   lots = value;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeController::parseCommand(string command)
  {
   string instruction = command;
   logger.debug(__FUNCTION__,StringFormat("Recevied %s",instruction));

// check market status
   if(!trade.marketOpen())
     {
      logger.debug(__FUNCTION__,"Market is closed. caching instruction");
      cache.cacheCommand(instruction,1,disk,true);
      return;
     }

// check trade context
   if(!trade.trade_context())
     {
      logger.debug(__FUNCTION__,"Trading context not ready. caching instruction");
      cache.cacheCommand(instruction,1,disk,true);
      return;
     }


// 32 OPEN     BUY/SELL    PENDING/MARKET    SYMBOL      PRICE    MAGICNUMBER    COMMENT
// 32 MODIFY   SL          PRICE
// 32 MODIFY   TP          PRICE
// 32 CLOSE

// GET identifier
   string id;

   if(!get_split_by_index(instruction," ",0,id))
     {
      logger.error(__FUNCTION__,StringFormat("Error parsing command: %s",instruction));
      return;
     }
// truncate id
   checkCommand(id,instruction);


   if(checkCommand("OPEN",instruction))
     {
      openCommand(id,instruction);
     }
   else
      if(checkCommand("MODIFY",instruction))
        {
         modifyCommand(id,instruction);
        }
      else
         if(checkCommand("CLOSE",instruction))
           {
            closeCommand(id);
           }
         else
           {
            logger.debug(__FUNCTION__,StringFormat("Unknown operation %s",instruction));
           }
   disk.filesDump(false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeController::openCommand(string id,string command)
  {
   string instruction = command;
   logger.debug(__FUNCTION__,StringFormat("Executing %s",instruction));

   if(disk.checkKey(TYPE_INT,"open_"+id))
     {
      logger.error(__FUNCTION__,StringFormat("Trade identifier already in use: %s",id));
      return;
     }

   string operation,execution,symbol,price,magicNum,comment,expiration;
   bool status;

   status = get_split_by_index(instruction," ",0,operation);
   status = status & get_split_by_index(instruction," ",1,execution);
   status = status & get_split_by_index(instruction," ",2,symbol);
   status = status & get_split_by_index(instruction," ",3,price);
   if(execution=="PENDING")
     {
      status = status & get_split_by_index(instruction," ",4,expiration);
      status = status & get_split_by_index(instruction," ",5,magicNum);
      status = status & get_split_by_index(instruction," ",6,comment);
     }
   else
     {
      status = status & get_split_by_index(instruction," ",4,magicNum);
      status = status & get_split_by_index(instruction," ",5,comment);
     }

   if(!status)
     {
      logger.error(__FUNCTION__,StringFormat("Error parsing command: %s",instruction));
      return;
     }

   int ticket;
   if(execution=="MARKET")
     {
      if(operation=="BUY")
        {
         ticket = trade.openOrderMarket(symbol,OP_BUY,lots,comment,StrToInteger(magicNum));
        }
      else
         if(operation=="SELL")
           {
            ticket = trade.openOrderMarket(symbol,OP_SELL,lots,comment,StrToInteger(magicNum));
           }
         else
           {
            logger.error(__FUNCTION__,StringFormat("Unknown operation: %s",operation));
            return;
           }
     }
   else
      if(execution=="PENDING")
        {
         if(operation=="BUY")
           {
            ticket = trade.openOrderPending(symbol,OP_BUY,lots,StrToDouble(price),comment,StrToInteger(magicNum),StrToInteger(expiration));
           }
         else
            if(operation=="SELL")
              {
               ticket = trade.openOrderPending(symbol,OP_SELL,lots,StrToDouble(price),comment,StrToInteger(magicNum),StrToInteger(expiration));
              }
            else
              {
               logger.error(__FUNCTION__,StringFormat("Unknown operation: %s",operation));
               return;
              }
        }
      else
        {
         logger.error(__FUNCTION__,StringFormat("Unknown Execution mode: %s",execution));
         return;
        }

   if(ticket==-1)
     {
      logger.error(__FUNCTION__,"Order Not opened");
      return;
     }
   else
     {
      disk.setData("open_"+id,ticket);
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeController::modifyCommand(string id,string command)
  {
   string instruction = command;
   string value;

   if(!get_split_by_index(instruction," ",1,value))
     {
      logger.error(__FUNCTION__,StringFormat("Error parsing command: %s",instruction));
      return;
     }

   if(disk.checkKey(TYPE_INT,"open_"+id))
     {
      int ticket;
      disk.getData("open_"+id,ticket);

      if(!trade.isOrderOpen(ticket))
        {
         // order is closed already
         logger.debug(__FUNCTION__,StringFormat("Already closed order: %d",ticket));
         logger.debug(__FUNCTION__,"Deleting entry");
         disk.deleteKey(TYPE_INT,"open_"+id);
         return;
        }

      if(checkCommand("SL",instruction))
        {
         if(!trade.modifyStopLoss(ticket,StringToDouble(value)))
           {
            logger.error(__FUNCTION__,StringFormat("Error modifying order: %d",ticket));
            logger.debug(__FUNCTION__,"Caching instruction");
            cache.cacheCommand(StringFormat("%s MODIFY %s",id,command),3,disk);
            return;
           }
        }
      else
         if(checkCommand("TP",instruction))
           {
            if(!trade.modifyTakeProfit(ticket,StringToDouble(value)))
              {
               logger.error(__FUNCTION__,StringFormat("Error modifying order: %d",ticket));
               logger.debug(__FUNCTION__,"Caching instruction");
               cache.cacheCommand(StringFormat("%s MODIFY %s",id,command),3,disk);
               return;
              }
           }
     }
   else
     {
      logger.debug(__FUNCTION__,StringFormat("Trade identifier not recognized or already closed: %s",id));
      return;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeController::closeCommand(string id)
  {
   if(disk.checkKey(TYPE_INT,"open_"+id))
     {
      int ticket;
      disk.getData("open_"+id,ticket);

      if(!trade.isOrderOpen(ticket))
        {
         // order is closed already
         logger.debug(__FUNCTION__,StringFormat("Already closed order: %d",ticket));
         logger.debug(__FUNCTION__,"Deleting entry");
         disk.deleteKey(TYPE_INT,"open_"+id);
         return;
        }

      if(trade.orderClose(ticket))
        {
         logger.debug(__FUNCTION__,"Deleting entry");
         disk.deleteKey(TYPE_INT,"open_"+id);
         return;
        }
      else
        {
         logger.error(__FUNCTION__,StringFormat("Error closing order: %d",ticket));
         logger.debug(__FUNCTION__,"Caching instruction");
         cache.cacheCommand(StringFormat("%s CLOSE",id),3,disk);
         return;
        }
     }
   else
     {
      logger.debug(__FUNCTION__,StringFormat("Trade identifier not recognized: %s",id));
      return;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeController::runCachedCommands(void)
  {
   string commands[];
   int count = cache.getCachedCommands(disk,commands);

   for(int i=0; i<count; i++)
     {
      logger.debug(__FUNCTION__,StringFormat("Got cached command: %s",commands[i]));
      parseCommand(commands[i]);
     }
  }
//+------------------------------------------------------------------+
