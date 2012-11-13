"-------------------------------------------------------------------------------
" Rational Number Prototype: {{{1
"-------------------------------------------------------------------------------

" ------------------------------------------------------------ 
" self#rational2#reload: {{{2
"  Cals self#reload to force reloading of rational code:
"    call self#reload('self#rational2#')
"  This function is only available in development mode, i.e.,
"    g:self#IN_DEVELOPMENT_MODE == 1
"  To make reloading of autoloaded forms functions simple, one might
"    want to define a mapping:
"      map <Leader>srr :call self#rational2#reload()
"  parameters: None
" ------------------------------------------------------------ 
if !exists("*self#rational2#reload")
  if g:self#IN_DEVELOPMENT_MODE
    function self#rational2#reload() 
      call self#reload('self#rational2#')
    endfunction
  endif
endif

"---------------------------------------------------------------------------
" Rational <- Object: {{{2
"---------------------------------------------------------------------------
" Rational Number object 
"   source see: 
"     http://introcs.cs.princeton.edu/java/92symbolic/Rational.java.html
"
" attributes
"   num   : numerator
"   den   : denominator
"---------------------------------------------------------------------------

let g:self#rational2#Rational = self#LoadObjectPrototype().clone('self#rational2#Rational')
let g:self#rational2#Rational.__num = 0
let g:self#rational2#Rational.__den = 1

" ------------------------------------------------------------ 
" g:self#rational2#Rational.init: {{{3
"   Initialize object
"  parameters: 
"   attrs  : 
"       num   : numerator
"       den   : denominator
" ------------------------------------------------------------ 
function! SELF_RATIONAL_init(attrs) dict
  call call(g:self_ObjectPrototype.init, [a:attrs], self)

  if type(self.__num) != g:self#NUMBER_TYPE
    throw "Rational: Numerator not Number type " . type(self.__num)
  endif
  if type(self.__den) != g:self#NUMBER_TYPE
    throw "Rational: Denominator not Number type " . type(self.__den)
  endif

  " reduce fraction
  let g = SELF_RATIONAL_gcd(self.__num, self.__den)
  let self.__num = self.__num / g
  let self.__den = self.__den / g

  " only needed for negative numbers
  if self.__den < 0 
    let self.__den = -self.__den 
    let self.__num = -self.__num
  endif

  return self
endfunction
let g:self#rational2#Rational.init = function("SELF_RATIONAL_init")


" ------------------------------------------------------------ 
" g:self#rational2#Rational.numerator: {{{3
"   return the numerator
"  parameters: None
" ------------------------------------------------------------ 
function! SELF_RATIONAL_numerator() dict
  return self.__num
endfunction
let g:self#rational2#Rational.numerator = function("SELF_RATIONAL_numerator")

" ------------------------------------------------------------ 
" g:self#rational2#Rational.denominator: {{{3
"   return the denominator
"  parameters: None
" ------------------------------------------------------------ 
function! SELF_RATIONAL_denominator() dict
  return self.__den
endfunction
let g:self#rational2#Rational.denominator = function("SELF_RATIONAL_denominator")

" ------------------------------------------------------------ 
" g:self#rational2#Rational.toFloat: {{{3
"   return numerator / denominator
"  parameters: None
" ------------------------------------------------------------ 
function! SELF_RATIONAL_toFloat() dict
  return (self.__num + 0.0) / self.__den
endfunction
let g:self#rational2#Rational.toFloat = function("SELF_RATIONAL_toFloat")

" ------------------------------------------------------------ 
" g:self#rational2#Rational.toString: {{{3
"   return numerator . "/" . denominator
"  parameters: None
" ------------------------------------------------------------ 
function! SELF_RATIONAL_toString() dict
  return (self.__den == 1)
        \ ? "" . self.__num
        \ : "" . self.__num . "/" . self.__den
endfunction
let g:self#rational2#Rational.toString = function("SELF_RATIONAL_toString")

" ------------------------------------------------------------ 
" g:self#rational2#Rational.doCompare: {{{3
"   return { -1, 0, +1 } if a < b, a = b, or a > b
"  parameters:
"   rational : other rational
" ------------------------------------------------------------ 
function! SELF_RATIONAL_doCompare(rational) dict
  let lhs = self.__num * a:rational.__den
  let rhs = self.__den * a:rational.__num
  return (lhs < rhs) ? -1 : (lhs > rhs) ? 1 : 0
