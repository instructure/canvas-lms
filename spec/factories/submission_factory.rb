#
# Copyright (C) 2011 Instructure, Inc.
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

def submission_model(opts={})
  assignment_model
  @student = opts[:user] || User.create!(:name => "new student")
  @enrollment = @course.enroll_student(@student)
  @assignment.reload # it caches the course pre-student enrollment
  @submission = @assignment.submit_homework(@student, :url => "http://www.instructure.com/")
end

def assignment_valid_attributes
  {
    :title => "value for title",
    :description => "value for description",
    :due_at => Time.now,
    :points_possible => "1.5"
  }
end
