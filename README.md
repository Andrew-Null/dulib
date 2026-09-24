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
  (at least for the moment)
- Regarding point 2 and 4 maybe some day I will make a distinction 
  between platform independent and platform dependent in dulib's 
  organization

