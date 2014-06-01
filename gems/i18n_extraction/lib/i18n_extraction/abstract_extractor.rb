module I18nExtraction
  module AbstractExtractor
    def initialize(options = {})
      @scope = options[:scope] || ''
      @translations = options[:translations] || {}
      @total = 0
      @total_unique = 0
      super()
    end

    def add_translation(full_key, default, line, remove_whitespace = false)
      raise "html tags on line #{line} (hint: use a wrapper or markdown)" if default =~ /<[a-z][a-z0-9]*[> \/]/i
      default = default.gsub(/\s+/, ' ') if remove_whitespace
      default = default.strip unless full_key =~ /separator/
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

    def infer_pluralization_hash(default)
      {:one => "1 #{default}", :other => "%{count} #{default.pluralize}"}
    end

    def allowed_pluralization_keys
      [:zero, :one, :few, :many, :other]
    end

    def required_pluralization_keys
      [:one, :other]
    end

    def self.included(base)
      base.instance_eval do
        attr_reader :total, :total_unique
        attr_accessor :translations, :scope
      end
    end
  end
end