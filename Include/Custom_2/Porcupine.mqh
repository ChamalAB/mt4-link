//+------------------------------------------------------------------+
//|                                                    Porcupine.mq4 |
//|                                Copyright 2019, Chamal Abayaratne |
//|                                            cabayaratne@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Chamal Abayaratne."
#property link      "cabayaratne@gmail.com"
#property version   "1.00"
#property strict

// Normal File open/close operatiion costs about 1-2 miliseconds on a standard SSD.
// Therfore in mql4, saving variables in a drive and reading from them will add a
// considerable delay for the program.
//
// Porcupine only open files from the disk once. The variables are stored in an
// array and loaded to the ram once. Once the variables are loaded to the main
// memory, the reading time will go down to approx 1 microsecond on a standard
// PC setup. Making this method 1000x faster than refering to sidk files each time.
//
// This module is used to transfer variables from main memory to persistence
// memory by serializing arrays. You can save String,Int,Double,DateTime data
// types with this module.
//
// Usage is simillar to MT4's global variable set,get,check functions.(which only allows to
// store double data type).
//
// This module can hold any number of variables and able dump to and load from
// local storage. data are stored as key,value pairs.
//
//
// --Features--
// 1. Set key,value to be saved
// 2. Retrieve values by calling the key
// 3. Check for value and get key(first found value-key pair will be returned)
// 4. Check for key existance
// 5. Set path for data storage(within the MQL4 sandbox)

//+------------------------------------------------------------------+
//|  STRUCT                                                          |
//+------------------------------------------------------------------+
struct DataSet
  {
   string            fileNames[16];     // record of files to be saved

   string            str_key[];        // keys
   string            str_value[];      // values
   datetime          str_c[];          // record created
   datetime          str_la[];         // record last accessed

   string            int_key[];        // keys
   int               int_value[];      // values
   datetime          int_c[];          // record created
   datetime          int_la[];         // record last accessed

   string            dbl_key[];        // keys
   double            dbl_value[];      // values
   datetime          dbl_c[];          // record created
   datetime          dbl_la[];         // record last accessed

   string            dtm_key[];        // keys
   datetime          dtm_value[];      // values
   datetime          dtm_c[];          // record created
   datetime          dtm_la[];         // record last accessed

                     DataSet() // Constructor
     {
      fileNames[0] = "str_key";
      fileNames[1] = "str_value";
      fileNames[2] = "str_c";
      fileNames[3] = "str_la";

      fileNames[4] = "int_key";
      fileNames[5] = "int_value";
      fileNames[6] = "int_c";
      fileNames[7] = "int_la";

      fileNames[8]  = "dbl_key";
      fileNames[9]  = "dbl_value";
      fileNames[10] = "dbl_c";
      fileNames[11] = "dbl_la";

      fileNames[12]  = "dtm_key";
      fileNames[13]  = "dtm_value";
      fileNames[14]  = "dtm_c";
      fileNames[15]  = "dtm_la";

      ArrayResize(str_key,1);
      ArrayResize(str_value,1);
      ArrayResize(str_c,1);
      ArrayResize(str_la,1);

      ArrayResize(int_key,1);
      ArrayResize(int_value,1);
      ArrayResize(int_c,1);
      ArrayResize(int_la,1);

      ArrayResize(dbl_key,1);
      ArrayResize(dbl_value,1);
      ArrayResize(dbl_c,1);
      ArrayResize(dbl_la,1);

      ArrayResize(dtm_key,1);
      ArrayResize(dtm_value,1);
      ArrayResize(dtm_c,1);
      ArrayResize(dtm_la,1);

      str_key[0] = "INIT";
      str_value[0] = "001";
      str_c[0] = TimeLocal();
      str_la[0] = TimeLocal();

      int_key[0] = "INIT";
      int_value[0] = 0;
      int_c[0] = TimeLocal();
      int_la[0] = TimeLocal();

      dbl_key[0] = "INIT";
      dbl_value[0] = 0.0;
      dbl_c[0] = TimeLocal();
      dbl_la[0] = TimeLocal();

      dtm_key[0] = "INIT";
      dtm_value[0] = 0.0;
      dtm_c[0] = TimeLocal();
      dtm_la[0] = TimeLocal();
     }
  };


