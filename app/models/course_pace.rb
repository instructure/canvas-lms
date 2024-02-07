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

  include MasterCourses::Restrictor
  restrict_columns :content, [:duration]
  restrict_columns :state, [:workflow_state]
  restrict_columns :settings, %i[exclude_weekends hard_end_dates]

  extend RootAccountResolver
  resolves_root_account through: :course

  belongs_to :course, inverse_of: :course_paces
  has_many :course_pace_module_items, dependent: :destroy

  accepts_nested_attributes_for :course_pace_module_items, allow_destroy: true

  belongs_to :course_section
  belongs_to :user
  belongs_to :root_account, class_name: "Account"

  after_create :log_pace_counts
  after_create :log_course_blackout_dates
  after_destroy :log_pace_deletes
  after_save :log_exclude_weekends_counts, if: :logging_for_weekends_required?
  after_save :log_average_item_duration

  validates :course_id, presence: true
  validate :valid_secondary_context

  scope :primary, -> { not_deleted.where(course_section_id: nil, user_id: nil) }
  scope :for_section, ->(section) { where(course_section_id: section) }
  scope :for_user, ->(user) { where(user_id: user) }
  scope :not_deleted, -> { where.not(workflow_state: "deleted") }
  scope :unpublished, -> { where(workflow_state: "unpublished") }
  scope :published, -> { where(workflow_state: "active").where.not(published_at: nil) }
  scope :section_paces, -> { where.not(course_section_id: nil) }
  scope :student_enrollment_paces, -> { where.not(user_id: nil) }

  workflow do
    state :unpublished
    state :active
    state :deleted
  end

  set_policy do
    given { |user, session| course.grants_right?(user, session, :manage) }
    can :read
  end

  def asset_name
    I18n.t("Course Pace")
  end

  def effective_name
    if user_id.present?
      user.name
    elsif course_section_id.present?
      course_section.name
    else
      course.name
    end
  end

  def type
    if user_id.present?
      "StudentEnrollment"
    elsif course_section_id.present?
      "Section"
    else
      "Course"
    end
  end

  # We need to add one day to the sum of durations here to
  # account for the oddity of the first item's set due date.
  # If a user is enrolled via a pace item with a duration of
  # one day on Jan 1 at 11:58pm, their due date would be on
  # Jan 2 at 11:59pm. If that same user were enrolled on Jan
  # 2 at 12:00am, their due date would be Jan 3 at 11:59pm.
  # While this oddity of finishing out the current day exists,
  # we will always need to add one to the sum of durations.
  def duration
    course_pace_module_items.sum(:duration) + 1
  end

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

  def create_publish_progress(run_at: Setting.get("course_pace_publish_interval", "300").to_i.seconds.from_now, enrollment_ids: nil)
    progress = Progress.create!(context: self, tag: "course_pace_publish")
    run_publish_progress(progress, run_at:, enrollment_ids:)
    progress
  end

  def run_publish_progress(progress, run_at: Time.now, enrollment_ids: nil)
    progress.process_job(self,
                         :publish,
                         {
                           run_at:,
                           singleton: "course_pace_publish:#{global_id}",
                           on_conflict: :overwrite
                         },
                         enrollment_ids:)
    progress
  end

  def publish(progress = nil, enrollment_ids: nil)
    raise "Course pace is deleted" if deleted?

    enrollments = enrollment_ids ? course.student_enrollments.where(id: enrollment_ids) : student_enrollments
    Time.use_zone(course.time_zone) do
      assignments_to_refresh = Set.new
      Assignment.suspend_due_date_caching do
        Assignment.suspend_grading_period_grade_recalculation do
          progress&.calculate_completion!(0, enrollments.size)
          enrollments.each do |enrollment|
            compressed_module_items = compress_dates(start_date: nil, enrollment:)
                                      .sort_by { |ppmi| ppmi.module_item.position }
                                      .group_by { |ppmi| ppmi.module_item.context_module }
                                      .sort_by { |context_module, _items| context_module.position }
                                      .to_h.values.flatten
            dates =
              CoursePaceDueDatesCalculator.new(self).get_due_dates(compressed_module_items, enrollment)
            course_pace_module_items.each do |course_pace_module_item|
              content_tag = course_pace_module_item.module_item
              assignment = content_tag.assignment
              next unless assignment

              due_at = CanvasTime.fancy_midnight(dates[course_pace_module_item.id].in_time_zone).in_time_zone("UTC")
              user_id = enrollment.user_id

              # Check for an old override
              current_override =
                assignment
                .assignment_overrides
                .active
                .where(set_type: "ADHOC", due_at_overridden: true)
                .joins(:assignment_override_students)
                .find_by(assignment_override_students: { user_id: })
              next if current_override&.due_at == due_at

              # See if there is already an assignment override with the correct date
              due_range = (due_at - 1.second).round..due_at.round
              correct_date_override =
                assignment.assignment_overrides.active.find_by(
                  set_type: "ADHOC",
                  due_at_overridden: true,
                  due_at: due_range
                )

              # If the assignment has already been submitted we are going to log that and continue
              if assignment.submissions.find_by(user_id:)&.submitted?
                InstStatsd::Statsd.increment("course_pacing.submitted_assignment_date_change")
              end

              # If it exists let's just add the student to it and remove them from the other
              if correct_date_override
                create_or_update_assignment_student_override!(correct_date_override, user_id)
              elsif current_override&.assignment_override_students&.size == 1
                current_override.update(due_at:)
              else
                assignment_override = assignment.assignment_overrides.create!(
                  title: I18n.t("Course Pacing"),
                  set_type: "ADHOC",
                  due_at_overridden: true,
                  due_at:
                )
                create_or_update_assignment_student_override!(assignment_override, user_id)
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
      SubmissionLifecycleManager.recompute_course(course, assignments: assignments_to_refresh, update_grades: true)

      # Maintain the weights of the module items
      course_pace_module_items.each(&:restore_attributes)

      # Explicitly complete the progress so we aren't left with any hanging progresses
      progress.complete! if progress&.running?

      # Mark as published
      log_module_items_count
      update(workflow_state: "active", published_at: DateTime.current)
    end
  end

  def republish_paces_for_affected_enrollments
    raise "Course pace is not deleted" unless deleted?

    grouped_paces_and_enrollments = student_enrollments.group_by do |enrollment|
      student_section_ids = enrollment.user.student_enrollments.shard(shard).where(course:).active.pluck(:course_section_id)
      pace = course.course_paces.published.where(course_section_id: student_section_ids).last
      pace || course.course_paces.published.primary.take
    end
    grouped_paces_and_enrollments.each do |pace, enrollments|
      pace.create_publish_progress(enrollment_ids: enrollments.pluck(:id))
    end
  end

  def published?
    active?
  end

  def primary?
    !deleted? && course_section_id.nil? && user_id.nil?
  end

  def compress_dates(save: false, start_date: self.start_date, enrollment: nil)
    CoursePaceHardEndDateCompressor.compress(
      self,
      course_pace_module_items,
      enrollment:,
      save:,
      start_date:
    )
  end

  def student_enrollments
    @student_enrollments ||=
      if user_id
        course.student_enrollments.where(user_id:)
      elsif course_section_id
        student_course_pace_user_ids = course.course_paces.not_deleted.where.not(user_id: nil).pluck(:user_id)
        course_section.student_enrollments.where.not(user_id: student_course_pace_user_ids)
      else
        student_course_pace_user_ids = course.course_paces.not_deleted.where.not(user_id: nil).pluck(:user_id)
        course_section_course_pace_section_ids =
          course.course_paces.not_deleted.where.not(course_section: nil).pluck(:course_section_id)
        course
          .student_enrollments
          .where
          .not(user_id: student_course_pace_user_ids)
          .where
          .not(course_section_id: course_section_course_pace_section_ids)
      end
    @student_enrollments.active
  end

  def start_date(with_context: false)
    valid_date_range = CourseDateRange.new(course)
    student_enrollment = course.student_enrollments.find_by(user_id:) if user_id

    enrollment_start_date = student_enrollment&.start_at || [student_enrollment&.effective_start_at, student_enrollment&.created_at].compact.max
    date = enrollment_start_date || course_section&.start_at || valid_date_range.start_at[:date]
    today = Date.today

    # always put pace plan dates in the course time zone
    if with_context
      if date
        context = (student_enrollment && "user") || (course_section&.start_at && "section") || (date && valid_date_range.start_at[:date_context])
      else
        date = today
        context = "hypothetical"
      end
      { start_date: date.in_time_zone(course.time_zone), start_date_context: context }
    else
      (date || today).in_time_zone(course.time_zone)
    end
  end

  def end_date
    self[:end_date]&.in_time_zone(course.time_zone)
  end

  def individual_pace_end_date
    student_enrollment = user.student_enrollments.shard(shard).where(course:).active.order(created_at: :desc).take
    course_section_paces = course.course_paces.not_deleted.section_paces.preload(:course_section)
    applied_section_pace = course_section_paces.find_by(course_section_id: student_enrollment.course_section_id)
    return student_enrollment.course_section.end_at if applied_section_pace&.course_section_id

    nil
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

    is_student_plan = course.student_enrollments.find_by(user_id:).present? if user_id

    date = if hard_end_dates
             self[:end_date]
           elsif is_student_plan
             individual_pace_end_date
           else
             course_section&.end_at
           end

    date ||= range_end
    date = date&.to_date

    if with_context
      context = if is_student_plan && date
                  "user"
                elsif course_section&.end_at
                  "section"
                elsif date
                  hard_end_dates ? "hard" : valid_date_range.end_at[:date_context]
                else
                  "hypothetical"
                end

      { end_date: date&.in_time_zone(course.time_zone), end_date_context: context }
    else
      date&.in_time_zone(course.time_zone)
    end
  end

  # This method will attempt to find an existing AssignmentOverrideStudent for the given user and assignment override.
  # If one exists it will update the workflow_state to active and update the assignment_override_id to the new override.
  # It also checks to see if the old override is now empty and deletes it if it is.
  # If no existing AssignmentOverrideStudent is found it will create a new one.
  #
  # @param assignment_override [AssignmentOverride] The assignment override to create or update the
  #   AssignmentOverrideStudent for
  # @param user_id [Integer] The user_id of the AssignmentOverrideStudent to create or update
  # @return [AssignmentOverrideStudent] The AssignmentOverrideStudent that was created or updated
  def create_or_update_assignment_student_override!(assignment_override, user_id)
    assignment = assignment_override.assignment
    assignment_override_student = assignment.assignment_override_students.find_by(user_id:)
    if assignment_override_student
      original_override = assignment_override_student.assignment_override
      assignment_override_student.update!(workflow_state: "active", assignment_override:)
      original_override.destroy_if_empty_set
    else
      assignment_override_student = assignment_override.assignment_override_students.create!(
        user_id:,
        no_enrollment: false
      )
    end
    assignment_override_student
  end

  def logging_for_weekends_required?
    saved_change_to_exclude_weekends? || (saved_change_to_id? && exclude_weekends)
  end

  def log_pace_counts
    if course_section_id.present?
      InstStatsd::Statsd.increment("course_pacing.section_paces.count")
    elsif user_id.present?
      InstStatsd::Statsd.increment("course_pacing.user_paces.count")
    else
      InstStatsd::Statsd.increment("course_pacing.course_paces.count")
    end
  end

  def log_exclude_weekends_counts
    if exclude_weekends
      InstStatsd::Statsd.increment("course_pacing.weekends_excluded")
    else
      # Only decrementing during an update (not initial create)
      InstStatsd::Statsd.decrement("course_pacing.weekends_excluded") unless saved_change_to_id?
    end
  end

  def log_average_item_duration
    return if course_pace_module_items.empty?

    average_duration = course_pace_module_items.pluck(:duration).sum / course_pace_module_items.length
    InstStatsd::Statsd.count("course_pacing.average_assignment_duration", average_duration)
  end

  def log_module_items_count
    all_active_course_module_items = course.context_module_tags.active
    paced_course_module_items = all_active_course_module_items.where(id: course_pace_module_items.pluck(:module_item_id))
    InstStatsd::Statsd.count("course.paced.paced_module_item_count", paced_course_module_items.size)
    InstStatsd::Statsd.count("course.paced.all_module_item_count", all_active_course_module_items.size)
  end

  def log_pace_deletes
    if course_section_id.present?
      InstStatsd::Statsd.increment("course_pacing.deleted_section_pace")
    elsif user_id.present?
      InstStatsd::Statsd.increment("course_pacing.deleted_user_pace")
    else
      InstStatsd::Statsd.increment("course_pacing.deleted_course_pace")
    end
  end

  def log_course_blackout_dates
    InstStatsd::Statsd.count("course_pacing.course_blackout_dates.count", CalendarEvent.with_blackout_date.active.where(context: course).size)
    account_blackout_dates = Account.multi_account_chain_ids([course.account.id]).sum { |id| CalendarEvent.with_blackout_date.active.where(context: Account.find(id)).size }
    InstStatsd::Statsd.count("course_pacing.account_blackout_dates.count", account_blackout_dates)
  end
end
