//+------------------------------------------------------------------+
//|                                                        Timer.mq4 |
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne."
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Timer
  {
private:
   int               interval,last;

public:
                     Timer(void);
   void              setInterval(int seconds);
   void              setLastTime(int epoch_unix_time);
   bool              checkInterval(void);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Timer::Timer(void)
  {
   setInterval(30);
   setLastTime((int)TimeGMT());
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Timer::setInterval(int seconds)
  {
   interval = seconds;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Timer::setLastTime(int epoch_unix_time)
  {
   last = epoch_unix_time;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Timer::checkInterval(void)
  {
   int now = (int)TimeGMT();

   if(now >= last+interval)
     {
      last = now;
      return true;
     }
   else
      return false;
  }