# Rails Application Generator

My default Rails application generator. This is a WIP specialized to my needs,
use at your own risk. Time zone defaults to Tokyo, Japan, `I18n.default_locale`
is set to `:ja` and `I18n.available_locales` to `[:ja, :en]`, etc.

Other preferences:

- only includes required Rails gems in Gemfile by explicitly including each
  component separately (rather than all at once with the usual `gem 'rails'`)
- completely banishes Sprockets (removes asset path, etc) if `--skip-sprockets`
  flag is set (Sprockets can be entirely replaced by Webpack)
- uses [slim](http://slim-lang.com/) as template engine, and converts
  application templates from erb to slim when generating application.
- assumes postgres as database
- if `--webpack` is used, installs [Semantic UI](https://semantic-ui.com/) for
  styling along with other dependencies to customize it (`less`, etc.). This is
  loosely based on the setup described
  [here](https://medium.com/@xijo/webpacker-less-semantic-ui-theming-702e4a6a806).
- if `--webpack`, installs jQuery (with `yarn`) and adds js to load it using
  Provide plugin.
- uses `rspec` + `factory_bot` for testing.
- with `--webpack` enabled, uses `/frontend` as its source path, following the
  component-based approach described in [this
  article](https://evilmartians.com/chronicles/evil-front-part-1).

## Usage

To use it, set the following in your `.railsrc` file:

```
--skip-test
--database=postgresql
--skip-sprockets
--skip-javascript
--skip-system-test
--skip-active-storage
--webpack
```

Then specify the template when generating your Rails app:

```ruby
rails new foo -m https://raw.githubusercontent.com/shioyama/rails-template/master/template.rb
```

You can also try the generator with different skip settings, and things
*should* work, but I haven't tested with other combinations very extensively.
