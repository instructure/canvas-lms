require 'i18n/hash_extensions'
require 'json'

namespace :i18n do
  def infer_scope(filename)
    case filename
      when /app\/views\/.*\.handlebars\z/
        filename.gsub(/.*app\/views\/jst\/_?|\.handlebars\z/, '').underscore.gsub(/\/_?/, '.')
      when /app\/controllers\//
        scope = filename.gsub(/.*app\/controllers\/|controller.rb/, '').gsub(/\/_?|_\z/, '.')
        scope == 'application.' ? '' : scope
      when /app\/messages\//
        filename.gsub(/.*app\/|erb/, '').gsub(/\/_?/, '.')
      when /app\/models\//
        scope = filename.gsub(/.*app\/models\/|rb/, '')
        STI_SUPERCLASSES.include?(scope) ? '' : scope
      when /app\/views\//
        filename.gsub(/.*app\/views\/|(html\.|fbml\.)?erb\z/, '').gsub(/\/_?/, '.')
      else
        ''
    end
  end

  desc "Verifies all translation calls"
  task :check => :environment do
    Bundler.require :i18n_tools
    only = if ENV['ONLY']
      ENV['ONLY'].split(',').map{ |path|
        path = '**/' + path if path =~ /\*/
        path = './' + path unless path =~ /\A.?\//
        if path =~ /\*/
          path = Dir.glob(path)
        elsif path !~ /\.(e?rb|js)\z/
          path = Dir.glob(path + '/**/*')
        end
        path
      }.flatten
    end

    STI_SUPERCLASSES = (`grep '^class.*<' ./app/models/*rb|grep -v '::'|sed 's~.*< ~~'|sort|uniq`.split("\n") - ['OpenStruct', 'Tableless']).
      map{ |name| name.underscore + '.' }

    COLOR_ENABLED = ($stdout.tty? rescue false)
    def color(text, color_code)
      COLOR_ENABLED ? "#{color_code}#{text}\e[0m" : text
    end

    def green(text)
      color(text, "\e[32m")
    end

    def red(text)
      color(text, "\e[31m")
    end

    @errors = []
    def process_files(files)
      files.each do |file|
        begin
          print green "." if yield file
        rescue SyntaxError, StandardError
          @errors << "#{$!}\n#{file}"
          print red "F"
        end
      end
    end

    t = Time.now

    I18n.available_locales
    stringifier = proc { |hash, (key, value)|
      hash[key.to_s] = value.is_a?(Hash) ?
        value.inject({}, &stringifier) :
        value
      hash
    }
    @translations = I18n.backend.send(:translations)[:en].inject({}, &stringifier)


    # Ruby
    files = (Dir.glob('./*') - ['./vendor'] + ['./vendor/plugins/*'] - ['./guard', './tmp']).map { |d| Dir.glob("#{d}/**/*rb") }.flatten.
      reject{ |file| file =~ %r{\A\./(rb-fsevent|vendor/plugins/rails_xss|db|spec)/} }
    files &= only if only
    file_count = files.size
    rb_extractor = I18nExtraction::RubyExtractor.new(:translations => @translations)
    process_files(files) do |file|
      source = File.read(file)
      source = Erubis::Eruby.new(source).src if file =~ /\.erb\z/

      # add a magic comment since that's the best way to convince RubyParser
      # 3.x it should treat the source as utf-8 (it ignores the source string encoding)
      # see https://github.com/seattlerb/ruby_parser/issues/101
      # unforunately this means line numbers in error messages are off by one
      sexps = RubyParser.for_current_ruby.parse("#encoding:utf-8\n#{source}")
      rb_extractor.scope = infer_scope(file)
      rb_extractor.in_html_view = (file =~ /\.(html|facebook)\.erb\z/)
      rb_extractor.process(sexps)
    end


    # JavaScript
    files = (Dir.glob('./public/javascripts/**/*.js') + Dir.glob('./app/views/**/*.erb')).
      reject{ |file| file =~ /\A\.\/public\/javascripts\/(i18nObj.js|i18n.js|jst\/|translations\/|compiled\/handlebars_helpers.js|tinymce\/jscripts\/tiny_mce(.*\/langs|\/tiny_mce\w*\.js))/ }
    files &= only if only
    js_extractor = I18nExtraction::JsExtractor.new(:translations => @translations)
    process_files(files) do |file|
      t2 = Time.now
      ret = js_extractor.process(File.read(file), :erb => (file =~ /\.erb\z/), :filename => file)
      file_count += 1 if ret
      puts "#{file} #{Time.now - t2}" if Time.now - t2 > 1
      ret
    end


    # Handlebars
    files = Dir.glob('./app/views/jst/**/*.handlebars')
    files &= only if only
    handlebars_extractor = I18nExtraction::HandlebarsExtractor.new(:translations => @translations)
    process_files(files) do |file|
      file_count += 1 if handlebars_extractor.process(File.read(file), infer_scope(file))
    end

    print "\n\n"
    failure = @errors.size > 0

    @errors.each_index do |i|
      puts "#{i+1})"
      puts red @errors[i]
      print "\n"
    end

    print "Finished in #{Time.now - t} seconds\n\n"
    total_strings = rb_extractor.total_unique + js_extractor.total_unique + handlebars_extractor.total_unique
    puts send((failure ? :red : :green), "#{file_count} files, #{total_strings} strings, #{@errors.size} failures")
    raise "check command encountered errors" if failure
  end

  desc "Generates a new en.yml file for all translations"
  task :generate => :check do
    yaml_dir = './config/locales/generated'
    FileUtils.mkdir_p(File.join(yaml_dir))
    yaml_file = File.join(yaml_dir, "en.yml")
    File.open(Rails.root.join(yaml_file), "w") do |file|
      file.write({'en' => @translations}.ya2yaml(:syck_compatible => true))
    end
    print "Wrote new #{yaml_file}\n\n"
  end

  desc "Generates JS bundle i18n files (non-en) and adds them to assets.yml"
  task :generate_js do
    require 'bundler'
    Bundler.setup
    require 'action_controller'
    require 'i18n'
    require 'sexp_processor'
    require 'jammit'
    require 'lib/i18n_extraction/js_extractor.rb'
    I18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')] +
                      Dir[Rails.root.join('vendor', 'plugins', '*', 'config', 'locales', '**', '*.{rb,yml}')]

    Hash.send :include, I18n::HashExtensions

    file_translations = {}

    locales = I18n.available_locales - [:en]
    # allow passing of extra, empty locales by including a comma-separated
    # list of abbreviations in the LOCALES environment variable. e.g.
    #
    # LOCALES=hi,ja,pt,zh-hans rake i18n:generate_js
    locales = locales + ENV['LOCALES'].split(',') if ENV['LOCALES']
    all_translations = I18n.backend.send(:translations)
    flat_translations = all_translations.flatten_keys

    if locales.empty?
      puts "Nothing to do, there are no non-en translations"
      exit 0
    end

    process_files = lambda do |extractor, files, arg_block|
      files.each do |file|
        begin
          extractor.translations = {}
          extractor.process(File.read(file), *arg_block.call(file)) or next

          translations = extractor.translations.flatten_keys.keys
          next if translations.empty?

          file_translations[extractor.scope] ||= {}
          locales.each do |locale|
            file_translations[extractor.scope].update flat_translations.slice(*translations.map{ |k| k.gsub(/\A/, "#{locale}.") })
          end
        rescue
          raise "Error reading #{file}: #{$!}\nYou should probably run `rake i18n:check' first"
        end
      end
    end

    # JavaScript
    files = Dir.glob('./public/javascripts/**/*.js').
      reject{ |file| file =~ /\A\.\/public\/javascripts\/(i18nObj.js|i18n.js|jst\/|translations\/|compiled\/handlebars_helpers.js|tinymce\/jscripts\/tiny_mce(.*\/langs|\/tiny_mce\w*\.js))/ }
    js_extractor = I18nExtraction::JsExtractor.new
    process_files.call(js_extractor, files, lambda{ |file| [{:filename => file}] } )

    # Handlebars
    files = Dir.glob('./app/views/jst/**/*.handlebars')
    handlebars_extractor = I18nExtraction::HandlebarsExtractor.new
    process_files.call(handlebars_extractor, files, lambda{ |file| [infer_scope(file)] } )

    dump_translations = lambda do |translation_name, translations|
      file = "public/javascripts/translations/#{translation_name}.js"
      locales.each { |locale| translations[locale.to_s] ||= {} }
      content = <<-TRANSLATIONS
