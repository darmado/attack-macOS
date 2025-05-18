# search

Search with Google, Wiki, Bing, YouTube and other popular services.


```zsh
plugins=( ... search.sh)
```

## Usage

You can use the `search.sh` plugin in these two forms:

- `search.sh <context> <term> [more terms if you want]`
- `<context> <term> [more terms if you want]`

For example, these two are equivalent:

```zsh
$ search.sh google oh-my-zsh
$ google oh-my-zsh
```

Available search contexts are:

| arg               | URL                                             |
| --------------------- | ----------------------------------------------- |
| `bing`                | `https://www.bing.com/search?q=`                |
| `google`              | `https://www.google.com/search?q=`              |
| `brs` or `brave`      | `https://search.brave.com/search?q=`            |
| `yahoo`               | `https://search.yahoo.com/search?p=`            |
| `ddg` or `duckduckgo` | `https://www.duckduckgo.com/?q=`                |
| `sp` or `startpage`   | `https://www.startpage.com/do/search?q=`        |
| `yandex`              | `https://yandex.ru/yandsearch?text=`            |
| `github`              | `https://github.com/search?q=`                  |
| `baidu`               | `https://www.baidu.com/s?wd=`                   |
| `ecosia`              | `https://www.ecosia.org/search?q=`              |
| `goodreads`           | `https://www.goodreads.com/search?q=`           |
| `qwant`               | `https://www.qwant.com/?q=`                     |
| `givero`              | `https://www.givero.com/search?q=`              |
| `stackoverflow`       | `https://stackoverflow.com/search?q=`           |
| `wolframalpha`        | `https://wolframalpha.com/input?i=`             |
| `archive`             | `https://web.archive.org/web/*/`                |
| `scholar`             | `https://scholar.google.com/scholar?q=`         |
| `ask`                 | `https://www.ask.com/web?q=`                    |
| `youtube`             | `https://www.youtube.com/results?search_query=` |
| `deepl`               | `https://www.deepl.com/translator#auto/auto/`   |
| `dockerhub`           | `https://hub.docker.com/search?q=`              |
| `npmpkg`              | `https://www.npmjs.com/search?q=`               |
| `packagist`           | `https://packagist.org/?query=`                 |
| `gopkg`               | `https://pkg.go.dev/search?m=package&q=`        |
| `chatgpt`             | `https://chatgpt.com/?q=`                       |
| `reddit`              | `https://www.reddit.com/search/?q=`             |



### Custom search engines

TBD

