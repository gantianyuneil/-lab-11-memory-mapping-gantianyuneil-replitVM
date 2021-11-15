Memory Mapping
===

In this lab you will use memory mapping and demand paging to edit a
file on disk by manipulating memory locations.

Requirements
---

You must use `mmap()` to map an image file into your process's address
space, then transform that file to turn white pixels black and black
pixels white.  The image file is exactly 4096 bytes in size, and the
image data is stored from the 50th byte to the 4096th byte.  White
bits will be represented with an ASCII 0 character, and black bits
will be represented with an ASCII 1 character.

All of your changes must be to the file `invert.c`.  You will probably
implement them in the `main()` function, and they amount to only a few
lines of code.

Your program must:

 * Open the file given as `argv[1]` using the `open()` system call;
   this code has been provided for you.
 * Use `mmap()` to map the open file into your program's address
   space.
 * Manipulate the mapped memory to change every `'0'` to `'1'`, and
   vice-versa, in the appropriate range.

Due to the way that we are using `mmap()`, you do not need to either
close the file or unmap the memory used by `mmap()`.  When your
program exits, both of these things will be handled by the operating
system.

Understanding `mmap()`
---

The `mmap()` system call is _one of the most complicated in a POSIX
system_.  It has six arguments, two of which are flag fields that
change its behavior in significant ways.  It deals in raw memory
addresses and involves both memory and file I/O.  Fortunately, we are
not going to need most of its complicated functionality.

```
#include <sys/mman.h>

void *mmap(void *addr, size_t length, int prot,
           int flags, int fd, off_t offset);
```

The basic purpose of mmap is to create a _m_emory _map_ping.  This
mapping can optionally be _backed_ by a file on disk, shared between
different processes on the system, placed at a user-selected location
in the process's address space, _etc._ We are going to create a
file-backed _single page_ of memory that is shared with other
processes (in this case, via the contents of that file) at an address
of the operating system's choosing.

The return value of `mmap()` is an address representing the first byte
of a successful mapping.  If the operation fails, it will return
`MAP_FAILED`, which is a pointer equal to the unsigned pointer-sized
integer value -1.  On our x86-64 Linux system, this address will
always be page-aligned and the mapping (regardless of the size
requested) will always an integral number of pages in size.

Let's consider each of the arguments to `mmap()`:

 * `addr`: This is the _virtual address_ at which we want to create a
   mapping.  We don't care, so use `NULL`.
 * `length`: This is the total size of the mapping, in bytes.  In our
   case we want to map the entire file, which has been sized to be
   _exactly one page_.  We know from lecture that pages on x86-64
   Linux are 4 KB, or 4096 bytes.
 * `prot`: This is the _protection_ with which the page is mapped.
   There are several possible values for this.  As discussed in
   lecture, pages can have many permissions associated with them,
   including readable, writable, and executable.  In our case we want
   the page to be readable (`PROT_READ`) and writable
   (`PROT_WRITE`).  This field is a bit mask, so the permissions
   should be combined with bitwise OR.
 * `flags`: The flags are the most complicated part of `mmap()`, in
   part because there are often many platform-specific possibilities.
   We want to use only a single flag, however, to indicate that we
   want changes to our memory mapping to be visible to the rest of the
   system.  Since our mapping is going to be bound to a file on disk,
   this means that changes to the memory mapping _will show up in the
   file on disk, automatically_.  To achieve this, we must use the
   flag `MAP_SHARED`.  There are many possible flags, but only a few
   are defined in POSIX; typically mappings will use `MAP_SHARED` or
   `MAP_PRIVATE` (which indicates that the mapping is private to the
   current process) and few or no additional flags.  The bulk
   allocator in your malloc project uses `MAP_PRIVATE`.
 * `fd`: This is a _file descriptor_ representing a file on disk that
   will be used to provide page backings for the mapping.  If this
   mapping is set to `MAP_PRIVATE`, then pages will be read in from
   the file represented by `fd` as they are read, but writes to memory
   will not be reflected in the file.  If it is set to `MAP_SHARED`,
   then changes to the memory in the mapping will automatically change
   the file on disk.
 * `offset`: This parameter modifies the `fd` option, by mapping only
   the portion of the file on disk _after_ skipping `offset` bytes at
   the beginning of the file.  This offset **must** be a multiple of
   the system page size.  We want to map the entire file, so we will
   use zero for this offset.

