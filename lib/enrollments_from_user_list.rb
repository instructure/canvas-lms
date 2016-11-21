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
    raise ArgumentError, "Must provide a UserList or Array (of user ids)" unless list.is_a?(UserList) || list.is_a?(Array)
    @enrollments = []
    @user_ids_to_touch = []

    users =
      if list.is_a?(UserList)
        list.addresses.slice!(0,@limit) if @limit
        list.users
      else
        # list of user ids
        User.where(:id => list).to_a
      end
    users.each_slice(Setting.get('enrollments_from_user_list_batch_size', 50).to_i) do |users|
      @course.transaction do
        Enrollment.suspend_callbacks(:update_cached_due_dates) do
          users.each { |user| enroll_user(user) }
        end
      end
    end
    if !@enrollments.empty?
      @course.transaction do
        DueDateCacher.recompute_course(@course)
      end
    end
    @user_ids_to_touch.uniq.each_slice(100) do |user_ids|
      User.where(id: user_ids).touch_all
    end

    @enrollments
  end

  protected

  def enroll_user(user)
    return unless user
    return if @enrolled_users.has_key?(user.id)
    @enrolled_users[user.id] = true
    enrollment = @course.enroll_user(user, @enrollment_type,
                        :section => @section,
                        :limit_privileges_to_course_section => @limit_privileges_to_course_section,
                        :allow_multiple_enrollments => true,
                        :role => @role,
                        :skip_touch_user => true)
    if enrollment
      @enrollments << enrollment
      if enrollment.need_touch_user
        @user_ids_to_touch << enrollment.user_id
        @user_ids_to_touch << enrollment.associated_user_id if enrollment.associated_user_id
      end
    end
  end
end
