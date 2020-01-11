//+------------------------------------------------------------------+
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne"
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict

#include <Custom_2\\Logger.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Files
  {
private:
   Logger            logger;
   string            path;


   string            listFiles(void);
   bool              checkFile(string FileName);

public:
                     Files(void);
   void              setDownloadPath(string Path);
   bool              fileDownload(string FileName,string Url,string post_data="");
   bool              fileUpload(string FileName,string Url,string post_data="");
   bool              fileDelete(string FileName);
   bool              getFileB64(string FileName,string &result);
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Files::Files(void)
  {
   logger.setName("Files");
   logger.setLevel(LEVEL_DEBUG);
   logger.setLog(false);
   logger.setPrint(true);
   logger.setPath("Files\\Logs\\log.log");

   setDownloadPath("Files\\");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Files::setDownloadPath(string Path)
  {
   path = Path;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Files::fileDownload(string FileName,string Url,string post_data="")
  {
   char data[],result_c[];
   string headers;

   FileName = path + FileName;
   logger.debug(__FUNCTION__,StringFormat("Downloading %s from %s POST %s.",FileName,Url,post_data));

   ArrayResize(data,StringToCharArray(post_data,data,0,WHOLE_ARRAY,CP_UTF8)-1);

   int res=WebRequest("POST",Url,"",NULL,20000,data,ArraySize(data),result_c,headers);
//Print("Status code: " , res, ", GLE: ", GetLastError());


   if(res==200)  // 200==Server response given
     {
      if(FileIsExist(FileName))
         FileDelete(FileName);

      int handle=FileOpen(FileName,FILE_READ|FILE_WRITE|FILE_BIN);

      if(handle!=INVALID_HANDLE)
        {
         FileWriteArray(handle,result_c,0,WHOLE_ARRAY);
         //--- close the file
         FileClose(handle);
        }
      else
        {
         logger.error(__FUNCTION__,StringFormat("File %s open failed.",FileName));
         return false;
        }
     }
   else // Handle non 200 server responses
     {
      logger.error(__FUNCTION__,StringFormat("Server Error respose code: %d.",res));
      return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Files::fileUpload(string FileName,string Url,string post_data="")
  {
   char data[],result_c[];
   string headers,result,file_data;

   string FilePath = path + FileName;

   if(!getFileB64(FilePath,result))
     {
      logger.error(__FUNCTION__,"B64 data gather failed");
      return false;
     }

// Make file data url safe by replace = with _
   if(StringReplace(result,"=","_")==-1 || StringReplace(result,"/","(")==-1 || StringReplace(result,"+",")")==-1)
     {
      logger.error(__FUNCTION__,"B64 urlsafe fix failed");
      return false;
     }

   file_data = StringFormat("filename=%s&data=%s",FileName,result);

   if(post_data=="")
      post_data=file_data;
   else
      post_data = StringFormat("%s&%s",post_data,file_data);

   ArrayResize(data,StringToCharArray(post_data,data,0,WHOLE_ARRAY,CP_UTF8)-1);

   int res=WebRequest("POST",Url,"",NULL,20000,data,ArraySize(data),result_c,headers);


   if(res==200)  // 200==Server response given
     {
      return true;
     }
   else // Handle non 200 server responses
     {
      logger.error(__FUNCTION__,StringFormat("Server Error respose code: %d.",res));
      return false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Files::checkFile(string FileName)
  {
   return FileIsExist(FileName);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Files::getFileB64(string FileName,string &result)
  {
   if(!checkFile(FileName))
     {
      logger.error(__FUNCTION__,StringFormat("File %s not found.",FileName));
      return false;
     }

   uchar src[],dst[],key[];
   int handle=FileOpen(FileName,FILE_READ|FILE_BIN);
   if(handle!=INVALID_HANDLE)
     {
      FileReadArray(handle,src);
      //--- close the file
      FileClose(handle);
     }
   else
     {
      logger.error(__FUNCTION__,StringFormat("File %s open failed.",FileName));
      return false;
     }

   int res = CryptEncode(CRYPT_BASE64,src,key,dst);
   if(res==0)
     {
      logger.error(__FUNCTION__,StringFormat("File %s encode error.",FileName));
      return false;
     }

   result = CharArrayToString(dst);
   return true;
  }

//+------------------------------------------------------------------+
