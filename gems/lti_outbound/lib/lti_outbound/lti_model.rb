module LtiOutbound
  class LTIModel
    class << self
      attr_accessor :substititions
    end

    def variable_substitution_mapping(placeholder)
      self.class.substititions ||= {}
      self.class.substititions[placeholder] && send(self.class.substititions[placeholder])
    end

    def has_variable_mapping?(placeholder)
      self.class.substititions ||= {}
      !!self.class.substititions[placeholder]
    end

    protected

    def self.add_variable_mapping(placeholder, substitution_method)
      @substititions ||= {}
      @substititions[placeholder] = substitution_method
    end

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