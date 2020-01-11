//+------------------------------------------------------------------+
//|                                                       Queues.mq4 |
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne."
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict


//+------------------------------------------------------------------+
//| class StringQueue                                                |
//+------------------------------------------------------------------+
class StringQueue
  {
private:
   string            array[];
   int               max,q_read,q_write,count;

public:

                     StringQueue(int max_elements=1000)
     {
      max = max_elements;
      q_write = 0;
      q_read = 0;
      ArrayResize(array,max);
      count = 0;
     }


   bool              push(string text);
   bool              pop(string &text);
   int               getCount(void);

  };

//+------------------------------------------------------------------+
//| push                                                             |
//+------------------------------------------------------------------+
bool StringQueue::push(string text)
  {
// 1. check if count is reached max
   if(count<max)
     {
      // 2. write data to index
      array[q_write] = text;
      //Print("Writing at index ",q_write);
      // 3. push index by one
      count++;
      q_write++;
      if(q_write==max)
        {
         // 4. if q_write has reached max elements, reset to 0
         q_write = 0;
        }
      return true;
     }
   else
     {
      //Print(__FUNCTION__,",Max elements reached. Cannot push..");
      return false;
     }
  }

//+------------------------------------------------------------------+
//| pop                                                              |
//+------------------------------------------------------------------+
bool StringQueue::pop(string &text)
  {
// 1. Check whether there are elements to pop
   if(count>0)
     {
      text = array[q_read];
      //Print("Reading at index ",q_read);
      count--;
      q_read++;
      if(q_read==max)
        {
         // 4. if q_read has reached max elements, reset to 0
         q_read = 0;
        }
      return true;
     }
   else
     {
      //Print(__FUNCTION__,",No items remain. Cannot pop..");
      return false;
     }
  }

//+------------------------------------------------------------------+
//| getCount                                                         |
//+------------------------------------------------------------------+
int StringQueue::getCount(void)
  {
   return count;
  }
//+------------------------------------------------------------------+
