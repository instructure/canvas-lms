# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
module LtiAdvantage::Messages
  # Class represeting an LTI 1.3 ReportReviewRequest.
  class ReportReviewRequest < JwtMessage
    MESSAGE_TYPE = "LtiReportReviewRequest"
    # Required claims for this message type
    REQUIRED_CLAIMS = (superclass::REQUIRED_CLAIMS + %i[
      activity
      for_user
      submission
      asset
      assetreport_type
    ]).freeze

    TYPED_ATTRIBUTES = superclass::TYPED_ATTRIBUTES.merge(
      submission: LtiAdvantage::Claims::Submission,
      for_user: LtiAdvantage::Claims::ForUser,
      asset: LtiAdvantage::Claims::Asset
    ).freeze

    attr_accessor(*(REQUIRED_CLAIMS - [:activity]))

    validates_presence_of(*REQUIRED_CLAIMS)
    validates_with LtiAdvantage::TypeValidator

    # Returns a new instance of ReportReviewRequest.
    #
    # @param [Hash] attributes for message initialization.
    # @return [ReportReviewRequest]
    def initialize(params = {})
      self.message_type = MESSAGE_TYPE
      self.version = "1.3.0"
      super
    end

    def submission
      @submission ||= TYPED_ATTRIBUTES[:submission].new
    end

    def for_user
      @for_user ||= TYPED_ATTRIBUTES[:for_user].new
    end

    def asset
      @asset ||= TYPED_ATTRIBUTES[:asset].new
    end
  end
end
