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

LNVL does not directly build a list of instructions to execute.
Instead it creates a list of *opcodes.*  Each opcode contains the
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
from opcode to opcode.  This property may be `nil`, e.g. the `no-op`
opcode has no arguments table.

The method `LNVL.Scene:drawCurrentContent()` adds the aforementioned
`scene` property to `arguments`.  Because of this, opcodes *must not*
provide their own `scene` property because LNVL will overrite its
value when executing the related instruction.

If the global property `LNVL.Settings.DebugModeEnabled` is true then
LNVL will print the list of opcodes for each scene when the engine
creates it.


How Opcodes and Instructions Interact
-------------------------------------

When LNVL loads a scene, that is, an `LNVL.Scene` object, it creates
an array of opcodes.  Each piece of content in the scene, every
argument given to the `LNVL.Scene:new()` constructor, results in the
creation of one or more `LNVL.Opcode` objects which the engine
collects in that array.  This happens in the
`LNVL.Scene:createOpcodeFromContent()` method, which LNVL calls once
for each piece of scene content to transform it into opcodes.  The
specific transformation process is this:

1. If the content is a string then LNVL creates a simple `say` opcode
that will print that string.

2. If the content is an `LNVL.Opcode` object, which is the return
value of most functions used as arguments of `LNVL.Scene:new()`, then
LNVL sends it to a *processor.* The `LNVL.Opcode.Processor` table maps
the names of opcodes (listed below) to processor functions.  These are
functions which accept the content, i.e. opcode object, as its sole
parameter, augment it with any extra data that LNVL may need later
when converting that particular opcode into an instruction, and then
return the possibly-modified opcode.  **Note:** It is a fatal error
for any processor function to not return an opcode or array of opcode
objects.

3. If the content is a table with no metatable then LNVL assumes it is
an array of opcode objects and processes each as per the description
above.

Instructions are generic actions that LNVL provides, such as
displaying dialog or drawing an image.  Opcodes fill in the blanks of
instructions so that they have specific effects.  For example, the
`set-image` instruction provides a generic way to set the image for
any object; the `set-character-image` opcode creates a `set-image`
instruction with the additional information necessary to modify a
given character image.

That is the basic relationship between opcodes and instructions.
Opcodes provide specific parameters to instructions, which are more
generic actions in the engine.  Everything LNVL does that the user
sees is the result of executing an instruction.  This happens in the
`LNVL.Scene:drawCurrentContent()` method since scenes are what
contains the opcodes LNVL uses to piece together instructions.


List of Opcodes
---------------

Below are all of the opcodes used in the LNVL engine, listed
alphabetically by name.  Opcodes are always written in lowercase
within the engine code.  When the engine processes each opcode it
gives the opcode a table of arguments.  The entries below list those
arguments as well as the instruction(s) the opcode generates.

### Add-Menu ###

The `add-menu` opcode tells LNVL to insert an `LNVL.Menu` object into
the current part of the scene.  When the engine encounters the
corresponding object it will yield to a ‘menu handler’, a
[Lua coroutine][4] that will `yield` the player’s menu choice.

1. `menu`: A reference to the `LNVL.Menu` object responsible for the
   creation of the opcode.

### Change-Scene ###

The `change-scene` opcode tells LNVL to switch to a different scene,
i.e. another `LNVL.Scene` object.

1. `name`: The name of the scene the engine should change to.  This
must be a string naming an `LNVL.Scene` object accessible in global
scope, i.e. from the `_G` table.

### Deactivate-Character ###

The `deactivate-character` opcode tells LNVL to no longer draw a
character to the screen.

1. `character`: An instance of `LNVL.Character` representing the
character to deactivate.

### Monologue ###

The `monologue` opcode expands into multiple `say` opcodes, used by
the `LNVL.Character:monologue()` method to present multiple lines of
dialog by a single character at once.

1. `character`: An instance of `LNVL.Character` who is speaking the
monologue.

2. `content`: An array of strings representing lines of dialog.


### Move-Character ###

The `move-character` opcode changes the position of a character, as in
changing where it appears on the screen.

1. `character`: An instance of `LNVL.Character` which we move.

2. `position`: One of the `LNVL.Position.*` constants indicating where
on screen the character should appear, e.g. `LNVL.Position.Right`.

### No-Op ###

The `no-op` opcode is unique in that it invokes no instruction.
There are certain methods which can appear within a scene, such as
`LNVL.Character:isAt()`, which require no instruction to affect the
game.  However, because they appear in a scene they must return an
opcode in order for the engine to properly compile the list of
instructions to execute.  The `no-op` opcode exists for those
functions to use.

This opcode takes no arguments.

### Say ###

The `say` opcode generates a `say` instruction.  The commonly-used
methods of `LNVL.Character` objects create this opcode in order to
compile dialog for a particular scene.

1. `content`: A string representing the line of dialog.

2. `character`: *(Optional)* An instance of `LNVL.Character` who is
speaking the line.

### Set-Character-Image ###

The `set-character-image` opcode creates a `set-image` instruction
that will change the image used to display an `LNVL.Character` on
screen.

