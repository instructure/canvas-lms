group :test do
  gem 'testingbot', require: false
  gem 'simplecov', '0.9.2', require: false
    gem 'docile', '1.1.3', require: false
  gem 'simplecov-rcov', '0.2.3', require: false
  gem 'bluecloth', '2.2.0' # for generating api docs
    gem 'redcarpet', '3.2.3', require: false
    gem 'github-markdown', '0.6.8', require: false
    gem 'bullet_instructure', '4.14.8', require: 'bullet'
  gem 'mocha', github: 'maneframe/mocha', ref: 'bb8813fbb4cc589d7c58073d93983722d61b6919', require: false
    gem 'metaclass', '0.0.2', require: false
  gem 'thin', '1.6.3'
    gem 'eventmachine', '1.0.4', require: false

  gem 'rspec', '3.4.0'
  gem 'rspec-rails', '3.4.1'
  gem 'rspec-collection_matchers', '1.1.2'
  gem 'shoulda-matchers', '2.8.0'

  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-canvas', require: false, path: 'gems/rubocop-canvas'

  gem 'once-ler', '0.0.15'

  gem 'sequel', '4.5.0', require: false
  # Keep this gem synced with docker-compose/seleniumff/Dockerfile
  gem 'selenium-webdriver', '2.53.4'
    gem 'childprocess', '0.5.0', require: false
    gem 'websocket', '1.0.7', require: false
  gem 'selinimum', '0.0.1', require: false, path: 'gems/selinimum'
  gem 'test_after_commit', '0.4.2'
  gem 'testrailtagging', '~> 0.3.6.5', git: 'https://github.com/instructure/testrailtagging', ref: 'master', require: false

  gem 'webmock', '1.22.3', require: false
    gem 'addressable', '2.3.8', require: false
    gem 'crack', '0.4.3', require: false
  gem 'yard', '0.8.7.6'
  gem 'yard-appendix', '>=0.1.8'
  gem 'timecop', '0.6.3'
  gem 'jira_ref_parser', '1.0.0'
  gem 'headless', '2.2.0', require: false
  gem 'escape_code', '0.2'

  unless CANVAS_RAILS4_0
    gem 'rails-dom-testing', '1.0.7'
  end
end
