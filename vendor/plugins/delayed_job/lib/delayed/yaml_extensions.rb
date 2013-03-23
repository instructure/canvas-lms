# New definitions for YAML to aid in serialization and deserialization of delayed jobs.

require 'yaml'
# this code needs to be updated to work with the new Psych YAML engine in ruby 1.9.x
# for now we force Syck
YAML::ENGINE.yamler = 'syck' if defined?(YAML::ENGINE) && YAML::ENGINE.yamler != 'syck'

# First, tell YAML how to load a Module. This depends on Rails .constantize and autoloading.
YAML.add_ruby_type("object:Module") do |type, val|
  val.constantize
end

class Module
  def to_yaml(opts = {})
    YAML.quick_emit(self.object_id, opts) do |out|
      out.scalar(taguri, name)
    end
  end
end

# Now we have to do the same for Class.
YAML.add_ruby_type("object:Class") do |type, val|
  val.constantize
end

class Class
  def to_yaml(opts = {})
    YAML.quick_emit(self.object_id, opts) do |out|
      out.scalar(taguri, name)
    end
  end
end

# Now, tell YAML how to intelligently load ActiveRecord objects, using the
# database rather than just serializing their attributes to the YAML. This
# ensures the object is up to date when we use it in the job.
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
    raise Delayed::Backend::RecordNotFound, "Couldn't find #{klass} with id #{val.inspect}"
  end
end

# Load Module/Class from yaml tag.
class Module
  def yaml_tag_read_class(name)
    name.constantize
    name
  end
end