endfunction
let g:self#rational2#Rational.doCompare = function("SELF_RATIONAL_doCompare")

" ------------------------------------------------------------ 
" g:self#rational2#Rational.equals: {{{3
"   return true if the same rational number and false otherwise
"   Override ObjectPrototype equals
"  parameters:
"   obj : other object
" ------------------------------------------------------------ 
function! SELF_RATIONAL_equals(obj) dict
  if type(a:obj) != g:self#DICTIONARY_TYPE
    return 0
  elseif ! has_key(a:obj, '_kind')
    return 0
  elseif a:obj.__kind != 'self#rational2#Rational'
    return 0
  else
    return self.doCompare(a:obj)
  endif
endfunction
let g:self#rational2#Rational.equals = function("SELF_RATIONAL_equals")

" ------------------------------------------------------------ 
" g:self#rational2#Rational.median: {{{3
"   return new rational whith
"       (self.__num + r.__num) / (self.__den + r.__den)
"  parameters:
"   rational : other rational
" ------------------------------------------------------------ 
function! SELF_RATIONAL_mediant(rational) dict
  let attrs = {'num': (self.__num+a:rational.__num), 
             \ 'den': (self.__den+a:rational.__den)}
  return self#rational2#new(attrs)
endfunction
let g:self#rational2#Rational.mediant = function("SELF_RATIONAL_mediant")

" ------------------------------------------------------------ 
" g:self#rational2#Rational.gcd: {{{3
"   return greatest common denominator
"  parameters:
"   m : Number
"   n : Number
" ------------------------------------------------------------ 
function! SELF_RATIONAL_gcd(m, n)
  let n = (a:n < 0) ? -a:n : a:n
  let m = (a:m < 0) ? -a:m : a:m
  return (n == 0) ? m : SELF_RATIONAL_gcd(n, m % n)
endfunction

" ------------------------------------------------------------ 
" g:self#rational2#Rational.lcm: {{{3
"   return least common multiple
"  parameters:
"   m : Number
"   n : Number
" ------------------------------------------------------------ 
function! SELF_RATIONAL_lcm(m, n)
  let n = (a:n < 0) ? -a:n : a:n
  let m = (a:m < 0) ? -a:m : a:m
  return m * ( n / SELF_RATIONAL_gcd(m, n))
endfunction

" ------------------------------------------------------------ 
" g:self#rational2#Rational.times: {{{3
"   return product
"  parameters:
"   rational : other rational
" ------------------------------------------------------------ 
function! SELF_RATIONAL_times(rational) dict
  let r_num = a:rational.__num
  let r_den = a:rational.__den
  let s_num = self.__num
  let s_den = self.__den

  let g = SELF_RATIONAL_gcd(s_num, r_den)
  let c_num = s_num / g
  let c_den = r_den / g

  let g = SELF_RATIONAL_gcd(r_num, s_den)
  let d_num = r_num / g
  let d_den = s_den / g

  let attrs = {'num': (c_num*d_num), 
             \ 'den': (c_den*d_den)}
  return self#rational2#new(attrs)
endfunction
let g:self#rational2#Rational.times = function("SELF_RATIONAL_times")

" ------------------------------------------------------------ 
" g:self#rational2#Rational.plus: {{{3
"   return sum
"  parameters:
"   rational : other rational
" ------------------------------------------------------------ 
function! SELF_RATIONAL_plus(rational) dict
  let r_num = a:rational.__num
  let r_den = a:rational.__den
  let s_num = self.__num
  let s_den = self.__den

  " special cases
  if s_num == 0 | return a:rational | endif
  if r_num == 0 | return self | endif

  " Find gcd of numerators and denominators
  let f = SELF_RATIONAL_gcd(s_num, r_num)
  let g = SELF_RATIONAL_gcd(s_den, r_den)

  " add cross-product terms for numerator
  let attrs = {'num': (((s_num/f)*(r_den/g)) + ((r_num/f)*(s_den/g))), 
             \ 'den': SELF_RATIONAL_lcm(s_den, r_den)}
  let x = self#rational2#new(attrs)

  " multiply back in
  let x.__num = x.__num * f
  return x