1. `character`: An instance of `LNVL.Character` to draw.

2. `image`: The new image to use for the character, which must be an
`LNVL.Drawable` object.

### Set-Character-Name ###

The `set-character-name` opcode creates a `set-name` instruction that
will change what name LNVL displays for a given character.  Note that
this does not change the actual name data, only the name which LNVL
shows in dialog scenes, e.g. this opcode cannot change the `firstName`
property of a character.

1. `character`: The instance of `LNVL.Character` to modify.

2. `name`: The name to display as a string, which must be one of four
   possible values:
       - `default`
       - `firstName`
       - `lastName`
       - `fullName`

### Set-Scene-Image ###

The `set-scene-image` opcode creates a `set-image` instruction that
will change the background image of a scene.

1. `image`: The new [background image][3] to use for the scene.

**Note:** This opcode logically requires an `LNVL.Scene` object to
modify but that is not part of the arguments.  The source-code
comments for `LNVL.Opcode.Processor["set-scene-image"]` explain in
detail why the opcode does not have a `scene` argument and how it gets
information about the scene later.


List of Instructions
--------------------

Below are all of the instructions recognized by LNVL, listed
alphabetically by name.  Instruction names are always written in
lowercase within the engine itself; e.g. the section for the ‘Say’
instruction refers to `say` in the code.  Following the description of
each instruction is a list of any required or optional arguments it
may have.

### Draw-Image ###

This instruction renders an image to the screen.  The arguments table
for its action function accepts the following properties:

1. `image`: The image to display.  This must be [an Image object][3]
or an `LNVL.Drawable` object.

2. `location`: *(Optional)* An array of two elements representing the X and Y
coordinates on screen where the engine will draw the image.

3. `border`: *(Optional)* An array of two elements representing a
solid-color border to draw around the image.  The first element must
be the color, either a table of RGB values or a color from the
`LNVL.Color` table.  The second element must be the width of the
border in pixels.  LNVL will only draw the border if `image` is an
`LNVL.Drawable` object.

4. `position`: *(Optional)* A constant from the `LNVL.Position` table
indicating the relative position on screen where the image should
appear.  LNVL only uses this value if `image` is an `LNVL.Drawable`
object.

**Note:** The instruction must receive either `location` or
`position`.  If the instruction receives both then `location` always
takes precedence.

### No-Op ###

This instruction is a no-op, i.e. no operation.  It does nothing.
LNVL never generates this instruction.  However, it must exist because
every opcode must have a corresponding instruction, in this case the
`no-op` opcode.

### Set-Name ###

This instruction changes the name of a given target object.

1. `target`: The object whose name is changed.  Currently the
   instruction only accepts `LNVL.Character` objects for this.

2. `name`: The name to use.  See the description of the `name`
   parameter for the `set-character-name` opcode for further
   information.

### Set-Position ###

This instruction changes the position of a target object, affecting
where it appears on screen.  The engine does not explicitly prevent
the creation of this instruction for target objects which it cannot
draw to the screen.  However, generating this instruction for such
objects serves no useful purpose.

1. `target`: The object whose position will change.  This object must
   have a `position` property that allows `LNVL.Position` objects for
   its value.

2. `position`: The new position as an `LNVL.Position` object.

### Say ###

This instruction prints dialog to the screen.  The arguments table for
its action function requires the following properties:

1. `content`: A string representing the dialog to say.

2. `character`: *(Optional)* A instance of an `LNVL.Character` who
will speak the dialog.  If this argument is present the text will
appear in the color defined by the `character.textColor` property.

### Set-Image ###

This instruction changes images for scenes, characters, and anything
else that uses images for display.  The arguments table for its action
function requires the following properties:

1. `target`: The object whose image will change.  Currently the engine
supports only `LNVL.Character` objects as valid targets.

2. `image`: The new image to use.  This must be [an `Image` object][3]
or an `LNVL.Drawable` object.

### Set-Scene ###

This instruction changes the currently active scene.  The arguments
table for its action function requires one property:

1. `name`: The name of a scene as a string to use as the new current
scene.  The instruction looks for an `LNVL.Scene` object with this
name in the global scope, i.e. inside of `_G`.  That scene becomes the
value of the global `LNVL.CurrentScene` variable.

### Show-Menu ###

This instruction shows the player a menu and waits until he selects
one of its choices.  LNVL will [resume][4] the coroutine
`LNVL.Settings.Handlers.Menu`, passing it one argument: the
`LNVL.Menu` object representing the current menu.  That function must
return one value: a string naming the menu choice selected by the
player, i.e. a valid key for the `LNVL.Menu.choices` table of the menu
that results in the execution of this instruction in the first place.

LNVL provides a dummy handler for this purpose, but game developers
should create their own so that they can handle input and the display
of graphics in ways more fitting for their particular game.  The
`src/settings.lua` file is the place to assign custom handlers.



[1]: http://www.lua.org/manual/5.1/manual.html#2.5.7
[2]: http://www.lua.org/manual/5.1/manual.html#2.8
[3]: https://love2d.org/wiki/Image
[4]: http://www.lua.org/manual/5.1/manual.html#5.2
