class Class
  def load_for_delayed_job(arg)
    self
  end

  def dump_for_delayed_job
    name
  end
end

class Module
  def yaml_tag_read_class(name)
    name.constantize
    name
  end
end

module Delayed
  class PerformableMethod < Struct.new(:object, :method, :args)
    STRING_FORMAT = /^LOAD\;([A-Z][\w\:]+)(?:\;(\w+))?$/

    attr_accessor :tag
    
    class LoadError < StandardError
    end

    def initialize(object, method, args = [])
      raise NoMethodError, "undefined method `#{method}' for #{object.inspect}" unless object.respond_to?(method)

      self.object = dump(object)
      self.args   = args.map { |a| dump(a) }
      self.method = method.to_sym

      if object.is_a?(Module)
        self.tag = "#{object.name}.#{method}"
      else
        self.tag = "#{object.class}##{method}"
      end
    end
    
    def display_name
      if STRING_FORMAT === object
        "#{$1}#{$2 ? '#' : '.'}#{method}"
      else
        "#{object.class}##{method}"
      end
    end
    
    def perform
      live_object.send(method, *args.map{|a| load(a)})
    end

    def live_object
      @live_object ||= load(object)
    end

    private

    def load(obj)
      if STRING_FORMAT === obj
        $1.constantize.load_for_delayed_job($2)
      else
        obj
      end
    rescue => e
      Delayed::Worker.logger.warn "Could not load object for job: #{e.message}"
      raise PerformableMethod::LoadError
    end

    def dump(obj)
      if obj.respond_to?(:dump_for_delayed_job)
        "LOAD;#{obj.dump_for_delayed_job}"
      else
        obj
      end
    end
  end
end
