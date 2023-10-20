# frozen_string_literal: true

require "i18n_tasks"
require "i18n_extraction"
require "shellwords"

# There are five high-level operations provided by these tasks:
#
#    check: validate the translate calls across the Ruby and JS codebases
#  extract: extract all translatable strings into a single .yml file
# generate: generate runtime files that make use of the translations
#   export: compile all strings that need translation into a format that can
#           be consumed by the translators
#   import: fetch new translations from the translators and persist them to disk
#
namespace :i18n do
  # All translations that were extracted from source code - Ruby, JavaScript,
  # TypeScript, and Handlebars.
  #
  # This file is hierarchical in structure. Keys may be defined by the user and
  # are otherwise inferred. The values are the English strings that are
  # hard-coded in the source code.
  #
  # This is the product of running I18nliner on the Ruby side and
  # @instructure/i18nliner on the frontend.
  source_translations_file = Rails.root.join("config/locales/generated/en.yml").to_s

  js_i18nliner_path = Rails.root.join("node_modules/@instructure/i18nliner-canvas/bin/i18nliner").to_s

  # Translations extracted from the frontend source code.
  #
  # This file has a hierarchical structure, unlike the "index" one. It looks
  # similar to what the Ruby I18nliner exports.
  js_translations_file = Rails.root.join("config/locales/generated/en-js.json").to_s

  # Input to the routine that generates JS modules for every locale, that are
  # then loaded at runtime by the frontend.
  #
  # See @instructure/i18nliner-canvas for the structure of this file.
  js_index_file = Rails.root.join("config/locales/generated/en-js-index.json").to_s

  # Directory to contain the auto-generated translation files for the frontend.
  js_translation_files_dir = Rails.public_path.join("javascripts/translations").to_s

  # like the top-level :environment, but just the i18n-y stuff we need.
  # also it's faster and doesn't require a db \o/
  #
  # This is intentionally requiring things individually rather than just loading
  # the rails+canvas environment, because that environment isn't available
  # during the deploy process. Don't change this out for a call to the
  # `environment` rake task.
  task :i18n_environment do
    I18nTasks::Environment.apply
  end

  desc "Validate translation calls everywhere"
  task check: [] do
    Parallel.each(["i18n:check_js", "i18n:check_rb"], in_processes: 2) do |task|
      Rake::Task[task].invoke
    end
  end

  desc "Validate translation calls in Ruby source code"
  task check_rb: :i18n_environment do
    Hash.include I18nTasks::HashExtensions unless {}.is_a?(I18nTasks::HashExtensions)

    def I18nliner.manual_translations
      I18n.available_locales
      I18n.backend.send(:translations)[:en]
    end

    puts "Ruby..."

    require "i18nliner/commands/check"

    @check = I18nliner::Commands::Check.run({ only: ENV["ONLY"] })

    exit 1 unless @check.success?
  end

  desc "Validate translation calls in JavaScript/HBS source code"
  task check_js: [] do
    puts "JS/HBS..."
    exit 1 unless system(js_i18nliner_path, "check")
  end

  # there is no explicit "extract_rb" step because we don't store the EXCLUSIVE
  # Ruby-sourced translations on disk, instead we use what I18nliner has
  # in-memory when we run the "check" task and combine that directly with the
  # translations extracted from JS, which are stored on disk
  desc "Extract translations from source code into a YAML file"
  task extract: [:check_rb] do
    Rake::Task["i18n:extract_js"].invoke unless ENV["I18N_JS_PRECOMPILED"] == "1"

    combined_translations = I18nTasks::Extract.new(
      rb_translations: @check.translations,
      js_translations: JSON.parse(File.read(js_translations_file))["en"].flatten_keys
    ).apply

    FileUtils.mkdir_p(File.dirname(source_translations_file))

    File.write(source_translations_file, {
      "en" => combined_translations
    }.to_yaml(line_width: -1))

    print "Wrote new #{source_translations_file}\n\n"
  end

  task extract_js: [] do
    exit 1 unless system(
      js_i18nliner_path,
      "export",
      "--translationsFile",
      js_translations_file,
      "--indexFile",
      js_index_file
    )
  end

  # TODO: remove once we're sure all places that called i18n:generate are now
  # calling i18n:extract (e.g. caturday)
  desc "Alias for i18n:extract"
  task generate: [:extract]

  desc "generate JavaScript translation files"
  task generate_js: [:i18n_environment] do
    Rake::Task["i18n:extract_js"].invoke unless ENV["I18N_JS_PRECOMPILED"] == "1"

    generator = I18nTasks::GenerateJs.new(
      index: JSON.parse(File.read(js_index_file))
    )

    FileUtils.mkdir_p(js_translation_files_dir)

    I18n.available_locales.map(&:to_s).sort.each do |locale|
      puts "Generating JS for #{locale}"

      File.write(
        "#{js_translation_files_dir}/#{locale}.json",
        generator.translations(locale).to_json
      )
    end
  end

  desc "Generate the pseudo-translation file lolz"
  task generate_lolz: [:extract, :environment] do
    strings_processed = 0
    process_lolz = proc do |val|
      case val
      when Hash
        processed = strings_processed

        hash = {}
        val.each_key { |key| hash[key] = process_lolz.call(val[key]) }

        print "." if strings_processed > processed
        hash
      when Array
        val.each.map { |v| process_lolz.call(v) }
      when String
        strings_processed += 1
        I18n.let_there_be_lols(val)
      else
        val
      end
    end

    t = Time.now
    translations = YAML.safe_load(File.open(source_translations_file))

    I18n.extend I18nTasks::Lolcalize
    lolz_translations = {}
    lolz_translations["lolz"] = process_lolz.call(translations["en"])
    puts

    File.write("config/locales/lolz.yml", lolz_translations.to_yaml(line_width: -1))
    print "\nFinished generating LOLZ from #{strings_processed} strings in #{Time.now - t} seconds\n"

    # add lolz to the locales.yml file
    locales = YAML.safe_load(open("config/locales/locales.yml"))
    if locales["lolz"].nil?
      locales["lolz"] = {
        "locales" => {
          "lolz" => "LOLZ (crowd-sourced)"
        },
        "crowdsourced" => true
      }

      File.write("config/locales/locales.yml", locales.to_yaml(line_width: -1))
      print "Added LOLZ to locales\n"
    end
  end

  desc "Exports new/changed English strings to be translated"
  task export: :environment do
    Hash.include I18nTasks::HashExtensions unless {}.is_a?(I18nTasks::HashExtensions)

    begin
      base_filename = source_translations_file
      export_filename = "en.yml"
      current_branch = nil

      prevgit = {}
      prevgit[:branch] = `git branch | grep '\*'`.sub(/^\* /, "").strip
      prevgit.delete(:branch) if prevgit[:branch].blank? || prevgit[:branch] == "master"
      unless `git status -s | grep -v '^\?\?' | wc -l`.strip == "0"
        `git stash`
        prevgit[:stashed] = true
      end

      last_export = nil
      loop do
        puts "Enter path or hash of previous export base (omit to export all):"
        arg = $stdin.gets.strip
        if arg.blank?
          last_export = { type: :none }
        elsif /\A[a-f0-9]{7,}\z/.match?(arg)
          puts "Fetching previous export..."
          ret = `git show --name-only --oneline #{arg}`
          if $?.exitstatus == 0
            if ret.include?(base_filename)
              `git checkout #{arg}`
              if (previous = YAML.safe_load_file(base_filename).flatten_keys rescue nil)
                last_export = { type: :commit, data: previous }
              else
                warn "Unable to load en.yml file"
              end
            else
              warn "Commit contains no en.yml file"
            end
          else
            warn "Invalid commit hash"
          end
          `git status -s | grep -v '^\?\?' | wc -l`
        else
          puts "Loading previous export..."
          if File.exist?(arg)
            if (previous = YAML.safe_load_file(arg).flatten_keys rescue nil)
              last_export = { type: :file, data: previous }
            else
              warn "Unable to load yml file"
            end
          else
            warn "Invalid path"
          end
        end
        break if last_export
      end

      loop do
        puts "Enter local branch containing current en translations (default master):"
        current_branch = $stdin.gets.strip
        break if current_branch.blank? || current_branch !~ /[^a-z0-9_.-]/
      end
      current_branch = nil if current_branch.blank?

      puts "Extracting current en translations..."
      `git checkout #{current_branch || "master"}` if last_export[:type] == :commit || current_branch != prevgit[:branch]
      Rake::Task["i18n:extract"].invoke

      puts "Exporting #{last_export[:data] ? "new/changed" : "all"} en translations..."
      current_strings = YAML.safe_load_file(base_filename).flatten_keys
      new_strings = if last_export[:data]
                      current_strings.each_with_object({}) do |(k, v), h|
                        h[k] = v unless last_export[:data][k] == v
                      end
                    else
                      current_strings
                    end
      File.write(export_filename, new_strings.expand_keys.to_yaml(line_width: -1))

      push = "n"
      y_n = %w[y n]
      loop do
        puts "Commit and push current translations? (Y/N)"
        push = $stdin.gets.strip.downcase[0, 1]
        break if y_n.include?(push)
      end
      if push == "y"
        `git add #{base_filename}`
        if `git status -s | grep -v '^\?\?' | wc -l`.strip == "0"
          puts "Exported en.yml, current translations unmodified (check git log for last change)"
        else
          `git commit -a -m"generated en.yml for translation"`
          local = current_branch || "master"
          `remote=$(git config branch."#{local}".remote); \
           remote_ref=$(git config branch."#{local}".merge); \
           remote_name=${remote_ref##refs/heads/}; \
           git push $remote HEAD:refs/for/$remote_name`
          puts "Exported en.yml, committed/pushed current translations (#{`git log --oneline|head -n 1`.sub(/ .*/m, "")})"
        end
      else
        puts "Exported en.yml, dumped current translations (not committed)"
      end
    ensure
      `git checkout #{prevgit[:branch] || "master"}` if prevgit[:branch] != current_branch
      `git stash pop` if prevgit[:stashed]
    end
  end

  desc "Validates and imports new translations"
  task :import, [:source_file, :translated_file] => :environment do |_t, args|
    require "open-uri"
    Hash.include I18nTasks::HashExtensions unless {}.is_a?(I18nTasks::HashExtensions)

    if args[:source_file]
      source_translations = YAML.safe_load_file(args[:source_file])
    else
      loop do
        puts "Enter path to original en.yml file:"
        arg = $stdin.gets.strip
        break if (source_translations = File.exist?(arg) && YAML.safe_load_file(arg) rescue nil)
      end
    end

    if args[:translated_file]
      new_translations = YAML.safe_load_file(args[:translated_file])
    else
      loop do
        puts "Enter path to translated file:"
        arg = $stdin.gets.strip
        break if (new_translations = File.exist?(arg) && YAML.safe_load_file(arg) rescue nil)
      end
    end

    import = I18nTasks::I18nImport.new(source_translations, new_translations)

    complete_translations = import.compile_complete_translations do |error_items, description|
      loop do
        puts "Warning: #{error_items.size} #{description}. What would you like to do?"
        puts " [C] continue anyway"
        puts " [V] view #{description}"
        puts " [D] debug"
        puts " [Q] quit"
        case $stdin.gets.upcase.strip
        when "C" then break :accept
        when "Q" then break :abort
        when "D" then debugger # rubocop:disable Lint/Debugger
        when "V" then puts error_items.join("\n")
        end
      end
    end

    next if complete_translations.nil?

    File.write("config/locales/#{import.language}.yml", { import.language => complete_translations }.to_yaml(line_width: -1))
  end

  desc "Imports new translations, ignores missing or unexpected keys"
  task :autoimport, [:translated_file, :source_file] => :environment do |_t, args|
    require "open-uri"

    source_translations = if args[:source_file].present?
                            YAML.safe_load_file(args[:source_file])
                          else
                            YAML.safe_load_file(source_translations_file)
                          end
    new_translations = YAML.safe_load_file(args[:translated_file])
    autoimport(source_translations, new_translations)
  end

  def autoimport(source_translations, new_translations)
    Hash.include I18nTasks::HashExtensions unless {}.is_a?(I18nTasks::HashExtensions)

    raise "Need source translations" unless source_translations
    raise "Need translated_file" unless new_translations

    errors = []

    import = I18nTasks::I18nImport.new(source_translations, new_translations)

    complete_translations = import.compile_complete_translations do |error_items, description|
      if description.include?("mismatches")
        # Output malformed stuff and don't import them
        errors.concat error_items
        :discard
      else
        # Import everything else
        :accept
      end
    end
    raise "got no translations" if complete_translations.nil?

    File.open("config/locales/#{import.language}.yml", "w") do |f|
      f.write <<~YAML
        # This YAML file is auto-generated from a Transifex import.
        # Do not edit it by hand, your changes will be overwritten.
      YAML
      f.write({ import.language => complete_translations }.to_yaml(line_width: -1))
    end

    puts({
      language: import.language,
      errors:,
    }.to_json)
  end

  desc "Lock a key so translators cannot change it"
  task :lock do
    require "optparse"
    require "yaml"

    options = { locales: [] }
    opts = OptionParser.new
    opts.banner = "Usage: rake i18n:lock -- [options] [keys]"
    opts.separator ""
    opts.separator "Options:"
    opts.on("-lCODE", "--locale=CODE", "Specific locale only") do |v|
      options[:locales] << v
    end
    opts.on("-h", "--help", "Show this message") do
      puts opts
      exit
    end
    args = opts.order!(ARGV) { nil }
    opts.parse!(args)
    options[:keys] = ARGV

    if options[:keys].empty?
      puts opts
      exit
    end

    Dir.chdir(Rails.root.join("config/locales"))
    locales_data = YAML.safe_load(open("locales.yml"))

    Dir.each_child(".") do |filename|
      next if ["locales.yml", "en.yml"].include?(filename)
      next if File.directory?(filename)

      locale = File.basename(filename, ".yml")
      next if options[:locales].present? && !options[:locales].include?(locale)

      data = YAML.safe_load_file(filename)

      options[:keys].each do |path|
        search = data[locale]
        slice_next = {}
        slice = slice_next
        last_key = nil
        path.to_s.split(".").each do |key|
          slice_next = slice_next[last_key] if last_key
          last_key = key
          search = search[key]
          if search.nil?
            puts "Invalid key #{path} for #{locale}"
            exit(1)
          end
          slice_next[key] = {}
        end
        slice_next[last_key] = search
        locales_data[locale].deep_merge!(slice)
      end
    end

    File.open("locales.yml", "w") { |f| YAML.dump(locales_data, f) }
    exit
  end
end
