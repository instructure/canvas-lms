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

def assignment_model(opts={})
  if opts[:course]
    course = opts.delete(:course)
  else
    course = course_model(:reusable => true)
  end
  # turn the group_category title into a group category "object"
  group_category = opts.delete(:group_category)
  @group_category = course.group_categories.create(:name => group_category) if group_category
  opts[:group_category] = @group_category if @group_category
  @assignment = factory_with_protected_attributes(course.assignments, assignment_valid_attributes.merge(opts))
  @assignment.context.should eql(course) rescue false
  @a = @assignment
  @c = course
  @a
end

def assignment_valid_attributes
  {
    :title => "value for title",
    :description => "value for description",
    :due_at => Time.now,
    :points_possible => "1.5"
  }
end
