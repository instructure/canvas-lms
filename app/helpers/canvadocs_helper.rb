# frozen_string_literal: true

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

module CanvadocsHelper
  include CoursesHelper

  private
  def canvadocs_session_url(user, annotation_context, submission)
    assignment = submission.assignment
    opts = {
      annotation_context: annotation_context.launch_id,
      anonymous_instructor_annotations: assignment.anonymous_instructor_annotations,
      enable_annotations: true,
      enrollment_type: canvadocs_user_role(assignment.course, user),
      moderated_grading_allow_list: submission.moderated_grading_allow_list(user),
      submission_id: submission.id
    }
    annotation_context.attachment.canvadoc_url(user, opts)
  end

  def canvadocs_user_name(user)
    user.short_name.delete(',')
  end

  def canvadocs_user_id(user)
    user.global_id.to_s
  end

  def canvadocs_user_role(course, user, enrollments=nil)
    user_type(course, user, enrollments)
  end
end
