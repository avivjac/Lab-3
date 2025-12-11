#include <stdio.h>
#include <stdlib.h>

// Global variables
FILE *infile = NULL;            // Input file (will be set to stdin by default)
FILE *outfile = NULL;           // Output file (will be set to stdout by default)
int debug_mode = 1;      // Default: debug mode is ON
unsigned char password[] = "Avivjac";  // Password for +D{password}
unsigned char encoding_key[256] = "0";    // Encoding key (default "0" = no change)
int encoding_mode = 0;                   // 0 = no encoding, 1 = add, -1 = subtract
int encode_pos = 0;              // Current position in encoding key
int encoding_length = 1;             // Length of encoding key

// Function to encode a single character
unsigned char encode(unsigned char c) {
    unsigned char key_digit = encoding_key[encode_pos];
    int key_value = key_digit - '0';
    
    encode_pos++;
    if (encode_pos >= encoding_length) {
        encode_pos = 0; 
    }
    
    if (encoding_mode == 0) {
        return c;
    }
    
    unsigned char result = c;
    
    if (c >= '0' && c <= '9') {
        int digit_value = c - '0';  
        if (encoding_mode == 1) {
            digit_value = (digit_value + key_value) % 10;
        } else if (encoding_mode == -1) {
            digit_value = (digit_value - key_value + 10) % 10;
        }
        result = '0' + digit_value;  
    }
    else if (c >= 'A' && c <= 'Z') {
        int letter_value = c - 'A';  
        if (encoding_mode == 1) {
            letter_value = (letter_value + key_value) % 26;
        } else if (encoding_mode == -1) {
            letter_value = (letter_value - key_value + 26) % 26;
        }
        result = 'A' + letter_value; 
    }
    
    return result;
}

int main(int argc, char **argv) {
    infile = stdin;  
    outfile = stdout;
    
    int i;
    
    for (i = 1; i < argc; i++) {
        // -D Case
        if (argv[i][0] == '-' && argv[i][1] == 'D' && argv[i][2] == '\0') {
            debug_mode = 0; 
            
            continue;
        }
        // +D Case
        else if (argv[i][0] == '+' && argv[i][1] == 'D') {
            int j = 2;  
            int match = 1;  
            int idx = 0; 
            
            while (password[idx] != '\0' && argv[i][j] != '\0') {
                if (password[idx] != argv[i][j]) {
                    match = 0;  
                    break;
                }
                idx++;
                j++;
            }
            
            if (match && password[idx] == '\0' && argv[i][j] == '\0') {
                debug_mode = 1;  // debug mode ON
            }
            continue;  
        }
        // +E Case
        else if (argv[i][0] == '+' && argv[i][1] == 'E') {
            int j = 2;  
            int idx = 0;
            
            while (argv[i][j] != '\0' && idx < 255) {
                if (argv[i][j] >= '0' && argv[i][j] <= '9') {
                    encoding_key[idx] = argv[i][j];
                    idx++;
                    j++;
                } else {
                    break;
                }
            }
            encoding_key[idx] = '\0';  // Null terminate
            encoding_length = idx;
            if (encoding_length == 0) {
                encoding_key[0] = '0';  
                encoding_length = 1;
            }
            encoding_mode = 1; 
            encode_pos = 0; 
            continue; 
        }
        // -E Case
        else if (argv[i][0] == '-' && argv[i][1] == 'E') {
            int j = 2;  
            int idx = 0;
            
            while (argv[i][j] != '\0' && idx < 255) {
                if (argv[i][j] >= '0' && argv[i][j] <= '9') {
                    encoding_key[idx] = argv[i][j];
                    idx++;
                    j++;
                } else {
                    break;
                }
            }
            encoding_key[idx] = '\0';  // Null terminate
            encoding_length = idx;
            if (encoding_length == 0) {
                encoding_key[0] = '0';  
                encoding_length = 1;
            }
            encoding_mode = -1;  
            encode_pos = 0;  
            continue; 
        }

        // -i Case
        else if (argv[i][0] == '-' && argv[i][1] == 'i') {
            infile = fopen(&argv[i][2], "r");
            if (infile == NULL) {
                fprintf(stderr, "Error: cannot open input file %s\n", &argv[i][2]);
                exit(1);
            }
            continue;
        }

        // -o Case 
        else if (argv[i][0] == '-' && argv[i][1] == 'o') {
            outfile = fopen(&argv[i][2], "w");
            if (outfile == NULL) {
                fprintf(stderr, "Error: cannot open output file %s\n", &argv[i][2]);
                exit(1);
            }
            continue;
        }

    }
    
    // Print AFTER processing all arguments
    if (debug_mode) {
        for (i = 0; i < argc; i++) {
            fprintf(stderr, "%s\n", argv[i]);  
        }
    }
    
    int c;  
    
    while (1) {
        c = fgetc(infile);
        
        // End condition
        if (c == EOF || feof(infile)) {
            break;  
        }
        
        c = encode((unsigned char)c);
        fputc(c, outfile);
    }
    
    if (outfile != stdout) {
        fclose(outfile);
    }
    if (infile != stdin) {
        fclose(infile);
    }

    return 0;
}


