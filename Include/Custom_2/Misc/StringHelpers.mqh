//+------------------------------------------------------------------+
//|                                                StringHelpers.mq4 |
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne."
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| SplitString                                                      |
//+------------------------------------------------------------------+
int SplitString(string text,string separator,string &result[])
  {
// Splits String
// return value is number of splits
   ushort u_sep =  StringGetCharacter(separator,0);
   int splits = StringSplit(text,u_sep,result);
   return splits;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool get_split_by_index(string in_text,string separator,int index,string &out_text)
  {
   string array[];
   int splits = SplitString(in_text,separator,array);

   if(splits<1)
     {
      return false;
     }

   if(index<0 || splits<=index)
     {
      return false;
     }

   out_text = array[index];
   return true;
  }

//+------------------------------------------------------------------+
//| checkCommand                                                     |
//+------------------------------------------------------------------+
bool checkCommand(string command,string &in_cmd)
  {
   bool command_match = false;
   string s_arrray[];
   ushort u_sep =  StringGetCharacter(" ",0);
   int splits = StringSplit(in_cmd,u_sep,s_arrray);

   if(splits<1)
      return command_match;

   if(s_arrray[0]==command)
     {
      in_cmd = "";
      command_match = true;
      for(int i=1; i<ArraySize(s_arrray); i++)
        {
         if(i==1)
           {
            // first append does not need any concatenation
            in_cmd = s_arrray[i];
           }
         else
           {
            in_cmd = in_cmd + " " + s_arrray[i];
           }
        }
     }
   return command_match;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool startsWith(string in_value,string search)
  {
   int count = StringLen(search);

   if(StringSubstr(in_value,0,count)==search)
      return true;
   else
      return false;
  }
//+------------------------------------------------------------------+
