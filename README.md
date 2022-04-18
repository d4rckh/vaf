<div align="center">
<h1>vaf</h1>
<h3>A fast, simple, and feature rich web fuzzer writen in nim</h3>
<img src="https://img.shields.io/github/stars/d4rckh/vaf"></img>
<a href="https://github.com/d4rckh/vaf/issues">
  <img src="https://img.shields.io/github/issues/d4rckh/vaf"></img>
</a>
<a href="https://github.com/d4rckh/vaf/network">
  <img src="https://img.shields.io/github/forks/d4rckh/vaf"></img>
</a>
<a href="https://github.com/d4rckh/vaf/blob/main/LICENSE">
  <img src="https://img.shields.io/github/license/d4rckh/vaf"></img>
</a>
<img src="https://img.shields.io/github/languages/top/d4rckh/vaf"></img>
<br><br>
<img src="screenshots/main.png"></img>
<br><br>
</div>

vaf is a cross-platform web fuzzer with a lot of features. Some of its features include:
- Fast threading
- HTTP header fuzzing
- Proxying
- [your own feature!](https://github.com/d4rckh/vaf/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=%5Bfeature%5D)
- And more...


## Installing

You can install vaf using this one-liner:
```
curl https://raw.githubusercontent.com/d4rckh/vaf/main/install.sh | sudo bash
```

## Options

```
Options:
  -h, --help
  -u, --url=URL              Target URL. Replace fuzz area with FUZZ
  -w, --wordlist=WORDLIST    The path to the wordlist.
  -m, --method=METHOD        Request method. Supported: POST, GET (default: GET)
  -H, --header=HEADER        Specify HTTP headers; can be used multiple times. Example: -H 'header1: val1' -H 'header1: val1'
  -pf, --prefix=PREFIX       The prefixes to append to the word (default: )
  -sf, --suffix=SUFFIX       The suffixes to append to the word (default: )
  -t, --threads=THREADS      Number of threads (default: 5)
  -sc, --status=STATUS       The status to filter; to 'any' to print on any status (default: 200)
  -g, --grep=GREP            Only log if the response body contains the string (default: )
  -ng, --notgrep=NOTGREP     Only log if the response body does no contain a string (default: )
  -pd, --postdata=POSTDATA   Specify POST data; used only if '-m post' is set (default: {})
  -x, --proxy=PROXY          Specify a proxy (default: )
  -ca, --cafile=CAFILE       Specify a CA root certificate; useful if you are using Burp/ZAP proxy (default: )
  -o, --output=OUTPUT        Output the results in a file (default: )
  -mr, --maxredirects=MAXREDIRECTS
                             How many redirects should vaf follow; 0 means none (default: 0)
  -v, --version              Print version information
  -pif, --printifreflexive   Print only if the fuzzed word is reflected in the page
  -i, --ignoressl            Do not verify SSL certificates; useful if you are using Burp/ZAP proxy
  -ue, --urlencode           URL encode the fuzzed words
  -pu, --printurl            Print the requested URL
  -ph, --printheaders        Print response headers
  -dbg, --debug              Prints debug information
```

## Examples

### Fuzz URL path, show only responses which returned 200 OK
```
vaf -u https://example.org/FUZZ -w path/to/wordlist.txt -sc OK
```

### Fuzz 'User-Agent' header, show only responses which returned 200 OK
```
vaf -u https://example.org/ -w path/to/wordlist.txt -sc OK -H "User-Agent: FUZZ"
```

### Fuzz POST data, show only responses which returned 200 OK
```
vaf -u https://example.org/ -w path/to/wordlist.txt -sc OK -m POST -H "Content-Type: application/json" -pd '{"username": "FUZZ"}'
```

# Contributors 

Thanks to everyone who contributed to this project!
- [@daanbreur](https://github.com/daanbreur)
