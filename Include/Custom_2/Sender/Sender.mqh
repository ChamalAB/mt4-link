//+------------------------------------------------------------------+
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne"
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict

#include <Custom_2\\mt4link\\mt4link_v2.mqh>
#include <Custom_2\\Sender\\TradeMonitor.mqh>
#include <Custom_2\\AppHelpers\\CacheCommands.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Sender
  {
private:
   Porcupine         disk;
   Logger            logger;
   CacheCommands     cache;
   TradeMonitor      monitor;
   mt4link           *mtlink;
   string            strategy,prefixes;
   int               exp_market,exp_pending,magic_number;

   void              runCachedUpdates(void);
   string            commandProces(string in_command);

public:
                     Sender(void);
                    ~Sender(void);
   void              setMt4Account(string Mt4Account);
   void              setPassword(string Password);
   void              setService(string Service);
   void              setServerUrl(string ServerUrl);
   void              setStrategy(string Strategy);
   void              setCommandPrefix(string Prefixes);
   void              setExpMarket(int minutes);
   void              setExpPending(int minutes);
   void              checkAndSendUpdates(void);

  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Sender::Sender(void)
  {
   mtlink = new mt4link();

   strategy = "DEFAULT";
   prefixes = "CMD ALL";

   cache.setInterval(15);

   exp_market = 1;
   exp_pending = 15;
   magic_number = 801;

   logger.setName("Sender");
   logger.setLevel(LEVEL_DEBUG);
   logger.setLog(false);
   logger.setPrint(true);

   disk.setPath("Files\\Sender\\");
   if(!disk.filesLoad())
      logger.error("Porcupine","Disk Files load failed");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Sender::~Sender(void)
  {
   if(!disk.filesDump())
      logger.error("Porcupine","File Dump failed");

   delete(mtlink);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Sender::setMt4Account(string Mt4Account)
  {
   mtlink.setMt4Account(Mt4Account);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Sender::setPassword(string Password)
  {
   mtlink.setPassword(Password);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Sender::setService(string Service)
  {
   mtlink.setService(Service);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Sender::setServerUrl(string ServerUrl)
  {
   mtlink.setServerUrl(ServerUrl);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Sender::setStrategy(string Strategy)
  {
   strategy = Strategy;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Sender::setCommandPrefix(string Prefixes)
  {
   prefixes = Prefixes;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Sender::setExpMarket(int minutes)
  {
   exp_market = minutes;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Sender::setExpPending(int minutes)
  {
   exp_pending = minutes;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Sender::commandProces(string in_command)
  {
   string operation,order_type;

   if(!get_split_by_index(in_command," ",1,operation))
     {
      logger.error(__FUNCTION__,StringFormat("Error in splitting %s",in_command));
      return "ERROR";
     }

   if(operation=="OPEN")
     {
      if(!get_split_by_index(in_command," ",3,order_type))
        {
         logger.error(__FUNCTION__,StringFormat("Error in splitting %s",in_command));
         return "ERROR";
        }

      // calculate expiration
      int expiration;
      int gmt_now = (int) TimeGMT();

      if(order_type=="MARKET")
        {
         expiration = gmt_now + (exp_market*60);
         return StringFormat("%s EXPIRE %d STRATEGY %s %s %d %s",prefixes,expiration,strategy,in_command,magic_number,strategy);
        }
      else
         if(order_type=="PENDING")
           {
            expiration = gmt_now + (exp_pending*60);
            return StringFormat("%s EXPIRE %d STRATEGY %s %s %d %d %s",prefixes,expiration,strategy,in_command,exp_pending,magic_number,strategy);
           }
         else
           {
            logger.error(__FUNCTION__,StringFormat("Error in order type %s",order_type));
            return "ERROR";
           }
      
     }
   return StringFormat("%s STRATEGY %s %s",prefixes,strategy,in_command);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Sender::checkAndSendUpdates(void)
  {
   monitor.checkUpdates();

   string instruction,out_instruction;

   while(true)
     {
      if(monitor.popInstruction(instruction))
        {
         // compose final instruction
         out_instruction = commandProces(instruction);
         logger.debug(__FUNCTION__,StringFormat("Sending Command %s",out_instruction));

         if(!mtlink.instructionWrite(out_instruction))
           {
            logger.error(__FUNCTION__,"Command send failed. Caching");
            cache.cacheCommand(out_instruction,1,disk,true);
           }
        }
      else
         break;
     }

   runCachedUpdates();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Sender::runCachedUpdates(void)
  {
   string commands[];
   int count = cache.getCachedCommands(disk,commands);

   for(int i=0; i<count; i++)
     {
      logger.debug(__FUNCTION__,StringFormat("Got cached command: %s",commands[i]));
      if(!mtlink.instructionWrite(commands[i]))
        {
         logger.error(__FUNCTION__,"Command send failed. Caching");
         cache.cacheCommand(commands[i],1,disk,true);
        }
     }
  }
