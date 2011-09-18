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

class User < ActiveRecord::Base
  include Context

  attr_accessible :name, :short_name, :time_zone, :show_user_services, :gender, :visible_inbox_types, :avatar_image, :subscribe_to_emails, :locale
  attr_accessor :original_id
  
  before_save :infer_defaults
  serialize :preferences
  include Workflow

  has_many :communication_channels, :order => 'position', :dependent => :destroy
  has_one :communication_channel, :order => 'position'
  has_many :enrollments, :dependent => :destroy
  
  has_many :current_enrollments, :class_name => 'Enrollment', :include => [:course, :course_section], :conditions => "enrollments.workflow_state = 'active' and ((courses.workflow_state = 'claimed' and (enrollments.type = 'TeacherEnrollment' or enrollments.type = 'TaEnrollment')) or (enrollments.workflow_state = 'active' and courses.workflow_state = 'available'))", :order => 'enrollments.created_at'
  has_many :invited_enrollments, :class_name => 'Enrollment', :include => [:course, :course_section], :conditions => "enrollments.workflow_state = 'invited' and ((courses.workflow_state = 'available' and (enrollments.type = 'StudentEnrollment'or enrollments.type = 'ObserverEnrollment')) or (courses.workflow_state != 'deleted' and (enrollments.type = 'TeacherEnrollment' or enrollments.type = 'TaEnrollment')))", :order => 'enrollments.created_at'
  has_many :current_and_invited_enrollments, :class_name => 'Enrollment', :include => [:course], :order => 'enrollments.created_at', 
           :conditions => "( enrollments.workflow_state = 'active' and ((courses.workflow_state = 'claimed' and (enrollments.type = 'TeacherEnrollment' or enrollments.type = 'TaEnrollment')) or (enrollments.workflow_state = 'active' and courses.workflow_state = 'available')) )
                           OR 
                           ( enrollments.workflow_state = 'invited' and ((courses.workflow_state = 'available' and (enrollments.type = 'StudentEnrollment'or enrollments.type = 'ObserverEnrollment')) or (courses.workflow_state != 'deleted' and (enrollments.type = 'TeacherEnrollment' or enrollments.type = 'TaEnrollment'))) )" 
  has_many :not_ended_enrollments, :class_name => 'Enrollment', :conditions => ["enrollments.workflow_state NOT IN (?)", ['rejected', 'completed', 'deleted']]  
  has_many :concluded_enrollments, :class_name => 'Enrollment', :include => [:course, :course_section], :conditions => "enrollments.workflow_state = 'completed'", :order => 'enrollments.created_at'
  has_many :courses, :through => :current_enrollments
  has_many :concluded_courses, :source => :course, :through => :concluded_enrollments
  has_many :all_courses, :source => :course, :through => :enrollments  
  has_many :group_memberships, :include => :group, :dependent => :destroy
  has_many :groups, :through => :group_memberships
  has_many :current_group_memberships, :include => :group, :class_name => 'GroupMembership', :conditions => "group_memberships.workflow_state = 'accepted'"
  has_many :current_groups, :through => :current_group_memberships, :source => :group, :conditions => "groups.workflow_state != 'deleted'"
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
  has_many :tags, :class_name => 'ContentTag', :as => 'context', :order => 'LOWER(title)', :dependent => :destroy
  has_many :attachments, :as => 'context', :dependent => :destroy
  has_many :active_attachments, :as => :context, :class_name => 'Attachment', :conditions => ['attachments.file_state != ?', 'deleted']
  has_many :active_images, :as => :context, :class_name => 'Attachment', :conditions => ["attachments.file_state != ? AND attachments.content_type LIKE 'image%'", 'deleted'], :order => 'attachments.display_name', :include => :thumbnail
  has_many :active_assignments, :as => :context, :class_name => 'Assignment', :conditions => ['assignments.workflow_state != ?', 'deleted']
  has_many :all_attachments, :as => 'context', :class_name => 'Attachment'
  has_many :folders, :as => 'context', :order => 'folders.name'
  has_many :active_folders, :class_name => 'Folder', :as => :context, :conditions => ['folders.workflow_state != ?', 'deleted'], :order => 'folders.name'
  has_many :active_folders_with_sub_folders, :class_name => 'Folder', :as => :context, :include => [:active_sub_folders], :conditions => ['folders.workflow_state != ?', 'deleted'], :order => 'folders.name'
  has_many :active_folders_detailed, :class_name => 'Folder', :as => :context, :include => [:active_sub_folders, :active_file_attachments], :conditions => ['folders.workflow_state != ?', 'deleted'], :order => 'folders.name'
  has_many :calendar_events, :as => 'context', :dependent => :destroy
  has_many :eportfolios, :dependent => :destroy
  has_many :notifications, :through => :notification_policies
  has_many :quiz_submissions, :dependent => :destroy
  has_many :dashboard_messages, :class_name => 'Message', :conditions => {:to => "dashboard", :workflow_state => 'dashboard'}, :order => 'created_at DESC', :dependent => :destroy
  has_many :notification_policies, :include => :communication_channel, :dependent => :destroy
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
  has_many :stream_items, :through => :stream_item_instances
  has_many :all_conversations, :class_name => 'ConversationParticipant', :include => :conversation, :order => "last_message_at DESC, conversation_id DESC"
  def conversations
    all_conversations.visible # i.e. exclude any where the user has deleted all the messages
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
  named_scope :for_course_section, lambda{|sections|
    section_ids = Array(sections).map{|s| s.is_a?(Fixnum) ? s : s.id }
    {:conditions => "enrollments.limit_priveleges_to_course_section IS NULL OR enrollments.limit_priveleges_to_course_section != #{User.connection.quoted_true} OR enrollments.course_section_id IN (#{section_ids.join(",")})" }
  }
  named_scope :name_like, lambda { |name|
    { :conditions => ["(", wildcard('users.name', 'users.short_name', name), " OR exists (select 1 from pseudonyms where ", wildcard('pseudonyms.sis_user_id', 'pseudonyms.unique_id', name), " and pseudonyms.user_id = users.id and (", User.send(:sanitize_sql_array, Pseudonym.active.proxy_options[:conditions]), ")))"].join }
  }
  named_scope :active, lambda {
    { :conditions => ["users.workflow_state != ?", 'deleted'] }
  }
  
  named_scope :has_current_student_enrollments, :conditions =>  "EXISTS (SELECT * FROM enrollments JOIN courses ON courses.id = enrollments.course_id AND courses.workflow_state = 'available' WHERE enrollments.user_id = users.id AND enrollments.workflow_state IN ('active','invited') AND enrollments.type = 'StudentEnrollment')"
  
  named_scope :order_by_sortable_name, :order => 'sortable_name ASC'
  
  named_scope :enrolled_in_course_between, lambda{|course_ids, start_at, end_at| 
    ids_string = course_ids.join(",")
    {
      :joins => :enrollments,
      :conditions => ["enrollments.course_id in (#{ids_string}) AND enrollments.created_at > ? AND enrollments.created_at < ?", start_at, end_at]
    }
  }
  
  # scopes to the most active users across the system
  named_scope :most_active, lambda { |*args|
    { 
      :joins => [:page_views],
      :order => "users.page_views_count DESC",
      :limit => (args.first || 10)
    }
  }
  
  # scopes to the most active users (by page view count) in a context:
  # User.x_most_active_in_context(30, Course.find(112)) # will give you the 30 most active users in course 112
  named_scope :x_most_active_in_context, lambda { |*args|
    {
      :select => "users.*, (SELECT COUNT(*) FROM page_views WHERE user_id = users.id AND context_id = #{args.last.id} AND context_type = '#{args.last.class.to_s}') AS page_views_count",
      :order => "page_views_count DESC",
      :limit => (args.first || 10),
    }
  }

  has_a_broadcast_policy

  validates_length_of :name, :maximum => maximum_string_length, :allow_nil => true
  validates_locale :locale, :browser_locale, :allow_nil => true

  before_save :assign_uuid
  before_save :update_avatar_image
  after_save :generate_reminders_if_changed
  
  def page_views_by_day(options={})
    conditions = {}
    if options[:dates]
      conditions.merge!({
        :created_at, (options[:dates].first)..(options[:dates].last)
      })
    end
    page_views_as_hash = {}
    self.page_views.count(
      :group => "date(created_at)", 
      :order => "date(created_at)",
      :conditions => conditions
    ).each do |day|
      page_views_as_hash[day.first] = day.last
    end
    page_views_as_hash
  end
  memoize :page_views_by_day
  
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
  
  def update_account_associations
    User.update_account_associations([self])
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

  def self.calculate_account_associations_from_accounts(starting_account_ids, account_chain_cache)
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
  
  def page_view_data(options={})    
    # if they dont supply a date range then use the first day returned by page_views_by_day 
    # (which should be the first day that there is pageview statistics gathered)
    dates = options[:dates] && options[:dates].first ? 
      [options[:dates].first, (options[:dates].last || Time.now)] : 
      [page_views_by_day.sort.first.first.to_datetime, Time.now] 
    enrollments_with_page_views = enrollments.reject{ |e| e.page_views_by_day(:dates => dates).empty? }
    days = []
    dates.first.to_datetime.upto(dates.last) do |d| 
      # this * 1000 part is because the Highcharts expects something like what Date.UTC(2006, 2, 28) would give you,
      # which is MILLISECONDS from the unix epoch, ruby's to_f gives you SECONDS since then.
      days << [ (d.at_beginning_of_day.to_f * 1000).to_i, page_views_by_day(:dates => dates)[d.to_date.to_s].to_i, nil, nil].concat(
        # these 2 nil's at the end here are because the google annotatedtimeline expects a title and a text, 
        # we can put something meaninful here once we start tracking noteworth events 
        enrollments_with_page_views.map{ |enrollment| [ enrollment.page_views_by_day(:dates => dates)[d.to_date.to_s].to_i, nil, nil] }
      ).flatten
    end
    { :days => days, :labels => ["All Page Views"] + enrollments_with_page_views.map{ |e| e.course.name  } }
  end
  memoize :page_view_data
  
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
      !m.deleted?
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
  
  def self.find_by_email(email)
    CommunicationChannel.find_by_path_and_path_type(email, 'email').try(:user)
  end
    
  def <=>(other)
    self.name <=> other.name
  end

  def last_name_first
    User.last_name_first(self.name)
  end
  
  def last_name_first_or_unnamed
    res = last_name_first
    res = "No Name" if res.strip.empty?
    res
  end
  
  def first_name
    (self.name || "").split(/\s/)[0]
  end
  
  def last_name
    (self.name || "").split(/\s/)[1..-1].join(" ")
  end
  
  def self.last_name_first(name)
    name_groups = []
    if name
      comma_separated = name.split(",")
      comma_separated.each do |clump|
        names = clump.split
        if name.match(/\s/)
          names = clump.split.map{|c| c.split(".").join(". ").split }.flatten
        end
        name = names.pop
        name += ", " + names.join(" ") if !names.empty?
        name_groups << name
      end
    end
    name_groups.join ", "
  end
  
  def self.user_lookup_cache_key(id)
    ['_user_lookup', id].cache_key
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
    self.sortable_name = self.last_name_first.downcase
    self.reminder_time_for_due_dates ||= 48.hours.to_i
    self.reminder_time_for_grading ||= 0
    User.invalidate_cache(self.id) if self.id
    @reminder_times_changed = self.reminder_time_for_due_dates_changed? || self.reminder_time_for_grading_changed?
    true
  end
  
  def sortable_name
    self.sortable_name = read_attribute(:sortable_name) || self.last_name_first.downcase
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
    communication_channels.to_a.find{|cc| cc.path_type == 'email' }
  end
  
  def email
    Rails.cache.fetch(['user_email', self].cache_key) do
      email_channel.path if email_channel
    end
  end
  
  def self.cached_name(id)
    key = user_lookup_cache_key(id)
    user = find_cached(key) do
      User.find_by_id(id)
    end
    user && user.name
  end
  
  def gmail_channel
    google_services = self.user_services.find_all_by_service_domain("google.com")
    addr = google_services.find{|s| s.service_user_id}.service_user_id rescue nil
    self.communication_channels.find_by_path_and_path_type(addr, 'email')
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
      cc = CommunicationChannel.find_or_create_by_path_and_user_id(e, self.id)
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
      event :merge, :transitions_to => :pending_merge
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
    
    state :registered do
      event :merge, :transitions_to => :pending_merge
    end
    
    state :pending_merge do
      event :complete_merge, :transitions_to => :merged
    end
    
    state :deleted
    
    state :merged
    state :processor
    state :test_user
  end
  
  def registered?
    self.workflow_state == 'registered' || self.workflow_state == 'test_user'
  end
  
  def unavailable?
    deleted?
  end
  
  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.save
    self.pseudonyms.each{|p| p.destroy }
    self.communication_channels.each{|cc| cc.destroy }
    self.enrollments.each{|e| e.destroy }
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
    new_user.creation_email ||= self.creation_email
    new_user.creation_unique_id ||= self.creation_unique_id
    new_user.creation_sis_batch_id ||= self.creation_sis_batch_id
    new_user.save
    updates = []
    self.pseudonyms.each do |p|
      max_position += 1
      updates << "WHEN id=#{p.id} THEN #{max_position}"
    end
    Pseudonym.connection.execute("UPDATE pseudonyms SET user_id=#{new_user.id}, position=CASE #{updates.join(" ")} ELSE NULL END WHERE id IN (#{self.pseudonyms.map(&:id).join(',')})") unless self.pseudonyms.empty?
    max_position = (new_user.communication_channels.last.position || 0) rescue 0
    updates = []
    enrollment_emails = []
    self.communication_channels.each do |cc|
      max_position += 1
      updates << "WHEN id=#{cc.id} THEN #{max_position}"
      enrollment_emails << cc.path if cc.path && cc.path_type == 'email'
    end
    CommunicationChannel.connection.execute("UPDATE communication_channels SET user_id=#{new_user.id}, position=CASE #{updates.join(" ")} ELSE NULL END WHERE id IN (#{self.communication_channels.map(&:id).join(',')})") unless self.communication_channels.empty?
    e_conn = Enrollment.connection
    e_conn.execute("UPDATE enrollments SET user_id=#{new_user.id} WHERE user_id=#{self.id} AND invitation_email IN (#{enrollment_emails.map{|email| e_conn.quote(email)}.join(',')})") unless enrollment_emails.empty?
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
    updates = {}
    ['account_users','asset_user_accesses',
      'assignment_reminders','attachments',
      'calendar_events','collaborations','conversation_participants',
      'context_module_progressions','discussion_entries','discussion_topics',
      'enrollments','group_memberships','page_comments','page_views',
      'rubric_assessments','short_messages',
      'submission_comment_participants','user_services','web_conferences',
      'web_conference_participants','wiki_pages'].each do |key|
      updates[key] = "user_id"
    end
    updates['submission_comments'] = 'author_id'
    updates['conversation_messages'] = 'author_id'
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
    self.reload
    Enrollment.send_later(:recompute_final_scores, new_user.id)
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
    # this list should be longer if the person has admin priveleges...
    self.courses
  end
  
  def courses_with_grades
    self.available_courses.select{|c| c.grants_right?(self, nil, :participate_as_student)}
  end
  memoize :courses_with_grades
  
  attr_accessor :invitation_email
  
  set_policy do
    given { |user| user == self }
    can :rename and can :read and can :manage and can :manage_content and can :manage_files and can :manage_calendar and can :become_user

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
        (self.associated_accounts.any?{|a| a.grants_right?(user, nil, :manage_students) })
      )
    end
    can :manage_user_details and can :remove_avatar and can :rename and can :view_statistics
    
    given do |user|
      user && (
        # or, if the user we are given is an admin in one of this user's accounts
        (self.associated_accounts.any?{|a| a.grants_right?(user, nil, :manage_user_logins) })
      )
    end
    can :manage_user_details and can :manage_logins and can :rename and can :view_statistics

    given do |user|
      user && ((
        # or, if the user we are given can masquerade in *all* of this user's accounts
        # (to prevent an account admin from masquerading and gaining access to another root account)
        (self.associated_accounts.all?{|a| a.grants_right?(user, nil, :become_user) } && !self.associated_accounts.empty?)
      ) && (
        # account admins can't masquerade as other account admins
        self.account_users.empty? || (
          # unless they're a site admin
          Account.site_admin.grants_right?(user, nil, :become_user) &&
          # and not wanting to become a site admin
          !Account.site_admin_user?(self)
        )
      ) || (
        # only site admins can masquerade as users that don't belong to any account
        self.associated_accounts.empty? && Account.site_admin.grants_right?(user, nil, :become_user)
      ))
    end
    can :become_user
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
            self.avatar_image_url = data['profile_image_url'] || self.avatar_image_url
            self.avatar_image_updated_at = Time.now
          end
        end
      end
    end
  end
  
  def self.max_messages_per_day
    Setting.get('max_messages_per_day_per_user', 50).to_i
  end
  
  def max_messages_per_day
    User.max_messages_per_day
  end
  
  def gravatar_url(size=50, fallback=nil)
    fallback ||= "http://#{HostUrl.default_host}/images/no_pic.gif"
    "https://secure.gravatar.com/avatar/#{Digest::MD5.hexdigest(self.email) rescue '000'}?s=#{size}&d=#{CGI::escape(fallback)}"
  end
  
  def avatar_image=(val)
    return false if avatar_state == :locked
    val ||= {}
    if val['type'] == 'facebook'
      # TODO: support this
    elsif val['type'] == 'gravatar'
      self.avatar_image_source = 'gravatar'
      self.avatar_image_url = nil
      self.avatar_image_updated_at = Time.now
      self.avatar_state = 'submitted'
    elsif val['type'] == 'twitter'
      twitter = self.user_services.for_service('twitter').first rescue nil
      if twitter
        url = URI.parse("http://twitter.com/users/show.json?user_id=#{twitter.service_user_id}")
        data = JSON.parse(Net::HTTP.get(url)) rescue nil
        if data
          self.avatar_image_source = 'twitter'
          self.avatar_image_url = data['profile_image_url'] || self.avatar_image_url
          self.avatar_image_updated_at = Time.now
          self.avatar_state = 'submitted'
        end
      end
    elsif val['type'] == 'linked_in'
      linked_in = self.user_services.for_service('linked_in').first rescue nil
      if linked_in
        profile = linked_in_profile
        if profile
          self.avatar_image_url = profile['picture_url']
          self.avatar_image_source = 'linked_in'
          self.avatar_image_updated_at = Time.now
          self.avatar_state = 'submitted'
        end
      end
    elsif val['type'] == 'attachment' && val['url'] && val['url'].match(/\A\/images\/thumbnails\//)
      self.avatar_image_url = val['url']
      self.avatar_image_source = 'attachment'
      self.avatar_image_updated_at = Time.now
      self.avatar_state = 'submitted'
    else
      self.avatar_image_url = nil
      self.avatar_image_source = 'no_pic'
      self.avatar_image_updated_at = Time.now
      self.avatar_state = 'approved'
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
      write_attribute(:avatar_state, val)
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
  
  def lti_role_types
    memberships = current_enrollments.uniq + account_users.uniq
    memberships.map{|membership|
      case membership
      when StudentEnrollment
        'Student'
      when TeacherEnrollment
        'Instructor'
      when TaEnrollment
        'Instructor'
      when ObserverEnrollment
        'Observer'
      when AccountUser
        'AccountAdmin'
      else
        'Observer'
      end
    }.uniq
  end
  
  def avatar_url(size=nil, avatar_setting=nil, fallback=nil)
    size ||= 50
    avatar_setting ||= 'enabled'
    if avatar_setting == 'enabled' || (avatar_setting == 'enabled_pending' && avatar_approved?) || (avatar_setting == 'sis_only')
      @avatar_url ||= self.avatar_image_url 
    end
    @avatar_url ||= '/images/no_pic.gif' if self.avatar_image_source == 'no_pic'
    @avatar_url ||= gravatar_url(size, fallback) if avatar_setting == 'enabled'
    @avatar_url ||= '/images/no_pic.gif'
    @avatar_url
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
  
  
  def close_notification(id)
    preferences[:closed_notifications] ||= []
    preferences[:closed_notifications] << id.to_i
    preferences[:closed_notifications].uniq!
    self.updated_at = Time.now
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
    Assignment.for_context_codes(course_codes).active.due_before(1.week.from_now).expecting_submission.due_after(opts[:due_after] || 4.weeks.ago).need_submitting_info(id, opts[:limit] || 15, ignored_ids)
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
  
  def self.serialization_excludes; [:uuid,:phone,:creation_unique_id,:creation_email,:features_used]; end
  
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
  
  def assert_pseudonym_and_communication_channel
    if !self.communication_channel && !self.pseudonym
      raise "User must have at least one pseudonym or communication channel"
    elsif self.communication_channel && !self.pseudonym
      self.reload
    elsif self.pseudonym && !self.communication_channel
      self.pseudonym.assert_communication_channel
      self.reload
    end
  end
  
  def generate_reminders_if_changed
    send_later(:generate_reminders!) if @reminder_times_changed
  end
  
  def generate_reminders!
    enrollments = self.current_enrollments
    mgmt_course_ids = enrollments.select{|e| e.admin? }.map(&:course_id).uniq
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
  
   # activesupport/lib/active_support/memoizable.rb from rails and
   # http://github.com/seamusabshere/cacheable/blob/master/lib/cacheable.rb from the cacheable gem
   # to get a head start
  
  # this method takes an optional {:include_enrollment_uuid => uuid}   so that you can pass it the session[:enrollment_uuid] and it will include it. 
  def cached_current_enrollments(opts={})
    Rails.cache.fetch([self, 'current_enrollments', opts[:include_enrollment_uuid] ].cache_key) do
      res = self.current_and_invited_enrollments.to_a.dup
      if opts[:include_enrollment_uuid] && pending_enrollment = Enrollment.find_by_uuid_and_workflow_state(opts[:include_enrollment_uuid], "invited")
        res << pending_enrollment
        res.uniq!
      end
      res
    end
  end
  memoize :cached_current_enrollments
  
  def cached_not_ended_enrollments
    @cached_all_enrollments = Rails.cache.fetch([self, 'not_ended_enrollments'].cache_key) do
      self.not_ended_enrollments.to_a
    end
  end
  
  def cached_current_group_memberships
    self.group_memberships.active.select{|gm| gm.group.active? }
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
    opts[:fallback_start_at] ||= opts[:start_at]
    opts[:limit] ||= 20
    
    submissions = []
    submissions += self.submissions.after(opts[:fallback_start_at]).for_context_codes(context_codes).find(
      :all, 
      :conditions => "submissions.score IS NOT NULL AND assignments.workflow_state != 'deleted'",
      :include => [:assignment, :user, :submission_comments],
      :order => 'submissions.created_at DESC',
      :limit => opts[:limit]
    )
    # THIS IS SLOW, it takes ~230ms for mike
    submissions += Submission.for_context_codes(context_codes).find(
      :all,
      :select => "submissions.*, last_updated_at_from_db",
      :joins => self.class.send(:sanitize_sql_array, [<<-SQL, opts[:fallback_start_at], self.id, self.id]),
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
      :limit => opts[:limit]
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
  
  alias_method :stream_items_simple, :stream_items
  def stream_items(opts={})
    opts[:start_at] ||= 2.weeks.ago
    opts[:fallback_start_at] = opts[:start_at]
  
    items = stream_items_simple.scoped(:conditions => { 'stream_item_instances.hidden' => false })
    # dont make the query do an stream_items.context_code IN
    # ('course_20033','course_20237','course_20247' ...) if they dont pass any
    # contexts, just assume it wants any context code.
    if opts[:contexts]
      # still need to optimize the query to use a root_context_code.  that way a
      # users course dashboard even if they have groups does a query with
      # "context_code=..." instead of "context_code IN ..."
      items = items.scoped(:conditions => ['stream_item_instances.context_code in (?)', setup_context_lookups(opts[:contexts])])
    end

    if opts[:before_id]
      items = items.scoped(:conditions => ['id < ?', opts[:before_id]], :limit => 21)
    else
      items = items.scoped(:limit => 21)
    end

    # next line does 2 things, 
    # 1. forces the query to be run, so that we dont send one query for the count and one for the actual dataset.
    # 2. make sure that we always return an array and not nil
    items.all(:order => 'stream_item_instances.id desc')
  end
  memoize :stream_items
  
  def calendar_events_for_calendar(opts={})
    opts = opts.dup
    context_codes = opts[:context_codes] || (opts[:contexts] ? setup_context_lookups(opts[:contexts]) : self.cached_context_codes)
    return [] if (!context_codes || context_codes.empty?)
    opts[:start_at] ||= 2.weeks.ago
    opts[:fallback_start_at] ||= opts[:start_at] - 2.weeks
    opts[:fallback_start_at] = opts[:start_at] unless opts[:include_forum] == false
    opts[:end_at] ||= 1.weeks.from_now
    
    events = []
    ev = CalendarEvent
    ev = CalendarEvent.active if !opts[:include_deleted_events]
    events += ev.for_context_codes(context_codes).between(opts[:fallback_start_at], opts[:end_at]).updated_after(opts[:updated_at])
    events += Assignment.active.for_context_codes(context_codes).due_between(opts[:fallback_start_at], opts[:end_at]).updated_after(opts[:updated_at]).with_just_calendar_attributes
    events.sort_by{|e| [e.start_at, e.title || ""] }.uniq
  end
  
  def recent_events(opts={})
    context_codes = opts[:context_codes] || (opts[:contexts] ? setup_context_lookups(opts[:contexts]) : self.cached_context_codes)
    return [] if (!context_codes || context_codes.empty?)
    
    opts[:start_at] ||= 2.weeks.ago
    opts[:fallback_start_at] ||= opts[:start_at] - 2.weeks
    opts[:fallback_start_at] = opts[:start_at] unless opts[:include_forum] == false
    opts[:limit] ||= 20
    
    events = CalendarEvent.active.for_context_codes(context_codes).between(opts[:fallback_start_at], Time.now).scoped(:limit => opts[:limit])
    events += Assignment.active.for_context_codes(context_codes).due_between(opts[:fallback_start_at], Time.now).scoped(:limit => opts[:limit])
    events.sort_by{|e| [e.start_at, e.title] }.reverse.uniq.first(opts[:limit])
  end

  def upcoming_events(opts={})
    context_codes = opts[:context_codes] || (opts[:contexts] ? setup_context_lookups(opts[:contexts]) : self.cached_context_codes)
    return [] if (!context_codes || context_codes.empty?)
    
    opts[:end_at] ||= 1.weeks.from_now
    opts[:limit] ||= 20
    
    events = CalendarEvent.active.for_context_codes(context_codes).between(Time.now, opts[:end_at]).scoped(:limit => opts[:limit])
    events += Assignment.active.for_context_codes(context_codes).due_between(Time.now, opts[:end_at]).scoped(:limit => opts[:limit]).include_submitted_count
    events.sort_by{|e| [e.start_at, e.title] }.uniq.first(opts[:limit])
  end

  def undated_events(opts={})
    opts = opts.dup
    context_codes = opts[:context_codes] || (opts[:contexts] ? setup_context_lookups(opts[:contexts]) : self.cached_context_codes)
    return [] if (!context_codes || context_codes.empty?)

    undated_events = []
    undated_events += CalendarEvent.active.for_context_codes(context_codes).undated.updated_after(opts[:updated_at])
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
      # (b) g.participating_users.include(u)
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
  
  def manageable_courses
    Course.manageable_by_user(self.id).not_deleted
  end

  def manageable_courses_name_like(query="")
    self.manageable_courses.not_deleted.name_like(query).limit(50)
  end
  memoize :manageable_courses_name_like
  
  def last_completed_module
    self.context_module_progressions.select{|p| p.completed? }.sort_by{|p| p.completed_at || p.created_at }.last.context_module rescue nil
  end
  
  def last_completed_course
    self.enrollments.select{|e| e.completed? }.sort_by{|e| e.completed_at || e.created_at }.last.course rescue nil
  end
  
  def last_mastered_assignment
    self.learning_outcome_results.sort_by{|r| r.assessed_at || r.created_at }.select{|r| r.mastery? }.map{|r| r.assignment }.last
  end
  
  def self.assert_by_email(email, name=nil, password=nil)
    user = Pseudonym.find_by_unique_id(email).user rescue nil
    user ||= CommunicationChannel.find_by_path_and_path_type(email, 'email').try(:user)
    res = {:email => email}
    if user
      p = user.pseudonyms.active.find_by_unique_id(email)
      if user.creation_pending? || user.pre_registered?
        p ||= user.pseudonyms.build(:unique_id => email, :password => password, :password_confirmation => password)
        p.password = password
        p.password_confirmation = password
        res[:password] = password
      elsif !p
        p ||= user.pseudonyms.create!(:unique_id => email, :password => password, :password_confirmation => password)
        res[:password] = password
      end
      cc = user.communication_channels.unretired.find_by_path(email)
      cc ||= user.communication_channels.create!(:path => email) unless CommunicationChannel.find_by_path(email)
    else
      user = User.create!(:name => name || email)
      user.pseudonyms.create!(:unique_id => email, :path => email, :password => password, :password_confirmation => password)
      cc = user.communication_channels.find_by_path_and_path_type(email, 'email') #pseudonym.communication_channel.confirm
      cc.confirm if cc
      res[:password] = password
      res[:new] = true
    end
    res[:user] = user
    res
  end
  
  def profile_pics_folder
    folder = self.active_folders.find_by_name(Folder::PROFILE_PICS_FOLDER_NAME)
    unless folder
      folder = self.folders.create!(:name => Folder::PROFILE_PICS_FOLDER_NAME,
        :parent_folder => Folder.root_folders(self).find {|f| f.name == Folder::MY_FILES_FOLDER_NAME })
    end
    folder
  end
  
  def quota
    read_attribute(:storage_quota) || Setting.get_cached('user_default_quota', 50.megabytes.to_s).to_i
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

  def eportfolios_enabled?
    accounts = associated_root_accounts.reject(&:site_admin?)
    accounts.size == 0 || accounts.any?{ |a| a.settings[:enable_eportfolios] != false }
  end

  def initiate_conversation(user_ids, private = nil)
    user_ids = ([self.id] + user_ids).uniq
    private = user_ids.size <= 2 if private.nil?
    Conversation.initiate(user_ids, private).conversation_participants.find_by_user_id(self.id)
  end

  def enrollment_visibility
    Rails.cache.fetch([self, 'enrollment_visibility'].cache_key, :expires_in => 1.hour) do
      full_course_ids = []
      section_id_hash = {}
      restricted_course_hash = {}
      user_counts = {}
      (courses + concluded_courses).each do |course|
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
        user_counts[course.id] = course.enrollments.scoped(:conditions => self.class.reflections[:current_and_invited_enrollments].options[:conditions]).scoped(:conditions => conditions).size +
                                 course.enrollments.scoped(:conditions => self.class.reflections[:concluded_enrollments].options[:conditions]).scoped(:conditions => conditions).size
      end
      {:full_course_ids => full_course_ids,
       :section_id_hash => section_id_hash,
       :restricted_course_hash => restricted_course_hash,
       :user_counts => user_counts
      }
    end
  end

  def messageable_groups
    group_visibility = group_membership_visibility
    Group.find_all_by_id(visible_group_ids.reject{ |id| group_visibility[:user_counts][id] == 0 } + [0])
  end

  def visible_group_ids
    Rails.cache.fetch([self, 'messageable_groups'].cache_key, :expires_in => 1.hour) do
      (courses + concluded_courses.recently_ended).inject(self.current_groups) { |groups, course|
        groups | course.groups.active
      }.map(&:id)
    end
  end

  def group_membership_visibility
    Rails.cache.fetch([self, 'group_membership_visibility'].cache_key, :expires_in => 1.hour) do
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
            conditions = {:user_id => group.group_memberships.map(&:user_id), :course_section_id => sections}
            user_counts[group.id] = conditions[:user_id].present? ?
                                      group.context.enrollments.scoped(:conditions => self.class.reflections[:current_and_invited_enrollments].options[:conditions]).scoped(:conditions => conditions).size +
                                      group.context.enrollments.scoped(:conditions => self.class.reflections[:concluded_enrollments].options[:conditions]).scoped(:conditions => conditions).size :
                                    0
          end
        end
      end
      {:full_group_ids => full_group_ids,
       :section_id_hash => section_id_hash,
       :user_counts => user_counts
      }
    end
  end

  MESSAGEABLE_USER_COLUMNS = ['id', 'short_name', 'name', 'avatar_image_url', 'avatar_image_source'].map{|col|"users.#{col}"}
  MESSAGEABLE_USER_COLUMN_SQL = MESSAGEABLE_USER_COLUMNS.join(", ")
  def messageable_users(options = {})
    course_hash = enrollment_visibility
    full_course_ids = course_hash[:full_course_ids]
    restricted_course_hash = course_hash[:restricted_course_hash]

    group_hash = group_membership_visibility
    full_group_ids = group_hash[:full_group_ids]
    group_section_ids = []

    account_ids = []

    if options[:context]
      limited_course_ids = []
      limited_group_ids = []
      Array(options[:context]).each do |context|
        if context =~ /\Acourse_(\d+)\z/
          limited_course_ids << $1.to_i
        elsif context =~ /\Agroup_(\d+)\z/
          limited_group_ids << $1.to_i
        end
      end
      full_course_ids &= limited_course_ids
      course_section_ids = course_hash[:section_id_hash].values_at(*limited_course_ids).flatten.compact
      group_section_ids = group_hash[:section_id_hash].values_at(*limited_group_ids).flatten.compact
      restricted_course_hash.delete_if{|course_id, ids| !limited_course_ids.include?(course_id)}
      full_group_ids &= limited_group_ids
    else
      course_section_ids = course_hash[:section_id_hash].values.flatten
      # if we're not searching with context(s) in mind, include any users we
      # have admin access to know about
      account_ids = associated_accounts.select{ |a| a.grants_right?(self, nil, :read_roster) }.map(&:id)
      account_ids &= options[:account_ids] if options[:account_ids]
    end

    # if :ids is present but empty (different than just not present), don't
    # bother doing a query that's guaranteed to return no results.
    return [] if options[:ids] && options[:ids].empty?

    user_condition_sql = "TRUE"
    user_condition_sql << " AND users.id IN (#{options[:ids].map(&:to_i).join(', ')})" if options[:ids].present?
    user_condition_sql << " AND users.id NOT IN (#{options[:exclude_ids].map(&:to_i).join(', ')})" if options[:exclude_ids].present?
    if options[:search] && (parts = options[:search].strip.split(/\s+/)).present?
      parts.each do |part|
        user_condition_sql << " AND (#{wildcard('users.name', 'users.short_name', part)})"
      end
    end
    user_sql = []

    course_sql = []
    course_sql << "(course_id IN (#{full_course_ids.join(',')}))" if full_course_ids.present?
    course_sql << "(course_section_id IN (#{course_section_ids.join(',')}))" if course_section_ids.present?
    course_sql << "(course_section_id IN (#{group_section_ids.join(',')}) AND EXISTS(SELECT 1 FROM group_memberships WHERE user_id = users.id AND group_id IN (#{limited_group_ids.join(',')})) )" if group_section_ids.present?
    course_sql << "(course_id IN (#{restricted_course_hash.keys.join(',')}) AND (enrollments.type = 'TeacherEnrollment' OR enrollments.type = 'TaEnrollment' OR enrollments.user_id IN (#{([self.id] + restricted_course_hash.values.flatten.uniq).join(',')})))" if restricted_course_hash.present?
    user_sql << <<-SQL if course_sql.present?
      SELECT #{MESSAGEABLE_USER_COLUMN_SQL}, course_id, NULL AS group_id, #{connection.func(:group_concat, :'enrollments.type', ':')} AS roles
      FROM users, enrollments, courses
      WHERE (#{course_sql.join(' OR ')}) AND users.id = user_id AND courses.id = course_id
        AND (#{self.class.reflections[:current_and_invited_enrollments].options[:conditions]}
          OR #{self.class.reflections[:concluded_enrollments].options[:conditions]}
        )
        AND #{user_condition_sql}
      GROUP BY #{connection.group_by(['users.id', 'course_id'], *(MESSAGEABLE_USER_COLUMNS[1, MESSAGEABLE_USER_COLUMNS.size]))}
    SQL

    user_sql << <<-SQL if full_group_ids.present?
      SELECT #{MESSAGEABLE_USER_COLUMN_SQL}, NULL AS course_id, group_id, NULL AS roles
      FROM users, group_memberships
      WHERE group_id IN (#{full_group_ids.join(',')}) AND users.id = user_id
        AND group_memberships.workflow_state = 'accepted'
        AND #{user_condition_sql}
    SQL

    # if this is an account admin who doesn't have any courses/groups in common
    # with the user, we want to know the user's highest current enrollment type
    highest_enrollment_sql = <<-SQL
      SELECT type
      FROM enrollments, courses
      WHERE
        user_id = users.id AND courses.id = course_id
        AND (#{self.class.reflections[:current_and_invited_enrollments].options[:conditions]})
      ORDER BY #{Enrollment::ENROLLMENT_RANK_SQL}
      LIMIT 1
    SQL
    user_sql << <<-SQL if account_ids.present?
      SELECT #{MESSAGEABLE_USER_COLUMN_SQL}, 0 AS course_id, NULL AS group_id, (#{highest_enrollment_sql}) AS roles
      FROM users, user_account_associations
      WHERE user_account_associations.account_id IN (#{account_ids.join(',')})
        AND user_account_associations.user_id = users.id
        AND #{user_condition_sql}
    SQL

    if options[:ids]
      # provides a way for this user to start a conversation with someone
      # that isn't normally messageable (requires that they already be in a
      # conversation with that user)
      if options[:conversation_id].present?
        user_sql << <<-SQL
          SELECT #{MESSAGEABLE_USER_COLUMN_SQL}, NULL AS course_id, NULL AS group_id, NULL AS roles
          FROM users, conversation_participants
          WHERE #{user_condition_sql}
            AND conversation_participants.user_id = users.id
            AND conversation_participants.conversation_id = #{options[:conversation_id].to_i}
        SQL
      elsif options[:no_check_context]
        user_sql << <<-SQL
          SELECT #{MESSAGEABLE_USER_COLUMN_SQL}, NULL AS course_id, NULL AS group_id, NULL AS roles
          FROM users
          WHERE #{user_condition_sql}
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
      ORDER BY LOWER(COALESCE(short_name, name))
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

  def mark_all_conversations_as_read!
    conversations.unread.update_all(:workflow_state => 'read')
    User.update_all 'unread_conversations_count = 0', :id => id
  end

  # association with dynamic, filtered join condition for submissions.
  # This is messy, but in ActiveRecord 2 this is the only way to do an eager
  # loading :include condition that has dynamic join conditions. It looks like
  # there's better solutions in AR 3.
  # See also e.g., http://makandra.com/notes/983-dynamic-conditions-for-belongs_to-has_many-and-has_one-associations
  has_many :submissions_for_given_assignments, :include => [:assignment, :submission_comments], :conditions => 'submissions.assignment_id IN (#{Api.assignment_ids_for_students_api.join(",")})', :class_name => 'Submission'
end
