require 'active_model'

module LtiAdvantage::Claims
  # Class represeting an LTI 1.3 message "lis" claim.
  # https://purl.imsglobal.org/spec/lti/claim/lis
  class Lis
    include ActiveModel::Model

    attr_accessor :course_offering_sourcedid, :course_section_sourcedid, :person_sourcedid

  end
end
