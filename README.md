
# vaf - very advanced (web) fuzzer
![GitHub Repo stars](https://img.shields.io/github/stars/d4rckh/vaf)
[![GitHub issues](https://img.shields.io/github/issues/d4rckh/vaf)](https://github.com/d4rckh/vaf/issues)
[![GitHub forks](https://img.shields.io/github/forks/d4rckh/vaf)](https://github.com/d4rckh/vaf/network)
[![GitHub license](https://img.shields.io/github/license/d4rckh/vaf)](https://github.com/d4rckh/vaf/blob/main/LICENSE)
![GitHub top language](https://img.shields.io/github/languages/top/d4rckh/vaf)

![main](screenshots/main.png)

vaf is a cross-platform web fuzzer with a lot of features. Some of its features include:
- Grepping
- Outputing results to a file
- Status code filtering
- Detect reflexivness (useful for finding xss)
- Add prefixes, suffixes
- Custom wordlists
- Fuzz any part of the url
- Fuzz POST data
- URL encode payload
- [Threading (wip)](https://github.com/d4rckh/vaf/pull/14)
- [your own feature!](https://github.com/d4rckh/vaf/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=%5Bfeature%5D)
- And more...


## Installing

You can install vaf:
- by downloading the **pre-compiled binaries in the [releases page](https://github.com/d4rckh/vaf/releases/)** and adding them manually to your path
- by running the `install.sh` **bash script** which will __download nim, build vaf from source and then link the binary to /usr/bin__  (make sure to `chmod +x install.sh`)

## Usage

Using vaf is very simple, here's the current help menu:
```
Usage:
  vaf [options]

Options:
  -h, --help
  -u, --url=URL              choose url, replace area to fuzz with []
  -w, --wordlist=WORDLIST    choose the wordlist to use
  -sc, --status=STATUS       set on which status to print, set this param to 'any' to print on any status (default: 200)
  -pr, --prefix=PREFIX       prefix, e.g. set this to / for content discovery if your url doesnt have a / at the end (default: )
  -sf, --suffix=SUFFIX       suffix, e.g. use this for extensions if you are doing content discovery (default: )
  -pd, --postdata=POSTDATA   only used if '-m post' is set (default: {})
  -m, --method=METHOD        the method to use PSOT/GET (default: GET)
  -g, --grep=GREP            greps for a string in the response (default: )
  -o, --output=OUTPUT        Output the results in a file (default: )
  -pif, --printifreflexive   print only if the output reflected in the page, useful for finding xss
  -ue, --urlencode           url encode the payloads
  -pu, --printurl            prints the url that has been requested
```

## Examples

Fuzz GET URLs
```
vaf.exe -w example_wordlists\short.txt -u https://example.org/[] -sf .html
```

Fuzz post data:
```
vaf.exe -w example_wordlists\short.txt -u https://jsonplaceholder.typicode.com/posts -m post -sc 201 -pd "{\"title\": \"[]\"}"
```

## Some tips

- Add a cmoma (`,`) at the end in the suffixes or prefixes argument to try the word without any suffix/prefix like this: `-pf .php,` or `-sf .php`
- Use `-pif` with a bunch of xss payloads as the wordlist to find XSS
- Make an issue if you want to suggest a feature

# Contributors 

Thanks to everyone who contributed to this project!
- [@daanbreur](https://github.com/daanbreur)
