# Rails Application Generator

My default Rails application generator. This is a WIP specialized to my needs,
use at your own risk. Time zone defaults to Tokyo, Japan, `I18n.default_locale`
is set to `:ja` and `I18n.available_locales` to `[:ja, :en]`, etc.

Other preferences:

- Completely banishes Sprockets (removes asset path, etc) if `skip-sprockets`
  flag is set
- Uses [slim](http://slim-lang.com/) as template engine
- Assumes postgres as database
- If `--webpack` is used, installs [Semantic UI](https://semantic-ui.com/) for
  styling along with other dependencies to customize it (`less`, etc.). Also
  installs jQuery.
- Uses rspec + factory_bot for testing

If `--webpack` is passed in, the generator uses `/frontend` as its source path,
following the component-based approach described in [this
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
