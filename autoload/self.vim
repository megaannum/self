" ============================================================================
" self.vim
"
" File:          self.vim
" Summary:       Vim Self Object Prototype System
" Author:        Richard Emberson <richard.n.embersonATgmailDOTcom>
" Last Modified: 2012
" Version:       2.5
"
" Tested on vim 7.3 on Linux
"
" ============================================================================
" Intro: {{{1
" Vim Self Object Prototype System allows developer to create 
"   object-base scripts (inspired after the David Ungar's Self language). 
"
" This code to be used by script developers, not for direct use by
"   end users (by itself, it does nothing).
"
" When Vim version 7.0 with dictionary variables and function references
"   came out, I created this object prototype support script. At that time 
"   I was planning to write a text-base windowing system on top of Vim which
"   would allow script to create such things as forms. During script
"   installation having per-script driven forms allowing for the tailoring
"   of the script environment might have been a good thing.
"
" Anyway, time pasted and I moved onto other projects without really
"   finishing this script. Then I wanted to create a Scala language
"   comment generation script much like the jcommenter.Vim script for
"   Java. My first cut, version 1.0, was all imperative: enumerations for
"   the different entity types (class, object, 
"   method, etc.); with functions for different behaviors and 
"   switch-case statements (i.e., if-elseif-endif) using the enumeration 
"   to determine which block of Vim script to execute. This worked
"   but each entity's behavior was scattered throughout the script file.
"
" I then thought to dust off my old object system and re-casting my
"   Scala comment generator using it. While the code size is the same,
"   now behavior is near the data (or in an object's prototype chain).
"
" So, here is the code. Along with this file there are some simple usage
"   example files also in the download. None of the examples, though, are
"   as complex as what is done in the scalacommenter.vim script.
"
" Later, I wanted to enhance Envim to allow one to enter refactoring options.
"   This required some sort of forms capability. Hence, I built Forms
"   a Vim library, but, along the way, discovered some bugs in the self code.
"   With this release, I hope they have all been fixed.
"
" ============================================================================
" Caveats: {{{1
" Without deeper native VimScript support for object prototypes, I suspect
"   that there is a performance penalty when using objects rather than
"   imperative functions and switch-case statements.
" Method lookup is static, a child object knows its parent (prototype) 
"   object's method at its creation. Post-creation if the parent adds 
"   a new method, the child can not access it.
"   Method dispatch does not dynamically walk up the parent chain attempting
"   to find a given method, if the child does not have the method (if
"   the child, which is a dictionary, does not have the method as a key,
"   then an error occurs - no chance to walk up the parent hierarchy.
" When an object has a type name (the '_kind' key) that ends with the string 
"   'Prototype', then children of the object have the object as their parent 
"   (their prototype) and the child's type name will be parent's type
"   name with the 'Prototype' part removed.
"   On the other hand, when an object does not have the string 
"   'Prototype' in its type name, then children of the object have 
"   the object's parent as their parent and have the same type name as
"   the object. If this is not done, then when the child objects call
"   a method a recursion error occurs. The Vim "call()" mechanism is
"   not powerful enough to support passing the object, 'self', as well
"   as chaining up the prototype hierarchy with self._prototype, 
"   self._prototype._prototype, self._prototype._prototype._prototype
"   and so on. Bram Moolenaar if you want to discuss this, contact me.
" All of the object methods are anonymous functions that make debugging
"   really hard; for a stack trace all you get are a bunch of numbers
"   as function names. Now, if you print out the keys of an object you
"   get both the function name and its number. Its too bad that stack
"   trace print the function's number rather than the function's name.
" Objects based upon the self prototype are separated into two types: those
"   that serve as prototypes for an application's objects and those that
"   are simply part of the prototype hierarchy. These are called out
"   separately because after an application is done, one might wish to
"   free up some memory and delete the objects associated with the
"   application, but one does not want to delete the base prototype
"   objects since they might be used again - for instance, if the
"   application is re-invoked. To that end, all objects have an '_id'
"   attribute, but for objects in a prototype hierarchy, the _id's
"   are negative number while for "application" objects, the _id's
"   are positive. Also, there are two different object managers, one
"   for each type of object. 
"
" ============================================================================
" Configuration Options: {{{1
"   These help control the behavior of Self.vim
"   Remember, if you change these and then upgrade to a later version, 
"   your changes will be lost.
" ============================================================================

