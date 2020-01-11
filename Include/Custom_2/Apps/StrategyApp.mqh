//+------------------------------------------------------------------+
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne"
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict


#include <Custom_2\\Apps\\MasterApp.mqh>
#include <Custom_2\\Apps\\CommandApp.mqh>
#include <Custom_2\\Misc\\StringHelpers.mqh>
#include <Custom_2\\AppHelpers\\TradeController.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class StrategyApp : public MasterApp
  {
private:
   string            myCommand;
   Logger            logger;
   TradeController   trc;
   string            strategies[];
   double            equityLimit;

   double            getAccountEquityPercentage(void);

public:
                     StrategyApp(void);
   string            getMyCommand(void);
   void              parseCommand(string command);

   bool              checkStrategy(string name);
   void              addStrategy(string strategy);
   void              setTradeLots(double value);
   void              setAccountEquityLimit(double limit);
   void              removeStrategy(string strategy);
   void              showAll(void);
   void              runCachedCommands(void);

  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
StrategyApp::StrategyApp(void)
  {
   myCommand = "STRATEGY";
   equityLimit = 50.00;
   trc.setLots(0.01);

   logger.setName(myCommand);
   logger.setLevel(LEVEL_DEBUG);
   logger.setLog(false);
   logger.setPrint(true);
   logger.setPath("Files\\Logs\\log.log");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string StrategyApp::getMyCommand(void)
  {
   return myCommand;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void StrategyApp::parseCommand(string command)
  {

   logger.debug(__FUNCTION__,StringFormat("Command Recieved: %s",command));
   string instruction = command;

// Index           0         1     2   ....
// STRATEGY [strategy name] 32   OPEN  ....

   string strategy_name,operation;
   bool status;

   status = get_split_by_index(instruction," ",0,strategy_name);
   status = status & get_split_by_index(instruction," ",2,operation);

   if(!status)
     {
      logger.error(__FUNCTION__,StringFormat("Error parsing command: %s",instruction));
      return;
     }

// truncate first command
   checkCommand(strategy_name,instruction);

   if(operation=="OPEN")
     {
      if(checkStrategy(strategy_name))
        {
         double equity = getAccountEquityPercentage();
         logger.debug(__FUNCTION__,StringFormat("Current Equity: %.2f , Limit: %.2f",equity,equityLimit));
         if(equity<equityLimit)
           {
            logger.debug(__FUNCTION__,"Accout Equity limit is reched. Skipping trade.");
           }
         else
           {
            trc.parseCommand(instruction);
           }
        }
      else
        {
         logger.debug(__FUNCTION__,"This strategy is not allowed");
        }
     }
   else
     {
      logger.debug(__FUNCTION__,"Pasing through instruction");
      trc.parseCommand(instruction);
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool StrategyApp::checkStrategy(string name)
  {
   int len = ArraySize(strategies);

   for(int i=0; i<len; i++)
     {
      if(name==strategies[i])
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void StrategyApp::addStrategy(string strategy)
  {
   if(checkStrategy(strategy))
     {
      logger.error(__FUNCTION__,StringFormat("Strategy %s already exists",strategy));
      return;
     }

   int new_len = ArraySize(strategies) + 1;
   if(ArrayResize(strategies,new_len)!=new_len)
     {
      logger.error(__FUNCTION__,"Array Resize failed");
      return;
     }
   strategies[new_len-1] = strategy;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void StrategyApp::setTradeLots(double value)
  {
   trc.setLots(value);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void StrategyApp::removeStrategy(string strategy)
  {
   if(!checkStrategy(strategy))
     {
      logger.error(__FUNCTION__,StringFormat("Strategy %s does not exist to delete",strategy));
      return;
     }

   int len = ArraySize(strategies);
   int idx =-1;
   for(int i=0; i<len; i++)
     {
      if(strategy==strategies[i])
         idx = i;
     }

   if(idx!=(len-1))
     {
      // this means element to be deleted not in the last index. a swap is needed
      strategies[idx] = strategies[len-1];
     }

   if(ArrayResize(strategies,len-1)!=(len-1))
     {
      logger.error(__FUNCTION__,"Array Resize failed");
      return;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void StrategyApp::showAll(void)
  {
   int len = ArraySize(strategies);

   for(int i=0; i<len; i++)
     {
      Print(strategies[i]);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void StrategyApp::runCachedCommands(void)
  {
   trc.runCachedCommands();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void StrategyApp::setAccountEquityLimit(double limit)
  {
   equityLimit = limit;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double StrategyApp::getAccountEquityPercentage(void)
  {
   return AccountEquity()/(MathMax(0.01,AccountBalance()))*100;
  }
//+------------------------------------------------------------------+
