# A Guide to `init.forth`

## Introduction

`init.forth` is the code file that bootstraps Forth from a working but minimal core to a "real" Forth. As a *kernel*, `maxiForth` lacks many of the amenities that make Forth a comfortable working environment, including basic words like `'`, `create`, `:`, `;`, and so on. This is deliberate in order to keep the size of the kernel as small as is reasonable, because the kernel is what must be rewritten for whatever architecture you are targeting next. However, it does mean that `init.forth` starts out with some pretty unconventional Forth code. It's a little like rubbing two sticks together to make fire, in this regard, except more difficult to follow. Possibly the most keenly felt absence is that of `\`, or some other comment character, as it means the file itself cannot be commented until after the comment character gets its (pretty basic) behavior of moving the input location to the end of the buffer and letting the kernel take over to skip you to the next line. It is this absence, more than any other, that motivates the current discussion; this could be titled, **init.forth: The missing documentation**.

As we pass through the various stages of documenting `init.forth`, we'll actually develop a very good understanding of the dictionary layout, how Forth words are run, and especially the layout of a Forth word in memory. It is often said that the data are more important than the code, for if you are shown code without data, you'll have no idea what's going on. However, if you're shown the data and it is explained to you, you'll be in such a good position that you could almost write the code yourself. One of my goals is to get as many people as possible to experience the enlightenment of writing a Forth of their own from scratch. This makes the lack of the `\` word in `init.forth` into a wonderful opportunity to walk you through the birth of the language!

## Interpretation and compilation

Forth is both an interpreter and a compiler; you build programs by defining words at the same interactive prompt from which you run them. This differs from other languages that typically split interpretation and compilation between different programs. In C, for example, you write source files and call the compiler and linker to produce an executable. Compilers could output machine code directly, but they often output assembly code. This assembly then gets "assembled" into the final program. This Forth, and ones that you build if you take up the challenge, will be built in assembly, so you'll get to experience the write-compile divide directly. In Forth, you compile directly with the `:` and `;` words right at the interpreter prompt.

On the other end of the spectrum are interpreted languages like Python, JavaScript, BASIC, and others. In these languages, your code is run by a program called an interpreter. In a pure interpreter, your code is broken up into its parts as the interpreter sees the parts and immediately translated into something the computer can run. There is no separate compiler to turn your text into a separate binary. In Forth, you enter words at the Forth prompt or write Forth into files and point the interpreter at them with the `include` word. In either case, your words are looked up by the interpreter and run.

One of the first goals of `init.forth` is to create the compilation words `:` and `'`.

## The format of a forth word

`init.forth` begins rather cryptically with a line that lays items down directly into memory using, among others, the `,` word. (More on `,` later.) The items being laid down fit the format of the header of a Forth word. This format looks like:

```[ *prev(8) ][ mask(0.3) ][ len(0.5) ][ char[31] ][ CFA(8) ][ 0(8) ]...```

The bits in parentheses are bytes and fractional bytes (bits). So, `8` represents a 64-bit word, and `0.3` represents three bits. So the above reads, in words: "A dictionary entry is a 64-bit pointer to the previous entry, three bits of masks, five bits specifying the length of a 31-byte (248-bit) string, said string, a 64-bit code field address (CFA), and 8 bytes of 0s. Semantically, it's a previous pointer, a masked length-prefixed word string, an address of the action to take for the word, and a reserved word for future use. The title of this section is **The format of a forth word**, and I've only given you the header, so far. The rest of a word goes:

```...[ P(8) ][ P(8) ]...```

Take "P" to stand for "parameter." This region of the word is the parameter field, and it begins at the parameter field address (PFA). The parameter field is left mysterious, but it's often just a list of execution tokens (XTs) that point to the CFAs of other words, along with their data. In other words, the PFA often contains the *body* of a Forth word. That understanding will get you pretty far.

## The behavior of some important first words

Before going too much further, you're going to need a little Forth vocabulary. This section contains some early words that are already defined in the kernel of `maxiForth` and with which you'll want to be familiar.

### `latest`
Puts the address of the variable that holds the address of the newest word onto the stack. `latest` is a special memory area for Forth: It represents the head of the dictionary, the hook where word lookup starts. Note that this is an address of an address.

### `@`, `c@`
Pronounced "get" and "character get." Dereferences the top value on the stack and replaces it with the dereferenced value. `@` gets a 64-bit value. `c@` gets an 8-bit value.

