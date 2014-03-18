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

def course_model(opts={})
  allow_reusable = opts.delete :reusable
  # if !@course && ReusableCourse.reusable_course && allow_reusable && opts.empty?
    # @course = ReusableCourse.reusable_course 
  # else
    @course = factory_with_protected_attributes(Course, course_valid_attributes.merge(opts))
    # ReusableCourse.reusable_course ||= @course
  # end
  # if @course == ReusableCourse.reusable_course && ReusableCourse.reusable_teacher && allow_reusable
    # @teacher = ReusableCourse.reusable_teacher
  # else
    @teacher = user_model
    e = @course.enroll_teacher(@teacher)
    e.accept
    # ReusableCourse.reusable_teacher ||= @teacher
  # end
  @user = @teacher
  @course
end

def course_valid_attributes
  {
    :name => 'value for name',
    :group_weighting_scheme => 'value for group_weighting_scheme',
    :start_at => Time.now,
    :conclude_at => Time.now + 100,
    :is_public => true,
    :allow_student_wiki_edits => true,
  }
end

class ReusableCourse
  cattr_accessor :reusable_course
  cattr_accessor :reusable_teacher
end
