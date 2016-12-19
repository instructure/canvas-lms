#
# Copyright (C) 2012 Instructure, Inc.
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

class AssignmentOverrideStudent < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :assignment_override
  belongs_to :user
  belongs_to :quiz, class_name: 'Quizzes::Quiz'

  after_save :destroy_override_if_needed
  after_destroy :destroy_override_if_needed

  strong_params

  validates_presence_of :assignment_override, :user
  validates_uniqueness_of :user_id, :scope => [:assignment_id, :quiz_id],
    :message => 'already belongs to an assignment override'

  validate :assignment_override do |record|
    if record.assignment_override && record.assignment_override.set_type != 'ADHOC'
      record.errors.add :assignment_override, "is not adhoc"
    end
  end

  validate :assignment do |record|
    if record.assignment_override && record.assignment_id != record.assignment_override.assignment_id
      record.errors.add :assignment, "doesn't match assignment_override"
    end
  end

  validate :user do |record|
    if record.user && record.context_id && !record.user.student_enrollments.shard(record.shard).where(:course_id => record.context_id).exists?
      record.errors.add :user, "is not in the assignment's course"
    end
  end

  validate do |record|
    if [record.assignment, record.quiz].all?(&:nil?)
      record.errors.add :base, "requires assignment or quiz"
    end
  end

  def context_id
    if quiz
      quiz.reload if quiz.id != quiz_id
      quiz.context_id
    elsif assignment
      assignment.reload if assignment.id != assignment_id
      assignment.context_id
    end
  end

  before_validation :default_values
  def default_values
    if assignment_override
      self.assignment_id = assignment_override.assignment_id
      self.quiz_id = assignment_override.quiz_id
    end
  end
  protected :default_values

  def destroy_override_if_needed
    assignment_override.destroy_if_empty_set
  end
  protected :destroy_override_if_needed

  def self.clean_up_for_assignment(assignment)
    return unless assignment.context_type == "Course"
    return if assignment.new_record?

    valid_student_ids = Enrollment
      .where(course_id: assignment.context_id)
      .where.not(workflow_state: "deleted")
      .pluck(:user_id)

    AssignmentOverrideStudent
      .where(assignment: assignment)
      .where.not(user_id: valid_student_ids)
      .each(&:destroy)
  end
end
