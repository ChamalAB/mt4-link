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
class FileManagementApp : public MasterApp
  {
   // Handles File Management part of an app
   //
   //
   // Syntax:
   // 1. Download file - FMA DOWNLOAD [filename]
   // 2. Upload file - FMA  UPLOAD [filename]
   // 3. Delete file - FMA DELETE [filename]
   // 4. Create file list - FMA SHOW FILES
private:

   CommandApp        *parent;
   string            myCommand;
   Logger            logger;

public:
                     FileManagementApp(void);
   string            getMyCommand(void);
   void              attachParent(CommandApp *app);
   void              parseCommand(string command);


  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
FileManagementApp::FileManagementApp(void)
  {
   myCommand = "FMA";

   logger.setName(myCommand);
   logger.setLevel(LEVEL_DEBUG);
   logger.setLog(false);
   logger.setPrint(true);
   logger.setPath("Files\\Logs\\log.log");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string FileManagementApp::getMyCommand(void)
  {
   return myCommand;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FileManagementApp::attachParent(CommandApp *app)
  {
   if(CheckPointer(app)==POINTER_DYNAMIC)
      parent = app;
   else
      logger.error(__FUNCTION__,"Invalid pointer type");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FileManagementApp::parseCommand(string command)
  {
   if(CheckPointer(parent)==POINTER_INVALID)
     {
      logger.error(__FUNCTION__,"Parent app not set");
      return;
     }

   logger.debug(__FUNCTION__,StringFormat("Command Recieved: %s",command));
   string instruction = command;


   if(checkCommand("DOWNLOAD",instruction))
     {
      logger.info(__FUNCTION__,StringFormat("Downloading file: %s",instruction));
      parent.downloadFile(instruction);
     }
   else
      if(checkCommand("UPLOAD",instruction))
        {
         logger.info(__FUNCTION__,StringFormat("Uploading file: %s",instruction));
         parent.uploadFile(instruction);
        }
      else
         if(checkCommand("DELETE",instruction))
           {
            logger.error(__FUNCTION__,"Function Not Mapped yet");
           }
         else
            if(checkCommand("SHOW",instruction))
              {
               if(checkCommand("FILES",instruction))
                 {
                  logger.error(__FUNCTION__,"Function Not Mapped yet");
                 }
              }
  }
//+------------------------------------------------------------------+
