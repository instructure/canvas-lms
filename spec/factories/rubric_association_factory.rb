#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Factories
  def rubric_association_model(opts={})
    course = (opts[:context] if opts[:context].is_a? Course) || @course || course_model(reusable: true)
    context = opts[:context] || course
    @rubric = opts[:rubric] || rubric_model(context: context)
    @rubric_association_object = opts[:association_object] ||
      course.assignments.first ||
      course.assignments.create!(assignment_valid_attributes)
    @rubric_association = @rubric.rubric_associations.create!(valid_rubric_assessment_attributes.merge(:association_object =>  @rubric_association_object, context: context, :purpose => opts[:purpose] || "none"))
  end

  def valid_rubric_assessment_attributes
    {
    }
  end
end
