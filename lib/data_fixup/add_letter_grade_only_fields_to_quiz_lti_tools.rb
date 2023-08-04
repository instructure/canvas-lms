# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module DataFixup::AddLetterGradeOnlyFieldsToQuizLtiTools
  def self.run
    ContextExternalTool.quiz_lti.find_each do |quiz_lti_tool|
      lgo_fields = {
        "canvas_assignment_restrict_quantitative_data" => "$com.instructure.Assignment.restrict_quantitative_data",
        "canvas_course_grading_scheme" => "$com.instructure.Course.gradingScheme",
      }
      quiz_lti_tool.custom_fields = quiz_lti_tool.custom_fields.merge(lgo_fields)
      quiz_lti_tool.save! if quiz_lti_tool.changed?
    end
  end
end
