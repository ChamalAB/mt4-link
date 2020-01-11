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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ExpireApp : public MasterApp
  {
   // Check expiration of a command
   // and launches another app if not
   //
   // Syntax:
   // EXPIRE [unix time] [.... other APP commands]
   //
private:
   CommandApp        *parent;
   string            myCommand;
   Logger            logger;

   bool              check_valid(int unix_time);
public:
                     ExpireApp(void);
   string            getMyCommand(void);
   void              attachParent(CommandApp *app);
   void              parseCommand(string command);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ExpireApp::ExpireApp(void)
  {
   myCommand = "EXPIRE";

   logger.setName(myCommand);
   logger.setLevel(LEVEL_DEBUG);
   logger.setLog(false);
   logger.setPrint(true);
   logger.setPath("Files\\Logs\\log.log");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string ExpireApp::getMyCommand(void)
  {
   return myCommand;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ExpireApp::attachParent(CommandApp *app)
  {
   if(CheckPointer(app)==POINTER_DYNAMIC)
      parent = app;
   else
      logger.error(__FUNCTION__,"Invalid pointer type");
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ExpireApp::check_valid(int unix_time)
  {
   int now = (int) TimeGMT();

   if(unix_time==0)
      return false;
   else
      if(unix_time>=now)
         return true;
      else
         return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ExpireApp::parseCommand(string command)
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
      logger.debug(__FUNCTION__,StringFormat("Checking Expiry: %d now: %d",StringToInteger(result),(int)TimeGMT()));

      if(check_valid((int)StringToInteger(result)))
        {
        logger.debug(__FUNCTION__,"Command not expired");
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
      logger.debug(__FUNCTION__,"Command expired");
      }
     }
   else
     {
      logger.error(__FUNCTION__,StringFormat("Error parsing command: %s",instruction));
     }
  }
//+------------------------------------------------------------------+
