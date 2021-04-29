# vaf
very advanced fuzzer

## compiling

1. Install nim from nim-lang.org
2. Run
```bash
nimble build
```
A vaf.exe file will be created in your directory ready to be used
## using vaf

using vaf is simple, here's the current help text:
```
Usage:
  vaf - very advanced fuzzer [options]

Options:
  -h, --help
  -u, --url=URL              choose url, replace area to fuzz with []
  -w, --wordlist=WORDLIST    choose the wordlist to use
  -sc, --status=STATUS       set on which status to print, set this param to 'any' to print on any status (default: 200)
  -pr, --prefix=PREFIX       prefix, e.g. set this to / for content discovery if your url doesnt have a / at the end (default: )
  -sf, --suffix=SUFFIX       suffix, e.g. use this for extensions if you are doing content discovery (default: )
  -pd, --postdata=POSTDATA   only used if '-m post' is set (default: {})
  -m, --method=METHOD        suffix, e.g. use this for extensions if you are doing content discovery (default: get)
  -pif, --printifreflexive   print only if the output reflected in the page, useful for finding xss
  -ue, --urlencode           url encode the payloads
  -pu, --printurl            prints the url that has been requested
```

## screenshots

![main without pu](screenshots/main%20without%20pu.png)
(with every status code printed, suffixes .php,.html and no prefixes)

![main](screenshots/main.png)
(with url printed, every status code printed, suffixes .php,.html and no prefixes)

![main](screenshots/main%20post.png)
(post data fuzzing)

## examples

Fuzz post data:

```
vaf.exe -w example_wordlists\short.txt -u https://jsonplaceholder.typicode.com/posts -m post -sc 201 -pd "{\"title\": \"[]\"}"
```

Fuzz GET URLs

```
vaf.exe -w example_wordlists\short.txt -u https://example.org/[] -sf .html
```

## tips

- Add a trailing `,` in the suffixes or prefixes argument to try the word without any suffix/prefix like this: `-pf .php,` or `-sf .php,`
- Use `-pif` with a bunch of xss payloads as the wordlist to find XSS
- Make an issue if you want to suggest a feature
