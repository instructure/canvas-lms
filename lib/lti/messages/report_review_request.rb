# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module Lti::Messages
  # A "factory" class that builds an ID Token (JWT) to be used in
  # 1EdTech LTI Asset Processor Report Review Request launches.
  #
  # This class relies on a another class (LtiAdvantage::Messages::ReportReviewRequest)
  # to model the data in the JWT body and produce a signature.
  class ReportReviewRequest < JwtMessage
    def initialize(tool:, context:, user:, expander:, return_url:, asset_report:, opts: {})
      super(tool:, context:, user:, expander:, return_url:, opts:)
      raise ArgumentError, "asset_report is required" unless asset_report

      @asset_report = asset_report
      @message = LtiAdvantage::Messages::ReportReviewRequest.new
    end

    def generate_post_payload_message
      add_activity_claim!
      add_submissions_claim!
      add_assetreport_type_claim!
      add_for_user_claim!
      add_asset_claim!
      super(validate_launch: true)
    end

    private

    def add_activity_claim!
      @message.activity.id = submission.assignment.lti_context_id
      @message.activity.title = submission.assignment.title
    end

    def add_submissions_claim!
      @message.submission.id =  submission.lti_attempt_id(@opts[:submission_attempt])
    end

    def add_assetreport_type_claim!
      @message.assetreport_type = @asset_report.report_type
    end

    def add_for_user_claim!
      @message.for_user.user_id = @user.lti_id
    end

    def add_asset_claim!
      @message.asset.id = @asset_report.asset.uuid
    end

    def submission
      @submission ||= @asset_report.asset.submission
    end

    def assignment
      @assignment ||= submission.assignment
    end

    def unexpanded_custom_parameters
      super.merge(@asset_report.asset_processor.report_custom_variables)
    end
  end
end
