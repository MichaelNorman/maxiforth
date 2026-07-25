# A Guide to `init.forth`

## Introduction

`init.forth` is the code file that bootstraps Forth from a working but minimal core to a "real" Forth. As a *kernel*, maxiForth lacks many of the amenities that make Forth a comfortable working environment, including basic words like `'`, `create`, `:`, `;`, and so on. This is deliberate in order to keep the size of the kernel as small as is reasonable, because the kernel is what must be rewritten for whatever architecture you are targeting next. However, it does mean that `init.forth` starts out with some pretty unconventional Forth code. It's a little like rubbing two sticks together to make fire, in this regard, except more difficult to follow. Possibly the most keenly felt absence is that of `\`, or some other comment character, as it means the file itself cannot be commented until after the comment character gets its (pretty basic) behavior of moving the input location to the end of the buffer and letting the kernal take over to skip you to the next line. It is this absence, more than any other, that motivates the current discussion; this could be titled, **init.forth: The Missing Documentation**.

As we pass through the various stages of documenting `init.forth`, we'll actually develop a very good understanding of the dictionary layout, how Forth words are run, and especially the layout of a Forth word in memory. It is often said that the data are more important than the code, for if you are shown code without data, you'll have no idea what's going on. However, if you're shown the data and it is explained to you, you'll be in such a good position that you could almost write the code yourself. Inasmuch as one of my goals is to get as many people as possible to experience the enlightenment of writing a Forth of their own from scratch, the lack of the `\` word in `init.forth` is a most welcome serendipity!

## Interpretation and compilation

Forth is both an interpreter and a compiler; you build programs by defining words at the same interactive prompt that you run them from. This differs from other languages, where there is usually only an interpreter or a compiler. In C, for example, you write source files and call the compiler and linker to produce an executable. Compilers could output machine code directly, but they ofen output assembly code, which then gets "assembled" into the final program. This Forth, and ones that you build if you take up the challenge, will be built in assembly, so you'll get to experience the write-compile divide directly. In Forth, you compile directly with the `:` and `;` words right at the interpreter prompt.

On the other end of the spectrum are interpreted languages like Python, JavaScript, BASIC, and others. In these languages, your code is run by a program called an interpreter. In a pure interpreter, your code is broken up into its parts as the interpreter sees the parts and immediately translated into something the computer can run. There is no separate compiler to turn your text into a separate binary. In Forth, you enter words at the Forth prompt or write Forth into files and point the interpreter at them with `include`. In either case, your words are looked up by the interpreter and run.

One of the first goals of `init.forth` is to create the compilation words `:` and `'`.

## The format of a forth word

`init.forth` begins rather cryptically with a line that lays items down directly and quite literally into memory using, among others, the `,` word. The items being laid down are in the format of the header of a Forth word. This format looks like:

```[*prev(8)][mask(0.3)][len(0.5)][char[31]][CFA(8)][0(8)]...```

The bits in parentheses are bytes and fractional bytes (bits). So, `8` represents a 64-bit word, and `0.3` represents three bits. In words, a dictionary entry is a 64-bit pointer to the previous entry, three bits of masks, five bits specifying the length of a 31-byte (248-bit) string, said string, a 64-bit code field address (CFA), and 64-bits of 0s. Semantically, it's a previous pointer, a masked word-length word string, an address of the action to take for the word, and a reserved word for future use. The title of this section is **The Format of a Forth Word**, and I've only given you the header, so far. The rest of a word goes:

```...[P(64)][P(64)]...```

We take "P" to stand for "parameter." This region of the word is the parameter field, and it begins at the parameter field address (PFA). The parameter field is left mysterious, but it's often just a list of execution tokens (XTs) that point to the CFAs of other words, along with their data. That understanding will get you pretty far.

## The behavior of some important first words

### `latest`
Puts the address of the variable that holds the address the newest word onto the stack. `latest` is a special memory ara for Forth: It represents the head of the dictionary, the hook where word lookup starts.

### `@`
Pronounced "get." Dereferences the top value on the stack and replaces it with the dereferenced value.

### `,`
Pronounced "comma." This word pops the stack, writes the value to the current location in the dictionary (called `HERE`), and advances `HERE`.

### `here`
The current write location at the end of the dictionary, by definition. `HERE` is the location pointed to by the value that `here` puts on the stack. `here` is a word. `HERE` is the location. `,` writes to `HERE`.

