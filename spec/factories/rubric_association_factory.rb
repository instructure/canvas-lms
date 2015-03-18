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

def rubric_association_model(opts={})
  course_model(:reusable => true) unless @course || opts[:context]
  @rubric = opts[:rubric] || rubric_model(:context => opts[:context] || @course)
  @rubric_association_object = opts[:association_object] ||
    @course.assignments.first ||
    @course.assignments.create!(assignment_valid_attributes)
  @rubric_association = @rubric.rubric_associations.create!(valid_rubric_assessment_attributes.merge(:association_object =>  @rubric_association_object, :context => opts[:context] || @course, :purpose => opts[:purpose] || "none"))
end

def valid_rubric_assessment_attributes
  {
  }
end
