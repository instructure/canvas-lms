YAML.add_ruby_type("object:Module") do |type, val|
  val.constantize
end

YAML.add_ruby_type("object:Class") do |type, val|
  val.constantize
end

class Module
  def to_yaml(opts = {})
    YAML.quick_emit(self.object_id, opts) do |out|
      out.scalar(taguri, name)
    end
  end

  def load_for_delayed_job(arg)
    self
  end
end

class Class
  def to_yaml(opts = {})
    YAML.quick_emit(self.object_id, opts) do |out|
      out.scalar(taguri, name)
    end
  end

  def load_for_delayed_job(arg)
    self
  end
end

class ActiveRecord::Base
  yaml_as "tag:ruby.yaml.org,2002:ActiveRecord"

  def to_yaml(opts = {})
    if id.nil?
      raise("Can't serialize unsaved ActiveRecord object for delayed job: #{self.inspect}")
    end
    YAML.quick_emit(self.object_id, opts) do |out|
      out.scalar(taguri, id.to_s)
    end
  end

  def self.yaml_new(klass, tag, val)
    klass.find(val)
  rescue ActiveRecord::RecordNotFound
    raise Delayed::Backend::DeserializationError, "Couldn't find #{klass} with id #{val.inspect}"
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

      self.tag = display_name
    end
    
    def display_name
      if STRING_FORMAT === object
        "#{$1}#{$2 ? '#' : '.'}#{method}"
      elsif object.is_a?(Module)
        "#{object}.#{method}"
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
      obj
    end
  end
end
