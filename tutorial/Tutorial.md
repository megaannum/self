# Self Tutorial

This is a tutorial covering the use of the VimL Self library.

The Self library had its origins soon after Vim 7.0 came out and
was sporadically worked upon for a number of years prior to its
posting on www.vim.org.

# Reflections

Some might object to some of the reflections here.
Well, I objected to the killing of the Branchidae.
But what can one do? Despair, lessons are rarely actually 
learned, so just keep on truckin'.

With version 7.0, VimL just had enough features to allow for
a library to extend it with Object Prototype capabilities.
The Dictionary data structure allowed one to associated functions
with the Dictionary and those functions had the concept of 'self', a reference
to the Dictionary instance.

Object Prototype languages do not have Class-base inheritance
but rather Object-base inheritance. One clones an Object instance
and then modifies and/or adds-to its attributes and methods to make a new 
Object 'kind'. The earliest instance of such an object-oriented
language, that I am aware of, was the Self language by
Dave Ungar and Randy Smith. For those whose knowledge of
Computer Science starts with the Internet, Javascript is also
an Object-base object-oriented language.

Now, whether the Vim 7.0 enhancements that permitted an Object-base
extension library was intensional or simple incidental could be a matter
of discussion. There are two key features that are missing and have to
be bolted on in order to get an Object-base language.
Without those features, VimL is closer to Ada vintage mid-1980s than
Javascript. You will recall (or maybe not) that with the original Ada,
one could create objects but there was no inheritance. Possibly, the
USA DoD felt that inheritance was too new and the associated
tools and techniques concerning inheritance were too untested 
to base the One-true-language-to-rule-them-all on. They might have been 
right, but, as a result, the One-language certainly allowed for the evolution 
of more advanced languages. Anyway, VimL allows for the creation of objects,
Dictionaries, but there is no support for inheritance.

Some might say, "We don't need no stinking Objects"; VimL is just
perfect the way it is. Well, if that were true, then Vim would not
have any complier bindings for some of the ghetto scripting 
languages. There are a handful of object-oriented scripting languages 
for which there are Vim compiler plugins. These would not exist unless 
folks thought there was a need. It is a shame that when Vim 7.0 came out
it was not recognized that with, possibly a bunch of extra work, one
of the very fast (far faster than the ghetto languages) Javascript
engines could be modified and used as a replacement VimL engine
allowing for a full object-oriented VimL (VimOOL).

So, what does VimL lack. First, a Dictionary data structure does not have
any notion of a 'prototype' parent Dictionary. It can not inherit either
attributes, key/value pairs, nor methods, whether named functions bound
to a Dictionary or un-named, numbered functions defined directly to the
Dictionary.

Example named and numbered Dictionary methods:

    let d = {}

    " named
    function! NamedFunc() dict 
      " functioncode
    endfuction
    let d.named = function("NamedFunc")

    " numbered
    function! d.numberedFunc() dict 
      " func code
    endfuction

To compensate for the lack of a 'prototype', all objects in the Self
library have the '_prototype' attribute which holds the parent object.
Because the '_prototype' value is the parent, when an object is cloned,
it is not a deep-clone.

The second feature that is missing is the ability of an object to call 
its prototype's method and prototype prototype's method, etc. And, no
the Vim 'call()' method is not enough. Consider that one has three
objects: A, B and C; where A is B's prototype and B is C's prototype.
In addition, A, B, and C all have a method 'm()' where we want the
C object to call its 'm()', internally, have the 'C.m()' method
call its prototype's 'm()' method 'B.m()' and, finally, have the 'B.m()'
call its prototype's 'm()' method 'A.m()'.

    function A.m() dict 
      " local code
    endfuction

    function B.m() dict 
      " local code
      " call prototype m()
    endfuction

    function C.m() dict 
      " local code
      " call prototype m()
    endfuction

What does the code look like in 'C.m()':

    function C.m() dict 
      " local code
      " call prototype m()
      let prototype = self._prototype " note that prototype == B
      call call(prototype.m, [], self)
    endfuction

and, doing the same for B:

    function B.m() dict 
      " local code
      " call prototype m()
      let prototype = self._prototype 
      call call(prototype.m, [], self)
    endfuction

