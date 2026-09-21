# Name
D__\_\_____
 
nULl______

__LIBrary

A very "creative" name I know

# What
A D library of various utilities ranging from common datatypes seen in
functional languages (Option and Result as in Rust, Maybe  and Either
as seen in Idris and presumably Haskell), to non-throwing versions of
capabilities already possessed by Phobos.

Not to mention various utilities and types I want, or that better fit 
the way I think.

- Well actually not Maybe, not distinct enough from Option, where as
  Result and Either can have different connotations/meanings


# Caveats
1. This no doubt needs a more exhaustive test suite
2. This library is largely intended for personal use so organization is
   dependent on my whims/preference, and willingness to refactor
3. Continuing from point 2, I have no plans to even attempt packaging
   this for dub
4. I barely use Windows 10, and don't have a computer with Windows 11.
   Windows support will be sparse/poor to non-existant
   

- Point 4 primarily affects anything to do with IO and the filesystem

# AI
Between the almost certain lack of D training data, D's (relatively) 
odd generic syntax (!(T) instead of \<T\>), and a lack of overall 
guiding functionality I suspect I would spend more time wrestling with 
any AI on both syntax and trying to explain direction then if I just 
wrote the code myself