### `,`
Pronounced "comma." Pops the top value off the stack, writes the value to the current location in the dictionary (called `HERE`), and advances `HERE`. This one shows up early in `init.forth` because we don't have any other machinery yet for modifying the dictionary.

### `here`
Pushes the current write location (at the end of the dictionary) onto the stack. This value *defines* the end of the dictionary for ordinary writes. `,` uses and updates the value it produces, for example. `HERE` is the location pointed to by the value that `here` puts on the stack. `here` is a word. `HERE` is the location. `,` writes to `HERE`.

### `dp`
Pushes the dictionary pointer onto the stack. This is the address where the pointer to `HERE` is stored. Another special Forth memory area. Writing to this updates `HERE` and changes the value that `here` will push to the stack.

### `!`, `c!`
Pronounced "store" and "character store." The opposite of their "get" counterparts. Pop an address from the top of the stack, pop the next value, and store the latter at the address pointed to by the former. They operate on 64-bit and 8-bit values, respectively.

### `word`
Gets a word from the input and writes it to the address pointed to by the top of the stack. Leaves the address on the stack. Note that `word` is postfix (RPN) with respect to the address, but *prefix* with respect to the word it reads. So: `<address> word <word-to-look-up>`.

### `docol`
Does a colon-defined word. This does some bookkeeping and transfers control to the first XT in the PFA. Welcome to Forth! A "colon definition" is a word that you create with the `:` and `;` words. Our first and most important goal is to implement the `:` and `;` words in Forth. Until we do, we have to work directly in memory, hand-building their machinery with `,` and address arithmetic so we can use them to build the rest of the language.

### `find`
Looks the word up that is stored in the address on the top of the stack, which it pops, and puts its XT onto the stack.

### `drop`
Forgets the top word on the stack and moves the top-of-stack pointer (TOS) accordingly.


### `lit`
Reads a value from the next slot in the dictionary and puts it on the stack. This lets colon-definitions work with values on the stack.

### `exit`
Leaves a colon-defined word's body at run time and undoes `docol`'s bookkeeping gracefully.

## Defining `'`

`'`, pronounced "tick," gets a word from the input stream, finds it, and puts its XT on the stack. Unfortunately or fortunately, depending on your perspective, it's the core word used in laying down values into the dictionary manually, so we have to lay its parts down manually with more verbose code. On the bright side, we get to see how its internals work and how much harder life could be without it just by reading its definition. In all its glory:

``` Forth
latest @ , here 8 - latest ! here word ' 32 + dp !
here word docol find drop @ , 0 ,
here word wbuf find drop ,
here word word find drop ,
here word find find drop ,
here word drop find drop ,
here word exit find drop ,
```

Before continuing, I should note that I'm going to prefer a more or less vertical approach to code layout when defining the early words in `maxiForth`. There are almost no decisions being made by this code, and the layout of what is being written is easier to scan if you sort of squint and read down the page, ignoring the machinery that's finding things and laying things down and reading what's being laid down in list fashion. Not all Forth has to look like this. This just happens to be a nice way to write and read *these particular* kinds of words. `'` is an *okay* example of this. I say this because the finding-and-laying-down machinery is still pretty wide. By the time we get to `create`, though, we'll be writing and reading some pretty lanky words. Back to it!

Remember the memory layout for the header of a Forth word from **The format of a Forth word**? That's what the first two lines of that are doing. Here is that format again to refresh your memory:

```[ *prev(8) ][ mask(0.3) ][ len(0.5) ][ char[31] ][ CFA(8) ][ 0(8) ]...```

Maybe it's easier to see now that `latest @ ,` gets the value of `latest` and writes it to `here` with `,`. This is now the `[ *prev(8) ]` in that definition. There are then 5 words that don't touch the definition, `here 8 - latest !`. Instead, this fragment gets the address where we just laid down `[*prev(8)]` by subtracting 8 (bytes) from the updated `HERE`, then stores it in `latest`. This makes the word we are about to create the head of the dictionary. (In other words, `find` starts at the address stored in `latest`.) Subsequent lookups will start from here until we add another link to the list. Now, we need to write a word to the dictionary. We have a word for this, `word`, that takes an address to which to write its data, hence `here word '`. That's going to write `[1(1)][39(1)][0(30)]`, or a 1-length word, `'`, followed by 30 zeros. We wrote those in place, without updating `HERE`, so `32 + dp !` adds 32 to the start of the `HERE` pointer that `word` left behind and stored it in `dp`.

