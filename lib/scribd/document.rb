module Scribd
  class Document
    def ==(o)
      return false unless o.is_a?(Scribd::Document)
      (self.instance_variables + o.instance_variables).uniq.all?{|iv| self.instance_variable_get(iv) == o.instance_variable_get(iv) }
    end
  end
end
