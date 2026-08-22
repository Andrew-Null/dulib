#!/run/current-system/sw/bin/nu

def gather [path: string, ext: string] {
  return (~/Other/Programming/Nu/gather.nu $path $ext | from nuon)
}

const arg0 = path self;
const selfdir = $arg0 | path dirname;
def main [opt: string] {
  let outpath = $"($selfdir)/bin/($opt).out"
  match $opt {
    "test" => {
      dmd -main -unittest ...(gather $"($selfdir)/src" d) -of=$outpath
      ./$outpath
    }
  }
}
