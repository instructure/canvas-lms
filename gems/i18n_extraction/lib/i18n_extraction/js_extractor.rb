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
        [^%]*?
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

    SCOPED_BLOCK_START_COMPONENTS = ['([ \t]*)(require|define)\(', '[^\)]+?', '[\'"]', 'i18n']
    SCOPED_BLOCK_START = /#{SCOPED_BLOCK_START_COMPONENTS.join}/
    SCOPED_BLOCK = /^#{SCOPED_BLOCK_START}(!(#?[\w.]+)|Obj)?['"].*?function\s*\([^\)]*I18n[^\)]*\)\s*\{( *\n(\1[^ ]+\n)?.*?\n\1\}\))/m

    I18N_ANY = /(I18n|i18n|jt)/

    I18N_CALL_START = /I18n\.(t|translate|beforeLabel)\(/
    I18N_KEY_OR_SIMPLE_EXPRESSION = /(#{I18N_KEY}|([\w\.]+|\(['"][\w.]+['"]\))+)/
    I18N_CALL = /
    #{I18N_CALL_START}
    #{I18N_KEY_OR_SIMPLE_EXPRESSION}
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
      options[:offset] ||= 1
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
      expression_type = options[:expression] || "expression"
      expected = []

      lines = source.lines.to_a
      lines.each_with_index do |line, number|
        line.scan(/#{options[:start_prefix]}#{start_pattern}#{options[:start_suffix] || /.*$/}/) do
          match = $&
          if options[:check_expected].nil? || number = options[:check_expected].call(lines, number)
            expected << [match, number + options[:offset]]
          end
        end
      end
      matches = []
      source.scan(full_pattern) { |args| matches << [$&] + args }
      raise "expected/actual mismatch (probably a bug)" if expected.size < matches.size
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

    def find_scopes(source, options)
      # really really dumb multi-line regex implementation across array of
      # lines... gross but necessary so we can get line numbers ... no back-
      # tracking, but sorta supports +?
      checker = lambda do |lines, offset|
        parts = SCOPED_BLOCK_START_COMPONENTS.dup
        line = lines[offset].dup
        while part = parts.shift
          pattern = /^#{part}/
          return false unless line =~ pattern
          while line.sub!(pattern, '')
            if line.empty?
              offset += 1
              line = lines[offset]
              return false if line.nil?
              line = line.dup
            end
            break if part !~ /\+\?\z/ || parts.present? && line =~ /^#{parts.join}/
          end
        end
        offset
      end

      scopes = find_matches(source, /#{SCOPED_BLOCK_START_COMPONENTS.first}/, SCOPED_BLOCK, :start_prefix => /\s*/, :start_suffix => '', :offset => options[:offset], :expression => "I18n scope", :check_expected => checker)
      raise "multiple scopes are not allowed" if scopes.size > 1
      scopes.each do |scope|
        yield({:name => scope[4].to_s.sub(/\A#/, ''), :source => scope[5], :offset => scope.pop})
      end
    end

    def check_scope_violations(source, options)
      offset = options[:offset]
      pattern = options[:pattern] || /#{I18N_CALL_START}.*$/
      type = options[:expression] || 'I18n call'
      # see if any other I18n calls happen outside of a scope
      chunks = source.split(/(#{SCOPED_BLOCK.to_s.gsub(/\\1/, '\\\\2')})/m) # captures subpatterns too, so we need to pick and choose what we want
      while chunk = chunks.shift
        if chunk =~ /^([ \t]*)#{SCOPED_BLOCK_START}/
          chunks.slice!(0, 5).inspect
        else
          find_matches chunk, pattern, pattern, :offset => offset do |match|
            raise "possibly unscoped #{type} on line #{match.last} (hint: check your indentation)"
          end
        end
        offset += chunk.count("\n")
      end
    end

    def process_js(source, options = {})
      find_scopes(source, options) do |scope|
        process_block scope[:source], scope[:name], :offset => scope[:offset]
      end
      check_scope_violations(source, :offset => options[:offset])
    end

    def process_js_blocks(source, options = {})
      # NOTE: we don't do any extraction from erb here since raw I18n js calls
      # are no longer supported. all js i18n in views should be done w/ jt
      # calls. we do sanity checks here rather than in the ruby extractor since
      # it's quite a bit easier
      blocks = find_matches(source, JS_BLOCK_START, JS_BLOCK, :start_prefix => /^\s*/, :start_suffix => /$/, :offset => options[:offset], :expression => "js_block")
      blocks.each do |match|
        block_source = match[3]
        offset = match.last + 1

        find_matches block_source, I18N_CALL_START, I18N_CALL, :offset => offset, :expression => "I18n call", :start_suffix => /[^\)\{$]+/ do |match|
          raise "raw I18n call on line #{match.last} (hint: use the jt helper instead)"
        end
        find_scopes(block_source, :offset => offset) do |scope|
          raise "i18n amd plugin is not supported in js_blocks (line #{scope[:offset]})" if scope[:name].present?
        end
        check_scope_violations(block_source, :offset => offset, :pattern => /(<%=\sjt[ \(]).*$/, :expression => 'jt call')
      end
    end

    def process_block(source, scope, options = {})
      @scope = scope
      find_matches(source, I18N_CALL_START, I18N_CALL, :offset => options[:offset], :expression => "I18n call", :start_suffix => /[^\)\{$]+/) do |args|
        method = args[1] # 0 = the full string
        key = args[2]
        default = args[6]
        call_options = args[29] # :( ... so many capture groups
        offset = args.last
        raise "possibly unscoped I18n call on line #{offset} (hint: did you forget the scope in the require/define call?)" if @scope.empty?
        process_call(scope, method, key, default, call_options, options.merge(:offset => offset))
      end
    end

    def process_call(scope, method, key, default, call_options, options)
      offset = options[:offset] || 0
      sub_calls = []
      return [] unless key = process_key(scope, method, key, default, options)

      default = process_default(key, default, options)

      if call_options
        # in case we are interpolating the results of another t call
        sub_calls = process_block(call_options, scope, options)
        call_options = call_options.scan(HASH_KEY).map(&:last).map(&:to_sym)
      end

      # single word count/pluralization fu
      if default.is_a?(String) && default =~ /\A[\w\-]+\z/ && call_options && call_options.include?(:count)
        default = infer_pluralization_hash(default)
      end

      (default.is_a?(String) ? {nil => default} : default).each_pair do |k, str|
        sub_key = k ? "#{key}.#{k}" : key
        str.scan(INTERPOLATION_KEY) do |match|
          if $& =~ /\A\{\{/
            raise "unsupported interpolation syntax used on line #{offset} of #{options[:filename]}"
          end
          i_key = (match[0] || match[1]).to_sym
          unless call_options && call_options.include?(i_key)
            raise "interpolation value not provided for #{i_key.inspect} (#{sub_key.inspect} on line #{offset})"
          end
        end
        add_translation sub_key, str, offset
      end
      sub_calls
    end

    def process_key(scope, method, key, default, options)
      if key !~ /\A#{I18N_KEY}\z/
        return nil if method == 'beforeLabel' && default.nil?
        raise "invalid key (#{key.inspect} on line #{options[:offset]})"
      end
      key = key[1, key.length - 2]
      if key.sub!(/\A#/, '')
        return nil if key =~ CORE_KEY && default.nil? # nothing to extract, so we bail
      else
        key = scope + '.' + (method == 'beforeLabel' ? 'labels.' : '') + key
      end
      key
    end

    def process_default(key, default, options)
      raise "no default provided for #{key.inspect} on line #{options[:offset]}" if default.nil?
      if default =~ /\A['"]/
        process_literal(default) rescue (raise "unable to \"parse\" default for #{key.inspect} on line #{options[:offset]}: #{$!}")
      else
        hash = JSON.parse(sanitize_json_hash(default)) rescue (raise "unable to \"parse\" default for #{key.inspect} on line #{options[:offset]}: #{$!}")
        pluralization_keys = hash.keys.map(&:to_sym)
        if (invalid_keys = (pluralization_keys - allowed_pluralization_keys)).size > 0
          raise "invalid :count sub-key(s): #{invalid_keys.inspect} on line #{options[:offset]}"
        elsif required_pluralization_keys & pluralization_keys != required_pluralization_keys
          raise "not all required :count sub-key(s) provided on line #{options[:offset]} (expected #{required_pluralization_keys.join(', ')})"
        end
        hash
      end
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