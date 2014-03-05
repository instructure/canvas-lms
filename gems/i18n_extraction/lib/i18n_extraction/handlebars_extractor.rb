module I18nExtraction
  class HandlebarsExtractor
    include AbstractExtractor

    I18N_CALL_START = /
      \{\{
      \#t \s+
      (?<quote> ["'])
      (?<key>   .*?)
      \g<quote>
      (?<opts>  [^\}]*)
      \}\}
    /x
    I18N_CALL = /
    #{I18N_CALL_START}
      (?<content> .*?)
      \{\{\/t\}\}
    /mx
    TAG_NAME = /[a-z][a-z0-9]*/i
    TAG_START = %r{<#{TAG_NAME}[^>]*(?<!/)>}
    TAG_END = %r{</#{TAG_NAME}>}
    TAG_EMPTY = %r{<#{TAG_NAME}[^>]*/>}
    I18N_WRAPPER = /
      (?<start>      (#{TAG_START}\s*)+)
      (?<startInner> #{TAG_START}#{TAG_END}|#{TAG_EMPTY})?
      (?<content>    [^<]+)
      (?<endInner>   #{TAG_START}#{TAG_END}|#{TAG_EMPTY})?
      (?<end>        (\s*#{TAG_END})+)
    /x

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
        match = Regexp.last_match
        key = match[:key]
        opts = match[:opts]
        content = match[:content]

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
      source.gsub!(I18N_WRAPPER) do
        match = Regexp.last_match

        if balanced_tags?(match[:start], match[:end])
          value = "#{match[:start]}#{match[:startInner]}$1#{match[:endInner]}#{match[:end]}".gsub(/\s+/, ' ')
          delimiter = wrappers[value] ||= '*' * (wrappers.size + 1)
          "#{delimiter}#{match[:content]}#{delimiter}"
        else
          match.to_s
        end
      end
      wrappers
    end

    def balanced_tags?(open, close)
      open.scan(TAG_START).map { |tag| tag.match(TAG_NAME).to_s } ==
          close.scan(TAG_END).map { |tag| tag.match(TAG_NAME).to_s }.reverse
    end

    def check_html(source, base_line_number)
      source.lines.each_with_index do |line, line_number|
        if line =~ /<[^>]+>/
          raise "translation contains un-wrapper-ed markup (line #{base_line_number + line_number}). hint: use a placeholder, or balance your markup"
        end
      end
    end
  end
end