That was a lot of words for not a lot of Forth! We wrote 40 bytes of data. That preamble will be repeated a few times. I'll refer to it as "writing the preamble," or "writing the header" if I'm talking about writing the preamble above and the CFA and placeholder, as discussed next.

After the preamble comes the CFA. The CFA is the location of the assembly code that the word points to. This word's action is `docol`, so we need to follow the address at `docol`'s XT. Perhaps you can see that `here word docol` reads the word for `docol` into the current location in the dictionary? The `docol` here doesn't represent a Forth word like 'here' and 'word' do on this line. `word` gets the name of a (potential) word from the input. "docol" is that word name right there in the input stream. The difference is that the outer intepreter sees `here` and `word` normally, but only `word` sees everything up to the space after "docol".

We run into a wrinkle here. There aren't a lot of places to put words, and the runtime needs to use its internal word storage for its machinery. Therefore, we just put the new word directly into the dictionary and then continue with the rest of the definition. (The alternative would have been to read it into `wbuf` and then copy it into the dictionary. Two birds with one stone.) `find` pops the address of the word off the stack and looks it up, setting the success value down after it. We trust that it succeeds (`drop`), and then do `@ ,`, which gets the address of the actual assembly code for `docol`, (called the CFA) and writes that into the dictionary at `HERE`. Finally, we said that we reserve a 0 in the format, which is accomplished by `0 ,`.

To review, that line wrote the assembly address of the business end of the word `docol` into the dictionary at `HERE` and followed it up with zero. The next five lines are very similar, fitting the  template below:

```
here word <thing> find drop ,
```

We can see a couple of differences between this line and the one that wrote the CFA of `docol`. First, we don't write the 0. That's a special value that comes after the CFA. Second, we don't dereference what `find` finds; there is no `@`. Third,  and finally, we're writing different things for each line. Those things will read `wbuf word find drop exit` when we're done, but more on that in a bit. For now, notice that `here word <thing> find drop ,` puts the XT for `<thing>` into the dictionary at `HERE`, which is exactly what `'` will do!

Well, almost exactly! Remember that I mentioned that we needed to find different locations in which to build words so that we didn't clobber things? Well, I created another special memory area that is accessible with the address that `wbuf` puts onto the stack. So, `wbuf word <thing> find drop ,` is just like `here word <thing> find drop ,`, except safer for the runtime since we're not clobbering the runtime's word buffer, nor are we writing into the dictionary (`HERE`) where things might get clobbered during definitions.

The final thing that we lay down into memory is the XT of `exit`. `exit` is the word that "backs out" of a colon definition and returns control to the word that dispatched to it. With few exceptions, every colon word needs this.

It's important and instructive to see `'` laid out directly in memory with the tools we had available. It's awe-inspiring, I think, to see that we can now just use `'` to accomplish `wbuf word find drop exit`. We will start ticking away almost immediately!

## Creating `create`

 `create` is the word that writes new dictionary entry headers. These headers are primed for implementing variables, but can be patched to function as words, constants, or what have you. Here is its code listing:

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

By now, you should recognize `latest @ , here 8 - latest ! here word create 32 + dp ! ' docol @ , 0 ,` as writing a header for the word `create`. It's identical to the first line of the definition of `'`, except that `'` is replaced by `create`. Well, almost identical. I snuck something in there, didn't I?! Do you see it now? `'` has already made its first appearance! We would had to have written `wbuf word docol find drop` before the `@` just seven lines ago! Now, we can just write `' docol @`. Immediately, we really start going to town with `'`! Tick is the star of the show! As a matter of fact, without trying to read each `'` and `,`, try reading the words that this definition lays down. I'll bet you can! I'll write it below, but don't peek! Really try to read it out loud, first. Done? Okay. Here it is:

```
latest @ , dp @ lit 8 - latest ! here word lit 32 + dp ! lit CFA(dovar) , lit 0 , exit
```

Did you get at least close? (`CFA(dovar)` is just the address of the code that runs `dovar`.) Exhilarating! We're now "thinking" in a word that we just defined and reaping the benefits of the notation! `' <thing> ,` means "write the XT for &lt;thing&gt;, found in the dictionary, `HERE`, and do the right thing with `HERE`." More directly, it's "put this word into the next spot in the definition."

But, now we have some new code, the code we laid down with our new best friend, `'`. Does that code remind you of anything? It should look to you quite a bit like writing the header, but with some extra stuff mixed in and on the end. When we're running "live" code, such as when we were writing the preamble or defining tick, we could just write `8` or `32` and the interpreter would put that on the stack for us. Inside a running word, the input stream isn't available, so values have to come from somewhere else. What were previously `8` and `32` have to become `lit 8` and `lit 32`, respectively. One level back, we had to do `' lit , 8 ,` and `' lit , 32 ,`. We "ticked in" `lit`. `8` didn't need to be ticked in, because the runtime did it for us during the definition, because the definition is "live code." Just squint at that one for a bit. It takes some time to sort it all out. At any rate, that explains some of the stuff that got "mixed in" to our clean ideas about writing the preamble.

