# frozen_string_literal: true
RAILS_VERSION = '~> 5.2.1'

remove_file "Gemfile"
run "touch Gemfile"
add_source 'https://rubygems.org'

%w[activerecord activemodel actionpack actionview actionmailer activejob activesupport railties].each do |gem_name|
  gem gem_name, RAILS_VERSION
end
gem 'sprockets-rails', '~> 3.2.1'

gem 'pg', '~> 1.0'
gem 'puma', '~> 3.11'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'slim-rails', '~> 3.1'
gem 'html2slim'
gem 'coffee-rails', '~> 4.2'
gem 'semantic-ui-sass', git: 'https://github.com/doabit/semantic-ui-sass.git'
gem 'bootsnap', '>= 1.1.0', require: false

gem_group :development, :test do
  gem 'pry-byebug'
  gem 'rspec-rails'
  gem 'factory_bot_rails'
end

gem_group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Remove stuff we don't need
remove_file "app/helpers"
remove_file "app/channels"
remove_file 'app/assets/javascripts/cable.js'
remove_file "config/cable.yml"

inside 'config' do
  remove_file 'database.yml'
  create_file 'database.yml' do <<-EOF
default: &default
  adapter: postgresql
  username: postgres
  encoding: unicode

development:
  <<: *default
  database: #{app_name}_development

test:
  <<: *default
  database: #{app_name}_test

EOF
  end
end

after_bundle do
  gsub_file 'app/assets/javascripts/application.js', '//= require activestorage', '//# require activestorage'
  gsub_file 'app/assets/javascripts/application.js', '//= require turbolinks', '//# require turbolinks'
  gsub_file 'config/application.rb', 'require "active_storage/engine"', '# require "active_storage/engine"'
  gsub_file 'config/application.rb', 'require "action_cable/engine"', '# require "action_cable/engine"'
  %w[test development production].each do |env|
    gsub_file "config/environments/#{env}.rb", /config\.active_storage/, '# config.active_storage'
  end

  # set config/application.rb
  application  do
    %q{
      # Set timezone
      config.time_zone = 'Tokyo'
      config.active_record.default_timezone = :local

      # Set locale
      I18n.enforce_available_locales = true
      config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
      config.i18n.default_locale = :ja
      config.i18n.available_locales = [:ja, :en]

      # Set generator
      config.generators do |g|
        g.orm :active_record
        g.template_engine :slim
        g.test_framework :rspec, :fixture => true
        g.fixture_replacement :factory_girl, :dir => "spec/factories"
        g.view_specs false
        g.controller_specs true
        g.routing_specs false
        g.helper_specs false
        g.request_specs false
        g.assets false
        g.helper false
      end
    }
  end

  # set Japanese locale
  get 'https://raw.githubusercontent.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml', 'config/locales/ja.yml'

  run 'for file in app/views/**/*.erb; do erb2slim $file ${file%erb}slim && rm $file; done'

  run "spring stop"
  generate 'rspec:install'
  run "echo '--color -f d' > .rspec"

  # # Git
  git init: "--quiet"
  git add: ".", commit: %(--all --no-verify --quiet --message "Initial commit.")
end
