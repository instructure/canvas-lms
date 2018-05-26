#
# Copyright (C) 2018 - present Instructure, Inc.
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

# @API Moderated Grading
# @subtopic Anonymous Provisional Grades
# @beta
#
class AnonymousProvisionalGradesController < ProvisionalGradesBaseController
  # @API Show provisional grade status for a student
  #
  # Determine whether or not the student's submission needs one or more provisional grades.
  #
  # @argument anonymous_id [String]
  #   The id of the student to show the status for
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/1/assignments/2/anonymous_provisional_grades/status?anonymous_id=1'
  #
  # @example_response
  #
  #       { "needs_provisional_grade": false }
  #
  def status
    @student = @context.submissions.find_by!(anonymous_id: params.fetch(:anonymous_id)).user
    super
  end
end
