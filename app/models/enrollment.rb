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

class Enrollment < ActiveRecord::Base
  SIS_TYPES = {
    "TeacherEnrollment" => "teacher",
    "TaEnrollment" => "ta",
    "DesignerEnrollment" => "designer",
    "StudentEnrollment" => "student",
    "ObserverEnrollment" => "observer"
  }.freeze

  self.ignored_columns += ["graded_at"]

  include Workflow

  belongs_to :course, inverse_of: :enrollments
  belongs_to :course_section, inverse_of: :enrollments
  belongs_to :root_account, class_name: "Account", inverse_of: :enrollments
  belongs_to :user, inverse_of: :enrollments
  belongs_to :sis_pseudonym, class_name: "Pseudonym", inverse_of: :sis_enrollments
  belongs_to :associated_user, class_name: "User"
  belongs_to :temporary_enrollment_pairing, inverse_of: :enrollments

  belongs_to :role
  include Role::AssociationHelper

  has_one :enrollment_state, dependent: :destroy, inverse_of: :enrollment

  has_many :role_overrides, as: :context, inverse_of: :context
  has_many :pseudonyms, primary_key: :user_id, foreign_key: :user_id
  has_many :course_account_associations, foreign_key: "course_id", primary_key: "course_id"
  has_many :scores, -> { active }

  validates :user_id, :course_id, :type, :root_account_id, :course_section_id, :workflow_state, :role_id, presence: true
  validates :limit_privileges_to_course_section, inclusion: { in: [true, false] }
  validates :associated_user_id, inclusion: { in: [nil],
                                              unless: ->(enrollment) { enrollment.type == "ObserverEnrollment" },
                                              message: -> { t("only ObserverEnrollments may have an associated_user_id") } }
  validate :cant_observe_self, if: ->(enrollment) { enrollment.type == "ObserverEnrollment" }
  validate :cant_observe_observer, if: ->(enrollment) { enrollment.type == "ObserverEnrollment" }

  validate :valid_role?
  validate :valid_course?
  validate :not_template_course?
  validate :valid_section?
  validate :not_student_view

  # update bulk destroy if changing or adding an after save
  before_save :assign_uuid
  before_validation :assert_section
  after_save :recalculate_enrollment_state
  after_save :update_user_account_associations_if_necessary
  before_save :audit_groups_for_deleted_enrollments
  before_validation :ensure_role_id
  after_create :create_linked_enrollments
  after_create :create_enrollment_state
  after_save :copy_scores_from_existing_enrollment, if: :need_to_copy_scores?
  after_save :clear_email_caches
  after_save :cancel_future_appointments
  after_save :update_linked_enrollments
  after_save :set_update_cached_due_dates
  after_save :touch_graders_if_needed
  after_save :reset_notifications_cache
  after_save :dispatch_invitations_later
  after_save :add_to_favorites_later
  after_commit :update_cached_due_dates
  after_save :update_assignment_overrides_if_needed
  after_create :needs_grading_count_updated, if: :active_student?
  after_update :needs_grading_count_updated, if: :active_student_changed?

  after_commit :sync_microsoft_group
  scope :microsoft_sync_relevant, -> { active_or_pending.accepted.not_fake }
  scope :microsoft_sync_irrelevant_but_not_fake, -> { not_fake.where("enrollments.workflow_state IN ('rejected', 'completed', 'inactive', 'invited')") }

  attr_accessor :already_enrolled, :need_touch_user, :skip_touch_user

  scope :current, -> { joins(:course).where(QueryBuilder.new(:active).conditions).readonly(false) }
  scope :current_and_invited, -> { joins(:course).where(QueryBuilder.new(:current_and_invited).conditions).readonly(false) }
  scope :current_and_future, -> { joins(:course).where(QueryBuilder.new(:current_and_future).conditions).readonly(false) }
  scope :concluded, -> { joins(:course).where(QueryBuilder.new(:completed).conditions).readonly(false) }
  scope :current_and_concluded, -> { joins(:course).where(QueryBuilder.new(:current_and_concluded).conditions).readonly(false) }

  def ensure_role_id
    self.role_id ||= role.id
  end

  def cant_observe_self
    errors.add(:associated_user_id, "Cannot observe yourself") if user_id == associated_user_id
  end

  def cant_observe_observer
    if !deleted? && course.enrollments.where(type: "ObserverEnrollment",
                                             user_id: associated_user_id,
                                             associated_user_id: user_id).exists?
      errors.add(:associated_user_id, "Cannot observe observer observing self")
    end
  end

  def valid_course?
    if !deleted? && course.deleted?
      errors.add(:course_id, "is not a valid course")
    end
  end

  def not_template_course?
    if course.template?
      errors.add(:course_id, "is a template course")
    end
  end

  def valid_section?
    unless deleted? || course_section.active?
      errors.add(:course_section_id, "is not a valid section")
    end
  end

  def not_student_view
    if type != "StudentViewEnrollment" && (new_record? || association(:user).loaded?) &&
       user.fake_student?
      errors.add(:user_id, "cannot add a student view student in a regular role")
    end
  end

  def valid_role?
    return true if deleted? || role.built_in?

    unless role.base_role_type == type
      errors.add(:role_id, "is not valid for the enrollment type")
    end

    unless course.account.valid_role?(role)
      errors.add(:role_id, "is not an available role for this course's account")
    end
  end

  def self.get_built_in_role_for_type(enrollment_type, root_account_id:)
    role = Role.get_built_in_role("StudentEnrollment", root_account_id:) if enrollment_type == "StudentViewEnrollment"
    role ||= Role.get_built_in_role(enrollment_type, root_account_id:)
    role
  end

  def default_canvas_role
    Enrollment.get_built_in_role_for_type(type, root_account_id: course.root_account_id)
  end

  # see #active_student?
  def self.active_student_conditions
    "(enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment') AND enrollments.workflow_state = 'active')"
  end

  # see .active_student_conditions
  def active_student?(was = false)
    suffix = was ? "_before_last_save" : ""

    %w[StudentEnrollment StudentViewEnrollment].include?(send(:"type#{suffix}")) &&
      send(:"workflow_state#{suffix}") == "active"
  end

  def active_student_changed?
    active_student? != active_student?(:was)
  end

  def clear_needs_grading_count_cache
    Assignment
      .where(context_id: course_id, context_type: "Course")
      .where(Submission.where(user_id:)
               .where("assignment_id=assignments.id")
               .where("#{Submission.needs_grading_conditions} OR
            (workflow_state = 'deleted' AND submission_type IS NOT NULL AND
            (score IS NULL OR NOT grade_matches_current_submission OR
            (submission_type = 'online_quiz' AND quiz_submission_id IS NOT NULL)))")
            .arel.exists)
      .where.not(Enrollment.where(Enrollment.active_student_conditions)
               .where(user_id:, course_id:)
               .where("id<>?", self)
               .arel.exists)
      .clear_cache_keys(:needs_grading)
  end

  def needs_grading_count_updated
    self.class.connection.after_transaction_commit do
      clear_needs_grading_count_cache
    end
  end

  include StickySisFields
  are_sis_sticky :start_at, :end_at

  has_a_broadcast_policy

  set_broadcast_policy do |p|
    p.dispatch :enrollment_invitation
    p.to { user }
    p.whenever do |record|
      !record.self_enrolled &&
        record.course &&
        record.user.registered? &&
        !record.observer? &&
        ((record.invited? && (record.just_created || record.saved_change_to_workflow_state?)) || @re_send_confirmation)
    end

    p.dispatch :enrollment_registration
    p.to { user.communication_channel }
    p.whenever do |record|
      !record.self_enrolled &&
        record.course &&
        !record.user.registered? &&
        ((record.invited? && (record.just_created || record.saved_change_to_workflow_state?)) || @re_send_confirmation)
    end

    p.dispatch :enrollment_notification
    p.to { user }
    p.whenever do |record|
      !record.self_enrolled &&
        record.course &&
        !record.course.created? &&
        !record.observer? &&
        record.just_created && record.active?
    end

    p.dispatch :enrollment_accepted
    p.to { course.participating_admins.restrict_to_sections([course_section_id]) - [user] }
    p.whenever do |record|
      record.course &&
        !record.observer? &&
        !record.just_created && (record.changed_state(:active, :invited) || record.changed_state(:active, :creation_pending))
    end
  end

  def dispatch_invitations_later
    # if in an invited state but not frd "invited?" because of future date restrictions, send it later
    if (just_created || saved_change_to_workflow_state? || @re_send_confirmation) && workflow_state == "invited" && inactive? && available_at &&
       !self_enrolled && !(observer? && user.registered?)
      # this won't work if they invite them and then change the course/term/section dates _afterwards_ so hopefully people don't do that
      delay(run_at: available_at, singleton: "send_enrollment_invitations_#{global_id}").re_send_confirmation_if_invited!
    end
  end

  scope :active, -> { where("enrollments.workflow_state<>'deleted'") }
  scope :deleted, -> { where(workflow_state: "deleted") }

  scope :admin, lambda {
                  select(:course_id)
                    .joins(:course)
                    .where("enrollments.type IN ('TeacherEnrollment','TaEnrollment', 'DesignerEnrollment') AND (courses.workflow_state IN ('created', 'claimed') OR (enrollments.workflow_state='active' AND courses.workflow_state='available'))")
                }

  scope :instructor, lambda {
                       select(:course_id)
                         .joins(:course)
                         .where("enrollments.type IN ('TeacherEnrollment','TaEnrollment') AND (courses.workflow_state IN ('created', 'claimed') OR (enrollments.workflow_state='active' AND courses.workflow_state='available'))")
                     }

  scope :of_student_type, -> { where(type: "StudentEnrollment") }

  scope :of_admin_type, -> { where(type: %w[TeacherEnrollment TaEnrollment DesignerEnrollment]) }

  scope :of_instructor_type, -> { where(type: ["TeacherEnrollment", "TaEnrollment"]) }

  scope :of_content_admins, -> { where(type: ["TeacherEnrollment", "DesignerEnrollment"]) }

  scope :of_observer_type, -> { where(type: "ObserverEnrollment") }

  scope :not_of_observer_type, -> { where.not(type: "ObserverEnrollment") }

  scope :student, lambda {
                    select(:course_id)
                      .joins(:course)
                      .where(type: "StudentEnrollment", workflow_state: "active", courses: { workflow_state: "available" })
                  }

  scope :student_in_claimed_or_available, lambda {
                                            select(:course_id)
                                              .joins(:course)
                                              .where(type: "StudentEnrollment", workflow_state: "active", courses: { workflow_state: %w[available claimed created] })
                                          }

  scope :all_student, lambda {
                        eager_load(:course)
                          .where("(enrollments.type = 'StudentEnrollment'
              AND enrollments.workflow_state IN ('invited', 'active', 'completed')
              AND courses.workflow_state IN ('available', 'completed')) OR
              (enrollments.type = 'StudentViewEnrollment'
              AND enrollments.workflow_state = 'active'
              AND courses.workflow_state != 'deleted')")
                      }

  scope :not_deleted, lambda {
    joins(:course)
      .where("(courses.workflow_state<>'deleted') AND (enrollments.workflow_state<>'deleted')")
  }

  scope :not_fake, -> { where("enrollments.type<>'StudentViewEnrollment'") }

  scope :temporary_enrollment_recipients_for_provider, lambda { |user|
    joins(:course).where(temporary_enrollment_source_user_id: user,
                         courses: { workflow_state: %w[available claimed created] })
  }

  scope :temporary_enrollments_for_recipient, lambda { |user|
    joins(:course).where(user_id: user, courses: { workflow_state: %w[available claimed created] })
                  .where.not(temporary_enrollment_source_user_id: nil)
  }

  def self.readable_types
    # with enough use, even translations can add up
    RequestCache.cache("enrollment_readable_types") do
      {
        "TeacherEnrollment" => t("#enrollment.roles.teacher", "Teacher"),
        "TaEnrollment" => t("#enrollment.roles.ta", "TA"),
        "DesignerEnrollment" => t("#enrollment.roles.designer", "Designer"),
        "StudentEnrollment" => t("#enrollment.roles.student", "Student"),
        "StudentViewEnrollment" => t("#enrollment.roles.student", "Student"),
        "ObserverEnrollment" => t("#enrollment.roles.observer", "Observer")
      }
    end
  end

  def self.readable_type(type)
    readable_types[type] || readable_types["StudentEnrollment"]
  end

  def self.sis_type(type)
    SIS_TYPES[type] || SIS_TYPES["StudentEnrollment"]
  end

  def sis_type
    Enrollment.sis_type(type)
  end

  def sis_role
    (!role.built_in? && role.name) || Enrollment.sis_type(type)
  end

  def self.valid_types
    SIS_TYPES.keys
  end

  def self.valid_type?(type)
    SIS_TYPES.key?(type)
  end

  def reload(options = nil)
    @enrollment_dates = nil
    super
  end

  def should_update_user_account_association?
    id_before_last_save.nil? || saved_change_to_course_id? || saved_change_to_course_section_id? ||
      saved_change_to_root_account_id? || being_restored?
  end

  def update_user_account_associations_if_necessary
    return if fake_student?

    if id_before_last_save.nil? || being_restored?
      return if %w[creation_pending deleted].include?(user.workflow_state)

      associations = User.calculate_account_associations_from_accounts([course.account_id, course_section.course.account_id, course_section.nonxlist_course.try(:account_id)].compact.uniq)
      user.update_account_associations(incremental: true, precalculated_associations: associations)
    elsif should_update_user_account_association?
      user.update_account_associations_later
    end
  end
  protected :update_user_account_associations_if_necessary

  def other_section_enrollment_exists?
    # If other active sessions that the user is enrolled in exist.
    course.student_enrollments.where.not(workflow_state: ["deleted", "rejected"]).for_user(user).where.not(id:).exists?
  end

  def audit_groups_for_deleted_enrollments
    # did the student cease to be enrolled in a non-deleted state in a section?
    had_section = course_section_id_was.present?
    deleted_states = ["deleted", "rejected"]
    was_active = !deleted_states.include?(workflow_state_was)
    is_deleted = deleted_states.include?(workflow_state)
    return unless had_section && was_active &&
                  (course_section_id_changed? || is_deleted)

    # what section the user is abandoning, and the section they're moving to
    # (if it's in the same course and the enrollment's not deleted)
    section = CourseSection.find(course_section_id_was)

    # ok, consider groups the user is in from the abandoned section's course
    user.groups.preload(:group_category).where(
      context_type: "Course", context_id: section.course_id
    ).each do |group|
      # check group deletion criteria if either enrollment is not a deletion
      # or it may be a deletion/unenrollment from a section but not from the course as a whole (still enrolled in another section)
      if !is_deleted || other_section_enrollment_exists?
        # don't bother unless the group's category has section restrictions
        next unless group.group_category&.restricted_self_signup?

        # skip if the user is the only user in the group. there's no one to have
        # a conflicting section.
        next unless group.users.where.not(id: user_id).exists?

        # check if the group has the section the user is abandoning as a common
        # section (from CourseSection#common_to_users? view, the enrollment is
        # still there since it queries the db directly and we haven't saved yet);
        # if not, dropping the section is not necessary
        next unless section.common_to_users?(group.users)
      end

      # at this point, the group is restricted, there's more than one user and
      # it appears that the group is common to the section being left by the user so
      # remove the user from the group. Or the student was only enrolled in one section and
      # by leaving the section he/she is completely leaving the course so remove the
      # user from any group related to the course.
      membership = group.group_memberships.where(user_id:).first
      membership&.destroy
    end
  end
  protected :audit_groups_for_deleted_enrollments

  def observers
    student? ? user.linked_observers.active.linked_through_root_account(root_account) : []
  end

  def create_linked_enrollments
    observers.each do |observer|
      create_linked_enrollment_for(observer)
    end
  end

  def update_linked_enrollments(restore: false)
    restorable_states = %w[inactive deleted completed]
    observers.each do |observer|
      enrollment = restore ? linked_enrollment_for(observer) : active_linked_enrollment_for(observer)
      if enrollment
        enrollment.update_from(self)
      elsif restore || (saved_change_to_workflow_state? && restorable_states.include?(workflow_state_before_last_save))
        create_linked_enrollment_for(observer)
      end
    end
  end

  def create_linked_enrollment_for(observer)
    # we don't want to create a new observer enrollment if one exists
    self.class.unique_constraint_retry do
      enrollment = linked_enrollment_for(observer)
      return true if enrollment && !enrollment.deleted? && !enrollment.inactive?
      return false unless observer.can_be_enrolled_in_course?(course)

      enrollment ||= observer.observer_enrollments.build
      enrollment.associated_user_id = user_id
      enrollment.shard = shard if enrollment.new_record?
      enrollment.update_from(self, !!@skip_broadcasts)
    end
  end

  def linked_enrollment_for(observer)
    observer.observer_enrollments.where(
      associated_user_id: user_id,
      course_section_id: course_section_id_before_last_save || course_section_id
    )
            .shard(Shard.shard_for(course_id)).first
  end

  def active_linked_enrollment_for(observer)
    enrollment = linked_enrollment_for(observer)
    # we don't want to "undelete" observer enrollments that have been
    # explicitly deleted
    return nil if enrollment&.deleted? && workflow_state_before_last_save != "deleted"

    enrollment
  end

  # This is Part 1 of the update_cached_due_dates callback.  It sets @update_cached_due_dates which determines
  # whether or not the update_cached_due_dates after_commit callback runs after this record has been committed.
  # This split allows us to suspend this callback and affect the update_cached_due_dates callback since after_commit
  # callbacks aren't being suspended properly.  We suspend this callback during some bulk operations.
  def set_update_cached_due_dates
    @update_cached_due_dates = saved_change_to_workflow_state? && (student? || fake_student?) && course
  end

  def update_cached_due_dates
    if @update_cached_due_dates
      update_grades = being_restored?(to_state: "active") ||
                      being_restored?(to_state: "inactive") ||
                      saved_change_to_id?
      SubmissionLifecycleManager.recompute_users_for_course(user_id, course, nil, update_grades:)
    end
  end

  def update_from(other, skip_broadcasts = false)
    self.course_id = other.course_id
    self.workflow_state = if type == "ObserverEnrollment" && other.workflow_state == "invited"
                            "active"
                          else
                            other.workflow_state
                          end
    self.start_at = other.start_at
    self.end_at = other.end_at
    self.course_section_id = other.course_section_id
    self.root_account_id = other.root_account_id
    self.sis_batch_id = other.sis_batch_id unless sis_batch_id.nil?
    self.skip_touch_user = other.skip_touch_user
    if skip_broadcasts
      save_without_broadcasting!
    else
      save!
    end
  end

  def clear_email_caches
    if saved_change_to_workflow_state? && (workflow_state_before_last_save == "invited" || workflow_state == "invited")
      if Enrollment.cross_shard_invitations?
        Shard.birth.activate do
          user.communication_channels.email.unretired.each { |cc| Rails.cache.delete([cc.path, "all_invited_enrollments2"].cache_key) }
        end
      else
        user.communication_channels.email.unretired.each { |cc| Rails.cache.delete([cc.path, "invited_enrollments2"].cache_key) }
      end
    end
  end

  def cancel_future_appointments
    if saved_change_to_workflow_state? && %w[completed deleted].include?(workflow_state) &&
       !course.current_enrollments.where(user_id:).exists? # ignore if they have another still valid enrollment
      course.appointment_participants.active.current.for_context_codes(user.asset_string).update_all(workflow_state: "deleted")
    end
  end

  def conclude
    self.workflow_state = "completed"
    self.completed_at = Time.now
    save
  end

  def unconclude
    self.workflow_state = "active"
    self.completed_at = nil
    save
  end

  def deactivate
    self.workflow_state = "inactive"
    save
  end

  def reactivate
    self.workflow_state = "active"
    save
  end

  def defined_by_sis?
    !!sis_batch_id
  end

  def assigned_observer?
    observer? && associated_user_id
  end

  def participating?
    state_based_on_date == :active
  end

  def participating_student?
    student? && participating?
  end

  def participating_observer?
    observer? && participating?
  end

  def participating_teacher?
    teacher? && participating?
  end

  def participating_ta?
    ta? && participating?
  end

  def participating_instructor?
    instructor? && participating?
  end

  def participating_designer?
    designer? && participating?
  end

  def participating_admin?
    admin? && participating?
  end

  def participating_content_admin?
    content_admin? && participating?
  end

  def associated_user_name
    associated_user&.short_name
  end

  def assert_section
    self.course_section = course.default_section if !course_section_id && course
    self.root_account_id ||= course.root_account_id rescue nil
  end

  def course_name(display_user = nil)
    course.nickname_for(display_user) || t("#enrollment.default_course_name", "Course")
  end

  def short_name(length = nil, display_user = nil)
    return @short_name if @short_name

    @short_name = course_section.display_name if course_section && root_account && root_account.show_section_name_as_course_name
    @short_name ||= course_name(display_user)
    @short_name = @short_name[0..length] if length
    @short_name
  end

  def long_name(display_user = nil)
    return @long_name if @long_name

    @long_name = course_name(display_user)
    @long_name = t("#enrollment.with_section", "%{course_name}, %{section_name}", course_name: @long_name, section_name: course_section.display_name) if course_section&.display_name && course_section.display_name != course_name(display_user)
    @long_name
  end

  TYPE_RANKS = {
    default: %w[TeacherEnrollment TaEnrollment DesignerEnrollment StudentEnrollment StudentViewEnrollment ObserverEnrollment],
    student: %w[StudentEnrollment TeacherEnrollment TaEnrollment DesignerEnrollment StudentViewEnrollment ObserverEnrollment]
  }.freeze
  TYPE_RANK_HASHES = TYPE_RANKS.transform_values { |v| rank_hash(v) }
  def self.type_rank_sql(order = :default)
    # don't call rank_sql during class load
    rank_sql(TYPE_RANKS[order], "enrollments.type")
  end

  def rank_sortable(order = :default)
    TYPE_RANK_HASHES[order][self.class.to_s]
  end

  STATE_RANK = ["active", ["invited", "creation_pending"], "completed", "inactive", "rejected", "deleted"].freeze
  STATE_RANK_HASH = rank_hash(STATE_RANK)
  def self.state_rank_sql
    # don't call rank_sql during class load
    @state_rank_sql ||= rank_sql(STATE_RANK, "enrollments.workflow_state")
  end

  def state_sortable
    STATE_RANK_HASH[state.to_s]
  end

  STATE_BY_DATE_RANK = ["active", %w[invited creation_pending pending_active pending_invited], "completed", "inactive", "rejected", "deleted"].freeze
  STATE_BY_DATE_RANK_HASH = rank_hash(STATE_BY_DATE_RANK)
  def self.state_by_date_rank_sql
    @state_by_date_rank_sql ||= Arel.sql(
      rank_sql(STATE_BY_DATE_RANK, "enrollment_states.state")
        .sub(/^CASE/, "CASE WHEN enrollment_states.restricted_access THEN #{STATE_BY_DATE_RANK.index("inactive")}") # pretend restricted access is the same as inactive
    )
  end

  def state_with_date_sortable
    STATE_RANK_HASH[state_based_on_date.to_s]
  end

  def accept!
    res = accept
    raise "can't accept" unless res

    res
  end

  def accept(force = false)
    GuardRail.activate(:primary) do
      return false unless force || invited?

      if update_attribute(:workflow_state, "active")
        if type == "StudentEnrollment"
          Enrollment.recompute_final_score_in_singleton(user_id, course_id)
        end
        true
      end
    end
  end

  def reset_notifications_cache
    if saved_change_to_workflow_state?
      StreamItemCache.invalidate_recent_stream_items(user_id, "Course", course_id)
    end
  end

  def add_to_favorites_later
    if saved_change_to_workflow_state? && workflow_state == "active"
      self.class.connection.after_transaction_commit do
        delay_if_production(priority: Delayed::LOW_PRIORITY).add_to_favorites
      end
    end
  end

  def self.batch_add_to_favorites(enrollment_ids)
    Enrollment.where(id: enrollment_ids).each(&:add_to_favorites)
  end

  def add_to_favorites
    # this method was written by Alan Smithee
    user.shard.activate do
      if user.favorites.where(context_type: "Course").exists? # only add a favorite if they've ever favorited anything even if it's no longer in effect
        Favorite.unique_constraint_retry do
          user.favorites.where(context_type: "Course", context_id: course).first_or_create!
        end
      end
    end
  end

  workflow do
    state :invited do
      event :reject, transitions_to: :rejected
      event :complete, transitions_to: :completed
    end

    state :creation_pending do
      event :invite, transitions_to: :invited
    end

    state :active do
      event :reject, transitions_to: :rejected
      event :complete, transitions_to: :completed
    end

    state :deleted
    state :rejected do
      event :unreject, transitions_to: :invited
    end
    state :completed

    # Inactive is a "hard" state, i.e. tuition not paid
    state :inactive
  end

  def enrollment_dates
    Canvas::Builders::EnrollmentDateBuilder.preload([self]) unless @enrollment_dates
    @enrollment_dates
  end

  def enrollment_state
    raise "cannot call enrollment_state on a new record" if new_record?

    result = super
    unless result
      association(:enrollment_state).reload
      result = super
    end
    result.enrollment = self # ensure reverse association
    result
  end

  def create_enrollment_state
    self.enrollment_state =
      shard.activate do
        GuardRail.activate(:primary) do
          EnrollmentState.unique_constraint_retry do
            EnrollmentState.where(enrollment_id: self).first_or_create
          end
        end
      end
  end

  def recalculate_enrollment_state
    if saved_changes.keys.intersect?(%w[workflow_state start_at end_at])
      @enrollment_dates = nil
      enrollment_state.state_is_current = false
      enrollment_state.is_direct_recalculation = true
    end
    enrollment_state.skip_touch_user ||= skip_touch_user
    enrollment_state.ensure_current_state
  end

  def state_based_on_date
    RequestCache.cache("enrollment_state_based_on_date", self, workflow_state, saved_changes?) do
      if %w[invited active completed].include?(workflow_state)
        enrollment_state.get_effective_state
      else
        workflow_state.to_sym
      end
    end
  end

  def readable_state_based_on_date
    # when view restrictions are in place, the effective state_based_on_date is :inactive, but
    # to admins we should show that they are :completed or :pending
    enrollment_state.get_display_state
  end

  def available_at
    if enrollment_state.pending?
      enrollment_state.state_valid_until
    end
  end

  def view_restrictable?
    (student? && !fake_student?) || observer?
  end

  def restrict_past_view?
    view_restrictable? && RequestCache.cache("restrict_student_past_view", global_course_id) do
      course.restrict_student_past_view?
    end
  end

  def restrict_future_view?
    view_restrictable? && RequestCache.cache("restrict_student_future_view", global_course_id) do
      course.restrict_student_future_view?
    end
  end

  def restrict_future_listing?
    enrollment_state.pending? &&
      (enrollment_state.restricted_access? || (!admin? && course.unpublished?)) &&
      course.account.restrict_student_future_listing[:value]
  end

  def active?
    state_based_on_date == :active
  end

  def inactive?
    state_based_on_date == :inactive
  end

  def hard_inactive?
    workflow_state == "inactive"
  end

  def invited?
    state_based_on_date == :invited
  end

  def accepted?
    state_based_on_date == :accepted
  end

  def completed?
    enrollment_state.get_display_state == :completed
  end

  def explicitly_completed?
    state == :completed
  end

  def completed_at
    if (date = read_attribute(:completed_at))
      date
    elsif !new_record? && completed?
      enrollment_state.state_started_at
    end
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"
    result = save
    if saved_change_to_workflow_state?
      user.try(:update_account_associations)
      scores.update_all(updated_at: Time.zone.now, workflow_state: :deleted)
      Enrollment.recompute_final_score_in_singleton(
        user.id,
        course.id
      )

      Assignment.remove_user_as_final_grader(user_id, course_id) if remove_user_as_final_grader?
    end
    result
  end

  def restore
    self.workflow_state = "active"
    self.completed_at = nil
    save
    true
  end

  def re_send_confirmation!
    @re_send_confirmation = true
    save
    @re_send_confirmation = false
    true
  end

  def re_send_confirmation_if_invited!
    re_send_confirmation! if invited?
  end

  def has_permission_to?(action)
    @permission_lookup ||= {}
    unless @permission_lookup.key? action
      @permission_lookup[action] = RoleOverride.enabled_for?(course, action, self.role_id, nil)
    end
    @permission_lookup[action].include?(:self)
  end

  def base_role_name
    self.class.to_s
  end

  # Determine if a user has permissions to conclude this enrollment.
  #
  # user    - The user requesting permission to conclude/delete enrollment.
  # context - The current context, e.g. course or section.
  # session - The current user's session (pass nil if not available).
  #
  # return Boolean
  def can_be_concluded_by(user, context, session)
    can_remove = [StudentEnrollment].include?(self.class) &&
                 context.grants_right?(user, session, :manage_students) &&
                 context.id == (context.is_a?(Course) ? course_id : course_section_id)
    can_remove || context.grants_right?(user, session, manage_admin_users_perm)
  end

  # Determine if a user has permissions to delete this enrollment.
  #
  # user    - The user requesting permission to conclude/delete enrollment.
  # context - The current context, e.g. course or section.
  # session - The current user's session (pass nil if not available).
  #
  # return Boolean
  def can_be_deleted_by(user, context, session)
    return context.grants_right?(user, session, :use_student_view) if fake_student?

    if root_account.feature_enabled? :granular_permissions_manage_users
      can_remove = can_delete_via_granular(user, session, context)
      can_remove &&= user_id != user.id || context.account.grants_right?(user, session, :allow_course_admin_actions)
    else
      can_remove = context.grants_right?(user, session, :manage_admin_users) && !student?
      can_remove ||= [StudentEnrollment, ObserverEnrollment].include?(self.class) && context.grants_right?(user, session, :manage_students)
      can_remove &&= user_id != user.id || context.account.grants_right?(user, session, :manage_admin_users)
    end
    can_remove && context.id == (context.is_a?(Course) ? course_id : course_section_id)
  end

  def pending?
    invited? || creation_pending?
  end

  def email
    user.email rescue t("#enrollment.default_email", "No Email")
  end

  def user_name
    read_attribute(:user_name) || user.name rescue t("#enrollment.default_user_name", "Unknown User")
  end

  def context
    @context ||= course
  end

  def context_id
    @context_id ||= course_id
  end

  def can_switch_to?(type)
    case type
    when "ObserverEnrollment",
         "StudentEnrollment"
      %w[TeacherEnrollment TaEnrollment DesignerEnrollment].include?(self.type)
    when "TaEnrollment"
      ["TeacherEnrollment"].include?(self.type)
    else
      false
    end
  end

  def self.workflow_readable_type(state)
    case state.to_s
    when "active"
      t("#enrollment.workflow.active", "Active")
    when "completed"
      t("#enrollment.workflow.completed", "Completed")
    when "deleted"
      t("#enrollment.workflow.deleted", "Deleted")
    when "invited"
      t("#enrollment.workflow.invited", "Invited")
    when "pending", "creation_pending"
      t("#enrollment.workflow.pending", "Pending")
    when "rejected"
      t("#enrollment.workflow.rejected", "Rejected")
    when "inactive"
      t("#enrollment.workflow.inactive", "Inactive")
    end
  end

  def readable_role_name
    role.built_in? ? readable_type : role.name
  end

  def readable_type
    Enrollment.readable_type(self.class.to_s)
  end

  # This is called to recompute the users' cached scores for a given course
  # when:
  #
  # * The user is merged with another user; the scores are recomputed for the
  #   new user in each of his/her courses.
  #
  # * An assignment's default grade is changed; all users in the assignment's
  #   course have their scores for that course recomputed.
  #
  # * A course is merged into another, a section is crosslisted/uncrosslisted,
  #   or a section is otherwise moved between courses; scores are recomputed
  #   for all users in the target course.
  #
  # * A course's group_weighting_scheme is changed; scores are recomputed for
  #   all users in the course.
  #
  # * Assignments are reordered (since an assignment may change groups, which
  #   may have weights); scores are recomputed for all users in the associated
  #   course.
  #
  # * An assignment's points_possible is changed; scores are recomputed for all
  #   users in the associated course.
  #
  # * An assignment group's rules or group_weight are changed; scores are
  #   recomputed for all users in the associated course.
  #
  # * A submission's score is changed; scores for the submission owner in the
  #   associated course are recomputed.
  #
  # * An assignment is deleted/undeleted
  #
  # * An enrollment is accepted (to address the scenario where a student
  #   is transferred from one section to another, and final grades need
  #   to be transferred)
  #
  # If some new feature comes up that affects calculation of a user's score,
  # please add appropriate calls to this so that the cached values don't get
  # stale! And once you've added the call, add the condition to the comment
  # here for future enlightenment.

  def self.recompute_final_score(*args, **kwargs)
    GradeCalculator.recompute_final_score(*args, **kwargs)
  end

  # This method is intended to not duplicate work for a single user.
  def self.recompute_final_score_in_singleton(user_id, course_id, **opts)
    # Guard against getting more than one user_id
    raise ArgumentError, "Cannot call with more than one user" if Array(user_id).size > 1

    delay_if_production(singleton: "Enrollment.recompute_final_score:#{user_id}:#{course_id}:#{opts[:grading_period_id]}",
                        max_attempts: 10)
      .recompute_final_score(user_id, course_id, **opts)
  end

  def self.recompute_due_dates_and_scores(user_id)
    Course.where(id: StudentEnrollment.where(user_id:).distinct.pluck(:course_id)).each do |course|
      SubmissionLifecycleManager.recompute_users_for_course([user_id], course, nil, update_grades: true)
    end
  end

  def self.recompute_final_scores(user_id)
    StudentEnrollment.where(user_id:).distinct.pluck(:course_id).each do |course_id|
      recompute_final_score_in_singleton(user_id, course_id)
    end
  end

  def computed_current_grade(id_opts = nil)
    cached_score_or_grade(:current, :grade, :posted, id_opts)
  end

  def computed_final_grade(id_opts = nil)
    cached_score_or_grade(:final, :grade, :posted, id_opts)
  end

  def computed_current_score(id_opts = nil)
    cached_score_or_grade(:current, :score, :posted, id_opts)
  end

  def computed_final_score(id_opts = nil)
    cached_score_or_grade(:final, :score, :posted, id_opts)
  end

  def effective_current_grade(id_opts = nil)
    score = find_score(id_opts)

    if score&.overridden? && course.allow_final_grade_override?
      score.effective_final_grade
    else
      computed_current_grade(id_opts)
    end
  end

  def effective_current_score(id_opts = nil)
    score = find_score(id_opts)

    if score&.overridden? && course.allow_final_grade_override?
      score.effective_final_score
    else
      computed_current_score(id_opts)
    end
  end

  def effective_final_grade(id_opts = nil)
    score = find_score(id_opts)

    if score&.overridden? && course.allow_final_grade_override?
      score.effective_final_grade
    else
      computed_final_grade(id_opts)
    end
  end

  def effective_final_score(id_opts = nil)
    score = find_score(id_opts)

    if score&.overridden? && course.allow_final_grade_override?
      score.effective_final_score
    else
      computed_final_score(id_opts)
    end
  end

  def effective_final_grade_custom_status_id(id_opts = nil)
    score = find_score(id_opts)

    score.custom_grade_status_id if score&.overridden? && course.allow_final_grade_override?
  end

  def override_grade(id_opts = nil)
    return nil unless course.allow_final_grade_override? && course.grading_standard_enabled?

    score = find_score(id_opts)
    score.effective_final_grade if score&.override_score
  end

  def override_score(id_opts = nil)
    return nil unless course.allow_final_grade_override?

    score = find_score(id_opts)
    score&.override_score
  end

  def computed_current_points(id_opts = nil)
    find_score(id_opts)&.current_points
  end

  def computed_final_points(id_opts = nil)
    find_score(id_opts)&.final_points
  end

  def unposted_current_points(id_opts = nil)
    find_score(id_opts)&.unposted_current_points
  end

  def unposted_current_grade(id_opts = nil)
    cached_score_or_grade(:current, :grade, :unposted, id_opts)
  end

  def unposted_final_grade(id_opts = nil)
    cached_score_or_grade(:final, :grade, :unposted, id_opts)
  end

  def unposted_current_score(id_opts = nil)
    cached_score_or_grade(:current, :score, :unposted, id_opts)
  end

  def unposted_final_score(id_opts = nil)
    cached_score_or_grade(:final, :score, :unposted, id_opts)
  end

  def cached_score_or_grade(current_or_final, score_or_grade, posted_or_unposted, id_opts = nil)
    score = find_score(id_opts)
    method = +"#{current_or_final}_#{score_or_grade}"
    method.prepend("unposted_") if posted_or_unposted == :unposted
    score&.send(method)
  end
  private :cached_score_or_grade

  def find_score(id_opts = nil)
    id_opts ||= Score.params_for_course
    given_score = id_opts.delete(:score)
    return given_score if given_score

    valid_keys = %i[course_score grading_period grading_period_id assignment_group assignment_group_id]
    return nil if id_opts.except(*valid_keys).any?

    result = if scores.loaded?
               scores.detect { |score| score.attributes >= id_opts.with_indifferent_access }
             else
               scores.where(id_opts).first
             end
    if result
      result.enrollment = self
      # have to go through gymnastics to force-preload a has_one :through without causing a db transaction
      if association(:course).loaded?
        assn = result.association(:course)
        assn.target = course
      end
    end
    result
  end

  def graded_at
    find_score&.updated_at
  end

  def self.typed_enrollment(type)
    return nil unless %w[StudentEnrollment
                         StudentViewEnrollment
                         TeacherEnrollment
                         TaEnrollment
                         ObserverEnrollment
                         DesignerEnrollment].include?(type)

    type.constantize
  end

  # overridden to return true in appropriate subclasses
  def student?
    false
  end

  def fake_student?
    false
  end

  def student_with_conditions?(include_future:, include_fake_student:)
    return false unless student? || fake_student?

    if include_fake_student
      include_future || participating?
    else
      include_future ? student? : participating_student?
    end
  end

  def temporary_enrollment?
    temporary_enrollment_source_user_id.present?
  end

  def temporary_enrollment_source_user
    return nil unless temporary_enrollment?

    User.find(temporary_enrollment_source_user_id)
  end

  def observer?
    false
  end

  def teacher?
    false
  end

  def ta?
    false
  end

  def designer?
    false
  end

  def instructor?
    teacher? || ta?
  end

  def admin?
    instructor? || designer?
  end

  def content_admin?
    teacher? || designer?
  end

  def to_atom
    {
      title: t("#enrollment.title", "%{user_name} in %{course_name}", user_name:, course_name:),
      updated: updated_at,
      published: created_at,
      link: "/courses/#{course.id}/enrollments/#{id}"
    }
  end

  set_policy do
    given { |user, session| course.grants_any_right?(user, session, :manage_students, manage_admin_users_perm, :read_roster) }
    can :read

    given { |user| self.user == user }
    can :read and can :read_grades

    given do |user, session|
      course.students_visible_to(user, include: :priors).where(id: user_id).exists? &&
        course.grants_any_right?(user, session, :manage_grades, :view_all_grades)
    end
    can :read and can :read_grades

    given { |user| course.observer_enrollments.where(user_id: user, associated_user_id: user_id).exists? }
    can :read and can :read_grades

    given { |user, session| course.grants_right?(user, session, :participate_as_student) && self.user.show_user_services }
    can :read_services

    # read_services says this person has permission to see what web services this enrollment has linked to their account
    given { |user, session| grants_right?(user, session, :read) && self.user.show_user_services }
    can :read_services
  end

  scope :before, lambda { |date|
    where("enrollments.created_at<?", date)
  }

  scope :for_user, ->(user) { where(user_id: user) }

  scope :for_courses_with_user_name, lambda { |courses|
    where(course_id: courses)
      .joins(:user)
      .select("user_id, course_id, users.name AS user_name")
  }
  scope :invited, -> { where(workflow_state: "invited") }
  scope :accepted, -> { where("enrollments.workflow_state<>'invited'") }
  scope :active_or_pending, -> { where("enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted', 'inactive')") }
  scope :all_active_or_pending, -> { where("enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted')") } # includes inactive

  scope :excluding_pending, -> { joins(:enrollment_state).where.not(enrollment_states: { state: EnrollmentState::PENDING_STATES }) }
  scope :active_by_date, -> { joins(:enrollment_state).where("enrollment_states.state = 'active'") }
  scope :invited_by_date, lambda {
                            joins(:enrollment_state).where(enrollment_states: { restricted_access: false })
                                                    .where("enrollment_states.state IN ('invited', 'pending_invited')")
                          }
  scope :active_or_pending_by_date, lambda {
                                      joins(:enrollment_state).where(enrollment_states: { restricted_access: false })
                                                              .where("enrollment_states.state IN ('active', 'invited', 'pending_invited', 'pending_active')")
                                    }
  scope :invited_or_pending_by_date, lambda {
                                       joins(:enrollment_state).where(enrollment_states: { restricted_access: false })
                                                               .where("enrollment_states.state IN ('invited', 'pending_invited', 'pending_active')")
                                     }
  scope :completed_by_date,
        -> { joins(:enrollment_state).where(enrollment_states: { restricted_access: false, state: "completed" }) }
  scope :not_inactive_by_date, lambda {
                                 joins(:enrollment_state).where(enrollment_states: { restricted_access: false })
                                                         .where("enrollment_states.state IN ('active', 'invited', 'completed', 'pending_invited', 'pending_active')")
                               }

  scope :active_or_pending_by_date_ignoring_access, lambda {
                                                      joins(:enrollment_state)
                                                        .where("enrollment_states.state IN ('active', 'invited', 'pending_invited', 'pending_active')")
                                                    }
  scope :not_inactive_by_date_ignoring_access, lambda {
                                                 joins(:enrollment_state)
                                                   .where("enrollment_states.state IN ('active', 'invited', 'completed', 'pending_invited', 'pending_active')")
                                               }
  scope :new_or_active_by_date, lambda {
                                  joins(:enrollment_state)
                                    .where("enrollment_states.state IN ('active', 'invited', 'pending_invited', 'pending_active', 'creation_pending')")
                                }

  scope :currently_online, -> { joins(:pseudonyms).where("pseudonyms.last_request_at>?", 5.minutes.ago) }
  # this returns enrollments for creation_pending users; should always be used in conjunction with the invited scope
  scope :for_email, lambda { |email|
    joins(user: :communication_channels)
      .where("users.workflow_state='creation_pending' AND communication_channels.workflow_state='unconfirmed' AND path_type='email' AND LOWER(path)=LOWER(?)", email)
      .select("enrollments.*")
      .readonly(false)
  }
  def self.cached_temporary_invitations(email)
    if Enrollment.cross_shard_invitations?
      Shard.birth.activate do
        Rails.cache.fetch([email, "all_invited_enrollments2"].cache_key) do
          Shard.with_each_shard(CommunicationChannel.associated_shards(email)) do
            Enrollment.invited.for_email(email).to_a
          end
        end
      end
    else
      Rails.cache.fetch([email, "invited_enrollments2"].cache_key) do
        Enrollment.invited.for_email(email).to_a
      end
    end
  end

  def self.order_by_sortable_name
    clause = User.sortable_name_order_by_clause("users")
    scope = order(clause)
    if scope.select_values.present?
      scope.select(clause)
    else
      scope.select(arel_table[Arel.star])
    end
  end

  def self.top_enrollment_by(key, rank_order = :default)
    raise "top_enrollment_by_user must be scoped" unless all.where_clause.present?

    key = key.to_s
    order(Arel.sql("#{key}, #{type_rank_sql(rank_order)}")).distinct_on(key)
  end

  def assign_uuid
    # DON'T use ||=, because that will cause an immediate save to the db if it
    # doesn't already exist
    self.uuid = CanvasSlug.generate_securish_uuid unless read_attribute(:uuid)
  end
  protected :assign_uuid

  def uuid
    unless read_attribute(:uuid)
      update_attribute(:uuid, CanvasSlug.generate_securish_uuid)
    end
    read_attribute(:uuid)
  end

  def self.limit_privileges_to_course_section!(course, user, limit)
    course.shard.activate do
      Enrollment.where(course_id: course, user_id: user).each do |enrollment|
        enrollment.limit_privileges_to_course_section = !!limit
        enrollment.save!
      end
    end
    user.clear_cache_key(:enrollments)
  end

  def self.course_user_state(course, uuid)
    Rails.cache.fetch(["user_state", course, uuid].cache_key) do
      enrollment = course.enrollments.where(uuid:).first
      if enrollment
        {
          enrollment_state: enrollment.workflow_state,
          user_state: enrollment.user.state,
          is_admin: enrollment.admin?
        }
      else
        nil
      end
    end
  end

  def self.serialization_excludes
    %i[uuid computed_final_score computed_current_score]
  end

  # enrollment term per-section is deprecated; a section's term is inherited from the
  # course it is currently tied to
  delegate :enrollment_term, to: :course

  def effective_start_at
    # try and use the enrollment dates logic first, since it knows about
    # overrides, etc. but if it doesn't find anything, start guessing by
    # looking at the enrollment, section, course, then term. if we still didn't
    # find it, fall back to the section or course creation date.
    enrollment_dates.filter_map(&:first).min ||
      start_at ||
      course_section&.start_at ||
      course.start_at ||
      course.enrollment_term&.start_at ||
      course_section&.created_at ||
      course.created_at
  end

  def effective_end_at
    # try and use the enrollment dates logic first, since it knows about
    # overrides, etc. but if it doesn't find anything, start guessing by
    # looking at the enrollment, section, course, then term.
    enrollment_dates.filter_map(&:last).max ||
      end_at ||
      course_section&.end_at ||
      course.conclude_at ||
      course.enrollment_term&.end_at
  end

  def self.cross_shard_invitations?
    false
  end

  def total_activity_time
    read_attribute(:total_activity_time).to_i
  end

  def touch_graders_if_needed
    if !active_student? && active_student?(:was) && course.submissions.where(user_id:).exists?
      self.class.connection.after_transaction_commit do
        course.admins.clear_cache_keys(:todo_list)
      end
    end
  end

  def update_assignment_overrides_if_needed
    assignment_scope = Assignment.where(context_id: course_id, context_type: "Course")
    override_scope = AssignmentOverrideStudent.where(user_id:)

    if being_deleted? && !enrollments_exist_for_user_in_course?
      return unless (assignment_ids = assignment_scope.pluck(:id)).any?

      # this is handled in after_commit :update_cached_due_dates
      AssignmentOverrideStudent.suspend_callbacks(:update_cached_due_dates) do
        override_scope.where(assignment_id: assignment_ids).find_each(&:destroy)
      end
    end

    if being_accepted?
      return unless ConditionalRelease::Service.enabled_in_context?(course)

      # Deleted student overrides associated with assignments with a Mastery Path override
      releases = override_scope.where(workflow_state: "deleted")
                               .where(assignment: assignment_scope)
                               .joins(assignment: :assignment_overrides)
                               .where(assignment_overrides: {
                                        set_type: AssignmentOverride::SET_TYPE_NOOP,
                                        set_id: AssignmentOverride::NOOP_MASTERY_PATHS,
                                        workflow_state: "active"
                                      }).distinct
      return unless releases.exists?

      # Add parent join to reduce duplication, which are used in both cases below
      releases = releases
                 .joins("INNER JOIN #{AssignmentOverride.quoted_table_name} parent ON assignment_override_students.assignment_override_id = parent.id")
      # Restore student overrides associated with an active assignment override
      releases.where("parent.workflow_state = 'active'").update(workflow_state: "active")
      # Restore student overrides and assignment overrides if assignment override is deleted
      releases.preload(:assignment_override).where("parent.workflow_state = 'deleted'").find_each do |release|
        release.update(workflow_state: "active")
        release.assignment_override.update(workflow_state: "active")
      end
    end
  end

  def section_or_course_date_in_past?
    if course_section&.end_at
      course_section.end_at < Time.zone.now
    elsif course.conclude_at
      course.conclude_at < Time.zone.now
    end
  end

  def student_or_fake_student?
    ["StudentEnrollment", "StudentViewEnrollment"].include?(type)
  end

  def allows_favoriting?
    !(course.elementary_subject_course? || course.elementary_homeroom_course?) || teacher? || ta? || designer? || user.roles(root_account).include?("teacher")
  end

  private

  def enrollments_exist_for_user_in_course?
    Enrollment.active.where(user_id:, course_id:).exists?
  end

  def copy_scores_from_existing_enrollment
    Score.where(enrollment_id: self).each(&:destroy_permanently!)
    other_enrollment_of_same_type_with_score.scores.each { |score| score.dup.update!(enrollment: self) }
  end

  def need_to_copy_scores?
    return false unless saved_change_to_id? || being_restored?

    student_or_fake_student? && other_enrollment_of_same_type_with_score.present?
  end

  def other_enrollment_of_same_type_with_score
    return @other_enrollment_of_same_type_with_score if defined?(@other_enrollment_of_same_type_with_score)

    @other_enrollment_of_same_type_with_score = other_enrollments_of_type(type).joins(:scores).first
  end

  def other_enrollments_of_type(types)
    Enrollment.where(
      course_id: course,
      user_id: user,
      type: Array.wrap(types)
    ).where.not(id:).where.not(workflow_state: :deleted)
  end

  def manage_admin_users_perm
    root_account.feature_enabled?(:granular_permissions_manage_users) ? :allow_course_admin_actions : :manage_admin_users
  end

  def can_delete_via_granular(user, session, context)
    (teacher? && context.grants_right?(user, session, :remove_teacher_from_course)) ||
      (ta? && context.grants_right?(user, session, :remove_ta_from_course)) ||
      (designer? && context.grants_right?(user, session, :remove_designer_from_course)) ||
      (observer? && context.grants_right?(user, session, :remove_observer_from_course)) ||
      (student? && context.grants_right?(user, session, :remove_student_from_course))
  end

  def remove_user_as_final_grader?
    instructor? &&
      !other_enrollments_of_type(["TaEnrollment", "TeacherEnrollment"]).exists?
  end

  def being_accepted?
    saved_change_to_workflow_state? && workflow_state == "active" && workflow_state_before_last_save == "invited"
  end

  def being_restored?(to_state: workflow_state)
    saved_change_to_workflow_state? && workflow_state_before_last_save == "deleted" && workflow_state == to_state
  end

  def being_reactivated?
    saved_change_to_workflow_state? && workflow_state != "deleted" && workflow_state_before_last_save == "inactive"
  end

  def being_uncompleted?
    saved_change_to_workflow_state? && workflow_state != "deleted" && workflow_state_before_last_save == "completed"
  end

  def being_deleted?
    workflow_state == "deleted" && workflow_state_before_last_save != "deleted"
  end

  def sync_microsoft_group
    return if type == "StudentViewEnrollment"
    return unless root_account.feature_enabled?(:microsoft_group_enrollments_syncing)
    return unless root_account.settings[:microsoft_sync_enabled]

    MicrosoftSync::Group.not_deleted.find_by(course_id:)&.enqueue_future_partial_sync self
  end
end
