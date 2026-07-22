# maxiForth roadmap

## Direction
maxiForth is a prototype for firstForth, the Forth that will accompany a book and/or YouTube series. As such, its
development has a natural end: When it's complete enough that firstForth can be developed so that its commits follow the
lesson/book plan by commit. firstForth, and therefore maxiForth, are meant to be languages for "getting work done" on
your computer, a sort of thinking curmudgeon's Python. Certain things need to be demonstrated in maxiForth to meet that
goal. One user story involvew wanting to do text processing and not wanting to compile an entire regex library into your
Forth. The tool to reach for is DLL-loading. The user compiles an existing regex library to a DLL, then discovers,
loads, and uses it to accomplish their text processing tasks. There's actually a family of user stories there. Using the
Clay layout library to do window layout. And so on. Another story involves programming windows, which will require a
facility for receiving callbacks.

The natural tension here is that the design philosophy of Forth, or at least of Chuck Moore, is against "general
purpose" languages. I personally don't currently have the problem of receiving callbacks from Windows. The justification
therefore has to be something along the lines of, "I need to demo these capabilities for my audience." Take the items in
the "Demo features" section in that spirit, as demos that "don't count" toward "being Forth." If any Forth programmer
can do them, then they're almost not Forth, by definition, but rather somebody's "problem" to solve.

The features are deliberately underspecified.

## Demo features

### 1) Heap strings
#### Status quo
The `i"` string creation word currently creates a word at runtime and puts its address onto the stack. The current best
practice for strings in definitions is to first put your string into a constant, like
```
i" \nError: BAD THING!\n" const bad-thing-err-str
```
Then use `bad-thing-err-str` in your definition. However, these strings are allocated in the dictionary inside the
program image. The dictionary is essentially a one-time arena that never gets deallocated. That's fine for small
systems that would fit inside a microcontroller for a washing machine, but problematic for something like an e-book
reader, word processor, or what have you.

#### Feature
Strings that are allocated on the heap. The `h"` word takes a variable from the stack and saves its string pointer to
it after it's done reading. The variable lives forever, but the string can be freed with `var-free`, which both checks
for 0 before freeing. It aborts with an error if you encounter a `0` in the variable.

### 2) Runtime DLL loading
#### Status quo
DLL access is through import library files at compile time, if that's what you want to do.

#### Feature
Wrap `LoadLibrary` and `GetProcAddress`, write a word that creates words to call into that library, marshalling the
data as required. This will allow runtime loading and use of DLLs.

### 3) Callbacks
#### Status quo
There is no facility for calling back into Forth.

#### Feature
This one will initially be Windows-centric, since that was the development platform. The steps for handling a callback
are:

1. Push callee-saved registers onto the stack.
2. Load your preserved (by your call) Forth state into `r12`-`r15`.
3. Move the ABI argument register values onto the stack.
4. Write the handler's XT into a two-cell trampoline that has a return-to-C word in its final position
5. In the return-to-C word: pop the handler's result off the stack into the ABI return register. Write updated PSP/RSP
   into the sahred save area, pop the callee-saved registers, and `ret`

I'm pretty sure most of that is right.

## Conclusion
This work will happen in parallel with the book, YT series, Linux port, and other efforts.
