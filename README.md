# Rails Application Generator

My WIP default Rails application generator. Currently configured to work with Rails 5.2.

This is very much specialized to my needs, so the time zone defaults to Tokyo,
Japan, `I18n.default_locale` is set to `:ja` and `I18n.available_locales` to
`[:ja, :en]`, etc.

Other preferences:

- [slim](http://slim-lang.com/) as template engine
- postgres as database
- [Semantic UI](https://semantic-ui.com/) for styling
- rspec for testing

To use it, just specify the template when generating your Rails app:

```ruby
rails new foo -m https://raw.githubusercontent.com/shioyama/rails-template/master/template.rb
```