" If set to true, then when re-sourcing this file during a vim session
"   static/global objects may be initialized again before use.
if ! exists("g:self#IN_DEVELOPMENT_MODE")
  let g:self#IN_DEVELOPMENT_MODE = 1
endif


" ============================================================================
" Description: {{{1
"
" Base Object Prototype for creating a prototype-base object inheritance
"   hierarchy. 
"
" This is not a class-base Object-Orient system, rather it is 
"   prototype-base. The Self language was, I believe, the first such
"   language. One of the more popular language today is prototype-base
"   (Do you know which language I am referring to?).
"
" With prototype-base OO language, child objects are created by making
"   a copy of another, the parent or prototype, object. Additional 
"   instance variables and methods can be added to the child object. Also,
"   methods of the child's parent (again, its prototype) can also 
"   be redefined.
"
" By convention, the names of public methods and values should not start
"   with an underscore. Private methods and values have names starting
"   with a single leading '_'. Methods and values with names starting 
"   with multiple '_'s are protected. 
"   Public and protected methods and values are copied into child
"   objects during creation. Private methods and values are not copied
"   during object creation.
"
" ============================================================================
" Installation: {{{1
"
" 1. If needed, edit the configuration section. Any configuration options
"   are commented, so I won't explain the options here.
"
" 2. Put something like this in your .vimrc file:
"
"      source $VIM/macros/self.vim
"      source $VIM/macros/some_scrip.vim
"
"   or wherever you put your Vim scripts.
"   Here, some_scrip.vim a script that requires the self.vim script
"   
" ============================================================================
" Usage: {{{1
"
" For the end-user there is no particular usage information.
"
" ============================================================================
" Comments: {{{1
"
"   Send any comments or bugreports to:
"       Richard Emberson <richard.n.embersonATgmailDOTcom>
"
" ============================================================================
" THE SCRIPT
" ============================================================================

