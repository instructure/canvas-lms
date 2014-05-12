module LtiOutbound
  class LTIConsumerInstance < LTIContext
    proc_accessor :lti_guid, :name, :domain

    add_variable_mapping '$Canvas.account.id', :id
    add_variable_mapping '$Canvas.account.sisSourceId', :sis_source_id
    add_variable_mapping '$Canvas.api.domain', :domain
  end
end
