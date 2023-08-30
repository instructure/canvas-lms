# frozen_string_literal: true

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

class CourseSection < ActiveRecord::Base
  include Workflow
  include MaterialChanges
  include SearchTermHelper

  belongs_to :course, inverse_of: :course_sections
  belongs_to :nonxlist_course, class_name: "Course"
  belongs_to :root_account, class_name: "Account"
  belongs_to :enrollment_term
  has_many :enrollments, -> { preload(:user).where("enrollments.workflow_state<>'deleted'") }
  has_many :all_enrollments, class_name: "Enrollment"
  has_many :student_enrollments, -> { where("enrollments.workflow_state NOT IN ('deleted', 'completed', 'rejected', 'inactive')").preload(:user) }, class_name: "StudentEnrollment"
  has_many :students, through: :student_enrollments, source: :user
  has_many :all_student_enrollments, -> { where("enrollments.workflow_state<>'deleted'").preload(:user) }, class_name: "StudentEnrollment"
  has_many :all_students, through: :all_student_enrollments, source: :user
  has_many :instructor_enrollments, -> { where(type: ["TaEnrollment", "TeacherEnrollment"]) }, class_name: "Enrollment"
  has_many :admin_enrollments, -> { where(type: %w[TaEnrollment TeacherEnrollment DesignerEnrollment]) }, class_name: "Enrollment"
  has_many :users, through: :enrollments
  has_many :course_account_associations
  has_many :calendar_events, as: :context, inverse_of: :context
  has_many :assignment_overrides, as: :set, dependent: :destroy
  has_many :discussion_topic_section_visibilities,
           lambda {
             where("discussion_topic_section_visibilities.workflow_state<>'deleted'")
           },
           dependent: :destroy
  has_many :discussion_topics, through: :discussion_topic_section_visibilities
  has_many :course_paces, dependent: :destroy

  before_validation :infer_defaults, :verify_unique_sis_source_id, :verify_unique_integration_id
  validates :course_id, :root_account_id, :workflow_state, presence: true
  validates :sis_source_id, length: { maximum: maximum_string_length, allow_nil: true, allow_blank: false }
  validates :name, length: { maximum: maximum_string_length, allow_blank: false }
  validate :validate_section_dates

  has_many :sis_post_grades_statuses

  before_save :maybe_touch_all_enrollments
  after_save :update_account_associations_if_changed
  after_save :delete_enrollments_later_if_deleted
  after_save :update_enrollment_states_if_necessary
  after_save :republish_course_pace_if_needed

  include StickySisFields
  are_sis_sticky :course_id, :name, :start_at, :end_at, :restrict_enrollments_to_section_dates

  delegate :account, to: :course

  def validate_section_dates
    if start_at.present? && end_at.present? && end_at < start_at
      errors.add(:end_at, t("End date cannot be before start date"))
      false
    else
      true
    end
  end

  def maybe_touch_all_enrollments
    touch_all_enrollments if start_at_changed? || end_at_changed? || restrict_enrollments_to_section_dates_changed? || course_id_changed?
  end

  def delete_enrollments_later_if_deleted
    delay_if_production.delete_enrollments_if_deleted if workflow_state == "deleted" && saved_change_to_workflow_state?
  end

  def delete_enrollments_if_deleted
    if workflow_state == "deleted"
      enrollments.where.not(workflow_state: "deleted").find_in_batches do |batch|
        Enrollment::BatchStateUpdater.destroy_batch(batch)
      end
    end
  end

  def participating_observers
    User.observing_students_in_course(participating_students.map(&:id), course.id)
  end

  def participating_observers_by_date
    User.observing_students_in_course(participating_students_by_date.map(&:id), course.id)
  end

  def participating_students
    course.participating_students.where(enrollments: { course_section_id: self })
  end

  def participating_students_by_date
    course.participating_students_by_date.where(enrollments: { course_section_id: self })
  end

  def participating_admins
    course.participating_admins.where("enrollments.course_section_id = ? OR NOT COALESCE(enrollments.limit_privileges_to_course_section, ?)", self, false)
  end

  def participating_admins_by_date
    course.participating_admins.where("enrollments.course_section_id = ? OR NOT COALESCE(enrollments.limit_privileges_to_course_section, ?)", self, false)
  end

  def participants(opts = {})
    ps = nil
    if opts[:by_date]
      ps = participating_students_by_date + participating_admins_by_date
      ps += participating_observers_by_date if opts[:include_observers]
    else
      ps = participating_students + participating_admins
      ps += participating_observers if opts[:include_observers]
    end
    ps
  end

  delegate :available?, to: :course

  def concluded?
    now = Time.now
    if end_at && restrict_enrollments_to_section_dates
      end_at < now
    else
      course.concluded?
    end
  end

  def touch_all_enrollments
    return if new_record?

    enrollments.touch_all
    User.where(id: all_enrollments.select(:user_id)).touch_all
  end

  def broadcast_data
    { course_id:, root_account_id: }
  end

  set_policy do
    given do |user, session|
      course.grants_right?(user, session, :manage_sections_add)
    end
    can :read and can :create

    given do |user, session|
      course.grants_right?(user, session, :manage_sections_edit)
    end
    can :read and can :update

    given do |user, session|
      course.grants_right?(user, session, :manage_sections_delete)
    end
    can :read and can :delete

    given do |user, session|
      manage_perm = if root_account.feature_enabled? :granular_permissions_manage_users
                      :allow_course_admin_actions
                    else
                      :manage_admin_users
                    end
      course.grants_any_right?(user, session, :manage_students, manage_perm)
    end
    can :read

    given { |user| course.account_membership_allows(user, :read_roster) }
    can :read

    given do |user, _session|
      if user
        enrollments = user.enrollments.shard(self).active_by_date.where(course:)
        enrollments.where(limit_privileges_to_course_section: false).or(enrollments.where(course_section: self)).any? { |e| e.has_permission_to?(:manage_calendar) }
      end
    end
    can :manage_calendar

    given { |user| course.account_membership_allows(user, :manage_calendar) }
    can :manage_calendar

    given do |user, _session|
      user && course.sections_visible_to(user).where(id: self).exists?
    end
    can :read

    given { |user, session| course.grants_right?(user, session, :manage_grades) }
    can :manage_grades

    given { |user, session| course.grants_right?(user, session, :read_as_admin) }
    can :read_as_admin
  end

  def update_account_associations_if_changed
    if (saved_change_to_course_id? || saved_change_to_nonxlist_course_id?) && !Course.skip_updating_account_associations?
      Course.delay_if_production(n_strand: ["update_account_associations", global_root_account_id])
            .update_account_associations([course_id, course_id_before_last_save, nonxlist_course_id, nonxlist_course_id_before_last_save].compact.uniq)
    end
  end

  def update_account_associations
    Course.update_account_associations([course_id, nonxlist_course_id].compact)
  end

  def verify_unique_sis_source_id
    return true unless sis_source_id
    return true if !root_account_id_changed? && !sis_source_id_changed?

    scope = root_account.course_sections.where(sis_source_id:)
    scope = scope.where("id<>?", self) unless new_record?

    return true unless scope.exists?

    errors.add(:sis_source_id, t("sis_id_taken", "SIS ID \"%{sis_id}\" is already in use", sis_id: sis_source_id))
    throw :abort
  end

  def verify_unique_integration_id
    return true unless integration_id
    return true if !root_account_id_changed? && !integration_id_changed?

    scope = root_account.course_sections.where(integration_id:)
    scope = scope.where("id<>?", self) unless new_record?

    return true unless scope.exists?

    errors.add(:integration_id, t("integration_id_taken", "INTEGRATRION ID \"%{integration_id}\" is already in use", integration_id:))
    throw :abort
  end

  alias_method :parent_event_context, :course

  def section_code
    name
  end

  def infer_defaults
    self.root_account_id ||= (course.root_account_id rescue nil) || Account.default.id
    raise "Course required" unless course

    self.root_account_id = course.root_account_id || Account.default.id
    # This is messy, and I hate it.
    # The SIS import actually gives us three names for a section
    #   and I don't know which one is best, or which one to show.
    # Here's the current plan:
    # - otherwise, just use name
    # - use the method display_name to consolidate this logic
    self.name ||= course.name if default_section
    self.name ||= "#{course.name} #{Time.zone.today}"
  end

  def defined_by_sis?
    !!sis_source_id
  end

  # NOTE: Don't assume the section_name contains the course name
  # it might include it if the SIS specifies, but you shouldn't
  # assume that this method on its own will be enough for a user
  # to recognize their course from a list
  # The only place this is used by itself right now is when listing
  # enrollments within a course
  def display_name
    @section_display_name ||= self.name
  end

  def move_to_course(course, **opts)
    return self if course_id == course.id

    old_course = self.course
    self.course = course
    self.root_account_id = course.root_account_id

    all_attrs = { course_id: course.id }
    if root_account_id_changed?
      all_attrs[:root_account_id] = self.root_account_id
    end

    CourseSection.unique_constraint_retry do
      self.default_section = (course.course_sections.active.empty?)
      save!
    end

    old_course.course_sections.reset
    course.course_sections.reset
    assignment_overrides.active.destroy_all
    discussion_topic_section_visibilities.active.destroy_all

    enrollment_data = all_enrollments.pluck(:id, :user_id)
    enrollment_ids = enrollment_data.map(&:first)
    user_ids = enrollment_data.map(&:last).uniq

    if enrollment_ids.any?
      all_enrollments.update_all all_attrs
      Enrollment.delay_if_production.batch_add_to_favorites(enrollment_ids)
    end

    Assignment.suspend_due_date_caching do
      Assignment.where(context: [old_course, self.course]).touch_all
    end

    User.clear_cache_keys(user_ids, :enrollments)
    EnrollmentState.delay_if_production(n_strand: ["invalidate_enrollment_states", global_root_account_id])
                   .invalidate_states_for_course_or_section(self, invalidate_access: true)
    User.delay_if_production.update_account_associations(user_ids) if old_course.account_id != course.account_id && !User.skip_updating_account_associations?
    if old_course.id != course_id && old_course.id != nonxlist_course_id && !Course.skip_updating_account_associations?
      old_course.delay_if_production.update_account_associations
    end

    SubmissionLifecycleManager.recompute_users_for_course(
      user_ids,
      course,
      nil,
      update_grades: true,
      executing_user: opts[:updating_user]
    )

    # it's possible that some enrollments were created using an old copy of the course section before the crosslist,
    # so wait a little bit and then make sure they get cleaned up
    delay_if_production(run_at: 10.seconds.from_now).ensure_enrollments_in_correct_section
  end

  def ensure_enrollments_in_correct_section
    enrollments.where.not(course_id:).each { |e| e.update_attribute(:course_id, course_id) }
  end

  def crosslist_to_course(course, **opts)
    return self if course_id == course.id

    self.nonxlist_course_id ||= course_id
    move_to_course(course, **opts)
  end

  def uncrosslist(**opts)
    return unless self.nonxlist_course_id

    if nonxlist_course.workflow_state == "deleted"
      nonxlist_course.workflow_state = "claimed"
      nonxlist_course.save!
    end
    nonxlist_course = self.nonxlist_course
    self.nonxlist_course = nil
    move_to_course(nonxlist_course, **opts)
  end

  def crosslisted?
    !!self.nonxlist_course_id
  end

  def destroy_course_if_no_more_sections
    if deleted? && course.course_sections.active.empty?
      course.destroy
    end
  end

  def deletable?
    !enrollments.where.not(workflow_state: "rejected").not_fake.exists?
  end

  def enroll_user(user, type, state = "invited")
    course.enroll_user(user, type, enrollment_state: state, section: self)
  end

  workflow do
    state :active
    state :deleted
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"
    enrollments.not_fake.each(&:destroy)
    assignment_overrides.each(&:destroy)
    discussion_topic_section_visibilities&.each(&:destroy)
    result = save!
    delay_if_production(
      priority: Delayed::LOW_PRIORITY,
      strand: "RemoveSectionFromGradebookFilters:#{global_course_id}"
    ).remove_from_gradebook_filters
    result
  end

  def self.destroy_batch(batch, sis_batch: nil, batch_mode: false)
    raise ArgumentError, "Cannot call with more than 1000 sections" if batch.count > 1000

    cs = CourseSection.where(id: batch).select(:id, :workflow_state).to_a
    data = SisBatchRollBackData.build_dependent_data(sis_batch:, contexts: cs, updated_state: "deleted", batch_mode_delete: batch_mode)
    CourseSection.where(id: cs.map(&:id)).update_all(workflow_state: "deleted", updated_at: Time.zone.now)
    Enrollment.where(course_section_id: cs.map(&:id)).active.find_in_batches do |e_batch|
      GuardRail.activate(:primary) do
        new_data = Enrollment::BatchStateUpdater.destroy_batch(e_batch, sis_batch:, batch_mode:)
        data.push(*new_data)
        SisBatchRollBackData.bulk_insert_roll_back_data(data)
        data = []
      end
    end
    AssignmentOverride.where(set_type: "CourseSection", set_id: cs.map(&:id)).find_each(&:destroy)
    DiscussionTopicSectionVisibility.where(course_section_id: cs.map(&:id)).find_in_batches do |d_batch|
      DiscussionTopicSectionVisibility.where(id: d_batch).update_all(workflow_state: "deleted")
    end
    cs.count
  end

  scope :active, -> { where("course_sections.workflow_state<>'deleted'") }

  scope :sis_sections, ->(account, *source_ids) { where(root_account_id: account, sis_source_id: source_ids).order(:sis_source_id) }

  def common_to_users?(users)
    users.all? { |user| student_enrollments.active.for_user(user).exists? }
  end

  def update_enrollment_states_if_necessary
    if saved_change_to_restrict_enrollments_to_section_dates? ||
       (restrict_enrollments_to_section_dates? && saved_material_changes_to?(:start_at, :end_at))
      EnrollmentState.delay_if_production(n_strand: ["invalidate_enrollment_states", global_root_account_id])
                     .invalidate_states_for_course_or_section(self)
    end
  end

  def republish_course_pace_if_needed
    return unless saved_changes.keys.intersect?(%w[start_at conclude_at restrict_enrollments_to_section_dates])
    return unless course.enable_course_paces?

    course_paces.published.find_each(&:create_publish_progress)
  end

  private

  def remove_from_gradebook_filters
    gradebook_settings = UserPreferenceValue.where(key: "gradebook_settings", sub_key: global_course_id)
    gradebook_settings.find_each do |setting|
      if setting.value.dig("filter_rows_by", "section_id") == id.to_s
        setting.value["filter_rows_by"]["section_id"] = nil
        setting.save
      end
    end
  end
end
