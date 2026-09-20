# Bind algorithmic problem statement

## Introduction and context

An important core part of 64-bit Windows programming is calling into the Windows library. In addition, using any external C library, or a library in any language that provides a C interface, is being able to match the 64-bit Windows calling convention. Doing this on a per-word basis is time-consuming and error-prone. Better to spend all the time and debugging in one place, a `bind` word that lets you emit `call` on a function pointer with the arguments loaded and inspect the results on the stack.

The non-variadic Win64 calling convention expects the first four arguments to be in `rcx`/`xmm0`, `rdx`/`xmm1`, `r8`/`xmm2`, and `r9`/`xmm3`, with the caveat that odd-shaped return values are identified by a pointer which goes into `rcx` and is returned in `rax`. There is a modestly complex set of rules around what byte patterns trigger the requirement for a pointer in `rcx`, but the big one is for structs. I've named this case the "big return value case." In the big return value case, the first three explicitly passed arguments go into `rdx`, `r8`, and `r9`. In either case, additional arguments go onto the stack, above the so-called "shadow space."

Shadow space is 32-bytes of extra space on the stack. This is a minimum because it must be aligned to a 16-byte boundary. Shadow space is moved by manipulating `rsp`. Subtract from `rsp` to create room on the stack before a call and add to `rsp` to restore the stack after a call. The following examples cover some interesting cases and give a flavor of the full solution.

**`Worked example 1:`**

**Problem:**
A callee takes 4 integer arguments and returns an integer. `rsp` is aligned to an 8-byte boundary, not a 16-byte boundary, before the call. (This is common because `call` pushes `rsp` onto the stack.) How much stack space must you allocate?

**Solution:**
You must allocate **40** bytes of stack space. You can do this with `sub rsp, 40`. The four arguments fit into `rcx`, `rdx`, `r8`, and `r9`. Because the return value does not trigger the big return value case, the fourth argument did not have to go onto the stack. You need 32 bytes of shadow space, but must take 8 more bytes to land on a 16-byte boundary, because you started on an 8-byte boundary.

**`Worked example 2:`**

**Problem:**
A callee takes 4 integer arguments and returns a 100-byte struct. `rsp` is aligned to an 8-byte boundary, not a 16-byte boundary, before the call. (This is common because `call` pushes `rsp` onto the stack.) How much stack space must you allocate?

**Solution:**
You must allocate **40** bytes of stack space. You can do this with `sub rsp, 40`. A pointer to your allocated 100-byte struct goes into `rcx`. The first three arguments go into `rdx`, `r8`, and `r9`. Because this is the big return value case, the fourth argument goes onto the stack at `rsp` + 32. (For example, with `lea r10 [rel myarg]`, followed by `mov [rsp + 32], r10`. Any free register will do.) You need 32 bytes of shadow space, but must take 8 more bytes to land on a 16-byte boundary, because you started on an 8-byte boundary. This left you with a free 8-byte slot for the extra argument, so you still only needed 40 bytes; aligning got you the space you needed.

**`Worked example 3:`**

**Problem:**
As in **Worked example 2**, except that the stack is aligned to a 16 byte boundary before you begin.

**Solution:**
You must allocate **48** bytes of stack space. `rcx` contains the pointer to the 100-byte struct, and only the first three arguments fit into the remaining registers, so 8 bytes more stack space are required. The fourth argument goes into `rsp` + 32. However, 40 mod 16 is 8. Because you started out aligned, you must subtract a multiple of 16 from `rsp`. Therefore, there will be 8 bytes of junk above your fourth argument after you `sub rsp, 48` and fill the argument slot, which is adjacent to the shadow space.

### Variadic functions

For variadic functions, the first four arguments go into both `rcx`/`xmm0`, `rdx`/`xmm1`, `r8`/`xmm2`, or `r9`/`xmm3`. Stashing all of those all the time might be excessive, so we'll implement `vbind` later after we've worked out `bind`.

## Implementation notes and data structures

### Return values

A function can return an integer type, a float type, vector type, a user-defined type, or a "big" type (structs and certain odd-shaped values). It can also return nothing, which is `void` in the vocabulary of C programming. The following table describes these cases.

**Table 1: Return value cases for C calls.**

