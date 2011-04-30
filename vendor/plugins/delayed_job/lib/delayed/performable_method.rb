module Delayed
  class PerformableMethod < Struct.new(:object, :method, :args)
    attr_accessor :tag

    def initialize(object, method, args = [])
      raise NoMethodError, "undefined method `#{method}' for #{object.inspect}" unless object.respond_to?(method)

      self.object = object
      self.args   = args
      self.method = method.to_sym

      self.tag = display_name
    end

    def display_name
      if object.is_a?(Module)
        "#{object}.#{method}"
      else
        "#{object.class}##{method}"
      end
    end

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
