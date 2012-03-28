module Delayed
  class PerformableMethod < Struct.new(:object, :method, :args)
    def initialize(object, method, args = [])
      raise NoMethodError, "undefined method `#{method}' for #{object.inspect}" unless object.respond_to?(method)

      self.object = object
      self.args   = args
      self.method = method.to_sym
    end

    def display_name
      if object.is_a?(Module)
        "#{object}.#{method}"
      else
        "#{object.class}##{method}"
      end
    end
    alias_method :tag, :display_name

    def perform
      object.send(method, *args)
    end

    def deep_de_ar_ize(arg)
      case arg
      when Hash
        "{#{arg.map { |k, v| "#{deep_de_ar_ize(k)} => #{deep_de_ar_ize(v)}" }.join(', ')}}"
      when Array
        "[#{arg.map { |a| deep_de_ar_ize(a) }.join(', ')}]"
      when ActiveRecord::Base
        "#{arg.class}.find(#{arg.id})"
      else
        arg.inspect
      end
    end

    def full_name
      obj_name = object.is_a?(ActiveRecord::Base) ? "#{object.class}.find(#{object.id}).#{method}" : display_name
      "#{obj_name}(#{args.map { |a| deep_de_ar_ize(a) }.join(', ')})"
    end
  end
end
