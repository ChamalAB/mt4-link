//+------------------------------------------------------------------+
//|                                                      mt4link.mq4 |
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne."
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict

#include <Custom_2\\Connections.mqh>
#include <Custom_2\\Communications\\SimpleHash.mqh>
#include <Custom_2\\mt4link\\Helpers.mqh>
#include <Custom_2\\Queues\\Queues.mqh>
#include <Custom_2\\Misc\\StringHelpers.mqh>
#include <Custom_2\\Porcupine.mqh>
#include <Custom_2\\Logger.mqh>
#include <Custom_2\\Files\\Files.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class mt4link
  {
private:
   string            service,password,mt4Number,serverUrl,connectionStatus;
   int               diskUpdateLast,diskUpdateWindow,updateDelay,updatePeriod,
                     updateLast,lastDownloadedIID,lastExecutedIID;
   bool              checkUpdate,isRegistered;

   Logger            logger;
   SimpleHash        *sHash;
   Porcupine         disk;
   StringQueue       queue;
   Files             files;


   bool              requestController(void);
   void              addDelay(void);
   void              resetDelay(void);
   bool              requestUpdate(void);
   bool              downloadInstructions(string &response);
   bool              checkInstructionIntegrity(string instruction);
   void              addToQueue(string instructions);
   bool              diskUpdateController(void);

protected:

public:
                     mt4link(void); // Constructor
                    ~mt4link(void);  // Deconstructor
   // Admin Scope - password required
   bool              instructionWrite(string Instruction); // not implemented yet
   bool              mt4AccountAdd(string Service,string Mt4Number); // not implemented yet
   bool              mt4AccountRemove(string Service,string Mt4Number); // not implemented yet

   // Client Scope
   bool              messageWrite(string Message);
   bool              getInstruction(string &instruction);
   bool              downloadFile(string FileName);
   bool              uploadFile(string FileName);

   // Common
   void              update(void);
   bool              getRegistration(bool update=false);
   string            getConnectionStatus(void);
   void              setUpdatePeriod(int seconds);

   // Setters
   void              setService(string Service);
   void              setMt4Account(string Mt4Number);
   void              setServerUrl(string ServerUrl);
   void              setPassword(string Password);

   // Getters
   string            getService(void);
   string            getMt4Account(void);
   string            getServerUrl(void);
  };


//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
mt4link::mt4link(void)
  {
   service = "";
   password = "";
   mt4Number = "";
   serverUrl = "";
   checkUpdate = true;
   isRegistered = false;
   updateLast = (int) D'1970.01.01 00:00:01';
   setUpdatePeriod(1);
   diskUpdateLast = (int) D'1970.01.01 00:00:01';
   diskUpdateWindow = 30; // in seconds
   connectionStatus = "OK";
   diskUpdateLast = (int) D'1970.01.01 00:00:01';
   diskUpdateWindow = 30; // in seconds

   logger.setName("mt4link");
   logger.setLevel(LEVEL_INFO);
   logger.setLog(true);
   logger.setPrint(false);
   logger.setPath("Files\\mt4link\\log.log");

   sHash = new SimpleHash(8);

   files.setDownloadPath("Files\\mt4link\\downloads\\");

   disk.setPath("Files\\mt4link\\disk\\");

   if(!disk.filesLoad())
      logger.error("Porcupine","Disk Files load failed");

   if(disk.checkKey(TYPE_INT,"lastExecutedIID"))
     {
      logger.debug("Porcupine","Last ID found on disk");
      if(disk.getData("lastExecutedIID",lastExecutedIID))
        {
         logger.debug("Porcupine","File Loaded");
        }
      else
        {
         logger.error("Porcupine","Data grab failed from disk");
         lastExecutedIID = 0;
        }
     }
   else
     {
      logger.debug("Porcupine","Last ID not found on disk");
      lastExecutedIID = 0;
     }

   lastDownloadedIID =  lastExecutedIID;
   logger.debug(__FUNCTION__,StringFormat("Last IID %d",lastDownloadedIID));

   logger.debug(__FUNCTION__,"mt4link initiated");
  }

//+------------------------------------------------------------------+
//| Deconstructor                                                    |
//+------------------------------------------------------------------+
mt4link::~mt4link(void)
  {
   delete(sHash);
   if(!disk.filesDump())
      logger.error("Porcupine","File Dump failed");


   logger.debug(__FUNCTION__,"mt4link deinitialized");
  }
//+------------------------------------------------------------------+
//| setService                                                       |
//+------------------------------------------------------------------+
void mt4link::setService(string Service)
  {
   service = Service;
  }


//+------------------------------------------------------------------+
//| setMt4Account                                                    |
//+------------------------------------------------------------------+
void mt4link::setMt4Account(string Mt4Number)
  {
   mt4Number = Mt4Number;
  }

//+------------------------------------------------------------------+
//| setServerUrl                                                     |
//+------------------------------------------------------------------+
void mt4link::setServerUrl(string ServerUrl)
  {
   serverUrl = ServerUrl;
  }

//+------------------------------------------------------------------+
//| setPassword                                                      |
//+------------------------------------------------------------------+
void mt4link::setPassword(string Password)
  {
   password = Password;
  }

