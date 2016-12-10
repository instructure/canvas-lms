group :test do
  if CANVAS_RAILS4_2
    gem 'rails-dom-testing', '1.0.7'
  else
    gem 'rails-dom-testing', '2.0.1'
  end

  gem 'gergich', '0.1.6', require: false
  gem 'testingbot', require: false
  # simplecov 0.10.0 shows significantly less coverage.
  # ensure the coverage build shows accurate data
  # before upgrading past 0.9.2. (CNVS-32826)
  gem 'simplecov', '0.9.2', require: false
    gem 'docile', '1.1.5', require: false
  gem 'simplecov-rcov', '0.2.3', require: false
  gem 'bluecloth', '2.2.0' # for generating api docs
    gem 'redcarpet', '3.3.4', require: false
    gem 'github-markdown', '0.6.9', require: false
    gem 'bullet_instructure', '4.14.8', require: 'bullet'
  gem 'mocha', github: 'maneframe/mocha', ref: 'bb8813fbb4cc589d7c58073d93983722d61b6919', require: false
    gem 'metaclass', '0.0.4', require: false
  gem 'thin', '1.7.0'
    gem 'eventmachine', '1.2.0.1', require: false

  gem 'rspec', '3.5.0'
  gem 'rspec_around_all', '0.2.0'
  gem 'rspec-rails', '3.5.2'
  gem 'rspec-collection_matchers', '1.1.2'

  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-canvas', require: false, path: 'gems/rubocop-canvas'

  gem 'once-ler', '0.0.16'

  gem 'sequel', '4.39.0', require: false
  # Keep this gem synced with docker-compose/seleniumff/Dockerfile
  gem 'selenium-webdriver', '2.53.4'
    gem 'childprocess', '0.5.9', require: false
    gem 'websocket', '1.2.3', require: false
  gem 'selinimum', '0.0.1', require: false, path: 'gems/selinimum'
  gem 'test_after_commit', '1.1.0' if CANVAS_RAILS4_2
  gem 'testrailtagging', '0.3.7', require: false

  gem 'webmock', '1.22.3', require: false
    gem 'addressable', '2.3.8', require: false
    gem 'crack', '0.4.3', require: false
  gem 'yard', '0.8.7.6'
  gem 'yard-appendix', '>=0.1.8'
  gem 'timecop', '0.8.1'
  gem 'jira_ref_parser', '1.0.0'
  gem 'headless', '2.3.1', require: false
  gem 'escape_code', '0.2'
end
