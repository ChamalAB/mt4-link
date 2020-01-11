//+------------------------------------------------------------------+
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne"
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict


#include <Custom_2\\Porcupine.mqh>
#include <Custom_2\\Timer.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CacheCommands
  {
private:
   Timer             timer;

   void              cleanCommands(Porcupine &Disk);

public:
                     CacheCommands(void);
   void              cacheCommand(string command,int retries,Porcupine &Disk,bool reset_retries=false);
   int               getCachedCommands(Porcupine &Disk,string &commands[]);
   void              setInterval(int seconds);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CacheCommands::CacheCommands(void)
  {
   setInterval(600);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CacheCommands::setInterval(int seconds)
  {
   timer.setInterval(seconds);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CacheCommands::cacheCommand(string command,int retries,Porcupine &Disk,bool reset_retries=false)
  {
   string key;

   if(Disk.checkValue(command,key))
     {
      // only modify retires
      if(reset_retries)
         {
         // if reset is enabled the retry parameter will be ovewritten
         Disk.setData(key,retries);
         }
     }
   else
     {
      // add new key and retires
      //find unused key to save
      int i=0;
      string name;
      while(true)
        {
         name = StringFormat("cache_%d",i);
         if(!Disk.checkKey(TYPE_STRING,name))
            break;
         i++;
        }
      Disk.setData(name,command);
      Disk.setData(name,retries);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CacheCommands::cleanCommands(Porcupine &Disk)
  {
   string keys[];
   int results;
   Disk.searchData("cache_",keys,TYPE_STRING);
   results = ArraySize(keys);

   for(int i=0; i<results; i++)
     {
      int value;
      Disk.getData(keys[i],value);

      if(value<=0)
        {
         Disk.deleteKey(TYPE_STRING,keys[i]);
         Disk.deleteKey(TYPE_INT,keys[i]);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CacheCommands::getCachedCommands(Porcupine &Disk,string &commands[])
  {
// clean expired commands
   cleanCommands(Disk);

// check interval
   if(!timer.checkInterval())
      return 0;
   
   string keys[];
   int results;
   Disk.searchData("cache_",keys,TYPE_STRING);
   results = ArraySize(keys);
   ArrayResize(commands,results);

   for(int i=0; i<results; i++)
     {
      // get values
      string value;
      Disk.getData(keys[i],value);
      commands[i] = value;

      // count down
      int retries;
      Disk.getData(keys[i],retries);
      Disk.setData(keys[i],retries-1);
     }

   return results;
  }