module BasicLtiOutbound
  class LTIModel
    def variable_substitution_mapping(placeholder)
      @@substititions ||= {}
      @@substititions[placeholder] && send(@@substititions[placeholder])
    end

    def has_variable_mapping?(placeholder)
      @@substititions ||= {}
      !!@@substititions[placeholder]
    end

    protected

    def self.add_variable_mapping(placeholder, substitution_method)
      @@substititions ||= {}
      @@substititions[placeholder] = substitution_method
    end
  end
end