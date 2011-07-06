module I18nExtraction
  def initialize(options = {})
    @scope = options[:scope] || ''
    @translations = options[:translations] || {}
    @total = 0
    @total_unique = 0
    super()
  end

  def add_translation(full_key, default, remove_whitespace = false)
    default = default.gsub(/\s+/, ' ') if remove_whitespace
    @total += 1
    scope = full_key.split('.')
    key = scope.pop
    hash = @translations
    while s = scope.shift
      if hash[s]
        raise "#{full_key.sub((scope.empty? ? '' : '.' + scope.join('.')) + '.' + key, '').inspect} used as both a scope and a key" unless hash[s].is_a?(Hash)
      else
        hash[s] = {}
      end
      hash = hash[s]
    end
    if hash[key]
      if hash[key] != default
        if hash[key].is_a?(Hash)
          raise "#{full_key.inspect} used as both a scope and a key"
        else
          raise "cannot reuse key #{full_key.inspect}"
        end
      end
    else
      @total_unique += 1
      hash[key] = default
    end
  end

  def self.included(base)
    base.instance_eval do
      attr_reader :translations, :total, :total_unique
      attr_accessor :scope
    end
  end
end

class I18nExtractor < SexpProcessor
  include I18nExtraction
  attr_accessor :in_html_view

  def process_defn(exp)
    exp.shift
    @current_defn = exp.shift
    process exp.shift until exp.empty?
    @current_defn = nil
    s
  end

  TRANSLATE_CALLS = [:t, :ot, :mt, :translate, :before_label]
  LABEL_CALLS = [:label, :blabel, :label_tag, :_label_symbol_translation]
  ALL_CALLS = TRANSLATE_CALLS + LABEL_CALLS + [:label_with_symbol_translation]

  def process_call(exp)
    exp.shift
    receiver = process(exp.shift)
    method = exp.shift

    call_scope = @scope
    if receiver && receiver.last == :Plugin && method == :register &&
        exp.first && exp.first.sexp_type == :arglist &&
        exp.first[1] && [:lit, :str].include?(exp.first[1].sexp_type)
      call_scope = "plugins.#{exp.first[1].last}."
    end

    # ignore things like mt's t call
    unless ALL_CALLS.include?(@current_defn)
      if TRANSLATE_CALLS.include?(method)
        process_translate_call(receiver, method, exp.shift)
      elsif LABEL_CALLS.include?(method)
        process_label_call(receiver, method, exp.shift)
      end
    end

    with_scope(call_scope) do
      process exp.shift until exp.empty?
    end
    s
  end

  def with_scope(scope)
    orig_scope = @scope
    @scope = scope
    yield if block_given?
  ensure
    @scope = orig_scope
  end

  def process_translate_call(receiver, method, args)
    args.shift
    unless args.size >= 2
      if method == :before_label
        process args.shift until args.empty?
        return
      elsif receiver && receiver.last == :I18n && args.size == 1
        return
      else
        raise "insufficient arguments for translate call"
      end
    end

    key = process_translation_key(receiver, args.shift, method == :before_label ? 'labels.' : '')

    default = process_default_translation(args.shift, key)

    options = if args.first.is_a?(Sexp)
      if args.first.sexp_type != :hash
        raise "translate options must be a hash: #{key.inspect}"
      end
      hash = args.shift
      hash.shift
      (0...(hash.size/2)).map{ |i|
        process hash[i * 2 + 1]
        raise "option keys must be strings or symbols" unless [:lit, :str].include?(hash[i * 2].sexp_type)
        hash[i * 2].last.to_sym
      }
    else
      []
    end

    # single word count/pluralization fu
    if default.is_a?(String) && default =~ /\A[\w\-]+\z/ && options.include?(:count)
      default = {:one => "1 #{default}", :other => "%{count} #{default.pluralize}"}
    end

    (default.is_a?(String) ? {nil => default} : default).each_pair do |k, str|
      sub_key = k ? "#{key}.#{k}" : key
      str.scan(/%\{([^\}]+)\}/) do |match|
        unless options.include?(match[0].to_sym)
          raise "interpolation value not provided for #{match[0].to_sym.inspect} (#{sub_key.inspect})"
        end
      end
      add_translation sub_key, str, (@in_html_view && method != :mt)
    end
  end

  # stuff we want:
  #  label :bar, :foo, :en => "Foo"
  #  label :bar, :foo, :foo_key, :en => "Foo"
  #  f.label :foo, :en => "Foo"
  #  f.label :foo, :foo_key, :en => "Foo"
  #  label_tag :foo, :en => "Foo"
  #  label_tag :foo, :foo_key, :en => "Foo"
  def process_label_call(receiver, method, args)
    args.shift
    args.shift unless receiver || method.to_s == 'label_tag' # remove object_name arg

    inferred = false
    default = nil
    key_arg = if args.size == 1 || args[1] && args[1].is_a?(Sexp) && args[1].sexp_type == :hash
      inferred = true
      args.shift
    elsif args[1].is_a?(Sexp)
      args.shift
      args.shift
    end
    if args.first.is_a?(Sexp) && args.first.sexp_type == :hash
      hash_args = args.first
      hash_args.shift
      (0...hash_args.size/2).each do |i|
        key = hash_args[2*i]
        value = hash_args[2*i + 1]
        if [:lit, :str].include?(key.sexp_type) && key.last.to_s == 'en'
          default = process_possible_string_concat(value)
        else
          process key
          process value
        end
      end
    end

    if key_arg
      raise "invalid/missing en default #{args.first.inspect}" if (inferred || key_arg.sexp_type == :lit) && !default
      if default
        key = process_translation_key(receiver, key_arg, 'labels.', inferred)
        add_translation key, default, true
      else
        process key_arg
      end
    end
  end

  def process_translation_key(receiver, exp, relative_scope, allow_strings=true)
    unless exp.is_a?(Sexp) && (exp.sexp_type == :lit || allow_strings && exp.sexp_type == :str)
      raise "invalid translation key #{exp.inspect} on line #{exp.line}"
    end
    key = exp.pop.to_s
    if key =~ /\A#/
      key.sub!(/\A#/, '')
    else
      raise "ambiguous translation key #{key.inspect} on line #{exp.line}" if @scope.empty? && receiver.nil?
      key = @scope + relative_scope + key
    end
  end

  def process_default_translation(exp, key)
    raise "invalid en default #{exp.inspect}" unless exp.is_a?(Sexp)
    if exp.sexp_type == :hash
      exp.shift
      hash = Hash[*exp.map{ |e| process_possible_string_concat(e, :allow_symbols => true) }]
      if (hash.keys - [:one, :other, :zero]).size > 0
        raise "invalid :count sub-key(s): #{exp.inspect}"
      elsif hash.values.any?{ |v| !v.is_a?(String) }
        raise "invalid en count default(s): #{exp.inspect}"
      end
      hash
    else
      process_possible_string_concat(exp, :top_level_error => lambda{ |exp| "invalid en default #{exp.inspect} on line #{exp.line}" })
    end
  rescue
    raise "#{$!} (#{key.inspect})"
  end

  def process_possible_string_concat(exp, options={})
    if exp.sexp_type == :str
      exp.last
    elsif exp.sexp_type == :lit && options.delete(:allow_symbols)
      exp.last
    elsif exp.sexp_type == :call && exp[2] == :+ && exp.last && exp.last.sexp_type == :arglist && exp.last.size == 2 && exp.last.last.sexp_type == :str
      process_possible_string_concat(exp[1]) + exp.last.last.last
    else
      raise options[:top_level_error] ? options[:top_level_error].call(exp) : "unsupported string concatenation: #{exp.inspect}"
    end
  end
end


class I18nJsExtractor
  include I18nExtraction

  I18N_KEY = /['"](#?[\w.]+)['"]/
  HASH_KEY = /['"]?(\w+)['"]?\s*:/

  INTERPOLATION_KEY = /%\{([^\}]+)\}|\{\{([^\}]+)\}\}/
  CORE_KEY = /\A(number|time|date|datetime)\./

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

  SCOPED_BLOCK_START = /I18n\.scoped/
  SCOPED_BLOCK = /^([ \t]*)#{SCOPED_BLOCK_START}\(#{I18N_KEY},\s*function\s*\(I18n\)\s*\{(.*?)\n\1\}\)(;|$)/m

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
      unless matches[i]
        raise "unable to \"parse\" #{expression_type} on line #{expected[i].last} (#{expected[i].first}...)"
      end
      len = [expected[i].first.size, matches[i].first.size].min
      if expected[i].first[0, len] != matches[i].first[0, len]
        raise "unable to \"parse\" #{expression_type} on line #{expected[i].last} (#{expected[i].first[0, len]}...)"
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
    scopes.each do |(v, v, scope, scope_source, v, offset)|
      process_block scope_source, scope.sub(/\A#/, ''), options.merge(:line_offset => offset)
    end
    # see if any other I18n calls happen outside of a scope
    chunks = source.split(/(#{SCOPED_BLOCK.to_s.gsub(/\\1/, '\\\\2')})/m) # captures subpatterns too, so we need to pick and choose what we want
    while chunk = chunks.shift
      if chunk =~ /^([ \t]*)#{SCOPED_BLOCK_START}/
        chunks.slice!(0, 4)
      else
        find_matches chunk, I18N_ANY do |match|
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
      find_matches block_source, /(#{SCOPED_BLOCK_START})/ do |match|
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