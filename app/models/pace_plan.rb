# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class PacePlan < ActiveRecord::Base
  include Workflow
  include Canvas::SoftDeletable

  extend RootAccountResolver
  resolves_root_account through: :course

  belongs_to :course, inverse_of: :pace_plans
  has_many :pace_plan_module_items, dependent: :destroy

  accepts_nested_attributes_for :pace_plan_module_items, allow_destroy: true

  belongs_to :course_section
  belongs_to :user
  belongs_to :root_account, class_name: 'Account'

  validates :course_id, presence: true
  validate :valid_secondary_context

  scope :primary, -> { not_deleted.where(course_section_id: nil, user_id: nil) }
  scope :for_section, ->(section) { where(course_section_id: section) }
  scope :for_user, ->(user) { where(user_id: user) }
  scope :not_deleted, -> { where.not(workflow_state: 'deleted') }
  scope :unpublished, -> { where(workflow_state: 'unpublished') }
  scope :published, -> { where(workflow_state: 'active').where.not(published_at: nil) }

  workflow do
    state :unpublished
    state :active
    state :deleted
  end

  set_policy do
    given { |user, session| self.course.grants_right?(user, session, :manage) }
    can :read
  end

  self.ignored_columns = %i[start_date]

  def valid_secondary_context
    if course_section_id.present? && user_id.present?
      self.errors.add(:base, "Only one of course_section_id and user_id can be given")
    end
  end

  def duplicate(opts = {})
    default_opts = {
      course_section_id: nil,
      user_id: nil,
      published_at: nil,
      workflow_state: 'unpublished'
    }
    pace_plan = self.dup
    pace_plan.attributes = default_opts.merge(opts)

    self.pace_plan_module_items.each do |pace_plan_module_item|
      pace_plan.pace_plan_module_items.new(
        module_item_id: pace_plan_module_item.module_item_id,
        duration: pace_plan_module_item.duration,
        root_account_id: pace_plan_module_item.root_account_id
      )
    end

    pace_plan
  end

  def publish(progress = nil)
    assignments_to_refresh = Set.new
    Assignment.suspend_due_date_caching do
      Assignment.suspend_grading_period_grade_recalculation do
        progress&.calculate_completion!(0, student_enrollments.size)
        student_enrollments.each do |enrollment|
          dates = PacePlanDueDatesCalculator.new(self).get_due_dates(pace_plan_module_items.not_deleted, enrollment)
          pace_plan_module_items.each do |pace_plan_module_item|
            content_tag = pace_plan_module_item.module_item
            assignment = content_tag.assignment
            next unless assignment

            due_at = dates[pace_plan_module_item.id]
            user_id = enrollment.user_id

            # Check for an old override
            current_override = assignment.assignment_overrides.active
                                         .where(set_type: 'ADHOC', due_at_overridden: true)
                                         .joins(:assignment_override_students)
                                         .find_by(assignment_override_students: { user_id: user_id })
            next if current_override&.due_at&.to_date == due_at

            # See if there is already an assignment override with the correct date
            due_time = CanvasTime.fancy_midnight(due_at.to_datetime).to_time
            due_range = (due_time - 1.second).round..due_time.round
            correct_date_override = assignment.assignment_overrides.active
                                              .find_by(set_type: 'ADHOC',
                                                       due_at_overridden: true,
                                                       due_at: due_range)

            # If it exists let's just add the student to it and remove them from the other
            if correct_date_override
              current_override&.assignment_override_students&.find_by(user_id: user_id)&.destroy
              correct_date_override.assignment_override_students.create(user_id: user_id, no_enrollment: false)
            elsif current_override&.assignment_override_students&.size == 1
              current_override.update(due_at: due_at.to_s)
            else
              current_override&.assignment_override_students&.find_by(user_id: user_id)&.destroy
              assignment.assignment_overrides.create!(
                set_type: 'ADHOC',
                due_at_overridden: true,
                due_at: due_at.to_s,
                assignment_override_students: [
                  AssignmentOverrideStudent.new(assignment: assignment, user_id: user_id, no_enrollment: false)
                ]
              )
            end

            # Remember content to refresh cache
            assignments_to_refresh << assignment
          end
          progress.increment_completion!(1) if progress&.total
        end
      end
    end

    # Clear caches
    Assignment.clear_cache_keys(assignments_to_refresh, :availability)
    DueDateCacher.recompute_course(course, assignments: assignments_to_refresh, update_grades: true)

    # Mark as published
    update(workflow_state: 'active', published_at: DateTime.current)
  end

  def student_enrollments
    @student_enrollments ||= if user_id
                               course.student_enrollments.where(user_id: user_id)
                             elsif course_section_id
                               student_pace_plan_user_ids = course.pace_plans.where.not(user_id: nil).pluck(:user_id)
                               course_section.student_enrollments.where.not(user_id: student_pace_plan_user_ids)
                             else
                               student_pace_plan_user_ids = course.pace_plans.where.not(user_id: nil).pluck(:user_id)
                               course_section_pace_plan_section_ids = course.pace_plans
                                                                            .where.not(course_section: nil)
                                                                            .pluck(:course_section_id)
                               course.student_enrollments
                                     .where.not(user_id: student_pace_plan_user_ids)
                                     .where.not(course_section_id: course_section_pace_plan_section_ids)
                             end
  end

  def start_date
    student_enrollment = course.student_enrollments.find_by(user_id: user_id) if user_id
    (student_enrollment&.start_at || course_section&.start_at || course.start_at || course.created_at).to_date
  end
end
