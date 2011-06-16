class I18nExtractor < SexpProcessor
  attr_reader :translations, :total, :total_unique
  attr_accessor :scope

  def initialize
    super
    @scope = ''
    @translations = {}
    @total = 0
    @total_unique = 0
  end

  def process_defn(exp)
    exp.shift
    @current_defn = exp.shift
    process exp.shift until exp.empty?
    @current_defn = nil
    s
  end

  TRANSLATE_CALLS = [:t, :ot, :mt, :translate, :before_label]
  LABEL_CALLS = [:label, :blabel]
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
      elsif receiver.last == :I18n && args.size == 1
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
    if default.is_a?(String) && default =~ /\A\w+\z/ && options.include?(:count)
      default = {:one => "1 #{default}", :other => "%{count} #{default.pluralize}"}
    end

    (default.is_a?(String) ? {nil => default} : default).each_pair do |k, str|
      sub_key = k ? "#{key}.#{k}" : key
      str.scan(/%\{([^\}]+)\}/) do |match|
        unless options.include?(match[0].to_sym)
          raise "interpolation value not provided for #{match[0].to_sym.inspect} (#{sub_key.inspect})"
        end
      end
      add_translation sub_key, str
    end
  end

  # stuff we want:
  #  label :bar, :foo, :en => "Foo"
  #  label :bar, :foo, :foo_key, :en => "Foo"
  #  f.label :foo, :en => "Foo"
  #  f.label :foo, :foo_key, :en => "Foo"
  def process_label_call(receiver, method, args)
    args.shift
    args.shift unless receiver # remove object_name arg

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
        add_translation key, default
      else
        process key_arg
      end
    end
  end

  def process_translation_key(receiver, exp, relative_scope, allow_strings=true)
    unless exp.is_a?(Sexp) && (exp.sexp_type == :lit || allow_strings && exp.sexp_type == :str)
      raise "invalid translation key #{exp.inspect}"
    end
    key = exp.pop.to_s
    if key =~ /\A#/
      key.sub!(/\A#/, '')
    else
      raise "ambiguous translation key #{key.inspect}" if @scope.empty? && receiver.nil?
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
      process_possible_string_concat(exp, :top_level_error => lambda{ |exp| "invalid en default #{exp.inspect}" })
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

  def add_translation(full_key, default)
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
end