#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

  attr_accessible :name, :short_name, :sortable_name, :time_zone, :show_user_services, :gender, :visible_inbox_types, :avatar_image, :subscribe_to_emails, :locale, :bio, :birthdate, :terms_of_use, :self_enrollment_code, :initial_enrollment_type
  attr_accessor :original_id, :menu_data

  before_save :infer_defaults
  serialize :preferences
  include TimeZoneHelper
  time_zone_attribute :time_zone
  include Workflow

  # Internal: SQL fragments used to return enrollments in their respective workflow
  # states. Where needed, these consider the state of the course to ensure that
  # students do not see their enrollments on unpublished courses.
  #
  # strict_course_state can be used to bypass the course state checks. This is
  # useful in places like the course settings UI, where we use these conditions
  # to search users in the course (rather than as an association on a
  # particular user)
  def self.enrollment_conditions(state, strict_course_state = true)
    #strict_course_state = true
    case state
      when :active
        if strict_course_state
          "( enrollments.workflow_state = 'active' and ((courses.workflow_state = 'claimed' and enrollments.type IN ('TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment', 'StudentViewEnrollment')) or (courses.workflow_state = 'available')) )"
        else
          "( enrollments.workflow_state = 'active' and courses.workflow_state != 'deleted' )"
        end
      when :invited
        if strict_course_state
          "( enrollments.workflow_state = 'invited' and ((courses.workflow_state = 'available' and (enrollments.type = 'StudentEnrollment' or enrollments.type = 'ObserverEnrollment')) or (courses.workflow_state != 'deleted' and (enrollments.type IN ('TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment', 'StudentViewEnrollment')))))"
        else
          "( enrollments.workflow_state IN ('invited', 'creation_pending') and courses.workflow_state != 'deleted' )"
        end
      when :deleted;          "enrollments.workflow_state = 'deleted'"
      when :rejected;         "enrollments.workflow_state = 'rejected'"
      when :completed;        "enrollments.workflow_state = 'completed'"
      when :creation_pending; "enrollments.workflow_state = 'creation_pending'"
      when :inactive;         "enrollments.workflow_state = 'inactive'"
      when :current_and_invited
        enrollment_conditions(:active, strict_course_state) +
        " OR " +
        enrollment_conditions(:invited, strict_course_state)
    end
  end

  has_many :communication_channels, :order => 'communication_channels.position ASC', :dependent => :destroy
  has_one :communication_channel, :order => 'position'
  has_many :enrollments, :dependent => :destroy

  has_many :current_enrollments, :class_name => 'Enrollment', :include => [:course, :course_section], :conditions => enrollment_conditions(:active), :order => 'enrollments.created_at'
  has_many :invited_enrollments, :class_name => 'Enrollment', :include => [:course, :course_section], :conditions => enrollment_conditions(:invited), :order => 'enrollments.created_at'
  has_many :current_and_invited_enrollments, :class_name => 'Enrollment', :include => [:course], :order => 'enrollments.created_at',
           :conditions => enrollment_conditions(:current_and_invited)
  has_many :current_and_future_enrollments, :class_name => 'Enrollment', :include => [:course], :order => 'enrollments.created_at',
           :conditions => enrollment_conditions(:current_and_invited, false)
  has_many :not_ended_enrollments, :class_name => 'Enrollment', :conditions => "enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted')", :order => 'enrollments.created_at'
  has_many :concluded_enrollments, :class_name => 'Enrollment', :include => [:course, :course_section], :conditions => enrollment_conditions(:completed), :order => 'enrollments.created_at'
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
           :conditions => [enrollment_conditions(:active), enrollment_conditions(:completed)].join(' OR '), :order => 'enrollments.created_at'
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
  has_many :context_external_tools, :as => :context, :dependent => :destroy, :order => 'name'

  has_many :student_enrollments
  has_many :ta_enrollments
  has_many :teacher_enrollments, :class_name => 'TeacherEnrollment', :conditions => ["enrollments.type = 'TeacherEnrollment'"]
  has_many :submissions, :include => [:assignment, :submission_comments], :order => 'submissions.updated_at DESC', :dependent => :destroy
  has_many :pseudonyms, :order => 'position', :dependent => :destroy
  has_many :active_pseudonyms, :class_name => 'Pseudonym', :conditions => ['pseudonyms.workflow_state != ?', 'deleted']
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
  has_many :grading_standards, :conditions => ['workflow_state != ?', 'deleted']
  has_many :context_module_progressions
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
  has_many :media_objects, :as => :context
  has_many :user_generated_media_objects, :class_name => 'MediaObject'
  has_many :user_notes
  has_many :account_reports
  has_many :stream_item_instances, :dependent => :delete_all
  has_many :all_conversations, :class_name => 'ConversationParticipant', :include => :conversation
  has_many :conversation_batches, :include => :root_conversation_message
  has_many :favorites
  has_many :favorite_courses, :source => :course, :through => :current_and_invited_enrollments, :conditions => "EXISTS (SELECT 1 FROM favorites WHERE context_type = 'Course' AND context_id = enrollments.course_id AND user_id = enrollments.user_id)"
  has_many :zip_file_imports, :as => :context
  has_many :messages

  has_many :following_user_follows, :class_name => 'UserFollow', :as => :followed_item
  has_many :user_follows, :foreign_key => 'following_user_id'

  has_many :collections, :as => :context
  has_many :collection_items, :through => :collections
  has_many :collection_item_upvotes

  has_one :profile, :class_name => 'UserProfile'
  alias :orig_profile :profile

  has_many :progresses, :as => :context

  belongs_to :otp_communication_channel, :class_name => 'CommunicationChannel'

  include StickySisFields
  are_sis_sticky :name, :sortable_name, :short_name

  def conversations
    # i.e. exclude any where the user has deleted all the messages
    all_conversations.visible.order("last_message_at DESC, conversation_id DESC")
  end

  def page_views(options={})
    PageView.for_user(self, options)
  end

  scope :of_account, lambda { |account| where("EXISTS (#{account.user_account_associations.select("1").where("user_account_associations.user_id=users.id").to_sql})") }
  scope :recently_logged_in, lambda {
    includes(:pseudonyms).
        where("pseudonyms.current_login_at>?", 1.month.ago).
        order("pseudonyms.current_login_at DESC").
        limit(25)
  }
  scope :include_pseudonym, includes(:pseudonym)
  scope :restrict_to_sections, lambda { |sections|
    if sections.empty?
      scoped
    else
      where("enrollments.limit_privileges_to_course_section IS NULL OR enrollments.limit_privileges_to_course_section<>? OR enrollments.course_section_id IN (?)", true, sections)
    end
  }
  scope :name_like, lambda { |name|
    where("#{wildcard('users.name', 'users.short_name', name)} OR EXISTS (#{Pseudonym.select("1").where(wildcard('pseudonyms.sis_user_id', 'pseudonyms.unique_id', name)).where("pseudonyms.user_id=users.id").active.to_sql})")
  }
  scope :active, where("users.workflow_state<>'deleted'")

  scope :has_current_student_enrollments, where("EXISTS (SELECT * FROM enrollments JOIN courses ON courses.id=enrollments.course_id AND courses.workflow_state='available' WHERE enrollments.user_id=users.id AND enrollments.workflow_state IN ('active','invited') AND enrollments.type='StudentEnrollment')")

  def self.order_by_sortable_name(options = {})
    order_clause = clause = sortable_name_order_by_clause
    order_clause = "#{clause} DESC" if options[:direction] == :descending
    scope = self.order(order_clause)
    if (scope.scope(:find, :select))
      scope = scope.select(clause)
    end
    if scope.scope(:find, :group)
      scope = scope.group(clause)
    end
    scope
  end

  def self.by_top_enrollment
    scope = self
    if (!scope.scope(:find, :select))
      scope = scope.select("users.*")
    end
    scope.select("MIN(#{Enrollment.type_rank_sql(:student)}) AS enrollment_rank").
      group(User.connection.group_by(User)).
      order("enrollment_rank").
      order_by_sortable_name
  end

  scope :enrolled_in_course_between, lambda { |course_ids, start_at, end_at| joins(:enrollments).where(:enrollments => { :course_id => course_ids, :created_at => start_at..end_at }) }

  scope :for_course_with_last_login, lambda { |course, root_account_id, enrollment_type|
    # add a field to each user that is the aggregated max from current_login_at and last_login_at from their pseudonyms
    scope = select("users.*, MAX(current_login_at) as last_login, MAX(current_login_at) IS NULL as login_info_exists").
      # left outer join ensures we get the user even if they don't have a pseudonym
      joins(sanitize_sql([<<-SQL, root_account_id])).where(:enrollments => { :course_id => course })
        LEFT OUTER JOIN pseudonyms ON pseudonyms.user_id = users.id AND pseudonyms.account_id = ?
        INNER JOIN enrollments ON enrollments.user_id = users.id
      SQL
    scope = scope.where("enrollments.workflow_state<>'deleted'")
    scope = scope.where(:enrollments => { :type => enrollment_type }) if enrollment_type
    # the trick to get unique users
    scope.group("users.id")
  }

  has_a_broadcast_policy

  attr_accessor :require_acceptance_of_terms, :require_presence_of_name,
    :require_self_enrollment_code, :self_enrollment_code,
    :self_enrollment_course, :validation_root_account

  validates_length_of :name, :maximum => maximum_string_length, :allow_nil => true
  validates_length_of :short_name, :maximum => maximum_string_length, :allow_nil => true
  validates_length_of :sortable_name, :maximum => maximum_string_length, :allow_nil => true
  validates_presence_of :name, :if => :require_presence_of_name
  validates_locale :locale, :browser_locale, :allow_nil => true
  validates_acceptance_of :terms_of_use, :if => :require_acceptance_of_terms, :allow_nil => false
  validates_each :self_enrollment_code do |record, attr, value|
    next unless record.require_self_enrollment_code
    if value.blank?
      record.errors.add(attr, "blank")
    elsif record.validation_root_account
      course = record.validation_root_account.self_enrollment_course_for(value)
      record.self_enrollment_course = course
      if course && course.self_enrollment?
        record.errors.add(attr, "full") if course.self_enrollment_limit_met?
        record.errors.add(attr, "already_enrolled") if course.user_is_student?(record, :include_future => true)
      else
        record.errors.add(attr, "invalid")
      end
    else
      record.errors.add(attr, "account_required")
    end
  end

  before_save :assign_uuid
  before_save :update_avatar_image
  before_save :record_acceptance_of_terms
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
    update_account_associations if !self.class.skip_updating_account_associations? && self.workflow_state_changed? && self.id_was
  end

  def update_account_associations(opts = nil)
    opts ||= {:all_shards => true}
    # incremental is only for the current shard
    return User.update_account_associations([self], opts) if opts[:incremental]
    self.shard.activate do
      User.update_account_associations([self], opts)
    end
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
  def self.calculate_account_associations(user, data, account_chain_cache)
    return [] if %w{creation_pending deleted}.include?(user.workflow_state) || user.fake_student?

    enrollments = data[:enrollments][user.id] || []
    sections = enrollments.map { |e| data[:sections][e.course_section_id] }
    courses = sections.map { |s| data[:courses][s.course_id] }
    courses += sections.select(&:nonxlist_course_id).map { |s| data[:courses][s.nonxlist_course_id] }
    starting_account_ids = courses.map(&:account_id)
    starting_account_ids += (data[:pseudonyms][user.id] || []).map(&:account_id)
    starting_account_ids += (data[:account_users][user.id] || []).map(&:account_id)
    starting_account_ids.uniq!

    result = calculate_account_associations_from_accounts(starting_account_ids, account_chain_cache)
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
    shards = [Shard.current]
    if !precalculated_associations
      if !users_or_user_ids.first.is_a?(User)
        users = users_or_user_ids = User.select([:id, :preferences, :workflow_state]).where(:id =>user_ids).all
      else
        users = users_or_user_ids
      end

      if opts[:all_shards]
        shards = Set.new
        users.each { |u| shards += u.associated_shards }
        shards = shards.to_a
      end

      # basically we're going to do a huge preload here, but custom sql to only load the columns we need
      data = {:enrollments => [], :sections => [], :courses => [], :pseudonyms => [], :account_users => []}
      Shard.with_each_shard(shards) do
        shard_user_ids = users.map(&:id)

        data[:enrollments] += shard_enrollments =
            Enrollment.where("workflow_state<>'deleted' AND type<>'StudentViewEnrollment'").
                where(:user_id => shard_user_ids).
                select([:user_id, :course_id, :course_section_id]).
                uniq.
                all

        # probably a lot of dups, so more efficient to use a set than uniq an array
        course_section_ids = Set.new
        shard_enrollments.each { |e| course_section_ids << e.course_section_id }
        data[:sections] += shard_sections = CourseSection.select([:id, :course_id, :nonxlist_course_id]).
            where(:id => course_section_ids.to_a).all unless course_section_ids.empty?
        shard_sections ||= []
        course_ids = Set.new
        shard_sections.each do |s|
          course_ids << s.course_id
          course_ids << s.nonxlist_course_id if s.nonxlist_course_id
        end

        data[:courses] += Course.select([:id, :account_id]).where(:id => course_ids.to_a).all unless course_ids.empty?

        data[:pseudonyms] += Pseudonym.active.select([:user_id, :account_id]).uniq.where(:user_id => shard_user_ids).all
        data[:account_users] += AccountUser.select([:user_id, :account_id]).uniq.where(:user_id => shard_user_ids).all
      end
      # now make it easy to get the data by user id
      data[:enrollments] = data[:enrollments].group_by(&:user_id)
      data[:sections] = data[:sections].index_by(&:id)
      data[:courses] = data[:courses].index_by(&:id)
      data[:pseudonyms] = data[:pseudonyms].group_by(&:user_id)
      data[:account_users] = data[:account_users].group_by(&:user_id)
    end

    # TODO: transaction on each shard?
    UserAccountAssociation.transaction do
      current_associations = {}
      to_delete = []
      Shard.with_each_shard(shards) do
        # if shards is more than just the current shard, users will be set; otherwise
        # we never loaded users, but it doesn't matter, cause it's all the current shard
        shard_user_ids = users ? users.map(&:id) : user_ids
        UserAccountAssociation.where(:user_id => shard_user_ids).all
      end.each do |aa|
        key = [aa.user_id, aa.account_id]
        # duplicates. the unique index prevents these now, but this code
        # needs to hang around for the migration itself
        if current_associations.has_key?(key)
          to_delete << aa.id
          next
        end
        current_associations[key] = [aa.id, aa.depth]
      end

      users_or_user_ids.each do |user_id|
        if user_id.is_a? User
          user = user_id
          user_id = user.id
        end

        account_ids_with_depth = precalculated_associations
        if account_ids_with_depth.nil?
          user ||= User.find(user_id)
          account_ids_with_depth = calculate_account_associations(user, data, account_chain_cache)
        end

        account_ids_with_depth.each do |account_id, depth|
          key = [user_id, account_id]
          association = current_associations[key]
          if association.nil?
            # new association, create it
            aa = UserAccountAssociation.new
            aa.user_id = user_id
            aa.account_id = account_id
            aa.depth = depth
            aa.shard = Shard.shard_for(account_id)
            aa.shard.activate do
              begin
                UserAccountAssociation.transaction(:requires_new => true) do
                  aa.save!
                end
              rescue ActiveRecord::Base::UniqueConstraintViolation
                # race condition - someone else created the UAA after we queried for existing ones
                old_aa = UserAccountAssociation.find_by_user_id_and_account_id(aa.user_id, aa.account_id)
                raise unless old_aa # wtf!
                # make sure we don't need to change the depth
                if depth < old_aa.depth
                  old_aa.depth = depth
                  old_aa.save!
                end
              end
            end
          else
            # for incremental, only update the old association if it is deeper than the new one
            # for non-incremental, update it if it changed
            if incremental && association[1] > depth || !incremental && association[1] != depth
              if Rails.version < '3.0'
                UserAccountAssociation.update_all({ :depth => depth }, :id => association[0])
              else
                UserAccountAssociation.where(:id => association[0]).update_all(:depth => depth)
              end
            end
            # remove from list of existing for non-incremental
            current_associations.delete(key) unless incremental
          end
        end
      end

      to_delete += current_associations.map { |k, v| v[0] }
      if Rails.version < '3.0'
        UserAccountAssociation.delete_all(:id => to_delete) unless incremental || to_delete.empty?
      else
        UserAccountAssociation.where(:id => to_delete).delete_all unless incremental || to_delete.empty?
      end
    end
  end

  # These methods can be overridden by a plugin if you want to have an approval
  # process or implement additional tracking for new users
  def registration_approval_required?; false; end
  def new_registration(form_params = {}); end
  # DEPRECATED, override new_registration instead
  def new_teacher_registration(form_params = {}); new_registration(form_params); end

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

  scope :with_service, lambda { |service|
    service = service.service if service.is_a?(UserService)
    includes(:user_services).where(:user_services => { :service => service.to_s })
  }
  scope :enrolled_before, lambda { |date| where("enrollments.created_at<?", date) }

  def group_memberships_for(context)
    groups.where('groups.context_id' => context,
      'groups.context_type' => context.class.to_s,
      'group_memberships.workflow_state' => 'accepted').
    where("groups.workflow_state <> 'deleted'")
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
    self.name ||= self.email || t('#user.default_user_name', "User")
    self.short_name = nil if self.short_name == ""
    self.short_name ||= self.name
    self.sortable_name = nil if self.sortable_name == ""
    # recalculate the sortable name if the name changed, but the sortable name didn't, and the sortable_name matches the old name
    self.sortable_name = nil if !self.sortable_name_changed? && self.name_changed? && User.name_parts(self.sortable_name).compact.join(' ') == self.name_was
    self.sortable_name = User.last_name_first(self.name, self.sortable_name_was) unless read_attribute(:sortable_name)
    self.reminder_time_for_due_dates ||= 48.hours.to_i
    self.reminder_time_for_grading ||= 0
    self.initial_enrollment_type = nil unless ['student', 'teacher', 'ta', 'observer'].include?(initial_enrollment_type)
    User.invalidate_cache(self.id) if self.id
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
    # if you change this cache_key, change it in email_cached? as well
    value = Rails.cache.fetch(['user_email', self].cache_key) do
      email_channel.try(:path) || :none
    end
    # this sillyness is because rails equates falsey as not in the cache
    value == :none ? nil : value
  end

  def email_cached?
    Rails.cache.exist?(['user_email', self].cache_key)
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
    self.communication_channels.email.by_path(addr).first
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
    communication_channels.sms.first
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

  def associate_with_shard(shard)
  end

  def self.clone_communication_channel(cc, new_user, max_position)
    new_cc = cc.clone
    new_cc.shard = new_user.shard
    new_cc.position += max_position
    new_cc.user = new_user
    new_cc.save!
    cc.notification_policies.each do |np|
      new_np = np.clone
      new_np.shard = new_user.shard
      new_np.communication_channel = new_cc
      new_np.save!
    end
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
    Pseudonym.order(:created_at).where(:user_id => id).active.last
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
    self.available_courses.with_each_shard.select{|c| c.grants_right?(self, nil, :participate_as_student)}
  end
  memoize :courses_with_grades

  def sis_pseudonym_for(context)
    root_account = context.root_account
    raise "could not resolve root account" unless root_account.is_a?(Account)
    if self.pseudonyms.loaded? && self.shard == root_account.shard
      self.pseudonyms.detect { |p| p.active? && p.sis_user_id && p.account_id == root_account.id }
    else
      root_account.shard.activate do
        root_account.pseudonyms.active.find_by_user_id(self.id, :conditions => "sis_user_id IS NOT NULL")
      end
    end
  end

  set_policy do
    given { |user| user == self }
    can :read and can :manage and can :manage_content and can :manage_files and can :manage_calendar and can :send_messages and can :update_avatar

    given { |user| user.present? && self.public? }
    can :follow

    given { |user| user == self && user.user_can_edit_name? }
    can :rename

    given {|user| self.courses.any?{|c| c.user_is_instructor?(user)}}
    can :rename and can :create_user_notes and can :read_user_notes

    given do |user|
      user && (
        # by default this means that the user we are given is an administrator
        # of an account of one of the courses that this user is enrolled in, or
        # an admin (teacher/ta/designer) in the course
        self.all_courses.any? { |c| c.grants_right?(user, nil, :read_reports) }
      )
    end
    can :rename and can :remove_avatar and can :read_reports

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
      Account.site_admin.grants_right?(user, :view_statistics) ||
          self.associated_accounts.any?{|a| a.grants_right?(user, nil, :view_statistics)  }
      )
    end
    can :view_statistics

    given do |user|
      user && (
        # or, if the user we are given is an admin in one of this user's accounts
        Account.site_admin.grants_right?(user, :manage_students) ||
        self.associated_accounts.any? {|a| a.grants_right?(user, nil, :manage_students) }
      )
    end
    can :manage_user_details and can :update_avatar and can :remove_avatar and can :rename and can :view_statistics and can :read and can :read_reports

    given do |user|
      user && (
        Account.site_admin.grants_right?(user, :manage_user_logins) ||
        self.associated_accounts.any?{|a| a.grants_right?(user, nil, :manage_user_logins)  }
      )
    end
    can :view_statistics and can :read and can :read_reports

    given do |user|
      user && (
        # or, if the user we are given is an admin in one of this user's accounts
        Account.site_admin.grants_right?(user, :manage_user_logins) ||
        (self.associated_accounts.any?{|a| a.grants_right?(user, nil, :manage_user_logins) } &&
         self.accounts.select(&:root_account?).all? {|a| has_subset_of_account_permissions?(user, a) } )
      )
    end
    can :manage_user_details and can :manage_logins and can :rename
  end

  def can_masquerade?(masquerader, account)
    return true if self == masquerader
    # student view should only ever have enrollments in a single course
    return true if self.fake_student? && self.courses.any?{ |c| c.grants_right?(masquerader, nil, :use_student_view) }
    return false unless
        account.grants_right?(masquerader, nil, :become_user) && self.find_pseudonym_for_account(account, true)
    has_subset_of_account_permissions?(masquerader, account)
  end

  def has_subset_of_account_permissions?(user, account)
    return true if user == self
    return false unless account.root_account?
    account_users = account.all_account_users_for(self)
    return true if account_users.empty?
    account_users.all? do |account_user|
      account_user.is_subset_of?(user)
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

  # only used by ContextModuleProgression#deep_evaluate
  def submitted_submission_for(assignment_id)
    @submissions ||= self.submissions.having_submission.except(:includes).select([:id, :score, :assignment_id]).all
    @submissions.detect{|s| s.assignment_id == assignment_id }
  end

  # only used by ContextModuleProgression#deep_evaluate
  def attempted_quiz_submission_for(quiz_id)
    @quiz_submissions ||= self.quiz_submissions.select([:id, :kept_score, :quiz_id, :workflow_state]).select{|s| !s.settings_only? }
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

  def record_acceptance_of_terms
    if @require_acceptance_of_terms && @terms_of_use
      preferences[:accepted_terms] = Time.now.utc
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
  #         'external,' or 'attachment.'
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

  AVATAR_SETTINGS = ['enabled', 'enabled_pending', 'sis_only', 'disabled']
  def avatar_url(size=nil, avatar_setting=nil, fallback=nil, request=nil)
    return fallback if avatar_setting == 'disabled'
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
      uri.scheme ||= request ? request.protocol[0..-4] : "https" # -4 to chop off the ://
      if HostUrl.cdn_host
        uri.host = HostUrl.cdn_host
      elsif request && !uri.host
        uri.host = request.host
        uri.port = request.port if ![80, 443].include?(request.port)
      elsif !uri.host
        uri.host, uri.port = HostUrl.default_host.split(/:/)
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

  scope :with_avatar_state, lambda { |state|
    scope = where("avatar_image_url IS NOT NULL").order("avatar_image_updated_at DESC")
    if state == 'any'
      scope.where("avatar_state IS NOT NULL AND avatar_state<>'none'")
    else
      scope.where(:avatar_state => state)
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

  def manual_mark_as_read?
    !!preferences[:manual_mark_as_read]
  end

  def ignore_item!(asset, purpose, permanent = false)
    begin
      # more likely this doesn't exist, so try the create first
      asset.ignores.create!(:user => self, :purpose => purpose, :permanent => permanent)
    rescue ActiveRecord::Base::UniqueConstraintViolation
      asset.shard.activate do
        ignore = asset.ignores.find_by_user_id_and_purpose(self.id, purpose)
        ignore.permanent = permanent
        ignore.save!
      end
    end
    self.touch
  end

  def assignments_needing_submitting(opts={})
    Shackles.activate(:slave) do
      course_ids = if opts[:contexts]
        (Array(opts[:contexts]).map(&:id) &
         current_student_enrollment_course_ids)
      else
        current_student_enrollment_course_ids
      end

      # allow explicitly passing a nil limit
      limit = opts[:limit]
      limit = 15 unless opts.key?(:limit)
      due_after = opts[:due_after] || 4.weeks.ago

      result = Shard.partition_by_shard(course_ids) do |shard_course_ids|
        Assignment.for_course(shard_course_ids).
          active.
          due_between_with_overrides(due_after,1.week.from_now).
          not_ignored_by(self, 'submitting').
          expecting_submission.
          need_submitting_info(id, limit).
          not_locked
      end
      # outer limit, since there could be limit * n_shards results
      result = result[0..(limit - 1)] if limit
      result
    end
  end
  memoize :assignments_needing_submitting

  def assignments_needing_submitting_total_count(opts={})
    assignments_needing_submitting(opts.merge(:limit => nil)).size
  end

  def assignments_needing_grading(opts={})
    Shackles.activate(:slave) do
      course_ids = if opts[:contexts]
        (Array(opts[:contexts]).map(&:id) &
        current_admin_enrollment_course_ids)
      else
        current_admin_enrollment_course_ids
      end

      # allow explicitly passing a nil limit
      limit = opts[:limit]
      limit = 15 unless opts.key?(:limit)

      result = Shard.partition_by_shard(course_ids) do |shard_course_ids|
        Assignment.for_course(shard_course_ids).active.
          expecting_submission.
          not_ignored_by(self, 'grading').
          need_grading_info(limit).
          reject{|a| a.needs_grading_count_for_user(self) == 0}
      end
      # outer limit, since there could be limit * n_shards results
      result = result[0..(limit - 1)] if limit
      result
    end
  end
  memoize :assignments_needing_grading

  def assignments_needing_grading_total_count(opts={})
    assignments_needing_grading(opts.merge(:limit => nil)).size
  end

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

  def self.serialization_excludes
    [
      :uuid,
      :phone,
      :features_used,
      :otp_communication_channel_id,
      :otp_secret_key_enc,
      :otp_secret_key_salt,
      :collkey
    ]
  end

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
    results = {
      :contexts => [context],
      :collaborations => [],
      :folders => [],
      :folders_with_subcontent => [],
      :files => []
    }
    context_codes = results[:contexts].map{|c| c.asset_string }

    if !context.is_a?(User) && user
      results[:collaborations] = user.collaborations.active.includes(:user, :users).select{|c| c.context_id && c.context_type && context_codes.include?("#{c.context_type.underscore}_#{c.context_id}") }
      results[:collaborations] = results[:collaborations].sort_by{|c| c.created_at}.reverse
    end

    results[:contexts].each do |context|
      results[:folders] += context.active_folders_with_sub_folders
    end

    results[:folders] = results[:folders].sort_by{|f| [f.parent_folder_id || 0, f.position || 0, f.name || "", f.created_at]}
    results
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


  # this finds the reverse account chain starting at in_root_account and ending
  # at the lowest account such that all of the accounts to which the user is
  # associated which descend from in_root_account, descend from one of the
  # accounts in the chain.  In other words, if the users associated accounts
  # made a tree, it would be the chain between the root and the first branching
  # point.
  def common_account_chain(in_root_account)
    rid = in_root_account.id
    accts = self.associated_accounts.where("accounts.id = ? OR accounts.root_account_id = ?", rid, rid)
    return [] if accts.blank?
    children = accts.inject({}) do |hash,acct| 
      pid = acct.parent_account_id
      if pid.present?
        hash[pid] ||= []
        hash[pid] << acct
      end
      hash
    end

    longest_chain = [in_root_account]
    while true
      next_children = children[longest_chain.last.id]
      break unless next_children.present? && next_children.count == 1
      longest_chain << next_children.first
    end
    longest_chain
  end

  def courses_with_primary_enrollment(association = :current_and_invited_courses, enrollment_uuid = nil, options = {})
    res = self.shard.activate do
      Rails.cache.fetch([self, 'courses_with_primary_enrollment', association, options].cache_key, :expires_in => 15.minutes) do
        send(association).with_each_shard do |scope|
          courses = scope.distinct_on(["courses.id"],
            :select => "courses.*, enrollments.id AS primary_enrollment_id, enrollments.type AS primary_enrollment, #{Enrollment.type_rank_sql} AS primary_enrollment_rank, enrollments.workflow_state AS primary_enrollment_state",
            :order => "courses.id, #{Enrollment.type_rank_sql}, #{Enrollment.state_rank_sql}")

          unless options[:include_completed_courses]
            enrollments = Enrollment.where(:id => courses.map(&:primary_enrollment_id)).all
            date_restricted_ids = enrollments.select{ |e| e.completed? || e.inactive? }.map(&:id)
            courses.reject! { |course| date_restricted_ids.include?(course.primary_enrollment_id.to_i) }
          end

          courses
        end
      end.dup
    end

    if association == :current_and_invited_courses
      if enrollment_uuid && pending_course = Course.
        select("courses.*, enrollments.type AS primary_enrollment, #{Enrollment.type_rank_sql} AS primary_enrollment_rank, enrollments.workflow_state AS primary_enrollment_state").
        joins(:enrollments).
        where(:enrollments => { :uuid => enrollment_uuid, :workflow_state => 'invited' }).first
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
    self.shard.activate do
      Rails.cache.fetch([self, 'active_emails'].cache_key) do
        self.communication_channels.active.email.map(&:path)
      end
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
    self.shard.activate do
      res = Rails.cache.fetch([self, 'current_enrollments2', opts[:include_enrollment_uuid], opts[:include_future] ].cache_key) do
        res = (opts[:include_future] ? current_and_future_enrollments : current_and_invited_enrollments).with_each_shard
        if opts[:include_enrollment_uuid] && pending_enrollment = Enrollment.find_by_uuid_and_workflow_state(opts[:include_enrollment_uuid], "invited")
          res << pending_enrollment
          res.uniq!
        end
        res
      end
    end + temporary_invitations
  end
  memoize :cached_current_enrollments

  def cached_not_ended_enrollments
    self.shard.activate do
      @cached_all_enrollments = Rails.cache.fetch([self, 'not_ended_enrollments2'].cache_key) do
        self.not_ended_enrollments.with_each_shard
      end
    end
  end

  def cached_current_group_memberships
    self.shard.activate do
      @cached_current_group_memberships = Rails.cache.fetch([self, 'current_group_memberships'].cache_key) do
        self.current_group_memberships.with_each_shard
      end
    end
  end

  def current_student_enrollment_course_ids
    @current_student_enrollments ||= Rails.cache.fetch([self, 'current_student_enrollments'].cache_key) do
      self.enrollments.with_each_shard { |scope| scope.student.select(:course_id) }
    end
    @current_student_enrollments.map(&:course_id)
  end

  def current_admin_enrollment_course_ids
    @current_admin_enrollments ||= Rails.cache.fetch([self, 'current_admin_enrollments'].cache_key) do
      self.enrollments.with_each_shard { |scope| scope.admin.select(:course_id) }
    end
    @current_admin_enrollments.map(&:course_id)
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

    Shackles.activate(:slave) do
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
  end
  memoize :submissions_for_context_codes

  # This is only feedback for student contexts (unless specific contexts are passed in)
  def recent_feedback(opts={})
    context_codes = opts[:context_codes]
    context_codes ||= if opts[:contexts]
        setup_context_lookups(opts[:contexts])
      else
        self.current_student_enrollment_course_ids.map { |id| "course_#{id}" }
      end
    submissions_for_context_codes(context_codes, opts)
  end
  memoize :recent_feedback

  def visible_stream_item_instances(opts={})
    instances = stream_item_instances.where(:hidden => false).order('stream_item_instances.id desc')

    # dont make the query do an stream_item_instances.context_code IN
    # ('course_20033','course_20237','course_20247' ...) if they dont pass any
    # contexts, just assume it wants any context code.
    if opts[:contexts]
      # still need to optimize the query to use a root_context_code.  that way a
      # users course dashboard even if they have groups does a query with
      # "context_code=..." instead of "context_code IN ..."
      conditions = setup_context_association_lookups("stream_item_instances.context", opts[:contexts])
      instances = instances.where(conditions) unless conditions.first.empty?
    elsif opts[:context]
      instances = instances.where(:context_type => opts[:context].class.base_class.name, :context_id => opts[:context])
    end

    instances
  end

  # NOTE: excludes submission stream items
  def cached_recent_stream_items(opts={})
    expires_in = 1.day

    if opts[:contexts]
      items = []
      Array(opts[:contexts]).each do |context|
        items.concat(
                   Rails.cache.fetch(StreamItemCache.recent_stream_items_key(self, context.class.base_class.name, context.id),
                                     :expires_in => expires_in) {
                     recent_stream_items(:context => context)
                   })
      end
      items.sort { |a,b| b.id <=> a.id }
    else
      # no context in cache key
      Rails.cache.fetch(StreamItemCache.recent_stream_items_key(self), :expires_in => expires_in) {
        recent_stream_items
      }
    end
  end

  # NOTE: excludes submission stream items
  def recent_stream_items(opts={})
    self.shard.activate do
      Shackles.activate(:slave) do
        visible_instances = visible_stream_item_instances(opts).
            includes(:stream_item).
            limit(Setting.get('recent_stream_item_limit', 100))
        visible_instances.map do |sii|
          si = sii.stream_item
          next unless si.present?
          next if si.asset_type == 'Submission'
          si.data.write_attribute(:unread, sii.unread?)
          si
        end.compact
      end
    end
  end

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

    now = Time.zone.now

    opts[:end_at] ||= 1.weeks.from_now
    opts[:limit] ||= 20

    events = CalendarEvent.active.for_user_and_context_codes(self, context_codes).between(now, opts[:end_at]).limit(opts[:limit]).reject(&:hidden?)
    events += select_upcoming_assignments(Assignment.
        active.
        for_context_codes(context_codes).
        due_between_with_overrides(now, opts[:end_at]).
        include_submitted_count.
        map {|a| a.overridden_for(self)},opts.merge(:time => now)).
      first(opts[:limit])
    events.sort_by{|e| [e.start_at ? 0: 1,e.start_at || 0, e.title] }.uniq.first(opts[:limit])
  end

  def select_upcoming_assignments(assignments,opts)
    time = opts[:time] || Time.zone.now
    assignments.select do |a|
      if a.grants_right?(self, nil, :delete)
        a.all_dates_visible_to(self).any? do |due_hash|
          due_hash[:due_at] && due_hash[:due_at] >= time && due_hash[:due_at] <= opts[:end_at]
        end
      else
        a.due_at && a.due_at >= time && a.due_at <= opts[:end_at]
      end
    end
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

  def setup_context_association_lookups(column, contexts=nil, opts = {})
    contexts = Array(contexts || cached_contexts)
    conditions = [[]]
    backcompat = opts[:backcompat]
    contexts.map do |context|
      if backcompat
        conditions.first << "((#{column}_type=? AND #{column}_id=?) OR (#{column}_code=? AND #{column}_type IS NULL))"
      else
        conditions.first << "(#{column}_type=? AND #{column}_id=?)"
      end
      conditions.concat [context.class.base_class.name, context.id]
      conditions << context.asset_string if backcompat
    end
    conditions[0] = conditions[0].join(" OR ")
    conditions
  end

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
      self.courses.includes(:active_groups).select { |c| c.grants_right?(self, :manage_groups) }.each { |c| context_groups += c.active_groups }
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

  # Public: Return an array of context codes this user belongs to.
  #
  # include_concluded_codes - If true, include concluded courses (default: true).
  #
  # Returns an array of context code strings.
  def conversation_context_codes(include_concluded_codes = true)
    Rails.cache.fetch([self, include_concluded_codes, 'conversation_context_codes4'].cache_key, :expires_in => 1.day) do
      Shard.birth.activate do
        associations = %w{courses concluded_courses current_groups}
        associations.slice!(1) unless include_concluded_codes

        associations.inject([]) do |result, association|
          association_type = association.split('_')[-1].slice(0..-2)
          result.concat(send(association).with_each_shard.map { |x| "#{association_type}_#{x.id}" })
        end.uniq
      end
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
    note = user_notes.active.order('user_notes.created_at').last
    self.last_user_note = note ? note.created_at : nil
  end

  TAB_PROFILE = 0
  TAB_COMMUNICATION_PREFERENCES = 1
  TAB_FILES = 2
  TAB_EPORTFOLIOS = 3
  TAB_HOME = 4

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

  def initiate_conversation(users, private = nil, options = {})
    users = ([self] + users).uniq_by(&:id)
    private = users.size <= 2 if private.nil?
    Conversation.initiate(users, private, options).conversation_participants.find_by_user_id(self)
  end

  def messageable_user_calculator
    @messageable_user_calculator ||= MessageableUser::Calculator.new(self)
  end

  def load_messageable_user(user, options={})
    messageable_user_calculator.load_messageable_user(user, options)
  end

  def load_messageable_users(users, options={})
    messageable_user_calculator.load_messageable_users(users, options)
  end

  def messageable_users_in_context(asset_string)
    messageable_user_calculator.messageable_users_in_context(asset_string)
  end

  def count_messageable_users_in_context(asset_string)
    messageable_user_calculator.count_messageable_users_in_context(asset_string)
  end

  def messageable_users_in_course(course_or_id)
    messageable_user_calculator.messageable_users_in_course(course_or_id)
  end

  def count_messageable_users_in_course(course_or_id)
    messageable_user_calculator.count_messageable_users_in_course(course_or_id)
  end

  def messageable_users_in_section(section_or_id)
    messageable_user_calculator.messageable_users_in_section(section_or_id)
  end

  def count_messageable_users_in_section(section_or_id)
    messageable_user_calculator.count_messageable_users_in_section(section_or_id)
  end

  def messageable_users_in_group(group_or_id)
    messageable_user_calculator.messageable_users_in_group(group_or_id)
  end

  def count_messageable_users_in_group(group_or_id)
    messageable_user_calculator.count_messageable_users_in_group(group_or_id)
  end

  def search_messageable_users(options={})
    messageable_user_calculator.search_messageable_users(options)
  end

  def messageable_sections
    messageable_user_calculator.messageable_sections
  end

  def messageable_groups
    messageable_user_calculator.messageable_groups
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
    if info = load_messageable_user(user)
      if Rails.version < '3.0'
        contexts += Course.find(:all, :conditions => {:id => info.common_courses.keys}) if info.common_courses.present?
        contexts += Group.find(:all, :conditions => {:id => info.common_groups.keys}) if info.common_groups.present?
      else
        contexts += Course.where(:id => info.common_courses.keys).all if info.common_courses.present?
        contexts += Group.where(:id => info.common_groups.keys).all if info.common_groups.present?
      end
    end
    contexts.map(&:name).sort_by{|c|c.downcase}
  end

  def mark_all_conversations_as_read!
    conversations.unread.update_all(:workflow_state => 'read')
    User.where(:id => id).update_all(:unread_conversations_count => 0)
  end

  def conversation_participant(conversation_id)
    all_conversations.find_by_conversation_id(conversation_id)
  end

  # Public: Reset the user's cached unread conversations count.
  #
  # Returns nothing.
  def reset_unread_conversations_counter
    self.class.where(:id => id).update_all(:unread_conversations_count => conversations.unread.count)
  end

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
    # try to find one that's already loaded if possible
    if self.pseudonyms.loaded?
      result = self.pseudonyms.detect { |p| p.active? && p.works_for_account?(account, allow_implicit) }
      return result if result || self.associated_shards.length == 1
    end
    self.all_active_pseudonyms.detect { |p| p.works_for_account?(account, allow_implicit) }
  end

  # account = the account that you want a pseudonym for
  # preferred_template_account = pass in an actual account if you have a preference for which account the new pseudonym gets copied from
  # this may not be able to find a suitable pseudonym to copy, so would still return nil
  # if a pseudonym is created, it is *not* saved, and *not* added to the pseudonyms collection
  def find_or_initialize_pseudonym_for_account(account, preferred_template_account = nil)
    pseudonym = find_pseudonym_for_account(account)
    if !pseudonym
      # list of copyable pseudonyms
      active_pseudonyms = self.all_active_pseudonyms(:reload).select { |p|!p.password_auto_generated? && !p.account.delegated_authentication? }
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
    self.preferences[:fake_student] && !!self.enrollments.where(:type => 'StudentViewEnrollment').first
  end

  def private?
    not public?
  end

  def default_collection_name
    t('#user.default_collection_name', "%{user_name}'s Collection", :user_name => self.short_name)
  end

  def profile(force_reload = false)
    orig_profile(force_reload) || build_profile
  end

  def otp_secret_key_remember_me_cookie(time)
    "#{time.to_i}.#{Canvas::Security.hmac_sha1("#{time.to_i}.#{self.otp_secret_key}")}"
  end

  def validate_otp_secret_key_remember_me_cookie(value)
    value =~ /^(\d+)\.[0-9a-f]+/ &&
        $1.to_i >= (Time.now.utc - 30.days).to_i &&
        value == otp_secret_key_remember_me_cookie($1)
  end

  def otp_secret_key
    return nil unless otp_secret_key_enc
    Canvas::Security::decrypt_password(otp_secret_key_enc, otp_secret_key_salt, 'otp_secret_key', self.shard.settings[:encryption_key]) if otp_secret_key_enc
  end

  def otp_secret_key=(key)
    if key
      self.otp_secret_key_enc, self.otp_secret_key_salt = Canvas::Security::encrypt_password(key, 'otp_secret_key', self.shard.settings[:encryption_key])
    else
      self.otp_secret_key_enc = self.otp_secret_key_salt = nil
    end
    key
  end

  def crocodoc_id!
    cid = read_attribute(:crocodoc_id)
    return cid if cid

    Setting.transaction do
      s = Setting.find_by_name('crocodoc_counter', :lock => true)
      cid = s.value = s.value.to_i + 1
      s.save!
    end

    update_attribute(:crocodoc_id, cid)
    cid
  end

  def crocodoc_user
    "#{crocodoc_id!},#{short_name.gsub(",","")}"
  end

  # mfa settings for a user are the most restrictive of any pseudonyms the user has
  # a login for
  def mfa_settings
    result = self.pseudonyms.with_each_shard { |scope| scope.includes(:account) }.map(&:account).uniq.map do |account|
      case account.mfa_settings
        when :disabled
          0
        when :optional
          1
        when :required_for_admins
          if account.all_account_users_for(self).empty?
            1
          else
            # short circuit the entire method
            return :required
          end
        when :required
          # short circuit the entire method
          return :required
      end
    end.max
    return :disabled if result.nil?
    [ :disabled, :optional ][result]
  end

  def weekly_notification_bucket
    # place in the next 24 hours after saturday morning midnight is
    # determined by account and user. messages for any user in the same
    # account (on the same shard) map into the same 6-hour window, and then
    # are spread within that window by user. this is specifically 24 real
    # hours, not 1 day, because DST sucks. so it'll go to 1am sunday
    # morning and 11pm saturday night on the DST transition days, but
    # midnight sunday morning the rest of the time.
    account_bucket = (shard.id.to_i + pseudonym.try(:account_id).to_i) % DelayedMessage::WEEKLY_ACCOUNT_BUCKETS
    user_bucket = self.id % DelayedMessage::MINUTES_PER_WEEKLY_ACCOUNT_BUCKET
    account_bucket * DelayedMessage::MINUTES_PER_WEEKLY_ACCOUNT_BUCKET + user_bucket
  end

  def weekly_notification_time
    # weekly notification scheduling happens in Eastern-time
    time_zone = ActiveSupport::TimeZone.us_zones.find{ |zone| zone.name == 'Eastern Time (US & Canada)' }

    # start at midnight saturday morning before next monday
    target = time_zone.now.next_week - 2.days

    minutes = weekly_notification_bucket.minutes

    # if we're already past that (e.g. it's sunday or late saturday),
    # advance by a week
    target += 1.week if target + minutes < time_zone.now

    # move into the 24 hours after midnight saturday morning and return
    target + minutes
  end

  def weekly_notification_range
    # weekly notification scheduling happens in Eastern-time
    time_zone = ActiveSupport::TimeZone.us_zones.find{ |zone| zone.name == 'Eastern Time (US & Canada)' }

    # start on January first instead of "today" to avoid DST, but still move to
    # a saturday from there so we get the right day-of-week on start_hour
    target = time_zone.now.change(:month => 1, :day => 1).next_week - 2.days + weekly_notification_bucket.minutes

    # 2 hour on-the-hour span around the target such that distance from the
    # start hour is at least 30 minutes.
    start_hour = target - 30.minutes
    start_hour = start_hour.change(:hour => start_hour.hour)
    end_hour = start_hour + 2.hours

    [start_hour, end_hour]
  end

  # Given a text string, return a value suitable for the user's initial_enrollment_type.
  # It supports strings formatted as enrollment types like "StudentEnrollment" and
  # it also supports text like "student", "teacher", "observer" and "ta".
  #
  # Any unsupported types have +nil+ returned.
  def self.initial_enrollment_type_from_text(type)
    # Convert the string "StudentEnrollment" to "student".
    # Return only valid matching types. Otherwise, nil.
    type = type.to_s.downcase.sub(/(view)?enrollment/, '')
    %w{student teacher ta observer}.include?(type) ? type : nil
  end

  def associated_shards
    [Shard.default]
  end

  def accounts
    self.account_users.with_each_shard { |scope| scope.includes(:account) }.map(&:account).uniq
  end
  memoize :accounts

  def all_pseudonyms
    self.pseudonyms.with_each_shard
  end
  memoize :all_pseudonyms

  def all_active_pseudonyms
    self.pseudonyms.with_each_shard { |scope| scope.active }
  end
  memoize :all_active_pseudonyms

  def prefers_gradebook2?
    preferences[:use_gradebook2] != false
  end

  def stamp_logout_time!
    if Rails.version < '3.0'
      User.update_all({ :last_logged_out => Time.zone.now }, :id => self)
    else
      User.where(:id => self).update_all(:last_logged_out => Time.zone.now)
    end
  end
end