//+------------------------------------------------------------------+
//|  CLASS                                                           |
//+------------------------------------------------------------------+
class Porcupine
  {
protected:
   string            path;
   bool              prevent_dump; // this flag is used to prevent data dump in case of file corruption
   DataSet           data;

public:
                     Porcupine()
     {
      // Constructor
      // set default path
      path = "Files\\Data\\";
      prevent_dump = false;
     }

   // path functions
   void              setPath(string p);
   string            getPath(void);

   // file functions
   bool              filesDump(bool remove_first=true);
   bool              filesLoad(void);

   // user functions
   bool              checkKey(int type_id,string key);
   bool              deleteKey(int type_id,string key);

   bool              checkValue(string value,string &key);
   bool              checkValue(int value,string &key);
   bool              checkValue(double value,string &key);
   bool              checkValue(datetime value,string &key);

   void              setData(string key,string value);
   void              setData(string key,int value);
   void              setData(string key,double value);
   void              setData(string key,datetime value);

   bool              getData(string key,string &value);
   bool              getData(string key,int &value);
   bool              getData(string key,double &value);
   bool              getData(string key,datetime &value);

   void              searchData(string search,string &keys[],int data_type);

   void              listAll();



private:
   bool              filesCheck(void);
   bool              filesRemove(void);

   bool              fileOpen_StringArray(string filePath,string &read_arr[]);
   bool              fileOpen_IntArray(string filePath,int &read_arr[]);
   bool              fileOpen_DoubleArray(string filePath,double &read_arr[]);
   bool              fileOpen_DateTimeArray(string filePath,datetime &read_arr[]);

   void              listString();
   void              listInt();
   void              listDouble();
   void              listDateTime();

   bool              startsWith(string in_value,string search);
  };



// class functions

//+------------------------------------------------------------------+
//|  set file save path                                              |
//+------------------------------------------------------------------+
void Porcupine::setPath(string p)
  {
   path = p;
  }


//+------------------------------------------------------------------+
//|  Get specified file save path                                    |
//+------------------------------------------------------------------+
string Porcupine::getPath(void)
  {
   return path;
  }


//+------------------------------------------------------------------+
//|  checks existance of all listed files in the path specified      |
//+------------------------------------------------------------------+
bool Porcupine::filesCheck(void) // checks existance of all listed files in the path specified
  {
// This function check for the existance of files
   int i,arr_size,count;
   bool state = true;

   arr_size = ArraySize(data.fileNames);
   count = 0;

   for(i=0; i<arr_size; i++)
     {
      //Print("Checking: ",path+data.fileNames[i]);
      if(FileIsExist(path+data.fileNames[i]))
        {
         // Print(__FUNCTION__," Found: ",data.fileNames[i]);
         count++;
        }
      else
        {
         Print(__FUNCTION__," Not Found: ",data.fileNames[i]);
        }
     }
   Print(__FUNCTION__,"files found: ",count," Out of ",arr_size);

   if(count==0)
     {
      Print(__FUNCTION__,"Clean installation found. creating data files");
      // create empty files
      filesDump(false);
     }
   else
      if(count<arr_size)
        {
         Print(__FUNCTION__,"File structre corrupted. request clean up or import");
         // create empty files or request import
         string message = "Data folder is corrupt. \n\nPress Ok to reset the data folder."
                          " Resetting the data folder will delete all data this EA has."
                          "\n\nIf you wish not to do this, Press Cancel.";
         int msg_box = MessageBox(message,"Error::Data Corrupt",MB_OKCANCEL|MB_ICONSTOP);

         if(msg_box==IDOK)
           {
            filesDump(true);
            state = true;
           }
         else
           {
            state = false;
            prevent_dump = true;
           }
        }
      else
        {
         Print(__FUNCTION__,"Required files available");
         // check for file contents algorithm
        }


   return state;
  }

//+------------------------------------------------------------------+
//|  Removes all listed files in the path specified                  |
//+------------------------------------------------------------------+
bool Porcupine::filesRemove(void) // Removes all listed files in the path specified
  {
   int i,arr_size;
   bool state = true;

   arr_size = ArraySize(data.fileNames);

   for(i=0; i<arr_size; i++)
     {
      if(FileIsExist(path+data.fileNames[i]))
        {
         if(!FileDelete(path+data.fileNames[i]))
           {
            Print(__FUNCTION__,"File ",path+data.fileNames[i]," delete failed. GLE: ",GetLastError());
            state = false;
           }
        }
     }
   return state;
  }

//+------------------------------------------------------------------+
//|  Create empty files in the path specified                        |
//+------------------------------------------------------------------+
bool Porcupine::filesDump(bool remove_first=true) // Create empty files in the path specified
  {
   bool state = true;
   int filehandle;
   string fPath;

   if(prevent_dump)
     {
      // prevent dump flag is activated
      Print(__FUNCTION__," Preventing files dump");
      return false;
     }

   if(remove_first)
     {
      filesRemove();
     }


//  01.dump str_key //**
   fPath = path+"str_key"; //**
   filehandle = FileOpen(fPath,FILE_TXT|FILE_READ|FILE_WRITE); //**
   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," ",fPath," open failed. GLE: ",GetLastError());
      state = false;
     }
   else
     {
      FileWriteArray(filehandle,data.str_key); //**
      FileClose(filehandle);
     }



// 02.dump str_value //**
   fPath = path+"str_value"; //**
   filehandle = FileOpen(fPath,FILE_TXT|FILE_READ|FILE_WRITE); //**
   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," ",fPath," open failed. GLE: ",GetLastError());
      state = false;
     }
   else
     {
      FileWriteArray(filehandle,data.str_value); //**
      FileClose(filehandle);
     }



