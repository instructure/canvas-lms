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

require 'atom'

class Enrollment < ActiveRecord::Base

  SIS_TYPES = {
      'TeacherEnrollment' => 'teacher',
      'TaEnrollment' => 'ta',
      'DesignerEnrollment' => 'designer',
      'StudentEnrollment' => 'student',
      'ObserverEnrollment' => 'observer'
  }

  include Workflow

  belongs_to :course, touch: true, inverse_of: :enrollments
  belongs_to :course_section, inverse_of: :enrollments
  belongs_to :root_account, class_name: 'Account', inverse_of: :enrollments
  belongs_to :user, inverse_of: :enrollments
  belongs_to :sis_pseudonym, class_name: 'Pseudonym', inverse_of: :sis_enrollments
  belongs_to :associated_user, :class_name => 'User'

  belongs_to :role
  include Role::AssociationHelper

  has_one :enrollment_state, :dependent => :destroy, inverse_of: :enrollment

  has_many :role_overrides, :as => :context, :inverse_of => :context
  has_many :pseudonyms, :primary_key => :user_id, :foreign_key => :user_id
  has_many :course_account_associations, :foreign_key => 'course_id', :primary_key => 'course_id'
  has_many :scores, -> { active }

  validates_presence_of :user_id, :course_id, :type, :root_account_id, :course_section_id, :workflow_state, :role_id
  validates_inclusion_of :limit_privileges_to_course_section, :in => [true, false]
  validates_inclusion_of :associated_user_id, :in => [nil],
                         :unless => lambda { |enrollment| enrollment.type == 'ObserverEnrollment' },
                         :message => "only ObserverEnrollments may have an associated_user_id"
  validate :cant_observe_self, :if => lambda { |enrollment| enrollment.type == 'ObserverEnrollment' }

  validate :valid_role?
  validate :valid_course?
  validate :valid_section?

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
  after_save :restore_submissions_and_scores
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

  attr_accessor :already_enrolled, :need_touch_user, :skip_touch_user
  scope :current, -> { joins(:course).where(QueryBuilder.new(:active).conditions).readonly(false) }
  scope :current_and_invited, -> { joins(:course).where(QueryBuilder.new(:current_and_invited).conditions).readonly(false) }
  scope :current_and_future, -> { joins(:course).where(QueryBuilder.new(:current_and_future).conditions).readonly(false) }
  scope :concluded, -> { joins(:course).where(QueryBuilder.new(:completed).conditions).readonly(false) }
  scope :current_and_concluded, -> { joins(:course).where(QueryBuilder.new(:current_and_concluded).conditions).readonly(false) }

  def self.not_yet_started(course)
    collection = self.where(course_id: course).to_a
    Canvas::Builders::EnrollmentDateBuilder.preload(collection)
    collection.select do |enrollment|
      enrollment.effective_start_at > Time.zone.now
    end
  end

  def self.section_ended(course_id)
    collection = self.where(course_id: course_id).to_a
    Canvas::Builders::EnrollmentDateBuilder.preload(collection)
    courses = Course.where(id: course_id)
    unless courses[0].nil?
      collection.select do |enrollment|
        (!enrollment.course_section.end_at.nil? &&
         enrollment.course_section.end_at < courses[0].time_zone.now) ||
          (!enrollment.course_section.start_at.nil? &&
           enrollment.course_section.start_at >  courses[0].time_zone.now)
      end
    end
  end

  def ensure_role_id
    self.role_id ||= self.role.id
  end

  def cant_observe_self
    self.errors.add(:associated_user_id, "Cannot observe yourself") if self.user_id == self.associated_user_id
  end

  def valid_course?
    if !deleted? && course.deleted?
      self.errors.add(:course_id, "is not a valid course")
    end
  end

  def valid_section?
    unless deleted? || course_section.active?
      self.errors.add(:course_section_id, "is not a valid section")
    end
  end

  def valid_role?
    return true if self.deleted? || role.built_in?

    unless self.role.base_role_type == self.type
      self.errors.add(:role_id, "is not valid for the enrollment type")
    end

    unless self.course.account.valid_role?(role)
      self.errors.add(:role_id, "is not an available role for this course's account")
    end
  end

  def self.get_built_in_role_for_type(enrollment_type)
    role = Role.get_built_in_role("StudentEnrollment") if enrollment_type == "StudentViewEnrollment"
    role ||= Role.get_built_in_role(enrollment_type)
    role
  end

  def default_role
    Enrollment.get_built_in_role_for_type(self.type)
  end

  # see #active_student?
  def self.active_student_conditions
    "(enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment') AND enrollments.workflow_state = 'active')"
  end

  # see .active_student_conditions
  def active_student?(was = false)
    suffix = was ? "_before_last_save" : ""

    %w[StudentEnrollment StudentViewEnrollment].include?(send("type#{suffix}")) &&
      send("workflow_state#{suffix}") == "active"
  end

  def active_student_changed?
    active_student? != active_student?(:was)
  end

  def touch_assignments
    Assignment.
      where(context_id: course_id, context_type: 'Course').
      where("EXISTS (?) AND NOT EXISTS (?)",
        Submission.where(user_id: user_id).
          where("assignment_id=assignments.id").
          where("#{Submission.needs_grading_conditions} OR
            (workflow_state = 'deleted' AND submission_type IS NOT NULL AND
            (score IS NULL OR NOT grade_matches_current_submission OR
            (submission_type = 'online_quiz' AND quiz_submission_id IS NOT NULL)))"),
        Enrollment.where(Enrollment.active_student_conditions).
          where(user_id: user_id, course_id: course_id).
          where("id<>?", self)).
      update_all(["updated_at=?", Time.now.utc])
  end

  def needs_grading_count_updated
    self.class.connection.after_transaction_commit do
      touch_assignments
    end
  end

  include StickySisFields
  are_sis_sticky :start_at, :end_at

  has_a_broadcast_policy

  set_broadcast_policy do |p|
    p.dispatch :enrollment_invitation
    p.to { self.user }
    p.whenever { |record|
      !record.self_enrolled &&
      record.course &&
      record.user.registered? &&
      !record.observer? &&
      ((record.invited? && (record.just_created || record.saved_change_to_workflow_state?)) || @re_send_confirmation)
    }

    p.dispatch :enrollment_registration
    p.to { self.user.communication_channel }
    p.whenever { |record|
      !record.self_enrolled &&
      record.course &&
      !record.user.registered? &&
      ((record.invited? && (record.just_created || record.saved_change_to_workflow_state?)) || @re_send_confirmation)
    }

    p.dispatch :enrollment_notification
    p.to { self.user }
    p.whenever { |record|
      !record.self_enrolled &&
      record.course &&
      !record.course.created? &&
      !record.observer? &&
      record.just_created && record.active?
    }

    p.dispatch :enrollment_accepted
    p.to {self.course.participating_admins.restrict_to_sections([self.course_section_id]) - [self.user] }
    p.whenever { |record|
      record.course &&
      !record.observer? &&
      !record.just_created && (record.changed_state(:active, :invited) || record.changed_state(:active, :creation_pending))
    }
  end

  def dispatch_invitations_later
    # if in an invited state but not frd "invited?" because of future date restrictions, send it later
    if (self.just_created || self.saved_change_to_workflow_state? || @re_send_confirmation) && self.workflow_state == 'invited' && self.inactive? && self.available_at &&
        !self.self_enrolled && !(self.observer? && self.user.registered?)
      # this won't work if they invite them and then change the course/term/section dates _afterwards_ so hopefully people don't do that
      self.send_later_enqueue_args(:re_send_confirmation_if_invited!, {:run_at => self.available_at, :singleton => "send_enrollment_invitations_#{global_id}"})
    end
  end

  scope :active, -> { where("enrollments.workflow_state<>'deleted'") }

  scope :admin, -> {
    select(:course_id).
        joins(:course).
        where("enrollments.type IN ('TeacherEnrollment','TaEnrollment', 'DesignerEnrollment') AND (courses.workflow_state IN ('created', 'claimed') OR (enrollments.workflow_state='active' AND courses.workflow_state='available'))") }

  scope :instructor, -> {
    select(:course_id).
        joins(:course).
        where("enrollments.type IN ('TeacherEnrollment','TaEnrollment') AND (courses.workflow_state IN ('created', 'claimed') OR (enrollments.workflow_state='active' AND courses.workflow_state='available'))") }

  scope :of_student_type, -> { where(:type => "StudentEnrollment") }

  scope :of_admin_type, -> { where(:type => ['TeacherEnrollment','TaEnrollment', 'DesignerEnrollment']) }

  scope :of_instructor_type, -> { where(:type => ['TeacherEnrollment', 'TaEnrollment']) }

  scope :of_content_admins, -> { where(:type => ['TeacherEnrollment', 'DesignerEnrollment']) }

  scope :student, -> {
    select(:course_id).
        joins(:course).
        where(:type => 'StudentEnrollment', :workflow_state => 'active', :courses => { :workflow_state => 'available' }) }

  scope :student_in_claimed_or_available, -> {
    select(:course_id).
        joins(:course).
        where(:type => 'StudentEnrollment', :workflow_state => 'active', :courses => { :workflow_state => ['available', 'claimed', 'created'] }) }

  scope :all_student, -> {
    eager_load(:course).
        where("(enrollments.type = 'StudentEnrollment'
              AND enrollments.workflow_state IN ('invited', 'active', 'completed')
              AND courses.workflow_state IN ('available', 'completed')) OR
              (enrollments.type = 'StudentViewEnrollment'
              AND enrollments.workflow_state = 'active'
              AND courses.workflow_state != 'deleted')") }

  scope :not_deleted, -> {
    joins(:course).
        where("(courses.workflow_state<>'deleted') AND (enrollments.workflow_state<>'deleted')")
  }

  scope :not_fake, -> { where("enrollments.type<>'StudentViewEnrollment'") }


  def self.readable_types
    # with enough use, even translations can add up
    RequestCache.cache('enrollment_readable_types') do
      {
        'TeacherEnrollment' => t('#enrollment.roles.teacher', "Teacher"),
        'TaEnrollment' => t('#enrollment.roles.ta', "TA"),
        'DesignerEnrollment' => t('#enrollment.roles.designer', "Designer"),
        'StudentEnrollment' => t('#enrollment.roles.student', "Student"),
        'StudentViewEnrollment' => t('#enrollment.roles.student', "Student"),
        'ObserverEnrollment' => t('#enrollment.roles.observer', "Observer")
      }
    end
  end

  def self.readable_type(type)
    readable_types[type] || readable_types['StudentEnrollment']
  end

  def self.sis_type(type)
    SIS_TYPES[type] || SIS_TYPES['StudentEnrollment']
  end

  def sis_type
    Enrollment.sis_type(self.type)
  end

  def sis_role
    (!self.role.built_in? && self.role.name) || Enrollment.sis_type(self.type)
  end

  def self.valid_types
    SIS_TYPES.keys
  end

  def self.valid_type?(type)
    SIS_TYPES.has_key?(type)
  end

  def self.types_with_indefinite_article
    {
      'TeacherEnrollment' => t('#enrollment.roles.teacher_with_indefinite_article', "A Teacher"),
      'TaEnrollment' => t('#enrollment.roles.ta_with_indefinite_article', "A TA"),
      'DesignerEnrollment' => t('#enrollment.roles.designer_with_indefinite_article', "A Designer"),
      'StudentEnrollment' => t('#enrollment.roles.student_with_indefinite_article', "A Student"),
      'StudentViewEnrollment' => t('#enrollment.roles.student_with_indefinite_article', "A Student"),
      'ObserverEnrollment' => t('#enrollment.roles.observer_with_indefinite_article', "An Observer")
    }
  end

  def self.type_with_indefinite_article(type)
    types_with_indefinite_article[type] || types_with_indefinite_article['StudentEnrollment']
  end

  def reload(options = nil)
    @enrollment_dates = nil
    super
  end

  def should_update_user_account_association?
    self.id_before_last_save.nil? || self.saved_change_to_course_id? || self.saved_change_to_course_section_id? ||
      self.saved_change_to_root_account_id? || being_restored?
  end

  def update_user_account_associations_if_necessary
    return if self.fake_student?
    if id_before_last_save.nil? || being_restored?
      return if %w{creation_pending deleted}.include?(self.user.workflow_state)
      associations = User.calculate_account_associations_from_accounts([self.course.account_id, self.course_section.course.account_id, self.course_section.nonxlist_course.try(:account_id)].compact.uniq)
      self.user.update_account_associations(:incremental => true, :precalculated_associations => associations)
    elsif should_update_user_account_association?
      self.user.update_account_associations_later
    end
  end
  protected :update_user_account_associations_if_necessary

  def other_section_enrollment_exists?
    # If other active sessions that the user is enrolled in exist.
    self.course.student_enrollments.where.not(:workflow_state => ['deleted', 'rejected']).for_user(self.user).where.not(id: self.id).exists?
  end

  def audit_groups_for_deleted_enrollments
    # did the student cease to be enrolled in a non-deleted state in a section?
    had_section = self.course_section_id_was.present?
    deleted_states = ['deleted', 'rejected']
    was_active = !deleted_states.include?(self.workflow_state_was)
    is_deleted = deleted_states.include?(self.workflow_state)
    return unless had_section && was_active &&
                  (self.course_section_id_changed? || is_deleted)

    # what section the user is abandoning, and the section they're moving to
    # (if it's in the same course and the enrollment's not deleted)
    section = CourseSection.find(self.course_section_id_was)

    # ok, consider groups the user is in from the abandoned section's course
    self.user.groups.preload(:group_category).where(
      :context_type => 'Course', :context_id => section.course_id).each do |group|

      # check group deletion criteria if either enrollment is not a deletion
      # or it may be a deletion/unenrollment from a section but not from the course as a whole (still enrolled in another section)
      if !is_deleted || other_section_enrollment_exists?
        # don't bother unless the group's category has section restrictions
        next unless group.group_category && group.group_category.restricted_self_signup?

        # skip if the user is the only user in the group. there's no one to have
        # a conflicting section.
        next unless group.users.where.not(id: self.user_id).exists?

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
      membership = group.group_memberships.where(user_id: self.user_id).first
      membership.destroy if membership
    end
  end
  protected :audit_groups_for_deleted_enrollments

  def observers
    student? ? user.linked_observers.active.linked_through_root_account(self.root_account) : []
  end

  def create_linked_enrollments
    observers.each do |observer|
      create_linked_enrollment_for(observer)
    end
  end

  def update_linked_enrollments
    observers.each do |observer|
      if enrollment = active_linked_enrollment_for(observer)
        enrollment.update_from(self)
      elsif self.saved_change_to_workflow_state? && self.workflow_state_before_last_save == 'inactive'
        create_linked_enrollment_for(observer)
      end
    end
  end

  def create_linked_enrollment_for(observer)
    # we don't want to create a new observer enrollment if one exists
    self.class.unique_constraint_retry do
      enrollment = linked_enrollment_for(observer)
      return true if enrollment && !enrollment.deleted?
      return false unless observer.can_be_enrolled_in_course?(course)
      enrollment ||= observer.observer_enrollments.build
      enrollment.associated_user_id = user_id
      enrollment.shard = shard if enrollment.new_record?
      enrollment.update_from(self, !!@skip_broadcasts)
    end
  end

  def linked_enrollment_for(observer)
    observer.observer_enrollments.where(
      :associated_user_id => user_id,
      :course_section_id => course_section_id_before_last_save || course_section_id).
        shard(Shard.shard_for(course_id)).first
  end

  def active_linked_enrollment_for(observer)
    enrollment = linked_enrollment_for(observer)
    # we don't want to "undelete" observer enrollments that have been
    # explicitly deleted
    return nil if enrollment && enrollment.deleted? && workflow_state_before_last_save != 'deleted'
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
      update_grades = being_restored?(to_state: 'active') || being_restored?(to_state: 'inactive')
      DueDateCacher.recompute_users_for_course(user_id, course, nil, update_grades: update_grades)
    end
  end

  def update_from(other, skip_broadcasts=false)
    self.course_id = other.course_id
    if self.type == 'ObserverEnrollment' && other.workflow_state == 'invited'
      self.workflow_state = 'active'
    else
      self.workflow_state = other.workflow_state
    end
    self.start_at = other.start_at
    self.end_at = other.end_at
    self.course_section_id = other.course_section_id
    self.root_account_id = other.root_account_id
    self.skip_touch_user = other.skip_touch_user
    if skip_broadcasts
      save_without_broadcasting!
    else
      save!
    end
  end

  def clear_email_caches
    if self.saved_change_to_workflow_state? && (self.workflow_state_before_last_save == 'invited' || self.workflow_state == 'invited')
      if Enrollment.cross_shard_invitations?
        Shard.birth.activate do
          self.user.communication_channels.email.unretired.each { |cc| Rails.cache.delete([cc.path, 'all_invited_enrollments2'].cache_key)}
        end
      else
        self.user.communication_channels.email.unretired.each { |cc| Rails.cache.delete([cc.path, 'invited_enrollments2'].cache_key)}
      end
    end
  end

  def cancel_future_appointments
    if saved_change_to_workflow_state? && %w{completed deleted}.include?(workflow_state)
      unless self.course.current_enrollments.where(:user_id => self.user_id).exists? # ignore if they have another still valid enrollment
        course.appointment_participants.active.current.for_context_codes(user.asset_string).update_all(:workflow_state => 'deleted')
      end
    end
  end

  def conclude
    self.workflow_state = "completed"
    self.completed_at = Time.now
    self.user.touch
    self.save
  end

  def unconclude
    self.workflow_state = 'active'
    self.completed_at = nil
    self.user.touch
    self.save
  end

  def deactivate
    self.workflow_state = "inactive"
    self.user.touch
    self.save
  end

  def reactivate
    self.workflow_state = "active"
    self.user.touch
    self.save
  end

  def defined_by_sis?
    !!self.sis_batch_id
  end

  def assigned_observer?
    self.observer? && self.associated_user_id
  end

  def participating?
    self.state_based_on_date == :active
  end

  def participating_student?
    self.student? && self.participating?
  end

  def participating_observer?
    self.observer? && self.participating?
  end

  def participating_teacher?
    self.teacher? && self.participating?
  end

  def participating_ta?
    self.ta? && self.participating?
  end

  def participating_instructor?
    self.instructor? && self.participating?
  end

  def participating_designer?
    self.designer? && self.participating?
  end

  def participating_admin?
    self.admin? && self.participating?
  end

  def participating_content_admin?
    self.content_admin? && self.participating?
  end

  def associated_user_name
    self.associated_user && self.associated_user.short_name
  end

  def assert_section
    self.course_section = self.course.default_section if !self.course_section_id && self.course
    self.root_account_id ||= self.course.root_account_id rescue nil
  end

  def course_name(display_user = nil)
    self.course.nickname_for(display_user) || t('#enrollment.default_course_name', "Course")
  end

  def short_name(length = nil, display_user = nil)
    return @short_name if @short_name
    @short_name = self.course_section.display_name if self.course_section && self.root_account && self.root_account.show_section_name_as_course_name
    @short_name ||= self.course_name(display_user)
    @short_name = @short_name[0..length] if length
    @short_name
  end

  def long_name(display_user = nil)
    return @long_name if @long_name
    @long_name = self.course_name(display_user)
    @long_name = t('#enrollment.with_section', "%{course_name}, %{section_name}", :course_name => @long_name, :section_name => self.course_section.display_name) if self.course_section && self.course_section.display_name && self.course_section.display_name != self.course_name(display_user)
    @long_name
  end

  TYPE_RANKS = {
    :default => ['TeacherEnrollment','TaEnrollment','DesignerEnrollment','StudentEnrollment','StudentViewEnrollment','ObserverEnrollment'],
    :student => ['StudentEnrollment','TeacherEnrollment','TaEnrollment','DesignerEnrollment','StudentViewEnrollment','ObserverEnrollment']
  }
  TYPE_RANK_HASHES = Hash[TYPE_RANKS.map{ |k, v| [k, rank_hash(v)] }]
  def self.type_rank_sql(order = :default)
    # don't call rank_sql during class load
    rank_sql(TYPE_RANKS[order], 'enrollments.type')
  end

  def rank_sortable(order = :default)
    TYPE_RANK_HASHES[order][self.class.to_s]
  end

  STATE_RANK = ['active', ['invited', 'creation_pending'], 'completed', 'inactive', 'rejected', 'deleted']
  STATE_RANK_HASH = rank_hash(STATE_RANK)
  def self.state_rank_sql
    # don't call rank_sql during class load
    @state_rank_sql ||= rank_sql(STATE_RANK, 'enrollments.workflow_state')
  end

  def state_sortable
    STATE_RANK_HASH[state.to_s]
  end

  STATE_BY_DATE_RANK = ['active', ['invited', 'creation_pending', 'pending_active', 'pending_invited'], 'completed', 'inactive', 'rejected', 'deleted']
  STATE_BY_DATE_RANK_HASH = rank_hash(STATE_BY_DATE_RANK)
  def self.state_by_date_rank_sql
    @state_by_date_rank_sql ||= rank_sql(STATE_BY_DATE_RANK, 'enrollment_states.state').
      sub(/^CASE/, "CASE WHEN enrollment_states.restricted_access THEN #{STATE_BY_DATE_RANK.index('inactive')}") # pretend restricted access is the same as inactive
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
    return false unless force || invited?
    update_attribute(:workflow_state, 'active')
    if self.type == 'StudentEnrollment'
      Enrollment.recompute_final_score_in_singleton(self.user_id, self.course_id)
    end
    touch_user
  end

  def reset_notifications_cache
    if self.saved_change_to_workflow_state?
      StreamItemCache.invalidate_recent_stream_items(self.user_id, "Course", self.course_id)
    end
  end

  def add_to_favorites_later
    if self.saved_change_to_workflow_state? && self.workflow_state == 'active'
      self.class.connection.after_transaction_commit do
        self.send_later_if_production_enqueue_args(:add_to_favorites, :priority => Delayed::LOW_PRIORITY)
      end
    end
  end

  def self.batch_add_to_favorites(enrollment_ids)
    Enrollment.where(:id => enrollment_ids).each(&:add_to_favorites)
  end

  def add_to_favorites
    # this method was written by Alan Smithee
    self.user.shard.activate do
      if user.favorites.where(:context_type => 'Course').exists? # only add a favorite if they've ever favorited anything even if it's no longer in effect
        Favorite.unique_constraint_retry do
          user.favorites.where(:context_type => 'Course', :context_id => course).first_or_create!
        end
      end
    end
  end

  workflow do
    state :invited do
      event :reject, :transitions_to => :rejected do self.user.touch; end
      event :complete, :transitions_to => :completed
    end

    state :creation_pending do
      event :invite, :transitions_to => :invited
    end

    state :active do
      event :reject, :transitions_to => :rejected do self.user.touch; end
      event :complete, :transitions_to => :completed
    end

    state :deleted
    state :rejected do
      event :unreject, :transitions_to => :invited
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
      self.shard.activate do
        Shackles.activate(:master) do
          EnrollmentState.unique_constraint_retry do
            EnrollmentState.where(:enrollment_id => self).first_or_create
          end
        end
      end
  end

  def recalculate_enrollment_state
    if (self.saved_changes.keys & %w{workflow_state start_at end_at}).any?
      @enrollment_dates = nil
      self.enrollment_state.state_is_current = false
      self.enrollment_state.is_direct_recalculation = true
    end
    self.enrollment_state.skip_touch_user ||= self.skip_touch_user
    self.enrollment_state.ensure_current_state
  end

  def state_based_on_date
    RequestCache.cache('enrollment_state_based_on_date', self, self.workflow_state, self.saved_changes?) do
      if %w{invited active completed}.include?(self.workflow_state)
        self.enrollment_state.get_effective_state
      else
        self.workflow_state.to_sym
      end
    end
  end

  def readable_state_based_on_date
    # when view restrictions are in place, the effective state_based_on_date is :inactive, but
    # to admins we should show that they are :completed or :pending
    self.enrollment_state.get_display_state
  end

  def available_at
    if self.enrollment_state.pending?
      self.enrollment_state.state_valid_until
    end
  end

  def view_restrictable?
    (self.student? && !self.fake_student?) || self.observer?
  end

  def restrict_past_view?
    self.view_restrictable? && RequestCache.cache('restrict_student_past_view', self.global_course_id) do
      self.course.restrict_student_past_view?
    end
  end

  def restrict_future_view?
    self.view_restrictable? && RequestCache.cache('restrict_student_future_view', self.global_course_id) do
      self.course.restrict_student_future_view?
    end
  end

  def restrict_future_listing?
    self.enrollment_state.pending? &&
      (self.enrollment_state.restricted_access? || (!self.admin? && self.course.unpublished?)) &&
      self.course.account.restrict_student_future_listing[:value]
  end

  def active?
    state_based_on_date == :active
  end

  def inactive?
    state_based_on_date == :inactive
  end

  def hard_inactive?
    workflow_state == 'inactive'
  end

  def invited?
    state_based_on_date == :invited
  end

  def accepted?
    state_based_on_date == :accepted
  end

  def completed?
    self.enrollment_state.get_display_state == :completed
  end

  def explicitly_completed?
    state == :completed
  end

  def completed_at
    if date = self.read_attribute(:completed_at)
      date
    elsif !new_record? && completed?
      self.enrollment_state.state_started_at
    end
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    result = self.save
    if result
      self.user.try(:update_account_associations)
      self.user.touch
      scores.update_all(updated_at: Time.zone.now, workflow_state: :deleted)

      Assignment.remove_user_as_final_grader(user_id, course_id) if remove_user_as_final_grader?
    end
    result
  end

  def restore
    self.workflow_state = 'active'
    self.completed_at = nil
    self.save
    true
  end

  def re_send_confirmation!
    @re_send_confirmation = true
    self.save
    @re_send_confirmation = false
    true
  end

  def re_send_confirmation_if_invited!
    self.re_send_confirmation! if self.invited?
  end

  def has_permission_to?(action)
    @permission_lookup ||= {}
    unless @permission_lookup.has_key? action
      @permission_lookup[action] = RoleOverride.enabled_for?(course, action, self.role, course)
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
      context.id == ((context.is_a? Course) ? self.course_id : self.course_section_id)
    can_remove ||= context.grants_right?(user, session, :manage_admin_users)
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

    can_remove = [StudentEnrollment, ObserverEnrollment].include?(self.class) &&
      context.grants_right?(user, session, :manage_students)
    can_remove ||= context.grants_right?(user, session, :manage_admin_users) unless student?
    can_remove &&= self.user_id != user.id || context.account.grants_right?(user, session, :manage_admin_users)
    can_remove &&= context.id == ((context.is_a? Course) ? self.course_id : self.course_section_id)
  end

  def pending?
    self.invited? || self.creation_pending?
  end

  def email
    self.user.email rescue t('#enrollment.default_email', "No Email")
  end

  def user_name
    read_attribute(:user_name) || self.user.name rescue t('#enrollment.default_user_name', "Unknown User")
  end

  def context
    @context ||= course
  end

  def context_id
    @context_id ||= course_id
  end

  def can_switch_to?(type)
    case type
    when 'ObserverEnrollment'
      ['TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment'].include?(self.type)
    when 'StudentEnrollment'
      ['TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment'].include?(self.type)
    when 'TaEnrollment'
      ['TeacherEnrollment'].include?(self.type)
    else
      false
    end
  end

  def self.workflow_readable_type(state)
    case state.to_s
      when 'active'
        t('#enrollment.workflow.active', "Active")
      when 'completed'
        t('#enrollment.workflow.completed', "Completed")
      when 'deleted'
        t('#enrollment.workflow.deleted', "Deleted")
      when 'invited'
        t('#enrollment.workflow.invited', "Invited")
      when 'pending', 'creation_pending'
        t('#enrollment.workflow.pending', "Pending")
      when 'rejected'
        t('#enrollment.workflow.rejected', "Rejected")
      when 'inactive'
        t('#enrollment.workflow.inactive', "Inactive")
    end
  end

  def readable_role_name
    self.role.built_in? ? self.readable_type : self.role.name
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

  def self.recompute_final_score(*args)
    GradeCalculator.recompute_final_score(*args)
  end

  # This method is intended to not duplicate work for a single user.
  def self.recompute_final_score_in_singleton(user_id, course_id, opts = {})
    # Guard against getting more than one user_id
    raise ArgumentError, "Cannot call with more than one user" if Array(user_id).size > 1

    send_later_if_production_enqueue_args(
      :recompute_final_score,
      {
        singleton: "Enrollment.recompute_final_score:#{user_id}:#{course_id}:#{opts[:grading_period_id]}",
        max_attempts: 10
      },
      user_id,
      course_id,
      opts
    )
  end

  def self.recompute_due_dates_and_scores(user_id)
    Course.where(:id => StudentEnrollment.where(user_id: user_id).distinct.pluck(:course_id)).each do |course|
      DueDateCacher.recompute_users_for_course([user_id], course, nil, update_grades: true)
    end
  end

  def self.recompute_final_scores(user_id)
    StudentEnrollment.where(user_id: user_id).distinct.pluck(:course_id).each do |course_id|
      recompute_final_score_in_singleton(user_id, course_id)
    end
  end

  def computed_current_grade(id_opts=nil)
    cached_score_or_grade(:current, :grade, :posted, id_opts)
  end

  def computed_final_grade(id_opts=nil)
    cached_score_or_grade(:final, :grade, :posted, id_opts)
  end

  def computed_current_score(id_opts=nil)
    cached_score_or_grade(:current, :score, :posted, id_opts)
  end

  def computed_final_score(id_opts=nil)
    cached_score_or_grade(:final, :score, :posted, id_opts)
  end

  def effective_current_grade(id_opts=nil)
    score = find_score(id_opts)

    if score&.overridden? && course.feature_enabled?(:final_grades_override)
      score.effective_final_grade
    else
      computed_current_grade(id_opts)
    end
  end

  def effective_current_score(id_opts=nil)
    score = find_score(id_opts)

    if score&.overridden? && course.feature_enabled?(:final_grades_override)
      score.effective_final_score_lower_bound
    else
      computed_current_score(id_opts)
    end
  end

  def effective_final_grade(id_opts=nil)
    score = find_score(id_opts)

    if score&.overridden? && course.feature_enabled?(:final_grades_override)
      score.effective_final_grade
    else
      computed_final_grade(id_opts)
    end
  end

  def effective_final_score(id_opts=nil)
    score = find_score(id_opts)

    if score&.overridden? && course.feature_enabled?(:final_grades_override)
      score.effective_final_score_lower_bound
    else
      computed_final_score(id_opts)
    end
  end

  def override_grade(id_opts=nil)
    return nil unless course.feature_enabled?(:final_grades_override) && course.grading_standard_enabled?
    score = find_score(id_opts)
    score.effective_final_grade if score&.override_score
  end

  def override_score(id_opts=nil)
    return nil unless course.feature_enabled?(:final_grades_override)
    score = find_score(id_opts)
    score&.override_score
  end

  def unposted_current_grade(id_opts=nil)
    cached_score_or_grade(:current, :grade, :unposted, id_opts)
  end

  def unposted_final_grade(id_opts=nil)
    cached_score_or_grade(:final, :grade, :unposted, id_opts)
  end

  def unposted_current_score(id_opts=nil)
    cached_score_or_grade(:current, :score, :unposted, id_opts)
  end

  def unposted_final_score(id_opts=nil)
    cached_score_or_grade(:final, :score, :unposted, id_opts)
  end

  def cached_score_or_grade(current_or_final, score_or_grade, posted_or_unposted, id_opts=nil)
    score = find_score(id_opts)
    method = "#{current_or_final}_#{score_or_grade}"
    method.prepend("unposted_") if posted_or_unposted == :unposted
    score&.send(method)
  end
  private :cached_score_or_grade

  def find_score(id_opts=nil)
    id_opts ||= Score.params_for_course
    valid_keys = %i(course_score grading_period grading_period_id assignment_group assignment_group_id)
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
        Bullet::Detector::Association.add_object_associations(result, :course) if defined?(Bullet) && Bullet.start?
      end
    end
    result
  end

  def graded_at
    score = find_score
    if score.present?
      score.updated_at
    else
      # TODO: drop the graded_at column after the data fixup to populate
      # the scores table completes
      read_attribute(:graded_at)
    end
  end

  def self.typed_enrollment(type)
    return nil unless ['StudentEnrollment', 'StudentViewEnrollment', 'TeacherEnrollment', 'TaEnrollment', 'ObserverEnrollment', 'DesignerEnrollment'].include?(type)
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
    Atom::Entry.new do |entry|
      entry.title     = t('#enrollment.title', "%{user_name} in %{course_name}", :user_name => self.user_name, :course_name => self.course_name)
      entry.updated   = self.updated_at
      entry.published = self.created_at
      entry.links    << Atom::Link.new(:rel => 'alternate',
                                    :href => "/courses/#{self.course.id}/enrollments/#{self.id}")
    end
  end

  set_policy do
    given {|user, session| self.course.grants_any_right?(user, session, :manage_students, :manage_admin_users, :read_roster)}
    can :read

    given { |user| self.user == user }
    can :read and can :read_grades

    given { |user, session| self.course.students_visible_to(user, include: :priors).where(:id => self.user_id).exists? &&
      self.course.grants_any_right?(user, session, :manage_grades, :view_all_grades) }
    can :read and can :read_grades

    given { |user| course.observer_enrollments.where(user_id: user, associated_user_id: self.user_id).exists? }
    can :read and can :read_grades

    given {|user, session| self.course.grants_right?(user, session, :participate_as_student) && self.user.show_user_services }
    can :read_services

    # read_services says this person has permission to see what web services this enrollment has linked to their account
    given {|user, session| self.grants_right?(user, session, :read) && self.user.show_user_services }
    can :read_services
  end

  scope :before, lambda { |date|
    where("enrollments.created_at<?", date)
  }

  scope :for_user, lambda { |user| where(:user_id => user) }

  scope :for_courses_with_user_name, lambda { |courses|
    where(:course_id => courses).
        joins(:user).
        select("user_id, course_id, users.name AS user_name")
  }
  scope :invited, -> { where(:workflow_state => 'invited') }
  scope :accepted, -> { where("enrollments.workflow_state<>'invited'") }
  scope :active_or_pending, -> { where("enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted', 'inactive')") }
  scope :all_active_or_pending, -> { where("enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted')") } # includes inactive

  scope :active_by_date, -> { joins(:enrollment_state).where("enrollment_states.state = 'active'") }
  scope :invited_by_date, -> { joins(:enrollment_state).where("enrollment_states.restricted_access = ?", false).
    where("enrollment_states.state IN ('invited', 'pending_invited')") }
  scope :active_or_pending_by_date, -> { joins(:enrollment_state).where("enrollment_states.restricted_access = ?", false).
    where("enrollment_states.state IN ('active', 'invited', 'pending_invited', 'pending_active')") }
  scope :invited_or_pending_by_date, -> { joins(:enrollment_state).where("enrollment_states.restricted_access = ?", false).
    where("enrollment_states.state IN ('invited', 'pending_invited', 'pending_active')") }
  scope :completed_by_date, -> { joins(:enrollment_state).where("enrollment_states.restricted_access = ?", false).
    where("enrollment_states.state = ?", "completed") }
  scope :not_inactive_by_date, -> { joins(:enrollment_state).where("enrollment_states.restricted_access = ?", false).
    where("enrollment_states.state IN ('active', 'invited', 'completed', 'pending_invited', 'pending_active')") }

  scope :active_or_pending_by_date_ignoring_access, -> { joins(:enrollment_state).
    where("enrollment_states.state IN ('active', 'invited', 'pending_invited', 'pending_active')") }
  scope :not_inactive_by_date_ignoring_access, -> { joins(:enrollment_state).
    where("enrollment_states.state IN ('active', 'invited', 'completed', 'pending_invited', 'pending_active')") }

  scope :currently_online, -> { joins(:pseudonyms).where("pseudonyms.last_request_at>?", 5.minutes.ago) }
  # this returns enrollments for creation_pending users; should always be used in conjunction with the invited scope
  scope :for_email, lambda { |email|
    joins(:user => :communication_channels).
        where("users.workflow_state='creation_pending' AND communication_channels.workflow_state='unconfirmed' AND path_type='email' AND LOWER(path)=LOWER(?)", email).
        select("enrollments.*").
        readonly(false)
  }
  def self.cached_temporary_invitations(email)
    if Enrollment.cross_shard_invitations?
      Shard.birth.activate do
        invitations = Rails.cache.fetch([email, 'all_invited_enrollments2'].cache_key) do
          Shard.with_each_shard(CommunicationChannel.associated_shards(email)) do
            Enrollment.invited.for_email(email).to_a
          end
        end
      end
    else
      Rails.cache.fetch([email, 'invited_enrollments2'].cache_key) do
        Enrollment.invited.for_email(email).to_a
      end
    end
  end

  def self.order_by_sortable_name
    clause = User.sortable_name_order_by_clause('users')
    scope = self.order(clause)
    if scope.select_values.present?
      scope = scope.select(clause)
    else
      scope = scope.select(self.arel_table[Arel.star])
    end
    scope
  end

  def self.top_enrollment_by(key, rank_order = :default)
    raise "top_enrollment_by_user must be scoped" unless all.where_clause.present?

    key = key.to_s
    order(Arel.sql("#{key}, #{type_rank_sql(rank_order)}")).distinct_on(key)
  end

  def assign_uuid
    # DON'T use ||=, because that will cause an immediate save to the db if it
    # doesn't already exist
    self.uuid = CanvasSlug.generate_securish_uuid if !read_attribute(:uuid)
  end
  protected :assign_uuid

  def uuid
    if !read_attribute(:uuid)
      self.update_attribute(:uuid, CanvasSlug.generate_securish_uuid)
    end
    read_attribute(:uuid)
  end

  def self.limit_privileges_to_course_section!(course, user, limit)
    course.shard.activate do
      Enrollment.where(:course_id => course, :user_id => user).each do |enrollment|
        enrollment.limit_privileges_to_course_section = !!limit
        enrollment.save!
      end
    end
    user.touch
  end

  def self.course_user_state(course, uuid)
    Rails.cache.fetch(['user_state', course, uuid].cache_key) do
      enrollment = course.enrollments.where(uuid: uuid).first
      if enrollment
        {
          :enrollment_state => enrollment.workflow_state,
          :user_state => enrollment.user.state,
          :is_admin => enrollment.admin?
        }
      else
        nil
      end
    end
  end

  def self.serialization_excludes; [:uuid,:computed_final_score, :computed_current_score]; end

  # enrollment term per-section is deprecated; a section's term is inherited from the
  # course it is currently tied to
  def enrollment_term
    self.course.enrollment_term
  end

  def effective_start_at
    # try and use the enrollment dates logic first, since it knows about
    # overrides, etc. but if it doesn't find anything, start guessing by
    # looking at the enrollment, section, course, then term. if we still didn't
    # find it, fall back to the section or course creation date.
    enrollment_dates.map(&:first).compact.min ||
    start_at ||
    course_section && course_section.start_at ||
    course.start_at ||
    course.enrollment_term && course.enrollment_term.start_at ||
    course_section && course_section.created_at ||
    course.created_at
  end

  def effective_end_at
    # try and use the enrollment dates logic first, since it knows about
    # overrides, etc. but if it doesn't find anything, start guessing by
    # looking at the enrollment, section, course, then term.
    enrollment_dates.map(&:last).compact.max ||
    end_at ||
    course_section && course_section.end_at ||
    course.conclude_at ||
    course.enrollment_term && course.enrollment_term.end_at
  end

  def self.cross_shard_invitations?
    false
  end

  def total_activity_time
    self.read_attribute(:total_activity_time).to_i
  end

  def touch_graders_if_needed
    if !active_student? && active_student?(:was) && self.course.submissions.where(:user_id => self.user_id).exists?
      self.class.connection.after_transaction_commit do
        User.where(id: self.course.admins).touch_all
      end
    end
  end

  def update_assignment_overrides_if_needed
    assignment_scope = Assignment.where(context_id: self.course_id, context_type: 'Course')
    override_scope = AssignmentOverrideStudent.where(user_id: self.user_id)

    if being_deleted? && !enrollments_exist_for_user_in_course?
      return unless (assignment_ids = assignment_scope.pluck(:id)).any?

      # this is handled in after_commit :update_cached_due_dates
      AssignmentOverrideStudent.suspend_callbacks(:update_cached_due_dates) do
        override_scope.where(assignment_id: assignment_ids).find_each(&:destroy)
      end
    end
  end

  def section_or_course_date_in_past?
    if self.course_section && self.course_section.end_at
      self.course_section.end_at < Time.now
    elsif self.course.conclude_at
      self.course.conclude_at < Time.now
    end
  end

  def student_or_fake_student?
    ['StudentEnrollment', 'StudentViewEnrollment'].include?(type)
  end

  private

  def enrollments_exist_for_user_in_course?
    Enrollment.active.where(user_id: self.user_id, course_id: self.course_id).exists?
  end

  def copy_scores_from_existing_enrollment
    Score.where(enrollment_id: self).each(&:destroy_permanently!)
    other_enrollment_of_same_type.scores.each { |score| score.dup.update!(enrollment: self) }
  end

  def need_to_copy_scores?
    return false unless saved_change_to_id? || being_restored?
    student_or_fake_student? && other_enrollment_of_same_type.present?
  end

  def restore_submissions_and_scores
    return unless being_restored?(to_state: "completed")

    # running in an n_strand to handle situations where a SIS import could
    # update a ton of enrollments from "deleted" to "completed".
    send_later_if_production_enqueue_args(
      :restore_submissions_and_scores_now,
      {
        n_strand: "Enrollment#restore_submissions_and_scores#{root_account.global_id}",
        max_attempts: 1,
        priority: Delayed::LOW_PRIORITY
      }
    )
  end

  def restore_submissions_and_scores_now
    restore_deleted_submissions
    restore_deleted_scores
  end

  def restore_deleted_submissions
    Submission.
      joins(:assignment).
      where(user_id: user_id, workflow_state: "deleted", assignments: { context_id: course_id }).
      merge(Assignment.active).
      in_batches.
      update_all("workflow_state = #{DueDateCacher::INFER_SUBMISSION_WORKFLOW_STATE_SQL}")
  end

  def restore_deleted_scores
    assignment_groups = course.assignment_groups.active.except(:order)
    grading_periods = GradingPeriod.for(course)

    Score.where(course_score: true).or(
      Score.where(assignment_group: assignment_groups)
    ).or(
      Score.where(grading_period: grading_periods)
    ).where(enrollment_id: id, workflow_state: "deleted").
      update_all(workflow_state: "active")
  end

  def other_enrollment_of_same_type
    return @other_enrollment_of_same_type if defined?(@other_enrollment_of_same_type)

    @other_enrollment_of_same_type = other_enrollments_of_type(type).first
  end

  def other_enrollments_of_type(types)
    Enrollment.where(
      course_id: course,
      user_id: user,
      type: Array.wrap(types)
    ).where.not(id: id, workflow_state: :deleted)
  end

  def remove_user_as_final_grader?
    instructor? &&
      !other_enrollments_of_type(['TaEnrollment', 'TeacherEnrollment']).exists?
  end

  def being_restored?(to_state: workflow_state)
    saved_change_to_workflow_state? && workflow_state_before_last_save == 'deleted' && workflow_state == to_state
  end

  def being_reactivated?
    saved_change_to_workflow_state? && workflow_state != 'deleted' && workflow_state_before_last_save == 'inactive'
  end

  def being_uncompleted?
    saved_change_to_workflow_state? && workflow_state != 'deleted' && workflow_state_before_last_save == 'completed'
  end

  def being_deleted?
    workflow_state == 'deleted' && workflow_state_before_last_save != 'deleted'
  end
end