But wait, in 'B,m()' when called from C's 'm()', the self reference is
C not B. So, 

      let prototype = self._prototype 

refers to C's prototype, not B's. So, within 'B.m()' when called from
'C.m()' the prototype object is B, not A. Thus 'B.m()' will call B's
'm()' once again with self being C once again. And you run out of stack.

With languages with true prototype support there is a mechanism for
an object to call its prototype's method, which, in turn can call its
prototype's method, and so on and this mechanism is transparently supported.
With the Self library due to VimL's limitation, such support must be
provided by an ad-hock convention.

One way to do this is by having all Self object methods support
a variable number of arguments where the last such argument, if
it exists, is the current object (in the above case B), not the
calling object, self (in the above case C). Thus, C's method would be:

    function C.m(...) dict 
      " local code
      " call prototype m()
      if a:0 > 0
        let prototype = a:1._prototype " note that prototype == B
      else
        " In this case, it would be B, but if there was an object D
        " derived from C, then D.m() would result in this being C, not B
        let prototype = self._prototype " note that prototype == B
      endif
      call call(prototype.m, [prototype], self)
    endfuction

and B's method:

    function B.m(...) dict 
      " local code
      " call prototype m()
      if a:0 > 0
        let prototype = a:1._prototype " note that prototype == C
      else
        let prototype = self._prototype " note that prototype == B
      endif
      call call(prototype.m, [prototype], self)
    endfuction

This will work, but is rather verbose and developers will forget to
do it.

So, as far as I can tell there is no real good solution.

Within the Forms library, which is based upon Self, I tend to simply
hard-code a method's prototype within it. This disallows true
method inheritance chaining but is simple and concrete.

    let g:A = { ... }
    function g:A.m() dict 
      " local code
    endfuction

    let g:B = { ... }
    function g:B.m() dict 
      " local code
      " call prototype m()
      let prototype = g:B._prototype " note that prototype == C
      call call(prototype.m, [], self)
    endfuction

    let g:C = { ... }
    function g:C.m() dict 
      " local code
      " call prototype m()
      let prototype = g:C._prototype " note that prototype == B
      call call(prototype.m, [], self)
    endfuction

The key for the above to work, is that the Objects, be globals so that
where ever the method happens to execute, they can be accessed.

## Object Prototype

At the top (bottom) of the Object, prototype, prototype, ,,, chain is
the Object Prototype defined in the self.vim file:

    let g:self_ObjectPrototype = { 
                            \ '_kind': 'self_ObjectPrototype' , 
                            \ '_prototype': '' }

Note that this is a global. Its 'kind' is 'self_ObjectPrototype' and
its 'prototype' is the empty String, not the empty Dictionary.
This is the only object whose prototype is not a Dictionary.
In addition to the attributes created explicitly, when the Object
Prototype is registered with the Prototype Manager (see below) it is given
a Number 'id' (_id) attribute which is unique per object.

## Common Attributes

All Objects that the following three attributes:

- kind 
    The kind of Object it is whether the base Object of that kind or a clone of the base Object.
- prototype
    The Object's parent Object.
- id
    A unique Number used both as a key by the Managers for Object lookup and for the generation of an Object's String tag (if the tag has not be explicitly set).

When a new Prototype kind is defined, its 'kind' is not the same as its prototype's 'kind'. On the other hand, when a Prototype is cloned, the clone's 'kind' is the same as its prototypes (the Object from which it was cloned). A new Prototype 'kind' has additional attributes and/or methods from its own prototype, else, why define a new Prototype 'kind' - simply clone the prototype.

## Common Methods

All Objects that the following public methods:

- init(attrs)
    Initialize the Object's attributes with the key/values in the attrs argument Dictionary. If the Object has an attribute of the form '__' + 'attributeName' and if 'attributeName' is a key in the attrs Dictionary, then set the attribute to the associated value from the attrs Dictionary.

- getKind()
    Return the 'kind' of this Object.

- isKindOf(kind)
    Return 'true' if the Object or any Object in its prototype chain is the same kind as the 'kind' argument and return false otherwise.

- getProtoType()
    Return the Object's prototype.

- equals(obj)
    Returns true if Object's 'id' attribute value equals the 'obj' argument's 'id' value (assuming that 'obj' is a Dictionary with attribute 'id').