### `!`
Pronounced "store." It's the opposite of get. Pops an address from the top of the stack, pops the next value, and stores the latter at the address pointed to by the former.

### `dp`
Dictionary pointer. The address where the pointer to `HERE` is stored. Another special Forth memory area.

### `word`
Gets a word from the input and writes it to the address pointed to by the top of the stack. Leaves the address on the stack

### `docol`
Do a colon-defined word. This does some bookkeeping and transfers control to the first XT in the PFA. Welcome to Forth! A "colon definition" is a word that you create with the `:` and `;` words. Our first and most important goal is to implement these words in Forth. Until we do, we have to work directly in memory, hand-building their machinery so we can use them to build the rest of the language.

### `find`
Look the word up that is stored in the address on the top of the stack, which it pops, and puts its XT onto the stack.

### `drop`
Forgets the top word on the stack and moves the top-of-stack pointer (TOS) accordingly.


### `lit`
A word that reads a value from the next slot in the dictionary and puts it on the stack. This is used so colon-definitions can work with values on the stack.

### `exit`
Leaves a colon-defined word and undoes `docol`'s bookkeeping gracefully.

## Defining `'`
`'`, pronounced "tick," gets a word from the input stream, finds it, and puts its XT on the stack. Unfortunately or fortunately, depending on your perspective, it's the core word used in laying down values into the dictionary manually, so we have to lay them down manually with more verbose means. On the bright side, we get to see how its internals work and how much harder life could be without it just by reading its definition. In all its glory:
``` Forth
latest @ , here 8 - latest ! here word ' 32 + dp !
here word docol find drop @ , 0 ,
here word wbuf find drop ,
here word word find drop ,
here word find find drop ,
here word drop find drop ,
here word exit find drop ,
```

Remember the memory layout for the header of a Forth word from **The Format of a Forth Word**? That's what the first two lines of that are doing. Here it is again to refresh your memory:

```[ *prev(8) ][ mask(0.3) ][ len(0.5) ][ char[31] ][ CFA(8) ][ 0(8) ]...```

Maybe it's easier to see now that `latest @ ,` gets the value of `latest` and writes it to `here` with `,`. This is now the `[*prev]` in that definition. There are then 5 words that don't touch the definition, `here 8 - latest !`. Instead, this fragment gets the address where we just laid down `[*prev]` by subtracting 8 (bytes) from the updated `HERE`, then stores it in `latest`. This makes the word we are about to create the head of the dictionary. Subsequent lookups will start from here until we add another link to the list. Now, we need to write a word to the dictionary. We have a word for this, `word`, that takes an address to which to write its data, hence `here word '`. That's going to write `[1(1)][39(1)][0(30)]`, or a 1-length word `'` followed by 30 zeros. We wrote those in place, without updating `HERE`, so `32 + dp !` adds 32 to the start of the `HERE` pointer that `word` left behind and stored it in `dp`.

That was a lot of words for not a lot of Forth! We wrote 40 bytes of data. That preamble will be repeated a few times. I'll refer to it as "writing the preamble," or "write/writes the preamble." The next thing we need after the preamble is the CFA. The CFA is the location of the assembly code that the `docol` word's CFA points to. In other words, we need to follow the address at `docol`'s XT. Perhaps you can see that `here word docol` puts the word for `docol` into the dictionary? There aren't a lot of places to put words, and the runtime needs to use its internal word storage for its machinery, so we just put it into the dictionary and then overwrite it with the rest of the definition. `find` picks the address of the word off the stack and looks it up, setting the success value down after it. We trust that it succeeds (`drop`), and then do `@ ,`, which gets the address of the actual assembly code for `docol` and writes that into the dictionary at `HERE`. Finally, we said that we reserve a 0 in the format, which is accomplished by `0 ,`.

So, that line wrote the assembly address of the business end of the word `docol` into the dictionary at `HERE` and followed it up with zero. The next five lines are very similar, fitting the template:
```
here word <thing> find drop ,
```
We can see a couple of differences. First, we don't write the 0. That's a special value that comes after the CFA. Second, we don't get the value of what `find` finds; we leave that level of indirection intact. (There is no `@`.) Third,  and finally, we're writing different things for each line. Those things read `wbuf word find drop exit`. But perhaps we're getting ahead of ourselves. For now, we can see that `here word <thing> find drop ,` puts the XT for `<thing>` into the dictionary at `HERE`, which is exactly what `'` will do!

