# search-position

Where does your site rank for a search phrase? search-position.mcritchie.studio

Type a search phrase and your site's address. The page shows the site's
position in the top 64 results, or "not in the first 64 results", then the
whole list, in pages of ten, with the site highlighted.

**The results are demo data.** Nothing is fetched from Google or any other
search engine, and no search API is called. Each phrase gets a believable,
generated results list, and the site's position in it is simulated. Every
page says so.

A rebuild of a 2015 weekend app,
[amcritchie/google-search-position](https://github.com/amcritchie/google-search-position)
(Rails 4). It kept the same two-field form, the position readout and the
highlighted list. The original asked Google's AJAX Search API through the
`google-search` gem; that API has been retired, so the rebuild generates its
results instead of scraping a live engine.

It is a Rails 8.1 app with **no database**, no accounts and no studio-engine,
built from the same shape as the other McRitchie Studio showcase apps, so it
runs on one Heroku Eco dyno.

## How it works

| Piece | Where |
|-------|-------|
| The page | `app/views/checks/show.html.erb` at `/`; the form submits with GET, so a check is a shareable link: `/?search=hiking+boots&url=reddit.com` |
| Reading the site address | `app/models/site_address.rb` |
| Reading the phrase | `app/models/search_phrase.rb` |
| The demo results | `app/models/demo_search.rb`, from the page kinds in `config/demo_web.yml` (the file documents its fields) |
| The position | `app/models/position_check.rb` |
| The look | `app/assets/stylesheets/application.css`, plain CSS with light and dark tokens |
| Health check | `/up` |

- **Deterministic.** Every random choice is seeded from a hash of the phrase
  (and, for placing the site, the phrase and the site), so a check gives the
  same answer on every visit.
- **Where the site lands.** If a generated result already belongs to the site
  (ask about `wikipedia.org`), that is its position, and every result that
  belongs to it is highlighted. Otherwise one page of the site is placed at a
  seeded spot, skewed toward the top, and one time in five it is left out, so
  "not in the first 64 results" happens too.
- **Matching an address.** Scheme, `www.`, letter case in the host, port,
  trailing slash, query and fragment never matter. A bare domain covers its
  subdomains (`wikipedia.org` covers `en.wikipedia.org`, not the reverse). A
  path covers that page and the pages below it on whole segments (`/blog`
  covers `/blog/post`, not `/blogger`). The 2015 original checked whether the
  result's address merely contained the site, so `go.com` matched `lego.com`.
- **No links out.** The generated addresses are made up, so results are text.
- **No cookies.** The session store is disabled. What you type is echoed back
  escaped, never as HTML.
- **No JavaScript needed.** `application.js` only swaps `no-js` for `js`.

## Develop

```bash
bundle install
bin/rails server -p 4300
bin/rails test               # unit + component + production https probe
bin/rails test:system        # the page in headless Chrome, desktop and a 375 px phone
bin/ci                       # everything CI runs
```

## Deploy

Heroku app `mcr-search-position` (company account), `heroku/ruby` buildpack, no
add-ons, one Eco `web` dyno (`Procfile`, no release phase since there is
nothing to migrate). There is no `config/credentials.yml.enc`; production
reads `SECRET_KEY_BASE` from the environment. Production forces HTTPS: the
Heroku router reports the visitor's scheme in `X-Forwarded-Proto`, so plain
`http://` gets a 301, except `/up`, which answers on either scheme
(`ProductionSslTest` boots production to prove it).

Branches: feature PRs target `accepted`, which is promoted to `release` and
then `main`. CI runs on every pull request and on pushes to `accepted`,
`release` and `main`.
