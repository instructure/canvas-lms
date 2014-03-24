#
# Copyright (C) 2012 Instructure, Inc.
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
#

module Api::V1::QuizGroup
  include Api::V1::Json

  API_ALLOWED_QUIZ_GROUP_OUTPUT_FIELDS = {
    :only => %w(
      id
      quiz_id
      name
      pick_count
      question_points
      assessment_question_bank_id
      position
      )
  }

  API_ALLOWED_QUIZ_INPUT_FIELDS = {
    :only => %w(
      name
      pick_count
      question_points
      assessment_question_bank_id
      position
      )
  }

  def quiz_groups_compound_json(quiz_groups, context, user, session)
    { quiz_groups: quiz_groups_json(quiz_groups, context, user, session) }
  end

  def quiz_groups_json(quiz_groups, context, user, session)
    quiz_groups.map do |quiz_group|
      quiz_group_json(quiz_group, context, user, session)
    end
  end

  def quiz_group_json(quiz_group, context, user, session)
    api_json(quiz_group, user, session, API_ALLOWED_QUIZ_GROUP_OUTPUT_FIELDS)
  end

  def filter_params(quiz_group_params)
    quiz_group_params.slice(*API_ALLOWED_QUIZ_INPUT_FIELDS[:only])
  end

  def update_api_quiz_group(quiz_group, quiz_group_params)
    return nil unless quiz_group.is_a?(Quizzes::QuizGroup) && quiz_group_params.is_a?(Hash)

    quiz_group.attributes = filter_params(quiz_group_params)
    quiz_group.save
  end

end
