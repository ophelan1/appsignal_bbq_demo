# Smokestack BBQ Supply — an AppSignal demo store

A working Rails e-commerce store, built to be **monitored in front of an audience**.

It sells barbecue equipment, has a real catalogue, cart and checkout — and a `/demo`
section full of endpoints that misbehave on purpose, so an AppSignal dashboard has
something worth pointing at.

---

## Why the demo endpoints exist

A healthy demo app produces a flat line in APM. That is a terrible thing to put in front
of a prospect: nothing is slow, nothing errors, and there is no story to tell.

So `/demo` deliberately breaks things, one recognisable shape at a time:

| Endpoint | What it does | What to point at in AppSignal |
| --- | --- | --- |
| `/demo/slow_query` | Correlated subquery per row over a cross join, then a 350ms sleep | Performance — one SQL event dominating the timeline |
| `/demo/n_plus_one` | Renders every product with no eager loading | Dozens of near-identical queries stacked up |
| `/demo/optimised` | The same page done properly | Three queries instead of forty — the side-by-side |
| `/demo/error` | Raises a real exception, returns 500 | Errors — new error group, backtrace, tags, params |
| `/demo/handled_error` | Catches it, reports it, returns 200 | An error on a *successful* request |
| `/demo/background_job` | Queues jobs; every third one fails and retries | The Background namespace, failing and succeeding jobs |
| `/demo/external_http` | Real HTTPS call to an external API | The HTTP call as its own event in the trace |
| `/demo/memory_hog` | Allocates 120,000 strings and throws them away | Allocation and memory graphs |
| `/demo/custom_metric` | Counter, two gauges, one distribution | Custom Metrics — build a dashboard from these |

Checkout also enqueues a real `OrderConfirmationJob`, so ordinary use of the store
produces background job traces too.

---

## Running it

### GitHub Codespaces (nothing installed locally)

Press **.** on the repo page, or **Code → Codespaces → Create codespace on main**.

The devcontainer runs `bin/setup` for you — gems, database, seed data — and forwards
port 3000. When it finishes:

```sh
export APPSIGNAL_PUSH_API_KEY="your-key"
bin/rails server
```

Codespaces pops up the forwarded URL. That is your demo.

### Locally

Requires Ruby 3.2 or newer. Nothing else — the database is SQLite.

```sh
bin/setup                              # gems, database, seed data
export APPSIGNAL_PUSH_API_KEY="your-key"
bin/rails server                       # http://localhost:3000
```

Without a push API key the app runs perfectly well; AppSignal simply stays inactive and
says so on `/demo`.

---

## Before a demo: fill the dashboard

Clicking buttons one at a time gives you a handful of data points, which looks like what
it is. To make the graphs look like a real application, start the server and then, in a
second terminal:

```sh
bin/rails demo:traffic              # ~2 minutes of mixed traffic
bin/rails demo:traffic MINUTES=10   # a fuller picture
bin/rails demo:burst                # one of every scenario, fast
bin/rails demo:status               # what the app currently holds
```

`demo:traffic` drives real HTTP at the running server — 70% ordinary shopping, 30% demo
endpoints, with background jobs queued along the way. Run it for ten minutes before a
call and the dashboard looks lived-in.

Give AppSignal about a minute after the traffic stops, then open Performance, Errors and
Background.

---

## Configuration

Everything is environment variables. Nothing sensitive is committed.

| Variable | Default | Purpose |
| --- | --- | --- |
| `APPSIGNAL_PUSH_API_KEY` | *(none)* | Your key. Without it, AppSignal is inactive. |
| `APPSIGNAL_APP_NAME` | `Smokestack BBQ Supply` | Name shown in AppSignal |
| `APPSIGNAL_APP_ENV` | current Rails env | Environment shown in AppSignal |
| `PORT` | `3000` | Server port |
| `GIT_SHA` | `demo` | Reported as the revision, for deploy markers |

AppSignal itself is configured in `config/appsignal.rb`. Session data is deliberately not
collected — worth mentioning out loud during a demo.

---

## Sample data

`bin/rails db:seed` is deterministic: same products, reviews and order history every
time, so your demo looks identical on every run.

- **20 products** across grills, rubs, sauces, wood and tools
- **~80 reviews**, weighted positive but not uniformly, so ratings look real
- **24 past orders** spread over the last 45 days, in various states

The catalogue lives in `db/seed_data/products.json`. Add an object to `products`, give it
a `category` matching one of the `categories`, re-seed, and it appears in the store.

---

## Tests

```sh
bin/rails test        # the full suite
bin/static-check      # syntax, routes, templates — no gems needed, ~1 second
```

The suite covers cart arithmetic and stock ceilings, VAT and shipping thresholds, order
validation and totals, the full browse-to-checkout flow, HTML escaping, open redirects,
and that each demo endpoint misbehaves in exactly the documented way.

CI runs the tests on Ruby 3.2, 3.3 and 3.4, then separately boots the app, seeds it, and
curls every storefront page and demo endpoint — including asserting that `/demo/error`
really does return 500.

---

## Layout

```
app/controllers/demo_controller.rb   The deliberately broken endpoints
app/models/cart.rb                   Session-backed cart (not Active Record)
app/models/order.rb                  Totals, VAT and shipping rules
config/appsignal.rb                  AppSignal configuration
db/seeds.rb                          Deterministic sample data
db/seed_data/products.json           The catalogue — edit this
lib/tasks/demo.rake                  Traffic generator
public/style.css                     The only stylesheet; no asset pipeline
bin/static-check                     Gem-free sanity checks
```

Deliberately absent: Action Mailer, Action Cable, Active Storage, Turbo, Stimulus, an
asset pipeline, Redis and a job backend. Every one of those is a thing that can break
five minutes before a demo.

---

## What this is not

No payment is taken and no card details are ever requested. There is no authentication,
so `/orders` and `/demo` are open to anyone who can reach the server — fine on localhost
or a private Codespace, not something to expose publicly.

Background jobs run in-process via Active Job's `:async` adapter, so they are lost on
restart. Running in production also needs `SECRET_KEY_BASE` set.

## Licence

MIT — see `LICENSE`.
