//+------------------------------------------------------------------+
//|                                                      Helpers.mq4 |
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne."
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict


#include <Custom_2\\Misc\\StringHelpers.mqh>

//+------------------------------------------------------------------+
//| separateInstruction - Helper Function                            |
//+------------------------------------------------------------------+
bool separateInstruction(string input_text,int &iid,string &instruction)
  {
   int s,iid_len;
   string s_array[];

   s = SplitString(input_text,"_",s_array);
   iid = (int) StringToInteger(s_array[0]);
   iid_len = StringLen(s_array[0])+1;

   if(iid<=0 && s_array[0]!="0")  // error check whether instruction id is present
      return false;

   if(s<2) // error check whether instruction has id and instruction separated
     {
      return false;
     }
   else
     {
      instruction = StringSubstr(input_text,iid_len);
      return true;
     }
  }
