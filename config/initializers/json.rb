# JSON::Ext overwrites Rails' implemenation of these.
# And does dumb stuff instantiating a state object and temp buffer and crap
# which is really slow if you have 50,000 nil values.
# Just return teh constant values.
class NilClass
  def as_json(*args)
    self
  end

  def to_json(*args)
    'null'
  end
end

class FalseClass
  def as_json(*args)
    self
  end

  def to_json(*args)
    'false'
  end
end

class TrueClass
  def as_json(*args)
    self
  end

  def to_json(*args)
    'true'
  end
end

# This changes a "perfect" reference check for a fast one.  If you see this
# exception, you can comment this out, and then the actual rails code will
# raise a similar exception on the very first duplicate object, to help you
# pinpoint the problem.
ActiveSupport::JSON::Encoding.module_eval do
  def self.encode(value, options = nil)
    options = {} unless Hash === options
    depth = (options[:recursion_depth] ||= 1)
    raise CircularReferenceError, 'something references itself (probably)' if depth > 1000
    options[:recursion_depth] = depth + 1
    Api.stringify_json_ids(value) if options[:stringify_json_ids]
    value.to_json(options)
  ensure
    options[:recursion_depth] = depth
  end
end
