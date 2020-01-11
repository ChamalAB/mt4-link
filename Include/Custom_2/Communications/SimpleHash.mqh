//+------------------------------------------------------------------+
//|                                                   SimpleHash.mq4 |
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne."
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict



//+------------------------------------------------------------------+
//| class Roller                                                     |
//+------------------------------------------------------------------+
class Roller
  {
private:
   int               roll_start,roll_end,now;

public:
                     Roller(int Start=65,int End=90) // Constructor
     {
      roll_start = Start;
      roll_end = End;
      now = Start;
     }

   void              add(int number);
   string            get();
  };

//+------------------------------------------------------------------+
//| add                                                              |
//+------------------------------------------------------------------+
void Roller::add(int number)
  {
   now = now + number;
   int overflow;
   while(true)
     {
      if(now>roll_end)
        {
         // Overflow
         overflow = now - roll_end;
         now = roll_start + overflow - 1;
        }
      else
        {
         break;
        }
     }
  }

//+------------------------------------------------------------------+
//| get                                                              |
//+------------------------------------------------------------------+
string Roller::get()
  {
   return CharToString((uchar)now);
  }



//+------------------------------------------------------------------+
//| class SimpleHash                                                 |
//+------------------------------------------------------------------+
class SimpleHash
  {
private:
   int               size;

public:
                     SimpleHash(int Size=4)
     {
      size = Size;
     }

   string            sHash(string input_text);
   string            common_token_generator(void);
   bool              common_token_check(string text_to_check);
  };


//+------------------------------------------------------------------+
//| sHash                                                            |
//+------------------------------------------------------------------+
string SimpleHash::sHash(string input_text)
  {
   uchar text[];
   int text_len = StringLen(input_text);
   ArrayResize(text,text_len);
   StringToCharArray(input_text,text,0,text_len,CP_UTF8);

   Roller list[];
   ArrayResize(list,size);

   int counter = 0; // counter for rollers
   for(int i=0; i<text_len; i++)
     {
      if(counter>=size)
         counter = 0; // reset counter for rollers
      list[counter].add((int)text[i]); // add to Rollers
      counter++;
     }

   string hash = IntegerToString(text_len);

   for(int i=0; i<size; i++)
     {
      hash = hash + list[i].get();
     }
   return hash;
  }

//+------------------------------------------------------------------+
//| common_token_generator                                           |
//+------------------------------------------------------------------+
string SimpleHash::common_token_generator(void)
  {
   MqlDateTime date1;
   string text;

   TimeGMT(date1);
// 2013-01-01 01:01 - all zero padded
   text = StringFormat("%d-%02d-%02d %02d:%02d",date1.year,date1.mon,date1.day,date1.hour,date1.min);
   text = text + IntegerToString((int)pow(date1.min,3));

   return sHash(text);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|common_token_check                                                |
//+------------------------------------------------------------------+
bool SimpleHash::common_token_check(string text_to_check)
  {
   MqlDateTime date1;
   string text;
   TimeToStruct(TimeGMT() - D'1970.01.01 00:01',date1);
// 2013-01-01 01:01 - all zero padded
   text = StringFormat("%d-%02d-%02d %02d:%02d",date1.year,date1.mon,date1.day,date1.hour,date1.min);
   text = text + IntegerToString((int)pow(date1.min,3));

   if(text_to_check==sHash(text))
      return true;
   else
      if(text_to_check==common_token_generator())
         return true;
      else
         return false;
  }
//+------------------------------------------------------------------+