But that doesn't explain this word `dovar` that we tick in *as a literal*. "As a literal" is doing some important work. We're looking up `dovar` in the dictionary and putting its value on the stack, but we want to do that once when `create` itself is defined, not *every time `create` runs. This is just going twist your brain into knots for a bit. You have to get very clear on when things are running and when they're being defined. `create` is a *defining word*. It defines words *when it runs*. We would prefer `create` to only have to write the address of the `dovar` now, rather than doing the `@` itself for every invocation of `create`. This means that we want to resolve the value of this address in the definition of `create`. Compare:

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
The first one *defers* resolving `dovar` until `create` runs by putting the XT of `dovar` on the stack and having `create` run `@` on it. The second one puts the value of `dovar` directly into the cell that follows `lit`. This kind of optimization isn't too critical for a word like `create` because it will almost always be run interactively or from a file, rather than from inside a deeply nested loop. You're not going to be creating 20 million variables at a time. However, it's a good exercise to think about the different times when your code is running and exactly what is happening when.

Back to `dovar`. It's just a word that puts the address of the location after itself in the dictionary onto the stack. This lets you put values in that spot and get them back with the name that you `create`d.

The only other notable thing about the definition of `create` is that we don't supply the name of the word to create after `word`. Remember, `word` reads from the input. Unlike most words, which are RPN, it takes its input after it, from the programmer or the script. So, you use it like `create something` to create a dictionary entry for the Forth entity (word/variable/constant/??) called `something`.

Before going to the next section, though, stop and marvel at how powerful `'` was for us, and how much additional power it bought us by making it so much easier to implement `create`!

## `create` some things

We're getting more for free now than we used to. We can just `create` a word to get an entry that we only have to modify slightly for it to function as the header for a word instead of a header for a variable. That's a real improvement from having to tick in and comma everything we wanted in a header piece by piece. We're not done, though. We're still on our way to creating our compilation words.

