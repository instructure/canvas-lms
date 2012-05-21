$canvas_tasks_loaded ||= false
unless $canvas_tasks_loaded
$canvas_tasks_loaded = true

def check_syntax(files)
  quick = ENV["quick"] && ENV["quick"] == "true"

  show_stoppers = []
  Array(files).each do |js_file|
    js_file.strip!
    # only lint things in public/javascripts that are not in /vendor, /compiled, etc.
    if js_file.match /public\/javascripts\/(?!vendor|compiled|i18n.js|translations)/
      file_path = File.join(Rails.root, js_file)

      unless quick
        # to use this, you need to have jshint installed from npm
        # (which means you need to have node.js installed)
        # on osx you can do:
        # brew install node
        # npm install jshint
        unless `which jshint`.empty?
          puts " --> Checking #{js_file} using JSHint:"
          js_hint_errors = `jshint #{file_path} --config "#{File.join(Rails.root, '.jshintrc')}"`
          puts js_hint_errors
        end

        # Checks for coding style problems using google's js style guide.
        # Only works if you have gjslint installed.
        # Download from http://code.google.com/closure/utilities/
        unless `which gjslint`.empty?
          puts " --> Checking #{js_file} using gjslint.py:"
          gjslint_errors = `gjslint --nojsdoc --strict #{js_file}`
          puts gjslint_errors = gjslint_errors.split("\n").reject{ |l| l.match("Line too long") }.join("\n")
        end
      end

      raise "jsl needs to be in your $PATH, download from: javascriptlint.com" if `which jsl`.empty?
      puts " --> Checking #{js_file} using jsl:"
      jsl_output = `jsl -process "#{file_path}" -nologo -conf "#{File.join(Rails.root, 'config', 'jslint.conf')}"`
      exit_status = $?.exitstatus
      if exit_status != 0
        if jsl_output.match("warning: trailing comma is not legal in ECMA-262 object initializers")
          exit_status = 2
          jsl_output << "fatal trailing comma found. Stupid IE!"
        end
        if exit_status >= 2
          show_stoppers << jsl_output
        end
        puts jsl_output
      end
    end
  end
  raise "Fatal JavaScript errors found" unless show_stoppers.empty?
end


namespace :canvas do
  desc "Compresses static assets"
  task :compress_assets do
    assets = FileList.new('public/**/*.js', 'public/**/*.css')
    before_bytes = 0
    after_bytes = 0
    processed = 0
    assets.each do |asset|
      asset_compressed = "#{asset}.gz"
      unless File.exists?(asset_compressed)
        `gzip --best --stdout "#{asset}" > "#{asset_compressed}"`
        before_bytes += File::Stat.new(asset).size
        after_bytes += File::Stat.new(asset_compressed).size
        processed += 1
      end
    end
    puts "Compressed #{processed} assets, #{before_bytes} -> #{after_bytes} bytes (#{"%.0f" % ((before_bytes.to_f - after_bytes.to_f) / before_bytes * 100)}% reduction)"
  end

  task :check_syntax  => "canvas:check_syntax:all"
  namespace :check_syntax do
    desc "Checks all js files that are staged for commiting to git for syntax errors. Make your .git/hooks/pre-commit look like: rake canvas:check_syntax:changed quick=true to not allow committing js with syntax errors"
    task :changed do
      files = `git diff-index --name-only --cached HEAD -- | grep '\.js$'`
      check_syntax(files)
    end

    desc "Checks all js files for sytax errors."
    task :all do
      #bundles = YAML.load(ERB.new(File.read('config/assets.yml')).result)['javascripts']
      files = (Dir.glob('./public/javascripts/*.js')).
        reject{ |file| file =~ /\A\.\/public\/javascripts\/(i18n.js|translations\/)/ }

      check_syntax(files)
    end
  end

  desc "Compile javascript and css assets."
  task :compile_assets do
    puts "--> Compiling static assets [css]"
    Rake::Task['css:generate'].invoke

    puts "--> Compiling static assets [jammit]"
    output = `bundle exec jammit 2>&1`
    raise "Error running jammit: \n#{output}\nABORTING" if $?.exitstatus != 0

    puts "--> Compiled static assets [css/jammit]"

    puts "--> Compiling static assets [javascript]"
    Rake::Task['js:generate'].invoke

    puts "--> Generating js localization bundles"
    Rake::Task['i18n:generate_js'].invoke

    puts "--> Optimizing JavaScript [r.js]"
    Rake::Task['js:build'].invoke

    puts "--> Generating documentation [yardoc]"
    Rake::Task['doc:api'].invoke
  end

  desc "Check static assets and generate api documentation."
     task :check_static_assets do
       threads = []
       threads << Thread.new do
         puts "--> JS tests"
         Rake::Task['js:test'].invoke
       end

       threads << Thread.new do
         puts "--> i18n check"
         Rake::Task['i18n:check'].invoke
       end

       threads << Thread.new do
         puts "--> Check syntax"
         Rake::Task['canvas:check_syntax'].invoke
       end

       threads << Thread.new do
         puts "--> Generating API documentation"
         Rake::Task['doc:api'].invoke
       end
     threads.each(&:join)
   end
end

namespace :db do
  desc "Shows pending db migrations."
  task :pending_migrations => :environment do
    pending_migrations = ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations
    pending_migrations.each do |pending_migration|
      tags = pending_migration.tags
      tags = " (#{tags.join(', ')})" unless tags.empty?
      puts '  %4d %s%s' % [pending_migration.version, pending_migration.name, tags]
    end
  end

  namespace :migrate do
    desc "Run all pending predeploy migrations"
    task :predeploy => [:environment, :load_config] do
      ActiveRecord::Migrator.new(:up, "db/migrate/", nil).migrate(:predeploy)
    end

    desc "Run all pending postdeploy migrations"
    task :postdeploy => [:environment, :load_config] do
      ActiveRecord::Migrator.new(:up, "db/migrate/", nil).migrate(:postdeploy)
    end
  end

  namespace :test do
    unless Rake::Task.task_defined?('db:test:reset')
      task :reset => [:environment, :load_config] do
        raise "Run with RAILS_ENV=test" unless Rails.env.test?
        config = ActiveRecord::Base.configurations['test']
        queue = config['queue']
        drop_database(queue) if queue rescue nil
        drop_database(config) rescue nil
        create_database(queue) if queue
        create_database(config)
        Rake::Task['db:migrate'].invoke
      end
    end
  end
end

end
