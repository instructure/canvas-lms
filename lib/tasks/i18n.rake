namespace :i18n do
  module HashExtensions
    def flatten(result={}, prefix='')
      each_pair do |k, v|
        if v.is_a?(Hash)
          v.flatten(result, "#{prefix}#{k}.")
        else
          result["#{prefix}#{k}"] = v
        end
      end
      result
    end

    def expand(result = {})
      each_pair do |k, v|
        parts = k.split('.')
        last = parts.pop
        parts.inject(result){ |h, k2| h[k2] ||= {}}[last] = v
      end
      result
    end
  end

  desc "Verifies all translation calls"
  task :check => :environment do
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

    def infer_scope(filename)
      case filename
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

    files = Dir.glob('./**/*rb').
      reject{ |file| file =~ /\A\.\/(vendor\/plugins\/rails_xss|db|spec)\// }
    files &= only if only
    file_count = files.size

    t = Time.now

    I18n.available_locales
    stringifier = proc { |hash, (key, value)|
      hash[key.to_s] = value.is_a?(Hash) ?
        value.inject({}, &stringifier) :
        value
      hash
    }
    default_translations = I18n.backend.send(:translations)[:en].inject({}, &stringifier)
    @extractor = I18nExtractor.new(:translations => default_translations)
    @errors = []
    files.each do |file|
      begin
        source = File.read(file)
        source = Erubis::Eruby.new(source).src if file =~ /\.erb\z/

        sexps = RubyParser.new.parse(source)
        @extractor.scope = infer_scope(file)
        @extractor.in_html_view = (file =~ /\.(html|facebook)\.erb\z/)
        @extractor.process(sexps)
        print green "."
      rescue SyntaxError, StandardError
        @errors << "#{$!}\n#{file}"
        print red "F"
      end
    end


    files = (Dir.glob('./public/javascripts/*.js') + Dir.glob('./app/views/**/*.erb')).
      reject{ |file| file =~ /\A\.\/public\/javascripts\/(i18n.js|translations\/)/ }
    files &= only if only
    @js_extractor = I18nJsExtractor.new(:translations => @extractor.translations)

    files.each do |file|
      begin
        if @js_extractor.process(File.read(file), :erb => (file =~ /\.erb\z/), :filename => file)
          file_count += 1
          print green "."
        end
      rescue
        @errors << "#{$!}\n#{file}"
        print red "F"
      end
    end

    print "\n\n"
    failure = @errors.size > 0

    @errors.each_index do |i|
      puts "#{i+1})"
      puts red @errors[i]
      print "\n"
    end

    print "Finished in #{Time.now - t} seconds\n\n"
    puts send((failure ? :red : :green), "#{file_count} files, #{@extractor.total_unique + @js_extractor.total_unique} strings, #{@errors.size} failures")
    raise "check command encountered errors" if failure
  end

  desc "Generates a new en.yml file for all translations"
  task :generate => :check do
    yaml_dir = './config/locales/generated'
    FileUtils.mkdir_p(File.join(yaml_dir))
    yaml_file = File.join(yaml_dir, "en.yml")
    File.open(File.join(RAILS_ROOT, yaml_file), "w") do |file|
      file.write({'en' => @extractor.translations}.ya2yaml(:syck_compatible => true))
    end
    print "Wrote new #{yaml_file}\n\n"
  end

  desc "Generates JS bundle i18n files (non-en) and adds them to assets.yml"
  task :generate_js => :environment do
    Hash.send :include, HashExtensions
    I18nExtractor

    files = Dir.glob('public/javascripts/*.js').
      reject{ |file| file =~ /\Apublic\/javascripts\/(i18n.js|translations\/)/ }

    bundles = Jammit.configuration[:javascripts]
    bundle_translations = bundles.keys.inject({}){ |hash, key| hash[key] = {}; hash }

    locales = I18n.available_locales - [:en]
    all_translations = I18n.backend.send(:translations).flatten
    if locales.empty?
      puts "Nothing to do, there are no non-en translations"
      exit 0
    end

    files.each do |file|
      extractor = I18nJsExtractor.new
      begin
        extractor.process(File.read(file), :filename => file) or next
      rescue
        raise "Error reading #{file}: #{$!}\nYou should probably run `rake i18n:check' first"
      end
      translations = extractor.translations.flatten.keys
      next if translations.empty?

      bundles.select { |bundle, files|
        files.include?(file)
      }.each { |bundle, files|
        locales.each do |locale|
          translations.each do |key|
            bundle_translations[bundle]["#{locale}.#{key}"] = all_translations["#{locale}.#{key}"] if all_translations["#{locale}.#{key}"]
          end
        end
      }.empty? and $stderr.puts "WARNING: #{file} has an I18n scope but is not used in any bundles"
    end

    assets_file = 'config/assets.yml'
    assets_content = File.read(assets_file)
    orig_assets_content = assets_content.dup

    bundle_it = proc { |bundle, *args|
      translations = args.shift
      translation_name = args.shift || bundle
      bundle_file = "public/javascripts/translations/#{translation_name}.js"
      content = <<-TRANSLATIONS
// this file was auto-generated by rake i18n:generate_js.
// you probably shouldn't edit it directly
$.extend(true, (I18n = I18n || {}), {translations: #{translations.to_json}});
      TRANSLATIONS
      if !File.exist?(bundle_file) || File.read(bundle_file) != content
        File.open(bundle_file, "w"){ |f| f.write content }
      end
      unless bundles[bundle].include?(bundle_file)
        assets_content.sub!(/(^  #{bundle}:\n(    - public\/[^\n]+\n)*)/, "\\1    - #{bundle_file}\n") or raise "couldn't add #{bundle_file} to assets.yml"
      end
    }

    bundle_translations.each do |bundle, translations|
      bundle_it.call(bundle, translations.expand) unless translations.empty?
    end

    # in addition to getting the non-en stuff into each bundle, we need to get the core
    # formats and stuff for all languages (en included) into the common bundle
    all_translations = I18n.backend.send(:translations)
    core_translations = I18n.available_locales.inject({}) { |h1, locale|
      h1[locale] = [:date, :time, :number, :datetime].inject({}) { |h2, key|
        h2[key] = all_translations[locale][key] if all_translations[locale][key]
        h2
      }
      h1
    }
    bundle_it.call(:common, core_translations, '_core')

    if orig_assets_content != assets_content
      File.open(assets_file, "w"){ |f| f.write assets_content }
    end
  end

  desc "Exports new/changed English strings to be translated"
  task :export => :environment do
    Hash.send :include, HashExtensions

    begin
      base_filename = "config/locales/generated/en.yml"
      export_filename = 'en.yml'

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
        elsif arg =~ /\A[a-z0-9]{7,}\z/
          puts "Fetching previous export..."
          ret = `git show --name-only --oneline #{arg}`
          if $?.exitstatus == 0
            if ret.include?(base_filename)
              `git checkout #{arg}`
              if previous = YAML.load(File.read(arg)).flatten rescue nil
                last_export = {:type => :file, :data => previous}
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
            if previous = YAML.load(File.read(arg)).flatten rescue nil
              last_export = {:type => :file, :data => previous}
            else
              $stderr.puts "Unable to load yml file"
            end
          else
            $stderr.puts "Invalid path"
          end
        end
      end until last_export

      puts "Extracting current en translations..."
      `git checkout master; git pull --rebase`
      Rake::Task["i18n:generate"].invoke

      puts "Exporting #{last_export[:data] ? "new/changed" : "all"} en translations..."
      current_strings = YAML.load(File.read(base_filename)).flatten
      new_strings = last_export[:data] ?
        current_strings.inject({}){ |h, (k, v)| h[k] = v unless last_export[:data][k] == v } :
        current_strings
      File.open(export_filename, "w"){ |f| f.write new_strings.expand }

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
          `git push -u origin master`
          puts "Exported en.yml, committed/pushed current translations (#{`git log --oneline|head -n 1`.sub(/ .*/m, '')})"
        end
      else
        puts "Exported en.yml, dumped current translations (not committed)"
      end
    ensure
      `git checkout #{prevgit[:branch]}` if prevgit[:branch]
      `git stash pop` if prevgit[:stashed]
    end
  end

  desc "Validates and imports new translations"
  task :import => :environment do
    Hash.send :include, HashExtensions

    def placeholders(str)
      str.scan(/%\{[^\}]+\}/).sort
    end

    def markdown_and_wrappers(str)
      # some stuff this doesn't check (though we don't use):
      #   blockquotes, e.g. "> some text"
      #   reference links, e.g. "[an example][id]"
      #   indented code
      (
        str.scan(/\\[\\`\*_\{\}\[\]\(\)#\+\-\.!]/) +
        str.scan(/(\*+|_+|`+)[^\s].*?[^\s]?\1/).map{|m|"#{m}-wrap"} +
        str.scan(/(!?\[)[^\]]+\]\(([^\)"']+).*?\)/).map{|m|"link:#{m.last}"} +
        str.scan(/^((\s*\*\s*){3,}|(\s*-\s*){3,}|(\s*_\s*){3,})$/).map{"hr"} +
        str.scan(/^[^=\-\n]+\n^(=+|-+)$/).map{|m|m.first[0]=='=' ? 'h1' : 'h2'} +
        str.scan(/^(\#{1,6})\s+[^#]*#*$/).map{|m|"h#{m.first.size}"} +
        str.scan(/^ {0,3}(\d+\.|\*|\+|\-)\s/).map{|m|m.first =~ /\d/ ? "1." : "*"}
      ).sort
    end

    begin
      puts "Enter path to original en.yml file:"
      arg = $stdin.gets.strip
      source_translations = File.exist?(arg) && YAML.load(File.read(arg)) rescue nil
    end until source_translations
    raise "Source does not have any English strings" unless source_translations.keys.include?('en')
    source_translations = source_translations['en'].flatten

    begin
      puts "Enter path to translated file:"
      arg = $stdin.gets.strip
      new_translations = File.exist?(arg) && YAML.load(File.read(arg)) rescue nil
    end until new_translations
    raise "Translation file contains multiple languages" if new_translations.size > 1
    language = new_translations.keys.first
    raise "Translation file appears to have only English strings" if language == 'en'
    new_translations = new_translations[language].flatten

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

    missing_keys = source_translations.keys - new_translations.keys
    next unless item_warning.call(missing_keys.sort, "missing translations") if missing_keys.present?

    unexpected_keys = new_translations.keys - source_translations.keys
    next unless item_warning.call(unexpected_keys.sort, "unexpected translations") if unexpected_keys.present?

    placeholder_mismatches = {}
    markdown_mismatches = {}
    new_translations.keys.each do |key|
      p1 = placeholders(source_translations[key].to_s)
      p2 = placeholders(new_translations[key].to_s)
      placeholder_mismatches[key] = [p1, p2] if p1 != p2

      m1 = markdown_and_wrappers(source_translations[key].to_s)
      m2 = markdown_and_wrappers(new_translations[key].to_s)
      markdown_mismatches[key] = [m1, m2] if m1 != m2
    end

    if placeholder_mismatches.size > 0
      next unless item_warning.call(placeholder_mismatches.map{|k,(p1,p2)| "#{k}: expected #{p1.inspect}, got #{p2.inspect}"}.sort, "placeholder mismatches")
    end

    if markdown_mismatches.size > 0
      next unless item_warning.call(markdown_mismatches.map{|k,(p1,p2)| "#{k}: expected #{p1.inspect}, got #{p2.inspect}"}.sort, "markdown/wrapper mismatches")
    end

    I18n.available_locales

    new_translations = (I18n.backend.send(:translations)[language.to_sym] || {}).flatten.merge(new_translations)
    File.open("config/locales/#{language}.yml", "w") { |f|
      f.write({language => new_translations.expand}.ya2yaml(:syck_compatible => true))
    }
  end
end