- super()
    This seems to simply return the Object's prototype but in a round about manner. Have to determine if if is any different from 'getProtoType()'.

- clone(...)
    Make a shallow copy of Object.

- delete(...)
    Perform a shallow delete of Object.

Many times code will simply use 'obj._prototype' rather than 
'obj.getProtoType()' since they should be the same thing.
Many times code will simply use 'obj._kind' rather than 
'obj.getKind()' since they should be the same thing.

## Objects and Prototypes

In the Self library there is a distinction between those objects that
define a new 'kind' and those that are clones of an existing 'kind'.
Of course, a new 'kind' is also a clone of an existing 'kind' but
a new 'kind' has a new kind-name. This is rather artificial, but one
distinction is important. During a Vim session, new kinds should not be 
deleted because they are the basis of Objects created for an 'application', 
While application Objects come and go as an application is run and then
stopped. As such, application Objects should be deleted when an application
is stopped (and will, most likely, not be run again during a Vim session).
This is a matter of garbage collection and memory usage.

So, Objects whose creation define a new kind, additional attributes and 
method, should not be deleted during a Vim session, but those Objects that
are created to make and run an application, should be deleted.

And, that is the distinction between Objects in Self. An Object that,
for example, defines a rational number with its 'numerator' and 
'denominator' Number attributes as well as methods for addition, subtraction,
etc., is a Prototype object. But a clone of this Object which is used 
as part of an application is simply an Object.

## Managers

There are two Object Managers in Self: one stores Prototype objects using
their 'id' attribute as a key and the other stores Objects using, again,
using their 'id' attributes. When an application has finished running, it
should be safe to ask the Object manager to delete all of its Objects.
On the other hand, if there is any expectation that the application or
another application might be run during a Vim session, then the Prototype
object Manager should not have its objects deleted.

The Prototype object Manager assigns unique negative numbers to an Object's
'id' attribute when it is registered. The Object Manager assigns unique
positive numbers to Object when they are registered.

## Example Usage

