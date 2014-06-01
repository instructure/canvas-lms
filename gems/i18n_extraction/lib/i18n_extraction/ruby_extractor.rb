module I18nExtraction
  class RubyExtractor < SexpProcessor
    include AbstractExtractor
    
    attr_accessor :in_html_view

    def process_defn(exp)
      exp.shift
      @current_defn = exp.shift
      process exp.shift until exp.empty?
      @current_defn = nil
      s
    end

    TRANSLATE_CALLS = [:t, :ot, :mt, :translate, :before_label, :jt]
    LABEL_CALLS = [:label, :blabel, :label_tag, :_label_symbol_translation]
    ALL_CALLS = TRANSLATE_CALLS + LABEL_CALLS + [:label_with_symbol_translation]

    def process_call(exp)
      exp.shift
      receiver = process(exp.shift)
      method = exp.shift

      call_scope = @scope
      if receiver && receiver.last == :Plugin && method == :register &&
          exp.first && [:lit, :str].include?(exp.first.sexp_type)
        call_scope = "plugins.#{exp.first.last}."
      end

      # ignore things like mt's t call
      unless ALL_CALLS.include?(@current_defn)
        if TRANSLATE_CALLS.include?(method)
          process_translate_call(receiver, method, exp)
        elsif LABEL_CALLS.include?(method)
          process_label_call(receiver, method, exp)
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
      line = args.line
      unless args.size >= 2
        if method == :before_label
          process args.shift until args.empty?
          return
        elsif receiver && receiver.last == :I18n && args.size == 1
          return
        else
          raise "insufficient arguments for translate call on line #{line}"
        end
      end

      key = process_translation_key(receiver, args.shift, method == :before_label ? 'labels.' : '')

      default = process_default_translation(args.shift, key)

      options = if args.first.is_a?(Sexp)
                  if method == :jt
                    if args.first.sexp_type != :str
                      raise "jt options must be a javascript string: #{key.inspect} on line #{line}"
                    end
                    str = args.shift.last
                    str.scan(/['"]?(\w+)['"]?:/).flatten.map(&:to_sym)
                  else
                    if args.first.sexp_type != :hash
                      raise "translate options must be a hash: #{key.inspect} on line #{line}"
                    end
                    hash = args.shift
                    hash.shift
                    (0...(hash.size/2)).map { |i|
                      process hash[i * 2 + 1]
                      raise "option keys must be strings or symbols on line #{line}" unless [:lit, :str].include?(hash[i * 2].sexp_type)
                      hash[i * 2].last.to_sym
                    }
                  end
                else
                  []
                end

      # single word count/pluralization fu
      if default.is_a?(String) && default =~ /\A[\w\-]+\z/ && options.include?(:count)
        default = infer_pluralization_hash(default)
      end

      (default.is_a?(String) ? {nil => default} : default).each_pair do |k, str|
        raise "english default for a before_label call ends in a colon on line #{line}" if method == :before_label && str.strip =~ /:\z/
        sub_key = k ? "#{key}.#{k}" : key
        str.scan(/%\{([^\}]+)\}/) do |match|
          unless options.include?(match[0].to_sym)
            raise "interpolation value not provided for #{match[0].to_sym.inspect} (#{sub_key.inspect}) on line #{line}"
          end
        end
        add_translation sub_key, str, line, (:remove_whitespace if @in_html_view && ![:mt, :jt].include?(method))
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
        hash_args = args.shift
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
        raise "invalid/missing en default #{args.first.inspect} on line #{key_arg.line}" if (inferred || key_arg.sexp_type == :lit) && !default
        if default
          key = process_translation_key(receiver, key_arg, 'labels.', inferred)
          raise "english default for a blabel call ends in a colon on line #{key_arg.line}" if method == :blabel && default.strip =~ /:\z/
          add_translation key, default, key_arg.line, :remove_whitespace
        elsif key_arg.sexp_type == :str && key_arg.last.to_s =~ /[^a-z_\.]/
          raise "unlocalized label call on line #{key_arg.line}: #{key_arg.inspect}"
        else
          process key_arg
        end
      end
      process args.shift until args.empty?
    end

    def process_translation_key(receiver, exp, relative_scope, allow_strings=true)
      unless exp.is_a?(Sexp) && (exp.sexp_type == :lit || allow_strings && exp.sexp_type == :str) && exp.last.to_s =~ /\A#?[a-z0-9_\.]+\z/
        raise "invalid translation key #{exp.inspect} on line #{exp.line}"
      end
      key = exp.pop.to_s
      if key =~ /\A#/ || receiver && receiver.last == :I18n
        key.sub!(/\A#/, '')
      else
        raise "ambiguous translation key #{key.inspect} on line #{exp.line}" if @scope.empty?
        key = @scope + relative_scope + key
      end
      key
    end

    def process_default_translation(exp, key)
      raise "invalid en default #{exp.inspect}" unless exp.is_a?(Sexp)
      if exp.sexp_type == :hash
        exp.shift
        hash = Hash[*exp.map { |e| process_possible_string_concat(e, :allow_symbols => true) }]
        pluralization_keys = hash.keys
        if (pluralization_keys - allowed_pluralization_keys).size > 0
          raise "invalid :count sub-key(s) #{exp.inspect} on line #{exp.line}"
        elsif required_pluralization_keys & pluralization_keys != required_pluralization_keys
          raise "not all required :count sub-key(s) provided on line #{exp.line} (expected #{required_pluralization_keys.join(', ')})"
        elsif hash.values.any? { |v| !v.is_a?(String) }
          raise "invalid en count default(s) #{exp.inspect} on line #{exp.line}"
        end
        hash
      else
        process_possible_string_concat(exp, :top_level_error => lambda { |exp| "invalid en default #{exp.inspect} on line #{exp.line}" })
      end
    rescue
      raise "#{$!} (#{key.inspect})"
    end

    def process_possible_string_concat(exp, options={})
      if exp.sexp_type == :str && exp.last !~ /#\{/ # like if they accidentally tried ruby interpolation in a single quoted string
        exp.last
      elsif exp.sexp_type == :lit && options.delete(:allow_symbols)
        exp.last
      elsif exp.sexp_type == :call && exp[2] == :+ && exp.size == 4 && exp[3].sexp_type == :str
        process_possible_string_concat(exp[1]) + exp[3].last
      else
        raise options[:top_level_error] ? options[:top_level_error].call(exp) : "unsupported string concatenation/interpolation #{exp.inspect} on line #{exp.line}"
      end
    end
  end
end