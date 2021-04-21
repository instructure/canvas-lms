# frozen_string_literal: true

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
  class SMSPresenter < Presenter
    def subject
      if anonymous?
        if anonymous_author_id.present?
          I18n.t(
            "New anonymous comment by Student (%{author_id}) for %{assignment_title}, Student (%{user_id}), %{course_name}.",
            assignment_title: assignment.title,
            author_id: anonymous_author_id,
            course_name: course.name,
            user_id: submission.anonymous_id
          )
        else
          I18n.t(
            "New anonymous comment for %{assignment_title}, Student (%{user_id}), %{course_name}.",
            assignment_title: assignment.title,
            course_name: course.name,
            user_id: submission.anonymous_id
          )
        end
      else
        I18n.t(
          "New comment by %{author_name} for %{assignment_title}, %{user_name}, %{course_name}.",
          assignment_title: assignment.title,
          author_name: submission_comment.author.name,
          course_name: course.name,
          user_name: submission.user.short_name
        )
      end
    end

    def body
      I18n.t(
        "More info at %{web_address}",
        web_address: HostUrl.context_host(assignment.context)
      )
    end
  end
end
