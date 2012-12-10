LNVL Instruction Set
====================



Introduction
------------

The LÖVE Visual Novel (LNVL) engine works by executing a series of
‘instructions’.  These instructions tell the engine to display dialog,
change a background image, bring a character sprite into view, and so
on.  This document explains the technical design of the instruction
system and how it fits into LNVL.  Computer programmers who want to
extend the functionality of LNVL will hopefully find this information
useful.


Structure of Instructions
-------------------------

Instructions in LNVL are [tables][1].  They all have the
[metatable][2] `LNVL.Instruction`.  This way programmers can use
`getmetatable()` to identify LNVL instructions.  Each instruction has
the following properties:

1. `name`: A string naming the instruction.  This is the intended way
to differentiate between instructions.

2. `action`: A function that executes the instruction.  The function
accepts a table of arguments but the exact arguments differ from
instruction to instruction.  See the documentation for individual
instructions for details on what arguments they require.  These
functions are not expected to return anything.

**Note:** Unless stated otherwise, the arguments table for the action
function of every instruction has a `scene` property representing the
`LNVL.Scene` object containing the instruction.

Every `LNVL.Instruction` object exists in the `LNVL.Instructions`
table.  The keys are the names of the instructions as strings.  The
values are the objects themselves.


Opcodes and Their Role
----------------------

LNVL does not *directly* build a list of instructions to execute.
Instead it creates a list of ‘opcodes’.  Each opcode contains the
information LNVL needs to determine which instruction to run and how
to run it.  This extra step of indirection in the process allows LNVL
to pass additional information to instructions more easily.

Each `LNVL.Scene` has a list of opcodes that describe what happens in
that scene.  As the player steps through the scene in the game, LNVL
steps through each opcode one-by-one.  Multiple opcodes may point to
the same instruction but provide different supplementary data, e.g. a
scene may have a lot of opcodes for the `say` instruction but each
will provide its own line of dialog.

The `LNVL.Opcode` class represents opcodes.  An opcode has two
properties:

1. `name`: The name of the instruction LNVL should execute when
it encounters this opcode.

2. `arguments`: A table of additional arguments to give to the
instruction when LNVL executes it.  The definitions of the
instructions dictate the contents of this table, so they will vary
from opcode to opcode.


List of Instructions
--------------------

Below are all of the instructions recognized by LNVL, listed
alphabetically by name.  Instruction names are always written in
lowercase within the engine itself; e.g. the section for the ‘Say’
instruction refers to `say` in the code.  Following the description of
each instruction is a list of any required or optional arguments it
may have.

### Say ###

This instruction prints dialog to the screen.  The arguments table for
its action function requires the following properties:

1. `content`: A string representing the dialog to say.

2. `character`: **(Optional)** A instance of an `LNVL.Character` who
will speak the dialog.



[1]: http://www.lua.org/manual/5.1/manual.html#2.5.7
[2]: http://www.lua.org/manual/5.1/manual.html#2.8