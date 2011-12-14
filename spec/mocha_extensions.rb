# This chunk of monkey patching thanks to Simone Carletti,
# see https://github.com/floehopper/mocha/pull/19 for more information

module Mocha
  class Expectation
    def returns(*values, &block)
      @return_values += if block_given?
        ReturnValues.build(block)
      else
        ReturnValues.build(*values)
      end
      self
    end
  end

  class SingleReturnValue
    def evaluate
      if @value.is_a?(Proc)
        @value.call
      else
        @value
      end
    end
  end
end

# allows setting up mocks/stubs that will be automatically applied any time
# this AR instance is instantiated, through find or whatever
# the record must be saved before calling any_instantiation, so that it has an id
class ActiveRecord::Base
  @@any_instantiation = {}

  def self.reset_any_instantiation!
    @@any_instantiation = {}
  end

  def self.add_any_instantiation(ar_obj)
    raise(ArgumentError, "need to save first") if ar_obj.new_record?
    @@any_instantiation[ [ar_obj.class.base_ar_class, ar_obj.id] ] = ar_obj
    ar_obj
  end

  def self.instantiate_with_any_instantiation(a)
    if obj = @@any_instantiation[[base_ar_class, a['id'].to_i]]
      obj
    else
      instantiate_without_any_instantiation(a)
    end
  end
  class << self
    alias_method_chain :instantiate, :any_instantiation
  end

  def any_instantiation
    ActiveRecord::Base.add_any_instantiation(self)
  end
end
