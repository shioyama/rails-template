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

gemfile_gems = gem_names.inject("") do |gems, gem_name|
  gems << "gem \"#{gem_name}\", \"#{RAILS_VERSION}\"\n"
end

in_root do
  gsub_file "Gemfile", /^gem 'rails'.*$/, gemfile_gems
  gsub_file "Gemfile", /^gem 'jbuilder'/, "# gem 'jbuilder'" if options[:skip_javascript]
  # Replace byebug with pry-byebug, which anyway depends on byebug
  gsub_file "Gemfile", /gem 'byebug'/, "gem 'pry-byebug'"
  gsub_file "Gemfile", /^group :development, :test do$/, <<-EOF
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
EOF
end

gem 'slim-rails', '~> 3.1'
gem 'foreman'

# Add foreman procfile
create_file "Procfile" do <<-EOF
server: bundle exec puma -p 3000
assets: bin/webpack-dev-server
EOF
end

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
    run "rails webpacker:install:erb"

    # See: https://evilmartians.com/chronicles/evil-front-part-1
    gsub_file "config/webpacker.yml", /source_path\: app\/javascript/, "source_path: frontend"
    insert_into_file "app/controllers/application_controller.rb", <<-EOF, after: /^class ApplicationController.*\n/
  prepend_view_path Rails.root.join("frontend")
EOF
    insert_into_file "app/helpers/application_helper.rb", <<-EOF, after: /^module ApplicationHelper.*\n/
  def component(component_name, locals = {}, &block)
    name = component_name.split("_").first
    render(['components', name, component_name].compact.join('/'), locals, &block)
  end

  alias c component
EOF
    create_file "lib/generators/component_generator.rb" do <<-EOF
class ComponentGenerator < Rails::Generators::Base
  argument :component_name, required: true, desc: "Component name, e.g: button"

  def create_view_file
    #{'create_file "#{component_path}/_#{component_name}.html.slim"'}
  end

  def create_css_file
    #{'create_file "#{component_path}/#{component_name}.scss"'}
  end

  def create_js_file
    create_file "\#{component_path}/\#{component_name}.js" do
      # require component's CSS inside JS automatically
      "#{'import \"./#{component_name}.scss\";\n'}"
    end
  end

  protected

  def component_path
    "#{'frontend/components/#{component_name}'}"
  end
end
EOF
    end

    run "mv app/javascript frontend"
    run "mkdir frontend/site"
    run "mkdir frontend/components"
    run "mkdir frontend/init"
    run "mkdir frontend/images"

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

    npm_packages = %w[jquery less less-loader rails-erb-loader rails-ujs resolve-url-loader]
    npm_packages += ["turbolinks"] unless options[:skip_turbolinks]
    npm_packages += ["activestorage"] unless options[:skip_active_storage]
    run "yarn add #{npm_packages.join(' ')} --save"
    run "yarn add semantic-ui --dev"

    run "cp node_modules/semantic-ui/src/theme.config.example frontend/theme.config"
    gsub_file "frontend/theme.config", /^@siteFolder\s+:\s+'site';$/, "@siteFolder  :  '../../site';"
    gsub_file "frontend/theme.config", /^@import\s.*\s\"theme.less\";$/, "@import (multiple) \"./semantic/src/theme.less\";"
    append_file "frontend/theme.config", "\n@fontPath : \"../../../themes/@{theme}/assets/fonts\";"

    insert_into_file "config/webpack/environment.js", <<-EOF, before: "module.exports"

const less = require('./loaders/less')
environment.loaders.append('less', less)

const webpack = require('webpack')
environment.plugins.append('Provide', new webpack.ProvidePlugin({
  $: 'jquery',
  jQuery: 'jquery',
  jquery: 'jquery'
}))

environment.config.set('resolve.alias', {
  '../../theme.config': '../../../../theme.config'
})

EOF

    create_file "config/webpack/loaders/less.js" do <<-EOF
const ExtractTextPlugin = require('extract-text-webpack-plugin');

module.exports = {
  test: /\.less$/,
  use: ExtractTextPlugin.extract({
    use: ['css-loader', 'less-loader']
  })
}
EOF
    end

    create_file "frontend/init/index.js" do <<-EOF
import "./index.scss"
EOF
    end
    create_file "frontend/init/index.scss"

    remove_file "frontend/packs/application.js"
    create_file "frontend/packs/application.js.erb" do <<-EOF
import 'semantic/src/semantic.less'
// Import whatever semantic ui modules you need, e.g.:
// import 'semantic/src/definitions/behaviors/api'

import "init"

// Import all images in frontend/images
<% images = Webpacker.config.source_path.join('images').glob('**/*.{png,svg}') %>
<% images.each do |image| %>
  import '<%= image %>';
<% end %>

import Rails from 'rails-ujs'
Rails.start()
#{%q{
import Turbolinks from 'turbolinks'
Turbolinks.start()} unless options[:skip_turbolinks]}
EOF
    end
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
        g.orm :active_record} unless options[:skip_active_record] }
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
        g.channel          assets: false} if options[:skip_sprockets] }
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

  # Git
  git init: "--quiet"
  git add: ".", commit: %(--all --no-verify --quiet --message "Initial commit.")
end
