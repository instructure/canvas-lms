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

module Lti
  class AssetProcessorController < ApplicationController
    before_action { require_feature_enabled :lti_asset_processor }
    before_action :require_user
    before_action :require_asset_processor
    before_action :require_context
    before_action :require_access_to_context
    before_action :require_submission

    def resubmit_notice
      Lti::AssetProcessorNotifier.notify_asset_processors(
        submission,
        asset_processor
      )
      head :no_content
    end

    def assignment
      asset_processor.assignment
    end

    def asset_processor_id
      params.require(:asset_processor_id)
    end

    def asset_processor
      @asset_processor ||= Lti::AssetProcessor.find(asset_processor_id)
    end

    def require_asset_processor
      not_found unless asset_processor
    end

    def context
      @context ||= assignment.context
    end

    def require_context
      not_found unless assignment&.context
    end

    def require_access_to_context
      return if context.is_a?(Course) && context.grants_any_right?(@current_user, session, :manage_grades, :view_all_grades)

      render status: :forbidden, plain: "invalid_request"
    end

    def student_id
      params.require(:student_id)
    end

    def student
      @student ||= User.find_by(id: student_id)
    end

    # "latest", 0, or any invalid value will be treated as latest
    def attempt
      @params ||= params[:attempt].to_i
    end

    def submission
      @submission ||=
        begin
          sub = assignment.submission_for_student(student)
          if attempt.positive?
            version = sub.versions.find { |s| s.model.attempt == attempt }&.model
          end

          version || sub
        end
    end

    def require_submission
      not_found unless student && assignment.assigned?(student)
    end
  end
end