Well, almost exactly! Remember that I mentioned that we needed to find different locations in which to build words so that we didn't clobber things? Well, I created another special memory area that is accessible with the address that `wbuf` puts onto the stack. So, `wbuf word <thing> find drop ,` is just like `here word <thing> find drop ,`, except safer for the runtime since we're not clobbering the runtime's word buffer, nor are we writing into the dictionary (`HERE`) where things might get clobbered during definitions.

The final thing that we lay down into memory is the XT of `exit`. `exit` is the word that "backs out" of a colon definition and returns control to the word that dispatched to it. With few exceptions, every colon word needs this.

It's important and instructive to see `'` laid out directly in memory with the tools we had available. It's awe-inspiring, I think, to see that we can now just use `'` to accomplish `wbuf word find drop exit`. And we will start ticking away almost immediately!

## Creating `create`

Here is the code listing for the definition of `create`, the word that writes new dictionary entry headers that are primed for implementing variables, but can be patched to function as any dictionary entry:
```
latest @ , here 8 - latest ! here word create 32 + dp !
' docol @ , 0 ,
' latest ,
' @ ,
' , ,
' dp ,
' @ ,
' lit ,
8 ,
' - ,
' latest ,
' ! ,
' here ,
' word ,
' lit ,
32 ,
' + ,
' dp ,
' ! ,
' lit ,
' dovar @ ,
' , ,
' lit ,
0 ,
' , ,
' exit ,
```

