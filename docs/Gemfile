# Gems to build the documentation locally, as GitHub Pages does:
#   bundle install
#   bundle exec jekyll serve
source "https://rubygems.org"

# The same Jekyll version and plugins as GitHub Pages (jekyll-paginate, jekyll-redirect-from, ...)
gem "github-pages", group: :jekyll_plugins

# Needed by `jekyll serve` with Ruby 3 and later
gem "webrick"

# Standard libraries that Ruby 3.4 no longer includes by default
# (Ruby 4 does not work with the github-pages gems; use Ruby 3.3, as GitHub Pages does)
gem "csv"
gem "base64"
gem "bigdecimal"
gem "logger"
