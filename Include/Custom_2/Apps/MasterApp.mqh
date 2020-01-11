//+------------------------------------------------------------------+
//|                                                    MasterApp.mq4 |
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne."
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict


//+------------------------------------------------------------------+
//| Master App Absrtact Class                                        |
//+------------------------------------------------------------------+
class MasterApp
  {
private:

public:
   virtual void              parseCommand(string command) = 0;
  };
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
