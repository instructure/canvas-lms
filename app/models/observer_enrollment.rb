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

class ObserverEnrollment < Enrollment
  def observer?
    true
  end

  # returns a hash mapping students to arrays of enrollments
  def self.observed_students(context, current_user)
    TempCache.cache(:observed_students, context, current_user) do
      context.shard.activate do
        observer_enrollments = context.observer_enrollments.where("user_id=? AND associated_user_id IS NOT NULL", current_user)
        observed_students = {}
        observer_enrollments.each do |e|
          student_enrollment = StudentEnrollment.active.where(user_id: e.associated_user_id, course_id: e.course_id).first
          next unless student_enrollment
          student = student_enrollment.user
          observed_students[student] ||= []
          observed_students[student] << student_enrollment
        end
        observed_students
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
    obs_hash = connection.select_all( ObserverEnrollment.where(course_id: course, user_id: observers).select([:user_id, :associated_user_id])).group_by{|record| record["user_id"]}
    obs_hash.keys.each{ |key|
      obs_hash[key.to_i] = obs_hash.delete(key).map{|v|
        v["associated_user_id"].try(:to_i)
      }.compact
    }
    # should look something like this: {10 => [11,12,13], 20 => [11,24,32]}
    obs_hash
  end
end
