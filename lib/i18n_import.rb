Hash.send(:include, I18n::HashExtensions) unless Hash.new.kind_of?(I18n::HashExtensions)

class I18nImport
  attr_reader :source_translations, :new_translations, :language

  def initialize(source_translations, new_translations)
    @source_translations = init_source(source_translations)
    @language = init_language(new_translations)
    TextHelper.recursively_strip_invalid_utf8!(new_translations, true)
    @new_translations = new_translations[language].flatten_keys
  end

  def compile_complete_translations(warning)
    return nil unless warning.call(missing_keys.sort, "missing translations") if missing_keys.present?
    return nil unless warning.call(unexpected_keys.sort, "unexpected translations") if unexpected_keys.present?

    find_mismatches

    if @placeholder_mismatches.size > 0
      return nil unless warning.call(mismatch_diff(@placeholder_mismatches), "placeholder mismatches")
    end

    if @markdown_mismatches.size > 0
      return nil unless warning.call(mismatch_diff(@markdown_mismatches), "markdown/wrapper mismatches")
    end

    complete_translations
  end

  def complete_translations
    I18n.available_locales
    base = (I18n.backend.send(:translations)[language.to_sym] || {})
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
    @placeholder_mismatches = {}
    @markdown_mismatches = {}
    new_translations.keys.each do |key|
      p1 = placeholders(source_translations[key].to_s)
      p2 = placeholders(new_translations[key].to_s)
      @placeholder_mismatches[key] = [p1, p2] if p1 != p2

      m1 = markdown_and_wrappers(source_translations[key].to_s)
      m2 = markdown_and_wrappers(new_translations[key].to_s)
      @markdown_mismatches[key] = [m1, m2] if m1 != m2
    end
  end

  def markdown_and_wrappers(str)
    # some stuff this doesn't check (though we don't use):
    #   blockquotes, e.g. "> some text"
    #   reference links, e.g. "[an example][id]"
    #   indented code
    (
      scan_and_report(str, /\\[\\`\*_\{\}\[\]\(\)#\+\-\.!]/) +
      scan_and_report(str, /(\*+|_+|`+)[^\s].*?[^\s]?\1/).map{|m|"#{m}-wrap"} +
      scan_and_report(str, /(!?\[)[^\]]+\]\(([^\)"']+).*?\)/).map{|m|"link:#{m.last}"} +
      scan_and_report(str, /^((\s*\*\s*){3,}|(\s*-\s*){3,}|(\s*_\s*){3,})$/).map{"hr"} +
      scan_and_report(str, /^[^=\-\n]+\n^(=+|-+)$/).map{|m|m.first[0]=='=' ? 'h1' : 'h2'} +
      scan_and_report(str, /^(\#{1,6})\s+[^#]*#*$/).map{|m|"h#{m.first.size}"} +
      scan_and_report(str, /^ {0,3}(\d+\.|\*|\+|\-)\s/).map{|m|m.first =~ /\d/ ? "1." : "*"}
    ).sort
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

  def mismatch_diff(mismatches)
    mismatches.map{|k,(p1,p2)| "#{k}: expected #{p1.inspect}, got #{p2.inspect}"}.sort
  end
end
