require 'lib/i18n_extraction/abstract_extractor'

module I18nExtraction
  class JsExtractor
    include AbstractExtractor

    I18N_KEY = /['"](#?[\w.]+)['"]/
    HASH_KEY = /['"]?(\w+)['"]?\s*:/

    INTERPOLATION_KEY = /%\{([^\}]+)\}|\{\{([^\}]+)\}\}/
    CORE_KEY = /\A(number|time|date|datetime|support)\./

    STRING_LITERAL = /'((\\'|[^'])*)'|"((\\"|[^"])*)"/m
    STRING_CONCATENATION = /(#{STRING_LITERAL})(\s*\+\s*(#{STRING_LITERAL})\s*)*/m

    RUBY_SYMBOL = /:(\w+|#{STRING_LITERAL})/

    REALLY_SIMPLE_HASH_LITERAL = /
      \{\s*
        #{HASH_KEY}\s*#{STRING_LITERAL}\s*
        (,\s*#{HASH_KEY}\s*#{STRING_LITERAL}\s*)*
      \}
    /mx

    SIMPLE_HASH_LITERAL = / # might have a t call as value, for example. no nested hashes, but we shouldn't need that
      \{
      (
        #{STRING_LITERAL} |
        [^}]
      )+
      \}
    /mx

    JS_BLOCK_START = /
      <%\s*
        js_block\s*
        ([^%]*? :i18n_scope\s* =>\s* (#{STRING_LITERAL}|#{RUBY_SYMBOL}))? [^%]*?
        (do|\{)\s*
      %>\s*
    /mx
    JS_BLOCK = /
      ^([ \t]*) # we rely on indentation matching for the block (and we ignore any single-line js_block calls)
      #{JS_BLOCK_START}\n
      (.*?)\n
      \1
      <%\s*(end|\})\s*%>
    /mx

    SCOPED_BLOCK_START = /((require|define)\(.*?function\(.*?I18n.*?I18n\s*=\s*|())I18n\.scoped/m
    SCOPED_BLOCK = /^([ \t]*)#{SCOPED_BLOCK_START}\(#{I18N_KEY}(,\s*function\s*\(I18n\)\s*\{|\);)\s?\n((\1[^ ].*?\n)?( *\n|\1(  |\t)[^\n]+\n)+)/m

    I18N_ANY = /(I18n)/

    I18N_CALL_START = /I18n\.(t|translate|beforeLabel)\(/
    I18N_CALL = /
      #{I18N_CALL_START}
        #{I18N_KEY} # key
        (,\s*
          ( #{STRING_CONCATENATION} | #{REALLY_SIMPLE_HASH_LITERAL} ) # default
          (,\s*
            ( #{SIMPLE_HASH_LITERAL} ) # options
          )?
        )?
      \)
    /mx

    def process(source, options = {})
      return false unless source =~ I18N_ANY
      if options.delete(:erb)
        process_js_blocks(source, options)
      else
        process_js(source, options)
      end
      true
    end

    # this is a bit more convoluted than just doing simple scans, but it lets
    # us figure out exactly which ones we can't grok (and get the line numbers)
    def find_matches(source, start_pattern, full_pattern=start_pattern, options = {})
      line_offset = options[:line_offset] || 0
      expression_type = options[:expression] || "expression"
      expected = []
      source.lines.each_with_index do |line, number|
        line.scan(/#{options[:start_prefix]}#{start_pattern}#{options[:start_suffix] || /.*$/}/) do
          expected << [$&, number + line_offset]
        end
      end
      matches = []
      source.scan(full_pattern){ |args| matches << [$&] + args }
      expected.each_index do |i|
        expected_string = expected[i].first.strip
        unless matches[i]
          raise "unable to \"parse\" #{expression_type} on line #{expected[i].last} (#{expected_string}...)"
        end
        matched_string = matches[i].first.strip
        unless matched_string.include?(expected_string)
          raise "unable to \"parse\" #{expression_type} on line #{expected[i].last} (#{expected_string}...)"
        end
        matches[i] << expected[i].last
        if block_given?
          # interleave sub-results into our matches
          # (e.g. an I18n.t that is interpolated into another I18n.t)
          matches.insert i + 1, *yield(matches[i])
        end
      end
      matches
    end

    def process_js(source, options = {})
      line_offset = options[:line_offset] || 1
      scopes = find_matches(source, SCOPED_BLOCK_START, SCOPED_BLOCK, :start_prefix => /\s*/, :line_offset => line_offset, :expression => "I18n scope")
      scopes.each do |scope|
        scope_name = scope[5]
        scope_source = scope[7]
        offset = scope.pop
        process_block scope_source, scope_name.sub(/\A#/, ''), options.merge(:line_offset => offset)
      end
      # see if any other I18n calls happen outside of a scope
      chunks = source.split(/(#{SCOPED_BLOCK.to_s.gsub(/\\1/, '\\\\2')})/m) # captures subpatterns too, so we need to pick and choose what we want
      while chunk = chunks.shift
        if chunk =~ /^([ \t]*)#{SCOPED_BLOCK_START}/
          chunks.slice!(0, 7).inspect
        else
          find_matches chunk, /#{I18N_ANY}.*$/ do |match|
            raise "possibly unscoped I18n call on line #{line_offset + match.last} (hint: check your indentation)"
          end
        end
        line_offset += chunk.count("\n")
      end
    end

    def process_js_blocks(source, options = {})
      line_offset = options[:line_offset] || 1
      extract_from_erb(source, :line_offset => line_offset).each do |scope, block_source, offset|
        offset = line_offset + offset
        find_matches block_source, /#{SCOPED_BLOCK_START}.*/ do |match|
          raise "scoped blocks are no longer supported in js_blocks, use :i18n_scope instead (line #{offset + match.last})"
        end
        if scope && (scope = process_literal(scope))
          process_block block_source, scope, options.merge(:restrict_to_scope => true, :line_offset => offset)
        elsif block_source =~ I18N_ANY
          find_matches block_source, /#{I18N_ANY}.*$/ do |match|
            raise "possibly unscoped I18n call on line #{offset + match.last} (hint: did you forget your :i18n_scope?)"
          end
        end
      end
    end

    def process_block(source, scope, options = {})
      line_offset = options[:line_offset] || 0
      calls = find_matches(source, I18N_CALL_START, I18N_CALL, :line_offset => line_offset, :expression => "I18n call", :start_suffix => /[^\)\{$]+/) do |args|
        method = args[1] # 0 = the full string
        key = args[2]
        default = args[4]
        call_options = args[27] # :( ... so many capture groups
        offset = args.last
        process_call(scope, method, key, default, call_options, options.merge(:line_offset => offset))
      end
    end

    def process_call(scope, method, key, default, call_options, options)
      line_offset = options[:line_offset] || 0
      sub_calls = []
      return sub_calls unless key = process_key(scope, method, key, default, options)

      default = process_default(key, default, options)

      if call_options
        # in case we are interpolating the results of another t call
        sub_calls = process_block(call_options, scope, options)
        call_options = call_options.scan(HASH_KEY).map(&:last).map(&:to_sym)
      end

      # single word count/pluralization fu
      if default.is_a?(String) && default =~ /\A[\w\-]+\z/ && call_options && call_options.include?(:count)
        default = {:one => "1 #{default}", :other => "%{count} #{default.pluralize}"}
      end

      (default.is_a?(String) ? {nil => default} : default).each_pair do |k, str|
        sub_key = k ? "#{key}.#{k}" : key
        str.scan(INTERPOLATION_KEY) do |match|
          if $& =~ /\A\{\{/
            $stderr.puts "Warning: deprecated interpolation syntax used on line #{line_offset} of #{options[:filename]}"
          end
          i_key = (match[0] || match[1]).to_sym
          unless call_options && call_options.include?(i_key)
            raise "interpolation value not provided for #{i_key.inspect} (#{sub_key.inspect} on line #{line_offset})"
          end
        end
        add_translation sub_key, str
      end
      sub_calls
    end

    def process_key(scope, method, key, default, options)
      line_offset = options[:line_offset] || 0
      if key =~ /\A#/
        raise "absolute keys are not supported in this context (#{key.inspect} on line #{line_offset})" if options[:restrict_to_scope]
        key.sub!(/\A#/, '')
        return nil if key =~ CORE_KEY && default.nil? # nothing to extract, so we bail
      else
        key = scope + '.' + (method == 'beforeLabel' ? 'labels.' : '') + key
      end
      key
    end

    def process_default(key, default, options)
      line_offset = options[:line_offset] || 0
      raise "no default provided for #{key.inspect} on line #{line_offset}" if default.nil?
      if default =~ /\A['"]/
        raise "erb cannot be used inside of default values (line #{line_offset})" if default =~ /<%/ # e.g. if you do I18n.t('foo', '<%= name %>') in a view
        process_literal(default) rescue (raise "unable to \"parse\" default for #{key.inspect} on line #{line_offset}: #{$!}")
      else
        hash = JSON.parse(sanitize_json_hash(default)) rescue (raise "unable to \"parse\" default for #{key.inspect} on line #{line_offset}: #{$!}")
        if (invalid_keys = (hash.keys.map(&:to_sym) - [:one, :other, :zero])).size > 0
          raise "invalid :count sub-key(s): #{invalid_keys.inspect} on line #{line_offset}"
        end
        hash
      end
    end

    def extract_from_erb(source, options = {})
      line_offset = options[:line_offset] || 0
      blocks = find_matches(source, JS_BLOCK_START, JS_BLOCK, :start_prefix => /^\s*/, :start_suffix => /$/, :line_offset => line_offset, :expression => "js_block")
      blocks.map{ |b| [b[3], b[14], b[16]] }
    end

    def sanitize_json_hash(string)
      string.gsub(/#{HASH_KEY}\s*#{STRING_LITERAL}/) { |m1|
        m1.sub(HASH_KEY) { |m2|
          '"' + m2.delete("'\":") + '":'
        }
      }.gsub(STRING_LITERAL) { |match|
        process_literal(match).inspect # double-quoted strings only
      }
    end

    def process_literal(string)
      instance_eval(string.gsub(/(^|[^\\])#/, '\1\\#'))
    end
  end
end