Once we have mapped a file into memory using `mmap()`, it will return
an address in memory representing the contents of that file.  If we
have mapped the file correctly, changes to the memory will change the
file on disk!  You will not have to perform any reads or writes, the
file contents will simply be available to your program at the returned
memory location, and changes to that memory will automatically be
pushed to the file by the operating system.

The PBM Image Format
---

You may find this information helpful for understanding what your
program is doing, and how to debug it.

The image files you have been provided with are in "plain PBM" format.
PBM stands for _Portable BitMap_, and is a simple format that was
originally intended to facilitate image interchange between
architecturally different hardware and operating systems.  It has a
very simple, well-defined, but forgiving format.  The "plain" format
that we are using MUST start with exactly the ASCII characters `P1`
followed by an ASCII whitespace character (space, tab, carriage
return, or line feed).  It must then contain two integers represented
in ASCII (like the arguments to your command-line calculator, or the
generation number in `life`) representing the X and Y dimensions of
the image, separated and followed by whitespace.

These three values (P1, X size, and Y size) represent the _header_ of
the image file.  After that comes the image data.  The image data is
simply X times Y ASCII 1 (for black) or 0 (for white) characters.
Whitespace between these characters is ignored, although it is common,
where possible, to arrange them as X characters in a row by Y rows of
text.

Any line in the file that starts with an ASCII `#` is ignored up until
the next ASCII newline character.  This can be used to insert comments
in the image.  These comments can occur either in the header or in the
image pixel data.

An example image, consisting of a 5x5 hollow black box with a
single black pixel in the center, looks like this:

```
P1 5 5
11111
10001
10101
10001
11111
```

The example images that you have been given are all 70x57 pixels in
size, and their header is exactly 49 bytes in size.  This is because
each row of the image is 71 bytes (70 zero or one bytes, followed by a
single newline) times 57 rows, which yields 4047 bytes; 4047 + 49 is
4096, which is exactly one page of memory.  These 49 bytes contain the
three values for the image header as well as a comment to pad out the
required space.

You can view the image data by simply opening them in your editor or
printing them to the terminal with `cat`.  You can view them _as
images_ by using the program `gpicview` installed on your virtual
machines.  Emacs understands PBM images, so opening the image in Emacs
will display it as an image file; pressing `C-c C-c` will allow you to
edit it as text, and pressing `C-c C-c` again will show you the edited
image.

Building and Testing
---

You can compile your code with `make` or `make invert`.

You have been provided with seven input files.  The files `white.pbm`
and `black.pbm` are pure white and pure black images, respectively;
the others have some sort of recognizable image content.

The source images _are set to be read-only_ when you build your
`invert` executable.  This means that if you try to access them
directly using your program, you will get an error like `error opening
file 'images/white.pbm'`.  This is to prevent you from inadvertently
corrupting your source images.

The command `make test` will invert the white and black images, and
compare the results to the black and white images, respectively.  You
can also run `make image-inverted.pbm`, where `image` is any of the
images in `images/`, and the makefile will automatically copy the
image, make the copy writable, and then run `invert` on it.

You may find the program `meld`, which can show the visual difference
between two files, useful for debugging your implementation.  By
running (for example) `meld white-inverted.pbm images/black.pbm` you
can see the difference between your inverted white bitmap and the
black provided bitmap (which should be identical).

The `gpicview` and Emacs editing modes mentioned in the previous
section will also let you view the differences in images by eye.

Submission
---

Submit only the file `invert.c` to Autograder.

Grading
---

Your code will be graded as follows:

 * 1 pt: `mmap()` is called correctly
 * 1 pt: Some change is made to the mapped file
 * 3 pts: The mapped file is inverted correctly, and the header is not altered
