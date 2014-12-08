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

class EnrollmentsFromUserList
  class << self
    def process(list, course, opts={})
      EnrollmentsFromUserList.new(course, opts).process(list)
    end
  end
  
  attr_reader :students, :course
  
  def initialize(course, opts={})
    @course = course
    @enrollment_type = opts[:enrollment_type] || 'StudentEnrollment'
    @role = opts[:role]
    @limit = opts[:limit]
    @section = (opts[:course_section_id].present? ? @course.course_sections.active.where(id: opts[:course_section_id].to_i).first : nil) || @course.default_section
    @limit_privileges_to_course_section = opts[:limit_privileges_to_course_section]
    @enrolled_users = {}
  end
  
  def process(list)
    raise ArgumentError, "Must provide a UserList" unless list.is_a?(UserList)
    @enrollments = []

    list.addresses.slice!(0,@limit) if @limit
    @course.transaction do
      Enrollment.suspend_callbacks(:update_cached_due_dates) do
        list.users.each { |user| enroll_user(user) }
      end
      if !@enrollments.empty?
        DueDateCacher.recompute_course(@course)
      end
    end
    @enrollments
  end
  
  protected
  
  def enroll_user(user)
    return unless user
    return if @enrolled_users.has_key?(user.id)
    @enrolled_users[user.id] = true
    @course.enroll_user(user, @enrollment_type, :section => @section, :limit_privileges_to_course_section => @limit_privileges_to_course_section, :role => @role).tap do |e|
      @enrollments << e if e
    end
  end
end
