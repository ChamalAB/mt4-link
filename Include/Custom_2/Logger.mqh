//+------------------------------------------------------------------+
//|                                                       Logger.mq4 |
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne."
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict

#include <Custom_2\\GeneralFunctions.mqh>

#define LEVEL_DEBUG     1
#define LEVEL_INFO      2
#define LEVEL_ERROR     3


//+------------------------------------------------------------------+
//| class Logger                                                     |
//+------------------------------------------------------------------+
class Logger
  {
   // Levels
   //
   // 1 - LEVEL_DEBUG
   // 2 - LEVEL_INFO      < default level
   // 3 - LEVEL_ERROR
   //
   // Deafult format
   // DEBUG [DATETIME] [MODULE NAME] [TEXT]
   // INFO [DATETIME] [MODULE NAME] [TEXT]
   // ERROR [DATETIME] [LE] [MODULE NAME] [TEXT]



private:
   string            path,name,time,level;
   bool              printEnable,logEnable;
   int               logLevel;



   bool              write(string text);
   string            getError(void);

public:
                     Logger(void)
     {
      path = "log.txt";
      name = __FILE__;
      printEnable = true;
      logEnable = false;
      setLevel(LEVEL_INFO);
     }


   void              setPath(string Path);
   void              setName(string Name);
   void              setPrint(bool Enable);
   void              setLog(bool Enable);
   void              setLevel(int Level);

   void              debug(string Module,string Text);
   void              info(string Module,string Text);
   void              error(string Module,string Text);

  };

//+------------------------------------------------------------------+
//| setPath                                                          |
//+------------------------------------------------------------------+
void Logger::setPath(string Path)
  {
   path = Path;
  }

//+------------------------------------------------------------------+
//| setName                                                          |
//+------------------------------------------------------------------+
void Logger::setName(string Name)
  {
   name = Name;
  }

//+------------------------------------------------------------------+
//| setPrint                                                         |
//+------------------------------------------------------------------+
void Logger::setPrint(bool Enable)
  {
   printEnable = Enable;
  }

//+------------------------------------------------------------------+
//| setLog                                                           |
//+------------------------------------------------------------------+
void Logger::setLog(bool Enable)
  {
   logEnable = Enable;
  }

//+------------------------------------------------------------------+
//| setLevel                                                         |
//+------------------------------------------------------------------+
void Logger::setLevel(int Level)
  {
   if(Level==LEVEL_DEBUG || Level==LEVEL_INFO ||Level==LEVEL_ERROR )
      logLevel = Level;
   else
      PrintFormat("LOGGER %s ERROR. UNKNOWN LEVEL. GIVEN %d",name,Level);
  }
  

string Logger::getError(void)
   {
   int LE = GetLastError();
   
   if(LE==0 || LE==4000)
      return StringFormat("%d - no Error",LE);
   else
      return StringFormat("%d - %s",LE,ErrorDescription(LE));
   }

//+------------------------------------------------------------------+
//| write                                                            |
//+------------------------------------------------------------------+
bool Logger::write(string text)
  {
   int handle = FileOpen(path,FILE_READ|FILE_WRITE|FILE_TXT);
   if(handle==INVALID_HANDLE)
     {
      Print("Logger Error: Log File Open Failed");
      return false;
     }

   if(!FileSeek(handle,0,SEEK_END))
     {
      Print("Logger Error: Log File Seek Failed");
      FileClose(handle);
      return false;
     }

   if(FileWrite(handle,text)==0)
     {
      Print("Logger Error: Log File Write Failed");
      FileClose(handle);
      return false;
     }
   FileClose(handle);
   return true;
  }

//+------------------------------------------------------------------+
//| Logger.debug                                                     |
//+------------------------------------------------------------------+
void Logger::debug(string Module,string Text)
  {
  time = TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS);
  level = "DEBUG";
  
   if(logLevel==LEVEL_DEBUG)
     {
      // Print
      if(printEnable)
        {
         PrintFormat("%s %s %s %s",level,name,Module,Text);
        }
      // File Log
      if(logEnable)
        {
         string log_text = StringFormat("%s %s %s %s %s",time,level,name,Module,Text);
         write(log_text);
        }
     }
  }
  
//+------------------------------------------------------------------+
//| Logger.info                                                      |
//+------------------------------------------------------------------+
void Logger::info(string Module,string Text)
  {
  time = TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS);
  level = "INFO";
  
   if(logLevel==LEVEL_DEBUG || logLevel==LEVEL_INFO)
     {
      // Print
      if(printEnable)
        {
         PrintFormat("%s %s %s %s",level,name,Module,Text);
        }
      // File Log
      if(logEnable)
        {
         string log_text = StringFormat("%s %s %s %s %s",time,level,name,Module,Text);
         write(log_text);
        }
     }
  }


//+------------------------------------------------------------------+
//| Logger.error                                                      |
//+------------------------------------------------------------------+
void Logger::error(string Module,string Text)
  {
  // need to capture error once becaue the error is reset once called
  string error = getError();
  time = TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS);
  level = "ERROR";
  
   if(logLevel==LEVEL_DEBUG || logLevel==LEVEL_INFO || logLevel==LEVEL_ERROR)
     {
      // Print
      if(printEnable)
        {
         PrintFormat("%s %s %s %s [LE:%s]",level,name,Module,Text,error);
        }
      // File Log
      if(logEnable)
        {
         string log_text = StringFormat("%s %s %s %s %s [LE:%s]",time,level,name,Module,Text,error);
         write(log_text);
        }
     }
  }