// 03.dump str_c //**
   fPath = path+"str_c"; //**
   filehandle = FileOpen(fPath,FILE_BIN|FILE_READ|FILE_WRITE); //**
   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," ",fPath," open failed. GLE: ",GetLastError());
      state = false;
     }
   else
     {
      FileWriteArray(filehandle,data.str_c); //**
      FileClose(filehandle);
     }



// 04.dump str_la //**
   fPath = path+"str_la"; //**
   filehandle = FileOpen(fPath,FILE_BIN|FILE_READ|FILE_WRITE); //**
   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," ",fPath," open failed. GLE: ",GetLastError());
      state = false;
     }
   else
     {
      FileWriteArray(filehandle,data.str_la); //**
      FileClose(filehandle);
     }



// 05.dump int_key //**
   fPath = path+"int_key"; //**
   filehandle = FileOpen(fPath,FILE_TXT|FILE_READ|FILE_WRITE); //**
   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," ",fPath," open failed. GLE: ",GetLastError());
      state = false;
     }
   else
     {
      FileWriteArray(filehandle,data.int_key); //**
      FileClose(filehandle);
     }



// 06.dump int_value //**
   fPath = path+"int_value"; //**
   filehandle = FileOpen(fPath,FILE_BIN|FILE_READ|FILE_WRITE); //**
   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," ",fPath," open failed. GLE: ",GetLastError());
      state = false;
     }
   else
     {
      FileWriteArray(filehandle,data.int_value); //**
      FileClose(filehandle);
     }



// 07.dump int_c //**
   fPath = path+"int_c"; //**
   filehandle = FileOpen(fPath,FILE_BIN|FILE_READ|FILE_WRITE); //**
   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," ",fPath," open failed. GLE: ",GetLastError());
      state = false;
     }
   else
     {
      FileWriteArray(filehandle,data.int_c); //**
      FileClose(filehandle);
     }



// 08.dump int_la //**
   fPath = path+"int_la"; //**
   filehandle = FileOpen(fPath,FILE_BIN|FILE_READ|FILE_WRITE); //**
   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," ",fPath," open failed. GLE: ",GetLastError());
      state = false;
     }
   else
     {
      FileWriteArray(filehandle,data.int_la); //**
      FileClose(filehandle);
     }



// 09.dump dbl_key //**
   fPath = path+"dbl_key"; //**
   filehandle = FileOpen(fPath,FILE_TXT|FILE_READ|FILE_WRITE); //**
   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," ",fPath," open failed. GLE: ",GetLastError());
      state = false;
     }
   else
     {
      FileWriteArray(filehandle,data.dbl_key); //**
      FileClose(filehandle);
     }



// 10.dump dbl_value //**
   fPath = path+"dbl_value"; //**
   filehandle = FileOpen(fPath,FILE_BIN|FILE_READ|FILE_WRITE); //**
   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," ",fPath," open failed. GLE: ",GetLastError());
      state = false;
     }
   else
     {
      FileWriteArray(filehandle,data.dbl_value); //**
      FileClose(filehandle);
     }



// 11.dump dbl_c //**
   fPath = path+"dbl_c"; //**
   filehandle = FileOpen(fPath,FILE_BIN|FILE_READ|FILE_WRITE); //**
   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," ",fPath," open failed. GLE: ",GetLastError());
      state = false;
     }
   else
     {
      FileWriteArray(filehandle,data.dbl_c); //**
      FileClose(filehandle);
     }



// 12.dump dbl_la //**
   fPath = path+"dbl_la"; //**
   filehandle = FileOpen(fPath,FILE_BIN|FILE_READ|FILE_WRITE); //**
   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," ",fPath," open failed. GLE: ",GetLastError());
      state = false;
     }
   else
     {
      FileWriteArray(filehandle,data.dbl_la); //**
      FileClose(filehandle);
     }



// 13.dump dtm_key //**
   fPath = path+"dtm_key"; //**
   filehandle = FileOpen(fPath,FILE_TXT|FILE_READ|FILE_WRITE); //**
   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," ",fPath," open failed. GLE: ",GetLastError());
      state = false;
     }
   else
     {
      FileWriteArray(filehandle,data.dtm_key); //**
      FileClose(filehandle);
     }



// 14.dump dtm_value //**
   fPath = path+"dtm_value"; //**
   filehandle = FileOpen(fPath,FILE_BIN|FILE_READ|FILE_WRITE); //**
   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," ",fPath," open failed. GLE: ",GetLastError());
      state = false;
     }
   else
     {
      FileWriteArray(filehandle,data.dtm_value); //**
      FileClose(filehandle);
     }



// 15.dump dtm_c //**
   fPath = path+"dtm_c"; //**
   filehandle = FileOpen(fPath,FILE_BIN|FILE_READ|FILE_WRITE); //**
   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," ",fPath," open failed. GLE: ",GetLastError());
      state = false;
     }
   else
     {
      FileWriteArray(filehandle,data.dtm_c); //**
      FileClose(filehandle);
     }