By now, you should recognize `latest @ , here 8 - latest ! here word create 32 + dp ! ' docol @ , 0 ,` as creating a header for the word `create`. It's identical to the first line of the defintion of `'`, except that `'` is replaced by `create`. See? You're getting the hang of this already! Well, almost. I snuck something in there, didn't I?! Do you see it now? That's right! `'` has already made its first appearance! We would had to have written `wbuf word docol find drop` before the `@` just seven lines ago! Now, we can just write `' docol @`. Immediately, we really start going to town with `'`! Tick is the star of the show! As a matter of fact, without trying to read each `'` and `,`, try reading the words that this definition lays down. I'll bet you can! I'll write it below, but don't peek! Really try to read it out loud, first. Done? Okay. Here it is:
```
latest @ , dp @ lit 8 - latest ! here word lit 32 + dp ! lit ['] dovar @, lit 0 , exit
```
Did you get at least close? (`[']` is a word we haven't seen or defined, yet.) Still, exhilarating, isn't it! We're now "thinking" in a word that we just defined and reaping the benefits of the notation! `' <thing> ,` means "write the XT for &lt;thing&gt;, found in the dictionary, `HERE`, and do the right thing with `HERE`." Semantically, it's "put this word into the next spot in the definition."

But, now we have some new code, the code we laid down with our new best friend, `'`. Does that code remind you of anything? It should look to you quite a bit like writing the preamble, but with some extra stuff mixed in and on the end. When we're running "live" code, such as when we were writing the preamble or defining tick, we could just write `8` or `32` and the interpreter would put that on the stack for us. Inside a running word, the input stream isn't available, so values have to come from somewhere else. What were previously `8` and `32` have to become `lit 8` and `lit 32`, respectively. One level back, we had to do `' lit , 8 ,` and `' lit , 32 ,`. We "ticked in" `lit`. `8` didn't need to be ticked in, because the runtime did it for us during the definition, because the definition is "live code." Just squint at that one for a bit. It takes some time to sort it all out. At any rate, that explains some of the stuff that got "mixed in" to our clean ideas about writing the preamble.

But that doesn't explain this word `dovar` that we tick in *as a literal*. "As a literal" is doing some important work. We're looking up `dovar` in the dictionary and putting its value on the stack, but we want to do that *when the definition runs*, and *not right now*. This is just going twist your brain into knots for a bit. You have to get very clear on when things are running and when they're being defined. `create` is a *defining word*. We would prefer it to always write the address of the `dovar` that we defined when we wrote the Forth. This means that we want to resolve the value of this address now, while we're writing `create`, and not every time `create` runs. Compare:
```
' lit ,
' dovar ,
' @ ,
```
with
```
' lit ,
' dovar @ ,
```
The first one *defers* resolving `dovar` until `create` runs by putting the XT of dovar on the stack and having `create` run `@` on it. The second one puts the value of `dovar` directly into the `lit`.

But, back to `dovar`. It's just a word that puts the address of the location after itself in the dictionary onto the stack. This lets you put things in that spot.

The only other notable thing about the definition of `create`, other than that it's pretty awesome, is that we don't supply the name of the word to create after `word`. Remember, `word` reads from the input. Unlike most words, which are RPN, it takes its input after it, from the programmer. So, you use it like `create something` to create a dictionary entry for the Forth entity (word/variable/constant/??) called `something`.

Before going to the next section, though, stop and marvel at how powerful `'` was for us, and how much additional power it bought us by making it so much easier to implement `create`. It's something else!

## `create` some things

We're getting more for free now than we used to. We can just `create` a word to get an entry that we only have to modify slightly for it to function as the header for a word instead of a header for a variable. That's a real improvement from having to tick in and comma everything we wanted in a header piece by piece. We're not done, though. We're still on our way to creating our compilation words.

When thinking about Forth, the concept of the simplest thing that could possibly work should come up quite a bit. In fact, our next efforts will make one constraint of this simplicity apparent: Forth is single-pass, and that pass is the current place in the input. This means that if you want to build a helper word, it has to be built temporally and lexically before the word that runs the helper. (There are ways around this, but we would have to build them, and they wouldn't be the simplest thing that could possibly work.)

`:` and `;` are best implemented with some helper words, so `init.forth` delays gratification a little more for a cleaner result. Words are hidden from dictionary lookup by "smudging" them, which essentially amounts to setting a flag on the word that the runtime recognizes. This gives rise to the need for the `smudge` and `unsmudge` words. The last word we'll need before we write `:` and `;`&mdash;technically, it's not needed until right before `;` is defined)&mdash;is `immediate`. An immediate word always runs when it is encountered, even during compilation. (You can still tick it because `'` does the lookup step without running it.) Because `;` is encountered during compilation, it needs to be immediate so that it can take over compilation and wrap things up.

Here's the listing for the definitions of `smudge` and `unsmudge`:

```
create smudge here 16 - dp ! ' docol @ , 0 ,
' latest ,
' @ ,
' lit ,
8 ,
' + ,
' dup ,
' @ ,
' lit ,
64 ,
' or ,
' swap ,
' ! ,
' exit ,

create unsmudge here 16 - dp ! ' docol @ , 0 ,
' latest ,
' @ ,
' lit ,
8 ,
' + ,
' dup ,
' @ ,
' lit ,
64 ,
' invert ,
' and ,
' swap ,
' ! ,
' exit ,
```

Look at `create` go! Instead of having to lay down the header item by item, we do `create <thing>`, followed by some arithmetic on `HERE`, `here 16 - dp !`, finally followed by laying down the CFA of `docol` where the CFA of `dovar` was with `' docol @`. Rather than go through the hassle of advancing over the `0` that create laid down, the easiest thing is just to lay it down again with ` 0 ,`. This line is only a little bit shorter than the manual line from earlier, but it's a little bit easier to read.

The bodies of `smudge` and `unsmudge` lay down a swath of values identical between them, so it's worthwile to understand them once. Those values are: `latest @ lit 8 + dup @ lit 64`. You should have enough practice now to be able to see that that duplicates the address 8 bytes beyond the `[*prev]` field of the word most recently laid down, replace the copy of that address with what lives there, and puts 64 onto the stack.

64 is a bit cryptic, but it's just the smudge bit. `or swap !` stores whatever was already there back onto itself, but with the smudge bit set. `invert and swap !` writes it back with the smudge bit cleared.

With those explained, we can turn our attention to `immediate`, which also operates on the last word and sets the flag that makes it immediate. Here is the code that defines it:

```
create immediate here 16 - dp ! ' docol @ , 0 ,
' latest ,
' @ ,
' lit ,
8 ,
' + ,
' dup ,
' c@ ,
' lit ,
32 ,
' or ,
' swap ,
' c! ,
' exit ,
```

Our hero `create` is doing its thing, we're doing our `docol` CFA replacement thing, and then the start of `immediate`'s body looks an awful lot like the ones from `smudge`/`unsmudge`, except we're using `c@` instead of `@`. `c@` just writes a single byte instead of 8 bytes. Clearly, the immediate flag is 32, and `c!` must store a character, rather than a word. You're reading Forth like it's your first language!

## `:` and `;`

Finally, the time is ripe! Like so much so far in this bootstrapping process, the new will seem strangely familiar. Diving right in with the listing for the definition of `:`:

```
create : here 16 - dp ! ' docol @ , 0 ,
' create ,
' smudge ,
' dp ,
' @ ,
' lit ,
16 ,
' - ,
' dp ,
' ! ,
' lit ,
' docol ,
' @ ,
' , ,
' dp ,
' @ ,
' lit ,
8 ,
' + ,
' dp ,
' ! ,
' lit ,
1 ,
' state ,
' ! ,
' exit ,
```

The header is laid down with the familiar `create`-and-replace mechanic we've already seen. Let's take a look at the body that is being laid down for `:`:
```
create smudge dp @ lit 16 - dp ! lit docol @ , dp @ lit 8 + dp ! lit 1 state ! exit
```

Fragments of that should seem familiar. `dp @ lit 16 - dp !` is just colon-word-ese for `here 16 - dp ! docol @ , 0,`, except that it opts for walking past the `dovar` reserved data field over replacing it with zero. After that, it simple sets `state` to 1. 0 is the interpreting state and 1 is the compiling state. Much of what `:` does is setup and teardown for machinery that's implemented in the outer loop. In `maxiForth`, that machinery is implemented in hand-laid CFAs. After `:` is run, the Forth runtime is in the "compiling" state.

This leaves only `;`, our first immediate word:

```
create ; here 16 - dp ! ' docol @ , 0 ,
' lit ,
0 ,
' state ,
' ! ,
' lit ,
' exit ,
' , ,
' unsmudge ,
' exit ,
immediate
```

Say goodbye to hand-laid headers. After `'` is defined, we have all the machinery we need. (We hardly knew ye!) The body that is laid down for `;` is just: `lit 0 state ! lit CFA(exit) , unsmudge exit`. The `CFA(exit)` was a bit of a cheat, but that's essentially what `' exit ,` lays down. All that `;` is doing is putting us back into the interpreting state, unsmudging the word so it's ready for lookup, and `exit`ing. We then call `immediate` to make it so `;` runs when the runtime is in the compiling state.

## The line comment word: `\`

You're not ready for the next two lines of code in `init.forth`. Well, you are, but they're still going to blow your mind:

```
: \ tib mib + >in ! ; immediate
\ Now we can comment!
```

No visbile `create`. No visible header patching. No ticking. No commas. We don't have to squint at a sea of ticking and commaing to know what the body of `\` does. It's right there: `tib mib + >in !`. There's an `exit` on the end, but that's now an "internal" to us. This *abstraction*, as thin as it is and layered as so closely as it is to raw assembly instructions, still lets us think in pure Forth. This is fortuitous, because there are three new words to figure out. `tib` is a pointer to the top of the input buffer. `mib` is the maximum valid index into the input buffer. `>in` is the address where input is currently being accepted from.

Semantically, the `\` word throws away everything after itself on the line.

A couple of gotchas and design decisions. `\` is the traditional line comment word. I think I prefer `#`. The other gotcah will getcha, for sure. Words in Forth must be separated by spaces, so:

```
\ This is a comment
\This is an error.
```
If you're used to thinking of comment characters as special to other interpreters or a preprocessor, that one might catch you buy surprise. You probably are. It probably will!

## Conclusion, sort of

There is now a comment word in `init.forth`, and therefore in `maxiForth`. The creation myth proper is over. It's now on to serpents, temptation, & etc. The rest of `init.forth` contains not just the scriptures, but the concordance in the form of comments. You're probably a passable scribe or priest, now. There are currently some opportunities for factoring in there that I will take advantage of to make `init.forth` a better example for future Forthers such as yourself, but perhaps the current state of things could serve as a warning or byword, which is just aa different kind of valuable instruction, I suppose. Either way, you're now prepared to excavate the remaining 250 lines of pure Forth to see how to build the rest of the language with the base machinery in place.

You could, if you wanted, take each section as a homework assignment and try recreating it after some study. There can be moments of transcendence and vertigo both in such an effort, especially if you have already written your own runtime in assembly and hand-laid CFAs. Where once you spake as an assembly programmer, understood as an assembly programmer, and thought as an assembly programmer, you will put away those childish things and begin to refactor like a Forth programmer. The Kingdom of Heaven is near!

Happy Forthing!