// this file was auto-generated by rake i18n:generate_js.
// you probably shouldn't edit it directly
define(['i18nObj', 'jquery'], function(I18n, $) {
  $.extend(true, I18n, {translations: #{translations.to_ordered.to_json}});
});
      TRANSLATIONS
      if !File.exist?(file) || File.read(file) != content
        File.open(file, "w"){ |f| f.write content }
      end
    end

    file_translations.each do |scope, translations|
      dump_translations.call(scope, translations.expand_keys)
    end

    # in addition to getting the non-en stuff into each scope_file, we need to get the core
    # formats and stuff for all languages (en included) into the common scope_file
    core_translations = I18n.available_locales.inject({}) { |h1, locale|
      h1[locale.to_s] = all_translations[locale].slice(:date, :time, :number, :datetime, :support)
      h1
    }
    dump_translations.call('_core_en', {'en' => core_translations.delete('en')})
    dump_translations.call('_core', core_translations)
  end

  desc "Exports new/changed English strings to be translated"
  task :export => :environment do
    Hash.send :include, I18n::HashExtensions

    begin
      base_filename = "config/locales/generated/en.yml"
      export_filename = 'en.yml'
      current_branch = nil

      prevgit = {}
      prevgit[:branch] = `git branch | grep '\*'`.sub(/^\* /, '').strip
      prevgit.delete(:branch) if prevgit[:branch].blank? || prevgit[:branch] == 'master'
      unless `git status -s | grep -v '^\?\?' | wc -l`.strip == '0'
        `git stash`
        prevgit[:stashed] = true
      end

      last_export = nil
      begin
        puts "Enter path or hash of previous export base (omit to export all):"
        arg = $stdin.gets.strip
        if arg.blank?
          last_export = {:type => :none}
        elsif arg =~ /\A[a-f0-9]{7,}\z/
          puts "Fetching previous export..."
          ret = `git show --name-only --oneline #{arg}`
          if $?.exitstatus == 0
            if ret.include?(base_filename)
              `git checkout #{arg}`
              if previous = YAML.safe_load(File.read(base_filename)).flatten_keys rescue nil
                last_export = {:type => :commit, :data => previous}
              else
                $stderr.puts "Unable to load en.yml file"
              end
            else
              $stderr.puts "Commit contains no en.yml file"
            end
          else
            $stderr.puts "Invalid commit hash"
          end
          `git status -s | grep -v '^\?\?' | wc -l`
        else
          puts "Loading previous export..."
          if File.exist?(arg)
            if previous = YAML.safe_load(File.read(arg)).flatten_keys rescue nil
              last_export = {:type => :file, :data => previous}
            else
              $stderr.puts "Unable to load yml file"
            end
          else
            $stderr.puts "Invalid path"
          end
        end
      end until last_export

      begin
        puts "Enter local branch containing current en translations (default master):"
        current_branch = $stdin.gets.strip
      end until current_branch.blank? || current_branch !~ /[^a-z0-9_\.\-]/
      current_branch = nil if current_branch.blank?

      puts "Extracting current en translations..."
      `git checkout #{current_branch || 'master'}` if last_export[:type] == :commit || current_branch != prevgit[:branch]
      Rake::Task["i18n:generate"].invoke

      puts "Exporting #{last_export[:data] ? "new/changed" : "all"} en translations..."
      current_strings = YAML.safe_load(File.read(base_filename)).flatten_keys
      new_strings = last_export[:data] ?
        current_strings.inject({}){ |h, (k, v)|
          h[k] = v unless last_export[:data][k] == v
          h
        } :
        current_strings
      File.open(export_filename, "w"){ |f| f.write new_strings.expand_keys.ya2yaml(:syck_compatible => true) }

      push = 'n'
      begin
        puts "Commit and push current translations? (Y/N)"
        push = $stdin.gets.strip.downcase[0, 1]
      end until ["y", "n"].include?(push)
      if push == 'y'
        `git add #{base_filename}`
        if `git status -s | grep -v '^\?\?' | wc -l`.strip == '0'
          puts "Exported en.yml, current translations unmodified (check git log for last change)"
        else
          `git commit -a -m"generated en.yml for translation"`
          remote_branch = `git remote-ref`.strip.sub(%r{\Aremotes/[^/]+/(.*)\z}, '\\1')
          local = current_branch || 'master'
          `remote=$(git config branch."#{local}".remote); \
           remote_ref=$(git config branch."#{local}".merge); \
           remote_name=${remote_ref##refs/heads/}; \
           git push $remote HEAD:refs/for/$remote_name`
          puts "Exported en.yml, committed/pushed current translations (#{`git log --oneline|head -n 1`.sub(/ .*/m, '')})"
        end
      else
        puts "Exported en.yml, dumped current translations (not committed)"
      end
    ensure
      `git checkout #{prevgit[:branch] || 'master'}` if prevgit[:branch] != current_branch
      `git stash pop` if prevgit[:stashed]
    end
  end

  desc "Validates and imports new translations"
  task :import, [:source_file, :translated_file] => :environment do |t, args|
    require 'ya2yaml'
    require 'open-uri'
    Hash.send(:include, I18n::HashExtensions) unless Hash.new.kind_of?(I18n::HashExtensions)

    if args[:source_file]
      source_translations = YAML.safe_load(open(args[:source_file]))
    else
      begin
        puts "Enter path to original en.yml file:"
        arg = $stdin.gets.strip
        source_translations = File.exist?(arg) && YAML.safe_load(File.read(arg)) rescue nil
      end until source_translations
    end

    if args[:translated_file]
      new_translations = YAML.safe_load(open(args[:translated_file]))
    else
      begin
        puts "Enter path to translated file:"
        arg = $stdin.gets.strip
        new_translations = File.exist?(arg) && YAML.safe_load(File.read(arg)) rescue nil
      end until new_translations
    end

    import = I18nImport.new(source_translations, new_translations)

    item_warning = lambda { |error_items, description|
      begin
        puts "Warning: #{error_items.size} #{description}. What would you like to do?"
        puts " [C] continue anyway"
        puts " [V] view #{description}"
        puts " [D] debug"
        puts " [Q] quit"
        command = $stdin.gets.upcase.strip
        return false if command == 'Q'
        debugger if command == 'D'
        puts error_items.join("\n") if command == 'V'
      end while command != 'C'
      true
    }

    complete_translations = import.compile_complete_translations(item_warning)
    next if complete_translations.nil?

    File.open("config/locales/#{import.language}.yml", "w") { |f|
      f.write({import.language => complete_translations}.ya2yaml(:syck_compatible => true))
    }
  end

  def transifex_languages(languages)
    if languages
      languages.split(/\s*,\s*/)
    else
      %w(ar zh fr ja pt es ru)
    end
  end

  def transifex_download(user, password, languages)
    transifex_url = "http://www.transifex.com/api/2/project/canvas-lms/"
    translation_url = transifex_url + "resource/canvas-lms/translation"
    userpass = "#{user}:#{password}"
    for lang in languages
      puts "Downloading tmp/#{lang}.yml"
      json = `curl --user #{userpass} #{translation_url}/#{lang}/`
      File.open("tmp/#{lang}.yml", "w") do |file|
        file.write JSON.parse(json)['content']
      end
    end
  end

  desc "Download language files from Transifex"
  task :transifex, [:user, :password, :languages] do |t, args|
    languages = transifex_languages(args[:languages])
    transifex_download(args[:user], args[:password], languages)
  end

  desc "Download language files from Transifex and import them"
  task :transifeximport, [:user, :password, :languages, :source_file] do |t, args|
    languages = transifex_languages(args[:languages])
    transifex_download(args[:user], args[:password], languages)

    source_file = args[:source_file] || 'config/locales/generated/en.yml'
    for lang in languages
      translated_file = "tmp/#{lang}.yml"
      puts "Importing #{translated_file}"
      Rake::Task['i18n:import'].reenable
      Rake::Task['i18n:import'].invoke(source_file, translated_file)
    end
  end

end

