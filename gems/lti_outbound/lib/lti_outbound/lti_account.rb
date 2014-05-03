module LtiOutbound
  class LTIAccount < LTIContext
    add_variable_mapping '$Canvas.account.id', :id
    add_variable_mapping '$Canvas.account.sisSourceId', :sis_source_id
  end
end
