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

class Enrollment < ActiveRecord::Base
  
  include Workflow

  belongs_to :course, :touch => true
  belongs_to :course_section
  belongs_to :root_account, :class_name => 'Account'
  belongs_to :user
  belongs_to :associated_user, :class_name => 'User'
  has_many :role_overrides, :as => :context
  has_many :pseudonyms, :primary_key => :user_id, :foreign_key => :user_id
  has_many :course_account_associations, :foreign_key => 'course_id', :primary_key => 'course_id'
  
  validates_presence_of :user_id
  validates_presence_of :course_id
  
  before_save :assign_uuid
  before_save :assert_section
  after_save :touch_user
  before_save :update_user_account_associations_if_necessary

  attr_accessible :user, :course, :workflow_state, :course_section, :limit_priveleges_to_course_section, :invitation_email

  trigger.after(:insert).where("NEW.workflow_state = 'active'") do
    <<-SQL
    UPDATE assignments
    SET needs_grading_count = needs_grading_count + 1
    WHERE id IN (SELECT assignment_id
                 FROM submissions
                 WHERE user_id = NEW.user_id
                   AND context_code = 'course_' || NEW.course_id
                   AND (#{Submission.needs_grading_conditions})
                );
    SQL
  end

  trigger.after(:update).where("NEW.workflow_state <> OLD.workflow_state AND (NEW.workflow_state = 'active' OR OLD.workflow_state = 'active')") do
    <<-SQL
    UPDATE assignments
    SET needs_grading_count = needs_grading_count + CASE WHEN NEW.workflow_state = 'active' THEN 1 ELSE -1 END
    WHERE id IN (SELECT assignment_id
                 FROM submissions
                 WHERE user_id = NEW.user_id
                   AND context_code = 'course_' || NEW.course_id
                   AND (#{Submission.needs_grading_conditions})
                );
    SQL
  end



  has_a_broadcast_policy
  
  set_broadcast_policy do |p|
    p.dispatch :enrollment_invitation
    p.to { self.user }
    p.whenever { |record|
      record.course and
      record.user.registered? and
      ((record.just_created && record.invited?) || record.changed_state(:invited) || @re_send_confirmation)
    }
    
    p.dispatch :enrollment_registration
    p.to { self.user.communication_channel }
    p.whenever { |record|
      record.course and 
      !record.user.registered? and
      ((record.just_created && record.invited?) || record.changed_state(:invited) || @re_send_confirmation)
    }
    
    p.dispatch :enrollment_notification
    p.to { self.user }
    p.whenever { |record|
      record.course && 
      !record.course.created? && 
      record.just_created && record.active?
    }
    
    p.dispatch :enrollment_accepted
    p.to {self.course.admins - [self.user] }
    p.whenever { |record|
      record.course &&
      !record.just_created && (record.changed_state(:active, :invited) || record.changed_state(:active, :creation_pending))
    }
  end

  named_scope :active,
              :conditions => ['enrollments.workflow_state != ?', 'deleted']
  named_scope :admin, 
              :select => 'course_id', 
              :joins => :course,
              :conditions => "enrollments.type IN ('TeacherEnrollment','TaEnrollment', 'DesignerEnrollment') 
                              AND (courses.workflow_state = 'claimed' OR (enrollments.workflow_state = 'active' and  courses.workflow_state = 'available'))"

  named_scope :student,
              :select => 'course_id',
              :joins => :course,
              :conditions => "enrollments.type = 'StudentEnrollment'
                              AND enrollments.workflow_state = 'active' 
                              AND courses.workflow_state = 'available'"
  
  named_scope :all_student,
              :include => :course,
              :conditions => "enrollments.type = 'StudentEnrollment'
                              AND enrollments.workflow_state IN ('invited', 'active', 'completed') 
                              AND courses.workflow_state IN ('available', 'completed')"
                              
  named_scope :ended,
              :joins => :course, 
              :conditions => "courses.workflow_state = 'aborted' or courses.workflow_state = 'completed' or enrollments.workflow_state = 'rejected' or enrollments.workflow_state = 'completed'"
              

  ENROLLMENT_RANK = ['TeacherEnrollment','TaEnrollment','DesignerEnrollment','StudentEnrollment','ObserverEnrollment']
  ENROLLMENT_RANK_SQL = ENROLLMENT_RANK.size.times.inject('CASE '){|s, i| s << "WHEN type = '#{ENROLLMENT_RANK[i]}' THEN #{i} "} << 'END'
  def self.highest_enrollment_type(type, type2)
    res = ENROLLMENT_RANK.find{|t| t == type || t == type2}
    res ||= type || type2
    res
  end
  
  def should_update_user_account_association?
    self.new_record? || self.course_id_changed? || self.course_section_id_changed? || self.root_account_id_changed?
  end
  
  def update_user_account_associations_if_necessary
    self.user.update_account_associations_later if should_update_user_account_association?
  end
  protected :update_user_account_associations_if_necessary

  def conclude
    self.workflow_state = "completed"
    self.completed_at = Time.now
    self.save
  end
  
  def page_views_by_day(options={})
    conditions = {
      :context_id => course.id,
      :context_type => course.class.to_s,
      :user_id => user.id
    }
    if options[:dates]
      conditions.merge!({
        :created_at, (options[:dates].first)..(options[:dates].last)
      })
    end
    page_views_as_hash = {}
    PageView.count(
      :group => "date(created_at)", 
      :conditions => conditions
    ).each do |day|
      page_views_as_hash[day.first] = day.last
    end
    page_views_as_hash
  end
  memoize :page_views_by_day
  
  
  def defined_by_sis?
    !!self.sis_source_id
  end
  
  def participating?
    !self.is_a?(CourseDesignerEnrollment) && self.state_based_on_date == :active
  end
  
  def student?
    self.is_a?(StudentEnrollment)
  end
  
  def assigned_observer?
    self.is_a?(ObserverEnrollment) && self.associated_user_id
  end
  
  def participating_student?
    self.is_a?(StudentEnrollment) && self.state_based_on_date == :active
  end
  
  def participating_observer?
    self.is_a?(ObserverEnrollment) && self.state_based_on_date == :active
  end
  
  def participating_admin?
    (self.is_a?(TeacherEnrollment) || self.is_a?(TaEnrollment)) && self.state_based_on_date == :active
  end
  
  def associated_user_name
    self.associated_user && self.associated_user.short_name
  end
  
  def assert_section
    self.course_section ||= self.course.default_section if self.course
    self.root_account_id = self.course_section.root_account_id rescue nil
  end
  
  def course_name
    self.course.name || t('#enrollment.default_course_name', "Course")
  end

  def short_name(length=nil)
    return @short_name if @short_name
    @short_name = self.course_section.display_name if self.course_section && self.root_account && self.root_account.show_section_name_as_course_name
    @short_name ||= self.course_name
    @short_name = @short_name[0..length] if length
    @short_name
  end
  
  def long_name
    return @long_name if @long_name
    @long_name = self.course_name
    @long_name = t('#enrollment.with_section', "%{course_name}, %{section_name}", :course_name => @long_name, :section_name => self.course_section.display_name) if self.course_section && self.course_section.display_name && self.course_section.display_name != self.course.name
    @long_name
  end
  
  def rank_sortable(student_first=false)
    type = self.class.to_s
    case type
    when 'StudentEnrollment'
      student_first ? 0 : 4
    when 'TeacherEnrollment'
      1
    when 'TaEnrollment'
      2
    when 'ObserverEnrollment'
      5
    when 'DesignerEnrollment'
      3
    else
      6
    end
  end
  
  def state_sortable
    case state
    when :invited
      1
    when :creation_pending
      1
    when :active
      0
    when :deleted
      5
    when :rejected
      4
    when :completed
      2
    else
      6
    end
  end
  
  def accept!
    res = accept
    raise "can't accept" unless res
    res
  end
  
  def accept
    return false unless invited?
    ids = nil
    ids = self.user.dashboard_messages.find_all_by_context_id_and_context_type(self.id, 'Enrollment', :select => "id").map(&:id) if self.user
    Message.delete_all({:id => ids}) if ids && !ids.empty?
    update_attribute(:workflow_state, 'active')
    true
  end
  
  workflow do
    state :invited do
      event :reject, :transitions_to => :rejected
      event :complete, :transitions_to => :completed
      event :pend, :transitions_to => :pending
    end
    
    state :creation_pending do
      event :invite, :transitions_to => :invited
    end
    
    state :active do
      event :reject, :transitions_to => :rejected
      event :complete, :transitions_to => :completed
      event :pend, :transitions_to => :pending
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
    Rails.cache.fetch([self, 'enrollment_dates'].cache_key) do
      if self.start_at && self.end_at
        [self.start_at, self.end_at]
      elsif course_section.try(:restrict_enrollments_to_section_dates) && !self.admin?
        [course_section.start_at, course_section.end_at]
      elsif course.try(:restrict_enrollments_to_course_dates) && !self.admin?
        [course.start_at, course.conclude_at]
      elsif course.try(:enrollment_term)
        course.enrollment_term.enrollment_dates_for(self)
      else
        [nil, nil]
      end
    end
  end

  def state_based_on_date
    if state == :active
      start_at, end_at = self.enrollment_dates
      if start_at && start_at >= Time.now
        :inactive
      elsif end_at && end_at <= Time.now
        :completed
      else
        :active
      end
    else
      state
    end
  end

  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.save
  end
  
  def restore
    self.workflow_state = 'active'
    self.save
  end
  
  def re_send_confirmation!
    @re_send_confirmation = true
    self.save
    @re_send_confirmation = false
    true
  end
  
  def has_permission_to?(action)
    @permission_lookup ||= {}
    unless @permission_lookup.has_key? action
      @permission_lookup[action] = RoleOverride.permission_for(self, action, self.class.to_s)[:enabled]
    end 
    @permission_lookup[action]
  end
  
  def pending?
    self.invited? || self.creation_pending?
  end
  
  def active_or_pending?
    self.active? || self.inactive? || self.pending?
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
  
  def self.readable_type(type)
    case type
    when 'TeacherEnrollment'
      t('#enrollment.roles.teacher', "Teacher")
    when 'StudentEnrollment'
      t('#enrollment.roles.student', "Student")
    when 'TaEnrollment'
      t('#enrollment.roles.ta', "TA")
    when 'ObserverEnrollment'
      t('#enrollment.roles.observer', "Observer")
    when 'DesignerEnrollment'
      t('#enrollment.roles.designer', "Designer")
    else
      t('#enrollment.roles.student', "Student")
    end
  end
  
  def workflow_readable_type
    case self.workflow_state
      when 'active'
        t('#enrollment.workflow.active', "Active")
      when 'completed'
        t('#enrollment.workflow.completed', "Completed")
      when 'deleted'
        t('#enrollment.workflow.deleted', "Deleted")
      when 'invited'
        t('#enrollment.workflow.invited', "Invited")
      when 'pending'
        t('#enrollment.workflow.pending', "Pending")
      when 'rejected'
        t('#enrollment.workflow.rejected', "Rejected")
    end
  end
  
  def readable_type
    Enrollment.readable_type(self.class.to_s)
  end
  
  def self.recompute_final_scores(user_id)
    user = User.find(user_id)
    user.student_enrollments.each do |enrollment|
      send_later(:recompute_final_score, user_id, enrollment.course_id)
    end
  end
  
  def self.recompute_final_score(user_ids, course_id)
    GradeCalculator.recompute_final_score(user_ids, course_id)
  end
  
  def computed_final_grade
    self.course.score_to_grade(self.computed_final_score)
  end

  def self.students(opts={})
    with_scope :find => opts do
      find(:all, :conditions => {:type => 'Student'}).map(&:user).compact
    end
  end
  
  def self.typed_enrollment(type)
    return nil unless ['StudentEnrollment', 'TeacherEnrollment', 'TaEnrollment', 'ObserverEnrollment', 'DesignerEnrollment'].include?(type)
    type.constantize
  end
  
  def admin?
    false
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
    given { |user| self.user == user }
    can :read and can :read_grades
    
    given {|user, session| self.course.grants_right?(user, session, :participate_as_student) && self.user.show_user_services }
    can :read_services

    # read_services says this person has permission to see what web services this enrollment has linked to their account
    given {|user, session| self.course.grants_right?(user, session, :manage_students) && self.user.show_user_services }
    can :read and can :read_services
    
    given { |user, session| self.course.students_visible_to(user, true).map(&:id).include?(self.user_id) && self.course.grants_right?(user, session, :manage_grades) }
    can :read and can :read_grades
    
    given { |user, session| self.course.students_visible_to(user, true).map(&:id).include?(self.user_id) && self.course.grants_right?(user, session, :read_as_admin) }
    can :read and can :read_grades
    
    given { |user| !!Enrollment.active.find_by_user_id_and_associated_user_id(user.id, self.user_id) }
    can :read and can :read_grades and can :read_services
  end
  
  named_scope :before, lambda{|date|
    {:conditions => ['enrollments.created_at < ?', date]}
  }
  
  named_scope :for_user, lambda{|user|
    {:conditions => ['enrollments.user_id = ?', user.id] }
  }
  
  named_scope :for_courses_with_user_name, lambda{|courses|
    {
      :conditions => {:course_id => courses.map(&:id)},
      :joins => :user,
      :select => 'user_id, course_id, users.name AS user_name'
    }
  }
  named_scope :accepted, lambda{
    {:conditions => ['enrollments.workflow_state != ?', 'invited'] }
  }
  named_scope :active_or_pending, lambda{
    {:conditions => {:workflow_state => ['invited', 'creation_pending', 'active']}}
  }
  named_scope :currently_online, lambda{
    {:joins => :pseudonyms, :conditions => ['pseudonyms.last_request_at > ?', 5.minutes.ago] }
  }
  
  def assign_uuid
    # DON'T use ||=, because that will cause an immediate save to the db if it
    # doesn't already exist
    self.uuid = AutoHandle.generate_securish_uuid if !read_attribute(:uuid)
  end
  protected :assign_uuid
  
  def uuid
    if !read_attribute(:uuid)
      self.update_attribute(:uuid, AutoHandle.generate_securish_uuid)
    end
    read_attribute(:uuid)
  end
  
  def self.limit_priveleges_to_course_section!(course, user, limit)
    Enrollment.update_all({:limit_priveleges_to_course_section => !!limit}, {:course_id => course.id, :user_id => user.id})
    user.touch
  end
  
  def self.course_user_state(course, uuid)
    Rails.cache.fetch(['user_state', course, uuid].cache_key) do
      enrollment = course.enrollments.find_by_uuid(uuid)
      if enrollment
        {
          :enrollment_state => enrollment.workflow_state,
          :user_state => enrollment.user.state
        }
      else
        nil
      end
    end
  end
  
  # this is just used to get a pseudonym_id in the user_lists.js stuff. 
  def users_pseudonym_id
    self.user.pseudonym.id
  end
  # this is also just used to get a communication_channel_id in the user_lists.js stuff
  def communication_channel_id
    self.user.communication_channel.id rescue nil
  end
  
  def self.serialization_excludes; [:uuid,:computed_final_score, :computed_current_score]; end

  # enrollment term per-section is deprecated; a section's term is inherited from the
  # course it is currently tied to
  def enrollment_term
    self.course.enrollment_term
  end
end
