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
  include Api::V1::User

  API_JSON_OPTS = {
    only: %w[id title description facts learning_objective pedagogical_guidance workflow_state course_id created_at updated_at]
  }.freeze

  CONVERSATION_JSON_OPTS = {
    only: %w[id llm_conversation_id workflow_state created_at updated_at user_id]
  }.freeze

  def ai_experience_json(ai_experience, user, session, opts = {})
    json = api_json(ai_experience, user, session, opts.merge(API_JSON_OPTS))
    json[:can_manage] = opts[:can_manage] if opts.key?(:can_manage)
    json[:submission_status] = opts[:submission_status] if opts.key?(:submission_status)
    json
  end

  def ai_experiences_json(ai_experiences, user, session, opts = {})
    ai_experiences.map do |ai_experience|
      ai_experience_json(ai_experience, user, session, opts)
    end
  end

  def ai_conversation_json(conversation, user, session, opts = {})
    json = api_json(conversation, user, session, opts.merge(CONVERSATION_JSON_OPTS))

    # Include student information if requested (for teacher view)
    if opts[:include_student] && conversation.user
      json[:student] = user_json(conversation.user, user, session, ["avatar_url"], @context)
    end

    # Include messages and progress if provided
    json[:messages] = opts[:messages] if opts[:messages]
    json[:progress] = opts[:progress] if opts[:progress]

    json
  end
end