//+------------------------------------------------------------------+
//| getMt4Account                                                    |
//+------------------------------------------------------------------+
string mt4link::getMt4Account(void)
  {
   return mt4Number;
  }

//+------------------------------------------------------------------+
//| getService                                                       |
//+------------------------------------------------------------------+
string mt4link::getService(void)
  {
   return service;
  }

//+------------------------------------------------------------------+
//| getServerUrl                                                     |
//+------------------------------------------------------------------+
string mt4link::getServerUrl(void)
  {
   return serverUrl;
  }


//+------------------------------------------------------------------+
//| getRegistration                                                  |
//+------------------------------------------------------------------+
bool mt4link::getRegistration(bool update=false)
  {
   if(update)
     {
      // check online for account registration
      string res;
      string get_request = StringFormat("%s/register?number=%s&service=%s",serverUrl,mt4Number,service);
      int server_res = send_get_request(get_request,res);

      if(server_res==200)
         isRegistered=true;
      else
         isRegistered=false;
     }

   return isRegistered;
  }


//+------------------------------------------------------------------+
//| getConnectionStatus                                              |
//+------------------------------------------------------------------+
string mt4link::getConnectionStatus(void)
  {
   return connectionStatus;
  }

//+------------------------------------------------------------------+
//| setUpdatePeriod                                                  |
//+------------------------------------------------------------------+
void mt4link::setUpdatePeriod(int seconds)
  {
   updatePeriod = seconds;
   updateDelay = seconds;
  }

//+------------------------------------------------------------------+
//| addDelay                                                         |
//+------------------------------------------------------------------+
void mt4link::addDelay(void)
  {
   connectionStatus = "ERROR";
   if(updateDelay<20)
      updateDelay++;
  }


//+------------------------------------------------------------------+
//| resetDelay                                                       |
//+------------------------------------------------------------------+
void mt4link::resetDelay(void)
  {
   connectionStatus = "OK";
   updateDelay = (int) MathMax(updateDelay/2,updatePeriod);
  }


//+------------------------------------------------------------------+
//| diskUpdateController                                             |
//+------------------------------------------------------------------+
bool mt4link::diskUpdateController(void)
  {
   int now = (int) TimeGMT();

   if(now>=(diskUpdateLast+diskUpdateWindow))
     {
      diskUpdateLast = (int) TimeGMT();
      return true;
     }
   else
      return false;
  }

//+------------------------------------------------------------------+
//| requestController                                                |
//+------------------------------------------------------------------+
bool mt4link::requestController(void)
  {
   int now = (int) TimeGMT();

   if(now>=(updateLast+updateDelay))
     {
      updateLast = (int) TimeGMT();
      return true;
     }
   else
      return false;
  }


