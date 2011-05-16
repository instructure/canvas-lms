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

    def full_name
      obj_name = object.is_a?(ActiveRecord::Base) ? "#{object.class}.find(#{object.id}).#{method}" : display_name
      arg_names = args.map do |a|
        a.is_a?(ActiveRecord::Base) ? "#{a.class}.find(#{a.id})" : a.inspect
      end
      "#{obj_name}(#{arg_names.join(", ")})"
    end
  end
end
