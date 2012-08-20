# self

Self: Vim prototype object system

# Introduction

Vim Self Object Prototype System allows developer to create 
object-base scripts (inspired after the David Ungar's Self language). 

This code to be used by script developers, not for direct use by
end users (by itself, it does nothing).

When Vim version 7.0 with dictionary variables and function references
came out, I created this object prototype support script. At that time 
I was planning to write a text-base windowing system on top of Vim which
would allow script to create such things as forms. During script
installation having per-script driven forms allowing for the tailoring
of the script environment might have been a good thing.

Anyway, time pasted and I moved onto other projects without really
finishing this script. Then I wanted to create a Scala language
comment generation script much like the jcommenter. Vim script for
Java. My first cut, version 1.0, was all imperative: enumerations for
the different entity types (class, object, 
method, etc.); with functions for different behaviors and 
switch-case statements (i.e., if-elseif-endif) using the enumeration 
to determine which block of Vim script to execute. This worked
but each entity's behavior was scattered throughout the script file.

I then thought to dust off my old object system and re-casting my
Scala comment generator using it. While the code size is the same,
now behavior is near the data (or in an object's prototype chain).

So, here is the code. Along with this file there are some simple usage
example files also in the download. None of the examples, though, are
as complex as what is done in the scalacommenter.vim script.

Later, I wanted to enhance Envim to allow one to enter refactoring options.
This required some sort of forms capability. Hence, I built {Forms}
a Vim library, but, along the way, discovered some bugs in the self code.
With this release, I hope they have all been fixed.

# Installation

The Self 'self.vim' code file should be in the 'autoload' directory and the
'self.txt' in the 'doc' directory.

## Intalling with vim-addon-manager (VAM)

For more information about vim-addon-manager, see [vim-addon-manager](https://github.com/MarcWeber/vim-addon-manager) and [Vim-addon-manager getting started](https://github.com/MarcWeber/vim-addon-manager/blob/master/doc/vim-addon-manager-getting-started.txt)

In your .vimrc, add self as shown below:

    fun SetupVAM()

      ...

      let g:vim_addon_manager = {}
      let g:vim_addon_manager.plugin_sources = {}

      ....

      let g:vim_addon_manager.plugin_sources['self'] = {'kind': 'git', 'url': 'git://github.com/megaannum/self'}

      let plugins = [
        \ 'self'
        \ ]

      call vam#ActivateAddons(plugins,{'auto_install' : 0})

      ...

    endf
    call SetupVAM()


Now start Vim. You will be asked by vim-addon-manager 
if you would like to download and install the self plugin (no dependencies).

## Installing with pathogen

I do not use pathogen. An example usage would be welcome.

# Usage

A function is created that return a label prototype object.

    if g:self#IN_DEVELOPMENT_MODE
      if exists("g:forms#Label")
	unlet g:forms#Label
      endif
    endif
    function! forms#loadLabelPrototype()
      if !exists("g:forms#Label")
	let g:forms#Label = self#LoadObjectPrototype().clone('forms#Label')
	let g:forms#Label.__text = ''
        ....
      endif
      return g:forms#Label
    endfunction

Then, a contructor function is defined that takes a Dictionary of attributes
as its parameter, clones the Label prototype object and then initializes
with the attributes.

    function! forms#newLabel(attrs)
      return forms#loadLabelPrototype().clone().init(a:attrs)
    endfunction

Application code would then create a label instance by calling the
constructor function.

    let attr = {'text': 'Some text'}
    let label = forms#newLabel(attr)

In addition, one can clone an existing instance and change the clone's
attribute value.

    let label_2 = label.clone()
    let label_2.__text = 'Some other text'

It is always the case that care must be taken in directly setting an object's
attribute because there could be some underlying semantics associated with the
value which are being by-passed by directly setting it. The prototype's
'init(attr)' may check those semantics (or there might be a setter method).

## Vim

[Vim location](http://www.vim.org/scripts/script.php?script_id=3072)

## Tutorial

There is a self tutorial which can be accessed at [Self tutorial](https://github.com/megaannum/self/blob/master/tutorial/self/Tutorial.md)
and the two example Rational number implementations covered in 
the tutorial are located at
[Rational1](https://github.com/megaannum/self/blob/master/autoload/self/rational1.vim)
and
[Rational2](https://github.com/megaannum/self/blob/master/autoload/self/rational2.vim)

## Acknowledgements and thanks

- Andy Wokula: provided feedback on help file syntax.