In the following example, a rational number Object will be created
along with a test function exercising the code.
For the code, see 
[Rational](https://github.com/megaannum/self/autoload/self/rational1.vim)
and
[Rational2](https://github.com/megaannum/self/autoload/self/rational2.vim)

There maybe many ways to structure code that defines a new Object Prototype
kind. Here, two ways will be described.

In both ways, a Dictionary is created that represents the Rational
Object Prototype and it has the Object Prototype as its prototype
and it has 'kind' self#rational1#Rational
(or self#rational2#Rational for the second example).
Additionally, it has 'num' and 'den' (numerator and denominator) attributes
and a number of additional methods.

To test either way, one can run 
':call self#rational1#Test()' and ':call self#rational2#Test()'.

Both ways of organizing the code define Rational Object methods using
'named' functions. The following is an example of the 'named' function
approach:

    function! SELF_RATIONAL_toString() dict
      return (self.__den == 1)
            \ ? "" . self.__num
            \ : "" . self.__num . "/" . self.__den
    endfunction
    let g:self#rational1#Rational.toString = function("SELF_RATIONAL_toString")

The name of the Rational Object's 'toString' method is 'SELF_RATIONAL_toString'
which corresponds to its namespace plus method name.

In both ways, it is the case that one needs to be able to support the
resourcing or reloading of the code during the development process. And,
I do not mean: exiting Vim, restarting Vim and then resourcing the file
under development or executing autoload via a function call.
Rather, some quick, explicit way for a developer to reload the code.

### Development Mode Guard

One way of supporting the reloading of the definition of a Rational is
to 'unlet' the definition every time the file is sourced when in
development mode. In the following selection of code from 'rational1.vim',
when the file is re-sourced in development mode, it the Rational
Object definition is defined, then it is 'unlet' (undefined).
Then in the 'self#rational2#loadRationalPrototype()' function,
if the Rational Object is not defined, it is defined.
When using this approach, after changes have been made to the file,
the developer needs to re-source the file for those changes to be seen.

    if g:self#IN_DEVELOPMENT_MODE
      if exists("g:self#rational1#Rational")
        " force reload of Rational definition
        unlet g:self#rational1#Rational
      endif
    endif

    " define Rational
    function! self#rational2#loadRationalPrototype()
      if !exists("g:self#rational1#Rational")
        let g:self#rational1#Rational = self#LoadObjectPrototype().clone('self#rational1#Rational')

        " code defining attributes and methods .....

      endif

      return g:self#rational1#Rational
    endfunction

    " Rational constructor
    function! self#rational1#newRational(attrs)
      return self#rational1#loadRationalPrototype().clone().init(a:attrs)
    endfunction

This approach was the second way I chose to structure Object code (the
first way was quite simply wrong and never saw the light of day).
It has the advantage that all the code that defines a Rational is
in the 'self#rational2#loadRationalPrototype()' function,
Its disadvantage is that it requires the developer to re-source the
file, implying that the developer must know where the file is.

It should be noted that this approach was used originally on code
that was not 'autoload' ready - all of the code was in the 'plugin'
directory and was all sourced on Vim startup.

### Self Reload Function

Another way is to use the fact that the code is 'autoload' ready.
Here there is a 'reload()' function that calls the Self library
'reload(prefix)' function. This function deletes all functions
whose name starts with the given 'prefix'. So, this this case the
prefix is 'self#rational2#'. In development mode, one simply 
executes 'self#rational2#reload()' and code in the file will
be reloaded, re-sourced, the next time one of its functions is called.

    if !exists("*self#rational2#reload")
      if g:self#IN_DEVELOPMENT_MODE
        " force reload of Rational definition
        function self#rational2#reload() 
          call self#reload('self#rational2#')
        endfunction
      endif
    endif

    " define Rational
    let g:self#rational2#Rational = self#LoadObjectPrototype().clone('self#rational2#Rational')

    " code defining attributes and methods .....

    " Rational constructor
    function! self#rational2#new(attrs)
      return g:self#rational2#Rational.clone().init(a:attrs)
    endfunction

This code does not have the encapsulation of the Rational code that
the first approach has, but it is cleaner and clearer.

## Fixing VimL

Can VimL be altered so that it natively supports prototype-base Objects?
Well, of course, it can. Thats why its called software. So, rather,
what would need to be done and how hard would it be?

It has been identified that there is no support for the notion of the
current 'prototype' when calling Dictionary functions. There is a
notion of current 'self'. As one calls a method up a prototype chain,
the 'self' Object does not change but the 'prototype' Object, the Object
that has the next method in the chain, does change.

To address this, such methods should have associated with them as
part of their data, the Object for which they were initially created.
From that Object, its prototype could then be a known object within the
method:

    let g:A = < ... >
    function g:A.m() obj
      " local code
      " the 'prototype' is the VimL base object (by default)
    endfuction

    let g:B = g:A< ... >
    function g:B.m() obj
      " local code
      " 'prototype' is g:A since g:B has prototype g:A
      " call prototype m()
      call call(prototype.m, [], self)
    endfuction

    let g:C = g:B< ... >
    function g:C.m() obj 
      " local code
      " 'prototype' is g:B since g:C has prototype g:B
      " call prototype m()
      call call(prototype.m, [], self)
    endfuction

Above, is a possible way of encoding the notion of Object (rather than
Dictionary) and 'prototype' as know name in an Object method.
Not saying this is the best way or only way, just an example.
The '< ... >' are the same as a Dictionary's '{ ... }' but signify 
that an Object is being created. And, 'obj< ... >' says that the
new object has 'obj' as its prototype. If 'obj' is missing, then
VimL's base prototype object is used as the prototype by default.
A 'clone' method would also be supported.

There would be a new data type in Vim called Object which is like
a Dictionary but supports functions (methods) that have the 'obj'
rather than the 'dict' tag associated with them. The 'obj' tag
says that there is a 'prototype' local variable (like the 'self'
local variable) defined in the context of the function.
The declaration of an Object type is like a Dictionary but there
1) has to be a way to distinguish a Object vs Dictionary definition and 2)
there has to be a way to declare and optional prototype object.

Also needed is that any of the Object types have an attribute called
'prototype' that holds it prototype object.


The last and much more ambitious change would be to embed a Javascript engine
(with modification) in Vim and use it to run the VimL + Objects code.

