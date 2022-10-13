# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class CoursePacing::PaceContextsApiController < ApplicationController
  before_action :require_feature_flag
  before_action :require_context
  before_action :ensure_pacing_enabled
  before_action :authorize_action
  before_action :load_type

  PERMITTED_CONTEXT_TYPES = %w[course section student_enrollment].freeze

  def index
    contexts = CoursePacing::PaceContextsService.new(@context).contexts_of_type(@type)
    paginated_contexts = Api.paginate(contexts, self, api_v1_pace_contexts_url, total_entries: contexts.count)
    render json: {
      pace_contexts: paginated_contexts.map { |c| CoursePacing::PaceContextsPresenter.as_json(c) }
    }
  end

  private

  def require_feature_flag
    not_found unless Account.site_admin.feature_enabled?(:course_paces_redesign)
  end

  def ensure_pacing_enabled
    not_found unless @context.enable_course_paces
  end

  def authorize_action
    authorized_action(@context, @current_user, :manage_content)
  end

  def load_type
    @type = params["type"]
    head :bad_request unless PERMITTED_CONTEXT_TYPES.include?(@type)
  end
end