|Case|Type description|Return behavior|Moves args?|
|:---|:---------------|:--------------|:----------|
|Integer|Any integer or pointer of any size up to 8 bytes.|Bit pattern in the lowest bits of `rax`.|No|
|Float|Any floating-point value up to 8 bytes.|Bit pattern in the lowest bits of `xmm0`.|No|
|Vector|16-byte (128-bit) vector values of type `__m128`, `__m128d`, or `__m128i`.| Bit pattern occupying all of `xmm0`.|No|
|User-defined types|1-, 2-, 4-, or 8-byte structs, unions, or classes.|Bit pattern in the lowest bits of `rax`.|No|
|Big return case|3-, 5-, 6-, 7-, or >8-byte or non-trivial types.|Pointer to the preallocated value place in `rax`.|Yes|



### Specifying function signatures

As can be seen from the previous discussion, an external call on Win64 requires careful setup. Without regard to order, `bind` needs to determine:

* Whether the function fits the big return case.
* Whether the function returns void.
* What the type is of each input argument, if any are present.
* The amount of parameter space to reserve, including the padding to align with a 16-byte boundary.

We'd like to do this without revisiting values too many times. This is complicated by the facts that the return value can affect the parameter layout. We simplify this by putting that decision onto the programmer. If you have the big struct case, then you allocate your own struct/field, put a pointer to it into `rcx`, and expect that pointer back in `rax`. In any event, we need to provide `bind` with what it needs to build the call. So, no matter the order in which the decisions need to be made, a signature string with the values in the following tables and a `|` separating the return code from the argument type list.
In any event, we need to provide `bind` with what it needs to build the call. So, no matter the order in which the decisions need to be made, a signature string with the values in the following tables and a `|` separating the return code from the argument type list.

**Table 2: Signature string return value codes.**

|Value|Description|Register|
|:----|:----------|:----------|
|v|`void`. No return value. `rax` and `xmm0` contain garbage.|None|
|B (arg list)|A "big struct" value. Anything with 3, 5, 6, 7, or more than 8 bytes, and nontrivial types. Pointer goes into `rcx` and shifts all args into the next register.|`rax` (pointer)|
|`[1248]`|A struct with length 1, 2, 4, or 8 bytes.|`rax` (value)|
|f|A 32-bit floating-point value.|`xmm0`|
|F|A 64-bit floating-point value.|`xmm0`|
|q|A 64-bit integer.|`rax` (value)|
|d|A 32-bit integer.|`eax` (value)|
|u|A 32-bit unsigned integer.|`eax` (value)|

**Table 3: Signature string argument value codes.**

|Value|Description|Register(s)|
|:----|:----------|:----------|
|B|A "big struct" pointer. Your signature string must start "B\|B" to control separate behaviors for the call and return.|`rcx` (pointer)|
|f|A 32-bit floating-point value.|`xmm0`-`xmm3`|
|F|A 64-bit floating-point value.|`xmm0`-`xmm3`|
|i|Any integer type. Entire cell is moved to the register|`rcx`, `rdx`, `r8`, `r9`|
|`([0-9]+)?$`|The number of stack arguments. (The ones beyond the first 4 explicit arguments.)|None. Placed on the stack above the shadow space.|

Therefore, a signature string can be represented by the regex `[BfFvsqdu]|B?[fFi]*`.

**Note:** The original plan for `bind` was to have it see the `B` on the return side and then (somehow) know how to pass the hidden pointer and bump the arguments up to the next register, keep track of how much stack space to allocate, and so on. However, the approach that actually works, and the one that I will take, is to put all that work onto the programmer. You know how big your struct is. `malloc` or `calloc` it. You get the pointer from that. Pass it as the argument in the argument slot for `B`, which must be the first slot. Free it when you're done. See how much easier things are if you just do everything yourself?

## Implementation

### Approach

`bind` requires a pointer to a callee and a pointer to a signature specification string. It will ask take the name for the bound word from the input. The signature string might look like `v|`, `B|Bffi`, or `F|FF`, among countless other possibilities. The first of those is a function that takes no arguments and gives you nothing back. The second returns a big struct, so it has the `B` placeholder so it knows what to do with the argument in that slot. (Once you type `B`, the `|B` is mandatory.) The final signature string is for a function that operates on two 64-bit floats and hands you back one 64-bit float.

Given the shape of the above, the general plan should be as follows:

1. Create a slew of anonymous primitives that each handle a precise entry from the implied matrices in tables **2** and **3** *at call time*.
2. Create CFAs for these low-level handlers so they can be baked directly into a binding.
3. Create a smaller batch of named primitives findable in the dictionary: one for the return slot, one for each of the four argument registers, and one for the stack arguments. Each of these primitives will bake in one of the CFAs in **(2)** *at bind time* so that the primitives in **(1)** will be run *at call time*.
4. Create the `bind` word in Forth that examines the signature string and creates the marshaling/calling logic in the binding for the user's word.

