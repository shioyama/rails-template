# Rails Application Generator

My default Rails application generator. This is a WIP specialized to my needs,
use at your own risk. Time zone defaults to Tokyo, Japan, `I18n.default_locale`
is set to `:ja` and `I18n.available_locales` to `[:ja, :en]`, etc.

Other preferences:

- Removes assets path, assumes you are using Webpack instead of Sprockets
- Uses [slim](http://slim-lang.com/) as template engine
- Assumes postgres as database
- [Semantic UI](https://semantic-ui.com/) for styling
- rspec + factory_bot for testing

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
