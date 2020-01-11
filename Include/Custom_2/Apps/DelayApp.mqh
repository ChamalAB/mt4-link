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
#include <Custom_2\\Misc\\RandomGenerators.mqh>
#include <Custom_2\\Misc\\StringHelpers.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class DelayApp : public MasterApp
  {
   // delays execution by a specified random interval
   // and launches another app
   //
   // Syntax:
   // DELAY [sleep interval in seconds] [.... other APP commands]
   //
private:
   CommandApp        *parent;
   string            myCommand;
   Logger            logger;

   void              random_delay(int seconds,int min_delay=2,int max_delay=180);
public:
                     DelayApp(void);
   string            getMyCommand(void);
   void              attachParent(CommandApp *app);
   void              parseCommand(string command);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
DelayApp::DelayApp(void)
  {
   myCommand = "DELAY";

   logger.setName(myCommand);
   logger.setLevel(LEVEL_DEBUG);
   logger.setLog(false);
   logger.setPrint(true);
   logger.setPath("Files\\Logs\\log.log");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string DelayApp::getMyCommand(void)
  {
   return myCommand;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DelayApp::attachParent(CommandApp *app)
  {
   if(CheckPointer(app)==POINTER_DYNAMIC)
      parent = app;
   else
      logger.error(__FUNCTION__,"Invalid pointer type");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DelayApp::random_delay(int seconds,int min_delay=2,int max_delay=180)
  {
// cannot exceeed max value
   int control = MathMin(seconds,max_delay);
// cannot be under min value
   control = MathMax(control,min_delay);

   Sleep((randBetween(min_delay,control))*1000);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DelayApp::parseCommand(string command)
  {
   if(CheckPointer(parent)==POINTER_INVALID)
     {
      logger.error(__FUNCTION__,"Parent app not set");
      return;
     }


   string instruction = command;
// get the delay value
   string result;

   if(get_split_by_index(instruction," ",0,result))
     {
      logger.debug(__FUNCTION__,StringFormat("Delaying by: %d",StringToInteger(result)));
      random_delay((int)StringToInteger(result));
      // remove command manually
      if(checkCommand(result,instruction))
        {
         logger.debug(__FUNCTION__,StringFormat("Sending to CommandApp: %s",instruction));
         parent.launchApp(instruction);
        }
      else
        {
         logger.error(__FUNCTION__,StringFormat("Error removing command manually: %s",instruction));
        }
     }
   else
     {
      logger.error(__FUNCTION__,StringFormat("Error parsing command: %s",instruction));
     }
  }
//+------------------------------------------------------------------+
