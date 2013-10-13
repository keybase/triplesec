#ifndef _WARN_H_
#define _WARN_H_

#ifdef HAVE_ERR_H
#include <err.h>
#else
#define NEED_WARN_PROGNAME
const char * warn_progname;
void warn(const char *, ...);
void warnx(const char *, ...);
#endif

#include <stdint.h>
#include <inttypes.h>

void dump_buf(const char *what, uint8_t *a, size_t l);

#endif /* !_WARN_H_ */
