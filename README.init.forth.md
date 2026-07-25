# A Guide to `init.forth`

## Introduction

`init.forth` is the code file that bootstraps Forth from a working but minimal core to a "real" Forth. As such, it lacks many of the amenities that make Forth a comfortable working environment, including basic words like `'`, `create`, `:`, `;`, and so on. This is deliberate in order to keep the size of the kernel, so to speak, of Forth as small as reasonable, because the kernel is what must be rewritten for whatever architecture you are targeting next. However, it does mean that `init.forth` starts out with some pretty unconventional Forth code. It's a little like rubbing two sticks together to make fire, in this regard, except more difficult to follow. Possibly the most keenly felt absence is that of `\`, or some other comment character, as it means the file itself cannot be commented until after the comment character gets its (pretty basic) behavior of moving the input location to the end of the buffer and letting the kernal take over to skip you to the next line. It is this absence, more than any other, that motivates the current discussion; this could be titled, **init.forth: The Missing Documentation**.

As we pass through the various stages of documenting `init.forth`, we'll actually develop a very good understanding of the dictionary layout, how Forth words are run, and especially the layout of a Forth word in memory. It is often said that the data are more important than the code, for if you are shown code without data, you'll have no idea what's going on. However, if you're shown the data and it is explained to you, you'll be in such a good position that you could almost write the code yourself. Inasmuch as one of my goals is to get as many people as possible to experience the enlightenment of writing a Forth of their own from scratch, the lack of the `\` word in `init.forth` is a most welcome serendipity!

## The Format of a Forth Word

`init.forth` begins rather cryptically with a line that lays items down directly and quite literally into memory using, among others, the `,` word. The items being laid down are in the format of the header of a Forth word. This format looks like:

```[*prev(8)][mask(0.3)][len(0.5)][char[31]][CFA(8)][0(8)]...```

The bits in parentheses are bytes and fractional bytes (bits). So, `8` represents a 64-bit word, and `0.3` represents three bits. In words, a dictionary entry is a 64-bit pointer to the previous entry, three bits of masks, five bits specifying the length of a 31-byte (248-byte) string, said string, a 64-bit code field address (CFA), and 64-bits of 0s. Semantically, it's a previous pointer, a masked word-length word string, an address of the action to take for the word, and a reserved word for future use. The title of this section is **The Format of a Forth Word**, and I've only given you the header, so far. The rest of a word goes:

```...[P(64)][P(64)]...```

We take "P" to stand for "parameter." This region of the word is the parameter field, and it begins at the parameter field address (PFA). The parameter field is left mysterious, but it's often just a list of execution tokens (XTs) that point to the CFAs of other words, along with their data. That understanding will get you pretty far.

## The Behavior of Some Important First Words

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

## `create` Some Things

## `:`, `immediate`, and `;`

## Let there be light: The Line Comment Word, `\`