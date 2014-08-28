module LtiOutbound
  class LTIModel
    protected

    def self.proc_accessor(*methods)
      attr_writer(*methods)
      proc_writer(*methods)
    end

    def self.proc_writer(*methods)
      methods.each do |method|
        define_method(method) do
          variable_name = "@#{method}"
          value = self.instance_variable_get(variable_name)
          if value.is_a?(Proc)
            value = value.call
            self.instance_variable_set(variable_name, value)
          end
          return value
        end
      end
    end
  end
end