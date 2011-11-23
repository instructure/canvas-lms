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