//+------------------------------------------------------------------+
//| requestUpdate                                                    |
//+------------------------------------------------------------------+
bool mt4link::requestUpdate(void)
  {
// check online for account registration
   string res;
   string get_request = StringFormat("%s/instruction/last?service=%s",serverUrl,service);
   int server_res = send_get_request(get_request,res);

   if(server_res==200 && res==IntegerToString(lastDownloadedIID))
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool mt4link::messageWrite(string Message)
  {
   string response;
   string url = StringFormat("%s/message/write",serverUrl);
   string commonToken = sHash.common_token_generator();
   string form_data = StringFormat("service=%s&commonToken=%s&mt4Number=%s&message=%s",
                                   service,commonToken,mt4Number,Message);

   logger.debug(__FUNCTION__,StringFormat("Sending to server: %s",form_data));

   if(send_post_request(url,form_data,response)==200)
     {
      logger.debug(__FUNCTION__,StringFormat("Received from server: %s",response));
      return true;
     }
   else
      return false;
  }

//+------------------------------------------------------------------+
//| downloadInstructions                                             |
//+------------------------------------------------------------------+
bool mt4link::downloadInstructions(string &response)
  {
   string url = StringFormat("%s/instruction/read",serverUrl);
   string commonToken = sHash.common_token_generator();
   string form_data = StringFormat("service=%s&commonToken=%s&mt4Number=%s&lastInstruction=%d",
                                   service,commonToken,mt4Number,lastDownloadedIID);

   logger.debug(__FUNCTION__,StringFormat("Sending to server: %s",form_data));

   if(send_post_request(url,form_data,response)==200)
     {
      logger.debug(__FUNCTION__,StringFormat("Received from server: %s",response));
      return true;
     }
   else
      {
      logger.error(__FUNCTION__,StringFormat("Received from server: %s",response));
      return false;
      }
  }

//+------------------------------------------------------------------+
//| checkInstructionIntegrity                                        |
//+------------------------------------------------------------------+
bool mt4link::checkInstructionIntegrity(string instruction)
  {
   string gen_hash,result[];
   int splits;

   splits =  SplitString(instruction,"|",result);

   if(splits==2)
     {
      gen_hash = sHash.sHash(result[0]);
      if(gen_hash==result[1])
         return true;
      else
         return false;
     }
   else
      return false;
  }

//+------------------------------------------------------------------+
//| addToQueue                                                       |
//+------------------------------------------------------------------+
void mt4link::addToQueue(string instructions)
  {
   string res_1,result[],ins;
   int splits,iid;

   SplitString(instructions,"|",result);
   res_1 = result[0];
   splits = SplitString(res_1,"^",result);

   for(int i=0; i<splits; i++)
     {
      if(separateInstruction(result[i],iid,ins))
         // instruction prefix and instruction are both saved in memory
        {
         lastDownloadedIID = iid;
         logger.info(__FUNCTION__,StringFormat("adding iid %d %s",iid,ins));
         if(!queue.push(result[i]))
           {
            logger.error(__FUNCTION__,StringFormat("Adding to queue failed. Queue count at: %d",queue.getCount()));
           }
        }
      else
        {
         logger.error(__FUNCTION__,StringFormat("Instruction parse failed. IID: %d",iid));
        }
     }
  }

//+------------------------------------------------------------------+
//| Update Messages From mt4link server                              |
//+------------------------------------------------------------------+
void mt4link::update(void)
  {
// disk dump
   if(diskUpdateController())
      if(!disk.filesDump())
         logger.error(__FUNCTION__,"File Dump failed");
// remote server update calling update
   if(requestController())
     {
      // request controller  -Timing ok
      logger.debug(__FUNCTION__,StringFormat("Request allowed. checkUpdate set to %d",checkUpdate));
      if(getRegistration(checkUpdate))
        {
         // user registration confirmed
         if(checkUpdate)
            logger.debug(__FUNCTION__,"User Registered");
         // once registered no need to check registration again unless error
         checkUpdate = false;
         if(requestUpdate())
           {
            // checked with last instruction and new messages are available to download
            logger.debug(__FUNCTION__,"New Instructions available on server");
            logger.debug(__FUNCTION__,StringFormat("downloading Instructions last IID %d",lastDownloadedIID));
            string response = "";
            if(downloadInstructions(response))
              {
               logger.debug(__FUNCTION__,"Downloaded");
               // downloaded instructions
               // check message integrity
               if(checkInstructionIntegrity(response))
                 {
                  logger.debug(__FUNCTION__,"Instruction Integrity passed");
                  // instruction is valid
                  resetDelay();
                  // add instructions to queue
                  logger.debug(__FUNCTION__,"Adding instructions to the queue");
                  addToQueue(response);
                 }
               else
                 {
                  logger.error(__FUNCTION__,"Instruction Integrity failed");
                  // invalid instruction
                  addDelay();
                  checkUpdate = true;
                 }
              } // END if(downloadInstructions(response))
            else
              {
               // downloading messages failed add delay and set check update true
               logger.error(__FUNCTION__,"Instruction download failed");
               addDelay();
               checkUpdate = true;
              } // END_ELSE if(downloadInstructions(response))
           } // END if(requestUpdate())
         else
           {
            logger.debug(__FUNCTION__,"No new updates to download");
            // if control reaches here it means no connection error
            resetDelay();
           } // END_ELSE if(requestUpdate())
        } // END if(getRegistration(checkUpdate))
      else
        {
         logger.debug(__FUNCTION__,"User registration check failed");
         // if getRegistration(checkUpdate) returns false add delay to next request
         addDelay();
        } // END_ELSE if(getRegistration(checkUpdate))
     } // END if(requestController())
  } // END mt4link::update(void)


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool mt4link::getInstruction(string &instruction)
  {
   int iid;
   string ins_raw;

   if(queue.pop(ins_raw))
     {
      separateInstruction(ins_raw,iid,instruction);
      lastExecutedIID = iid;
      disk.setData("lastExecutedIID",iid);
      logger.debug(__FUNCTION__,StringFormat("Remaining in queue: %d",queue.getCount()));
      return true;
     }
   else
     {
      return false;
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool mt4link::downloadFile(string FileName)
  {
   string url = StringFormat("%s/download",serverUrl);
   string commonToken = sHash.common_token_generator();
   string form_data = StringFormat("service=%s&commonToken=%s&mt4Number=%s&filename=%s",
                                   service,commonToken,mt4Number,FileName);


   return files.fileDownload(FileName,url,form_data);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool mt4link::uploadFile(string FileName)
  {
   string url = StringFormat("%s/upload",serverUrl);
   string commonToken = sHash.common_token_generator();
   string form_data = StringFormat("service=%s&commonToken=%s&mt4Number=%s",
                                   service,commonToken,mt4Number);

   return files.fileUpload(FileName,url,form_data);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool mt4link::instructionWrite(string Instruction)
  {
   string response;
   string url = StringFormat("%s/instruction/write",serverUrl);
   string commonToken = sHash.common_token_generator();
   string form_data = StringFormat("service=%s&password=%s&commonToken=%s&instruction=%s",
                                   service,password,commonToken,Instruction);

   logger.debug(__FUNCTION__,StringFormat("Sending to server: %s",form_data));

   if(send_post_request(url,form_data,response)==200)
     {
      logger.debug(__FUNCTION__,StringFormat("Received from server: %s",response));
      return true;
     }
   else
      return false;
  }
//+------------------------------------------------------------------+
