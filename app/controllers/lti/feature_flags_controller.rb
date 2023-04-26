# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module Lti
  # @API LTI Advantage Feature Flags
  # @internal
  #
  # Feature flag API for LTI Advantage tools.
  #
  # @model FeatureFlag
  #     {
  #       "id": "FeatureFlag",
  #       "description": "A canvas feature flag.",
  #       "properties": {
  #         "state": {
  #           "description": "The current state of the feature flag",
  #           "example": "on",
  #           "type": "string"
  #         },
  #         "name": {
  #           "description": "The name of the feature flag",
  #           "example": "New Feature",
  #           "type": "string"
  #         }
  #       }
  #     }
  #
  class FeatureFlagsController < ApplicationController
    include ::Lti::IMS::Concerns::AdvantageServices
    MIME_TYPE = "application/vnd.canvas.featureflags+json"

    ACTION_SCOPE_MATCHERS = {
      show: all_of(TokenScopes::LTI_SHOW_FEATURE_FLAG_SCOPE),
    }.freeze.with_indifferent_access

    # @API Show the specified feature flag
    #
    # @returns FeatureFlag
    def show
      render json: feature, content_type: MIME_TYPE
    end

    private

    def lti_service_context
      @lti_service_context ||= if params.include?(:account_id)
                                 context_from_id(Account, params[:account_id])
                               else
                                 context_from_id(Course, params[:course_id])
                               end
    end

    def context_from_id(context_type, context_id)
      # If the id is an integer, it's a Canvas id, not an LTI id
      column_name = (context_id.to_i.to_s == context_id) ? :id : :lti_context_id
      context_type.find_by(column_name => context_id)
    end

    def feature
      context.lookup_feature_flag(params.require(:feature)) || Account.site_admin.lookup_feature_flag(params.require(:feature))
    rescue => e
      raise e.message.include?("no such feature") ? ActiveRecord::RecordNotFound : e
    end

    def scopes_matcher
      ACTION_SCOPE_MATCHERS.fetch(action_name, self.class.none)
    end

    def context
      lti_service_context
    end
  end
end
