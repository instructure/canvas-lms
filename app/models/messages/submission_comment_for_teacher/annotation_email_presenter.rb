#
# Copyright (C) 2019 - present Instructure, Inc.
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

module Messages::SubmissionCommentForTeacher
  class AnnotationEmailPresenter < AnnotationPresenter

    def subject
      if anonymous?
        I18n.t(
          "Anonymous Submission Annotation: Student (%{id}), %{assignment_title}, %{course_name}",
          assignment_title: assignment.title,
          course_name: course.name,
          id: submission.anonymous_id
        )
      else
        I18n.t(
          "Submission Annotation: %{user_name}, %{assignment_title}, %{course_name}",
          assignment_title: assignment.title,
          course_name: course.name,
          user_name: submission.user.short_name
        )
      end
    end

    def body
      if anonymous?
        I18n.t(
          "Someone just made a new annotation on the anonymous submission for Student (%{user_id}) for %{assignment_title}",
          assignment_title: assignment.title,
          user_id: submission.anonymous_id
        )
      else
        I18n.t(
          "%{author_name} just made a new annotation on the submission for %{user_name} for %{assignment_title}",
          assignment_title: assignment.title,
          author_name: data.author_name,
          user_name: submission.user.short_name
        )
      end
    end

  end
end
