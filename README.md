## License

- **Code:** MIT (see LICENSE). Use it freely in your own projects.

## Name

"maxiForth" is the name of this project. The MIT License covers the code, not this name. Please
don't publish forks, mirrors, repackagings, or derivative courses under
the "maxiForth" name, or in any way that suggests they
are the original or are endorsed by the author. Rename your fork and you're
free to do as the license allows.

## Overview

maxiForth responds to a line of input with "` ok\n`." Here's a basic session:
```
3 5 +<ENTER> ok
.<ENTER>
8 ok
: cr 10 emit ;<ENTER> ok
i" Hello, world!" const greeting<ENTER> ok
greeting cr type<ENTER>
Hello, world! ok
var message !<ENTER> ok
greeting message !<ENTER> ok
message @ cr type<ENTER>
Hello, World! ok

```
Don't let the trivial example fool you. You can write applications in maxiForth.

maxiForth is a prototype for an unconventional indirect threaded code (ITC) Forth that strives to see how
much one can do with the  smallest amount of assembly that is (reasonably) possible. Forths are little
languages that are (mostly) intended to be (mostly) hand-built from assembly, bootstrapping up to a real
"high level" programming language and giving you access to your "system." Typically, that system is a new
piece of hardware on which you want to do things like, well, whatever hardware testers do. maxiForth sits
inside your operating system, for better or for worse, rather than atop bare metal. Your OS is maxiForth's
"system." maxiForth is close to "complete," which is a hard word to define for a language that you're
intended to develop on your own, add new words in assembly when you have to, and can add new words in Forth
essentially at will.

I have been pragmatic in maxiForth's development. For example, I haven't been above calling out to `printf`
to get things going, and the interpreter IO is accomplished with `_getch` and `_putch` at the command line,
but with `fgets` for file input. Some of this is a consequence of maxiForth's "system" including the C
runtime environment.

### Some useful words
#### include <file>

`include` treats the rest of its input line as a file name and opens a file. When it fails, it does so silently,
except to complain if you've nested your `include`d files too deeply. As in 17 or more deep, which ought to be
enough. It's up to you to get your file names right.

#### swap, dup, rot, nip, tuck, 2dup, and the rest of the stack bestiary

These, and possibly a few more, stack manipulation words let you duplicate stack entries, swap the top 2, rotate
the top 3, and so on. Type "Forth stack words" into any search engine, or ask an LLM about them, and you'll
get an adequate explanation. If not, you can muscle up and read the source. It's not that bad.

#### pause

This is a handy one for debugging. Drop it into a misbehaving word definition and start maxiForth in debug mode.
`pause` just issues an `int3`, suspending execution. Many a bug in maxiForth was tracked down by bisecting with
`pause`!

### The big ones: `:` and `;`

Forths are both interpreters and compilers. Juxtaposition is composition, so you can cut programs up pretty much
any way you like. Forth takes advantage of this with the `:` and `;` words, which start and finish compilation,
respectively, of new words. Forth has no native way to square integers. If this is a useful thing to have for your
problem, you can do:

```
: sq dup * ;
```
This defines a new word, called `sq`, that duplicates whatever is on top of the stack--It's a 64-bit word--multiplies
the copies together, and puts the result back on the stack. (Overflow is your responsibility, as it always is.) If
you think that `dup 1 + *` is too difficult to remember for `n(n+1)`, you could use `sq` in another definition, like
so:
```
: sqpl dup sq + ;
```
Let there be light, or at least a few sparks. With that ability to compose functions, there is little you can't do.

### Some missing things, coming soon

* Compile-time strings. The current string word is `i"`, for "interpreter string." Trying to use `i"` in a colon
  definition will not produce the expected results.
* DLL loading and discovery. This is the big one. Your system includes DLLs. You are a serious Forth programmer. You
  should be able to load a DLL up, figure out how it works, and start defining words to make calls.
* Dynamic dictionary sizing and bounds checks. Currently, you can define yourself right off the end of the dictionary,
  if you want, overwriting whatever comes after it. Eventually, compilation might check for the edge of the world
  coming and allocate you some extra space. Maybe. Or, you could do it yourself. Really. YAGNI.
* `do...loop/+loop`. Technically, `begin...while/until...repeat` gets you Turing completeness, up to certain
  off-by-one concerns. YAGNI, but ergonomic.
* Crash-only dictionary persistence. There is no way to persist your dictionary. The recommended practice is to
noodle around at the interactive prompt and copy your work into a file that you load at startup to get those
definitions into your dictioary. (Just add a line to the end of `init.forth`. Maybe I'll feel generous one day and
write a hook for a `custom.forth` file, but I don't think Chuck Moore would approve. YAGNI, after all.)

## Prerequisites

I wrote and built this Forth on CLion from JetBrains Software, which you can download free
for non-commercial use. You can find documentation, download links, and installation instructions
here: [JetBrains CLion](https://www.jetbrains.com/clion/). If you can tolerate the command line,
and if you can tolerate Microsoft, you can also use VS Code. Building and debugging will be slightly
trickier.

I wrote the core Forth runtime in The Netwide Assembler (nasm or NASM, for short) an open source
assembly language for the x86 CPU architecture. You can find documentation, download links, and
installation instructions  here: [The Netwide Assembler](www.nasm.us). While Clion is a nice-to-have,
you must have a working installation of NASM on your machine to build and run maxiForth.

## Building and running maxiForth

maxiForth is a command-line application. You can enter Forth words, as they are called, from the
prompt after you change to the appropriate directory and do `.\maxiForth.exe`.

To be able to do that, you need to be able to build it. That's easy enough to do in Clion, and I leave it to
your initiative to figure it out. Here's something that might work from the command line if you need it:

```
cmake -B cmake-build-debug
cmake --build cmake-build-debug
```

If nothing happens, try `cmake --build cmake-build-debug --clean-first --verbose`.

## Conclusion, sorta

It's late, and I should be in bed. Forth has a long and rich history. Some of it is even useful for using and
understanding maxiForth. But I think I warned you it was idiosyncratic in the introduction. I've eschewed the
complications of ANS Forth. I haven't even looked at the internals of an of the other Forths out there. I did
all this by chatting with LLMs that were explicitly forbidden from giving me code solutions unless I asked for
them directly, which I only did to resolve bugs that escaped my sleuthing and patience. In short, you're not
always going to get the best answers from chatbots or the internet concerning how to program in maxiForth unless
you put the sources into the context. Enjoy it. Poke around. Oh! Definitely open `init.forth` and give it a
good long study. It's far from a magnum opus, but it's really cool to see the `'` keyword laid down with the `,`
word, then get immediately used to make the `create` word, and then bootstrap up an eminently usable Forth.

Above all, check back for updates!