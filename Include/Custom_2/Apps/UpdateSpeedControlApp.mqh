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
class UpdateSpeedControlApp : public MasterApp
  {
   // controls the speed of the mt4link app
   //
   //
   // Syntax:
   // USCA UPDATE SPEED [update interval in seconds]
   //
private:
   CommandApp        *parent;
   string            myCommand;
   Logger            logger;

public:
                     UpdateSpeedControlApp(void);
   string            getMyCommand(void);
   void              attachParent(CommandApp *app);
   void              parseCommand(string command);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
UpdateSpeedControlApp::UpdateSpeedControlApp(void)
  {
   myCommand = "USCA";

   logger.setName(myCommand);
   logger.setLevel(LEVEL_DEBUG);
   logger.setLog(false);
   logger.setPrint(true);
   logger.setPath("Files\\Logs\\log.log");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string UpdateSpeedControlApp::getMyCommand(void)
  {
   return myCommand;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateSpeedControlApp::attachParent(CommandApp *app)
  {
   if(CheckPointer(app)==POINTER_DYNAMIC)
      parent = app;
   else
      logger.error(__FUNCTION__,"Invalid pointer type");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateSpeedControlApp::parseCommand(string command)
  {
   if(CheckPointer(parent)==POINTER_INVALID)
     {
      logger.error(__FUNCTION__,"Parent app not set");
      return;
     }


   logger.debug(__FUNCTION__,StringFormat("Command Recieved: %s",command));
   string instruction = command;
   bool cmd_pass = false;

   if(checkCommand("UPDATE",instruction))
      if(checkCommand("SPEED",instruction))
         cmd_pass = true;

   if(cmd_pass)
     {
      logger.info(__FUNCTION__,StringFormat("Changing update interval to: %s",instruction));
      if((int)StringToInteger(instruction)>0)
         parent.setUpdatePeriod((int)StringToInteger(instruction));
      else
         logger.error(__FUNCTION__,"Error setting update speed");
     }
   else
      logger.info(__FUNCTION__,"Syntax error");
  }
//+------------------------------------------------------------------+
