# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

class GradesPresenter
  def initialize(enrollments)
    @enrollments = enrollments
  end

  def student_enrollments
    @student_enrollments ||= begin
      current_enrollments.select { |e| e.student? }.index_by { |e| e.course }
    end
  end

  def observed_enrollments
    @observed_enrollments ||= begin
      observer_enrollments.map { |e|
        e.shard.activate do
          StudentEnrollment.active.where(user_id: e.associated_user_id, course_id: e.course_id).first
        end
      }.uniq.compact
    end
  end

  def course_grade_summaries
    @course_grade_summaries ||= begin
      summaries = {}
      Shard.partition_by_shard(teacher_enrollments) do |sharded_enrollments|
        # This should probably be rewritten to index by the courses' global_id, but that would require changes else
        # where in the presenter as well.
        summaries.merge!(
          CourseScoreStatistic.where(course_id: sharded_enrollments.map(&:course_id)).index_by(&:course_id)
        )
      end
      # The erb that uses this expects a value for all course ids in the hash. Since they aren't interesting enough to
      # store, we'll make them the empty case default value for the hash. Since its only used in a read only capacity
      # they can be all the exact same object.
      summaries.each_with_object(Hash.new({ score: nil, students: 0 })) do |(key, value), memo|
        memo[key] = value.grades_presenter_hash
      end
    end
  end

  def teacher_enrollments
    @teacher_enrollments ||= current_enrollments.select { |e| e.instructor? }.index_by { |e| e.course }.values
  end

  def prior_enrollments
    []
  end

  def has_single_enrollment?
    student_enrollments.length + teacher_enrollments.length + observed_enrollments.length == 1
  end

  def single_enrollment
    student_enrollments.values.first || teacher_enrollments.first || observed_enrollments.first
  end

  private

  def observer_enrollments
    @observer_enrollments ||= begin
      current_enrollments.select { |e| e.is_a?(ObserverEnrollment) && e.associated_user_id }
    end
  end

  def current_enrollments
    @current_enrollments ||= begin
      @enrollments.select { |e| e.state_based_on_date == :active }
    end
  end

end
