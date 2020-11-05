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

module Messages::AssignmentSubmitted
  class SummaryPresenter < Presenter
    include TextHelper

    def subject
      if anonymous?
        I18n.t(
          "Anonymous Submission: %{assignment_title}",
          assignment_title: assignment.title
        )
      else
        I18n.t(
          "Submission: %{user_name}, %{assignment_title}",
          assignment_title: assignment.title,
          user_name: submission.user.name
        )
      end
    end

    def body
      I18n.t(
        "turned in: %{submission_date}",
        submission_date: datetime_string(message.force_zone(submission.submitted_at))
      )
    end
  end
end
