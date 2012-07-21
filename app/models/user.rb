#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

class User < ActiveRecord::Base
  # this has to be before include Context to prevent a circular dependency in Course
  def self.sortable_name_order_by_clause(table = nil)
    col = table ? "#{table}.sortable_name" : 'sortable_name'
    best_unicode_collation_key(col)
  end

  include Context
  include UserFollow::FollowedItem

  attr_accessible :name, :short_name, :sortable_name, :time_zone, :show_user_services, :gender, :visible_inbox_types, :avatar_image, :subscribe_to_emails, :locale, :bio, :birthdate, :terms_of_use, :self_enrollment_code
  attr_accessor :original_id, :menu_data

  before_save :infer_defaults
  serialize :preferences
  include Workflow

  # Internal: SQL fragments used to return enrollments in their respective workflow
  # states. Where needed, these consider the state of the course to ensure that
  # students do not see their enrollments on unpublished courses.
  ENROLLMENT_CONDITIONS = {
    :active => "( enrollments.workflow_state = 'active' and ((courses.workflow_state = 'claimed' and (enrollments.type IN ('TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment', 'StudentViewEnrollment'))) or (enrollments.workflow_state = 'active' and courses.workflow_state = 'available')) )",
    :invited => "( enrollments.workflow_state = 'invited' and ((courses.workflow_state = 'available' and (enrollments.type = 'StudentEnrollment' or enrollments.type = 'ObserverEnrollment')) or (courses.workflow_state != 'deleted' and (enrollments.type IN ('TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment', 'StudentViewEnrollment')))))",
    :deleted => "enrollments.workflow_state = 'deleted'",
    :rejected => "enrollments.workflow_state = 'rejected'",
    :completed => "enrollments.workflow_state = 'completed'",
    :creation_pending => "enrollments.workflow_state = 'creation_pending'",
    :inactive => "enrollments.workflow_state = 'inactive'" }

  has_many :communication_channels, :order => 'position', :dependent => :destroy
  has_one :communication_channel, :order => 'position'
  has_many :enrollments, :dependent => :destroy

  has_many :current_enrollments, :class_name => 'Enrollment', :include => [:course, :course_section], :conditions => ENROLLMENT_CONDITIONS[:active], :order => 'enrollments.created_at'
  has_many :invited_enrollments, :class_name => 'Enrollment', :include => [:course, :course_section], :conditions => ENROLLMENT_CONDITIONS[:invited], :order => 'enrollments.created_at'
  has_many :current_and_invited_enrollments, :class_name => 'Enrollment', :include => [:course], :order => 'enrollments.created_at',
           :conditions => [ENROLLMENT_CONDITIONS[:active], ENROLLMENT_CONDITIONS[:invited]].join(' OR ')
  has_many :not_ended_enrollments, :class_name => 'Enrollment', :conditions => ["enrollments.workflow_state NOT IN (?)", ['rejected', 'completed', 'deleted']]
  has_many :concluded_enrollments, :class_name => 'Enrollment', :include => [:course, :course_section], :conditions => ENROLLMENT_CONDITIONS[:completed], :order => 'enrollments.created_at'
  has_many :observer_enrollments
  has_many :observee_enrollments, :foreign_key => :associated_user_id, :class_name => 'ObserverEnrollment'
  has_many :user_observers, :dependent => :delete_all
  has_many :observers, :through => :user_observers, :class_name => 'User'
  has_many :user_observees, :class_name => 'UserObserver', :foreign_key => :observer_id, :dependent => :delete_all
  has_many :observed_users, :through => :user_observees, :source => :user
  has_many :courses, :through => :current_enrollments, :uniq => true
  has_many :current_and_invited_courses, :source => :course, :through => :current_and_invited_enrollments
  has_many :concluded_courses, :source => :course, :through => :concluded_enrollments, :uniq => true
  has_many :all_courses, :source => :course, :through => :enrollments
  has_many :current_and_concluded_enrollments, :class_name => 'Enrollment', :include => [:course, :course_section],
           :conditions => [ENROLLMENT_CONDITIONS[:active], ENROLLMENT_CONDITIONS[:completed]].join(' OR '), :order => 'enrollments.created_at'
  has_many :current_and_concluded_courses, :source => :course, :through => :current_and_concluded_enrollments, :uniq => true
  has_many :group_memberships, :include => :group, :dependent => :destroy
  has_many :groups, :through => :group_memberships

  has_many :current_group_memberships, :include => :group, :class_name => 'GroupMembership', :conditions => "group_memberships.workflow_state = 'accepted' AND groups.workflow_state <> 'deleted'"
  has_many :current_groups, :through => :current_group_memberships, :source => :group
  has_many :user_account_associations
  has_many :associated_accounts, :source => :account, :through => :user_account_associations, :order => 'user_account_associations.depth'
  has_many :associated_root_accounts, :source => :account, :through => :user_account_associations, :order => 'user_account_associations.depth', :conditions => 'accounts.parent_account_id IS NULL'
  has_many :developer_keys
  has_many :access_tokens, :include => :developer_key

  has_many :student_enrollments
  has_many :ta_enrollments
  has_many :teacher_enrollments
  has_many :submissions, :include => [:assignment, :submission_comments], :order => 'submissions.updated_at DESC', :dependent => :destroy
  has_many :pseudonyms_with_channels, :class_name => 'Pseudonym', :order => 'position', :include => :communication_channels
  has_many :pseudonyms, :order => 'position', :dependent => :destroy
  has_many :pseudonym_accounts, :source => :account, :through => :pseudonyms
  has_one :pseudonym, :conditions => ['pseudonyms.workflow_state != ?', 'deleted'], :order => 'position'
  has_many :attachments, :as => 'context', :dependent => :destroy
  has_many :active_images, :as => :context, :class_name => 'Attachment', :conditions => ["attachments.file_state != ? AND attachments.content_type LIKE 'image%'", 'deleted'], :order => 'attachments.display_name', :include => :thumbnail
  has_many :active_assignments, :as => :context, :class_name => 'Assignment', :conditions => ['assignments.workflow_state != ?', 'deleted']
  has_many :all_attachments, :as => 'context', :class_name => 'Attachment'
  has_many :folders, :as => 'context', :order => 'folders.name'
  has_many :active_folders, :class_name => 'Folder', :as => :context, :conditions => ['folders.workflow_state != ?', 'deleted'], :order => 'folders.name'
  has_many :active_folders_with_sub_folders, :class_name => 'Folder', :as => :context, :include => [:active_sub_folders], :conditions => ['folders.workflow_state != ?', 'deleted'], :order => 'folders.name'
  has_many :active_folders_detailed, :class_name => 'Folder', :as => :context, :include => [:active_sub_folders, :active_file_attachments], :conditions => ['folders.workflow_state != ?', 'deleted'], :order => 'folders.name'
  has_many :calendar_events, :as => 'context', :dependent => :destroy, :include => [:parent_event]
  has_many :eportfolios, :dependent => :destroy
  has_many :quiz_submissions, :dependent => :destroy
  has_many :dashboard_messages, :class_name => 'Message', :conditions => {:to => "dashboard", :workflow_state => 'dashboard'}, :order => 'created_at DESC', :dependent => :destroy
  has_many :collaborations, :order => 'created_at DESC'
  has_many :user_services, :order => 'created_at', :dependent => :destroy
  has_one :scribd_account, :as => :scribdable
  has_many :rubric_associations, :as => :context, :include => :rubric, :order => 'rubric_associations.created_at DESC'
  has_many :rubrics
  has_many :context_rubrics, :as => :context, :class_name => 'Rubric'
  has_many :grading_standards
  has_many :context_module_progressions
  has_many :assignment_reminders
  has_many :assessment_question_bank_users
  has_many :assessment_question_banks, :through => :assessment_question_bank_users
  has_many :learning_outcome_results

  has_many :inbox_items, :order => 'created_at DESC'
  has_many :submission_comment_participants
  has_many :submission_comments, :through => :submission_comment_participants, :include => {:submission => {:assignment => {}, :user => {}} }
  has_many :collaborators
  has_many :collaborations, :through => :collaborators, :include => [:user, :collaborators]
  has_many :assigned_submission_assessments, :class_name => 'AssessmentRequest', :foreign_key => 'assessor_id', :include => {:user => {}, :submission => :assignment}
  has_many :assigned_assessments, :class_name => 'AssessmentRequest', :foreign_key => 'assessor_id'
  has_many :web_conference_participants
  has_many :web_conferences, :through => :web_conference_participants
  has_many :account_users
  has_many :accounts, :through => :account_users
  has_many :media_objects, :as => :context
  has_many :user_generated_media_objects, :class_name => 'MediaObject'
  has_many :page_views
  has_many :user_notes
  has_many :account_reports
  has_many :stream_item_instances, :dependent => :delete_all
  has_many :all_conversations, :class_name => 'ConversationParticipant', :include => :conversation
  has_many :favorites
  has_many :favorite_courses, :source => :course, :through => :current_and_invited_enrollments, :conditions => "EXISTS (SELECT 1 FROM favorites WHERE context_type = 'Course' AND context_id = enrollments.course_id AND user_id = enrollments.user_id)"
  has_many :zip_file_imports, :as => :context
  has_many :messages

  has_many :following_user_follows, :class_name => 'UserFollow', :as => :followed_item
  has_many :user_follows, :foreign_key => 'following_user_id'

  has_many :collections, :as => :context
  has_many :collection_items, :through => :collections

  include StickySisFields
  are_sis_sticky :name, :sortable_name, :short_name

  def conversations
    # i.e. exclude any where the user has deleted all the messages
    all_conversations.visible.scoped(:order => "last_message_at DESC, conversation_id DESC")
  end

  named_scope :of_account, lambda { |account|
    {
      :joins => :user_account_associations,
      :conditions => ['user_account_associations.account_id = ?', account.id]
    }
  }
  named_scope :recently_logged_in, lambda{
    {
      :joins => :pseudonym,
      :include => :pseudonyms,
      :conditions => ['pseudonyms.current_login_at > ?', 1.month.ago],
      :order => 'pseudonyms.current_login_at DESC',
      :limit => 25
    }
  }
  named_scope :include_pseudonym, lambda{
    {:include => :pseudonym }
  }
  named_scope :restrict_to_sections, lambda{|sections|
    section_ids = Array(sections).map{|s| s.is_a?(Fixnum) ? s : s.id }
    if section_ids.empty?
      {:conditions => {}}
    else
      {:conditions => ["enrollments.limit_privileges_to_course_section IS NULL OR enrollments.limit_privileges_to_course_section != ? OR enrollments.course_section_id IN (?)", true, section_ids]}
    end
  }
  named_scope :name_like, lambda { |name|
    { :conditions => ["(", wildcard('users.name', 'users.short_name', name), " OR exists (select 1 from pseudonyms where ", wildcard('pseudonyms.sis_user_id', 'pseudonyms.unique_id', name), " and pseudonyms.user_id = users.id and (", User.send(:sanitize_sql_array, Pseudonym.active.proxy_options[:conditions]), ")))"].join }
  }
  named_scope :active, lambda {
    { :conditions => ["users.workflow_state != ?", 'deleted'] }
  }

  named_scope :has_current_student_enrollments, :conditions =>  "EXISTS (SELECT * FROM enrollments JOIN courses ON courses.id = enrollments.course_id AND courses.workflow_state = 'available' WHERE enrollments.user_id = users.id AND enrollments.workflow_state IN ('active','invited') AND enrollments.type = 'StudentEnrollment')"

  def self.order_by_sortable_name
    scoped(:order => sortable_name_order_by_clause)
  end

  named_scope :enrolled_in_course_between, lambda{|course_ids, start_at, end_at|
    ids_string = course_ids.join(",")
    {
      :joins => :enrollments,
      :conditions => ["enrollments.course_id in (#{ids_string}) AND enrollments.created_at > ? AND enrollments.created_at < ?", start_at, end_at]
    }
  }

  has_a_broadcast_policy

  attr_accessor :require_acceptance_of_terms, :require_presence_of_name,
    :require_self_enrollment_code, :require_birthdate, :self_enrollment_code,
    :self_enrollment_course, :validation_root_account

  # users younger than this age can't sign up without a course join code
  def self.self_enrollment_min_age
    13
  end

  validates_length_of :name, :maximum => maximum_string_length, :allow_nil => true
  validates_presence_of :name, :if => :require_presence_of_name
  validates_locale :locale, :browser_locale, :allow_nil => true
  validates_acceptance_of :terms_of_use, :if => :require_acceptance_of_terms, :allow_nil => false
  validates_each :birthdate do |record, attr, value|
    next unless record.require_birthdate
    if value
      record.errors.add(attr, "too_young") if !record.require_self_enrollment_code && value > self_enrollment_min_age.years.ago
    else
      record.errors.add(attr, "blank")
    end
  end
  validates_each :self_enrollment_code do |record, attr, value|
    next unless record.require_self_enrollment_code
    if value.blank?
      record.errors.add(attr, "blank")
    elsif record.validation_root_account
      record.self_enrollment_course = record.validation_root_account.all_courses.find_by_self_enrollment_code(value)
      record.errors.add(attr, "invalid") unless record.self_enrollment_course
    else
      record.errors.add(attr, "account_required")
    end
  end

  before_save :assign_uuid
  before_save :update_avatar_image
  after_save :generate_reminders_if_changed
  after_save :update_account_associations_if_necessary
  after_save :self_enroll_if_necessary

  def self.skip_updating_account_associations(&block)
    @skip_updating_account_associations = true
    block.call
  ensure
    @skip_updating_account_associations = false
  end
  def self.skip_updating_account_associations?
    !!@skip_updating_account_associations
  end

  def update_account_associations_later
    self.send_later_if_production(:update_account_associations) unless self.class.skip_updating_account_associations?
  end

  def update_account_associations_if_necessary
    update_account_associations if !self.class.skip_updating_account_associations? && self.workflow_state_changed?
  end

  def update_account_associations(opts = {})
    User.update_account_associations([self], opts)
  end

  def self.add_to_account_chain_cache(account_id, account_chain_cache)
    if account_id.is_a? Account
      account = account_id
      account_id = account.id
    end
    return account_chain_cache[account_id] if account_chain_cache.has_key?(account_id)
    account ||= Account.find(account_id)
    return account_chain_cache[account.id] = [account.id] if account.root_account?
    account_chain_cache[account.id] = [account.id] + add_to_account_chain_cache(account.parent_account_id, account_chain_cache)
  end

  def self.calculate_account_associations_from_accounts(starting_account_ids, account_chain_cache = {})
    results = {}
    remaining_ids = []
    starting_account_ids.each do |account_id|
      unless account_chain_cache.has_key? account_id
        remaining_ids << account_id
        next
      end
      account_chain = account_chain_cache[account_id]
      account_chain.each_with_index do |account_id, idx|
        results[account_id] ||= idx
        results[account_id] = idx if idx < results[account_id]
      end
    end

    unless remaining_ids.empty?
      accounts = Account.find_all_by_id(remaining_ids)
      accounts.each do |account|
        account_chain = add_to_account_chain_cache(account, account_chain_cache)
        account_chain.each_with_index do |account_id, idx|
          results[account_id] ||= idx
          results[account_id] = idx if idx < results[account_id]
        end
      end
    end
    results
  end

  # Users are tied to accounts a couple ways:
  #   Through enrollments:
  #      User -> Enrollment -> Section -> Course -> Account
  #      User -> Enrollment -> Section -> Non-Xlisted Course -> Account
  #   Through pseudonyms:
  #      User -> Pseudonym -> Account
  #   Through account_users
  #      User -> AccountUser -> Account
  def calculate_account_associations(account_chain_cache = {})
    return [] if %w{creation_pending deleted}.include?(self.workflow_state)

    # Hopefully these have all been pre-loaded
    starting_account_ids = self.enrollments.map { |e| e.workflow_state != 'deleted' ? [e.course_section.course.account_id, e.course_section.nonxlist_course.try(:account_id)] : nil }.flatten.compact
    starting_account_ids += self.pseudonyms.map { |p| p.active? ? p.account_id : nil }.compact
    starting_account_ids += self.account_users.map(&:account_id)
    starting_account_ids.uniq!

    result = User.calculate_account_associations_from_accounts(starting_account_ids, account_chain_cache)
    result
  end

  def self.update_account_associations(users_or_user_ids, opts = {})
    return if users_or_user_ids.empty?

    opts.reverse_merge! :account_chain_cache => {}
    account_chain_cache = opts[:account_chain_cache]

    # Split it up into manageable chunks
    if users_or_user_ids.length > 500
      users_or_user_ids.uniq.compact.each_slice(500) do |users_or_user_ids_slice|
        update_account_associations(users_or_user_ids_slice, opts)
      end
      return
    end

    incremental = opts[:incremental]
    precalculated_associations = opts[:precalculated_associations]

    user_ids = users_or_user_ids
    user_ids = user_ids.map(&:id) if user_ids.first.is_a?(User)
    users_or_user_ids = User.find(:all, :conditions => {:id => user_ids}, :include => [:pseudonyms, :account_users, { :enrollments => { :course_section => [ :course, :nonxlist_course ] }}]) if !user_ids.first.is_a?(User) && !precalculated_associations
    UserAccountAssociation.transaction do
      current_associations = {}
      to_delete = []
      UserAccountAssociation.find(:all, :conditions => { :user_id => user_ids }).each do |aa|
        key = [aa.user_id, aa.account_id]
        # duplicates
        if current_associations.has_key?(key)
          to_delete << aa.id
          next
        end
        current_associations[key] = [aa.id, aa.depth]
      end

      users_or_user_ids.each do |user_id|
        if user_id.is_a? User
          user = user_id
          user_id = user_id.id
        end

        account_ids_with_depth = precalculated_associations
        if account_ids_with_depth.nil?
          user ||= User.find(user_id)
          account_ids_with_depth = user.calculate_account_associations(account_chain_cache)
        end

        # we don't want student view students to have account associations.
        next if user && user.fake_student?

        account_ids_with_depth.each do |account_id, depth|
          key = [user_id, account_id]
          association = current_associations[key]
          if association.nil?
            # new association, create it
            UserAccountAssociation.create! do |aa|
              aa.user_id = user_id
              aa.account_id = account_id
              aa.depth = depth
            end
          else
            # for incremental, only update the old association if it is deeper than the new one
            # for non-incremental, update it if it changed
            if incremental && association[1] > depth || !incremental && association[1] != depth
              UserAccountAssociation.update_all("depth=#{depth}", :id => association[0])
            end
            # remove from list of existing for non-incremental
            current_associations.delete(key) unless incremental
          end
        end
      end

      to_delete += current_associations.map { |k, v| v[0] }
      UserAccountAssociation.delete_all(:id => to_delete) unless incremental || to_delete.empty?
    end
  end

  # These two methods can be overridden by a plugin if you want to have an approval process for new teachers
  def registration_approval_required?; false; end
  def new_teacher_registration(form_params = {}); end

  set_broadcast_policy do |p|
    p.dispatch :new_teacher_registration
    p.to { Account.site_admin.users }
    p.whenever { |record|
      record.just_created && record.school_name && record.school_position
    }
  end

  def assign_uuid
    # DON'T use ||=, because that will cause an immediate save to the db if it
    # doesn't already exist
    self.uuid = AutoHandle.generate_securish_uuid if !read_attribute(:uuid)
  end
  protected :assign_uuid

  def hashtag
    nil
  end

  named_scope :with_service, lambda { |service|
    if service.is_a?(UserService)
      {:include => :user_services, :conditions => ['user_services.service = ?', service.service]}
    else
      {:include => :user_services, :conditions => ['user_services.service = ?', service.to_s]}
    end
  }
  named_scope :enrolled_before, lambda{|date|
    {:conditions => ['enrollments.created_at < ?', date]}
  }

  def group_memberships_for(context)
    return [] unless context
    self.group_memberships.select do |m|
      m.group &&
      m.group.context_id == context.id &&
      m.group.context_type == context.class.to_s &&
      !m.group.deleted? &&
      m.accepted?
    end.map(&:group)
  end

  def <=>(other)
    self.name <=> other.name
  end

  def default_pseudonym_id
    self.pseudonyms.active.first.id
  end

  def available?
    true
  end

  def participants
    []
  end

  # compatibility only - this isn't really last_name_first
  def last_name_first
    self.sortable_name
  end

  def last_name_first_or_unnamed
    res = last_name_first
    res = "No Name" if res.strip.empty?
    res
  end

  def first_name
    User.name_parts(self.sortable_name)[0] || ''
  end

  def last_name
    User.name_parts(self.sortable_name)[1] || ''
  end

  # Feel free to add, but the "authoritative" list (http://en.wikipedia.org/wiki/Title_(name)) is quite large
  SUFFIXES = /^(Sn?r\.?|Senior|Jn?r\.?|Junior|II|III|IV|V|VI|Esq\.?|Esquire)$/i

  # see also user_sortable_name.js
  def self.name_parts(name, prior_surname = nil)
    return [nil, nil, nil] unless name
    surname, given, suffix = name.strip.split(/\s*,\s*/, 3)

    # Doe, John, Sr.
    # Otherwise change Ho, Chi, Min to Ho, Chi Min
    if suffix && !(suffix =~ SUFFIXES)
      given = "#{given} #{suffix}"
      suffix = nil
    end

    if given
      # John Doe, Sr.
      if !suffix && given =~ SUFFIXES
        suffix = given
        given = surname
        surname = nil
      end
    else
      # John Doe
      given = name.strip
      surname = nil
    end

    given_parts = given.split
    # John Doe Sr.
    if !suffix && given_parts.length > 1 && given_parts.last =~ SUFFIXES
      suffix = given_parts.pop
    end
    # Use prior information on the last name to try and reconstruct it
    prior_surname_parts = nil
    surname = given_parts.pop(prior_surname_parts.length).join(' ') if !surname && prior_surname.present? && (prior_surname_parts = prior_surname.split) && !prior_surname_parts.empty? && given_parts.length >= prior_surname_parts.length && given_parts[-prior_surname_parts.length..-1] == prior_surname_parts
    # Last resort; last name is just the last word given
    surname = given_parts.pop if !surname && given_parts.length > 1

    [ given_parts.empty? ? nil : given_parts.join(' '), surname, suffix ]
  end

  def self.last_name_first(name, name_was = nil)
    given, surname, suffix = name_parts(name, name_parts(name_was)[1])
    given = [given, suffix].compact.join(' ')
    surname ? "#{surname}, #{given}".strip : given
  end

  def self.user_lookup_cache_key(id)
    ['_user_lookup2', id].cache_key
  end

  def self.invalidate_cache(id)
    Rails.cache.delete(user_lookup_cache_key(id)) if id
  rescue
    nil
  end

  def infer_defaults
    self.name = nil if self.name == "User"
    self.name ||= self.email || t(:default_user_name, "User")
    self.short_name = nil if self.short_name == ""
    self.short_name ||= self.name
    self.sortable_name = nil if self.sortable_name == ""
    # recalculate the sortable name if the name changed, but the sortable name didn't, and the sortable_name matches the old name
    self.sortable_name = nil if !self.sortable_name_changed? && self.name_changed? && User.name_parts(self.sortable_name).compact.join(' ') == self.name_was
    self.sortable_name = User.last_name_first(self.name, self.sortable_name_was) unless read_attribute(:sortable_name)
    self.reminder_time_for_due_dates ||= 48.hours.to_i
    self.reminder_time_for_grading ||= 0
    User.invalidate_cache(self.id) if self.id
    @reminder_times_changed = self.reminder_time_for_due_dates_changed? || self.reminder_time_for_grading_changed?
    true
  end

  def sortable_name
    self.sortable_name = read_attribute(:sortable_name) || User.last_name_first(self.name)
  end

  def primary_pseudonym
    self.pseudonyms.active.first
  end

  def primary_pseudonym=(p)
    p = Pseudonym.find(p)
    p.move_to_top
    self.reload
    p
  end

  def email_channel
    # It's already ordered, so find the first one, if there's one.
    communication_channels.to_a.find{|cc| cc.path_type == 'email' && cc.workflow_state != 'retired' }
  end

  def email
    Rails.cache.fetch(['user_email', self].cache_key) do
      email_channel.path if email_channel
    end
  end

  def self.cached_name(id)
    key = user_lookup_cache_key(id)
    user = Rails.cache.fetch(key) do
      User.find_by_id(id)
    end
    user && user.name
  end

  def gmail_channel
    google_services = self.user_services.find_all_by_service_domain("google.com")
    addr = google_services.find{|s| s.service_user_id}.service_user_id rescue nil
    self.communication_channels.email.by_path(addr).find(:first)
  end

  def gmail
    res = gmail_channel.path rescue nil
    res ||= self.user_services.find_all_by_service_domain("google.com").map(&:service_user_id).compact.first
    res ||= email
  end

  def google_docs_address
    service = self.user_services.find_by_service('google_docs')
    service && service.service_user_id
  end

  def email=(e)
    if e.is_a?(CommunicationChannel) and e.user_id == self.id
      cc = e
    else
      cc = self.communication_channels.find_or_create_by_path_and_path_type(e, 'email')
      cc.user = self
    end
    cc.move_to_top
    cc.save!
    self.reload
    cc.path
  end

  def sms_channel
    # It's already ordered, so find the first one, if there's one.
    communication_channels.find(:first, :conditions => {:path_type => 'sms'})
  end

  def sms
    sms_channel.path if sms_channel
  end

  def sms=(s)
    if s.is_a?(CommunicationChannel) and s.user_id == self.id
      cc = s
    else
      cc = CommunicationChannel.find_or_create_by_path_and_user_id(s, self.id)
    end
    cc.move_to_top
    cc.save!
    self.reload
    cc.path
  end

  def short_name
    read_attribute(:short_name) || name
  end

  def unread_inbox_items_count
    count = read_attribute(:unread_inbox_items_count)
    if count.nil?
      self.unread_inbox_items_count = count = self.inbox_items.unread.count rescue 0
      self.save
    end
    count
  end

  workflow do
    state :pre_registered do
      event :register, :transitions_to => :registered
    end

    # Not listing this first so it is not the default.
    state :pending_approval do
      event :approve, :transitions_to => :pre_registered
      event :reject, :transitions_to => :deleted
    end

    state :creation_pending do
      event :create_user, :transitions_to => :pre_registered
      event :register, :transitions_to => :registered
    end

    state :registered

    state :deleted
  end

  def unavailable?
    deleted?
  end

  alias_method :destroy!, :destroy
  def destroy(even_if_managed_passwords=false)
    ActiveRecord::Base.transaction do
      self.workflow_state = 'deleted'
      self.save
      self.pseudonyms.each{|p| p.destroy(even_if_managed_passwords) }
      self.communication_channels.each{|cc| cc.destroy }
      self.enrollments.each{|e| e.destroy }
    end
  end

  def remove_from_root_account(account)
    self.enrollments.find_all_by_root_account_id(account.id).each(&:destroy)
    self.pseudonyms.active.find_all_by_account_id(account.id).each { |p| p.destroy(true) }
    self.account_users.find_all_by_account_id(account.id).each(&:destroy)
    self.save
    self.update_account_associations
  end

  def move_to_user(new_user)
    return unless new_user
    return if new_user == self
    max_position = (new_user.pseudonyms.last.position || 0) rescue 0
    new_user.save
    updates = []
    self.pseudonyms.each do |p|
      max_position += 1
      updates << "WHEN id=#{p.id} THEN #{max_position}"
    end
    Pseudonym.connection.execute("UPDATE pseudonyms SET user_id=#{new_user.id}, position=CASE #{updates.join(" ")} ELSE NULL END WHERE id IN (#{self.pseudonyms.map(&:id).join(',')})") unless self.pseudonyms.empty?

    max_position = (new_user.communication_channels.last.position || 0) rescue 0
    position_updates = []
    to_retire_ids = []
    self.communication_channels.each do |cc|
      max_position += 1
      position_updates << "WHEN id=#{cc.id} THEN #{max_position}"
      source_cc = cc
      # have to find conflicting CCs, and make sure we don't have conflicts
      # To avoid the case where a user has duplicate CCs and one of them is retired, don't look for retired ccs
      # it's okay to do that even if the only matching CC is a retired CC, because it would end up on the no-op
      # case below anyway.
      # Behavior is undefined if a user has both an active and an unconfirmed CC; it's not allowed with current
      # validations, but could be there due to older code that didn't enforce the uniqueness.  The results would
      # simply be that they'll continue to have duplicate unretired CCs
      target_cc = new_user.communication_channels.detect { |cc| cc.path.downcase == source_cc.path.downcase && cc.path_type == source_cc.path_type && !cc.retired? }
      next unless target_cc

      # we prefer keeping the "most" active one, preferring the target user if they're equal
      # the comments inline show all the different cases, with the source cc on the left,
      # target cc on the right.  The * indicates the CC that will be retired in order
      # to resolve the conflict
      if target_cc.active?
        # retired, active
        # unconfirmed*, active
        # active*, active
        to_retire = source_cc
      elsif source_cc.active?
        # active, unconfirmed*
        # active, retired
        to_retire = target_cc
      elsif target_cc.unconfirmed?
        # unconfirmed*, unconfirmed
        # retired, unconfirmed
        to_retire = source_cc
      end
      #elsif
        # unconfirmed, retired
        # retired, retired
      #end

      to_retire_ids << to_retire.id if to_retire && !to_retire.retired?
    end
    CommunicationChannel.update_all("user_id=#{new_user.id}, position=CASE #{position_updates.join(" ")} ELSE NULL END", :id => self.communication_channels.map(&:id)) unless self.communication_channels.empty?
    CommunicationChannel.update_all({:workflow_state => 'retired'}, :id => to_retire_ids) unless to_retire_ids.empty?

    to_delete_ids = []
    self.enrollments.each do |enrollment|
      source_enrollment = enrollment
      # non-deleted enrollments should be unique per [course_section, type]
      target_enrollment = new_user.enrollments.detect { |enrollment| enrollment.course_section_id == source_enrollment.course_section_id && enrollment.type == source_enrollment.type && !['deleted', 'inactive', 'rejected'].include?(enrollment.workflow_state) }
      next unless target_enrollment

      # we prefer keeping the "most" active one, preferring the target user if they're equal
      # the comments inline show all the different cases, with the source enrollment on the left,
      # target enrollment on the right.  The * indicates the enrollment that will be deleted in order
      # to resolve the conflict.
      if target_enrollment.active?
        # deleted, active
        # inactive, active
        # rejected, active
        # invited*, active
        # creation_pending*, active
        # active*, active
        # completed*, active
        to_delete = source_enrollment
      elsif source_enrollment.active?
        # active, deleted
        # active, inactive
        # active, rejected
        # active, invited*
        # active, creation_pending*
        # active, completed*
        to_delete = target_enrollment
      elsif target_enrollment.completed?
        # deleted, completed
        # inactive, completed
        # rejected, completed
        # invited*, completed
        # creation_pending*, completed
        # completed*, completed
        to_delete = source_enrollment
      elsif source_enrollment.completed?
        # completed, deleted
        # completed, inactive
        # completed, rejected
        # completed, invited*
        # completed, creation_pending*
        to_delete = target_enrollment
      elsif target_enrollment.invited?
        # deleted, invited
        # inactive, invited
        # rejected, invited
        # creation_pending*, invited
        # invited*, invited
        to_delete = source_enrollment
      elsif source_enrollment.invited?
        # invited, deleted
        # invited, inactive
        # invited, rejected
        # invited, creation_pending*
        to_delete = target_enrollment
      elsif target_enrollment.creation_pending?
        # deleted, creation_pending
        # inactive, creation_pending
        # rejected, creation_pending
        # creation_pending*, creation_pending
        to_delete = source_enrollment
      end
      #elsif
        # creation_pending, deleted
        # creation_pending, inactive
        # creation_pending, rejected
        # deleted, rejected
        # inactive, rejected
        # rejected, rejected
        # rejected, deleted
        # rejected, inactive
        # deleted, inactive
        # inactive, inactive
        # inactive, deleted
        # deleted, deleted
      #end

      to_delete_ids << to_delete.id if to_delete && !['deleted', 'inactive', 'rejected'].include?(to_delete.workflow_state)
    end
    Enrollment.update_all({:workflow_state => 'deleted'}, :id => to_delete_ids) unless to_delete_ids.empty?

    [
      [:quiz_id, :quiz_submissions],
      [:assignment_id, :submissions]
    ].each do |unique_id, table|
      begin
        # Submissions are a special case since there's a unique index
        # on the table, and if both the old user and the new user
        # have a submission for the same assignment there will be
        # a conflict.
        already_there_ids = table.to_s.classify.constantize.find_all_by_user_id(new_user.id).map(&unique_id)
        already_there_ids = [0] if already_there_ids.empty?
        table.to_s.classify.constantize.update_all({:user_id => new_user.id}, "user_id=#{self.id} AND #{unique_id} NOT IN (#{already_there_ids.join(',')})")
      rescue => e
        logger.error "migrating #{table} column user_id failed: #{e.to_s}"
      end
    end
    all_conversations.find_each{ |c| c.move_to_user(new_user) }
    updates = {}
    ['account_users','asset_user_accesses',
      'assignment_reminders','attachments',
      'calendar_events','collaborations',
      'context_module_progressions','discussion_entries','discussion_topics',
      'enrollments','group_memberships','page_comments',
      'rubric_assessments','short_messages',
      'submission_comment_participants','user_services','web_conferences',
      'web_conference_participants','wiki_pages'].each do |key|
      updates[key] = "user_id"
    end
    updates['submission_comments'] = 'author_id'
    updates['conversation_messages'] = 'author_id'
    updates = updates.to_a
    updates << ['enrollments', 'associated_user_id']
    updates.each do |table, column|
      begin
        klass = table.classify.constantize
        if klass.new.respond_to?("#{column}=".to_sym)
          klass.connection.execute("UPDATE #{table} SET #{column}=#{new_user.id} WHERE #{column}=#{self.id}")
        end
      rescue => e
        logger.error "migrating #{table} column #{column} failed: #{e.to_s}"
      end
    end
    # delete duplicate enrollments where this user is the observee
    new_user.observee_enrollments.remove_duplicates!

    # delete duplicate observers/observees, move the rest
    user_observees.where(:user_id => new_user.user_observees.map(&:user_id)).delete_all
    user_observees.update_all(:observer_id => new_user.id)
    xor_observer_ids = (Set.new(user_observers.map(&:observer_id)) ^ new_user.user_observers.map(&:observer_id)).to_a
    user_observers.where(:observer_id => new_user.user_observers.map(&:observer_id)).delete_all
    user_observers.update_all(:user_id => new_user.id)
    # for any observers not already watching both users, make sure they have
    # any missing observer enrollments added
    new_user.user_observers.where(:observer_id => xor_observer_ids).each(&:create_linked_enrollments)

    self.reload
    Enrollment.send_later(:recompute_final_scores, new_user.id)
    new_user.update_account_associations
    new_user.touch
    self.destroy
  end

  # Overwrites the old user name, if there was one.  Fills in the new one otherwise.
  def assert_name(name=nil)
    if name && (self.pre_registered? || self.creation_pending?) && name != email
      self.name = name
      save!
    end
    self
  end

  def to_atom
    Atom::Entry.new do |entry|
      entry.title     = self.name
      entry.updated   = self.updated_at
      entry.published = self.created_at
      entry.links    << Atom::Link.new(:rel => 'alternate',
                                    :href => "/users/#{self.id}")
    end
  end

  def admins
    [self]
  end

  def students
    [self]
  end

  def latest_pseudonym
    Pseudonym.scoped(:order => 'created_at DESC', :conditions => {:user_id => id}).active.first
  end

  def used_feature(feature)
    self.update_attribute(:features_used, ((self.features_used || "").split(/,/).map(&:to_s) + [feature.to_s]).uniq.join(','))
  end

  def used_feature?(feature)
    self.features_used && self.features_used.split(/,/).include?(feature.to_s)
  end

  def available_courses
    # this list should be longer if the person has admin privileges...
    self.courses
  end

  def courses_with_grades
    self.available_courses.select{|c| c.grants_right?(self, nil, :participate_as_student)}
  end
  memoize :courses_with_grades

  def sis_pseudonym_for(context)
    root_account = context.root_account
    raise "could not resolve root account" unless root_account.is_a?(Account)
    if self.pseudonyms.loaded?
      self.pseudonyms.detect { |p| p.active? && p.sis_user_id && p.account_id == root_account.id }
    else
      self.pseudonyms.active.find_by_account_id(root_account.id, :conditions => ["sis_user_id IS NOT NULL"])
    end
  end

  set_policy do
    given { |user| user == self }
    can :read and can :manage and can :manage_content and can :manage_files and can :manage_calendar and can :send_messages and can :update_avatar

    given { |user| user.present? && self.public? }
    can :follow

    given { |user| user == self && user.user_can_edit_name? }
    can :rename

    given {|user| self.courses.any?{|c| c.user_is_teacher?(user)}}
    can :rename and can :create_user_notes and can :read_user_notes

    given do |user|
      user && (
        # this means that the user we are given is an administrator of an account of one of the courses that this user is enrolled in
        self.all_courses.any? { |c| c.grants_right?(user, nil, :read_reports) }
      )
    end
    can :rename and can :remove_avatar and can :view_statistics

    given do |user|
      user && self.all_courses.any? { |c| c.grants_right?(user, nil, :manage_user_notes) }
    end
    can :create_user_notes and can :read_user_notes

    given { |user| user && self.all_courses.any? { |c| c.grants_right?(user, nil, :read_user_notes) } }
    can :read_user_notes

    given do |user|
      user && (
        self.associated_accounts.any?{|a| a.grants_right?(user, nil, :manage_user_notes)}
      )
    end
    can :create_user_notes and can :read_user_notes and can :delete_user_notes

    given do |user|
      user && (
        # or, if the user we are given is an admin in one of this user's accounts
        Account.site_admin.grants_right?(user, :manage_students) ||
        self.associated_accounts.any? {|a| a.grants_right?(user, nil, :manage_students) }
      )
    end
    can :manage_user_details and can :update_avatar and can :remove_avatar and can :rename and can :view_statistics and can :read

    given do |user|
      user && (
        # or, if the user we are given is an admin in one of this user's accounts
        Account.site_admin.grants_right?(user, :manage_user_logins) ||
        self.associated_accounts.any?{|a| a.grants_right?(user, nil, :manage_user_logins) }
      )
    end
    can :manage_user_details and can :manage_logins and can :rename and can :view_statistics and can :read
  end

  def can_masquerade?(masquerader, account)
    return true if self == masquerader
    # student view should only ever have enrollments in a single course
    return true if self.fake_student? && self.courses.any?{ |c| c.grants_right?(masquerader, nil, :use_student_view) }
    return false unless
        account.grants_right?(masquerader, nil, :become_user) && self.find_pseudonym_for_account(account, true)
    account_users = account.all_account_users_for(self)
    return true if account_users.empty?
    account_users.map(&:account).uniq.all? do |account|
      needed_rights = account.check_policy(self)
      account.grants_rights?(masquerader, nil, *needed_rights).values.all?
    end
  end

  def self.infer_id(obj)
    case obj
    when User
      obj.id
    when Numeric
      obj
    when CommunicationChannel
      obj.user_id
    when Pseudonym
      obj.user_id
    when AccountUser
      obj.user_id
    when OpenObject
      obj.id
    when String
      obj.to_i
    else
      raise ArgumentError, "Cannot infer a user_id from #{obj.inspect}"
    end
  end

  def management_contexts
    contexts = [self] + self.courses + self.groups.active + self.all_courses
    contexts.uniq
  end

  def file_management_contexts
    contexts = [self] + self.courses + self.groups.active + self.all_courses
    contexts.uniq.select{|c| c.grants_right?(self, nil, :manage_files) }
  end

  def facebook
    self.user_services.for_service('facebook').first rescue nil
  end

  def visible_inbox_types=(val)
    types = (val || "").split(",")
    write_attribute(:visible_inbox_types, types.map{|t| t.classify }.join(","))
  end

  def show_in_inbox?(type)
    if self.respond_to?(:visible_inbox_types) && self.visible_inbox_types
      types = self.visible_inbox_types.split(",")
      types.include?(type)
    else
      true
    end
  end

  def submitted_submission_for(assignment_id)
    @submissions ||= self.submissions.having_submission.to_a
    @submissions.detect{|s| s.assignment_id == assignment_id }
  end

  def attempted_quiz_submission_for(quiz_id)
    @quiz_submissions ||= self.quiz_submissions.select{|s| !s.settings_only? }
    @quiz_submissions.detect{|qs| qs.quiz_id == quiz_id }
  end

  def module_progression_for(module_id)
    @module_progressions ||= self.context_module_progressions.to_a
    @module_progressions.detect{|p| p.context_module_id == module_id }
  end

  def clear_cached_lookups
    @module_progressions = nil
    @quiz_submissions = nil
    @submissions = nil
  end

  def update_avatar_image(force_reload=false)
    if !self.avatar_image_url || force_reload
      if self.avatar_image_source == 'facebook'
        # TODO: support this
      elsif self.avatar_image_source == 'twitter'
        twitter = self.user_services.for_service('twitter').first rescue nil
        if twitter
          url = URI.parse("http://twitter.com/users/show.json?user_id=#{twitter.service_user_id}")
          data = JSON.parse(Net::HTTP.get(url)) rescue nil
          if data
            self.avatar_image_url = data['profile_image_url_https'] || self.avatar_image_url
            self.avatar_image_updated_at = Time.now
          end
        end
      end
    end
  end

  def self.max_messages_per_day
    Setting.get('max_messages_per_day_per_user', 500).to_i
  end

  def max_messages_per_day
    User.max_messages_per_day
  end

  def gravatar_url(size=50, fallback=nil, request=nil)
    fallback = self.class.avatar_fallback_url(fallback, request)
    "https://secure.gravatar.com/avatar/#{Digest::MD5.hexdigest(self.email) rescue '000'}?s=#{size}&d=#{CGI::escape(fallback)}"
  end

  # Public: Set a user's avatar image. This is a convenience method that sets
  #   the avatar_image_source, avatar_image_url, avatar_updated_at, and
  #   avatar_state on the user model.
  #
  # val - A hash of options used to configure the avatar.
  #       :type - The type of avatar. Should be 'facebook,' 'gravatar,'
  #         'twitter,' 'linked_in,' 'external,' or 'attachment.'
  #       :url - The URL of the gravatar. Used for types 'external' and
  #         'attachment.'
  #
  # Returns nothing if avatar is set; false if avatar is locked.
  def avatar_image=(val)
    return false if avatar_state == :locked

    # Clear out the old avatar first, in case of failure to get new avatar.
    # The order of these attributes is standard throughout the method.
    self.avatar_image_source = 'no_pic'
    self.avatar_image_url = nil
    self.avatar_image_updated_at = Time.zone.now
    self.avatar_state = 'approved'

    # Return here if we're passed a nil val or any non-hash val (both of which
    # will just nil the user's avatar).
    return unless val.is_a?(Hash)

    if val['type'] == 'facebook'
      # TODO: support this
    elsif val['type'] == 'gravatar'
      self.avatar_image_source = 'gravatar'
      self.avatar_image_url = nil
      self.avatar_state = 'submitted'
    elsif val['type'] == 'twitter'
      twitter = self.user_services.for_service('twitter').first rescue nil
      if twitter
        url = URI.parse("http://twitter.com/users/show.json?user_id=#{twitter.service_user_id}")
        data = JSON.parse(Net::HTTP.get(url)) rescue nil
        if data
          self.avatar_image_source = 'twitter'
          self.avatar_image_url = data['profile_image_url_https'] || self.avatar_image_url
          self.avatar_state = 'submitted'
        end
      end
    elsif val['type'] == 'linked_in'
      @linked_in_service = self.user_services.for_service('linked_in').first rescue nil
      if @linked_in_service
        self.extend LinkedIn
        profile = linked_in_profile
        if profile
          self.avatar_image_source = 'linked_in'
          self.avatar_image_url = profile['picture_url']
          self.avatar_state = 'submitted'
        end
      end
    elsif val['type'] == 'external'
      self.avatar_image_source = 'external'
      self.avatar_image_url = val['url']
      self.avatar_state = 'submitted'
    elsif val['type'] == 'attachment' && val['url']
      self.avatar_image_source = 'attachment'
      self.avatar_image_url = val['url']
      self.avatar_state = 'submitted'
    end
  end

  def report_avatar_image!(associated_context=nil)
    if avatar_state == :approved || avatar_state == :locked
      avatar_state = 're_reported'
    else
      avatar_state = 'reported'
    end
    save!
  end

  def avatar_state
    if ['none', 'submitted', 'approved', 'locked', 'reported', 're_reported'].include?(read_attribute(:avatar_state))
      read_attribute(:avatar_state).to_sym
    else
      :none
    end
  end

  def avatar_state=(val)
    if ['none', 'submitted', 'approved', 'locked', 'reported', 're_reported'].include?(val.to_s)
      if val == 'none'
        self.avatar_image_url = nil
        self.avatar_image_source = 'no_pic'
        self.avatar_image_updated_at = Time.now
      end
      write_attribute(:avatar_state, val.to_s)
    end
  end

  def avatar_reportable?
    [:submitted, :approved, :reported, :re_reported].include?(avatar_state)
  end

  def avatar_approvable?
    [:submitted, :reported, :re_reported].include?(avatar_state)
  end

  def avatar_approved?
    [:approved, :locked, :re_reported].include?(avatar_state)
  end

  def self.avatar_key(user_id)
    user_id = user_id.to_s
    if !user_id.blank? && user_id != '0'
      "#{user_id}-#{Canvas::Security.hmac_sha1(user_id)[0, 10]}"
    else
      "0"
    end
  end

  def self.user_id_from_avatar_key(key)
    user_id, sig = key.to_s.split(/-/, 2)
    (Canvas::Security.hmac_sha1(user_id.to_s)[0, 10] == sig) ? user_id : nil
  end

  # Returns the LTI membership based on the LTI specs here: http://www.imsglobal.org/LTI/v1p1pd/ltiIMGv1p1pd.html#_Toc309649701
  def lti_role_types(context=nil)
    memberships = []
    if context.is_a?(Course)
      memberships += current_enrollments.find_all_by_course_id(context.id).uniq
    end
    if context.respond_to?(:account_chain) && !context.account_chain_ids.empty?
      memberships += account_users.find_all_by_membership_type_and_account_id('AccountAdmin', context.account_chain_ids).uniq
    end
    return ["urn:lti:sysrole:ims/lis/None"] if memberships.empty?
    memberships.map{|membership|
      case membership
      when StudentEnrollment, StudentViewEnrollment
        'Learner'
      when TeacherEnrollment
        'Instructor'
      when TaEnrollment
        'Instructor'
      when DesignerEnrollment
        'ContentDeveloper'
      when ObserverEnrollment
        'urn:lti:instrole:ims/lis/Observer'
      when AccountUser
        'urn:lti:instrole:ims/lis/Administrator'
      else
        'urn:lti:instrole:ims/lis/Observer'
      end
    }.uniq
  end

  AVATAR_SETTINGS = ['enabled', 'enabled_pending', 'sis_only', 'disabled']
  def avatar_url(size=nil, avatar_setting=nil, fallback=nil, request=nil)
    size ||= 50
    avatar_setting ||= 'enabled'
    fallback = self.class.avatar_fallback_url(fallback, request)
    if avatar_setting == 'enabled' || (avatar_setting == 'enabled_pending' && avatar_approved?) || (avatar_setting == 'sis_only')
      @avatar_url ||= self.avatar_image_url
    end
    @avatar_url ||= fallback if self.avatar_image_source == 'no_pic'
    @avatar_url ||= gravatar_url(size, fallback, request) if avatar_setting == 'enabled'
    @avatar_url ||= fallback
  end

  def avatar_path
    "/images/users/#{User.avatar_key(self.id)}"
  end

  def self.default_avatar_fallback
    "/images/messages/avatar-50.png"
  end

  def self.avatar_fallback_url(fallback=nil, request=nil)
    return fallback if fallback == '%{fallback}'
    if fallback and uri = URI.parse(fallback) rescue nil
      uri.scheme ||= request ? request.scheme : "https"
      if request && !uri.host
        uri.host = request.host
        uri.port = request.port if ![80, 443].include?(request.port)
      elsif !uri.host
        uri.host = HostUrl.default_host.split(/:/)[0]
        uri.port = HostUrl.default_host.split(/:/)[1]
      end
      uri.to_s
    else
      avatar_fallback_url(default_avatar_fallback, request)
    end
  end

  # Clear the avatar_image_url attribute and save it if the URL contains the given uuid.
  #
  # ==== Arguments
  # * <tt>uuid</tt> - The Attachment#uuid value for the file. Used as part of the url identifier.
  def clear_avatar_image_url_with_uuid(uuid)
    raise ArgumentError, "'uuid' is required and cannot be blank" if uuid.blank?
    if self.avatar_image_url.to_s.match(/#{uuid}/)
      self.avatar_image_url = nil
      self.save
    end
  end

  named_scope :with_avatar_state, lambda{|state|
    if state == 'any'
      {
        :conditions =>['avatar_image_url IS NOT NULL AND avatar_state IS NOT NULL AND avatar_state != ?', 'none'],
        :order => 'avatar_image_updated_at DESC'
      }
    else
      {
        :conditions => ['avatar_image_url IS NOT NULL AND avatar_state = ?', state],
        :order => 'avatar_image_updated_at DESC'
      }
    end
  }

  def sorted_rubrics
    context_codes = ([self] + self.management_contexts).uniq.map(&:asset_string)
    rubrics = self.context_rubrics.active
    rubrics += Rubric.active.find_all_by_context_code(context_codes)
    rubrics.uniq.sort_by{|r| [(r.association_count || 0) > 3 ? 'a' : 'b', (r.title.downcase rescue 'zzzzz')]}
  end

  def assignments_recently_graded(opts={})
    opts = { :start_at => 1.week.ago, :limit => 10 }.merge(opts)
    Submission.recently_graded_assignments(id, opts[:start_at], opts[:limit])
  end
  memoize :assignments_recently_graded

  def assignments_recently_graded_total_count(opts={})
    assignments_recently_graded(opts.merge({:limit => nil})).size
  end
  memoize :assignments_recently_graded_total_count

  def preferences
    read_attribute(:preferences) || write_attribute(:preferences, {})
  end

  def watched_conversations_intro?
    preferences[:watched_conversations_intro] == true
  end

  def watched_conversations_intro(value=true)
    preferences[:watched_conversations_intro] = value
  end

  def send_scores_in_emails?
    preferences[:send_scores_in_emails] == true
  end


  def close_announcement(announcement)
    preferences[:closed_notifications] ||= []
    # serialize ids relative to the user
    self.shard.activate do
      preferences[:closed_notifications] << announcement.id
    end
    preferences[:closed_notifications].uniq!
    save
  end

  def ignore_item!(asset_string, purpose, permanent=nil)
    permanent ||= false
    asset_string = asset_string.gsub(/![0-9a-z_]/, '')
    preferences[:ignore] ||= {}
    preferences[:ignore][purpose.to_sym] ||= {}
    preferences[:ignore][purpose.to_sym].each do |key, item|
      preferences[:ignore][purpose.to_sym].delete(key) if item && (!item[:set] || item[:set] < 6.months.ago.utc.iso8601)
    end
    preferences[:ignore][purpose.to_sym][asset_string] = {:permanent => permanent, :set => Time.now.utc.iso8601}
    self.updated_at = Time.now
    save!
  end

  def ignored_item_changed!(asset_string, purpose)
    preferences[:ignore] ||= {}
    preferences[:ignore][purpose.to_sym] ||= {}
    if preferences[:ignore][purpose.to_sym][asset_string]
      preferences[:ignore][purpose.to_sym].delete(asset_string) if !preferences[:ignore][purpose.to_sym][asset_string][:permanent]
    end
    self.updated_at = Time.now
    save!
  end

  def ignored_items(purpose)
    (preferences[:ignore] || {})[purpose.to_sym] || {}
  end

  def assignments_needing_submitting(opts={})
    course_codes = opts[:contexts] ? (Array(opts[:contexts]).map(&:asset_string) & current_student_enrollment_course_codes) : current_student_enrollment_course_codes
    ignored_ids = ignored_items(:submitting).select{|key, val| key.match(/\Aassignment_/) }.map{|key, val| key.sub(/\Aassignment_/, "") }
    Assignment.for_context_codes(course_codes).active.due_before(1.week.from_now).
      expecting_submission.due_after(opts[:due_after] || 4.weeks.ago).
      need_submitting_info(id, opts[:limit] || 15, ignored_ids).
      not_locked
  end
  memoize :assignments_needing_submitting

  def assignments_needing_submitting_total_count(opts={})
    course_codes = opts[:contexts] ? (Array(opts[:contexts]).map(&:asset_string) & current_student_enrollment_course_codes) : current_student_enrollment_course_codes
    ignored_ids = ignored_items(:submitting).select{|key, val| key.match(/\Aassignment_/) }.map{|key, val| key.sub(/\Aassignment_/, "") }
    Assignment.for_context_codes(course_codes).active.due_before(1.week.from_now).expecting_submission.due_after(4.weeks.ago).need_submitting_info(id, nil, ignored_ids).size
  end
  memoize :assignments_needing_submitting_total_count

  def assignments_needing_grading(opts={})
    course_codes = opts[:contexts] ? (Array(opts[:contexts]).map(&:asset_string) & current_admin_enrollment_course_codes) : current_admin_enrollment_course_codes
    ignored_ids = ignored_items(:grading).select{|key, val| key.match(/\Aassignment_/) }.map{|key, val| key.sub(/\Aassignment_/, "") }
    Assignment.for_context_codes(course_codes).active.expecting_submission.need_grading_info(opts[:limit] || 15, ignored_ids)
  end
  memoize :assignments_needing_grading

  def assignments_needing_grading_total_count(opts={})
    course_codes = opts[:contexts] ? (Array(opts[:contexts]).map(&:asset_string) & current_admin_enrollment_course_codes) : current_admin_enrollment_course_codes
    ignored_ids = ignored_items(:grading).select{|key, val| key.match(/\Aassignment_/) }.map{|key, val| key.sub(/\Aassignment_/, "") }
    Assignment.for_context_codes(course_codes).active.expecting_submission.need_grading_info(nil, ignored_ids).size
  end
  memoize :assignments_needing_grading_total_count

  def generate_access_verifier(ts)
    require 'openssl'
    digest = OpenSSL::Digest::MD5.new
    OpenSSL::HMAC.hexdigest(digest, uuid, ts.to_s)
  end

  private :generate_access_verifier
  def access_verifier
    ts = Time.now.utc.to_i
    [ts, generate_access_verifier(ts)]
  end

  def valid_access_verifier?(ts, sig)
    ts.to_i > 5.minutes.ago.to_i && ts.to_i < 1.minute.from_now.to_i && sig == generate_access_verifier(ts.to_i)
  end

  def uuid
    if !read_attribute(:uuid)
      self.update_attribute(:uuid, AutoHandle.generate_securish_uuid)
    end
    read_attribute(:uuid)
  end

  def self.serialization_excludes; [:uuid,:phone,:features_used]; end

  def migrate_content_links(html, from_course)
    Course.migrate_content_links(html, from_course, self)
  end

  attr_accessor :merge_mappings
  attr_accessor :merge_results
  def merge_mapped_id(*args)
    nil
  end

  def map_merge(*args)
  end
  def log_merge_result(text)
    @merge_results ||= []
    @merge_results << text
  end
  def warn_merge_result(text)
    record_merge_result(text)
  end

  def file_structure_for(user)
    User.file_structure_for(self, user)
  end

  def secondary_identifier
    self.email || self.id
  end

  def self.file_structure_for(context, user)
    res = {
      :contexts => [context],
      :collaborations => [],
      :folders => [],
      :folders_with_subcontent => [],
      :files => []
    }
    context_codes = res[:contexts].map{|c| c.asset_string }
    if !context.is_a?(User) && user
      res[:collaborations] = user.collaborations.active.find(:all, :include => [:user, :users]).select{|c| c.context_id && c.context_type && context_codes.include?("#{c.context_type.underscore}_#{c.context_id}") }
      res[:collaborations] = res[:collaborations].sort_by{|c| c.created_at}.reverse
    end
    res[:contexts].each do |context|
      res[:folders] += context.active_folders_with_sub_folders
    end
    res[:folders] = res[:folders].sort_by{|f| [f.parent_folder_id || 0, f.position || 0, f.name || "", f.created_at]}
    res
  end

  def generate_reminders_if_changed
    send_later(:generate_reminders!) if @reminder_times_changed
  end

  def generate_reminders!
    enrollments = self.current_enrollments
    mgmt_course_ids = enrollments.select{|e| e.instructor? }.map(&:course_id).uniq
    student_course_ids = enrollments.select{|e| !e.admin? }.map(&:course_id).uniq
    assignments = Assignment.for_courses(mgmt_course_ids + student_course_ids).active.due_after(Time.now)
    student_assignments = assignments.select{|a| student_course_ids.include?(a.context_id) }
    mgmt_assignments = assignments - student_assignments

    due_assignment_ids = []
    grading_assignment_ids = []
    assignment_reminders.each do |r|
      res = r.update_for(self)
      if r.reminder_type == 'grading' && res
        grading_assignment_ids << r.assignment_id
      elsif r.reminder_type == 'due_at' && res
        due_assignment_ids << r.assignment_id
      end
    end
    needed_ids = student_assignments.map(&:id) - due_assignment_ids
    student_assignments.select{|a| needed_ids.include?(a.id) }.each do |assignment|
      r = assignment_reminders.build(:user => self, :assignment => assignment, :reminder_type => 'due_at')
      r.update_for(assignment)
    end
    needed_ids = mgmt_assignments.map(&:id) - grading_assignment_ids
    mgmt_assignments.select{|a| needed_ids.include?(a.id) }.each do |assignment|
      r = assignment_reminders.build(:user => self, :assignment => assignment, :reminder_type => 'grading')
      r.update_for(assignment)
    end
    save
  end

  def self_enroll_if_necessary
    return unless @self_enrollment_course
    @self_enrollment_course.self_enroll_student(self, :skip_pseudonym => @just_created, :skip_touch_user => true)
  end

  def time_difference_from_date(hash)
    n = hash[:number].to_i
    n = nil if n == 0
    if hash[:metric] == "weeks"
      (n || 1).weeks.to_i
    elsif hash[:metric] == "days"
      (n || 1).days.to_i
    elsif hash[:metric] == "hours"
      (n || 1).hours.to_i
    elsif hash[:metric] == "never"
      0
    else
      nil
    end
  end

  def remind_for_due_dates=(hash)
    self.reminder_time_for_due_dates = time_difference_from_date(hash)
  end

  def remind_for_grading=(hash)
    self.reminder_time_for_grading = time_difference_from_date(hash)
  end

  def is_a_context?
    true
  end

  def account
    self.pseudonym.account rescue Account.default
  end
  memoize :account

  def courses_with_primary_enrollment(association = :current_and_invited_courses, enrollment_uuid = nil, options = {})
    res = Rails.cache.fetch([self, 'courses_with_primary_enrollment', association, options].cache_key, :expires_in => 15.minutes) do
      courses = send(association).distinct_on(["courses.id"],
        :select => "courses.*, enrollments.id AS primary_enrollment_id, enrollments.type AS primary_enrollment, #{Enrollment.type_rank_sql} AS primary_enrollment_rank, enrollments.workflow_state AS primary_enrollment_state",
        :order => "courses.id, #{Enrollment.type_rank_sql}, #{Enrollment.state_rank_sql}")
      unless options[:include_completed_courses]
        date_restricted = Enrollment.find(:all, :conditions => { :id => courses.map(&:primary_enrollment_id) }).select{ |e| e.completed? || e.inactive? }.map(&:id)
        courses.reject! { |course| date_restricted.include?(course.primary_enrollment_id.to_i) }
      end
      courses
    end.dup
    if association == :current_and_invited_courses
      if enrollment_uuid && pending_course = Course.find(:first,
        :select => "courses.*, enrollments.type AS primary_enrollment, #{Enrollment.type_rank_sql} AS primary_enrollment_rank, enrollments.workflow_state AS primary_enrollment_state",
        :joins => :enrollments, :conditions => ["enrollments.uuid=? AND enrollments.workflow_state='invited'", enrollment_uuid])
        res << pending_course
        res.uniq!
      end
      pending_enrollments = temporary_invitations
      unless pending_enrollments.empty?
        Enrollment.send(:preload_associations, pending_enrollments, :course)
        res.concat(pending_enrollments.map { |e| c = e.course; c.write_attribute(:primary_enrollment, e.type); c.write_attribute(:primary_enrollment_rank, e.rank_sortable.to_s); c.write_attribute(:primary_enrollment_state, e.workflow_state); c.write_attribute(:invitation, e.uuid); c })
        res.uniq!
      end
    end
    res.sort_by{ |c| [c.primary_enrollment_rank, c.name.downcase] }
  end
  memoize :courses_with_primary_enrollment

  def cached_active_emails
    Rails.cache.fetch([self, 'active_emails'].cache_key) do
      self.communication_channels.active.email.map(&:path)
    end
  end

  def temporary_invitations
    cached_active_emails.map { |email| Enrollment.cached_temporary_invitations(email).dup.reject { |e| e.user_id == self.id } }.flatten
  end

   # activesupport/lib/active_support/memoizable.rb from rails and
   # http://github.com/seamusabshere/cacheable/blob/master/lib/cacheable.rb from the cacheable gem
   # to get a head start

  # this method takes an optional {:include_enrollment_uuid => uuid}   so that you can pass it the session[:enrollment_uuid] and it will include it.
  def cached_current_enrollments(opts={})
    res = Rails.cache.fetch([self, 'current_enrollments', opts[:include_enrollment_uuid] ].cache_key) do
      res = self.current_and_invited_enrollments(true).to_a.dup
      if opts[:include_enrollment_uuid] && pending_enrollment = Enrollment.find_by_uuid_and_workflow_state(opts[:include_enrollment_uuid], "invited")
        res << pending_enrollment
        res.uniq!
      end
      res
    end + temporary_invitations
  end
  memoize :cached_current_enrollments

  def cached_not_ended_enrollments
    @cached_all_enrollments = Rails.cache.fetch([self, 'not_ended_enrollments'].cache_key) do
      self.not_ended_enrollments.to_a
    end
  end

  def cached_current_group_memberships
    @cached_current_group_memberships = Rails.cache.fetch([self, 'current_group_memberships'].cache_key) do
      self.current_group_memberships.to_a
    end
  end

  def current_student_enrollment_course_codes
    @current_student_enrollment_course_codes ||= Rails.cache.fetch([self, 'current_student_enrollment_course_codes'].cache_key) do
      self.enrollments.student.scoped(:select => "course_id").map{|e| "course_#{e.course_id}"}
    end
  end

  def current_admin_enrollment_course_codes
    @current_admin_enrollment_course_codes ||= Rails.cache.fetch([self, 'current_admin_enrollment_course_codes'].cache_key) do
      self.enrollments.admin.scoped(:select => "course_id").map{|e| "course_#{e.course_id}"}
    end
  end

  # TODO: this smells, I really don't get it (anymore... I wrote it :-( )
  def self.module_progression_job_queued(user_id, time_string=nil)
    time_string ||= Time.now.utc.iso8601
    @@user_jobs ||= {}
    @@user_jobs[user_id] ||= time_string
  end

  def self.module_progression_jobs_queued?(user_id)
    recent = 1.minute.ago.utc.iso8601
    @@user_jobs ||= {}
    !!(@@user_jobs && @@user_jobs[user_id] && @@user_jobs[user_id] > recent)
  end

  def submissions_for_context_codes(context_codes, opts={})
    return [] if (!context_codes || context_codes.empty?)
    opts[:start_at] ||= 2.weeks.ago
    opts[:limit] ||= 20

    submissions = []
    submissions += self.submissions.after(opts[:start_at]).for_context_codes(context_codes).find(
      :all,
      :conditions => ["submissions.score IS NOT NULL AND assignments.workflow_state != ? AND assignments.muted = ?", 'deleted', false],
      :include => [:assignment, :user, :submission_comments],
      :order => 'submissions.created_at DESC',
      :limit => opts[:limit]
    )

    # THIS IS SLOW, it takes ~230ms for mike
    submissions += Submission.for_context_codes(context_codes).find(
      :all,
      :select => "submissions.*, last_updated_at_from_db",
      :joins => self.class.send(:sanitize_sql_array, [<<-SQL, opts[:start_at], self.id, self.id]),
                INNER JOIN (
                  SELECT MAX(submission_comments.created_at) AS last_updated_at_from_db, submission_id
                  FROM submission_comments, submission_comment_participants
                  WHERE submission_comments.id = submission_comment_id
                    AND (submission_comments.created_at > ?)
                    AND (submission_comment_participants.user_id = ?)
                    AND (submission_comments.author_id <> ?)
                  GROUP BY submission_id
                ) AS relevant_submission_comments ON submissions.id = submission_id
                INNER JOIN assignments ON assignments.id = submissions.assignment_id AND assignments.workflow_state <> 'deleted'
                SQL
      :order => 'last_updated_at_from_db DESC',
      :limit => opts[:limit],
      :conditions => { "assignments.muted" => false }
    )

    submissions = submissions.sort_by{|t| (t.last_updated_at_from_db.to_datetime.in_time_zone rescue nil)  || t.created_at}.reverse
    submissions = submissions.uniq
    submissions.first(opts[:limit])
    submissions
  end
  memoize :submissions_for_context_codes

  # This is only feedback for student contexts (unless specific contexts are passed in)
  def recent_feedback(opts={})
    context_codes = opts[:context_codes] || (opts[:contexts] ? setup_context_lookups(opts[:contexts]) : self.current_student_enrollment_course_codes)
    submissions_for_context_codes(context_codes, opts)
  end
  memoize :recent_feedback

  def visible_stream_item_instances(opts={})
    instances = stream_item_instances.scoped(:conditions => { 'stream_item_instances.hidden' => false }, :order => 'stream_item_instances.id desc', :include => :stream_item)

    # dont make the query do an stream_item_instances.context_code IN
    # ('course_20033','course_20237','course_20247' ...) if they dont pass any
    # contexts, just assume it wants any context code.
    if opts[:contexts]
      # still need to optimize the query to use a root_context_code.  that way a
      # users course dashboard even if they have groups does a query with
      # "context_code=..." instead of "context_code IN ..."
      instances = instances.scoped(:conditions => ['stream_item_instances.context_code in (?)', setup_context_lookups(opts[:contexts])])
    end

    instances
  end

  def recent_stream_items(opts={})
    visible_stream_item_instances(opts).scoped(:include => :stream_item, :limit => 21).map(&:stream_item).compact
  end
  memoize :recent_stream_items

  def calendar_events_for_calendar(opts={})
    opts = opts.dup
    context_codes = opts[:context_codes] || (opts[:contexts] ? setup_context_lookups(opts[:contexts]) : self.cached_context_codes)
    return [] if (!context_codes || context_codes.empty?)
    opts[:start_at] ||= 2.weeks.ago
    opts[:end_at] ||= 1.weeks.from_now

    events = []
    ev = CalendarEvent
    ev = CalendarEvent.active if !opts[:include_deleted_events]
    event_codes = context_codes + AppointmentGroup.manageable_by(self, context_codes).intersecting(opts[:start_at], opts[:end_at]).map(&:asset_string)
    events += ev.for_user_and_context_codes(self, event_codes, []).between(opts[:start_at], opts[:end_at]).updated_after(opts[:updated_at])
    events += Assignment.active.for_context_codes(context_codes).due_between(opts[:start_at], opts[:end_at]).updated_after(opts[:updated_at]).with_just_calendar_attributes
    events.sort_by{|e| [e.start_at, e.title || ""] }.uniq
  end

  def upcoming_events(opts={})
    context_codes = opts[:context_codes] || (opts[:contexts] ? setup_context_lookups(opts[:contexts]) : self.cached_context_codes)
    return [] if (!context_codes || context_codes.empty?)

    opts[:end_at] ||= 1.weeks.from_now
    opts[:limit] ||= 20

    events = CalendarEvent.active.for_user_and_context_codes(self, context_codes).between(Time.now.utc, opts[:end_at]).scoped(:limit => opts[:limit]).reject(&:hidden?)
    events += Assignment.active.for_context_codes(context_codes).due_between(Time.now.utc, opts[:end_at]).scoped(:limit => opts[:limit]).include_submitted_count
    appointment_groups = AppointmentGroup.manageable_by(self, context_codes).intersecting(Time.now.utc, opts[:end_at]).scoped(:limit => opts[:limit])
    appointment_groups.each { |ag| ag.context = ag.contexts_for_user(self).first }
    events += appointment_groups
    events.sort_by{|e| [e.start_at, e.title] }.uniq.first(opts[:limit])
  end

  def undated_events(opts={})
    opts = opts.dup
    context_codes = opts[:context_codes] || (opts[:contexts] ? setup_context_lookups(opts[:contexts]) : self.cached_context_codes)
    return [] if (!context_codes || context_codes.empty?)

    undated_events = []
    undated_events += CalendarEvent.active.for_user_and_context_codes(self, context_codes, []).undated.updated_after(opts[:updated_at])
    undated_events += Assignment.active.for_context_codes(context_codes).undated.updated_after(opts[:updated_at]).with_just_calendar_attributes
    undated_events.sort_by{|e| e.title }
  end

  def setup_context_lookups(contexts=nil)
    # TODO: All the event methods use this and it's really slow.
    Array(contexts || cached_contexts).map(&:asset_string)
  end
  memoize :setup_context_lookups

  # TODO: doesn't actually cache, needs to be optimized
  def cached_contexts
    @cached_contexts ||= begin
      context_groups = []
      # according to the set_policy block in group.rb, user u can manage group
      # g if either:
      # (a) g.context.grants_right?(u, :manage_groups)
      # (b) g.has_member?(u)
      # this is a very performance sensitive method, so we're bypassing the
      # normal policy checking and somewhat duplicating auth logic here. which
      # is a shame. it'd be really nice to add support to our policy framework
      # for understanding how to load associations based on policies.
      self.courses.all(:include => :active_groups).select { |c| c.grants_right?(self, :manage_groups) }.each { |c| context_groups += c.active_groups }
      self.courses + (self.groups.active + context_groups).uniq
    end
  end

  # TODO: doesn't actually cache, needs to be optimized
  def cached_context_codes
    Array(self.cached_contexts).map(&:asset_string)
  end

  # context codes of things that might have a schedulable appointment for the
  # given user, i.e. courses and sections
  def appointment_context_codes
    ret = {:primary => [], :secondary => []}
    cached_current_enrollments.each do |e|
      next unless e.student? && e.active?
      ret[:primary] << "course_#{e.course_id}"
      ret[:secondary] << "course_section_#{e.course_section_id}"
    end
    ret[:secondary].concat groups.map{ |g| "group_category_#{g.group_category_id}" }
    ret
  end
  memoize :appointment_context_codes

  def manageable_appointment_context_codes
    ret = {:full => [], :limited => [], :secondary => []}
    cached_current_enrollments.each do |e|
      next unless e.course.grants_right?(self, nil, :manage_calendar)
      if e.course.visibility_limited_to_course_sections?(self)
        ret[:limited] << "course_#{e.course_id}"
        ret[:secondary] << "course_section_#{e.course_section_id}"
      else
        ret[:full] << "course_#{e.course_id}"
      end
    end
    ret
  end
  memoize :manageable_appointment_context_codes

  def conversation_context_codes
    Rails.cache.fetch([self, 'conversation_context_codes2'].cache_key, :expires_in => 1.day) do
      ( courses.map{ |c| "course_#{c.id}" } +
        concluded_courses.map{ |c| "course_#{c.id}" } +
        current_groups.map{ |g| "group_#{g.id}"}
      ).uniq
    end
  end
  memoize :conversation_context_codes

  def section_context_codes(context_codes)
    course_ids = context_codes.grep(/\Acourse_\d+\z/).map{ |s| s.sub(/\Acourse_/, '').to_i }
    return [] unless course_ids.present?
    Course.find_all_by_id(course_ids).inject([]) do |ary, course|
      ary.concat course.sections_visible_to(self).map(&:asset_string)
    end
  end

  def manageable_courses(include_concluded = false)
    Course.manageable_by_user(self.id, include_concluded).not_deleted
  end

  def manageable_courses_name_like(query = '', include_concluded = false)
    self.manageable_courses(include_concluded).not_deleted.name_like(query).limit(50)
  end

  def last_completed_module
    self.context_module_progressions.select{|p| p.completed? }.sort_by{|p| p.completed_at || p.created_at }.last.context_module rescue nil
  end

  def last_completed_course
    self.enrollments.select{|e| e.completed? }.sort_by{|e| e.completed_at || e.created_at }.last.course rescue nil
  end

  def last_mastered_assignment
    self.learning_outcome_results.sort_by{|r| r.assessed_at || r.created_at }.select{|r| r.mastery? }.map{|r| r.assignment }.last
  end

  def profile_pics_folder
    initialize_default_folder(Folder::PROFILE_PICS_FOLDER_NAME)
  end

  def conversation_attachments_folder
    initialize_default_folder(Folder::CONVERSATION_ATTACHMENTS_FOLDER_NAME)
  end

  def initialize_default_folder(name)
    folder = self.active_folders.find_by_name(name)
    unless folder
      folder = self.folders.create!(:name => name,
        :parent_folder => Folder.root_folders(self).find {|f| f.name == Folder::MY_FILES_FOLDER_NAME })
    end
    folder
  end

  def quota
    return read_attribute(:storage_quota) if read_attribute(:storage_quota)
    accounts = associated_root_accounts.reject(&:site_admin?)
    accounts.empty? ?
      self.class.default_storage_quota :
      accounts.sum(&:default_user_storage_quota)
  end
  
  def self.default_storage_quota
    Setting.get_cached('user_default_quota', 50.megabytes.to_s).to_i
  end

  def update_last_user_note
    note = user_notes.active.scoped(:order => 'user_notes.created_at DESC', :limit=>1).first
    self.last_user_note = note ? note.created_at : nil
  end

  TAB_PROFILE = 0
  TAB_COMMUNICATION_PREFERENCES = 1
  TAB_FILES = 2
  TAB_EPORTFOLIOS = 3
  TAB_HOME = 4

  def sis_user_id
    pseudonym.try(:sis_user_id)
  end

  def highest_role
    return 'admin' unless self.accounts.empty?
    return 'teacher' if self.cached_current_enrollments.any?(&:admin?)
    return 'student' if self.cached_current_enrollments.any?(&:student?)
    return 'user'
  end
  memoize :highest_role

  def roles
    res = ['user']
    res << 'student' if self.cached_current_enrollments.any?(&:student?)
    res << 'teacher' if self.cached_current_enrollments.any?(&:admin?)
    res << 'admin' unless self.accounts.empty?
    res
  end
  memoize :roles

  def eportfolios_enabled?
    accounts = associated_root_accounts.reject(&:site_admin?)
    accounts.size == 0 || accounts.any?{ |a| a.settings[:enable_eportfolios] != false }
  end

  def initiate_conversation(user_ids, private = nil)
    user_ids = ([self.id] + user_ids).uniq
    private = user_ids.size <= 2 if private.nil?
    Conversation.initiate(user_ids, private).conversation_participants.find_by_user_id(self.id)
  end

  def messageable_user_clause
    "users.workflow_state IN ('registered', 'pre_registered')"
  end

  def messageable_enrollment_user_clause
    "EXISTS (SELECT 1 FROM users WHERE id = enrollments.user_id AND #{messageable_user_clause})"
  end

  def messageable_enrollment_clause(include_concluded_students=false)
    <<-SQL
    (
      #{self.class.reflections[:current_and_invited_enrollments].options[:conditions]}
      OR
      #{self.class.reflections[:concluded_enrollments].options[:conditions]}
      #{include_concluded_students ? "" : "AND enrollments.type IN ('TeacherEnrollment', 'TaEnrollment')"}
    )
    SQL
  end

  def enrollment_visibility
    Rails.cache.fetch([self, 'enrollment_visibility_with_sections_2'].cache_key, :expires_in => 1.day) do
      full_course_ids = []
      section_id_hash = {}
      restricted_course_hash = {}
      user_counts = {}
      section_user_counts = {}
      student_in_course_ids = []
      linked_observer_ids = observee_enrollments.collect {|e| e.user_id}.uniq
      courses_with_primary_enrollment(:current_and_concluded_courses, nil, :include_completed_courses => true).each do |course|
        section_visibilities = course.section_visibilities_for(self)
        conditions = nil
        case course.enrollment_visibility_level_for(self, section_visibilities)
          when :full
            full_course_ids << course.id
          when :sections
            section_id_hash[course.id] = section_visibilities.map{|s| s[:course_section_id]}
            conditions = {:course_section_id => section_id_hash[course.id]}
          when :restricted
            section_visibilities.each do |s|
              restricted_course_hash[course.id] ||= []
              restricted_course_hash[course.id] << s[:associated_user_id] if s[:associated_user_id]
            end
            conditions = "enrollments.type = 'TeacherEnrollment' OR enrollments.type = 'TaEnrollment' OR enrollments.user_id IN (#{([self.id] + restricted_course_hash[course.id].uniq).join(',')})"
        end
        base_conditions = messageable_enrollment_clause
        base_conditions << " AND " << messageable_enrollment_user_clause
        if course.primary_enrollment == 'StudentEnrollment'
          student_in_course_ids << course.id
          base_conditions << " AND (enrollments.type != 'ObserverEnrollment'"
          base_conditions << "  OR enrollments.user_id IN (#{linked_observer_ids.join(',')})" if linked_observer_ids.any?
          base_conditions << ")"
        end
        user_counts[course.id] = course.enrollments.scoped(:conditions => base_conditions).scoped(:conditions => conditions).scoped(:conditions => "enrollments.type != 'StudentViewEnrollment'").count("DISTINCT user_id")

        sections = course.sections_visible_to(self)
        if sections.size > 1
          sections.each{ |section| section_user_counts[section.id] = 0 }
          connection.select_all("SELECT course_section_id, COUNT(DISTINCT user_id) AS user_count FROM courses, enrollments WHERE (#{base_conditions}) AND course_section_id IN (#{sections.map(&:id).join(', ')}) AND courses.id = #{course.id} AND enrollments.type != 'StudentViewEnrollment' GROUP BY course_section_id").each do |row|
            section_user_counts[row["course_section_id"].to_i] = row["user_count"].to_i
          end
        end
      end
      {:full_course_ids => full_course_ids,
       :section_id_hash => section_id_hash,
       :restricted_course_hash => restricted_course_hash,
       :user_counts => user_counts,
       :section_user_counts => section_user_counts,
       :student_in_course_ids => student_in_course_ids,
       :linked_observer_ids => linked_observer_ids
      }
    end
  end
  memoize :enrollment_visibility

  def messageable_groups
    group_visibility = group_membership_visibility
    Group.scoped(:conditions => {:id => visible_group_ids.reject{ |id| group_visibility[:user_counts][id] == 0 } + [0]})
  end

  def visible_group_ids
    Rails.cache.fetch([self, 'messageable_groups'].cache_key, :expires_in => 1.day) do
      (courses + concluded_courses.recently_ended).inject(self.current_groups) { |groups, course|
        groups | course.groups.active
      }.map(&:id)
    end
  end
  memoize :visible_group_ids

  def group_membership_visibility
    Rails.cache.fetch([self, 'group_membership_visibility'].cache_key, :expires_in => 1.day) do
      course_visibility = enrollment_visibility
      own_group_ids = current_groups.map(&:id)

      full_group_ids = []
      section_id_hash = {}
      user_counts = {}

      if visible_group_ids.present?
        Group.find_all_by_id(visible_group_ids).each do |group|
          if own_group_ids.include?(group.id) || group.context_type == 'Course' && course_visibility[:full_course_ids].include?(group.context_id)
            full_group_ids << group.id
            user_counts[group.id] = group.users.size
          elsif group.context_type == 'Course' && sections = course_visibility[:section_id_hash][group.context_id]
            section_id_hash[group.id] = sections
            user_counts[group.id] = group.context.enrollments.scoped(:conditions => [
              "user_id IN (?) AND course_section_id IN (?) AND #{messageable_enrollment_user_clause} AND #{messageable_enrollment_clause(true)}",
              group.group_memberships.map(&:user_id),
              sections
            ]).size
          end
        end
      end
      {:full_group_ids => full_group_ids,
       :section_id_hash => section_id_hash,
       :user_counts => user_counts
      }
    end
  end
  memoize :group_membership_visibility

  MESSAGEABLE_USER_COLUMNS = ['id', 'short_name', 'name', 'avatar_image_url', 'avatar_image_source'].map{|col|"users.#{col}"}
  MESSAGEABLE_USER_COLUMN_SQL = MESSAGEABLE_USER_COLUMNS.join(", ")
  MESSAGEABLE_USER_CONTEXT_REGEX = /\A(course|section|group)_(\d+)(_([a-z]+))?\z/
  def messageable_users(options = {})
    # if :ids is specified but empty (different than just not specified), don't
    # bother doing a query that's guaranteed to return no results.
    return [] if options[:ids] && options[:ids].empty?

    course_hash = enrollment_visibility
    full_course_ids = course_hash[:full_course_ids]
    restricted_course_hash = course_hash[:restricted_course_hash]

    group_hash = group_membership_visibility
    full_group_ids = group_hash[:full_group_ids]
    group_section_ids = []
    student_in_course_ids = course_hash[:student_in_course_ids]
    linked_observer_ids = course_hash[:linked_observer_ids]
    account_ids = []

    limited_id = {}
    enrollment_type_sql = " AND enrollments.type != 'StudentViewEnrollment'"
    if student_in_course_ids.present?
      enrollment_type_sql += " AND (enrollments.type != 'ObserverEnrollment' OR course_id NOT IN (#{student_in_course_ids.join(',')})"
      enrollment_type_sql += "  OR user_id IN (#{linked_observer_ids.join(',')})" if linked_observer_ids.present?
      enrollment_type_sql += ")"
    end
    
    include_concluded_students = true

    if options[:context]
      if options[:context].sub(/_all\z/, '') =~ MESSAGEABLE_USER_CONTEXT_REGEX
        type = $1
        include_concluded_students = false unless type == 'group'
        limited_id[type] = $2.to_i
        enrollment_type = $4
        if enrollment_type && type != 'group' # course and section only, since the only group "enrollment type" is member
          if enrollment_type == 'admins'
            enrollment_type_sql += " AND enrollments.type IN ('TeacherEnrollment','TaEnrollment')"
          else
            enrollment_type_sql += " AND enrollments.type = '#{enrollment_type.capitalize.singularize}Enrollment'"
          end
        end
      end
      full_course_ids &= [limited_id['course']]
      full_group_ids &= [limited_id['group']]
      restricted_course_hash.delete_if{ |course_id, ids| course_id != limited_id['course']}
      if limited_id['section'] && section = CourseSection.find_by_id(limited_id['section'])
        course_section_ids = course_hash[:full_course_ids].include?(section.course_id) ?
          [limited_id['section']] :
          (course_hash[:section_id_hash][section.course_id] || []) & [limited_id['section']]
      else
        course_section_ids = course_hash[:section_id_hash].values_at(limited_id['course']).flatten.compact
        group_section_ids = group_hash[:section_id_hash].values_at(limited_id['group']).flatten.compact
      end
    else
      course_section_ids = course_hash[:section_id_hash].values.flatten
      # if we're not searching with a context in mind, include any users we
      # have admin access to know about
      account_ids = associated_accounts.select{ |a| a.grants_right?(self, nil, :read_roster) }.map(&:id)
      account_ids &= options[:account_ids] if options[:account_ids]
    end

    user_conditions = []
    user_conditions << messageable_user_clause unless options[:skip_visibility_checks] && options[:ids]
    user_conditions << "users.id IN (#{options[:ids].map(&:to_i).join(', ')})" if options[:ids].present?
    user_conditions << "users.id NOT IN (#{options[:exclude_ids].map(&:to_i).join(', ')})" if options[:exclude_ids].present?
    if options[:search] && (parts = options[:search].strip.split(/\s+/)).present?
      parts.each do |part|
        user_conditions << "(#{wildcard('users.name', 'users.short_name', part)})"
      end
    end
    user_condition_sql = user_conditions.present? ? "AND " + user_conditions.join(" AND ") : ""
    user_sql = []

    # this is redundant (and potentially less restrictive than course_sql),
    # but it allows the planner to initially limit enrollments to relevant
    # courses much more efficiently than the OR'ed course_sql does
    all_course_ids = (course_hash[:full_course_ids] + course_hash[:section_id_hash].keys + restricted_course_hash.keys).compact

    course_sql = []
    course_sql << "(course_id IN (#{full_course_ids.join(',')}))" if full_course_ids.present?
    course_sql << "(course_section_id IN (#{course_section_ids.join(',')}))" if course_section_ids.present?
    course_sql << "(course_section_id IN (#{group_section_ids.join(',')}) AND EXISTS(SELECT 1 FROM group_memberships WHERE user_id = users.id AND group_id = #{limited_id['group']}) )" if limited_id['group'] && group_section_ids.present?
    course_sql << "(course_id IN (#{restricted_course_hash.keys.join(',')}) AND (enrollments.type = 'TeacherEnrollment' OR enrollments.type = 'TaEnrollment' OR enrollments.user_id IN (#{([self.id] + restricted_course_hash.values.flatten.uniq).join(',')})))" if restricted_course_hash.present?
    user_sql << <<-SQL if course_sql.present?
      SELECT #{MESSAGEABLE_USER_COLUMN_SQL}, course_id, NULL AS group_id, #{connection.func(:group_concat, :'enrollments.type', ':')} AS roles
      FROM users, enrollments, courses
      WHERE course_id IN (#{all_course_ids.join(', ')})
        AND (#{course_sql.join(' OR ')}) AND users.id = user_id AND courses.id = course_id
        AND #{messageable_enrollment_clause(include_concluded_students)}
        #{enrollment_type_sql}
        #{user_condition_sql}
      GROUP BY #{connection.group_by(['users.id', 'course_id'], *(MESSAGEABLE_USER_COLUMNS[1, MESSAGEABLE_USER_COLUMNS.size]))}
    SQL

    user_sql << <<-SQL if full_group_ids.present?
      SELECT #{MESSAGEABLE_USER_COLUMN_SQL}, NULL AS course_id, group_id, NULL AS roles
      FROM users, group_memberships
      WHERE group_id IN (#{full_group_ids.join(',')}) AND users.id = user_id
        AND group_memberships.workflow_state = 'accepted'
        #{user_condition_sql}
    SQL

    # if this is an account admin who doesn't have any courses/groups in common
    # with the user, we want to know the user's highest current enrollment type
    highest_enrollment_sql = <<-SQL
      SELECT type
      FROM enrollments, courses
      WHERE
        user_id = users.id AND courses.id = course_id
        AND (#{self.class.reflections[:current_and_invited_enrollments].options[:conditions]})
      ORDER BY #{Enrollment.type_rank_sql}
      LIMIT 1
    SQL
    user_sql << <<-SQL if account_ids.present?
      SELECT #{MESSAGEABLE_USER_COLUMN_SQL}, 0 AS course_id, NULL AS group_id, (#{highest_enrollment_sql}) AS roles
      FROM users, user_account_associations
      WHERE user_account_associations.account_id IN (#{account_ids.join(',')})
        AND user_account_associations.user_id = users.id
        #{user_condition_sql}
    SQL

    if options[:ids]
      # provides a way for this user to start a conversation with someone
      # that isn't normally messageable (requires that they already be in a
      # conversation with that user)
      if options[:conversation_id].present?
        user_sql << <<-SQL
          SELECT #{MESSAGEABLE_USER_COLUMN_SQL}, NULL AS course_id, NULL AS group_id, NULL AS roles
          FROM users, conversation_participants
          WHERE conversation_participants.user_id = users.id
            AND conversation_participants.conversation_id = #{options[:conversation_id].to_i}
            #{user_condition_sql}
        SQL
      elsif options[:skip_visibility_checks] # we don't care about the contexts, we've passed in ids
        user_sql << <<-SQL
          SELECT #{MESSAGEABLE_USER_COLUMN_SQL}, NULL AS course_id, NULL AS group_id, NULL AS roles
          FROM users
          #{user_condition_sql.sub(/\AAND/, "WHERE")}
        SQL
      end
    end

    # if none of our potential sources was included, we're done
    return [] if user_sql.empty?

    concat_sql = connection.adapter_name =~ /postgres/i ? :"course_id::text || ':' || roles::text" : :"course_id || ':' || roles"

    users = User.find_by_sql(<<-SQL)
      SELECT #{MESSAGEABLE_USER_COLUMN_SQL},
        #{connection.func(:group_concat, concat_sql)} AS common_courses,
        #{connection.func(:group_concat, :group_id)} AS common_groups
      FROM (
        #{user_sql.join(' UNION ')}
      ) users
      GROUP BY #{connection.group_by(*MESSAGEABLE_USER_COLUMNS)}
      ORDER BY #{options[:rank_results] ? "(COUNT(course_id) + COUNT(group_id)) DESC," : ""}
        LOWER(COALESCE(short_name, name)),
        id
      #{options[:limit] && options[:limit] > 0 ? "LIMIT #{options[:limit].to_i}" : ""}
      #{options[:offset] && options[:offset] > 0 ? "OFFSET #{options[:offset].to_i}" : ""}
    SQL
    users.each do |user|
      user.common_courses = user.common_courses.to_s.split(",").inject({}){ |hash, info|
        roles = info.split(/:/)
        hash[roles.shift.to_i] = roles
        hash
      }
      user.common_groups = user.common_groups.to_s.split(",").inject({}){ |hash, info|
        roles = info.split(/:/)
        hash[roles.shift.to_i] = ['Member']
        hash
      }
    end
  end

  def short_name_with_shared_contexts(user)
    if (contexts = shared_contexts(user)).present?
      "#{short_name} (#{contexts[0, 2].to_sentence})"
    else
      short_name
    end
  end

  def shared_contexts(user)
    contexts = []
    if info = messageable_users(:ids => [user.id]).first
      contexts += Course.find(:all, :conditions => {:id => info.common_courses.keys}) if info.common_courses.present?
      contexts += Group.find(:all, :conditions => {:id => info.common_groups.keys}) if info.common_groups.present?
    end
    contexts.map(&:name).sort_by{|c|c.downcase}
  end

  def mark_all_conversations_as_read!
    conversations.unread.update_all(:workflow_state => 'read')
    User.update_all 'unread_conversations_count = 0', :id => id
  end

  def conversation_participant(conversation_id)
    all_conversations.find_by_conversation_id(conversation_id)
  end

  # association with dynamic, filtered join condition for submissions.
  # This is messy, but in ActiveRecord 2 this is the only way to do an eager
  # loading :include condition that has dynamic join conditions. It looks like
  # there's better solutions in AR 3.
  # See also e.g., http://makandra.com/notes/983-dynamic-conditions-for-belongs_to-has_many-and-has_one-associations
  has_many :submissions_for_given_assignments, :include => [:assignment, :submission_comments], :conditions => 'submissions.assignment_id IN (#{Api.assignment_ids_for_students_api.join(",")})', :class_name => 'Submission'

  def set_menu_data(enrollment_uuid)
    return @menu_data if @menu_data
    coalesced_enrollments = []

    cached_enrollments = self.cached_current_enrollments(:include_enrollment_uuid => enrollment_uuid)
    cached_enrollments.each do |e|

      next if e.state_based_on_date == :inactive

      if e.state_based_on_date == :completed
        has_completed_enrollment = true
        next
      end

      if !e.course
        coalesced_enrollments << {
          :enrollment => e,
          :sortable => [e.rank_sortable, e.state_sortable, e.long_name],
          :types => [ e.readable_type ]
        }
      end

      existing_enrollment_info = coalesced_enrollments.find { |en|
        # coalesce together enrollments for the same course and the same state
        !e.course.nil? && en[:enrollment].course == e.course && en[:enrollment].workflow_state == e.workflow_state
      }

      if existing_enrollment_info
        existing_enrollment_info[:types] << e.readable_type
        existing_enrollment_info[:sortable] = [existing_enrollment_info[:sortable] || [999,999, 999], [e.rank_sortable, e.state_sortable, 0 - e.id]].min
      else
        coalesced_enrollments << { :enrollment => e, :sortable => [e.rank_sortable, e.state_sortable, 0 - e.id], :types => [ e.readable_type ] }
      end
    end
    coalesced_enrollments = coalesced_enrollments.sort_by{|e| e[:sortable] || [999,999, 999] }
    active_enrollments = coalesced_enrollments.map{ |e| e[:enrollment] }

    cached_group_memberships = self.cached_current_group_memberships
    coalesced_group_memberships = cached_group_memberships.
      select{ |gm| gm.active_given_enrollments?(active_enrollments) }.
      sort_by{ |gm| gm.group.name }

    @menu_data = {
      :group_memberships => coalesced_group_memberships,
      :group_memberships_count => cached_group_memberships.length,
      :accounts => self.accounts,
      :accounts_count => self.accounts.length,
    }
  end

  def menu_courses(enrollment_uuid = nil)
    return @menu_courses if @menu_courses
    favorites = self.courses_with_primary_enrollment(:favorite_courses, enrollment_uuid)
    return (@menu_courses = favorites) if favorites.length > 0
    @menu_courses = self.courses_with_primary_enrollment(:current_and_invited_courses, enrollment_uuid).first(12)
  end

  def user_can_edit_name?
    associated_root_accounts.any? { |a| a.settings[:users_can_edit_name] != false } || associated_root_accounts.empty?
  end

  def sections_for_course(course)
    course.student_enrollments.active.for_user(self).map { |e| e.course_section }
  end

  def can_create_enrollment_for?(course, session, type)
    can_add = %w{StudentEnrollment ObserverEnrollment}.include?(type) && course.grants_right?(self, session, :manage_students)
    can_add ||= type == 'TeacherEnrollment' && course.teacherless? && course.grants_right?(self, session, :manage_students)
    can_add ||= course.grants_right?(self, session, :manage_admin_users)

    can_add
  end

  def group_member_json(context)
    h = { :user_id => self.id, :name => self.last_name_first, :display_name => self.short_name }
    if context && context.is_a?(Course)
      self.sections_for_course(context).each do |section|
        h[:sections] ||= []
        h[:sections] << { :section_id => section.id, :section_code => section.section_code }
      end
    end
    h
  end

  def find_pseudonym_for_account(account, allow_implicit = false)
    self.pseudonyms.detect { |p| p.active? && p.works_for_account?(account, allow_implicit) }
  end

  # account = the account that you want a pseudonym for
  # preferred_template_account = pass in an actual account if you have a preference for which account the new pseudonym gets copied from
  # this may not be able to find a suitable pseudonym to copy, so would still return nil
  # if a pseudonym is created, it is *not* saved, and *not* added to the pseudonyms collection
  def find_or_initialize_pseudonym_for_account(account, preferred_template_account = nil)
    pseudonym = find_pseudonym_for_account(account)
    if !pseudonym
      # list of copyable pseudonyms
      active_pseudonyms = self.pseudonyms.select { |p| p.active? && !p.password_auto_generated? && !p.account.delegated_authentication? }
      templates = []
      # re-arrange in the order we prefer
      templates.concat active_pseudonyms.select { |p| p.account_id == preferred_template_account.id } if preferred_template_account
      templates.concat active_pseudonyms.select { |p| p.account_id == Account.site_admin.id }
      templates.concat active_pseudonyms.select { |p| p.account_id == Account.default.id }
      templates.concat active_pseudonyms
      templates.uniq!

      template = templates.detect { |template| !account.pseudonyms.custom_find_by_unique_id(template.unique_id) }
      if template
        # creating this not attached to the user's pseudonyms is intentional
        pseudonym = account.pseudonyms.build
        pseudonym.user = self
        pseudonym.unique_id = template.unique_id
        pseudonym.password_salt = template.password_salt
        pseudonym.crypted_password = template.crypted_password
      end
    end
    pseudonym
  end

  # Public: Add this user as an admin in the given account.
  #
  # account - The account model to create the admin in.
  # role - String name of the role to add the user to. If nil,
  #        'AccountAdmin' will be used (default: nil).
  # send_notification - If set to false, do not send any email
  #                     notifications (default: true).
  #
  # Returns an AccountUser model object.
  def flag_as_admin(account, role=nil, send_notification = true)
    admin = account.add_user(self, role)

    return admin unless send_notification

    if self.registered?
      admin.account_user_notification!
    else
      admin.account_user_registration!
    end
    admin
  end

  def fake_student?
    self.preferences[:fake_student] && !!self.enrollments.find(:first, :conditions => {:type => "StudentViewEnrollment"})
  end

  def private?
    not public?
  end

  def default_collection_name
    t :default_collection_name, "%{user_name}'s Collection", :user_name => self.short_name
  end
end
