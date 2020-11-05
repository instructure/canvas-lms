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

module Messages::AssignmentSubmittedLate
  class TwitterPresenter < Presenter
    def body
      if anonymous?
        I18n.t(
          "Canvas Alert - Late Anonymous Submission: %{assignment_name}",
          assignment_name: assignment.title
        )
      else
        I18n.t(
          "Canvas Alert - Late Submission: %{user_name}, %{assignment_name}",
          assignment_name: assignment.title,
          user_name: submission.user.name
        )
      end
    end
  end
end
