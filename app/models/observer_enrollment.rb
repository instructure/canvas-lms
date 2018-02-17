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

class ObserverEnrollment < Enrollment
  def observer?
    true
  end

  def self.observed_enrollments_for_courses(contexts, user)
    contexts = Array(contexts)
    observed_students = []
    Shard.partition_by_shard(contexts) do |sharded_contexts|
      observer_enrollment_data = user.observer_enrollments.where(course_id: sharded_contexts)
        .where('associated_user_id IS NOT NULL').pluck(:course_id, :associated_user_id)

      observer_enrollment_data.group_by(&:first).each do |course_id, course_enroll_data|
        associated_user_ids = course_enroll_data.map(&:last)
        students = StudentEnrollment.active.where(user_id: associated_user_ids, course_id: course_id)
        observed_students.concat(students)
      end
    end
    observed_students
  end

  def self.observed_enrollments_for_enrollments(observer_enrollments, active_by_date: false)
    # if we already have the enrollments why go and fetch them again
    observer_enrollments = Array(observer_enrollments)
    observed_student_enrollments = []
    Shard.partition_by_shard(observer_enrollments) do |sharded_observer_enrollments|
      sharded_observer_enrollments.group_by(&:course_id).each do |course_id, enrollments|
        associated_user_ids = enrollments.map(&:associated_user_id)
        student_enrolls = StudentEnrollment.active.where(user_id: associated_user_ids, course_id: course_id)
        student_enrolls = student_enrolls.active_by_date if active_by_date
        observed_student_enrollments.concat(student_enrolls.to_a)
      end
    end
    observed_student_enrollments
  end

  # returns a hash mapping students to arrays of enrollments
  def self.observed_students(context, current_user)
    RequestCache.cache(:observed_students, context, current_user) do
      context.shard.activate do
        associated_user_ids = context.observer_enrollments.where(user_id: current_user).
          where("associated_user_id IS NOT NULL").select(:associated_user_id)
        context.student_enrollments.
          where(user_id: associated_user_ids).group_by(&:user)
      end
    end
  end

  # note: naively finding users by these ID's may not work due to sharding
  def self.observed_student_ids(context, current_user)
    context.shard.activate do
      context.observer_enrollments.where("user_id=? AND associated_user_id IS NOT NULL", current_user).pluck(:associated_user_id)
    end
  end

  def self.observed_student_ids_by_observer_id(course, observers)
    # select_all allows plucking multiplecolumns without instantiating AR objects
    obs_hash = {}

    ObserverEnrollment.where(course_id: course, user_id: observers).
      pluck(:user_id, :associated_user_id).each do |user_id, associated_user_id|

      obs_hash[user_id] ||= []
      obs_hash[user_id] << associated_user_id if associated_user_id
    end

    # should look something like this: {10 => [11,12,13], 20 => [11,24,32]}
    obs_hash
  end
end
