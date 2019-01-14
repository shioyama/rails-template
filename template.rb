# This generator is intended to be run with the following flags:
#
#   --skip-test
#   --database=postgresql
#   --skip-sprockets
#   --skip-javascript
#   --skip-system-test
#   --skip-active-storage
#   --webpack
#
# Put them in a .railsrc and run:
#
#   rails new foo -m ~/dev/rails-template/template.rb
#
# It also attempts to accommodate other combination of skip flags in a sensible
# way, but has not been tested very much for this.
#
RAILS_VERSION = '~> 5.2.2'

gem_names = %w[activemodel actionpack activejob activesupport railties]
gem_names << "activerecord"  unless options[:skip_active_record]
gem_names << "actionmailer"  unless options[:skip_action_mailer]
gem_names << "actioncable"   unless options[:skip_action_cable]
gem_names << "activestorage" unless options[:skip_active_storage]

gemfile_gems = gem_names.inject("") { |gems, gem_name| gems << "gem \"#{gem_name}\", \"#{RAILS_VERSION}\"\n" }

in_root do
  gsub_file "Gemfile", /^gem 'rails'.*$/, gemfile_gems, verbose: false
  gsub_file "Gemfile", /^gem 'jbuilder'/, "# gem 'jbuilder'", verbose: false if options[:skip_javascript]
  # Replace byebug with pry-byebug, which anyway depends on byebug
  gsub_file "Gemfile", /gem 'byebug'/, "gem 'pry-byebug'", verbose: false
  gsub_file "Gemfile", /^group :development, :test do$/, <<-EOF
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
EOF
end

gem 'slim-rails', '~> 3.1'

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
  if options[:webpack]
    # See: https://evilmartians.com/chronicles/evil-front-part-1
    gsub_file "config/webpacker.yml", /source_path\: app\/javascript/, "source_path: frontend", verbose: false
    run "mv app/javascript frontend"

    create_file 'semantic.json' do <<-EOF
{
  "base": "frontend/semantic",
  "paths": {
    "source": {
      "config": "src/theme.config",
      "definitions": "src/definitions/",
      "site": "src/site/",
      "themes": "src/themes/"
    },
    "output": {
      "packaged": "dist/",
      "uncompressed": "dist/components/",
      "compressed": "dist/components/",
      "themes": "dist/themes/"
    },
    "clean": "dist/"
  },
  "permission": false,
  "autoInstall": true,
  "rtl": false,
  "components": ["reset", "site", "button", "container", "divider", "flag", "header", "icon", "image", "input", "label", "list", "loader", "placeholder", "rail", "reveal", "segment", "step", "breadcrumb", "form", "grid", "menu", "message", "table", "ad", "card", "comment", "feed", "item", "statistic", "accordion", "checkbox", "dimmer", "dropdown", "embed", "modal", "nag", "popup", "progress", "rating", "search", "shape", "sidebar", "sticky", "tab", "transition", "api", "form", "state", "visibility"],
  "version": "2.4.2"
}
EOF
    end

    run "yarn add jquery less less-loader rails-erb-loader rails-ujs resolve-url-loader #{"turbolinks " unless options[:skip_turbolinks]}--save"
    run "yarn add semantic-ui --dev"

    run "cp node_modules/semantic-ui/src/theme.config.example frontend/theme.config"
  end

  # Remove sprockets assets path if we're skipping sprockets
  run "rm -rf app/assets" if options[:skip_sprockets]

  # set config/application.rb
  application do <<-EOF
      # Set timezone
      config.time_zone = 'Tokyo'#{%q{
      config.active_record.default_timezone = :local} unless options[:skip_active_record] }

      # Set locale
      I18n.enforce_available_locales = true
      config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
      config.i18n.default_locale = :ja
      config.i18n.available_locales = [:ja, :en]

      # Set generator
      config.generators do |g|#{%q{
        g.orm :active_record
} unless options[:skip_active_record] }
        g.template_engine :slim
        g.test_framework :rspec, :fixture => true
        g.fixture_replacement :factory_bot, :dir => "spec/factories"

        # Specs
        g.view_specs       false
        g.controller_specs true
        g.routing_specs    false
        g.helper_specs     false
        g.request_specs    false#{%q{

        # Assets
        g.stylesheets      false
        g.javascripts      false
        g.helper           false
        g.channel          assets: false
} if options[:skip_sprockets] }
      end
EOF
  end

  # set Japanese locale
  get 'https://raw.githubusercontent.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml', 'config/locales/ja.yml'
  run 'rm config/locales/en.yml'
  get 'https://raw.githubusercontent.com/svenfuchs/rails-i18n/master/rails/locale/en.yml', 'config/locales/en.yml'

  run 'gem install html2slim'
  run 'for file in app/views/**/*.erb; do erb2slim $file ${file%erb}slim && rm $file; done'

  run "spring stop"
  generate 'rspec:install'
  run "echo '--color -f d' > .rspec"

  # # Git
  git init: "--quiet"
  git add: ".", commit: %(--all --no-verify --quiet --message "Initial commit.")
end