// 16.dump dtm_la //**
   fPath = path+"dtm_la"; //**
   filehandle = FileOpen(fPath,FILE_BIN|FILE_READ|FILE_WRITE); //**
   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," ",fPath," open failed. GLE: ",GetLastError());
      state = false;
     }
   else
     {
      FileWriteArray(filehandle,data.dtm_la); //**
      FileClose(filehandle);
     }

   return state;
  }

//+------------------------------------------------------------------+
//|  check for key by type                                           |
//+------------------------------------------------------------------+
bool Porcupine::filesLoad(void)
  {
   bool status = true;

// Check files
   status = status & filesCheck();

// string files
   status = status & fileOpen_StringArray(path+"str_key",data.str_key);
   status = status & fileOpen_StringArray(path+"str_value",data.str_value);
   status = status & fileOpen_DateTimeArray(path+"str_c",data.str_c);
   status = status & fileOpen_DateTimeArray(path+"str_la",data.str_la);

// int files
   status = status & fileOpen_StringArray(path+"int_key",data.int_key);
   status = status & fileOpen_IntArray(path+"int_value",data.int_value);
   status = status & fileOpen_DateTimeArray(path+"int_c",data.int_c);
   status = status & fileOpen_DateTimeArray(path+"int_la",data.int_la);

// double files
   status = status & fileOpen_StringArray(path+"dbl_key",data.dbl_key);
   status = status & fileOpen_DoubleArray(path+"dbl_value",data.dbl_value);
   status = status & fileOpen_DateTimeArray(path+"dbl_c",data.dbl_c);
   status = status & fileOpen_DateTimeArray(path+"dbl_la",data.dbl_la);

// datetime files
   status = status & fileOpen_StringArray(path+"dtm_key",data.dtm_key);
   status = status & fileOpen_DateTimeArray(path+"dtm_value",data.dtm_value);
   status = status & fileOpen_DateTimeArray(path+"dtm_c",data.dtm_c);
   status = status & fileOpen_DateTimeArray(path+"dtm_la",data.dtm_la);

   return status;
  }




//+------------------------------------------------------------------+
//|  check for key by type                                           |
//+------------------------------------------------------------------+
bool Porcupine::checkKey(int type_id,string key)
  {
   bool status = false;
   int i,arr_size;

   if(type_id==TYPE_STRING)
     {
      arr_size = ArraySize(data.str_key);
      for(i=0; i<arr_size; i++)
        {
         if(data.str_key[i]==key)
           {
            data.str_la[i] = TimeLocal();
            return true;
           }
        }
     }
   else
      if(type_id==TYPE_INT)
        {
         arr_size = ArraySize(data.int_key);
         for(i=0; i<arr_size; i++)
           {
            if(data.int_key[i]==key)
              {
               data.int_la[i] = TimeLocal();
               return true;
              }
           }
        }
      else
         if(type_id==TYPE_DOUBLE)
           {
            arr_size = ArraySize(data.dbl_key);
            for(i=0; i<arr_size; i++)
              {
               if(data.dbl_key[i]==key)
                 {
                  data.dbl_la[i] = TimeLocal();
                  return true;
                 }
              }
           }
         else
            if(type_id==TYPE_DATETIME)
              {
               arr_size = ArraySize(data.dtm_key);
               for(i=0; i<arr_size; i++)
                 {
                  if(data.dtm_key[i]==key)
                    {
                     data.dtm_la[i] = TimeLocal();
                     return true;
                    }
                 }
              }
            else
              {
               Print(__FUNCTION__," Unknown key type specified ",type_id);
              }
   return status;
  }


