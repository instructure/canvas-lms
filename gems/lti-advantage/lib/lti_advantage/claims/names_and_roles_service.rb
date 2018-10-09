require 'active_model'

module LtiAdvantage::Claims
  # Class represeting an LTI 1.3 message "nameroleservice" claim.
  # https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice
  class NamesAndRolesService
    include ActiveModel::Model

    attr_accessor :context_memberships_url,
                  :service_versions

    validates_presence_of :context_memberships_url, :service_versions
  end
end
