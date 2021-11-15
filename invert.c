#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>

#define FILESIZE 4096

int main(int argc, char *argv[]) {
    int fd;

    if (argc != 2) {
        fprintf(stderr, "usage: invert <filename>\n");
        exit(1);
    }

    if ((fd = open(argv[1], O_RDWR)) < 0) {
        fprintf(stderr, "error opening file '%s'\n", argv[1]);
        exit(1);
    }

    /* Your implementation should go here */

    return 0;
}
