namespace :i18n do
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
    @extractor = I18nExtractor.new
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
    class Hash
      # for sorted goodness
      def to_yaml( opts = {} )
        YAML::quick_emit( object_id, opts ) do |out|
          out.map( taguri, to_yaml_style ) do |map|
            sort.each do |k, v|
              map.add( k, v )
            end
          end
        end
      end
    end
    yaml_file = File.join(yaml_dir, "en.yml")
    File.open(File.join(RAILS_ROOT, yaml_file), "w") do |file|
      file.write({'en' => @extractor.translations}.to_yaml)
    end
    print "Wrote new #{yaml_file}\n\n"
  end

  desc "Generates JS bundle i18n files (non-en) and adds them to assets.yml"
  task :generate_js => :environment do
    I18nExtractor

    class Hash
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
end