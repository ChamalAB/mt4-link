//+------------------------------------------------------------------+
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne"
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict


int randBetween(int Start,int End)
   {
   int num = Start + (End-Start)*MathRand()/32768;
   return num;
   }
   
string randStringGenerator(int size)
   {
   string set = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$^*()|{};:''<>,.?/-_";
   string output = "";
   int string_len = StringLen(set);
   
   int random;
   for(int i=0;i<size;i++)
      {
      random = randBetween(0,string_len);
      output = output + StringSubstr(set,random,1);
      }
   
   return output;
   }