" Load Once: {{{1
if &cp || ( exists("g:loaded_self") && ! g:self#IN_DEVELOPMENT_MODE )
  finish
endif
let g:loaded_self = 'v2.5'
let s:keepcpo = &cpo
set cpo&vim

function! self#version()
  return '2.5'
endfunction

" ++++++++++++++++++++++++++++++++++++++++++++
" Reload : {{{1
" ++++++++++++++++++++++++++++++++++++++++++++

" ------------------------------------------------------------ 
" self#reload: {{{2
"  With Vim autoloading, this function can be used to force a 
"    reloading of functions that were autoloaded.
"  This function is only available in development mode, i.e.,
"    g:self#IN_DEVELOPMENT_MODE == 1
"  To make reloading of autoloaded functions simple, one might
"    want to define a mapping. Lets say your prefix is 'joesvimcode#'.
"    Then the mapping might be:
"      map <Leader>r :call self#reload('joesvimcode#')
"    or if there is a sub-code base to be reloaed
"      map <Leader>r :call self#reload('joesvimcode#somesubcode#')
"  To reload the self.vim functions use:
"    :call self#reload('self#')
"
"  Note that calling self#reload will delete/unlet all objects, so
"    if you are working on a library that uses the self library,
"    you really ought to reload that liberary at the same time.
"
"  parameters: 
"    prefix : The autoload function prefix to match function
"              names against. For instance, to force reload of
"              self functions, the prefix should be 'self#'.
" ------------------------------------------------------------ 
if !exists("*self#reload")
  if g:self#IN_DEVELOPMENT_MODE
    function self#reload(prefix) 
      call self#load_function_names()
      if exists("g:self_function_names")
        let fnlist = split(g:self_function_names, '\n')
        for fn in fnlist
          if fn =~ a:prefix
            let n = strpart(fn, 9)
            let i = stridx(n, '(')
            let n = strpart(n, 0, i)
            let FR = function(n)
            try
              delfunction FR
              " echo "delete " .n
            catch /.*/
              " can not delete current function
            endtry
          endif
        endfor
        unlet g:self_function_names
      endif
    endfunction
  endif
endif

" ------------------------------------------------------------ 
" self#load_function_names: {{{2
"  Load all function names into g:self_function_names
"  parameters: None
" ------------------------------------------------------------ 
function! self#load_function_names() 
    execute "redir => g:self_function_names"
    silent function
    execute "redir END"
endfunction


" Utils : {{{1
" ============================================================================
" Public functions
" ============================================================================

" ++++++++++++++++++++++++++++++++++++++++++++
" Print a dictionary item to standard output
" ++++++++++++++++++++++++++++++++++++++++++++

" ++++++++++++++++++++++++++++++++++++++++++++
" Vim type enumerations.
" ++++++++++++++++++++++++++++++++++++++++++++
" Existance check is to allow reloading of file.
if ! exists("g:self#NUMBER_TYPE")
  let g:self#NUMBER_TYPE     = type(0)
  lockvar g:self#NUMBER_TYPE
endif
if ! exists("g:self#STRING_TYPE")
  let g:self#STRING_TYPE     = type("")
  lockvar g:self#STRING_TYPE
endif
if ! exists("g:self#FUNCREF_TYPE")
  let g:self#FUNCREF_TYPE    = type(function("tr"))
  lockvar g:self#FUNCREF_TYPE
endif
if ! exists("g:self#LIST_TYPE")
  let g:self#LIST_TYPE       = type([])
  lockvar g:self#LIST_TYPE
endif
if ! exists("g:self#DICTIONARY_TYPE")
  let g:self#DICTIONARY_TYPE = type({})
  lockvar g:self#DICTIONARY_TYPE
endif
if ! exists("g:self#FLOAT_TYPE")
  let g:self#FLOAT_TYPE     = type(0.0)
  lockvar g:self#FLOAT_TYPE
endif

function! self#printDict(item) 
  for key in keys(a:item)
   echo key . ': ' . string(a:item[key])
  endfor
endfunction

function! CaptureFunDef(fname)
  execute "redir => g:fundef"
  execute "function " . a:fname
  execute "redir END"
endfunction

function! GetFunDef(fname)
  silent call CaptureFunDef(a:fname)
  return string(g:fundef)
endfunction

" ++++++++++++++++++++++++++++++++++++++++++++
" g: varname  The variable is global
" s: varname  The variable is local to the current script file
" w: varname  The variable is local to the current editor window
" t: varname  The variable is local to the current editor tab
" b: varname  The variable is local to the current editor buffer
" l: varname  The variable is local to the current function
" a: varname  The variable is a parameter of the current function
" v: varname  The variable is one that Vim predefines 
" ++++++++++++++++++++++++++++++++++++++++++++
function! s:gettype(type) 
  if exists('s:' . a:type)
    return 's:' . a:type
  elseif exists('g:' . a:type)
    return 'g:' . a:type
  elseif exists('w:' . a:type)
    return 'w:' . a:type
  elseif exists('t:' . a:type)
    return 't:' . a:type
  elseif exists('b:' . a:type)
    return 'b:' . a:type
  else
    return a:type
  endif
endfunction


" ++++++++++++++++++++++++++++++++++++++++++++
" Self Logging : {{{1
" ++++++++++++++++++++++++++++++++++++++++++++
if ! exists("g:self_log_file")
  let g:self_log_file = "SELF_LOG"
endif
if ! exists("g:self_do_log")
  let g:self_do_log = 0
endif

function! self#log(msg) 
  if g:self_do_log
    execute "redir >> " . g:self_log_file
    silent echo a:msg
    execute "redir END"
  endif
endfunction



" Prototype and Object Managers: {{{1

if ! exists("g:self_can_delete_prototypes")
  let g:self_can_delete_prototypes = 0
endif

" Prototype Manager: {{{1
" Clear Prototype Manager
if g:self#IN_DEVELOPMENT_MODE
  if exists("g:self_ProtoTypeManager")
    unlet g:self_ProtoTypeManager
  endif
endif

if !exists("g:self_ProtoTypeManager")
  let g:self_ProtoTypeManager = { '_id': 0, '_prototypeDB': {} }

  " All id's are negative
  function SELF_ProtoTypeManager_nextId() dict
    let g:self_ProtoTypeManager._id  = g:self_ProtoTypeManager._id - 1
    let l:id = g:self_ProtoTypeManager._id
    return l:id
  endfunction
  let g:self_ProtoTypeManager.nextId = function("SELF_ProtoTypeManager_nextId")

  function SELF_ProtoTypeManager_store(prototype) dict
    let l:id = self.nextId()
    let a:prototype._id = l:id
    let self._prototypeDB[l:id] = a:prototype
  endfunction
  let g:self_ProtoTypeManager.store = function("SELF_ProtoTypeManager_store")

  function SELF_ProtoTypeManager_hasId(id) dict
    return has_key(self._prototypeDB, a:id)
  endfunction
  let g:self_ProtoTypeManager.hasId = function("SELF_ProtoTypeManager_hasId")

  function SELF_ProtoTypeManager_lookup(id) dict
    if has_key(self._prototypeDB, a:id)
      return self._prototypeDB[a:id]
    else
      throw "Prototype does not exist with id: " . a:id
    endif
  endfunction
  let g:self_ProtoTypeManager.lookup = function("SELF_ProtoTypeManager_lookup")

  function SELF_ProtoTypeManager_remove(prototype) dict
    if has_key(a:prototype, '_id')
      call self.removeId(a:prototype._id)
      unlet a:prototype._id
    endif
  endfunction
  let g:self_ProtoTypeManager.remove = function("SELF_ProtoTypeManager_remove")

  function SELF_ProtoTypeManager_removeId(id) dict
    if has_key(self._prototypeDB, a:id)
      unlet self._prototypeDB[a:id]
    endif
  endfunction
  let g:self_ProtoTypeManager.removeId = function("SELF_ProtoTypeManager_removeId")

  function SELF_ProtoTypeManager_removeAll() dict
    for key in keys(self._prototypeDB)
      call self.removeId(key)
    endfor
  endfunction
  let g:self_ProtoTypeManager.removeAll = function("SELF_ProtoTypeManager_removeAll")
endif

function! self#IsPrototype(obj)
  if type(a:obj) == g:self#DICTIONARY_TYPE
    if has_key(a:obj, '_id')
      return g:self_ProtoTypeManager.hasId(a:obj._id)
    else
      return 0
    endif
  else
    return 0
  endif
endfunction

" Object Manager: {{{1
" Clear Object Manager
if g:self#IN_DEVELOPMENT_MODE
  if exists("g:self_ObjectManager")
    unlet g:self_ObjectManager
  endif
endif

if !exists("g:self_ObjectManager")
  let g:self_ObjectManager = { '_id': 0, '_objectDB': {} }

  " All id's are positive
  function SELF_ObjectManager_nextId() dict
    let g:self_ObjectManager._id  = g:self_ObjectManager._id + 1
    let l:id = g:self_ObjectManager._id
    return l:id
  endfunction
  let g:self_ObjectManager.nextId = function("SELF_ObjectManager_nextId")

  function SELF_ObjectManager_store(prototype) dict
    let a:prototype._id = self.nextId()
    let self._objectDB[a:prototype._id] = a:prototype
  endfunction
  let g:self_ObjectManager.store = function("SELF_ObjectManager_store")

  function SELF_ObjectManager_hasId(id) dict
    return has_key(self._objectDB, a:id)
  endfunction
  let g:self_ObjectManager.hasId = function("SELF_ObjectManager_hasId")

  function SELF_ObjectManager_lookup(id) dict
    if has_key(self._objectDB, a:id)
      return self._objectDB[a:id]
    else
      throw "Object does not exist with id: " . a:id
    endif
  endfunction
  let g:self_ObjectManager.lookup = function("SELF_ObjectManager_lookup")

  function SELF_ObjectManager_remove(prototype) dict
    if has_key(a:prototype, '_id')
      call self.removeId(a:prototype._id)
      unlet a:prototype._id
    endif
  endfunction
  let g:self_ObjectManager.remove = function("SELF_ObjectManager_remove")

  function SELF_ObjectManager_removeId(id) dict
    if has_key(self._objectDB, a:id)
      unlet self._objectDB[a:id]
    endif
  endfunction
  let g:self_ObjectManager.removeId = function("SELF_ObjectManager_removeId")

  function SELF_ObjectManager_removeAll() dict
    for key in keys(self._objectDB)
      call self.removeId(key)
    endfor
  endfunction
  let g:self_ObjectManager.removeAll = function("SELF_ObjectManager_removeAll")

endif

function! self#IsObject(obj)
  if type(a:obj) == g:self#DICTIONARY_TYPE
    if has_key(a:obj, '_id')
      return g:self_ObjectManager.hasId(a:obj._id)
    else
      return 0
    endif
  else
    return 0
  endif
endfunction


" ObjectPrototype Support: {{{1
function! self#InChainTypeClone(...) dict
  call self#log('self#InChainTypeClone calling _cloneType TOP')
  return exists('a:1') ?  g:self_ObjectPrototype._cloneType(self, a:1) 
                  \ : g:self_ObjectPrototype._cloneType(self)
endfunction

function! self#NotInChainTypeClone(...) dict
  call self#log('self#NotInChainTypeClone calling _cloneObject TOP')
  return exists('a:1') ? g:self_ObjectPrototype._cloneObject(a:1) 
                  \ : g:self_ObjectPrototype._cloneObject(self)
endfunction

function! self#TypeDelete(...) dict
call self#log('self#TypeDelete: TOP')
  if exists('a:1')
call self#log('self#TypeDelete: a:1')
    if self#IsObject(a:1) || self#IsPrototype(a:1)
call self#log('self#TypeDelete: Object or Type')
      if a:1._kind == 'self_ObjectPrototype'
call self#log('self#TypeDelete: self_ObjectPrototype')
        if self#IsObject(self)
call self#log('self#TypeDelete: Object')
          call g:self_ObjectPrototype._deleteObject(self)
        elseif self#IsPrototype(self)
call self#log('self#TypeDelete: Type')
          call g:self_ObjectPrototype._deleteType(self)
        else
          throw 'self#TypeDelete: self neither Object nor Type'
        endif
      else
call self#log('self#TypeDelete: not self_ObjectPrototype')
        call call(a:1._prototype.delete, [a:1._prototype], self)
      endif
    else
      throw 'self#TypeDelete: a:1 neither Object nor Type'
    endif
  else
call self#log('self#TypeDelete: no a:1')
    if self#IsObject(self) || self#IsPrototype(self)
call self#log('self#TypeDelete: Object or Type')
      if self._kind == 'self_ObjectPrototype'
call self#log('self#TypeDelete: self_ObjectPrototype')
        call g:self_ObjectPrototype._deleteType(self)
      else
call self#log('self#TypeDelete: not self_ObjectPrototype')
        call call(self._prototype.delete, [self._prototype], self)
      endif
    else
      throw 'self#TypeDelete: self neither Object nor Type'
    endif
  endif
endfunction

function! self#ObjectDelete(...) dict
call self#log('self#ObjectDelete: TOP')
  if exists('a:1')
call self#log('self#ObjectDelete: a:1')
    if self#IsObject(a:1)
call self#log('self#ObjectDelete: Object')
      call call(a:1._prototype.delete, [a:1._prototype], self)
    else
      throw 'self#ObjectDelete: a:1 neither Object nor Type'
    endif
  else
call self#log('self#ObjectDelete: no a:1')
    if self#IsObject(self)
call self#log('self#ObjectDelete: Object')
      call call(self._prototype.delete, [self._prototype], self)
    else
      throw 'self#ObjectDelete: self neither Object nor Type'
    endif
  endif
endfunction



" ObjectPrototype: {{{1
" ++++++++++++++++++++++++++++++++++++++++++++
" SELF.VIM self_ObjectPrototype
" ++++++++++++++++++++++++++++++++++++++++++++
if g:self#IN_DEVELOPMENT_MODE
  if exists("g:self_ObjectPrototype")
    unlet g:self_ObjectPrototype
  endif
endif
function! self#LoadObjectPrototype()
  if !exists("g:self_ObjectPrototype")
    "-----------------------------------------------
    " private variables
    "-----------------------------------------------
    let g:self_ObjectPrototype = { '_kind': 'self_ObjectPrototype' , '_prototype': '' }
    call g:self_ProtoTypeManager.store(g:self_ObjectPrototype)

    "-----------------------------------------------
    " public methods
    "-----------------------------------------------
    function! SELF_ObjectPrototype_init(attrs) dict
" call self#log("self_ObjectPrototype.init TOP")
      if type(a:attrs) != g:self#DICTIONARY_TYPE
        throw "g:self_ObjectPrototype.init attrs type not Dictionary"
      endif
      for name in keys(a:attrs)
        if exists("self.__" . name)
          unlet self['__' . name]
          let self['__' . name] = a:attrs[name]
        elseif name == 'tag'
          let self['__' . name] = a:attrs[name]
        endif
      endfor
" call self#log("self_ObjectPrototype.init BOTTOM")
      return self
    endfunction
    let g:self_ObjectPrototype.init = function("SELF_ObjectPrototype_init")

    function! SELF_ObjectPrototype_getKind() dict
      return self._kind
    endfunction
    let g:self_ObjectPrototype.getKind = function("SELF_ObjectPrototype_getKind")

    function! SELF_ObjectPrototype_isKindOf(kind) dict
      if self.getKind() == a:kind
        return 1
      else
        let parent = self._prototype
        while type(parent) == g:self#DICTIONARY_TYPE
          if parent.getKind() == a:kind
            return 1
          endif
          if type(parent._prototype) == g:self#DICTIONARY_TYPE
            let parent = parent._prototype
          else
            break
          endif
        endwhile
        return 0
      endif
    endfunction
    let g:self_ObjectPrototype.isKindOf = function("SELF_ObjectPrototype_isKindOf")

    function! SELF_ObjectPrototype_getPrototype() dict
      return self._prototype
    endfunction
    let g:self_ObjectPrototype.getPrototype = function("SELF_ObjectPrototype_getPrototype")

if 0
    function g:self_ObjectPrototype.instanceOf(prototype) dict
      let kind = a:prototype._kind
      let parent = self._prototype
      while type(parent) == g:self#DICTIONARY_TYPE
        if parent._kind == kind
          return 1
        endif
        if type(parent._prototype) == g:self#DICTIONARY_TYPE
          let parent = parent._prototype
        else
          break
        endif
      endwhile
      return 0
    endfunction
endif

    function! SELF_ObjectPrototype_equals(obj) dict
      if type(a:obj) == g:self#DICTIONARY_TYPE
        if has_key(a:obj, '_id') && has_key(self, '_id')
          return a:obj._id == self._id
        else
          return 0
        endif
      else
        return 0
      endif
    endfunction
    let g:self_ObjectPrototype.equals = function("SELF_ObjectPrototype_equals")

    function! SELF_ObjectPrototype_super() dict
      throw "self_ObjectPrototype has no super prototype"
    endfunction
    let g:self_ObjectPrototype.super = function("SELF_ObjectPrototype_super")

    "-----------------------------------------------
    " reserved methods
    "-----------------------------------------------

    function! SELF_ObjectPrototype_clone(...) dict
call self#log("clone TOP")
      if exists("a:1")
call self#log("clone a:1=".a:1)
        return g:self_ObjectPrototype._cloneType(self, a:1)
      else
        return g:self_ObjectPrototype._cloneObject(self)
      endif
    endfunction
    let g:self_ObjectPrototype.clone = function("SELF_ObjectPrototype_clone")

    " If a:1 exits, it is the object requesting deletion
    " If it does not exist, then its self_ObjectPrototype requesting deletion
    function! SELF_ObjectPrototype_delete(...) dict
call self#log("delete TOP")
      if self#IsObject(self)
        call g:self_ObjectPrototype._deleteObject(self)
      elseif self#IsPrototype(self)
        call g:self_ObjectPrototype._deleteType(self)
      else
        throw 'self_ObjectPrototype.delete: self neither Object nor Type'
      endif
    endfunction
    let g:self_ObjectPrototype.delete = function("SELF_ObjectPrototype_delete")


    "-----------------------------------------------
    " private methods
    "-----------------------------------------------

    function SELF_ObjectPrototype__cloneType(prototype, ...) dict
call self#log("_cloneType TOP")
call self#log("_cloneType prototype._id=" . a:prototype._id)
call self#log("_cloneType g:self_ProtoTypeManager=" . g:self_ProtoTypeManager.hasId(a:prototype._id))
      if exists("a:1")
        let l:kind = a:1
        let l:inchain = 1
      else
        let l:kind = a:prototype._kind
        let l:inchain = 0
      endif
call self#log("_cloneType l:kind=" . l:kind)
call self#log("_cloneType inchain=" . l:inchain)
      let l:o = {}
      for key in keys(a:prototype)
        if key == "_prototype"
          " setting the _prototype 
          let l:o[key] = a:prototype

        elseif key == "_kind"
          " setting the _kind 
          let l:o[key] = l:kind

        elseif key[0] == '_' && key[1] != '_'
          " Private methods are not copied

        elseif key == "super"
          if l:inchain
            let l:fd =        "function! l:o.super() dict\n"
            let l:fd = l:fd .   "return g:self_ProtoTypeManager.lookup(" . a:prototype._id . ")\n"
            let l:fd = l:fd . "endfunction"
            execute l:fd
          else
            let l:fd =        "function! l:o.super() dict\n"
            let l:fd = l:fd .   "let l:p = g:self_ProtoTypeManager.lookup(" . a:prototype._id . ")\n"
            let l:fd = l:fd .   "return g:self_ProtoTypeManager.lookup(l:p._prototype._id)\n"
            let l:fd = l:fd . "endfunction"
            execute l:fd
          endif

        elseif key == "clone"
          if l:inchain
            let l:o.clone = function("self#InChainTypeClone")

          else
            let l:o.clone = function("self#NotInChainTypeClone")

          endif


        elseif key == "delete"
call self#log("_cloneType making delete")
            let l:o.delete = function("self#TypeDelete")

        else
          if type(a:prototype[key]) == g:self#FUNCREF_TYPE
            " Do NOT call this Object's direct Prototype, rather call its
            " Prototype's Prototype.
            let kname = substitute(a:prototype._kind, '#', "_", "g")
            let fname = "MT_". kname . "_" . key

call self#log("_cloneType fname=".fname)
            " let l:fd = ""
            if ! exists("*".fname)
              let l:fd =        "function! " . fname . "(...) dict\n"
              let l:fd = l:fd .   "let l:obj = g:self_ProtoTypeManager.lookup(" . a:prototype._id . ")\n"
              let l:fd = l:fd .   "return call(l:obj." . key . ", a:000, self)\n"
              let l:fd = l:fd . "endfunction"
call self#log("_cloneType l:fd=".l:fd)
              execute l:fd
            endif
            let l:fd = "let l:o." . key . ' = function("'. fname . '")'
call self#log("_cloneType l:fd=".l:fd)
            execute l:fd

          elseif type(a:prototype[key]) == g:self#LIST_TYPE
            let l:o[key] = deepcopy(a:prototype[key])

          elseif type(a:prototype[key]) == g:self#DICTIONARY_TYPE
            let l:o[key] = deepcopy(a:prototype[key])

          else
            let l:o[key] = a:prototype[key]
          endif
        endif
      endfor

      if l:inchain
        call g:self_ProtoTypeManager.store(l:o)
      else
        call g:self_ObjectManager.store(l:o)
      endif

" call self#log("_cloneType " . l:o._kind . "  " . string(l:o))
call self#log("_cloneType BOTTOM kind=" . l:o._kind)
call self#log("_cloneType BOTTOM id=" . l:o._id)
call self#log("_cloneType BOTTOM parent._kind=" . l:o._prototype._kind)
call self#log("_cloneType BOTTOM parent._id=" . l:o._prototype._id)
call self#log("_cloneType BOTTOM super._kind=" . l:o.super()._kind)
call self#log("_cloneType BOTTOM super._id=" . l:o.super()._id)

      return l:o
    endfunction
    let g:self_ObjectPrototype._cloneType = function("SELF_ObjectPrototype__cloneType")



    function SELF_ObjectPrototype__cloneObject(prototype) dict
call self#log("_cloneObject TOP")
call self#log("_cloneObject prototype._id=" . a:prototype._id)
call self#log("_cloneObject ObjectManager=" . g:self_ObjectManager.hasId(a:prototype._id))

      let l:useid = 0
      let l:usetype = 1

      let l:pt1 = a:prototype._kind
      if type(a:prototype._prototype) == g:self#DICTIONARY_TYPE
        let l:pt2 = a:prototype._prototype._kind
        if l:pt1 != l:pt2
          let l:usetype = 1
        else
          if type(a:prototype._prototype._prototype) == g:self#DICTIONARY_TYPE
            let l:pt3 = a:prototype._prototype._prototype._kind
            if l:pt2 != l:pt3
              " use self._prototype
              let l:usetype = 0
            else
              let l:useid = 1
            endif
          else
            " use self._prototype
            let l:usetype = 0
          endif
        endif
      else
        let l:usetype = 1
      endif

      let l:o = {}

      for key in keys(a:prototype)
call self#log("_cloneObject key=".key)
        if key == "_prototype"
          " setting the _prototype 
          let l:o[key] = a:prototype

        elseif key == "_kind"
          " setting the _kind 
          let l:o[key] = a:prototype._kind

        elseif key[0] == '_' && key[1] != '_'
          " Private methods are not copied

        elseif key == "super"
          if l:useid
            let l:fd =        "function! l:o.super() dict\n"
            let l:fd = l:fd .   "return g:self_ObjectManager.lookup(" . a:prototype._id . ")\n"
            let l:fd = l:fd . "endfunction"
            execute l:fd

          elseif l:usetype
            let l:fd =        "function! l:o.super() dict\n"
            let l:fd = l:fd .   "return " . s:gettype(l:pt1) . "\n"
            let l:fd = l:fd . "endfunction"
            execute l:fd

          else
            let l:fd =        "function! l:o.super() dict\n"
            let l:fd = l:fd .   "return self._prototype" . "\n"
            let l:fd = l:fd . "endfunction"
            execute l:fd
          endif

        elseif key == "clone"
            let l:fd =        "function! l:o.clone(...) dict\n"
            let l:fd = l:fd .   "call self#log('clone calling clone(self)TOP')\n"
            let l:fd = l:fd .   "let l:o = g:self_ObjectManager.lookup(" . a:prototype._id . ")\n"
            let l:fd = l:fd .   "if exists('a:1')\n"
            let l:fd = l:fd .     "return l:o.clone(a:1)\n"
            let l:fd = l:fd .   "else\n"
            let l:fd = l:fd .     "return l:o.clone(self)\n"
            let l:fd = l:fd .   "endif\n"
            let l:fd = l:fd . "endfunction"
            execute l:fd



        elseif key == "delete"
call self#log("_cloneObject making delete")
            let l:o.delete = function("self#ObjectDelete")

        else
          if type(a:prototype[key]) == g:self#FUNCREF_TYPE
            " Pass self to the prototype's method
            let kname = substitute(a:prototype._kind, '#', "_", "g")
            let fname = "MO_". kname . "_" . key
call self#log("_cloneObject fname=".fname)
            " let l:fd = ""
            if ! exists("*".fname)
              let l:fd =        "function! " . fname . "(...) dict\n"
              let l:fd = l:fd .   "let l:o = g:self_ObjectManager.lookup(" . a:prototype._id . ")\n"
              let l:fd = l:fd .   "return call(l:o." . key . ", a:000, self)\n"
              let l:fd = l:fd . "endfunction"
call self#log("_cloneObject l:fd=".l:fd)
              execute l:fd
            endif
            let l:fd = "let l:o." . key . ' = function("'. fname . '")'
call self#log("_cloneObject l:fd=".l:fd)
            execute l:fd

          elseif type(a:prototype[key]) == g:self#LIST_TYPE
            let l:o[key] = deepcopy(a:prototype[key])

          elseif type(a:prototype[key]) == g:self#DICTIONARY_TYPE
            let l:o[key] = deepcopy(a:prototype[key])

          else
call self#log("_cloneObject value=".a:prototype[key])
            let l:o[key] = a:prototype[key]
          endif
        endif
      endfor

      call g:self_ObjectManager.store(l:o)

" call self#log("_cloneObject " . l:o._kind . "  " . string(l:o))
call self#log("_cloneObject BOTTOM " . l:o._kind)
call self#log("_cloneObject BOTTOM id=" . l:o._id)
call self#log("_cloneObject BOTTOM parent._kind=" . l:o._prototype._kind)
call self#log("_cloneObject BOTTOM parent._id=" . l:o._prototype._id)
call self#log("_cloneObject BOTTOM super._kind=" . l:o.super()._kind)
call self#log("_cloneObject BOTTOM super._id=" . l:o.super()._id)

      return l:o
    endfunction
    let g:self_ObjectPrototype._cloneObject = function("SELF_ObjectPrototype__cloneObject")



    function SELF_ObjectPrototype__deleteType(prototype) dict
      let l:i = stridx(a:prototype._kind, "Prototype")   
      if l:i == -1
        throw "Should only be called to delete Prototypes, not: " . a:prototype.getKind()
      endif
      if g:self_can_delete_prototypes
        call g:self_ProtoTypeManager.remove(a:prototype)
        for key in keys(a:prototype)
          unlet a:prototype[key]
        endfor
      else
        throw "Not allowed to delete Prototypes, to enable set g:self_can_delete_prototypes true"
      endif
    endfunction
    let g:self_ObjectPrototype._deleteType = function("SELF_ObjectPrototype__deleteType")

    function SELF_ObjectPrototype__deleteObject(prototype) dict
call self#log("_deleteObject TOP id=" . a:prototype._id)
      call g:self_ObjectManager.remove(a:prototype)
      for key in keys(a:prototype)
        unlet a:prototype[key]
      endfor
    endfunction
    let g:self_ObjectPrototype._deleteObject = function("SELF_ObjectPrototype__deleteObject")
  endif

  return g:self_ObjectPrototype

endfunction

" ==============
"  Restore: {{{1
" ==============
let &cpo= s:keepcpo
unlet s:keepcpo

" ================
"  Modelines: {{{1
" ================
" vim: ts=4 fdm=marker
