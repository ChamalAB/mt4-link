//+------------------------------------------------------------------+
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne"
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict


#include <Custom_2\\Apps\\MasterApp.mqh>
#include <Custom_2\\mt4link\\mt4link_v2.mqh>
#include <Custom_2\\Misc\\StringHelpers.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CommandApp : public MasterApp
  {
private:
   Logger            logger;
   mt4link           *mtlink;
   MasterApp         *apps[];
   string            appNames[];

   void              parseCommand(string command);



public:
                     CommandApp(void);
                    ~CommandApp(void);
   void              setMt4Account(string Mt4Account);
   void              setPassword(string Password);
   void              setService(string Service);
   void              setServerUrl(string ServerUrl);
   void              update(void);
   void              attachApp(MasterApp *appObj,string appName);
   string            getConnectionStatus(void);
   bool              checkRegistration(void);

   // to be controlled by Apps
   void              setUpdatePeriod(int UpdatePeriod);
   bool              downloadFile(string FileName);
   bool              uploadFile(string FileName);
   void              launchApp(string command);

  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CommandApp::CommandApp(void)
  {
   mtlink = new mt4link();

   logger.setName("CommandApp");
   logger.setLevel(LEVEL_DEBUG);
   logger.setLog(false);
   logger.setPrint(true);
   logger.setPath("Files\\Logs\\log.log");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CommandApp::~CommandApp(void)
  {
   delete(mtlink);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CommandApp::setMt4Account(string Mt4Account)
  {
   mtlink.setMt4Account(Mt4Account);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CommandApp::setPassword(string Password)
  {
   mtlink.setPassword(Password);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CommandApp::setService(string Service)
  {
   mtlink.setService(Service);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CommandApp::setServerUrl(string ServerUrl)
  {
   mtlink.setServerUrl(ServerUrl);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CommandApp::setUpdatePeriod(int UpdatePeriod)
  {
   mtlink.setUpdatePeriod(UpdatePeriod);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CommandApp::attachApp(MasterApp *appObj,string appName)
  {

   if(CheckPointer(appObj)!=POINTER_DYNAMIC)
     {
      logger.error(__FUNCTION__,StringFormat("App %s pointer not POINTER_DYNAMIC",appName));
      return;
     }

   int new_size = ArraySize(apps);

   if(ArrayResize(apps,new_size+1)==-1)
     {
      logger.error(__FUNCTION__,"Array resize failed");
      return;
     }

   if(ArrayResize(appNames,new_size+1)==-1)
     {
      logger.error(__FUNCTION__,"Array resize failed");
      return;
     }

   apps[new_size] = appObj;
   appNames[new_size] = appName;
   logger.debug(__FUNCTION__,StringFormat("Adding %s at index %d OK",appName,new_size));
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CommandApp::update(void)
  {
   mtlink.update();

   string ins;
   while(true)
     {
      if(mtlink.getInstruction(ins))
         parseCommand(ins);
      else
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CommandApp::launchApp(string command)
  {
   string instruction = command;

   int app_count = ArraySize(apps);
   bool app_found = false;

   for(int i=0; i<app_count; i++)
     {
      if(checkCommand(appNames[i],instruction))
        {
         logger.debug(__FUNCTION__,StringFormat("Matching app found: %s. Executing: %s",appNames[i],instruction));
         apps[i].parseCommand(instruction);
         app_found = true;
        }
     }
     
  if(!app_found)
      logger.debug(__FUNCTION__,"Matching app not found");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CommandApp::parseCommand(string command)
  {
   logger.debug(__FUNCTION__,StringFormat("Command Recieved: %s",command));
   string instruction = command;

   if(checkCommand("CMD",instruction))
      if(checkCommand("ALL",instruction) || checkCommand(mtlink.getMt4Account(),instruction))
        {
         logger.debug(__FUNCTION__,StringFormat("Command passed first stage. Executing: %s",instruction));
         launchApp(instruction);
        }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CommandApp::downloadFile(string FileName)
  {
   return mtlink.downloadFile(FileName);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CommandApp::uploadFile(string FileName)
  {
   return mtlink.uploadFile(FileName);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CommandApp::getConnectionStatus(void)
  {
   return mtlink.getConnectionStatus();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CommandApp::checkRegistration(void)
  {
   return mtlink.getRegistration(true);
  }
//+------------------------------------------------------------------+
