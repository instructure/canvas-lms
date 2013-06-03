require 'lib/i18n_extraction/abstract_extractor'

module I18nExtraction
  class HandlebarsExtractor
    include AbstractExtractor

    I18N_CALL_START = /
      \{\{
      \#t \s+
      (["'])   # quote  ($1)
      (.*?)    # key    ($2)
      \1       # quote
      ([^\}]*) # opts   ($3)
      \}\}
    /x
    I18N_CALL = /
      #{I18N_CALL_START}
      (.*?)   # content ($4)
      \{\{\/t\}\}
    /mx
    I18N_WRAPPER = /((<([a-zA-Z]+)[^>]*>)+)([^<]+)((<\/\3>)+(<\/[^>]+>)*)/

    def process(source, scope)
      @scope = scope
      scan(source, :scope => scope, :strict => true) do |data|
        add_translation data[:key], data[:value], data[:line_number]
      end
    end

    def scan(source, options={})
      options = {
        :method => :scan
      }.merge(options)

      method = options[:method]
      scope = options[:scope] ? options[:scope] + "." : ""

      block_line_numbers = []
      source.lines.each_with_index do |line, line_number|
        line.scan(/#{I18N_CALL_START}.*(\}|$)/) do
          block_line_numbers << line_number + 1
        end
      end

      result = source.send(method, I18N_CALL) do
        line_number = block_line_numbers.shift
        key = $2
        opts = $3
        content = $4

        raise "invalid translation key #{key.inspect} on line #{line_number}" if options[:strict] && key !~ /\A#?[\w.]+\z/
        key = scope + key if scope.size > 0 && !key.sub!(/\A#/, '')
        convert_placeholders!(content, line_number)
        wrappers = extract_wrappers!(content)
        check_html(content, line_number) if options[:strict]
        content.gsub!(/\s+/, ' ')
        content.strip!
        yield :key => key,
              :value => content,
              :options => opts,
              :wrappers => wrappers,
              :line_number => line_number
      end
      raise "possibly unterminated #t call (line #{block_line_numbers.shift} or earlier)" unless block_line_numbers.empty?
      result
    end

    def convert_placeholders!(source, base_line_number)
      source.lines.each_with_index do |line, line_number|
        if line =~ /%h?\{(.*?)\}/
          raise "use {{placeholder}} instead of %{placeholder}"
        end
        if line =~ /\{{2,3}(.*?)\}{2,3}/ && $1 =~ /[^a-z0-9_\.]/i
          raise "helpers may not be used inside #t calls (line #{base_line_number + line_number})"
        end
      end
      source.gsub!(/\{{3}(.*?)\}{3}/, '%h{\1}')
      source.gsub!(/\{\{(.*?)\}\}/, '%{\1}')
    end

    def extract_wrappers!(source)
      wrappers = {}
      source.gsub!(I18N_WRAPPER){
        value = "#{$1}$1#{$5}"
        delimiter = wrappers[value] ||= '*' * (wrappers.size + 1)
        "#{delimiter}#{$4}#{delimiter}"
      }
      wrappers
    end

    def check_html(source, base_line_number)
      source.lines.each_with_index do |line, line_number|
        if line =~ /<[^>]+>/
          raise "translation contains un-wrapper-ed markup (line #{base_line_number + line_number}). hint: use a placeholder"
        end
      end
    end
  end
end
