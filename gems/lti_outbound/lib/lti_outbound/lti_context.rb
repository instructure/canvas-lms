module LtiOutbound
  class LTIContext < LTIModel
    proc_accessor :consumer_instance, :opaque_identifier, :id, :sis_source_id, :name
  end
end