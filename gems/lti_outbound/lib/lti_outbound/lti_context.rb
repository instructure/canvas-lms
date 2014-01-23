module LtiOutbound
  class LTIContext < LTIModel
    attr_accessor :root_account, :opaque_identifier, :id, :sis_source_id

    add_variable_mapping '.id', :id
    add_variable_mapping '.sisSourceId', :sis_source_id
  end
end