### `bind`'s algorithm

We must consider that `bind`'s algorithm is a meta-algorithm. It is building a word that constructs a call and handles the return value. Therefore, we have to classify the algorithms that `bind` will produce. Simply put, we need some kind of parametric summary description of what a maxiForth external binding will do.

`bind` will look at this description and create four values:  an offset for `rsp`; the number of register arguments to load, if any are present; the number of stack arguments to copy, if any are present; and a marshaling specification for register arguments, if present.

#### Argument counts and offset for `rsp`

The following are the steps for calculating the offset and the numbers of register and stack arguments.

1. Take the length of the signature string.
2. If it's 2, set the offset to 32 (maxiForth is aligned to 16-byte boundaries internally.), set the number of stack arguments and the number of register arguments to 0, and skip past (8).
3. Subtract 2 from the length.
4. If the adjusted length is 4 or less, assign 0 to the number of stack arguments to copy, save the length as the number of register arguments, set the offset to 32, and skip past (8).
5. Interpret everything after the 4th character as an integer in base 10. Save that integer as the number of stack arguments to copy. Set the number of register arguments to 4.
6. Add the number of stack arguments to the number of register arguments.
7. If the result is odd, add 1 to it.
8. Multiply the number by `POINTER_SIZE`. (This value happens to be 8, so just shift the number over 3). This is the offset. 


Now bind knows the shape of what to lay down. Assuming that the word is created, `dovar` is replaced with `docol`, and `here` points to the start of the parameter field:

1. Lay down an XT for the word that subtracts the computed number of bytes from `rsp`.
2. Lay down the number of bytes to subtract.
3. If the number of arguments was larger than four, lay down an XT for the word that copies the stack arguments from the data stack to a block starting at `rsp + 32`.
4. If (3) was not a no-op, lay down the number of stack arguments to copy.
5. If the number of register arguments was greater than zero, lay down the word that loads register arguments.
6. If (5) wasn't a no-op, lay down the marshalling specification.

`bind` is now ready to process the return value and place the return block, if necessary. As well, it needs to unwind `rsp`. However, it's probably best to explain the marshalling specification.

#### Marshaling specification

The marshaling specification is a list of bytes, one for each register argument to marshal. The runtime marshaling code will be a series of four blocks, each representing 5 possible operations. (`i` and `u` in the signature string map to the same marshaling step.) `bind` needs only to know how to map letter codes to case values. Choosing between an integer register and a floating point register is accomplished by the runtime word by baking the operations into the word, jumping to the appropriate start based on the number of arguments, and shifting the bytes off the end of a register to aid with masking. **Table 4** explains the mapping. Basically, the possible values in the signature string are in the first column. They map to the marshaling code in the rightmost column. The middle three columns summarize what each block will do. 

**Table 4: Marshaling flags and actions.**

| Code | Register class | Operation | Source class | Case value |
|:----:|:---------------|:----------|:------------:|:----------:|
|  u   | e*             | mov       |      d       |     1      |
|  i   | r*             | popq      |              |     2      |
|  q   | r*             | popq      |              |     2      |
|  d   | r*             | movsxd    |      d       |     3      |
|  f   | x*             | movd      |      d       |     4      |
|  F   | x*             | movq      |              |     5      |
| 1,2  | r*             | movsxd    |     1,2      |     6      |
|  z   | r*             | movzx     |      1       |     7      |

Once `bind` lays down the XT for the register marshaling word and the marshaling specification (presumimg there are register arguments), or if there are no register arguments, `bind` now has to lay down the return handler.

#### The return handler

There are 11 possible return value codes. `bind` skips laying down the return handler for the `v` (void) case because there is nothing to handle. Of the 10 remaining, `B`, `q`, and `8` all map to `stack_pushq rax, DATA_TOS_REG`, collapsing our remaining 10 distinct actions to 8. Refer to **Table 4** for notes on the operations that the return handler performs for each type.

Because the return handler is only installed when there is a return value, we could not rely on it to restore the registers if that were important to us. The caller-saved registers are `rax`, `rcx`, `rdx`, `r8` through `r10`, and `xmm0` through `xmm5`. However,othing inside `maxiForth` currently depends on preserving any of these registers across word invocations. YAGNI for now, then. We can implement a preserving variant later. (We might implement varargs variants, too, which would expand the matrix of bind words from two entries up to four.)



#### Exiting

Trivially, we must remember to write the XT for `exit` at the end of the word in order to continue execution within the runtime.