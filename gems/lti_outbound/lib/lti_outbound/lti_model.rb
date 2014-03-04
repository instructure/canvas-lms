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
  end
end