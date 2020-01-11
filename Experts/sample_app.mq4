//+------------------------------------------------------------------+
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Chamal Abayaratne"
#property version   "1.00"
#property strict

#include <Custom_2\\Apps\\CommandApp.mqh>
#include <Custom_2\\Apps\\UpdateSpeedControlApp.mqh>
#include <Custom_2\\Apps\\FileManagementApp.mqh>
#include <Custom_2\\Apps\\DelayApp.mqh>
#include <Custom_2\\Apps\\ExpireApp.mqh>
#include <Custom_2\\Apps\\StrategyApp.mqh>

CommandApp              *cmd;
UpdateSpeedControlApp   *usca;
FileManagementApp       *fma;
DelayApp                *delay;
ExpireApp               *expire;
StrategyApp             *strategy_def;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(1);
   cmd = new CommandApp();
   usca = new UpdateSpeedControlApp();
   fma = new FileManagementApp();
   delay = new DelayApp();
   expire = new ExpireApp();
   strategy_def = new StrategyApp();

   cmd.setMt4Account("12345");
   cmd.setService("SERVICE");
   cmd.setPassword("PASSWORD");
   cmd.setServerUrl("https://mt4tradelink.xyz/v1");
   //cmd.setServerUrl("http://192.168.8.103/v1");
   cmd.setUpdatePeriod(2);
   
   if(!cmd.checkRegistration())
      return (INIT_FAILED);
   
   cmd.attachApp(usca,usca.getMyCommand());
   usca.attachParent(cmd);
   
   cmd.attachApp(fma,fma.getMyCommand());
   fma.attachParent(cmd);
   
   cmd.attachApp(delay,delay.getMyCommand());
   delay.attachParent(cmd);
   
   cmd.attachApp(expire,expire.getMyCommand());
   expire.attachParent(cmd);
   
   cmd.attachApp(strategy_def,strategy_def.getMyCommand());
   strategy_def.addStrategy("STRAT_2");
   strategy_def.setAccountEquityLimit(100);
   strategy_def.setTradeLots(0.02);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   delete(strategy_def);
   delete(expire);
   delete(delay);
   delete(fma);
   delete(usca);
   delete(cmd);


//--- destroy timer
   EventKillTimer();

  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   Comment(cmd.getConnectionStatus());
   cmd.update();
   strategy_def.runCachedCommands();
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---

  }
//+------------------------------------------------------------------+
