#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

  attr_protected :sis_source_id, :sis_batch_id, :course_id,
      :root_account_id, :enrollment_term_id, :integration_id

  belongs_to :course
  belongs_to :nonxlist_course, :class_name => 'Course'
  belongs_to :root_account, :class_name => 'Account'
  belongs_to :enrollment_term
  has_many :enrollments, -> { preload(:user).where("enrollments.workflow_state<>'deleted'") }, dependent: :destroy
  has_many :all_enrollments, :class_name => 'Enrollment'
  has_many :students, :through => :student_enrollments, :source => :user
  has_many :student_enrollments, -> { where("enrollments.workflow_state NOT IN ('deleted', 'completed', 'rejected', 'inactive')").preload(:user) }, class_name: 'StudentEnrollment'
  has_many :all_student_enrollments, -> { where("enrollments.workflow_state<>'deleted'").preload(:user) }, class_name: 'StudentEnrollment'
  has_many :instructor_enrollments, -> { where(type: ['TaEnrollment', 'TeacherEnrollment']) }, class_name: 'Enrollment'
  has_many :admin_enrollments, -> { where(type: ['TaEnrollment', 'TeacherEnrollment', 'DesignerEnrollment']) }, class_name: 'Enrollment'
  has_many :users, :through => :enrollments
  has_many :course_account_associations
  has_many :calendar_events, :as => :context
  has_many :assignment_overrides, :as => :set, :dependent => :destroy

  before_validation :infer_defaults, :verify_unique_sis_source_id
  validates_presence_of :course_id, :root_account_id, :workflow_state
  validates_length_of :sis_source_id, :maximum => maximum_string_length, :allow_nil => true, :allow_blank => false
  validates_length_of :name, :maximum => maximum_string_length, :allow_nil => false, :allow_blank => false

  has_many :sis_post_grades_statuses

  before_save :maybe_touch_all_enrollments
  after_save :update_account_associations_if_changed
  after_save :delete_enrollments_later_if_deleted
  after_save :update_enrollment_states_if_necessary

  include StickySisFields
  are_sis_sticky :course_id, :name, :start_at, :end_at, :restrict_enrollments_to_section_dates

  def maybe_touch_all_enrollments
    self.touch_all_enrollments if self.start_at_changed? || self.end_at_changed? || self.restrict_enrollments_to_section_dates_changed? || self.course_id_changed?
  end

  def delete_enrollments_later_if_deleted
    send_later_if_production(:delete_enrollments_if_deleted) if workflow_state == 'deleted' && workflow_state_changed?
  end

  def delete_enrollments_if_deleted
    if workflow_state == 'deleted'
      self.enrollments.active.find_each(&:destroy)
    end
  end

  def participating_observers
    User.observing_students_in_course(participating_students.map(&:id), course.id)
  end

  def participating_observers_by_date
    User.observing_students_in_course(participating_students_by_date.map(&:id), course.id)
  end

  def participating_students
    course.participating_students.where(:enrollments => { :course_section_id => self })
  end

  def participating_students_by_date
    course.participating_students_by_date.where(:enrollments => { :course_section_id => self })
  end

  def participating_admins
    course.participating_admins.where("enrollments.course_section_id = ? OR NOT COALESCE(enrollments.limit_privileges_to_course_section, ?)", self, false)
  end

  def participating_admins_by_date
    course.participating_admins.where("enrollments.course_section_id = ? OR NOT COALESCE(enrollments.limit_privileges_to_course_section, ?)", self, false)
  end

  def participants(opts={})
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

  def available?
    course.available?
  end

  def concluded?
    now = Time.now
    if self.end_at && self.restrict_enrollments_to_section_dates
      self.end_at < now
    else
      self.course.concluded?
    end
  end

  def touch_all_enrollments
    return if new_record?
    self.enrollments.touch_all
    User.where(id: all_enrollments.select(:user_id)).
        update_all(updated_at: Time.now.utc)
  end

  set_policy do
    given { |user, session| self.course.grants_right?(user, session, :manage_sections) }
    can :read and can :create and can :update and can :delete

    given { |user, session| self.course.grants_any_right?(user, session, :manage_students, :manage_admin_users) }
    can :read

    given { |user| self.course.account_membership_allows(user, :read_roster) }
    can :read

    given { |user, session| self.course.grants_right?(user, session, :manage_calendar) }
    can :manage_calendar

    given { |user, session|
      user &&
      self.course.sections_visible_to(user).where(:id => self).exists? &&
      self.course.grants_right?(user, session, :read_roster)
    }
    can :read

    given { |user, session| self.course.grants_right?(user, session, :manage_grades) }
    can :manage_grades


    given { |user, session| self.course.grants_right?(user, session, :read_as_admin) }
    can :read_as_admin
  end

  def update_account_associations_if_changed
    if (self.course_id_changed? || self.nonxlist_course_id_changed?) && !Course.skip_updating_account_associations?
      Course.send_later_if_production(:update_account_associations,
                                      [self.course_id, self.course_id_was, self.nonxlist_course_id, self.nonxlist_course_id_was].compact.uniq)
    end
  end

  def update_account_associations
    Course.update_account_associations([self.course_id, self.nonxlist_course_id].compact)
  end

  def verify_unique_sis_source_id
    return true unless self.sis_source_id
    return true if !root_account_id_changed? && !sis_source_id_changed?

    scope = root_account.course_sections.where(sis_source_id: self.sis_source_id)
    scope = scope.where("id<>?", self) unless self.new_record?

    return true unless scope.exists?

    self.errors.add(:sis_source_id, t('sis_id_taken', "SIS ID \"%{sis_id}\" is already in use", :sis_id => self.sis_source_id))
    false
  end

  alias_method :parent_event_context, :course

  def section_code
    self.name
  end

  def infer_defaults
    self.root_account_id ||= (self.course.root_account_id rescue nil) || Account.default.id
    raise "Course required" unless self.course
    self.root_account_id = self.course.root_account_id || Account.default.id
    # This is messy, and I hate it.
    # The SIS import actually gives us three names for a section
    #   and I don't know which one is best, or which one to show.
    name_had_changed = name_changed?
    # Here's the current plan:
    # - otherwise, just use name
    # - use the method display_name to consolidate this logic
    self.name ||= self.course.name if self.default_section
    self.name ||= "#{self.course.name} #{Time.zone.today}"
  end

  def defined_by_sis?
    !!self.sis_source_id
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

  def move_to_course(course, *opts)
    return self if self.course_id == course.id
    old_course = self.course
    self.course = course
    self.root_account_id = course.root_account_id
    self.default_section = (course.course_sections.active.size == 0)
    old_course.course_sections.reset
    course.course_sections.reset
    assignment_overrides.active.destroy_all
    user_ids = self.all_enrollments.map(&:user_id).uniq

    old_course_is_unrelated = old_course.id != self.course_id && old_course.id != self.nonxlist_course_id
    if self.root_account_id_changed?
      self.save!
      self.all_enrollments.update_all :course_id => course, :root_account_id => self.root_account_id
    else
      self.save!
      self.all_enrollments.update_all :course_id => course
    end
    EnrollmentState.send_later_if_production(:invalidate_states_for_course_or_section, self)
    User.send_later_if_production(:update_account_associations, user_ids) if old_course.account_id != course.account_id && !User.skip_updating_account_associations?
    if old_course.id != self.course_id && old_course.id != self.nonxlist_course_id
      old_course.send_later_if_production(:update_account_associations) unless Course.skip_updating_account_associations?
    end
    Enrollment.send_now_or_later(opts.include?(:run_jobs_immediately) ? :now : :later, :recompute_final_score, user_ids, course.id)
  end

  def crosslist_to_course(course, *opts)
    return self if self.course_id == course.id
    self.nonxlist_course_id ||= self.course_id
    self.move_to_course(course, *opts)
  end

  def uncrosslist(*opts)
    return unless self.nonxlist_course_id
    if self.nonxlist_course.workflow_state == "deleted"
      self.nonxlist_course.workflow_state = "claimed"
      self.nonxlist_course.save!
    end
    nonxlist_course = self.nonxlist_course
    self.nonxlist_course = nil
    self.move_to_course(nonxlist_course, *opts)
  end

  def crosslisted?
    return !!self.nonxlist_course_id
  end

  def destroy_course_if_no_more_sections
    if self.deleted? && self.course.course_sections.active.empty?
      self.course.destroy
    end
  end

  def deletable?
    !self.enrollments.where.not(:workflow_state => 'rejected').not_fake.exists?
  end

  def enroll_user(user, type, state='invited')
    self.course.enroll_user(user, type, :enrollment_state => state, :section => self)
  end

  workflow do
    state :active
    state :deleted
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.enrollments.not_fake.each(&:destroy)
    self.assignment_overrides.each(&:destroy)
    save!
  end

  scope :active, -> { where("course_sections.workflow_state<>'deleted'") }

  scope :sis_sections, lambda { |account, *source_ids| where(:root_account_id => account, :sis_source_id => source_ids).order(:sis_source_id) }

  def common_to_users?(users)
    users.all?{ |user| self.student_enrollments.active.for_user(user).count > 0 }
  end

  def update_enrollment_states_if_necessary
    if self.restrict_enrollments_to_section_dates_changed? || (self.restrict_enrollments_to_section_dates? && (changes.keys & %w{start_at end_at}).any?)
      EnrollmentState.send_later_if_production(:invalidate_states_for_course_or_section, self)
    end
  end
end
