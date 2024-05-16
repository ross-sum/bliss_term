#include "gtk_terminal_io.h"
/*
#include <errno.h>
#include <unistd.h>
*/

/* Write the buffer, data out the device. len is the number of
   valid characters in the buffer to write. */
int WriteFD(int fd, char *data, int len)
{
   int wlen;  // total number of bytes actually written
   
   wlen = write(fd, data, len);
   if (wlen != len) {
      //printf("Error from write: %d, %d\n", wlen, errno);
      return -errno;
   }
   return 0;
}

// data is something like: unsigned char data[80];
// returns the number of bytes read.  If there is no data yet, then
// 0 is returned.
int ReadFD(int fd, char *data, int length)
{
   int rdlen;
   if (length > 1) {
      rdlen = read(fd, data, length -1);  // sizeof(data) - 1);
   } 
   else {
      rdlen = read(fd, data, length);
   }
   if ((rdlen > 0 ) && (length > 1)) {
      data[rdlen] = 0;  // ensure null terminated if possible
   }
   // If rdlen < 0 then error.  If == 0 then no data yet (time-out).
   return rdlen;
}
