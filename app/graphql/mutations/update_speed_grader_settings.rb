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
#

class Mutations::UpdateSpeedGraderSettings < Mutations::BaseMutation
  argument :grade_by_question, Boolean, required: true

  field :speed_grader_settings, Types::SpeedGraderSettingsType, null: false

  def resolve(input:)
    unless current_user.grants_right?(current_user, :update_speed_grader_settings)
      raise GraphQL::ExecutionError, "Not authorized to update speed grader settings"
    end

    current_user.preferences[:enable_speedgrader_grade_by_question] = input.fetch(:grade_by_question)
    current_user.save!
    current_user
  end
end
