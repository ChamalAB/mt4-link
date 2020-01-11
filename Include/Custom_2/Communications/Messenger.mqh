//+------------------------------------------------------------------+
//|                                                    Messenger.mq4 |
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne."
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict


#include <Custom\\Connections.mqh>
#include <Custom\\Communications\\SimpleHash.mqh>
#include <Custom\\Queues\\Queues.mqh>
#include <Custom\\Misc\\StringHelpers.mqh>

class Messenger
   {
   private:
   string server_url;
   SimpleHash hasher;
   StringQueue queue;
   
   
   protected:
   
   
   
   public:
   Messenger(string url="http://127.0.0.1")
      {
      server_url = url;
      }
      
      
   bool check(bool update=true);
   bool get(string &message);
   bool send(string message);
   
   
   };

//+------------------------------------------------------------------+
//|  Check whther any messages                                       |
//+------------------------------------------------------------------+
bool Messenger::check(bool update=true)
   {
   if(update)
      {
      // Check server for update and return status
      string message_id;
      
      // 1. Check url+/pending  - '' if no update or message_ID is received
      bool status = send_post_request(server_url+"/pending","",message_id);
      
      if(status)
         {
         if(message_id!="")
            {
            // 2. Get url+/get - - 404 if no message or payload is downloaded
            string message;
            bool status_2;
            status_2 = send_post_request(server_url+"/get",
                                         "message_id="+message_id,
                                         message);
            if(status_2)
               {
               // 3. Confirm url+/confirm PACKAGE_INVALID - message_ID does not exist
               //                         PACKAGE_INGENUINE - message hash check failed
               //                         PACKAGE_GENUINE - message is received
               string hash= hasher.sHash(message);
               string response_2;
               bool status_3;
               
               status_3 = send_post_request(server_url+"/confirm",
                                            "message_id="+message_id+"&hash="+hash,
                                            response_2);
               if(status_3)
                  {
                  if(response_2=="PACKAGE_GENUINE")
                     {
                     // 4. Split message
                     string array[];
                     int splits;
                     splits = SplitString(message,"^",array);
                     // 5. Store in queue
                     for(int i=0;i<splits;i++)
                        {
                        queue.push(array[i]);
                        }
                     }
                  else if (response_2=="PACKAGE_INGENUINE")
                     {
                     Print(__FUNCTION__," PACKAGE_INGENUINE");
                     }
                  else if (response_2==" PACKAGE_INVALID")
                     {
                     Print(__FUNCTION__," PACKAGE_INVALID");
                     }
                  else
                     {
                     Print(__FUNCTION__,
                           " Unknown response in confirming. Response: ",
                            response_2);
                     }
                  }
               else
                  {
                  Print(__FUNCTION__," Error confirming message..");
                  }
               }
            else
               {
               Print(__FUNCTION__," Error downloading message..");
               }
            }
         }
      else
         {
         Print(__FUNCTION__," Error connecting to server..");
         }
      } // End of update part
      
   if(queue.getCount()==0) return false;
   else return true;
   }
   
   
bool Messenger::get(string &message)
   {
   return queue.pop(message);
   }