require 'active_model'

module LtiAdvantage::Claims
  # Class represeting an LTI 1.3 message "context" claim.
  # https://purl.imsglobal.org/spec/lti/claim/context
  class Context
    include ActiveModel::Model
    attr_accessor :id, :label, :title, :type
    validates_presence_of :id

  end
end
