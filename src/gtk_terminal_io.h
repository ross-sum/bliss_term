#include <errno.h>
#include <unistd.h>

   
/* Write the buffer, data out the device. len is the number of
   valid characters in the buffer to write. */
int WriteFD(int fd, char *data, int len);

// data is something like: unsigned char data[80];
// returns the number of bytes read.  If there is no data yet, then
// 0 is returned.
int ReadFD(int fd, char *data, int length);