//+------------------------------------------------------------------+
//|  Check Value by type                                             |
//+------------------------------------------------------------------+
bool Porcupine::checkValue(string value,string &key) //*
  {
   bool status = false;
   int i,arr_size;

   arr_size = ArraySize(data.str_value); //*

   for(i=0; i<arr_size; i++)
     {
      if(data.str_value[i]==value)  //*
        {
         data.str_la[i] = TimeLocal(); //*
         key = data.str_key[i]; //*
         return true;
        }
     }
   key = NULL;
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Porcupine::checkValue(int value,string &key) //*
  {
   bool status = false;
   int i,arr_size;

   arr_size = ArraySize(data.int_value); //*

   for(i=0; i<arr_size; i++)
     {
      if(data.int_value[i]==value)  //*
        {
         data.int_la[i] = TimeLocal(); //*
         key = data.int_key[i]; //*
         return true;
        }
     }
   key = NULL;
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Porcupine::checkValue(double value,string &key) //*
  {
   bool status = false;
   int i,arr_size;

   arr_size = ArraySize(data.dbl_value); //*

   for(i=0; i<arr_size; i++)
     {
      if(data.dbl_value[i]==value)  //*
        {
         data.dbl_la[i] = TimeLocal(); //*
         key = data.dbl_key[i]; //*
         return true;
        }
     }
   key = NULL;
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Porcupine::checkValue(datetime value,string &key) //*
  {
   bool status = false;
   int i,arr_size;

   arr_size = ArraySize(data.dtm_value); //*

   for(i=0; i<arr_size; i++)
     {
      if(data.dtm_value[i]==value)  //*
        {
         data.dtm_la[i] = TimeLocal(); //*
         key = data.dtm_key[i]; //*
         return true;
        }
     }
   key = NULL;
   return false;
  }




//+------------------------------------------------------------------+
//|  Delete key by type                                              |
//+------------------------------------------------------------------+
bool Porcupine::deleteKey(int type_id,string key)
  {
   int arrSize,i;
// status flag
   bool found = false;

   if(type_id==TYPE_STRING) //*
     {
      arrSize = ArraySize(data.str_key); //*

      for(i=0; i<arrSize; i++)
        {
         if(data.str_key[i]==key) //*
           {
            // key is found threfore marked the flag. array resize will
            // only be triggered if this is true
            found = true;

            // if the last element of the array, then no need to copy
            // back the last item to the current one
            if(i<(arrSize-1))
              {
               data.str_key[i] = data.str_key[arrSize-1]; //*
               data.str_value[i] = data.str_value[arrSize-1]; //*
               data.str_c[i] = data.str_c[arrSize-1]; //*
               data.str_la[i] = data.str_la[arrSize-1]; //*
              }
            // no need to loop further if key is found
            break;
           }
        }
      if(found)
        {
         if(ArrayResize(data.str_key,arrSize-1)==-1) //*
           {
            Print(__FUNCTION__," Array str_key Resize error GLE: ",GetLastError()); //*
            found = false;
           }
         if(ArrayResize(data.str_value,arrSize-1)==-1) //*
           {
            Print(__FUNCTION__," Array str_value Resize error GLE: ",GetLastError()); //*
            found = false;
           }
         if(ArrayResize(data.str_c,arrSize-1)==-1) //*
           {
            Print(__FUNCTION__," Array str_c Resize error GLE: ",GetLastError()); //*
            found = false;
           }
         if(ArrayResize(data.str_la,arrSize-1)==-1) //*
           {
            Print(__FUNCTION__," Array str_la Resize error GLE: ",GetLastError()); //*
            found = false;
           }
        }
     }

   else
      if(type_id==TYPE_INT) //*
        {
         arrSize = ArraySize(data.int_key); //*

         for(i=0; i<arrSize; i++)
           {
            if(data.int_key[i]==key) //*
              {
               // key is found threfore marked the flag. array resize will
               // only be triggered if this is true
               found = true;

               // if the last element of the array, then no need to copy
               // back the last item to the current one
               if(i<(arrSize-1))
                 {
                  data.int_key[i] = data.int_key[arrSize-1]; //**
                  data.int_value[i] = data.int_value[arrSize-1]; //**
                  data.int_c[i] = data.int_c[arrSize-1]; //**
                  data.int_la[i] = data.int_la[arrSize-1]; //**
                 }
               // no need to loop further if key is found
               break;
              }
           }
         if(found)
           {
            if(ArrayResize(data.int_key,arrSize-1)==-1) //*
              {
               Print(__FUNCTION__," Array int_key Resize error GLE: ",GetLastError()); //*
               found = false;
              }
            if(ArrayResize(data.int_value,arrSize-1)==-1) //*
              {
               Print(__FUNCTION__," Array int_value Resize error GLE: ",GetLastError()); //*
               found = false;
              }
            if(ArrayResize(data.int_c,arrSize-1)==-1) //*
              {
               Print(__FUNCTION__," Array int_c Resize error GLE: ",GetLastError()); //*
               found = false;
              }
            if(ArrayResize(data.int_la,arrSize-1)==-1) //*
              {
               Print(__FUNCTION__," Array int_la Resize error GLE: ",GetLastError()); //*
               found = false;
              }
           }
        }

      else
         if(type_id==TYPE_DOUBLE) //*
           {
            arrSize = ArraySize(data.dbl_key); //*

            for(i=0; i<arrSize; i++)
              {
               if(data.dbl_key[i]==key) //*
                 {
                  // key is found threfore marked the flag. array resize will
                  // only be triggered if this is true
                  found = true;

                  // if the last element of the array, then no need to copy
                  // back the last item to the current one
                  if(i<(arrSize-1))
                    {
                     data.dbl_key[i] = data.dbl_key[arrSize-1]; //**
                     data.dbl_value[i] = data.dbl_value[arrSize-1]; //**
                     data.dbl_c[i] = data.dbl_c[arrSize-1]; //**
                     data.dbl_la[i] = data.dbl_la[arrSize-1]; //**
                    }
                  // no need to loop further if key is found
                  break;
                 }
              }
            if(found)
              {
               if(ArrayResize(data.dbl_key,arrSize-1)==-1) //*
                 {
                  Print(__FUNCTION__," Array dbl_key Resize error GLE: ",GetLastError()); //*
                  found = false;
                 }
               if(ArrayResize(data.dbl_value,arrSize-1)==-1) //*
                 {
                  Print(__FUNCTION__," Array dbl_value Resize error GLE: ",GetLastError()); //*
                  found = false;
                 }
               if(ArrayResize(data.dbl_c,arrSize-1)==-1) //*
                 {
                  Print(__FUNCTION__," Array dbl_c Resize error GLE: ",GetLastError()); //*
                  found = false;
                 }
               if(ArrayResize(data.dbl_la,arrSize-1)==-1) //*
                 {
                  Print(__FUNCTION__," Array dbl_la Resize error GLE: ",GetLastError()); //*
                  found = false;
                 }
              }
           }

         else
            if(type_id==TYPE_DATETIME) //*
              {
               arrSize = ArraySize(data.dtm_key); //*

               for(i=0; i<arrSize; i++)
                 {
                  if(data.dtm_key[i]==key) //*
                    {
                     // key is found threfore marked the flag. array resize will
                     // only be triggered if this is true
                     found = true;

                     // if the last element of the array, then no need to copy
                     // back the last item to the current one
                     if(i<(arrSize-1))
                       {
                        data.dtm_key[i] = data.dtm_key[arrSize-1]; //**
                        data.dtm_value[i] = data.dtm_value[arrSize-1]; //**
                        data.dtm_c[i] = data.dtm_c[arrSize-1]; //**
                        data.dtm_la[i] = data.dtm_la[arrSize-1]; //**
                       }
                     // no need to loop further if key is found
                     break;
                    }
                 }
               if(found)
                 {
                  if(ArrayResize(data.dtm_key,arrSize-1)==-1) //*
                    {
                     Print(__FUNCTION__," Array dtm_key Resize error GLE: ",GetLastError()); //*
                     found = false;
                    }
                  if(ArrayResize(data.dtm_value,arrSize-1)==-1) //*
                    {
                     Print(__FUNCTION__," Array dtm_value Resize error GLE: ",GetLastError()); //*
                     found = false;
                    }
                  if(ArrayResize(data.dtm_c,arrSize-1)==-1) //*
                    {
                     Print(__FUNCTION__," Array dtm_c Resize error GLE: ",GetLastError()); //*
                     found = false;
                    }
                  if(ArrayResize(data.dtm_la,arrSize-1)==-1) //*
                    {
                     Print(__FUNCTION__," Array dtm_la Resize error GLE: ",GetLastError()); //*
                     found = false;
                    }
                 }
              }

            else
              {
               Print(__FUNCTION__," Unknow type id is provided");
              }

   return found;
  }

//+------------------------------------------------------------------+
//|  Set String to memory                                            |
//+------------------------------------------------------------------+
void Porcupine::setData(string key,string value)
  {
   int i,arr_size;
   arr_size = ArraySize(data.str_key);

   for(i=0; i<arr_size; i++)
     {
      if(data.str_key[i]==key)
        {
         data.str_value[i]    = value;
         data.str_c[i]        = TimeLocal();
         data.str_la[i]       = TimeLocal();
         return;
        }
     }
// element does not exist
// create new key value pair
   ArrayResize(data.str_key,arr_size+1);
   ArrayResize(data.str_value,arr_size+1);
   ArrayResize(data.str_c,arr_size+1);
   ArrayResize(data.str_la,arr_size+1);

   data.str_key[arr_size]     = key;
   data.str_value[arr_size]   = value;
   data.str_c[arr_size]       = TimeLocal();
   data.str_la[arr_size]      = TimeLocal();

   return;
  }


//+------------------------------------------------------------------+
//|  Set Integer to memory                                           |
//+------------------------------------------------------------------+
void Porcupine::setData(string key,int value)
  {
   int i,arr_size;
   arr_size = ArraySize(data.int_key);

   for(i=0; i<arr_size; i++)
     {
      if(data.int_key[i]==key)
        {
         data.int_value[i]    = value;
         data.int_c[i]        = TimeLocal();
         data.int_la[i]       = TimeLocal();
         return;
        }
     }
// element does not exist
// create new key value pair
   ArrayResize(data.int_key,arr_size+1);
   ArrayResize(data.int_value,arr_size+1);
   ArrayResize(data.int_c,arr_size+1);
   ArrayResize(data.int_la,arr_size+1);

   data.int_key[arr_size]     = key;
   data.int_value[arr_size]   = value;
   data.int_c[arr_size]       = TimeLocal();
   data.int_la[arr_size]      = TimeLocal();

   return;
  }


//+------------------------------------------------------------------+
//|  Set double to memory                                            |
//+------------------------------------------------------------------+
void Porcupine::setData(string key,double value)
  {
   int i,arr_size;
   arr_size = ArraySize(data.dbl_key);

   for(i=0; i<arr_size; i++)
     {
      if(data.dbl_key[i]==key)
        {
         data.dbl_value[i]    = value;
         data.dbl_c[i]        = TimeLocal();
         data.dbl_la[i]       = TimeLocal();
         return;
        }
     }
// element does not exist
// create new key value pair
   ArrayResize(data.dbl_key,arr_size+1);
   ArrayResize(data.dbl_value,arr_size+1);
   ArrayResize(data.dbl_c,arr_size+1);
   ArrayResize(data.dbl_la,arr_size+1);

   data.dbl_key[arr_size]     = key;
   data.dbl_value[arr_size]   = value;
   data.dbl_c[arr_size]       = TimeLocal();
   data.dbl_la[arr_size]      = TimeLocal();

   return;
  }


//+------------------------------------------------------------------+
//|  Set double to memory                                            |
//+------------------------------------------------------------------+
void Porcupine::setData(string key,datetime value)
  {
   int i,arr_size;
   arr_size = ArraySize(data.dtm_key);

   for(i=0; i<arr_size; i++)
     {
      if(data.dtm_key[i]==key)
        {
         data.dtm_value[i]    = value;
         data.dtm_c[i]        = TimeLocal();
         data.dtm_la[i]       = TimeLocal();
         return;
        }
     }
// element does not exist
// create new key value pair
   ArrayResize(data.dtm_key,arr_size+1);
   ArrayResize(data.dtm_value,arr_size+1);
   ArrayResize(data.dtm_c,arr_size+1);
   ArrayResize(data.dtm_la,arr_size+1);

   data.dtm_key[arr_size]     = key;
   data.dtm_value[arr_size]   = value;
   data.dtm_c[arr_size]       = TimeLocal();
   data.dtm_la[arr_size]      = TimeLocal();

   return;
  }

//+------------------------------------------------------------------+
//|  Get string from memory                                          |
//+------------------------------------------------------------------+
bool Porcupine::getData(string key,string &value)
  {
   int i,arr_size;
   arr_size = ArraySize(data.str_key);

   for(i=0; i<arr_size; i++)
     {
      if(data.str_key[i]==key)
        {
         value                = data.str_value[i];
         data.str_la[i]       = TimeLocal();
         return true;
        }
     }
   value = NULL;
   return false;
  }


//+------------------------------------------------------------------+
//|  Get int from memory                                             |
//+------------------------------------------------------------------+
bool Porcupine::getData(string key,int &value)
  {
   int i,arr_size;
   arr_size = ArraySize(data.int_key);

   for(i=0; i<arr_size; i++)
     {
      if(data.int_key[i]==key)
        {
         value                = data.int_value[i];
         data.int_la[i]       = TimeLocal();
         return true;
        }
     }
   value = NULL;
   return false;
  }


//+------------------------------------------------------------------+
//|  Get Double from memory                                          |
//+------------------------------------------------------------------+
bool Porcupine::getData(string key,double &value)
  {
   int i,arr_size;
   arr_size = ArraySize(data.dbl_key);

   for(i=0; i<arr_size; i++)
     {
      if(data.dbl_key[i]==key)
        {
         value                = data.dbl_value[i];
         data.dbl_la[i]       = TimeLocal();
         return true;
        }
     }
   value = NULL;
   return false;
  }


//+------------------------------------------------------------------+
//|  Get DateTime from memory                                        |
//+------------------------------------------------------------------+
bool Porcupine::getData(string key,datetime &value)
  {
   int i,arr_size;
   arr_size = ArraySize(data.dtm_key);

   for(i=0; i<arr_size; i++)
     {
      if(data.dtm_key[i]==key)
        {
         value                = data.dtm_value[i];
         data.dtm_la[i]       = TimeLocal();
         return true;
        }
     }
   value = NULL;
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Porcupine::searchData(string search,string &keys[],int data_type)
  {
   if(data_type==TYPE_STRING)
     {
      int arr_size = ArraySize(data.str_key); //

      for(int i=0; i<arr_size; i++)
        {
         if(startsWith(data.str_key[i],search)) //
           {
            int size = ArraySize(keys);
            ArrayResize(keys,size+1);

            keys[size]           = data.str_key[i]; //
           }
        }
     }

   else
      if(data_type==TYPE_INT)
        {
         int arr_size = ArraySize(data.int_key); //

         for(int i=0; i<arr_size; i++)
           {
            if(startsWith(data.int_key[i],search)) //
              {
               int size = ArraySize(keys);
               ArrayResize(keys,size+1);

               keys[size]           = data.int_key[i]; //
              }
           }
        }

      else
         if(data_type==TYPE_DOUBLE)
           {
            int arr_size = ArraySize(data.dbl_key); //

            for(int i=0; i<arr_size; i++)
              {
               if(startsWith(data.dbl_key[i],search)) //
                 {
                  int size = ArraySize(keys);
                  ArrayResize(keys,size+1);

                  keys[size]           = data.dbl_key[i]; //
                 }
              }
           }

         else
            if(data_type==TYPE_DATETIME)
              {
               int arr_size = ArraySize(data.dtm_key); //

               for(int i=0; i<arr_size; i++)
                 {
                  if(startsWith(data.dtm_key[i],search)) //
                    {
                     int size = ArraySize(keys);
                     ArrayResize(keys,size+1);

                     keys[size]           = data.dtm_key[i]; //
                    }
                 }
              }
            else
              {
               Print(__FUNCTION__," unknown data type.");
              }
  }

//+------------------------------------------------------------------+
//|  File OPen and read arrays for all types                         |
//+------------------------------------------------------------------+
bool Porcupine::fileOpen_StringArray(string filePath,string &read_arr[])
  {
   bool status = true;
   uint num_elements;
   int filehandle = FileOpen(filePath,FILE_TXT|FILE_READ);

   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," File ",filePath," open failed. GLE: ",GetLastError());
      status = false;
     }
   else
     {
      num_elements = FileReadArray(filehandle,read_arr);

      if(num_elements==0)
        {
         Print(__FUNCTION__," File Array ",filePath," read array failed. GLE: ",GetLastError());
         status = false;
        }
      FileClose(filehandle);
     }
   return status;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Porcupine::fileOpen_IntArray(string filePath,int &read_arr[])
  {
   bool status = true;
   uint num_elements;
   int filehandle = FileOpen(filePath,FILE_BIN|FILE_READ);

   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," File ",filePath," open failed. GLE: ",GetLastError());
      status = false;
     }
   else
     {
      num_elements = FileReadArray(filehandle,read_arr);

      if(num_elements==0)
        {
         Print(__FUNCTION__," File Array ",filePath," read array failed. GLE: ",GetLastError());
         status = false;
        }
      FileClose(filehandle);
     }
   return status;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Porcupine::fileOpen_DoubleArray(string filePath,double &read_arr[])
  {
   bool status = true;
   uint num_elements;
   int filehandle = FileOpen(filePath,FILE_BIN|FILE_READ);

   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," File ",filePath," open failed. GLE: ",GetLastError());
      status = false;
     }
   else
     {
      num_elements = FileReadArray(filehandle,read_arr);

      if(num_elements==0)
        {
         Print(__FUNCTION__," File Array ",filePath," read array failed. GLE: ",GetLastError());
         status = false;
        }
      FileClose(filehandle);
     }
   return status;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Porcupine::fileOpen_DateTimeArray(string filePath,datetime &read_arr[])
  {
   bool status = true;
   uint num_elements;
   int filehandle = FileOpen(filePath,FILE_BIN|FILE_READ);

   if(filehandle==INVALID_HANDLE)
     {
      Print(__FUNCTION__," File ",filePath," open failed. GLE: ",GetLastError());
      status = false;
     }
   else
     {
      num_elements = FileReadArray(filehandle,read_arr);

      if(num_elements==0)
        {
         Print(__FUNCTION__," File Array ",filePath," read array failed. GLE: ",GetLastError());
         status = false;
        }
      FileClose(filehandle);
     }
   return status;
  }

//+------------------------------------------------------------------+
//|  data list functions                                             |
//+------------------------------------------------------------------+
void Porcupine::listAll(void)
  {
   listString();
   listInt();
   listDouble();
   listDateTime();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Porcupine::listString(void)
  {
   int arrSize,i;
   arrSize = ArraySize(data.str_key);//*
   Print("---String data---");//*

   for(i=0; i<arrSize; i++)
     {
      PrintFormat("%s , %s , %s , %s",data.str_key[i],data.str_value[i],TimeToStr(data.str_c[i]),TimeToStr(data.str_la[i]));//*****
     }
   Print("----");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Porcupine::listInt(void)
  {
   int arrSize,i;
   arrSize = ArraySize(data.int_key);//*
   Print("---Int data---");//*

   for(i=0; i<arrSize; i++)
     {
      PrintFormat("%s , %i , %s , %s",data.int_key[i],data.int_value[i],TimeToStr(data.int_c[i]),TimeToStr(data.int_la[i]));//*****
     }
   Print("----");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Porcupine::listDouble(void)
  {
   int arrSize,i;
   arrSize = ArraySize(data.dbl_key);//*
   Print("---Double data---");//*

   for(i=0; i<arrSize; i++)
     {
      PrintFormat("%s , %s , %s , %s",data.dbl_key[i],DoubleToStr(data.dbl_value[i],4),TimeToStr(data.dbl_c[i]),TimeToStr(data.dbl_la[i]));//*****
     }
   Print("----");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Porcupine::listDateTime(void)
  {
   int arrSize,i;
   arrSize = ArraySize(data.dtm_key);//*
   Print("---DateTime data---");//*

   for(i=0; i<arrSize; i++)
     {
      PrintFormat("%s , %s , %s , %s",data.dtm_key[i],TimeToStr(data.dtm_value[i]),TimeToStr(data.dtm_c[i]),TimeToStr(data.dtm_la[i]));//*****
     }
   Print("----");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Porcupine::startsWith(string in_value,string search)
  {
   int count = StringLen(search);

   if(StringSubstr(in_value,0,count)==search)
      return true;
   else
      return false;
  }


//+------------------------------------------------------------------+
