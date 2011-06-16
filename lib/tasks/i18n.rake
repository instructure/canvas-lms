namespace :i18n do
  desc "Verifies all translation calls"
  task :check => :environment do
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
          filename.gsub(/.*app\/views\/|html\.erb/, '').gsub(/\/_?/, '.')
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

    t = Time.now
    @extractor = I18nExtractor.new
    @errors = []
    files.each do |file|
      begin
        source = File.read(file)
        source = Erubis::Eruby.new(source).src if file =~ /\.erb\z/

        sexps = RubyParser.new.parse(source)
        @extractor.scope = infer_scope(file)
        @extractor.process(sexps)
        print green "."
      rescue SyntaxError, StandardError
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
    puts send((failure ? :red : :green), "#{files.size} files, #{@extractor.total_unique} strings, #{@errors.size} failures")
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
end