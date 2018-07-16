require 'active_model'

module LtiAdvantage::Claims
  # Class represeting an LTI 1.3 message "resource_link" claim.
  # https://purl.imsglobal.org/spec/lti/claim/resource_link
  class ResourceLink
    include ActiveModel::Model

    attr_accessor :description, :id, :title
    validates_presence_of :id

  end
end
