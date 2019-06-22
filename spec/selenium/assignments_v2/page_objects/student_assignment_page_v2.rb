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

require_relative '../../common'

class StudentAssignmentPageV2
  class << self
    include SeleniumDependencies

    def visit(course, assignment)
      get "/courses/#{course.id}/assignments/#{assignment.id}/?assignments_2=true"
    end

    def assignment_locked_image
      f("img[alt='Assignment Locked']")
    end

    def lock_icon
      f("svg[name='IconLock']")
    end

    def details_toggle_css
      "button[data-test-id='assignments-2-assignment-toggle-details']"
    end
  end
end