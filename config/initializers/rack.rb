#encoding:ASCII-8BIT

Rack::Utils.key_space_limit = 128.kilobytes # default is 64KB

# https://groups.google.com/forum/#!topic/rubyonrails-security/gcUbICUmKMc
if CANVAS_RAILS3
  module Rack
    Utils.module_eval do
      class << self
        attr_accessor :param_depth_limit
      end

      self.param_depth_limit = 100

      def normalize_params(params, name, v = nil, depth = Utils.param_depth_limit)
        raise RangeError if depth <= 0

        name =~ %r(\A[\[\]]*([^\[\]]+)\]*)
        k = $1 || ''
        after = $' || ''

        return if k.empty?

        if after == ""
          params[k] = v
        elsif after == "[]"
          params[k] ||= []
          raise TypeError, "expected Array (got #{params[k].class.name}) for param `#{k}'" unless params[k].is_a?(Array)
          params[k] << v
        elsif after =~ %r(^\[\]\[([^\[\]]+)\]$) || after =~ %r(^\[\](.+)$)
          child_key = $1
          params[k] ||= []
          raise TypeError, "expected Array (got #{params[k].class.name}) for param `#{k}'" unless params[k].is_a?(Array)
          if params_hash_type?(params[k].last) && !params[k].last.key?(child_key)
            normalize_params(params[k].last, child_key, v, depth - 1)
          else
            params[k] << normalize_params(params.class.new, child_key, v, depth - 1)
          end
        else
          params[k] ||= params.class.new
          raise TypeError, "expected Hash (got #{params[k].class.name}) for param `#{k}'" unless params_hash_type?(params[k])
          params[k] = normalize_params(params[k], after, v, depth - 1)
        end

        return params
      end
      module_function :normalize_params
    end
  end
end