require 'active_model'

module LtiAdvantage::Claims
  # Class represeting an LTI 1.3 message "launch_presentation" claim.
  # https://purl.imsglobal.org/spec/lti/claim/launch_presentation
  class LaunchPresentation
    include ActiveModel::Model

    attr_accessor :document_target, :height, :locale, :return_url, :width
  end
end
