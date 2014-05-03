module LtiOutbound
  class LTIContext < LTIModel
    attr_accessor :consumer_instance, :opaque_identifier, :id, :sis_source_id, :name
  end
end