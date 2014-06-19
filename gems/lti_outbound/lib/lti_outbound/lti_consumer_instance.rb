module LtiOutbound
  class LTIConsumerInstance < LTIContext
    proc_accessor :lti_guid, :name, :domain
  end
end
