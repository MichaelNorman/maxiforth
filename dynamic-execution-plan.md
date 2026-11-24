# Plan of work for dynamic execution of code

1. ~~Load the Windows memory functions from the DLL and expose them as words~~
2. ~~Set up a separate target for the dynamically allocated routines to make them available as binary data.~~
3. ~~Write the "Hello, dynamic world!" routine and assemble it.~~
4. ~~Package the binary data.~~
5. ~~Load, bless, and run the data.~~

# Plan of work for Windows infra code

1. ~~Decide on memory layout for protected memory: I choose manual layout because this is a compile-time activity with low need for generalizing.~~
2. ~~Move assembly Windows callback infra into winstubs.asm.~~
3. Remove current dynamic execution test code.
4. Write word to get stub per-word callback code (thunk & trampoline)