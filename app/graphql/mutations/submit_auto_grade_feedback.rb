# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

class Mutations::SubmitAutoGradeFeedback < Mutations::BaseAiFeedback
  argument :course_id, ID, required: true

  private

  def check_feature_and_permissions!(input)
    course_id = GraphQLHelpers.parse_relay_or_legacy_id(input[:course_id], "Course")
    course = Course.find(course_id)
    verify_authorized_action!(course, :manage_grades)

    unless course.feature_enabled?(:project_lhotse)
      raise GraphQL::ExecutionError, I18n.t("Grading Assistance is not enabled for this course.")
    end

    course.root_account.uuid
  end

  def feature_slug
    "grading-assistance-feedback"
  end
end
