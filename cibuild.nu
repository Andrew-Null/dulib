#!/usr/bin/nu

def gather [path: string, ext: string] {
  let absp = $path | path expand
  let toglob = $"($absp)/**/*.($ext)"
  return (glob $toglob)
}

const arg0 = path self;
const selfdir = $arg0 | path dirname;
def main [opt: string] {
  let outpath = $"($selfdir)/bin/($opt).out"
  match $opt {
    "test" => {
      dmd -main -color -unittest ...(gather $"($selfdir)/src" d) -of=($outpath)
      ^($outpath)
    }
  }
}
