# frozen_string_literal: true

require "i18n_tasks"
require "i18n_extraction"
require "shellwords"

namespace :i18n do
  desc "Verifies all translation calls"
  task check: :i18n_environment do
    Hash.include I18nTasks::HashExtensions unless {}.is_a?(I18nTasks::HashExtensions)

    def I18nliner.manual_translations
      I18n.available_locales
      I18n.backend.send(:translations)[:en]
    end

    puts "\nJS/HBS..."
    js_pid = spawn "./gems/canvas_i18nliner/bin/i18nliner export"

    puts "\nRuby..."
    require "i18nliner/commands/check"

    options = { only: ENV["ONLY"] }
    @command = I18nliner::Commands::Check.run(options)
    @command.success? or exit 1
    @translations = @command.translations
    remove_unwanted_translations(@translations)

    Process.wait js_pid
    if $?.exitstatus > 0
      warn "Error extracting JS/HBS translations; confirm that `./gems/canvas_i18nliner/bin/i18nliner export` works"
      exit $?.exitstatus
    end
    js_translations = JSON.parse(File.read("config/locales/generated/en.json"))["en"].flatten_keys
    # merge js in
    js_translations.each do |key, value|
      @translations[key] = value
    end
  end

  desc "Generates a new en.yml file for all translations"
  task generate: :check do
    def deep_sort_hash_by_keys(value)
      sort = lambda do |node|
        case node
        when Hash
          node.keys.sort.index_with do |key|
            sort[node[key]]
          end
        else
          node
        end
      end

      sort[value]
    end

    yaml_dir = "./config/locales/generated"
    FileUtils.mkdir_p(File.join(yaml_dir))
    yaml_file = File.join(yaml_dir, "en.yml")
    special_keys = %w[
      locales
      crowdsourced
      custom
      bigeasy_locale
      fullcalendar_locale
      moment_locale
    ].freeze

    Rails.root.join(yaml_file).open("w") do |file|
      file.write(
        {
          "en" => deep_sort_hash_by_keys(
            remove_dynamic_translations(
              @translations.except(*special_keys)
            )
          )
        }.to_yaml(line_width: -1)
      )
    end
    print "Wrote new #{yaml_file}\n\n"
  end

  # like the top-level :environment, but just the i18n-y stuff we need.
  # also it's faster and doesn't require a db \o/
  task :i18n_environment do
    # This is intentionally requiring things individually rather than just
    # loading the rails+canvas environment, because that environment isn't
    # available during the deploy process. Don't change this out for a call to
    # the `environment` rake task.
    require "bundler"
    Bundler.setup
    # for consistency in how canvas does json ... this way our specs can
    # verify _core_en is up to date
    require "config/initializers/json"

    # set up rails i18n paths ... normally rails env does this for us :-/
    require "action_controller"
    require "active_record"
    require "will_paginate"
    I18n.load_path.unshift(*WillPaginate::I18n.load_path)
    I18n.load_path += Dir[Rails.root.join("gems/plugins/*/config/locales/*.{rb,yml}")]
    I18n.load_path += Dir[Rails.root.join("config/locales/*.{rb,yml}")]
    I18n.load_path += Dir[Rails.root.join("config/locales/locales.yml")]
    I18n.load_path += Dir[Rails.root.join("config/locales/community.csv")]

    I18n::Backend::Simple.include I18nTasks::CsvBackend
    I18n::Backend::Simple.include I18n::Backend::Fallbacks

    require "i18nliner/extractors/translation_hash"
    I18nliner::Extractors::TranslationHash.class_eval do
      def encode_with(coder)
        coder.represent_map nil, self # make translation hashes encode to yaml like a regular hash
      end
    end
  end

  desc "Generates JS bundle i18n files (non-en) and adds them to assets.yml"
  task generate_js: :i18n_environment do
    Hash.include I18nTasks::HashExtensions unless {}.is_a?(I18nTasks::HashExtensions)

    locales = I18n.available_locales
    all_translations = I18n.backend.send(:translations)

    flat_translations = all_translations.flatten_keys

    if locales.empty?
      puts "Nothing to do, there are no non-en translations"
      exit 0
    end

    system "./gems/canvas_i18nliner/bin/i18nliner generate_js"
    if $?.exitstatus > 0
      warn "Error extracting JS translations; confirm that `./gems/canvas_i18nliner/bin/i18nliner generate_js` works"
      exit $?.exitstatus
    end
    file_translations = JSON.parse(File.read("config/locales/generated/js_bundles.json"))

    dump_translations = lambda do |filename, content|
      file = "public/javascripts/translations/#{filename}.js"
      if !File.exist?(file) || File.read(file) != content
        File.open(file, "w") { |f| f.write content }
      end
    end

    translation_for_key = lambda do |locale, key|
      try_locales = [locale.to_s, locale.to_s.split('-')[0], 'en'].uniq

      try_locales.each do |try_locale|
        return [key, flat_translations["#{try_locale}.#{key}"]] if flat_translations.has_key?("#{try_locale}.#{key}")
      end

      # puts "key #{key} not found for locale #{locale} or possible fallbacks #{try_locales.to_sentence}"
      nil
    end

    # Compute common metadata for all locales
    key_counts = {}
    scopes = {}
    unique_key_scopes = {}
    file_translations.map do |scope, keys|
      stripped_scope = scope.split('.')[0]
      keys.each do |key|
        key_counts[key] = (key_counts[key] || 0) + 1
        unique_key_scopes[key] = stripped_scope
        scopes[stripped_scope] = true
        scopes[key.split('.')[0]] = true if key.count('.') > 0
      end
    end

    flat_translations.map do |key, translation|
      I18nTasks::Utils::CORE_KEYS.map do |scope|
        stripped_key = key.split(".", 2)[1] # remove the language prefix

        next unless stripped_key.start_with?(scope.to_s)

        key_counts[stripped_key] = (key_counts[stripped_key] || 0) + 1
        unique_key_scopes[stripped_key] = scope
        scopes[scope.to_s] = true
      end
    end

    # 1. Find all of the keys that are used more than once, they will be stored at the root-level and always loaded.
    # 2. Find the best translation for the given key.
    common_keys, unique_keys = I18nTasks::Utils.partition_hash(key_counts) { |k, v| v > 1 }

    puts "Common Keys: #{common_keys.count}"
    puts "Unique Keys: #{unique_keys.count}"

    eager_common_keys, lazy_common_keys = I18nTasks::Utils.partition_hash(common_keys) { |k, v| k.count('.') == 0 }
    lazy_unique_root_keys, lazy_unique_nested_keys = I18nTasks::Utils.partition_hash(unique_keys) { |k, v| k.count('.') == 0 }

    # 3. All common, non-nested translations will be loaded immediately.
    # 4. All other translations will be loaded when their scope is first accessed.

    eager_root_keys = eager_common_keys
    lazy_nested_keys = lazy_common_keys.merge(lazy_unique_nested_keys)
    lazy_root_keys = lazy_unique_root_keys
    lazy_root_keys_by_scope = lazy_root_keys.each_with_object(Hash.new { |hash, k| hash[k] = [] }) { |(k, v), obj| obj[unique_key_scopes[k]] << k }

    puts "Eager-Loaded Keys: #{eager_root_keys.count}"
    puts "Lazy-Loaded Root Keys: #{lazy_root_keys.count}"
    puts "Lazy-Loaded Nested Keys: #{lazy_nested_keys.count}"

    base_translations_js_start = "import { setRootTranslations, setLazyTranslations } from '@canvas/i18n/mergeI18nTranslations.js'; (function(setRootTranslations, setLazyTranslations) {"
    base_translations_js_end = "})(setRootTranslations, setLazyTranslations)"

    locales.each do |locale|
      puts "Generating JS for #{locale}"

      eager_root_translations = eager_root_keys.filter_map { |k, v| translation_for_key.call(locale, k) }.to_h
      lazy_nested_translations_by_scope = I18nTasks::Utils.flat_keys_to_nested(lazy_nested_keys.filter_map { |k, v| translation_for_key.call(locale, k) }.to_h)
      lazy_root_translations_by_scope = lazy_root_keys_by_scope.map { |scope, keys| [scope, keys.filter_map { |k| translation_for_key.call(locale, k) }.to_h] }.to_h

      common_translations_js = I18nTasks::Utils.eager_translations_js(locale, eager_root_translations)

      translations_js = scopes.map do |scope, _unused|
        lazy_root_translations = lazy_root_translations_by_scope.fetch(scope, {})
        lazy_scoped_translations = lazy_nested_translations_by_scope.fetch(scope.to_sym, {})

        I18nTasks::Utils.lazy_translations_js(locale, scope, lazy_root_translations, lazy_scoped_translations)
      end

      dump_translations.call locale, [base_translations_js_start, common_translations_js, *translations_js, base_translations_js_end].compact.join("\n\n")

      if locale == :en
        puts "Generating Default JS"

        core_translations_js = I18nTasks::Utils::CORE_KEYS.map do |scope|
          lazy_scoped_translations = lazy_nested_translations_by_scope.fetch(scope.to_sym, {})

          I18nTasks::Utils.lazy_translations_js(locale, scope, {}, lazy_scoped_translations)
        end

        dump_translations.call '_core_en', [base_translations_js_start, core_translations_js, base_translations_js_end].compact.join("\n\n")
      end
    end
  end

  desc "Generate the pseudo-translation file lolz"
  task generate_lolz: [:generate, :environment] do
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
    translations = YAML.safe_load(open("config/locales/generated/en.yml"))

    I18n.extend I18nTasks::Lolcalize
    lolz_translations = {}
    lolz_translations["lolz"] = process_lolz.call(translations["en"])
    puts

    File.open("config/locales/lolz.yml", "w") do |f|
      f.write(lolz_translations.to_yaml(line_width: -1))
    end
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

      File.open("config/locales/locales.yml", "w") do |f|
        f.write(locales.to_yaml(line_width: -1))
      end
      print "Added LOLZ to locales\n"
    end
  end

  desc "Exports new/changed English strings to be translated"
  task export: :environment do
    Hash.include I18nTasks::HashExtensions unless {}.is_a?(I18nTasks::HashExtensions)

    begin
      base_filename = "config/locales/generated/en.yml"
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
              if (previous = YAML.safe_load(File.read(base_filename)).flatten_keys rescue nil)
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
            if (previous = YAML.safe_load(File.read(arg)).flatten_keys rescue nil)
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
        break if current_branch.blank? || current_branch !~ /[^a-z0-9_.\-]/
      end
      current_branch = nil if current_branch.blank?

      puts "Extracting current en translations..."
      `git checkout #{current_branch || "master"}` if last_export[:type] == :commit || current_branch != prevgit[:branch]
      Rake::Task["i18n:generate"].invoke

      puts "Exporting #{last_export[:data] ? "new/changed" : "all"} en translations..."
      current_strings = YAML.safe_load(File.read(base_filename)).flatten_keys
      new_strings = if last_export[:data]
                      current_strings.each_with_object({}) do |(k, v), h|
                        h[k] = v unless last_export[:data][k] == v
                      end
                    else
                      current_strings
                    end
      File.open(export_filename, "w") { |f| f.write new_strings.expand_keys.to_yaml(line_width: -1) }

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
      source_translations = YAML.safe_load(File.read(args[:source_file]))
    else
      loop do
        puts "Enter path to original en.yml file:"
        arg = $stdin.gets.strip
        break if (source_translations = File.exist?(arg) && YAML.safe_load(File.read(arg)) rescue nil)
      end
    end

    if args[:translated_file]
      new_translations = YAML.safe_load(File.read(args[:translated_file]))
    else
      loop do
        puts "Enter path to translated file:"
        arg = $stdin.gets.strip
        break if (new_translations = File.exist?(arg) && YAML.safe_load(File.read(arg)) rescue nil)
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

    File.open("config/locales/#{import.language}.yml", "w") do |f|
      f.write({ import.language => complete_translations }.to_yaml(line_width: -1))
    end
  end

  desc "Imports new translations, ignores missing or unexpected keys"
  task :autoimport, [:translated_file, :source_file] => :environment do |_t, args|
    require "open-uri"

    source_translations = if args[:source_file].present?
                            YAML.safe_load(File.read(args[:source_file]))
                          else
                            YAML.safe_load(File.read("config/locales/generated/en.yml"))
                          end
    new_translations = YAML.safe_load(File.read(args[:translated_file]))
    autoimport(source_translations, new_translations)
  end

  def remove_unwanted_translations(translations)
    translations["date"].delete("order")
  end

  def remove_dynamic_translations(translations)
    process = lambda do |node|
      case node
      when Hash
        node.delete_if { |_k, v| process.call(v).nil? }
      when Proc
        nil
      else
        node
      end
    end

    process.call(translations)
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
      errors: errors,
    }.to_json)
  end

  def parsed_languages(languages)
    if languages.present?
      if languages.include?(">")
        languages.split(",").map { |lang| lang.split(">") }.to_h
      else
        languages.split(",")
      end
    else
      %w[ar zh fr ja pt es ru]
    end
  end

  def import_languages(import_type, args)
    require "json"
    languages = parsed_languages(args[:languages])
    source_file = args[:source_file] || "config/locales/generated/en.yml"
    source_translations = YAML.safe_load(File.read(source_file))

    languages.each do |lang|
      if lang.is_a?(Array)
        lang, remote_lang = *lang
      else
        lang, remote_lang = lang, lang.sub("-", "_")
      end

      puts "Downloading #{remote_lang}.yml"
      yml =
        case import_type
        when :transifex
          json = transifex_download(args[:user], args[:password], remote_lang)
          JSON.parse(json)["content"]
        when :s3
          s3_download(args[:s3_bucket], remote_lang)
        end
      File.write("tmp/#{lang}.yml", yml)
      new_translations = { lang => YAML.safe_load(yml)[remote_lang] }

      puts "Importing #{lang}.yml"
      autoimport(source_translations, new_translations)
    end
  end

  def transifex_download(user, password, transifex_lang)
    require "open-uri"

    transifex_url = "http://www.transifex.com/api/2/project/canvas-lms/"
    translation_url = transifex_url + "resource/canvas-lms/translation"
    userpass = "#{user}:#{Shellwords.escape(password)}"
    `curl -L --user #{userpass} #{translation_url}/#{transifex_lang}/`
  end

  def s3_download(bucket_name, s3_lang)
    require "aws-sdk-s3"

    bucket = Aws::S3::Resource.new(
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
      region: ENV["AWS_REGION"]
    ).bucket(bucket_name)
    bucket.object("translations/canvas-lms/#{s3_lang}/#{s3_lang}.yml").get.body.read
  end

  desc "Download language files from Transifex"
  task :transifex, [:user, :password, :languages] do |_t, args| # rubocop:disable Rails/RakeEnvironment
    languages = transifex_languages(args[:languages])
    transifex_download(args[:user], args[:password], languages)
  end

  desc "Download language files from Transifex and import them"
  task :transifeximport, %i[user password languages source_file] => :environment do |_t, args|
    import_languages(:transifex, args)
  end

  desc "Download language files from s3 and import them"
  task :s3import, %i[s3_bucket languages source_file] => :environment do |_t, args|
    import_languages(:s3, args)
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

      data = YAML.safe_load(File.read(filename))

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
