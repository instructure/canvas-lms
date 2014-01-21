module BasicLtiOutbound
  class LTIAccount < LTIContext
    attr_accessor :lti_guid, :name, :domain

    add_variable_mapping ".domain", :domain
  end
end
