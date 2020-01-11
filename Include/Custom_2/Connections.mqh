//+------------------------------------------------------------------+
//|                                                  Connections.mq4 |
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne."
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict


//+------------------------------------------------------------------+
//| Send post request                                                |
//+------------------------------------------------------------------+
int send_post_request(string post_url,string post_string,string &result_string)
  {
   ResetLastError();
   char data[], result[];
   string headers;
   ArrayResize(data,StringToCharArray(post_string,data,0,WHOLE_ARRAY,CP_UTF8)-1);
   int res=WebRequest("POST",post_url,"",NULL,20000,data,ArraySize(data),result,headers);

   if(GetLastError()==4000)   // 4000==No error returned
     {
      result_string = CharArrayToString(result,0,WHOLE_ARRAY,CP_UTF8);
      return res;
     }
   else
     {
      return -1;
     }
  }

//+------------------------------------------------------------------+
//| Send get request                                                |
//+------------------------------------------------------------------+
int send_get_request(string post_url,string &result_string)
  {
   ResetLastError();
   char data[], result[];
   string headers;
   ArrayResize(data,StringToCharArray("",data,0,WHOLE_ARRAY,CP_UTF8)-1);
   int res=WebRequest("GET",post_url,"",NULL,20000,data,ArraySize(data),result,headers);

   if(GetLastError()==4000)   // 4000==No error returned
     {
      result_string = CharArrayToString(result,0,WHOLE_ARRAY,CP_UTF8);
      return res;
     }
   else
     {
      return -1;
     }
  }
//+------------------------------------------------------------------+