endfunction
let g:self#rational2#Rational.plus = function("SELF_RATIONAL_plus")

" ------------------------------------------------------------ 
" g:self#rational2#Rational.negate: {{{3
"   return negative
"  parameters: None
" ------------------------------------------------------------ 
function! SELF_RATIONAL_negate() dict
  let attrs = {'num': -self.__num, 'den': self.__den}
  return self#rational2#new(attrs)
endfunction
let g:self#rational2#Rational.negate = function("SELF_RATIONAL_negate")

" ------------------------------------------------------------ 
" g:self#rational2#Rational.minus: {{{3
"   return self - rational
"  parameters: 
"   rational : other rational
" ------------------------------------------------------------ 
function! SELF_RATIONAL_minus(rational) dict
  return self.plus(a:rational.negate())
endfunction
let g:self#rational2#Rational.minus = function("SELF_RATIONAL_minus")

" ------------------------------------------------------------ 
" g:self#rational2#Rational.reciprocal: {{{3
"   return self - rational
"  parameters: 
"   rational : other rational
" ------------------------------------------------------------ 
function! SELF_RATIONAL_reciprocal(rational) dict
  let attrs = {'num': -self.__den, 'den': self.__num}
  return self#rational2#new(attrs)
endfunction
let g:self#rational2#Rational.reciprocal = function("SELF_RATIONAL_reciprocal")

" ------------------------------------------------------------ 
" g:self#rational2#Rational.divide: {{{3
"   return self / rational
"  parameters: 
"   rational : other rational
" ------------------------------------------------------------ 
function! SELF_RATIONAL_divide(rational) dict
  return self.times(a:rational.reciprocal())
endfunction
let g:self#rational2#Rational.divide = function("SELF_RATIONAL_divide")

" ------------------------------------------------------------ 
" self#rational2#new: {{{2
"   Create new Rational Number
"  parameters: 
"   attrs  : attributes for initializing new object
" ------------------------------------------------------------ 
function! self#rational2#new(attrs)
  return g:self#rational2#Rational.clone().init(a:attrs)
endfunction

function! self#rational2#Test()
  " test one
  let x = self#rational2#new({'num': 1, 'den': 2})
  let y = self#rational2#new({'num': 1, 'den': 3})
  let z = x.plus(y)
  let r = "expect: 5/6, actual: " . z.toString()
  call input("test one continue: " .r)

  " test two
  let x = self#rational2#new({'num': 8, 'den': 9})
  let y = self#rational2#new({'num': 1, 'den': 9})
  let z = x.plus(y)
  let r = "expect: 1, actual: " . z.toString()
  call input("test two continue: " .r)

  " test three
  let x = self#rational2#new({'num': 1, 'den': 200000000})
  let y = self#rational2#new({'num': 1, 'den': 300000000})
  let z = x.plus(y)
  let r = "expect: 1/120000000, actual: " . z.toString()
  call input("test three continue: " .r)

  " test four
  let x = self#rational2#new({'num': 1073741789, 'den': 20})
  let y = self#rational2#new({'num': 1073741789, 'den': 30})
  let z = x.plus(y)
  let r = "expect: 1073741789/12, actual: " . z.toString()
  call input("test four continue: " .r)

  " test five
  let x = self#rational2#new({'num': 4, 'den': 17})
  let y = self#rational2#new({'num': 17, 'den': 4})
  let z = x.times(y)
  let r = "expect: 1, actual: " . z.toString()
  call input("test five continue: " .r)

  " test six
  let x = self#rational2#new({'num': 3037141, 'den': 3247033})
  let y = self#rational2#new({'num': 3037547, 'den': 3246599})
  let z = x.times(y)
  let r = "expect: 841/961, actual: " . z.toString()
  call input("test six continue: " .r)

  " test seven
  let x = self#rational2#new({'num': 1, 'den': 6})
  let y = self#rational2#new({'num': -4, 'den': -8})
  let z = x.minus(y)
  let r = "expect: -1/3, actual: " . z.toString()
  call input("test seven continue: " .r)

endfunction

" ================
"  Modelines: {{{1
" ================
" vim: ts=4 fdm=marker
