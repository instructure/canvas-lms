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

class CourseSection < ActiveRecord::Base
  include Workflow

  attr_protected :sis_source_id, :sis_batch_id, :course_id,
      :root_account_id, :enrollment_term_id
  belongs_to :course
  belongs_to :nonxlist_course, :class_name => 'Course'
  belongs_to :root_account, :class_name => 'Account'
  belongs_to :account
  has_many :enrollments, :include => :user, :conditions => ['enrollments.workflow_state != ?', 'deleted'], :dependent => :destroy
  has_many :all_enrollments, :class_name => 'Enrollment'
  has_many :students, :through => :student_enrollments, :source => :user
  has_many :student_enrollments, :class_name => 'StudentEnrollment', :conditions => ['enrollments.workflow_state != ? AND enrollments.workflow_state != ? AND enrollments.workflow_state != ? AND enrollments.workflow_state != ?', 'deleted', 'completed', 'rejected', 'inactive'], :include => :user
  has_many :instructor_enrollments, :class_name => 'Enrollment', :conditions => "(enrollments.type = 'TaEnrollment' or enrollments.type = 'TeacherEnrollment')"
  has_many :admin_enrollments, :class_name => 'Enrollment', :conditions => "(enrollments.type = 'TaEnrollment' or enrollments.type = 'TeacherEnrollment' or enrollments.type = 'DesignerEnrollment')"
  has_many :users, :through => :enrollments
  has_many :course_account_associations
  has_many :calendar_events, :as => :context

  before_validation :infer_defaults, :verify_unique_sis_source_id
  validates_presence_of :course_id

  before_save :set_update_account_associations_if_changed
  before_save :maybe_touch_all_enrollments
  after_save :update_account_associations_if_changed

  include StickySisFields
  are_sis_sticky :course_id, :name, :start_at, :end_at, :restrict_enrollments_to_section_dates

  def maybe_touch_all_enrollments
    self.touch_all_enrollments if self.start_at_changed? || self.end_at_changed? || self.restrict_enrollments_to_section_dates_changed? || self.course_id_changed?
  end

  def participating_students
    course.participating_students.scoped(:conditions => ["enrollments.course_section_id = ?", id])
  end

  def participants
    participating_students + 
    course.participating_admins.scoped(:conditions => ["enrollments.course_section_id = ? OR NOT COALESCE(enrollments.limit_privileges_to_course_section, ?)", id, false])
  end

  def available?
    course.available?
  end

  def touch_all_enrollments
    return if new_record?
    self.enrollments.update_all(:updated_at => Time.now.utc)
    case User.connection.adapter_name
    when 'MySQL'
      User.connection.execute("UPDATE users, enrollments SET users.updated_at=NOW() WHERE users.id=enrollments.user_id AND enrollments.course_section_id=#{self.id}")
    else
      User.update_all({:updated_at => Time.now.utc}, "id IN (SELECT user_id FROM enrollments WHERE course_section_id=#{self.id})")
    end
  end

  set_policy do
    given {|user, session| self.cached_context_grants_right?(user, session, :manage_sections) }
    can :read and can :create and can :update and can :delete

    given {|user, session| self.cached_context_grants_right?(user, session, :manage_students, :manage_admin_users) }
    can :read

    given {|user, session| self.course.account_membership_allows(user, session, :read_roster) }
    can :read

    given {|user, session| self.cached_context_grants_right?(user, session, :manage_calendar) }
    can :manage_calendar

    given {|user, session| self.enrollments.find_by_user_id(user.id) && self.cached_context_grants_right?(user, session, :read_roster) }
    can :read

    given {|user, session| self.cached_context_grants_right?(user, session, :read_as_admin) }
    can :read_as_admin
  end

  def set_update_account_associations_if_changed
    @should_update_account_associations = self.account_id_changed? || self.course_id_changed? || self.nonxlist_course_id_changed?
    @should_update_account_associations = false if self.new_record? && self.account_id.nil?
    true
  end

  def update_account_associations_if_changed
    send_later_if_production(:update_account_associations) if @should_update_account_associations && !Course.skip_updating_account_associations?
  end

  def update_account_associations
    Course.update_account_associations([self.course, self.nonxlist_course].compact)
    self.course.try(:update_account_associations)
    self.nonxlist_course.try(:update_account_associations)
  end

  def verify_unique_sis_source_id
    return true unless self.sis_source_id
    existing_section = CourseSection.find_by_root_account_id_and_sis_source_id(self.root_account_id, self.sis_source_id)
    return true if !existing_section || existing_section.id == self.id

    self.errors.add(:sis_source_id, t('sis_id_taken', "SIS ID \"%{sis_id}\" is already in use", :sis_id => self.sis_source_id))
    false
  end

  alias_method :parent_event_context, :course

  def section_code
    self.name ||= read_attribute(:section_code)
  end

  def infer_defaults
    self.root_account_id ||= (self.course.root_account_id rescue nil) || Account.default.id
    self.assert_course unless self.course
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
    self.name ||= "#{self.course.name} #{Time.zone.today.to_s}"
    self.section_code ||= self.name
    if name_had_changed
      self.section_code = self.name
    end
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
    @section_display_name ||= self.name || self.section_code
  end

  def assert_course
    self.course ||= Course.create!(:name => self.name || self.section_code, :root_account => self.root_account)
  end

  def move_to_course(course, *opts)
    return self if self.course_id == course.id
    old_course = self.course
    self.course = course
    self.root_account_id = course.root_account_id
    self.default_section = (course.course_sections.active.size == 0)
    old_course.course_sections.reset
    course.course_sections.reset
    user_ids = self.enrollments.map(&:user_id).uniq

    old_course_is_unrelated = old_course.id != self.course_id && old_course.id != self.nonxlist_course_id
    if self.root_account_id_changed?
      self.save!
      self.enrollments.update_all :course_id => course.id, :root_account_id => self.root_account_id
    else
      self.save!
      self.enrollments.update_all :course_id => course.id
    end
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
    self.enrollments.count == 0
  end

  def enroll_user(user, type, state='invited')
    self.course.enroll_user(user, type, :enrollment_state => state, :section => self)
  end

  workflow do
    state :active
    state :deleted
  end

  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    save!
  end

  named_scope :active, lambda {
    { :conditions => ['course_sections.workflow_state != ?', 'deleted'] }
  }

  named_scope :sis_sections, lambda{|account, *source_ids|
    {:conditions => {:root_account_id => account.id, :sis_source_id => source_ids}, :order => :sis_source_id}
  }

  def common_to_users?(users)
    users.all?{ |user| self.student_enrollments.active.for_user(user).count > 0 }
  end
end
