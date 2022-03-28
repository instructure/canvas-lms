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

class CoursePace < ActiveRecord::Base
  include Workflow
  include Canvas::SoftDeletable

  extend RootAccountResolver
  resolves_root_account through: :course

  belongs_to :course, inverse_of: :course_paces
  has_many :course_pace_module_items, dependent: :destroy

  accepts_nested_attributes_for :course_pace_module_items, allow_destroy: true

  belongs_to :course_section
  belongs_to :user
  belongs_to :root_account, class_name: "Account"

  validates :course_id, presence: true
  validate :valid_secondary_context

  scope :primary, -> { not_deleted.where(course_section_id: nil, user_id: nil) }
  scope :for_section, ->(section) { where(course_section_id: section) }
  scope :for_user, ->(user) { where(user_id: user) }
  scope :not_deleted, -> { where.not(workflow_state: "deleted") }
  scope :unpublished, -> { where(workflow_state: "unpublished") }
  scope :published, -> { where(workflow_state: "active").where.not(published_at: nil) }

  workflow do
    state :unpublished
    state :active
    state :deleted
  end

  set_policy do
    given { |user, session| course.grants_right?(user, session, :manage) }
    can :read
  end

  self.ignored_columns = %i[start_date]

  def valid_secondary_context
    if course_section_id.present? && user_id.present?
      errors.add(:base, "Only one of course_section_id and user_id can be given")
    end
  end

  def duplicate(opts = {})
    default_opts = {
      course_section_id: nil,
      user_id: nil,
      published_at: nil,
      workflow_state: "unpublished"
    }
    course_pace = dup
    course_pace.attributes = default_opts.merge(opts)

    course_pace_module_items.each do |course_pace_module_item|
      course_pace.course_pace_module_items.new(
        module_item_id: course_pace_module_item.module_item_id,
        duration: course_pace_module_item.duration,
        root_account_id: course_pace_module_item.root_account_id
      )
    end

    course_pace
  end

  def create_publish_progress(run_at: Setting.get("course_pace_publish_interval", "300").to_i.seconds.from_now)
    progress = Progress.create!(context: self, tag: "course_pace_publish")
    progress.process_job(self, :publish, {
                           run_at: run_at,
                           singleton: "course_pace_publish:#{id}",
                           on_conflict: :overwrite
                         })
    progress
  end

  def publish(progress = nil)
    Time.use_zone(course.time_zone) do
      assignments_to_refresh = Set.new
      Assignment.suspend_due_date_caching do
        Assignment.suspend_grading_period_grade_recalculation do
          progress&.calculate_completion!(0, student_enrollments.size)
          ordered_module_items = course_pace_module_items.not_deleted
                                                         .sort_by { |ppmi| ppmi.module_item.position }
                                                         .group_by { |ppmi| ppmi.module_item.context_module }
                                                         .sort_by { |context_module, _items| context_module.position }
                                                         .to_h.values.flatten
          student_enrollments.each do |enrollment|
            dates =
              CoursePaceDueDatesCalculator.new(self).get_due_dates(ordered_module_items, enrollment)
            course_pace_module_items.each do |course_pace_module_item|
              content_tag = course_pace_module_item.module_item
              assignment = content_tag.assignment
              next unless assignment

              due_at = dates[course_pace_module_item.id]
              user_id = enrollment.user_id

              # Check for an old override
              current_override =
                assignment
                .assignment_overrides
                .active
                .where(set_type: "ADHOC", due_at_overridden: true)
                .joins(:assignment_override_students)
                .find_by(assignment_override_students: { user_id: user_id })
              next if current_override&.due_at&.to_date == due_at

              # See if there is already an assignment override with the correct date
              due_time = CanvasTime.fancy_midnight(due_at.to_datetime).to_time
              due_range = (due_time - 1.second).round..due_time.round
              correct_date_override =
                assignment.assignment_overrides.active.find_by(
                  set_type: "ADHOC",
                  due_at_overridden: true,
                  due_at: due_range
                )

              # If it exists let's just add the student to it and remove them from the other
              if correct_date_override
                current_override&.assignment_override_students&.find_by(user_id: user_id)&.destroy
                correct_date_override.assignment_override_students.create(
                  user_id: user_id,
                  no_enrollment: false
                )
              elsif current_override&.assignment_override_students&.size == 1
                current_override.update(due_at: due_at.to_s)
              else
                current_override&.assignment_override_students&.find_by(user_id: user_id)&.destroy
                assignment.assignment_overrides.create!(
                  set_type: "ADHOC",
                  due_at_overridden: true,
                  due_at: due_at.to_s,
                  assignment_override_students: [
                    AssignmentOverrideStudent.new(
                      assignment: assignment,
                      user_id: user_id,
                      no_enrollment: false
                    )
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
      update(workflow_state: "active", published_at: DateTime.current)
    end
  end

  def compress_dates(save: true, start_date: self.start_date)
    CoursePaceHardEndDateCompressor.compress(
      self,
      course_pace_module_items,
      save: save,
      start_date: start_date
    )
  end

  def student_enrollments
    @student_enrollments ||=
      if user_id
        course.student_enrollments.where(user_id: user_id)
      elsif course_section_id
        student_course_pace_user_ids = course.course_paces.where.not(user_id: nil).pluck(:user_id)
        course_section.student_enrollments.where.not(user_id: student_course_pace_user_ids)
      else
        student_course_pace_user_ids = course.course_paces.where.not(user_id: nil).pluck(:user_id)
        course_section_course_pace_section_ids =
          course.course_paces.where.not(course_section: nil).pluck(:course_section_id)
        course
          .student_enrollments
          .where
          .not(user_id: student_course_pace_user_ids)
          .where
          .not(course_section_id: course_section_course_pace_section_ids)
      end
  end

  def start_date(with_context: false)
    Time.use_zone(course.time_zone) do
      valid_date_range = CourseDateRange.new(course)
      student_enrollment = course.student_enrollments.find_by(user_id: user_id) if user_id

      # always put pace plan dates in the course time zone
      date = student_enrollment&.effective_start_at || course_section&.start_at || valid_date_range.start_at[:date]
      date&.to_date
      today = Date.today

      if with_context
        if date
          context = (student_enrollment && "user") || (course_section&.start_at && "section") || (date && valid_date_range.start_at[:date_context])
        else
          date = today
          context = "hypothetical"
        end
        { start_date: date, start_date_context: context }
      else
        date || today
      end
    end
  end

  def end_date
    Time.use_zone(course.time_zone) { self[:end_date] }
  end

  def effective_end_date(with_context: false)
    valid_date_range = CourseDateRange.new(course)
    range_end = valid_date_range.end_at[:date]

    # by default in the UI, courses end on midnight of the date selected
    # in this case back it up to fancy_midnight the previous day
    # previous day
    if range_end && (range_end.hour == 0 && range_end.min == 0)
      range_end = CanvasTime.fancy_midnight(range_end - 1.minute)
    end

    is_student_plan = course.student_enrollments.find_by(user_id: user_id).present? if user_id

    date = ((is_student_plan || hard_end_dates) && self[:end_date]) || range_end
    date = date&.to_date

    if with_context
      context = if is_student_plan
                  "user"
                elsif date
                  hard_end_dates ? "hard" : valid_date_range.end_at[:date_context]
                else
                  "hypothetical"
                end
      { end_date: date, end_date_context: context }
    else
      date
    end
  end
end
