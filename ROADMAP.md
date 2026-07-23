# maxiForth roadmap

## Direction
maxiForth is a prototype for firstForth, the Forth that will accompany a book and/or YouTube series. As such, its
development has a natural end: When it's complete enough that firstForth can be developed so that its commits follow the
lesson/book plan by commit. firstForth, and therefore maxiForth, are meant to be languages for "getting work done" on
your computer, a sort of thinking curmudgeon's Python. Certain things need to be demonstrated in maxiForth to meet that
goal.

Here are the user stories that I think get maxiForth across this finish line:
* Text processing and without compiling an entire regex library into your Forth. The tool to reach for is DLL-loading to
discover, loads and use the libary.
* Using the Clay layout library to do window layout.
* Programming Windows natively.

Text processing will, in the scenario laid out, would require DLL loading, but likely not callbacks. While Clay can be
compiled right into Forth, it still needs to call back into your code for a few things, text measurement among them. The
Windows programming story involves bots DLLs and heayv usage of callbacks.

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

### 4) `do...leave...loop/+loop`

#### Status
maxiForth relies on `begin...while/until...repeat` for all of its looping. Certain calculations require a bit of
trickery if you want to exit early.

#### Feature(s)
Basic `do...loop/+loop` is fairly straightforward, accepting a limit range and, in the case of a `+loop` a step.
Internally, `loop` pushes `1` for the step and just calls `+loop`, a convenience that saves the programmer some typing.
The real trickery comes in when you try to `leave` a loop. You need to thread bread crumbs through the memory locations
that `leave` will use at run time to break out, which means writing the address of the previous `leave` into the address
"hole" that is waiting for the final offset. Then the compile step has to walk those addresses, destructively writing
offsets to the end of the loop at each step before jumping to the previous `leave`.

I almost forgot! the complication of having `+loop`, which can walk *down* past a *lower bound*, is that it all but
necessitates implementing a sign crossing check on a difference, rather than a straight limit comparison. It's a pain. I
have to look up how to do it each time. This is why I'm putting it off until I either need it or can no longer put up
with the embarrassment. I am not easily embarrassed, at least not in this case.

## Conclusion
This work, and the rewrite and Linux port, will happen in parallel with the book, YT series, Linux port, and other
efforts.