When thinking about Forth, the simplest thing that could possibly work should be the thing you reach for first. Our next efforts will make one constraint of this simplicity apparent: Forth is single-pass, and that pass is the current place in the input. This means that if you want to build a helper word, you have to build it before the word that uses it. (There are ways around this, but we would have to build them, and they wouldn't be the simplest thing that could possibly work.)

`:` and `;` are best implemented with some helper words, so `init.forth` delays gratification a little more for a cleaner result. The first thing we need to handle are *smudging* and *unsmudging*. Words are hidden from dictionary lookup by smudging them, which essentially amounts to setting a flag on the word that the runtime recognizes. This gives rise to the need for the `smudge` and `unsmudge` words. The last word we'll need before we write `:` and `;`&mdash;technically, it's not needed until right before `;` is defined&mdash;is `immediate`. An immediate word always runs when it is encountered, even during compilation. (You can still tick it because `'` does the lookup step without running it.) Because `;` is encountered during compilation, it needs to be immediate so that it can take over compilation and wrap things up.

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

Look at `create` go! Instead of having to lay down the header item by item, we do `create <thing>`, followed by some arithmetic on `HERE`, `here 16 - dp !`, finally followed by laying down the CFA of `docol` where the CFA of `dovar` was with `' docol @`. Rather than go through the hassle of advancing over the `0` that create laid down, the easiest thing is just to lay it down again with `0 ,`. This line is only a little bit shorter than the manual line from earlier, but it's a little bit easier to read.

Another aside about when things run will be instructive here. Remember how we wanted `create` to lay down the address of `dovar`, which is constant, without having to look it up each time? We want the opposite for `smudge` and `unsmudge` with respect to `latest`. Had we mistakenly done:

``` ' latest @ ,```

instead of the correct

```
' latest ,
' @ ,
```

then `smudge` and `unsmudge` would always have laid down the values of `latest` that were stored there when they were defined, rather than the current value when the smudged state is being changed. Be sure you understand the difference. Or don't. You'll get it eventually. It can just take a little time and experience.

The bodies of `smudge` and `unsmudge` lay down a swath of values that are identical between them, so it's worthwhile to understand them once. Those values are: `latest @ lit 8 + dup @ lit 64`. You should have enough practice now to be able to see that this fragment duplicates the address 8 bytes beyond the `[*prev]` field of the word most recently laid down, replaces the copy of that address with what lives there, and puts 64 onto the stack.

64 is a bit cryptic, but it's just the smudge bit. `or swap !` stores whatever was already there back onto itself, except with the smudge bit set. `invert and swap !` writes it back with the smudge bit cleared.

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

Our hero `create` is doing its thing, we're doing our `docol` CFA replacement thing, and then the start of `immediate`'s body looks an awful lot like the ones from `smudge`/`unsmudge`, except we're using `c@` instead of `@`. `c@` just writes a single byte instead of 8. Clearly, the immediate flag is 32, and `c!` must store a character, rather than a word. You're reading Forth like it's your first language!

## `:` and `;`

Finally! The time is ripe! We can now define the two words that turn Forth into an extensible language. Like so much so far in this bootstrapping process, the new will seem strangely familiar. Diving right in with the listing for the definition of `:`:

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

Fragments of that should seem familiar. `dp @ lit 16 - dp !` is just colon-word-ese for `here 16 - dp ! docol @ , 0,`, except that it opts for walking past the `dodoes` reserved data field over replacing it with zero. (`dodoes` is a part of the does machinery that lets you specify behavior for `create`d words.) After that, it simply sets `state` to 1. 0 is the interpreting state and 1 is the compiling state. Much of what `:` does is set-up and teardown for machinery that's implemented in the outer loop. (In `maxiForth`, that machinery is implemented in hand-laid CFAs.) After `:` is run, the Forth runtime is in the "compiling" state.

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

Say goodbye to hand-laid headers on their final victory lap! After `;` is defined, we have the machinery to do actual Forth programming. The body that is laid down for `;` is just: `lit 0 state ! lit CFA(exit) , unsmudge exit`. The `XT(exit)` was a bit of a cheat, but that's essentially what `' exit ,` lays down. All that `;` is doing is putting us back into the interpreting state, unsmudging the word so it's ready for lookup, and `exit`ing. We then call `immediate` to make it so `;` runs when the runtime is in the compiling state.

## The line comment word: `\`

You're not ready for the next two lines of code in `init.forth`. Well, you are, but they're still going to blow your mind:

```
: \ tib mib + >in ! ; immediate
\ Now we can comment!
```

No visible `create`. No visible header patching. No ticking. No commas. We don't have to squint at a sea of ticking and commaing to know what the body of `\` does. It's right there: `tib mib + >in !`. There's an `exit` on the end, but that's now an "internal" to us. This *abstraction*, as thin as it is and layered as so closely as it is to raw assembly instructions, still lets us think in pure Forth. This is lucky, because it unburdens us to more easily figure out the three new words that we see in the definition. `tib` is a pointer to the top of the input buffer. `mib` is the maximum valid index into the input buffer. `>in` is the address where input is currently being accepted from.

Semantically, the `\` word throws away everything after itself on the line.

A couple of gotchas and design decisions. `\` is the traditional line comment word. I think I prefer `#`. The other gotcha will getcha, for sure. Words in Forth must be separated by spaces, so:

```
\ This is a comment
\This is an error.
```

If you're used to thinking of comment characters as special to other interpreters or a preprocessor, that one might catch you buy surprise. You probably are. It probably will!

## Conclusion, sort of

There is now a comment word in `init.forth`, and therefore in `maxiForth`. The creation myth proper is over. It's now on to serpents, temptation, & etc. The rest of `init.forth` contains not just the scriptures, but the concordance in the form of comments. You're probably a passable scribe or priest, now. There are currently some opportunities for factoring in there that I will take advantage of to make `init.forth` a better example for future Forthers such as yourself, but perhaps the current state of things could serve as a warning or byword, which is just a different kind of valuable instruction, I suppose. Either way, you're now prepared to excavate the remaining 250 lines of pure Forth to see how to build the rest of the language with the base machinery in place.

You could, if you wanted, take each section as a homework assignment and try recreating it after some study. I promise you, there can be moments of both transcendence and vertigo in such an effort, especially if you have already written your own runtime in assembly and hand-laid CFAs. Where once you spake as an assembly programmer, understood as an assembly programmer, and thought as an assembly programmer, you will put away those childish things and begin to refactor like a Forth programmer. The Kingdom of Heaven is near!

Happy Forthing!