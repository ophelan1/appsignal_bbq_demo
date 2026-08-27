Rails.application.routes.draw do
  root "products#index"

  get "products",       to: "products#index",  as: :products
  get "products/:slug", to: "products#show",   as: :product
  get "categories/:slug", to: "products#category", as: :category
  get "search",         to: "products#search", as: :search

  get    "cart",             to: "carts#show",        as: :cart
  post   "cart/add",         to: "carts#add",         as: :cart_add
  patch  "cart/update",      to: "carts#update_item", as: :cart_update
  delete "cart/remove",      to: "carts#remove_item", as: :cart_remove

  get  "checkout",           to: "orders#new",    as: :checkout
  post "checkout",           to: "orders#create"
  get  "orders",             to: "orders#index",  as: :orders
  get  "orders/:reference",  to: "orders#show",   as: :order

  # Everything below exists to give AppSignal something worth looking at.
  # None of it is part of the storefront a customer would use.
  get  "demo",                to: "demo#index",           as: :demo
  get  "demo/slow_query",     to: "demo#slow_query",      as: :demo_slow_query
  get  "demo/n_plus_one",     to: "demo#n_plus_one",      as: :demo_n_plus_one
  get  "demo/optimised",      to: "demo#optimised",       as: :demo_optimised
  get  "demo/error",          to: "demo#error",           as: :demo_error
  get  "demo/handled_error",  to: "demo#handled_error",   as: :demo_handled_error
  post "demo/background_job", to: "demo#background_job",  as: :demo_background_job
  get  "demo/external_http",  to: "demo#external_http",   as: :demo_external_http
  get  "demo/memory_hog",     to: "demo#memory_hog",      as: :demo_memory_hog
  get  "demo/custom_metric",  to: "demo#custom_metric",   as: :demo_custom_metric

  get "up", to: "health#show", as: :health
end
