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
  # A "factory" class that builds an ID Token (JWT) to be used in LTI Advantage
  # Platform Notices. These messages are sent to tools separately from the launch
  # process to inform tools about events in the platform
  #
  # This class relies on a another class (LtiAdvantage::Messages::PnsNotice)
  # to model the data in the JWT body and produce a signature.
  class AssetProcessorSettingsRequest < JwtMessage
    def initialize(tool:, context:, user:, expander:, return_url:, asset_processor:, opts: {})
      super(tool:, context:, user:, expander:, return_url:, opts:)
      raise ArgumentError, "asset_processor is required" unless asset_processor

      @asset_processor = asset_processor
      @message = LtiAdvantage::Messages::AssetProcessorSettingsRequest.new
    end

    def generate_post_payload_message
      add_activity_claim!
      super(validate_launch: true)
    end

    def add_activity_claim!
      @message.activity.id = @asset_processor.assignment.lti_context_id
      @message.activity.title = @asset_processor.assignment.title
    end
  end
end
