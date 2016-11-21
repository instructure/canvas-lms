require 'timeout'
require 'json'
require_relative "../../config/initializers/webpack"

namespace :js do
  desc 'run Karma as you develop, can use `rake js:dev <ember app name> <browser>`'
  task :dev do
    app = ARGV[1]
    app = nil if app == 'NA'
    #browsers = ARGV[2] || 'Firefox,Chrome,Safari'
    browsers = ARGV[2] || 'Chrome'
    if app
      ENV['JS_SPEC_MATCHER'] = matcher_for_ember_app app
      unless File.exists?("app/coffeescripts/ember/#{app}")
        puts "no app found at app/coffeescripts/ember/#{app}"
        exit
      end
    end
    build_runner
    exec("node_modules/.bin/karma start --browsers #{browsers}")
  end

  def matcher_for_ember_app app_name
    "**/#{app_name}/**/*.spec.js"
  end

  desc 'generate requirejs loader file @ spec/javascripts/load_tests.js'
  task :generate_runner do
    build_runner
  end

  def build_runner
    require 'canvas/require_js'
    require 'erubis'
    output = Erubis::Eruby.new(File.read("#{Rails.root}/spec/javascripts/load_tests.js.erb")).
        result(Canvas::RequireJs.get_binding)
    File.open("#{Rails.root}/spec/javascripts/load_tests.js", 'w') { |f| f.write(output) }
    build_requirejs_config
  end

  def generate_prng
    if ENV["seed"]
      seed = ENV["seed"].to_i
    else
      srand
      seed = rand(1 << 20)
    end
    puts "--> randomized with seed #{seed}"
    Random.new(seed)
  end

  def build_requirejs_config
    require 'canvas/require_js'
    require 'erubis'
    output = Erubis::Eruby.new(File.read("#{Rails.root}/spec/javascripts/requirejs_config.js.erb")).
        result(Canvas::RequireJs.get_binding)
    File.open("#{Rails.root}/spec/javascripts/requirejs_config.js", 'w') { |f| f.write(output) }
  end

  desc 'test javascript specs with Karma'
  task :test, :reporter do |task, args|
    reporter = args[:reporter]
    if CANVAS_WEBPACK
      Rake::Task['i18n:generate_js'].invoke
      webpack_test_dir = Rails.root + "spec/javascripts/webpack"
      FileUtils.rm_rf(webpack_test_dir)
      puts "--> Bundling tests for ember apps"
      `npm run webpack-test-ember`
      puts "--> Running tests for ember apps"
      test_suite(reporter)
      FileUtils.rm_rf(webpack_test_dir)
      puts "--> Bundling tests for canvas proper"
      `npm run webpack-test`
      puts "--> Running tests for canvas proper"
      test_suite(reporter)
    else
      require 'canvas/require_js'

      # run test for each ember app individually
      matcher = ENV['JS_SPEC_MATCHER']

      if matcher
        puts "--> Matcher: #{matcher}"
      end

      if !matcher || matcher.to_s =~ %r{app/coffeescripts/ember}
        ignored_embers = ['shared','modules'] #,'quizzes','screenreader_gradebook'
        Dir.entries('app/coffeescripts/ember').reject { |d|
          d.match(/^\./) || ignored_embers.include?(d)
        }.each do |ember_app|
          puts "--> Running tests for '#{ember_app}' ember app"
          ENV["JS_SPEC_MATCHER"] = matcher_for_ember_app ember_app
          test_suite(reporter)
        end

        ENV['JS_SPEC_MATCHER'] = nil
      end

      test_suite(reporter)
    end
  end

  def test_suite(reporter = nil)
    return if test_js_with_timeout(300, reporter)

    do_retry = ENV['retry'] != 'false' && !ENV['JS_SPEC_MATCHER']
    raise "Karma tests failed" unless do_retry

    puts "--> Karma tests failed." # retrying karma...
    test_js_with_timeout(400, reporter) or raise "Karma tests failed on second attempt."
  end

  def test_js_with_timeout(timeout,reporter)
    require 'canvas/require_js'
    Timeout::timeout(timeout) do
      quick = ENV["quick"] && ENV["quick"] == "true"
      unless quick
        puts "--> do rake js:test quick=true to skip generating compiled coffeescript and handlebars."
        Rake::Task['js:generate'].invoke
      end
      puts "--> executing browser tests with Karma"
      build_runner
      reporters = ['progress', 'coverage', reporter].reject(&:blank?).join(',')
      command = %Q{./node_modules/karma/bin/karma start --browsers Chrome --single-run --reporters #{reporters}}
      puts "running karma with command: #{command} on node #{`node -v`}"
      result = system(command)

      puts 'some specs failed' unless result
      result
    end
  rescue Timeout::Error
    puts "Karma tests reached timeout!"
    false
  end
end
