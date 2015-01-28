module I18nTasks
  class I18nImport
    attr_reader :source_translations, :new_translations, :language

    class MisMatch < Struct.new(:key, :expected, :actual)
      def to_s
        "#{key}: expected #{expected.inspect}, got #{actual.inspect}"
      end
    end

    def initialize(source_translations, new_translations)
      @source_translations = init_source(source_translations)
      @language = init_language(new_translations)
      Utf8Cleaner.recursively_strip_invalid_utf8!(new_translations, true)
      @new_translations = new_translations[language].flatten_keys
    end

    def compare_translations(&warning)
      [
          [missing_keys, "missing translations"],
          [unexpected_keys, "unexpected translations"]
      ].each do |keys, description|
        if keys.present?
          case (action = yield(keys.sort, description))
            when :abort then
              throw(:abort)
            when :discard then
              :ok # <-discard and accept are the same in this case
            when :accept then
              :ok # <-/
            else
              raise "don't know how to handle #{action}"
          end
        end
      end
    end

    def compare_mismatches(&warning)
      # Important to populate @placeholder_mismatches and @markdown_mismatches first
      find_mismatches

      [
          [@placeholder_mismatches, "placeholder mismatches"],
          [@markdown_mismatches, "markdown/wrapper mismatches"],
      ].each do |mismatches, description|
        if mismatches.size > 0
          case (action = yield(mismatches, description))
            when :abort then
              throw(:abort)
            when :discard then
              @new_translations.delete_if do |k, v|
                mismatches.any? { |m| m.key == k }
              end
            when :accept then
              :ok
            else
              raise "don't know how to handle #{action}"
          end
        end
      end
    end

    def compile_complete_translations(&warning)
      catch(:abort) do
        compare_translations(&warning)
        compare_mismatches(&warning)
        complete_translations
      end
    end

    def complete_translations
      I18n.available_locales
      base = (I18n.backend.direct_lookup(language) || {})
      translations = base.flatten_keys.merge(new_translations)
      fix_plural_keys(translations)
      translations.expand_keys
    end

    def fix_plural_keys(flat_hash)
      other_keys = flat_hash.keys.grep(/\.other$/)
      other_keys.each do |other_key|
        one_key = other_key.gsub(/other$/, 'one')
        if flat_hash[one_key].nil?
          flat_hash[one_key] = flat_hash[other_key]
        end
      end
    end

    def missing_keys
      source_translations.keys - new_translations.keys
    end

    def unexpected_keys
      new_translations.keys - source_translations.keys
    end

    def find_mismatches
      @placeholder_mismatches = []
      @markdown_mismatches = []
      new_translations.keys.each do |key|
        next unless source_translations[key]
        p1 = placeholders(source_translations[key].to_s)
        p2 = placeholders(new_translations[key].to_s)
        @placeholder_mismatches << MisMatch.new(key, p1, p2) if p1 != p2

        m1 = markdown_and_wrappers(source_translations[key].to_s)
        m2 = markdown_and_wrappers(new_translations[key].to_s)
        @markdown_mismatches << MisMatch.new(key, m1, m2) if m1 != m2
      end
    end

    LIST_ITEM_PATTERN = /^ {0,3}(\d+\.|\*|\+|\-)\s/

    def markdown_and_wrappers(str)
      # Since underscores can be wrappers, and underscores can also be inside
      # placeholders (as placeholder names) we need to be unambiguous about
      # underscores in placeholders:
      dashed_str = str.gsub(/%\{([^\}]+)\}/) { |x| x.gsub("_", "-") }
      # some stuff this doesn't check (though we don't use):
      #   blockquotes, e.g. "> some text"
      #   reference links, e.g. "[an example][id]"
      #   indented code
      matches = scan_and_report(dashed_str, /\\[\\`\*_\{\}\[\]\(\)#\+\-\.!]/) # escaped special char
        .concat(wrappers(dashed_str))
        .concat(scan_and_report(dashed_str, /(!?\[)[^\]]+\]\(([^\)"']+).*?\)/).map { |m| "link:#{m.last}" }) # links

      # only do fancy markdown checks on multi-line strings
      if dashed_str =~ /\n/
        matches.concat(scan_and_report(dashed_str, /^(\#{1,6})\s+[^#]*#*$/).map { |m| "h#{m.first.size}" }) # headings
               .concat(scan_and_report(dashed_str, /^[^=\-\n]+\n^(=+|-+)$/).map { |m| m.first[0]=='=' ? 'h1' : 'h2' }) # moar headings
               .concat(scan_and_report(dashed_str, /^((\s*\*\s*){3,}|(\s*-\s*){3,}|(\s*_\s*){3,})$/).map { "hr" })
               .concat(scan_and_report(dashed_str, LIST_ITEM_PATTERN).map { |m| m.first =~ /\d/ ? "1." : "*" })
      end
      matches.uniq.sort
    end

    # return array of balanced wrappers in the source string, e.g.
    # "* **ohai** * user, *welcome*!" => ["**-wrap", "*-wrap"]
    def wrappers(str)
      pattern = /\*+|\++|`+/
      str = str.gsub(LIST_ITEM_PATTERN, '') # ignore markdown lists
      parts = scan_and_report(str, pattern)
      stack = []
      result = []
      parts.each do |part|
        next if part !~ pattern
        if stack.last == part
          result << "#{part}-wrap"
          stack.pop
        else
          stack << part
        end
      end
      result.uniq
    end

    def placeholders(str)
      str.scan(/%h?\{[^\}]+\}/).sort
    rescue ArgumentError => e
      puts "Unable to scan string: #{str.inspect}"
      raise e
    end

    def scan_and_report(str, re)
      str.scan(re)
    rescue ArgumentError => e
      puts "Unable to scan string: #{str.inspect}"
      raise e
    end

    private
    def init_source(translations)
      raise "Source does not have any English strings" unless translations.keys.include?('en')
      translations['en'].flatten_keys
    end

    def init_language(translations)
      raise "Translation file contains multiple languages" if translations.size > 1
      language = translations.keys.first
      raise "Translation file appears to have only English strings" if language == 'en'
      language
    end
  end
end
