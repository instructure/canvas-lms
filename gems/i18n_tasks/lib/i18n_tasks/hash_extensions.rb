module I18nTasks
  module HashExtensions
    def flatten_keys(result={}, prefix='')
      each_pair do |k, v|
        if v.is_a?(Hash)
          v.flatten_keys(result, "#{prefix}#{k}.")
        else
          result["#{prefix}#{k}"] = v
        end
      end
      result
    end

    def expand_keys(result = {})
      each_pair do |k, v|
        parts = k.split('.')
        last = parts.pop
        parts.inject(result) { |h, k2| h[k2] ||= {} }[last] = v
      end
      result
    end

    def to_ordered
      keys.sort_by(&:to_s).inject ActiveSupport::OrderedHash.new do |h, k|
        v = fetch(k)
        h[k] = v.is_a?(Hash) ? v.to_ordered : v
        h
      end
    end

    Hash.send(:include, HashExtensions)
  end
end