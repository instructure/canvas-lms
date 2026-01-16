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

module Api::V1::AiExperience
  include Api::V1::Json

  API_JSON_OPTS = {
    only: %w[id title description facts learning_objective pedagogical_guidance workflow_state course_id created_at updated_at]
  }.freeze

  def ai_experience_json(ai_experience, user, session, opts = {})
    json = api_json(ai_experience, user, session, opts.merge(API_JSON_OPTS))
    # Include can_manage permission if provided
    json[:can_manage] = opts[:can_manage] if opts.key?(:can_manage)
    json
  end

  def ai_experiences_json(ai_experiences, user, session, opts = {})
    ai_experiences.map do |ai_experience|
      ai_experience_json(ai_experience, user, session, opts)
    end
  end
end
