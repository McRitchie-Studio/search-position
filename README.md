# portfolio

Alex McRitchie's portfolio: portfolio.mcritchie.studio

One page listing the web apps Alex has built since 2014, each with its year, a
one-line description, a link to the original code on GitHub and, where one
exists, a link to its live build on `mcritchie.studio`. Several of the old apps
are back as **showcase rebuilds** made through the McRitchie Studio App
Builder; the page marks them as such.

A rebuild of the 2017–23 portfolio site,
[amcritchie/portfolio](https://github.com/amcritchie/portfolio) (Rails 5,
alexmcritchie.com). Nothing was ported: the old repo supplied the voice and
the project list, checked against each project's own GitHub repository.

It is a Rails 8.1 app with **no database**, no accounts and no studio-engine,
built from the [dads-app](https://github.com/McRitchie-Studio/dads-app) shape,
so it runs on one Heroku Eco dyno.

## How it works

| Piece | Where |
|-------|-------|
| The project list | `config/projects.yml`, newest first; the file documents its fields |
| Reading it | `app/models/project.rb`, a plain `Data` class loaded once and frozen; a malformed file raises at boot |
| The page | `app/views/projects/index.html.erb` at `/` |
| The look | `app/assets/stylesheets/application.css`, plain CSS with light and dark tokens |
| Health check | `/up` |

- **No JavaScript needed.** Every link works without it; `application.js`
  only swaps `no-js` for `js` on `<html>`.
- **No cookies.** The session store is disabled; the page has no forms.
- **Deep links.** Each project is an anchor: `/#cyvasse`. The targeted card
  is outlined.
- **Phones.** Below 34rem the timeline rail folds away and the year sits
  above each card.

To add a project, add a row to `config/projects.yml` in year order. A
`live` link must be `https` on `mcritchie.studio`; set `rebuild: true` when it
is a modern rebuild rather than the original. `ProjectTest` checks every row,
and fails on anything that looks like an email address or phone number.

## Develop

```bash
bundle install
bin/rails server -p 3810
bin/rails test               # unit + component + production https probe
bin/rails test:system        # the page in headless Chrome, desktop and a 375 px phone
bin/ci                       # everything CI runs
```

## Deploy

Heroku app `mcr-portfolio` (company account, stack heroku-26), `heroku/ruby`
buildpack, no add-ons, one Eco `web` dyno (`Procfile`, no release phase since
there is nothing to migrate). There is no `config/credentials.yml.enc`;
production reads `SECRET_KEY_BASE` from the environment. Production forces
HTTPS: the Heroku router reports the visitor's scheme in `X-Forwarded-Proto`,
so plain `http://` gets a 301, except `/up`, which answers on either scheme
(`ProductionSslTest` boots production to prove it).

Branches: feature PRs target `accepted`, which is promoted to `release` and
then `main`. CI runs on every pull request and on pushes to `accepted`,
`release` and `main`.
