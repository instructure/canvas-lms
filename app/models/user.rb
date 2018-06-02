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

class User < ActiveRecord::Base
  GRAVATAR_PATTERN = /^https?:\/\/[a-zA-Z0-9.-]+\.gravatar\.com\//
  include TurnitinID

  # this has to be before include Context to prevent a circular dependency in Course
  def self.sortable_name_order_by_clause(table = nil)
    col = table ? "#{table}.sortable_name" : 'sortable_name'
    best_unicode_collation_key(col)
  end


  include Context
  include ModelCache
  include UserLearningObjectScopes

  attr_accessor :previous_id, :menu_data, :gradebook_importer_submissions, :prior_enrollment

  before_save :infer_defaults
  after_create :set_default_feature_flags
  after_update :clear_cached_short_name, if: -> (user) {user.saved_change_to_short_name? || (user.read_attribute(:short_name).nil? && user.saved_change_to_name?)}

  serialize :preferences
  include TimeZoneHelper
  time_zone_attribute :time_zone
  include Workflow

  def self.enrollment_conditions(state)
    Enrollment::QueryBuilder.new(state).conditions or raise "invalid enrollment conditions"
  end

  has_many :communication_channels, -> { order('communication_channels.position ASC') }, dependent: :destroy
  has_many :notification_policies, through: :communication_channels
  has_one :communication_channel, -> { where("workflow_state<>'retired'").order(:position) }
  has_many :ignores
  has_many :planner_notes, :dependent => :destroy

  has_many :enrollments, :dependent => :destroy

  has_many :not_ended_enrollments, -> { where("enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted', 'inactive')") }, class_name: 'Enrollment', multishard: true
  has_many :not_removed_enrollments, -> { where.not(workflow_state: ['rejected', 'deleted', 'inactive']) }, class_name: 'Enrollment', multishard: true
  has_many :observer_enrollments
  has_many :observee_enrollments, :foreign_key => :associated_user_id, :class_name => 'ObserverEnrollment'

  has_many :as_student_observation_links, -> { where.not(:workflow_state => 'deleted') }, class_name: 'UserObservationLink',
    foreign_key: :user_id, dependent: :destroy, inverse_of: :student
  has_many :as_observer_observation_links, -> { where.not(:workflow_state => 'deleted') }, class_name: 'UserObservationLink',
    foreign_key: :observer_id, dependent: :destroy, inverse_of: :observer

  has_many :linked_observers, -> { distinct }, :through => :as_student_observation_links, :source => :observer, :class_name => 'User'
  has_many :linked_students, -> { distinct }, :through => :as_observer_observation_links, :source => :student, :class_name => 'User'

  has_many :all_courses, :source => :course, :through => :enrollments
  has_many :all_courses_for_active_enrollments, -> { Enrollment.active }, :source => :course, :through => :enrollments
  has_many :group_memberships, -> { preload(:group) }, dependent: :destroy
  has_many :groups, -> { where("group_memberships.workflow_state<>'deleted'") }, :through => :group_memberships
  has_many :polls, class_name: 'Polling::Poll'

  has_many :current_group_memberships, -> { eager_load(:group).where("group_memberships.workflow_state = 'accepted' AND groups.workflow_state<>'deleted'") }, class_name: 'GroupMembership'
  has_many :current_groups, :through => :current_group_memberships, :source => :group
  has_many :user_account_associations
  has_many :associated_accounts, -> { order("user_account_associations.depth") }, source: :account, through: :user_account_associations
  has_many :associated_root_accounts, -> { order("user_account_associations.depth").where(accounts: { parent_account_id: nil }) }, source: :account, through: :user_account_associations
  has_many :developer_keys
  has_many :access_tokens, -> { where(:workflow_state => "active").preload(:developer_key) }
  has_many :notification_endpoints, :through => :access_tokens
  has_many :context_external_tools, -> { order(:name) }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :lti_results, inverse_of: :user, class_name: 'Lti::Result'

  has_many :student_enrollments
  has_many :ta_enrollments
  has_many :teacher_enrollments, -> { where(enrollments: { type: 'TeacherEnrollment' })}, class_name: 'TeacherEnrollment'
  has_many :all_submissions, -> { preload(:assignment, :submission_comments).order('submissions.updated_at DESC') }, class_name: 'Submission', dependent: :destroy
  has_many :submissions, -> { active.preload(:assignment, :submission_comments, :grading_period).order('submissions.updated_at DESC') }
  has_many :pseudonyms, -> { order(:position) }, dependent: :destroy
  has_many :active_pseudonyms, -> { where("pseudonyms.workflow_state<>'deleted'") }, class_name: 'Pseudonym'
  has_many :pseudonym_accounts, :source => :account, :through => :pseudonyms
  has_many :active_pseudonym_accounts, :source => :account, :through => :active_pseudonyms
  has_one :pseudonym, -> { where("pseudonyms.workflow_state<>'deleted'").order(:position) }
  has_many :attachments, :as => 'context', :dependent => :destroy
  has_many :active_images, -> { where("attachments.file_state != ? AND attachments.content_type LIKE 'image%'", 'deleted').order('attachments.display_name').preload(:thumbnail) }, as: :context, inverse_of: :context, class_name: 'Attachment'
  has_many :active_assignments, -> { where("assignments.workflow_state<>'deleted'") }, as: :context, inverse_of: :context, class_name: 'Assignment'
  has_many :all_attachments, :as => 'context', :class_name => 'Attachment'
  has_many :assignment_student_visibilities
  has_many :quiz_student_visibilities, :class_name => 'Quizzes::QuizStudentVisibility'
  has_many :folders, -> { order('folders.name') }, as: :context, inverse_of: :context
  has_many :submissions_folders, -> { where.not(:folders => {:submission_context_code => nil}) }, as: :context, inverse_of: :context, class_name: 'Folder'
  has_many :active_folders, -> { where("folders.workflow_state<>'deleted'").order('folders.name') }, class_name: 'Folder', as: :context, inverse_of: :context
  has_many :calendar_events, -> { preload(:parent_event) }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :eportfolios, :dependent => :destroy
  has_many :quiz_submissions, :dependent => :destroy, :class_name => 'Quizzes::QuizSubmission'
  has_many :dashboard_messages, -> { where(to: "dashboard", workflow_state: 'dashboard').order('created_at DESC') }, class_name: 'Message', dependent: :destroy
  has_many :collaborations, -> { order('created_at DESC') }
  has_many :user_services, -> { order('created_at') }, dependent: :destroy
  has_many :rubric_associations, -> { preload(:rubric).order('rubric_associations.created_at DESC') }, as: :context, inverse_of: :context
  has_many :rubrics
  has_many :context_rubrics, :as => :context, :inverse_of => :context, :class_name => 'Rubric'
  has_many :grading_standards, -> { where("workflow_state<>'deleted'") }
  has_many :context_module_progressions
  has_many :assessment_question_bank_users
  has_many :assessment_question_banks, :through => :assessment_question_bank_users
  has_many :learning_outcome_results

  has_many :collaborators
  has_many :collaborations, -> { preload(:user, :collaborators) }, through: :collaborators
  has_many :assigned_submission_assessments, -> { preload(:user, submission: :assignment) }, class_name: 'AssessmentRequest', foreign_key: 'assessor_id'
  has_many :assigned_assessments, :class_name => 'AssessmentRequest', :foreign_key => 'assessor_id'
  has_many :web_conference_participants
  has_many :web_conferences, :through => :web_conference_participants
  has_many :account_users
  has_many :media_objects, :as => :context, :inverse_of => :context
  has_many :user_generated_media_objects, :class_name => 'MediaObject'
  has_many :user_notes
  has_many :account_reports
  has_many :stream_item_instances, :dependent => :delete_all
  has_many :all_conversations, -> { preload(:conversation) }, class_name: 'ConversationParticipant'
  has_many :conversation_batches, -> { preload(:root_conversation_message) }
  has_many :favorites
  has_many :messages
  has_many :sis_batches
  has_many :sis_post_grades_statuses
  has_many :content_migrations, :as => :context, :inverse_of => :context
  has_many :content_exports, :as => :context, :inverse_of => :context
  has_many :usage_rights,
    as: :context, inverse_of: :context,
    class_name: 'UsageRights',
    dependent: :destroy
  has_many :gradebook_csvs, dependent: :destroy

  has_one :profile, :class_name => 'UserProfile'

  has_many :progresses, :as => :context, :inverse_of => :context
  has_many :one_time_passwords, -> { order(:id) }, inverse_of: :user

  belongs_to :otp_communication_channel, :class_name => 'CommunicationChannel'

  include StickySisFields
  are_sis_sticky :name, :sortable_name, :short_name

  include FeatureFlags

  def conversations
    # i.e. exclude any where the user has deleted all the messages
    all_conversations.visible.order("last_message_at DESC, conversation_id DESC")
  end

  def page_views(options={})
    PageView.for_user(self, options)
  end

  scope :of_account, lambda { |account| joins(:user_account_associations).where(:user_account_associations => {:account_id => account}).shard(account.shard) }
  scope :recently_logged_in, -> {
    eager_load(:pseudonyms).
        where("pseudonyms.current_login_at>?", 1.month.ago).
        order("pseudonyms.current_login_at DESC").
        limit(25)
  }
  scope :include_pseudonym, -> { preload(:pseudonym) }
  scope :restrict_to_sections, lambda { |sections|
    if sections.empty?
      all
    else
      where("enrollments.limit_privileges_to_course_section IS NULL OR enrollments.limit_privileges_to_course_section<>? OR enrollments.course_section_id IN (?)", true, sections)
    end
  }
  scope :name_like, lambda { |name|
    next none if name.strip.empty?
    scopes = []
    all.primary_shard.activate do
      base_scope = except(:select, :order, :group, :having)
      scopes << base_scope.where(wildcard('users.name', name))
      scopes << base_scope.where(wildcard('users.short_name', name))
      scopes << base_scope.joins(:pseudonyms).where(wildcard('pseudonyms.sis_user_id', name)).where(pseudonyms: {workflow_state: 'active'})
      scopes << base_scope.joins(:pseudonyms).where(wildcard('pseudonyms.unique_id', name)).where(pseudonyms: {workflow_state: 'active'})
    end

    scopes.map!(&:to_sql)
    self.from("(#{scopes.join("\nUNION\n")}) users")
  }
  scope :active, -> { where("users.workflow_state<>'deleted'") }

  scope :has_current_student_enrollments, -> do
    where("EXISTS (?)",
      Enrollment.joins("JOIN #{Course.quoted_table_name} ON courses.id=enrollments.course_id AND courses.workflow_state='available'").
          where("enrollments.user_id=users.id AND enrollments.workflow_state IN ('active','invited') AND enrollments.type='StudentEnrollment'"))
  end

  scope :not_fake_student, -> { where("enrollments.type <> 'StudentViewEnrollment'")}

  # NOTE: only use for courses with differentiated assignments on
  scope :able_to_see_assignment_in_course_with_da, lambda {|assignment_id, course_id|
    joins(:assignment_student_visibilities).
    where(:assignment_student_visibilities => { :assignment_id => assignment_id, :course_id => course_id })
  }

  # NOTE: only use for courses with differentiated assignments on
  scope :able_to_see_quiz_in_course_with_da, lambda {|quiz_id, course_id|
    joins(:quiz_student_visibilities).
    where(:quiz_student_visibilities => { :quiz_id => quiz_id, :course_id => course_id })
  }

  scope :observing_students_in_course, lambda {|observee_ids, course_ids|
    joins(:enrollments).where(enrollments: {type: 'ObserverEnrollment', associated_user_id: observee_ids, course_id: course_ids, workflow_state: 'active'})
  }

  # when an observer is added to a course they get an enrollment where associated_user_id is nil. when they are linked to
  # a student, this first enrollment stays the same, but a new one with an associated_user_id is added. thusly to find
  # course observers, you take the difference between all active observers and active observers with associated users
  scope :observing_full_course, lambda {|course_ids|
    active_observer_scope = joins(:enrollments).where(enrollments: {type: 'ObserverEnrollment', course_id: course_ids, workflow_state: 'active'})
    users_observing_students = active_observer_scope.where("enrollments.associated_user_id IS NOT NULL").pluck(:id)

    if users_observing_students == [] || users_observing_students == nil
      active_observer_scope
    else
      active_observer_scope.where("users.id NOT IN (?)", users_observing_students)
    end
  }

  scope :linked_through_root_accounts, lambda {|root_accounts|
    root_accounts = Array(root_accounts)
    root_accounts << nil # TODO: remove after root_account_id is populated and is not-nulled (a)
    where(UserObservationLink.table_name => {:root_account_id => root_accounts})
  }

  def reload(*)
    @all_pseudonyms = nil
    @all_active_pseudonyms = nil
    super
  end

  def assignment_and_quiz_visibilities(context)
    RequestCache.cache("assignment_and_quiz_visibilities", self, context) do
      {assignment_ids: DifferentiableAssignment.scope_filter(context.assignments, self, context).pluck(:id),
        quiz_ids: DifferentiableAssignment.scope_filter(context.quizzes, self, context).pluck(:id)}
    end
  end

  def self.order_by_sortable_name(options = {})
    clause = sortable_name_order_by_clause
    sort_direction = options[:direction] == :descending ? 'DESC' : 'ASC'
    scope = self.order("#{clause} #{sort_direction}").order("#{self.table_name}.id #{sort_direction}")
    if scope.select_values.empty?
      scope = scope.select(self.arel_table[Arel.star])
    end
    if scope.select_values.present?
      scope = scope.select(clause)
    end
    if scope.group_values.present?
      scope = scope.group(clause)
    end
    scope
  end

  def self.by_top_enrollment
    scope = self.all
    if scope.select_values.blank?
      scope = scope.select("users.*")
    end
    scope.select("MIN(#{Enrollment.type_rank_sql(:student)}) AS enrollment_rank").
      group(User.connection.group_by(User)).
      order("enrollment_rank").
      order_by_sortable_name
  end

  scope :enrolled_in_course_between, lambda { |course_ids, start_at, end_at| joins(:enrollments).where(:enrollments => { :course_id => course_ids, :created_at => start_at..end_at }) }

  scope :with_last_login, lambda {
    select("users.*, MAX(current_login_at) as last_login").
      joins("LEFT OUTER JOIN #{Pseudonym.quoted_table_name} ON pseudonyms.user_id = users.id").
      group("users.id")
  }

  scope :for_course_with_last_login, lambda { |course, root_account_id, enrollment_type|
    # add a field to each user that is the aggregated max from current_login_at and last_login_at from their pseudonyms
    scope = select("users.*, MAX(current_login_at) as last_login, MAX(current_login_at) IS NULL as login_info_exists").
      # left outer join ensures we get the user even if they don't have a pseudonym
      joins(sanitize_sql([<<-SQL, root_account_id])).where(:enrollments => { :course_id => course })
        LEFT OUTER JOIN #{Pseudonym.quoted_table_name} ON pseudonyms.user_id = users.id AND pseudonyms.account_id = ?
        INNER JOIN #{Enrollment.quoted_table_name} ON enrollments.user_id = users.id
      SQL
    scope = scope.where("enrollments.workflow_state<>'deleted'")
    scope = scope.where(:enrollments => { :type => enrollment_type }) if enrollment_type
    # the trick to get unique users
    scope.group("users.id")
  }

  attr_accessor :require_acceptance_of_terms, :require_presence_of_name,
    :require_self_enrollment_code, :self_enrollment_code,
    :self_enrollment_course, :validation_root_account, :sortable_name_explicitly_set
  attr_reader :self_enrollment

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
      if course && course.self_enrollment_enabled?
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

  def courses_for_enrollments(enrollment_scope)
    Course.active.joins(:all_enrollments).merge(enrollment_scope.except(:joins)).distinct
  end

  def courses
    courses_for_enrollments(enrollments.current)
  end

  def current_and_invited_courses
    courses_for_enrollments(enrollments.current_and_invited)
  end

  def concluded_courses
    courses_for_enrollments(enrollments.concluded)
  end

  def current_and_concluded_courses
    courses_for_enrollments(enrollments.current_and_concluded)
  end

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
    update_account_associations if !self.class.skip_updating_account_associations? && self.saved_change_to_workflow_state? && self.id_before_last_save
  end

  def update_account_associations(opts = nil)
    opts ||= {:all_shards => true}
    # incremental is only for the current shard
    return User.update_account_associations([self], opts) if opts[:incremental]
    self.shard.activate do
      User.update_account_associations([self], opts)
    end
  end

  def enrollments_for_account_and_sub_accounts(account)
    # enrollments are always on the course's shard
    # and courses are always on the root account's shard
    account.shard.activate do
      Enrollment.where(user_id: self).active.joins(:course).where("courses.account_id=? OR courses.root_account_id=?",account,account)
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
      accounts = Account.where(id: remaining_ids)
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
        users = users_or_user_ids = User.select([:id, :preferences, :workflow_state, :updated_at]).where(id: user_ids).to_a
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
                distinct.to_a

        # probably a lot of dups, so more efficient to use a set than uniq an array
        course_section_ids = Set.new
        shard_enrollments.each { |e| course_section_ids << e.course_section_id }
        data[:sections] += shard_sections = CourseSection.select([:id, :course_id, :nonxlist_course_id]).
            where(:id => course_section_ids.to_a).to_a unless course_section_ids.empty?
        shard_sections ||= []
        course_ids = Set.new
        shard_sections.each do |s|
          course_ids << s.course_id
          course_ids << s.nonxlist_course_id if s.nonxlist_course_id
        end

        data[:courses] += Course.select([:id, :account_id]).where(:id => course_ids.to_a).to_a unless course_ids.empty?

        data[:pseudonyms] += Pseudonym.active.select([:user_id, :account_id]).distinct.where(:user_id => shard_user_ids).to_a
        data[:account_users] += AccountUser.active.select([:user_id, :account_id]).distinct.where(:user_id => shard_user_ids).to_a
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
        UserAccountAssociation.where(:user_id => shard_user_ids).to_a
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

      users_or_user_ids.uniq.sort_by{|u| u.try(:id) || u}.each do |user_id|
        if user_id.is_a? User
          user = user_id
          user_id = user.id
        end

        account_ids_with_depth = precalculated_associations
        if account_ids_with_depth.nil?
          user ||= User.find(user_id)
          account_ids_with_depth = calculate_account_associations(user, data, account_chain_cache)
        end

        account_ids_with_depth.sort_by(&:first).each do |account_id, depth|
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
              rescue ActiveRecord::RecordNotUnique
                # race condition - someone else created the UAA after we queried for existing ones
                old_aa = UserAccountAssociation.where(user_id: aa.user_id, account_id: aa.account_id).first
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
            if (incremental && association[1] > depth) || (!incremental && association[1] != depth)
              UserAccountAssociation.where(:id => association[0]).update_all(:depth => depth)
            end
            # remove from list of existing for non-incremental
            current_associations.delete(key) unless incremental
          end
        end
      end

      to_delete += current_associations.map { |k, v| v[0] }
      UserAccountAssociation.where(:id => to_delete).delete_all unless incremental || to_delete.empty?
    end
  end

  # These methods can be overridden by a plugin if you want to have an approval
  # process or implement additional tracking for new users
  def registration_approval_required?; false; end

  def new_registration(form_params = {}); end
  # DEPRECATED, override new_registration instead
  def new_teacher_registration(form_params = {}); new_registration(form_params); end

  def assign_uuid
    # DON'T use ||=, because that will cause an immediate save to the db if it
    # doesn't already exist
    self.uuid = CanvasSlug.generate_securish_uuid if !read_attribute(:uuid)
  end
  protected :assign_uuid

  scope :with_service, lambda { |service|
    service = service.service if service.is_a?(UserService)
    eager_load(:user_services).where(:user_services => { :service => service.to_s })
  }
  scope :enrolled_before, lambda { |date| where("enrollments.created_at<?", date) }

  def group_memberships_for(context)
    groups.where('groups.context_id' => context,
      'groups.context_type' => context.class.to_s,
      'group_memberships.workflow_state' => 'accepted').
    where("groups.workflow_state <> 'deleted'")
  end

  # Returns an array of groups which are currently visible for the user.
  def visible_groups
    @visible_groups ||= begin
      enrollments = self.cached_current_enrollments(preload_dates: true, preload_courses: true)
      self.current_groups.select do |group|
        group.context_type != 'Course' || enrollments.any? do |en|
          en.course == group.context && !(en.inactive? || en.completed?) && (en.admin? || en.course.available?)
        end
      end
    end
  end

  def <=>(other)
    self.name <=> other.name
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
    User.name_parts(self.sortable_name, likely_already_surname_first: true)[0] || ''
  end

  def last_name
    User.name_parts(self.sortable_name, likely_already_surname_first: true)[1] || ''
  end

  # Feel free to add, but the "authoritative" list (http://en.wikipedia.org/wiki/Title_(name)) is quite large
  SUFFIXES = /^(Sn?r\.?|Senior|Jn?r\.?|Junior|II|III|IV|V|VI|Esq\.?|Esquire)$/i

  # see also user_sortable_name.js
  def self.name_parts(name, prior_surname: nil, likely_already_surname_first: false)
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
      if !likely_already_surname_first && !suffix && surname =~ /\s/ && given =~ SUFFIXES
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

  def self.last_name_first(name, name_was = nil, likely_already_surname_first:)
    previous_surname = name_parts(name_was, likely_already_surname_first: likely_already_surname_first)[1]
    given, surname, suffix = name_parts(name, prior_surname: previous_surname)
    given = [given, suffix].compact.join(' ')
    surname ? "#{surname}, #{given}".strip : given
  end

  def infer_defaults
    self.name = nil if self.name == "User"
    self.name ||= self.email || t('#user.default_user_name', "User")
    self.short_name = nil if self.short_name == ""
    self.short_name ||= self.name
    self.sortable_name = nil if self.sortable_name == ""
    # recalculate the sortable name if the name changed, but the sortable name didn't, and the sortable_name matches the old name
    self.sortable_name = nil if !self.sortable_name_changed? &&
        !sortable_name_explicitly_set &&
        self.name_changed? &&
        User.name_parts(self.sortable_name, likely_already_surname_first: true).compact.join(' ') == self.name_was
    unless read_attribute(:sortable_name)
      self.sortable_name = User.last_name_first(self.name, self.sortable_name_was, likely_already_surname_first: true)
    end
    self.reminder_time_for_due_dates ||= 48.hours.to_i
    self.reminder_time_for_grading ||= 0
    self.initial_enrollment_type = nil unless ['student', 'teacher', 'ta', 'observer'].include?(initial_enrollment_type)
    true
  end

  def set_default_feature_flags
    self.enable_feature!(:new_user_tutorial_on_off)
  end

  def sortable_name
    self.sortable_name = read_attribute(:sortable_name) ||
        User.last_name_first(self.name, likely_already_surname_first: false)
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
    if communication_channels.loaded?
      communication_channels.to_a.find { |cc| cc.path_type == 'email' && cc.workflow_state != 'retired' }
    else
      communication_channels.email.unretired.first
    end
  end

  def email
    value = Rails.cache.fetch(email_cache_key) do
      email_channel.try(:path) || :none
    end
    # this sillyness is because rails equates falsey as not in the cache
    value == :none ? nil : value
  end

  def email_cache_key
    ['user_email', self].cache_key
  end

  def clear_email_cache!
    Rails.cache.delete(email_cache_key)
  end

  def email_cached?
    Rails.cache.exist?(email_cache_key)
  end

  def gmail_channel
    addr = self.user_services.
        where(service_domain: "google.com").
        limit(1).pluck(:service_user_id).first
    self.communication_channels.email.by_path(addr).first
  end

  def gmail
    res = gmail_channel.path rescue nil
    res ||= google_drive_address
    res ||= google_docs_address
    res || email
  end

  def google_docs_address
    google_service_address('google_docs')
  end

  def google_drive_address
    google_service_address('google_drive')
  end

  def google_service_address(service_name)
    self.user_services.where(service: service_name)
      .limit(1).pluck(service_name == 'google_drive' ? :service_user_name : :service_user_id).first
  end

  def email=(e)
    if e.is_a?(CommunicationChannel) and e.user_id == self.id
      cc = e
    else
      cc = self.communication_channels.email.by_path(e).first ||
           self.communication_channels.email.create!(path: e)
      cc.user = self
    end
    cc.move_to_top
    cc.save!
    self.reload
    self.clear_email_cache!
    cc.path
  end

  def sms_channel
    # It's already ordered, so find the first one, if there's one.
    communication_channels.sms.first
  end

  def sms
    sms_channel.path if sms_channel
  end

  def short_name
    read_attribute(:short_name) || name
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

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.remove_from_root_account(:all)
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now.utc
    self.save
  end

  # avoid extraneous callbacks when enrolled in multiple sections
  def delete_enrollments(enrollment_scope=self.enrollments)
    courses_to_update = enrollment_scope.active.distinct.pluck(:course_id)
    Enrollment.suspend_callbacks(:set_update_cached_due_dates) do
      enrollment_scope.each{ |e| e.destroy }
    end
    user_ids = enrollment_scope.pluck(:user_id).uniq
    courses_to_update.each do |course|
      DueDateCacher.recompute_users_for_course(user_ids, course)
    end
  end

  def remove_from_root_account(root_account)
    ActiveRecord::Base.transaction do
      if root_account == :all
        # make sure to hit all shards
        enrollment_scope = self.enrollments.shard(self)
        user_observer_scope = self.as_student_observation_links.shard(self)
        user_observee_scope = self.as_observer_observation_links.shard(self)
        pseudonym_scope = self.pseudonyms.active.shard(self)
        account_users = self.account_users.active.shard(self)
        has_other_root_accounts = false
      else
        # make sure to do things on the root account's shard. but note,
        # root_account.enrollments won't include the student view user's
        # enrollments, so we need to fetch them off the user instead; the
        # student view user won't be cross shard, so that will still be the
        # right shard
        enrollment_scope = fake_student? ? self.enrollments : root_account.enrollments.where(user_id: self)
        user_observer_scope = self.as_student_observation_links.shard(self)
        user_observee_scope = self.as_observer_observation_links.shard(self)
        pseudonym_scope = root_account.pseudonyms.active.where(user_id: self)

        account_users = root_account.account_users.where(user_id: self).to_a +
          self.account_users.shard(root_account).where(:account_id => root_account.all_accounts).to_a
        has_other_root_accounts = self.associated_accounts.shard(self).where('accounts.id <> ?', root_account).exists?
      end

      self.delete_enrollments(enrollment_scope)
      user_observer_scope.destroy_all
      user_observee_scope.destroy_all
      pseudonym_scope.each(&:destroy)
      account_users.each(&:destroy)

      # only delete the user's communication channels when the last account is
      # removed (they don't belong to any particular account). they will always
      # be on the user's shard
      self.communication_channels.each(&:destroy) unless has_other_root_accounts

      self.update_account_associations
    end
    self.reload
  end

  def associate_with_shard(shard, strength = :strong)
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

  def check_courses_right?(user, sought_right)
    # Look through the currently enrolled courses first.  This should
    # catch most of the calls.  If none of the current courses grant
    # the right then look at the concluded courses.
    user && sought_right && (
      self.courses.any?{ |c| c.grants_right?(user, sought_right) } ||
      self.concluded_courses.any?{ |c| c.grants_right?(user, sought_right) }
    )
  end

  def check_accounts_right?(user, sought_right)
    # check if the user we are given is an admin in one of this user's accounts
    return false unless user
    return true if Account.site_admin.grants_right?(user, sought_right)
    common_shards = associated_shards & user.associated_shards
    search_method = ->(shard) do
      associated_accounts.shard(shard).any?{|a| a.grants_right?(user, sought_right) }
    end

    # search shards the two users have in common first, since they're most likely
    return true if common_shards.any?(&search_method)

    # now do an exhaustive search, since it's possible to have admin permissions for accounts
    # you're not associated with
    return true if (associated_shards - common_shards).any?(&search_method)

    false
  end

  set_policy do
    given { |user| user == self }
    can :read and can :read_grades and can :read_profile and can :read_as_admin and can :manage and
      can :manage_content and can :manage_files and can :manage_calendar and can :send_messages and
      can :update_avatar and can :manage_feature_flags and can :api_show_user

    given { |user| user == self && user.user_can_edit_name? }
    can :rename

    given {|user| self.courses.any?{|c| c.user_is_instructor?(user)}}
    can :read_profile

    # by default this means that the user we are given is an administrator
    # of an account of one of the courses that this user is enrolled in, or
    # an admin (teacher/ta/designer) in the course
    given { |user| self.check_courses_right?(user, :read_reports) }
    can :read_profile and can :remove_avatar and can :read_reports

    given { |user| self.check_courses_right?(user, :manage_user_notes) }
    can :create_user_notes and can :read_user_notes

    given {|user| self.check_accounts_right?(user, :manage_user_notes) }
    can :create_user_notes and can :read_user_notes and can :delete_user_notes

    given {|user| self.check_accounts_right?(user, :view_statistics) }
    can :view_statistics

    given {|user| self.check_accounts_right?(user, :manage_students) }
    can :read_profile and can :view_statistics and can :read_reports and can :read_grades

    given {|user| self.check_accounts_right?(user, :manage_user_logins) }
    can :read and can :read_reports and can :read_profile and can :api_show_user

    given {|user| self.check_accounts_right?(user, :read_roster) }
    can :read_full_profile and can :api_show_user

    given {|user| self.check_accounts_right?(user, :view_all_grades) }
    can :read_grades

    given {|user| self.check_accounts_right?(user, :view_user_logins) }
    can :view_user_logins

    given {|user| self.check_accounts_right?(user, :read_email_addresses) }
    can :read_email_addresses

    given do |user|
      self.check_accounts_right?(user, :manage_user_logins) && self.adminable_accounts.select(&:root_account?).all? {|a| has_subset_of_account_permissions?(user, a) }
    end
    can :manage_user_details and can :rename and can :update_avatar and can :remove_avatar and
      can :manage_feature_flags

    given{ |user| self.pseudonyms.shard(self).any?{ |p| p.grants_right?(user, :update) } }
    can :merge

    given do |user|
      # a user can reset their own MFA, but only if the setting isn't required
      (self == user && self.mfa_settings != :required) ||

      # a site_admin with permission to reset_any_mfa
      (Account.site_admin.grants_right?(user, :reset_any_mfa)) ||
      # an admin can reset another user's MFA only if they can manage *all*
      # of the user's pseudonyms
      self != user && self.pseudonyms.shard(self).all? do |p|
        p.grants_right?(user, :update) ||
        # the account does not have mfa enabled
        p.account.mfa_settings == :disabled ||
        # they are an admin user and have reset MFA permission
        p.account.grants_right?(user, :reset_any_mfa)
      end
    end
    can :reset_mfa

    given { |user| user && user.as_observer_observation_links.where(user_id: self.id).exists? }
    can :read and can :read_as_parent
  end

  def can_masquerade?(masquerader, account)
    return true if self == masquerader
    # student view should only ever have enrollments in a single course
    return true if self.fake_student? && self.courses.any?{ |c| c.grants_right?(masquerader, :use_student_view) }
    return false unless
        account.grants_right?(masquerader, nil, :become_user) && SisPseudonym.for(self, account, type: :implicit, require_sis: false)
    has_subset_of_account_permissions?(masquerader, account)
  end

  def has_subset_of_account_permissions?(user, account)
    return true if user == self
    return false unless account.root_account?

    Rails.cache.fetch(['has_subset_of_account_permissions', self, user, account].cache_key, :expires_in => 60.minutes) do
      account_users = account.all_account_users_for(self)
      account_users.all? do |account_user|
        account_user.is_subset_of?(user)
      end
    end
  end

  def allows_user_to_remove_from_account?(account, other_user)
    Pseudonym.new(account: account, user: self).grants_right?(other_user, :delete) &&
    (Pseudonym.new(account: account, user: self).grants_right?(other_user, :manage_sis) ||
     !account.pseudonyms.active.where(user_id: self).where('sis_user_id IS NOT NULL').exists?)
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
    contexts = [self] + self.courses + self.groups.active + self.all_courses_for_active_enrollments
    contexts.uniq
  end

  def file_management_contexts
    contexts = [self] + self.courses + self.groups.active + self.all_courses
    contexts.uniq.select{|c| c.grants_right?(self, nil, :manage_files) }
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

  def update_avatar_image(force_reload=false)
    if !self.avatar_image_url || force_reload
      if self.avatar_image_source == 'twitter'
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
    accept_terms if @require_acceptance_of_terms && @terms_of_use
  end

  def accept_terms
    preferences[:accepted_terms] = Time.now.utc
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
  #       :type - The type of avatar. Should be 'gravatar,'
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
    external_avatar_url_patterns = Setting.get('avatar_external_url_patterns', '^https://[a-zA-Z0-9.-]+\.instructure\.com/').split(/,/).map {|re| Regexp.new re}

    if val['url'] && val['url'].match?(GRAVATAR_PATTERN)
      self.avatar_image_source = 'gravatar'
      self.avatar_image_url = val['url']
      self.avatar_state = 'submitted'
    elsif val['type'] == 'attachment' && val['url']
      self.avatar_image_source = 'attachment'
      self.avatar_image_url = val['url']
      self.avatar_state = 'submitted'
    elsif val['url'] && external_avatar_url_patterns.find { |p| val['url'].match?(p) }
      self.avatar_image_source = 'external'
      self.avatar_image_url = val['url']
      self.avatar_state = 'submitted'
    end
  end

  def report_avatar_image!(associated_context=nil)
    if self.avatar_state == :approved || self.avatar_state == :locked
      self.avatar_state = 're_reported'
    else
      self.avatar_state = 'reported'
    end
    self.save!
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
    Canvas::Security.verify_hmac_sha1(sig, user_id.to_s, truncate: 10) ? user_id : nil
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
    if (avatar_setting == 'enabled') && (self.avatar_image_source == 'gravatar')
      @avatar_url ||= gravatar_url(size, fallback, request)
    end
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
      uri.scheme ||= request ? request.protocol[0..-4] : HostUrl.protocol # -4 to chop off the ://
      if HostUrl.cdn_host
        uri.host = HostUrl.cdn_host
      elsif request && !uri.host
        uri.host = request.host
        uri.port = request.port if ![80, 443].include?(request.port)
      elsif !uri.host
        uri.host, port = HostUrl.default_host.split(/:/)
        uri.port = Integer(port) if port
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
    rubrics += Rubric.active.where(context_code: context_codes).to_a
    rubrics.uniq.sort_by{|r| [(r.association_count || 0) > 3 ? CanvasSort::First : CanvasSort::Last, Canvas::ICU.collation_key(r.title || CanvasSort::Last)]}
  end

  def assignments_recently_graded(opts={})
    opts = { :start_at => 1.week.ago, :limit => 10 }.merge(opts)
    Submission.active.recently_graded_assignments(id, opts[:start_at], opts[:limit])
  end

  def preferences
    read_or_initialize_attribute(:preferences, {})
  end

  def new_user_tutorial_statuses
    preferences[:new_user_tutorial_statuses] ||= {}
  end

  def custom_colors
    preferences[:custom_colors] ||= {}
  end

  def dashboard_positions
    preferences[:dashboard_positions] ||= {}
  end

  def dashboard_positions=(new_positions)
    preferences[:dashboard_positions] = new_positions
  end

  # Use the user's preferences for the default view
  # Otherwise, use the account's default (if set)
  # Fallback to using cards (default option on the Account settings page)
  def dashboard_view
    preferences[:dashboard_view] || account.default_dashboard_view || 'cards'
  end

  def dashboard_view=(new_dashboard_view)
    preferences[:dashboard_view] = new_dashboard_view
  end

  def course_nicknames
    preferences[:course_nicknames] ||= {}
  end

  def course_nickname(course)
    shard.activate do
      course_nicknames[course.id]
    end
  end

  def watched_conversations_intro?
    preferences[:watched_conversations_intro] == true
  end

  def watched_conversations_intro(value=true)
    preferences[:watched_conversations_intro] = value
  end

  def send_scores_in_emails?(root_account)
    preferences[:send_scores_in_emails] == true && root_account.settings[:allow_sending_scores_in_emails] != false
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

  def prefers_high_contrast?
    !!feature_enabled?(:high_contrast)
  end

  def manual_mark_as_read?
    !!preferences[:manual_mark_as_read]
  end

  def collapse_global_nav?
    !!preferences[:collapse_global_nav]
  end

  def disabled_inbox?
    !!preferences[:disable_inbox]
  end

  def create_announcements_unlocked?
    preferences.fetch(:create_announcements_unlocked, false)
  end

  def create_announcements_unlocked(bool)
    preferences[:create_announcements_unlocked] = bool
  end

  def use_new_conversations?
    true
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
      self.update_attribute(:uuid, CanvasSlug.generate_securish_uuid)
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

  def secondary_identifier
    self.email || self.id
  end

  def self_enroll_if_necessary
    return unless @self_enrollment_course
    return if @self_enrolling # avoid infinite recursion when enrolling across shards (pseudonym creation + shard association stuff)
    @self_enrolling = true
    @self_enrollment = @self_enrollment_course.self_enroll_student(self, :skip_pseudonym => @just_created, :skip_touch_user => true)
    @self_enrolling = false
  end

  def is_a_context?
    true
  end

  def account
    self.pseudonym.account rescue Account.default
  end

  # this finds the reverse account chain starting at in_root_account and ending
  # at the lowest account such that all of the accounts to which the user is
  # associated with, which descend from in_root_account, descend from one of the
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

    enrollment_account_ids = in_root_account.
      all_enrollments.
      current_and_concluded.
      where(user_id: self).
      joins(:course).
      distinct.
      pluck(:account_id)

    longest_chain = [in_root_account]
    while true
      break if enrollment_account_ids.include?(longest_chain.last.id)

      next_children = children[longest_chain.last.id]
      break unless next_children.present? && next_children.count == 1
      longest_chain << next_children.first
    end
    longest_chain
  end

  def courses_with_primary_enrollment(association = :current_and_invited_courses, enrollment_uuid = nil, options = {})
    cache_key = [association, enrollment_uuid, options].cache_key
    @courses_with_primary_enrollment ||= {}
    @courses_with_primary_enrollment.fetch(cache_key) do
      res = self.shard.activate do
        result = Rails.cache.fetch([self, 'courses_with_primary_enrollment2', association, options, ApplicationController.region].cache_key, :expires_in => 15.minutes) do

          # Set the actual association based on if its asking for favorite courses or not.
          actual_association = association == :favorite_courses ? :current_and_invited_courses : association
          scope = send(actual_association)

          shards = in_region_associated_shards
          # Limit favorite courses based on current shard.
          if association == :favorite_courses
            ids = self.favorite_context_ids("Course")
            if ids.empty?
              scope = scope.none
            else
              shards = shards & ids.map { |id| Shard.shard_for(id) }
              scope = scope.where(id: ids)
            end
          end

          unless options[:include_completed_courses]
            scope = scope.joins(:all_enrollments => :enrollment_state).where("enrollment_states.restricted_access = ?", false).
              where("enrollment_states.state IN ('active', 'invited', 'pending_invited', 'pending_active')")
          end

          scope.select("courses.*, enrollments.id AS primary_enrollment_id, enrollments.type AS primary_enrollment_type, enrollments.role_id AS primary_enrollment_role_id, #{Enrollment.type_rank_sql} AS primary_enrollment_rank, enrollments.workflow_state AS primary_enrollment_state, enrollments.created_at AS primary_enrollment_date").
              order(Arel.sql("courses.id, #{Enrollment.type_rank_sql}, #{Enrollment.state_rank_sql}")).
              distinct_on(:id).shard(shards).to_a
        end
        result.dup
      end

      if association == :current_and_invited_courses
        if enrollment_uuid && (pending_course = Course.active.
          select("courses.*, enrollments.type AS primary_enrollment,
                  #{Enrollment.type_rank_sql} AS primary_enrollment_rank,
                  enrollments.workflow_state AS primary_enrollment_state,
                  enrollments.created_at AS primary_enrollment_date").
          joins(:enrollments).
          where(enrollments: { uuid: enrollment_uuid, workflow_state: 'invited' }).first)
          res << pending_course
          res.uniq!
        end
        pending_enrollments = temporary_invitations
        unless pending_enrollments.empty?
          ActiveRecord::Associations::Preloader.new.preload(pending_enrollments, :course)
          res.concat(pending_enrollments.map do |e|
            c = e.course
            c.primary_enrollment_type = e.type
            c.primary_enrollment_role_id = e.role_id
            c.primary_enrollment_rank = e.rank_sortable
            c.primary_enrollment_state = e.workflow_state
            c.primary_enrollment_date = e.created_at
            c.invitation = e.uuid
            c
          end)
          res.uniq!
        end
      end

      @courses_with_primary_enrollment[cache_key] =
        res.sort_by{ |c| [c.primary_enrollment_rank, Canvas::ICU.collation_key(c.name)] }
    end
  end

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

   # http://github.com/seamusabshere/cacheable/blob/master/lib/cacheable.rb from the cacheable gem
   # to get a head start

  # this method takes an optional {:include_enrollment_uuid => uuid}   so that you can pass it the session[:enrollment_uuid] and it will include it.
  def cached_current_enrollments(opts={})
    RequestCache.cache('cached_current_enrollments', self, opts) do
      enrollments = self.shard.activate do
        res = Rails.cache.fetch([self, 'current_enrollments3', opts[:include_future], ApplicationController.region ].cache_key) do
          scope = (opts[:include_future] ? self.enrollments.current_and_future : self.enrollments.current_and_invited)
          scope.shard(in_region_associated_shards).to_a
        end
        if opts[:include_enrollment_uuid] && !res.find { |e| e.uuid == opts[:include_enrollment_uuid] } &&
            (pending_enrollment = Enrollment.where(uuid: opts[:include_enrollment_uuid], workflow_state: "invited").first)
          res << pending_enrollment
        end
        res
      end + temporary_invitations

      if opts[:preload_dates]
        Canvas::Builders::EnrollmentDateBuilder.preload_state(enrollments)
      end
      if opts[:preload_courses]
        ActiveRecord::Associations::Preloader.new.preload(enrollments, :course)
      end
      enrollments
    end
  end

  def cached_invitations(opts={})
    enrollments = Rails.cache.fetch([self, 'invited_enrollments', ApplicationController.region ].cache_key) do
      self.enrollments.shard(in_region_associated_shards).invited_by_date.
        joins(:course).where.not(courses: {workflow_state: 'deleted'}).to_a
    end
    if opts[:include_enrollment_uuid] && !enrollments.find { |e| e.uuid == opts[:include_enrollment_uuid] } &&
      (pending_enrollment = Enrollment.invited_by_date.where(uuid: opts[:include_enrollment_uuid]).first)
      enrollments << pending_enrollment
    end
    enrollments += temporary_invitations
    ActiveRecord::Associations::Preloader.new.preload(enrollments, :course) if opts[:preload_course]
    enrollments
  end

  def has_active_enrollment?
    # don't need an expires_at here because user will be touched upon enrollment activation
    Rails.cache.fetch([self, 'has_active_enrollment', ApplicationController.region ].cache_key) do
      self.enrollments.shard(in_region_associated_shards).current.active_by_date.exists?
    end
  end

  def has_future_enrollment?
    Rails.cache.fetch([self, 'has_future_enrollment', ApplicationController.region ].cache_key, :expires_in => 1.hour) do
      self.enrollments.shard(in_region_associated_shards).active_or_pending_by_date.exists?
    end
  end

  def group_membership_key
    [self, 'current_group_memberships', ApplicationController.region].cache_key
  end

  def cached_current_group_memberships
    @cached_current_group_memberships ||= self.shard.activate do
      Rails.cache.fetch(group_membership_key) do
        self.current_group_memberships.shard(self.in_region_associated_shards).to_a
      end
    end
  end

  def has_student_enrollment?
    Rails.cache.fetch([self, 'has_student_enrollment', ApplicationController.region ].cache_key) do
      self.enrollments.shard(in_region_associated_shards).where(:type => %w{StudentEnrollment StudentViewEnrollment}).
        where.not(:workflow_state => %w{rejected inactive deleted}).exists?
    end
  end

  def participating_student_current_and_concluded_course_ids
    @participating_student_current_and_concluded_course_ids ||=
      participating_course_ids('student_current_and_concluded') do |enrollments|
        enrollments.current_and_concluded.not_inactive_by_date_ignoring_access
      end
  end

  def participating_student_course_ids
    @participating_student_course_ids ||=
      participating_course_ids('student') do |enrollments|
        enrollments.current.active_by_date
      end
  end

  def participating_course_ids(cache_qualifier)
    self.shard.activate do
      cache_path = [self, "participating_#{cache_qualifier}_course_ids", ApplicationController.region]
      Rails.cache.fetch(cache_path.cache_key) do
        enrollments = yield self.enrollments.
          shard(in_region_associated_shards).
          where(type: %w{StudentEnrollment StudentViewEnrollment})
        enrollments.distinct.pluck(:course_id)
      end
    end
  end
  private :participating_course_ids

  def participating_instructor_course_ids
    @participating_instructor_course_ids ||= self.shard.activate do
      Rails.cache.fetch([self, 'participating_instructor_course_ids', ApplicationController.region].cache_key) do
        self.enrollments.shard(in_region_associated_shards).of_instructor_type.current.active_by_date.distinct.pluck(:course_id)
      end
    end
  end

  def participating_enrollments
    @participating_enrollments ||= self.shard.activate do
      Rails.cache.fetch([self, 'participating_enrollments', ApplicationController.region].cache_key) do
        self.enrollments.shard(in_region_associated_shards).current.active_by_date.to_a
      end
    end
  end

  def participated_course_ids
    @participated_course_ids ||= self.shard.activate do
      Rails.cache.fetch([self, 'participated_course_ids', ApplicationController.region].cache_key) do
        self.not_removed_enrollments.shard(in_region_associated_shards).distinct.pluck(:course_id)
      end
    end
  end

  def submissions_for_context_codes(context_codes, opts={})
    return [] unless context_codes.present?

    opts = {limit: 20}.merge(opts.slice(:start_at, :limit))
    shard.activate do
      Rails.cache.fetch([self, 'submissions_for_context_codes', context_codes, opts].cache_key, expires_in: 15.minutes) do
        opts[:start_at] ||= 4.weeks.ago

        Shackles.activate(:slave) do
          submissions = []
          submissions += self.submissions.where("GREATEST(submissions.submitted_at, submissions.created_at) > ?", opts[:start_at]).
            for_context_codes(context_codes).eager_load(:assignment).
            where("submissions.score IS NOT NULL AND assignments.workflow_state=? AND assignments.muted=?", 'published', false).
            order('submissions.created_at DESC').
            limit(opts[:limit]).to_a

          subs_with_comment_scope = Submission.active.where(user_id: self).for_context_codes(context_codes).
            joins(:assignment).
            where(assignments: {muted: false, workflow_state: 'published'}).
            where('last_comment_at > ?', opts[:start_at])
          # have to order by last_updated_at_from_db in another query because of distinct_on in the first one
          submissions += Submission.from(subs_with_comment_scope).limit(opts[:limit]).order("last_comment_at").select("*").to_a

          submissions = submissions.sort_by{|t| t.last_comment_at || t.created_at}.reverse
          submissions = submissions.uniq
          submissions.first(opts[:limit])

          ActiveRecord::Associations::Preloader.new.preload(submissions, [:assignment, :user, :submission_comments])
          submissions
        end
      end
    end
  end

  # This is only feedback for student contexts (unless specific contexts are passed in)
  def recent_feedback(opts={})
    context_codes = opts[:context_codes]
    context_codes ||= if opts[:contexts]
        setup_context_lookups(opts[:contexts])
      else
        self.participating_student_course_ids.map { |id| "course_#{id}" }
      end
    submissions_for_context_codes(context_codes, opts)
  end

  def visible_stream_item_instances(opts={})
    instances = stream_item_instances.where(:hidden => false).order('stream_item_instances.id desc')

    # dont make the query do an stream_item_instances.context_code IN
    # ('course_20033','course_20237','course_20247' ...) if they dont pass any
    # contexts, just assume it wants any context code.
    if opts[:contexts]
      # still need to optimize the query to use a root_context_code.  that way a
      # users course dashboard even if they have groups does a query with
      # "context_code=..." instead of "context_code IN ..."
      instances = instances.polymorphic_where('stream_item_instances.context' => opts[:contexts])
    elsif opts[:context]
      instances = instances.where(:context_type => opts[:context].class.base_class.name, :context_id => opts[:context])
    end

    instances
  end

  # NOTE: excludes submission stream items
  def cached_recent_stream_items(opts={})
    expires_in = 1.day

    # just cache on the user's shard... makes cache invalidation much
    # easier if we visit other shards
    shard.activate do
      if opts[:contexts]
        items = []
        Array(opts[:contexts]).each do |context|
          items.concat(
                     Rails.cache.fetch(StreamItemCache.recent_stream_items_key(self, context.class.base_class.name, context.id),
                                       :expires_in => expires_in) {
                       recent_stream_items(:context => context)
                     })
        end
        items.sort_by(&:id).reverse
      else
        # no context in cache key
        Rails.cache.fetch(StreamItemCache.recent_stream_items_key(self), :expires_in => expires_in) {
          recent_stream_items
        }
      end
    end
  end

  # NOTE: excludes submission stream items
  def recent_stream_items(opts={})
    self.shard.activate do
      Shackles.activate(:slave) do
        visible_instances = visible_stream_item_instances(opts).
          preload(stream_item: :context).
          limit(Setting.get('recent_stream_item_limit', 100))
        visible_instances.map do |sii|
          si = sii.stream_item
          next if si.blank?
          next if si.asset_type == 'Submission'
          next if si.context_type == "Course" && (si.context.concluded? || self.participating_enrollments.none?{|e| e.course_id == si.context_id})
          si.unread = sii.unread?
          si
        end.compact
      end
    end
  end

  def calendar_events_for_contexts(context_codes, opts={})
    event_codes = context_codes
    event_codes += AppointmentGroup.manageable_by(self, context_codes).intersecting(opts[:start_at], opts[:end_at]).map(&:asset_string)
    CalendarEvent.active.for_user_and_context_codes(self, event_codes, []).between(opts[:start_at], opts[:end_at]).
      updated_after(opts[:updated_at])
  end

  def calendar_events_for_calendar(opts={})
    opts = opts.dup
    context_codes = opts[:context_codes] || (opts[:contexts] ? setup_context_lookups(opts[:contexts]) : self.cached_context_codes)
    return [] if !context_codes || context_codes.empty?
    opts[:start_at] ||= 2.weeks.ago
    opts[:end_at] ||= 1.week.from_now

    events = []
    events += calendar_events_for_contexts(context_codes, opts)
    events += Assignment.published.for_context_codes(context_codes).due_between(opts[:start_at], opts[:end_at]).
      updated_after(opts[:updated_at]).with_just_calendar_attributes
    events.sort_by{|e| [e.start_at, Canvas::ICU.collation_key(e.title || CanvasSort::First)] }.uniq
  end

  def upcoming_events(opts={})
    context_codes = opts[:context_codes] || (opts[:contexts] ? setup_context_lookups(opts[:contexts]) : self.cached_context_codes)
    return [] if (!context_codes || context_codes.empty?)

    now = Time.zone.now

    opts[:end_at] ||= 1.weeks.from_now
    opts[:limit] ||= 20

    # if we're looking through a lot of courses, we should probably not spend a lot of time
    # computing which sections are visible or not before we make the db call;
    # instead, i think we should pull for all the sections and filter after the fact
    filter_after_db = !opts[:use_db_filter] &&
      (context_codes.grep(/\Acourse_\d+\z/).count > Setting.get('filter_events_by_section_code_threshold', '25').to_i)

    section_codes = self.section_context_codes(context_codes, filter_after_db)
    limit = filter_after_db ? opts[:limit] * 2 : opts[:limit] # pull extra events just in case
    events = CalendarEvent.active.for_user_and_context_codes(self, context_codes, section_codes).
      between(now, opts[:end_at]).limit(limit).order(:start_at).to_a.reject(&:hidden?)

    if filter_after_db
      original_count = events.count
      if events.any?{|e| e.context_code.start_with?("course_section_")}
        section_ids = events.map(&:context_code).grep(/\Acourse_section_\d+\z/).map{ |s| s.sub(/\Acourse_section_/, '').to_i }
        section_course_codes = Course.joins(:course_sections).where(:course_sections => {:id => section_ids}).
          pluck(:id).map{|id| "course_#{id}"}
        visible_section_codes = self.section_context_codes(section_course_codes)
        events.reject!{|e| e.context_code.start_with?("course_section_") && !visible_section_codes.include?(e.context_code)}
        events = events.first(opts[:limit]) # strip down to the original limit
      end

      # if we've filtered too many (which should be unlikely), just fallback on the old behavior
      if original_count >= opts[:limit] && events.count < opts[:limit]
        return self.upcoming_events(opts.merge(:use_db_filter => true))
      end
    end

    assignments = Assignment.published.
      for_context_codes(context_codes).
      due_between_with_overrides(now, opts[:end_at]).
      include_submitted_count

    if assignments.any?
      if AssignmentOverrideApplicator.should_preload_override_students?(assignments, self, "upcoming_events")
        AssignmentOverrideApplicator.preload_assignment_override_students(assignments, self)
      end

      events += select_available_assignments(
        select_upcoming_assignments(assignments.map {|a| a.overridden_for(self)}, opts.merge(:time => now))
      )

    end
    events.sort_by{|e| [e.start_at ? 0: 1,e.start_at || 0, Canvas::ICU.collation_key(e.title)] }.uniq.first(opts[:limit])
  end

  def select_available_assignments(assignments, opts = {})
    return [] if assignments.empty?
    available_course_ids = if opts[:include_concluded]
                            participated_course_ids
                          else
                            Shard.partition_by_shard(assignments.map(&:context_id).uniq) do |course_ids|
                              self.enrollments.shard(Shard.current).where(course_id: course_ids).active_by_date.pluck(:course_id)
                            end
                          end

    assignments.select {|a| available_course_ids.include?(a.context_id) }
  end

  def select_upcoming_assignments(assignments,opts)
    time = opts[:time] || Time.zone.now
    assignments.select do |a|
      if a.grants_right?(self, :delete)
        a.dates_hash_visible_to(self).any? do |due_hash|
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
    undated_events += Assignment.published.for_context_codes(context_codes).undated.updated_after(opts[:updated_at]).with_just_calendar_attributes
    Canvas::ICU.collate_by(undated_events, &:title)
  end

  def setup_context_lookups(contexts)
    # TODO: All the event methods use this and it's really slow.
    Array(contexts).map(&:asset_string)
  end

  def cached_context_codes
    # (hopefully) don't need to include cross-shard because calendar events/assignments/etc are only seached for on current shard anyway
    @cached_context_codes ||=
      Rails.cache.fetch([self, 'cached_context_codes', Shard.current].cache_key, :expires_in => 15.minutes) do
        group_ids = self.groups.active.pluck(:id)
        cached_current_course_ids = Rails.cache.fetch([self, 'cached_current_course_ids', Shard.current].cache_key) do
          # don't need an expires at because user will be touched if enrollment state changes from 'active'
          self.enrollments.shard(Shard.current).current.active_by_date.distinct.pluck(:course_id)
        end

        cached_current_course_ids.map{|id| "course_#{id}" } + group_ids.map{|id| "group_#{id}"}
      end
  end

  # context codes of things that might have a schedulable appointment for the
  # given user, i.e. courses and sections
  def appointment_context_codes(include_observers: false)
    @appointment_context_codes ||= {}
    @appointment_context_codes[include_observers] ||= Rails.cache.fetch([self, 'cached_appointment_codes', ApplicationController.region, include_observers ].cache_key, expires_in: 1.day) do
      ret = {:primary => [], :secondary => []}
      cached_current_enrollments(preload_dates: true).each do |e|
        next unless (e.student? || (include_observers && e.observer?)) && e.active?
        ret[:primary] << "course_#{e.course_id}"
        ret[:secondary] << "course_section_#{e.course_section_id}"
      end
      ret[:secondary].concat groups.map{ |g| "group_category_#{g.group_category_id}" }
      ret
    end
  end

  def manageable_appointment_context_codes
    @manageable_appointment_context_codes ||= Rails.cache.fetch([self, 'cached_manageable_appointment_codes', ApplicationController.region ].cache_key, expires_in: 1.day) do
      ret = {:full => [], :limited => [], :secondary => []}
      cached_current_enrollments(preload_courses: true).each do |e|
        next unless e.course.grants_right?(self, :manage_calendar)
        if e.course.visibility_limited_to_course_sections?(self)
          ret[:limited] << "course_#{e.course_id}"
          ret[:secondary] << "course_section_#{e.course_section_id}"
        else
          ret[:full] << "course_#{e.course_id}"
        end
      end
      ret
    end
  end

  # Public: Return an array of context codes this user belongs to.
  #
  # include_concluded_codes - If true, include concluded courses (default: true).
  #
  # Returns an array of context code strings.
  def conversation_context_codes(include_concluded_codes = true)
    return @conversation_context_codes[include_concluded_codes] if @conversation_context_codes
    Rails.cache.fetch([self, include_concluded_codes, 'conversation_context_codes4'].cache_key, :expires_in => 1.day) do
      Shard.birth.activate do
        associations = %w{courses concluded_courses current_groups}
        associations.slice!(1) unless include_concluded_codes

        associations.inject([]) do |result, association|
          association_type = association.split('_')[-1].slice(0..-2)
          result.concat(send(association).shard(self).pluck(:id).map { |id| "#{association_type}_#{id}" })
        end.uniq
      end
    end
  end

  def self.convert_global_id_rows(rows)
    rows.map do |row|
      row.map do |id|
        Shard.relative_id_for(id, Shard.current, Shard.birth)
      end
    end
  end

  def self.preload_conversation_context_codes(users)
    users = users.reject { |u| u.instance_variable_get(:@conversation_context_codes) }
    return if users.length < Setting.get("min_users_for_conversation_context_codes_preload", 5).to_i
    preload_shard_associations(users)
    shards = Set.new
    users.each do |user|
      shards.merge(user.associated_shards)
    end

    active_contexts = {}
    concluded_contexts = {}

    Shard.with_each_shard(shards.to_a) do
      course_rows = convert_global_id_rows(
          Enrollment.joins(:course).
              where(User.enrollment_conditions(:active)).
              where(user_id: users).
              distinct.pluck(:user_id, :course_id))
      course_rows.each do |user_id, course_id|
        active_contexts[user_id] ||= []
        active_contexts[user_id] << "course_#{course_id}"
      end

      cc_rows = convert_global_id_rows(
          Enrollment.joins(:course).
              where(User.enrollment_conditions(:completed)).
              where(user_id: users).
              distinct.pluck(:user_id, :course_id))
      cc_rows.each do |user_id, course_id|
        concluded_contexts[user_id] ||= []
        concluded_contexts[user_id] << "course_#{course_id}"
      end

      group_rows = convert_global_id_rows(
          GroupMembership.joins(:group).
              merge(User.instance_exec(&User.reflections['current_group_memberships'].scope).only(:where)).
              where(user_id: users).
              distinct.pluck(:user_id, :group_id))
      group_rows.each do |user_id, group_id|
        active_contexts[user_id] ||= []
        active_contexts[user_id] << "group_#{group_id}"
      end
    end
    Shard.birth.activate do
      users.each do |user|
        active = active_contexts[user.id] || []
        concluded = concluded_contexts[user.id] || []
        user.instance_variable_set(:@conversation_context_codes, {
          true => (active + concluded).uniq,
          false => active
        })
      end
    end
  end

  def section_context_codes(context_codes, skip_visibility_filter=false)
    course_ids = context_codes.grep(/\Acourse_\d+\z/).map{ |s| s.sub(/\Acourse_/, '').to_i }
    return [] unless course_ids.present?

    section_ids = []
    if skip_visibility_filter
      full_course_ids = course_ids
    else
      full_course_ids = []
      Course.where(id: course_ids).each do |course|
        result = course.course_section_visibility(self)
        case result
        when Array
          section_ids.concat(result)
        when :all
          full_course_ids << course.id
        end
      end
    end

    if full_course_ids.any?
      current_shard = Shard.current
      Shard.partition_by_shard(full_course_ids) do |shard_course_ids|
        section_ids.concat(CourseSection.active.where(:course_id => shard_course_ids).pluck(:id).
            map{|id| Shard.relative_id_for(id, Shard.current, current_shard)})
      end
    end
    section_ids.map{|id| "course_section_#{id}"}
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
    folder = self.active_folders.where(name: name).first
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
    Setting.get('user_default_quota', 50.megabytes.to_s).to_i
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

  def roles(root_account, exclude_deleted_accounts = nil)
    # Don't include roles for deleted accounts and don't cache
    # the results.
    return user_roles(root_account, true) if exclude_deleted_accounts

    return @roles if @roles
    root_account.shard.activate do
      @roles = Rails.cache.fetch(['user_roles_for_root_account3', self, root_account].cache_key) do
        user_roles(root_account)
      end
    end
  end

  def eportfolios_enabled?
    accounts = associated_root_accounts.reject(&:site_admin?)
    accounts.size == 0 || accounts.any?{ |a| a.settings[:enable_eportfolios] != false }
  end

  def initiate_conversation(users, private = nil, options = {})
    users = ([self] + users).uniq(&:id)
    private = users.size <= 2 if private.nil?
    Conversation.initiate(users, private, options).conversation_participants.where(user_id: self).first
  end

  def address_book
    @address_book ||= AddressBook.for(self)
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

  def mark_all_conversations_as_read!
    updated = conversations.unread.update_all(:workflow_state => 'read')
    if updated > 0
      User.where(:id => id).update_all(:unread_conversations_count => 0)
    end
  end

  def conversation_participant(conversation_id)
    all_conversations.where(conversation_id: conversation_id).first
  end

  # Public: Reset the user's cached unread conversations count.
  #
  # Returns nothing.
  def reset_unread_conversations_counter
    unread_count = conversations.unread.count
    if self.unread_conversations_count != unread_count
      self.class.where(:id => id).update_all(:unread_conversations_count => unread_count)
    end
  end

  def set_menu_data(enrollment_uuid)
    return @menu_data if @menu_data
    coalesced_enrollments = []

    cached_enrollments = self.cached_current_enrollments(:include_enrollment_uuid => enrollment_uuid, :preload_dates => true)
    cached_enrollments.each do |e|

      next if e.state_based_on_date == :inactive

      if e.state_based_on_date == :completed
        has_completed_enrollment = true
        next
      end

      existing_enrollment_info = coalesced_enrollments.find { |en|
        # coalesce together enrollments for the same course and the same state
        en[:enrollment].course == e.course && en[:enrollment].workflow_state == e.workflow_state
      }

      if existing_enrollment_info
        existing_enrollment_info[:types] << e.readable_type
        existing_enrollment_info[:sortable] = [existing_enrollment_info[:sortable] || CanvasSort::Last, [e.rank_sortable, e.state_sortable, 0 - e.id]].min
      else
        coalesced_enrollments << { :enrollment => e, :sortable => [e.rank_sortable, e.state_sortable, 0 - e.id], :types => [ e.readable_type ] }
      end
    end
    coalesced_enrollments = coalesced_enrollments.sort_by{|e| e[:sortable] }
    active_enrollments = coalesced_enrollments.map{ |e| e[:enrollment] }

    cached_group_memberships = self.cached_current_group_memberships
    coalesced_group_memberships = Canvas::ICU.collate_by(cached_group_memberships.
      select{ |gm| gm.active_given_enrollments?(active_enrollments) }) { |gm| gm.group.name }

    @menu_data = {
      :group_memberships => coalesced_group_memberships,
      :group_memberships_count => cached_group_memberships.length,
      :accounts => self.adminable_accounts,
      :accounts_count => self.adminable_accounts.length,
    }
  end

  # Public: Returns a unique list of favorite context type ids relative to the active shard.
  #
  # Examples
  #
  #   favorite_context_ids("Course")
  #   # => [1, 2, 3, 4]
  #
  # Returns an array of unique global ids.
  def favorite_context_ids(context_type)
    @favorite_context_ids ||= {}

    context_ids = @favorite_context_ids[context_type]
    unless context_ids
      # Only get the users favorites from their shard.
      self.shard.activate do
        # Get favorites and map them to their global ids.
        context_ids = self.favorites.where(context_type: context_type).pluck(:context_id).map { |id| Shard.global_id_for(id) }
        @favorite_context_ids[context_type] = context_ids
      end
    end

    # Return ids relative for the current shard
    context_ids.map { |id|
      Shard.relative_id_for(id, self.shard, Shard.current)
    }
  end

  def menu_courses(enrollment_uuid = nil)
    return @menu_courses if @menu_courses

    favorites = self.courses_with_primary_enrollment(:favorite_courses, enrollment_uuid)
    if favorites.length > 0
      @menu_courses = favorites
    else
      # this terribleness is so we try to make sure that the newest courses show up in the menu
      @menu_courses = self.courses_with_primary_enrollment(:current_and_invited_courses, enrollment_uuid).
        sort_by{ |c| [c.primary_enrollment_rank, Time.now - (c.primary_enrollment_date || Time.now)] }.
        first(Setting.get('menu_course_limit', '20').to_i).
        sort_by{ |c| [c.primary_enrollment_rank, Canvas::ICU.collation_key(c.name)] }
    end
    ActiveRecord::Associations::Preloader.new.preload(@menu_courses, :enrollment_term)
    @menu_courses
  end

  def user_can_edit_name?
    active_pseudonym_accounts.any? { |a| a.settings[:users_can_edit_name] != false } || active_pseudonym_accounts.empty?
  end

  def sections_for_course(course)
    course.student_enrollments.active.for_user(self).map { |e| e.course_section }
  end

  def can_create_enrollment_for?(course, session, type)
    return false if type == "StudentEnrollment" && MasterCourses::MasterTemplate.is_master_course?(course)
    if type != "StudentEnrollment" && course.grants_right?(self, session, :manage_admin_users)
      return true
    end
    if course.grants_right?(self, session, :manage_students)
      if %w{StudentEnrollment ObserverEnrollment}.include?(type) || (type == 'TeacherEnrollment' && course.teacherless?)
        return true
      end
    end
  end

  def can_be_enrolled_in_course?(course)
    !!SisPseudonym.for(self, course, type: :implicit, require_sis: false) ||
        (self.creation_pending? && self.enrollments.where(course_id: course).exists?)
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

  # account = the account that you want a pseudonym for
  # preferred_template_account = pass in an actual account if you have a preference for which account the new pseudonym gets copied from
  # this may not be able to find a suitable pseudonym to copy, so would still return nil
  # if a pseudonym is created, it is *not* saved, and *not* added to the pseudonyms collection
  def find_or_initialize_pseudonym_for_account(account, preferred_template_account = nil)
    pseudonym = SisPseudonym.for(self, account, type: :trusted, require_sis: false)
    unless pseudonym
      # list of copyable pseudonyms
      active_pseudonyms = self.all_active_pseudonyms(:reload).select { |p| !p.password_auto_generated? && !p.account.delegated_authentication? }
      templates = []
      # re-arrange in the order we prefer
      templates.concat active_pseudonyms.select { |p| p.account_id == preferred_template_account.id } if preferred_template_account
      templates.concat active_pseudonyms.select { |p| p.account_id == Account.site_admin.id }
      templates.concat active_pseudonyms.select { |p| p.account_id == Account.default.id }
      templates.concat active_pseudonyms
      templates.uniq!

      template = templates.detect { |template| !account.pseudonyms.active.by_unique_id(template.unique_id).first }
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

  def fake_student?
    self.preferences[:fake_student] && !!self.enrollments.where(:type => 'StudentViewEnrollment').first
  end

  def private?
    not public?
  end

  def profile
    super || build_profile
  end

  def parse_otp_remember_me_cookie(cookie)
    return 0, [], nil unless cookie
    time, *ips, hmac = cookie.split('-')
    [time, ips, hmac]
  end

  def otp_secret_key_remember_me_cookie(time, current_cookie, remote_ip = nil, options = {})
    _, ips, _ = parse_otp_remember_me_cookie(current_cookie)
    cookie = [time.to_i, *[*ips, remote_ip].compact.sort].join('-')

    hmac_string = "#{cookie}.#{self.otp_secret_key}"
    return hmac_string if options[:hmac_string]
    "#{cookie}-#{Canvas::Security.hmac_sha1(hmac_string)}"
  end

  def validate_otp_secret_key_remember_me_cookie(value, remote_ip = nil)
    time, ips, hmac = parse_otp_remember_me_cookie(value)
    time.to_i >= (Time.now.utc - 30.days).to_i &&
        (remote_ip.nil? || ips.include?(remote_ip)) &&
        Canvas::Security.verify_hmac_sha1(hmac, otp_secret_key_remember_me_cookie(time, value, nil, hmac_string: true))
  end

  def otp_secret_key
    return nil unless otp_secret_key_enc
    Canvas::Security::decrypt_password(otp_secret_key_enc, otp_secret_key_salt, 'otp_secret_key', self.shard.settings[:encryption_key]) if otp_secret_key_enc
  end

  def otp_secret_key=(key)
    if key
      self.otp_secret_key_enc, self.otp_secret_key_salt = Canvas::Security::encrypt_password(key, 'otp_secret_key')
    else
      self.otp_secret_key_enc = self.otp_secret_key_salt = nil
    end
    key
  end

  def crocodoc_id!
    cid = read_attribute(:crocodoc_id)
    return cid if cid

    Setting.transaction do
      s = Setting.lock.where(name: 'crocodoc_counter').first_or_create(value: 0)
      cid = s.value = s.value.to_i + 1
      s.save!
    end

    update_attribute(:crocodoc_id, cid)
    cid
  end

  def crocodoc_user
    "#{crocodoc_id!},#{short_name.delete(',')}"
  end

  def moderated_grading_ids(create_crocodoc_id=false)
    {
      crocodoc_id: create_crocodoc_id ? crocodoc_id! : crocodoc_id,
      global_id: global_id.to_s
    }
  end

  # mfa settings for a user are the most restrictive of any pseudonyms the user has
  # a login for
  def mfa_settings(pseudonym_hint: nil)
    # try to short-circuit site admins where it is required
    if pseudonym_hint
      mfa_settings = pseudonym_hint.account.mfa_settings
      return :required if mfa_settings == :required ||
          mfa_settings == :required_for_admins && !pseudonym_hint.account.all_account_users_for(self).empty?
    end

    result = self.pseudonyms.shard(self).preload(:account).map(&:account).uniq.map do |account|
      case account.mfa_settings
        when :disabled
          0
        when :optional
          1
        when :required_for_admins
          # if pseudonym_hint is given, and we got to here, we don't need
          # to redo the expensive all_account_users_for check
          if (pseudonym_hint && pseudonym_hint.account == account) ||
              account.all_account_users_for(self).empty?
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

  def self.preload_shard_associations(users)
  end

  def associated_shards(strength = :strong)
    [Shard.default]
  end

  def in_region_associated_shards
    associated_shards.select { |shard| shard.in_current_region? || shard.default? }
  end

  def adminable_accounts_scope
    Account.shard(self.in_region_associated_shards).active.joins(:account_users).
      where(account_users: {user_id: self.id}).
      where.not(account_users: {workflow_state: 'deleted'})
  end

  def adminable_accounts
    @adminable_accounts ||= shard.activate do
      Rails.cache.fetch(['adminable_accounts_1', self, ApplicationController.region].cache_key) do
        adminable_accounts_scope.order(Account.best_unicode_collation_key('name'), :id).to_a
      end
    end
  end

  def all_paginatable_accounts
    ShardedBookmarkedCollection.build(Account::Bookmarker, self.adminable_accounts_scope.order(:name, :id))
  end

  def all_pseudonyms_loaded?
    !!@all_pseudonyms
  end

  def all_pseudonyms
    @all_pseudonyms ||= self.pseudonyms.shard(self).to_a
  end

  def all_active_pseudonyms_loaded?
    !!@all_active_pseudonyms
  end

  def current_active_groups?
    return true if self.current_groups.preload(:context).any?(&:context_available?)
    return true if self.current_groups.shard(self.in_region_associated_shards).preload(:context).any?(&:context_available?)
    false
  end

  def all_active_pseudonyms(reload=false)
    @all_active_pseudonyms = nil if reload
    @all_active_pseudonyms ||= self.pseudonyms.shard(self).active.to_a
  end

  def preferred_gradebook_version
    preferences.fetch(:gradebook_version, 'default')
  end

  def stamp_logout_time!
    User.where(:id => self).update_all(:last_logged_out => Time.zone.now)
  end

  def content_exports_visible_to(user)
    self.content_exports.where(user_id: user)
  end

  def show_bouncing_channel_message!
    unless show_bouncing_channel_message?
      self.preferences[:show_bouncing_channel_message] = true
      self.save!
    end
  end

  def show_bouncing_channel_message?
    !!self.preferences[:show_bouncing_channel_message]
  end

  def dismiss_bouncing_channel_message!
    if show_bouncing_channel_message?
      self.preferences[:show_bouncing_channel_message] = false
      self.save!
    end
  end

  def bouncing_channel_message_dismissed?
    self.preferences[:show_bouncing_channel_message] == false
  end

  def update_bouncing_channel_message!(channel=nil)
    force_set_bouncing = channel && channel.bouncing? && !channel.imported?
    set_bouncing = force_set_bouncing || self.communication_channels.unretired.any? { |cc| cc.bouncing? && !cc.imported? }

    if force_set_bouncing
      show_bouncing_channel_message!
    elsif set_bouncing
      show_bouncing_channel_message! unless bouncing_channel_message_dismissed?
    else
      dismiss_bouncing_channel_message!
    end
  end

  def locale
    result = super
    result = nil unless I18n.locale_available?(result)
    result
  end

  def submissions_folder(for_course = nil)
    shard.activate do
      if for_course
        parent_folder = self.submissions_folder
        Folder.unique_constraint_retry do
          self.folders.where(parent_folder_id: parent_folder, submission_context_code: for_course.asset_string).
            first_or_create!(name: for_course.name)
        end
      else
        return @submissions_folder if @submissions_folder
        Folder.unique_constraint_retry do
          @submissions_folder = self.folders.where(parent_folder_id: Folder.root_folders(self).first,
                                                   submission_context_code: 'root').
            first_or_create!(name: I18n.t('Submissions', locale: self.locale))
        end
      end
    end
  end

  def authenticate_one_time_password(code)
    result = one_time_passwords.where(code: code, used: false).take
    return unless result
    # atomically update used
    return unless one_time_passwords.where(used: false, id: result).update_all(used: true, updated_at: Time.now.utc) == 1
    result
  end

  def generate_one_time_passwords(regenerate: false)
    regenerate ||= !one_time_passwords.exists?
    return unless regenerate
    one_time_passwords.scope.delete_all
    Setting.get('one_time_password_count', 10).to_i.times { one_time_passwords.create! }
  end

  def user_roles(root_account, exclude_deleted_accounts = nil)
    roles = ['user']
    enrollment_types = root_account.all_enrollments.where(user_id: self, workflow_state: 'active').distinct.pluck(:type)
    roles << 'student' unless (enrollment_types & %w[StudentEnrollment StudentViewEnrollment]).empty?
    roles << 'teacher' unless (enrollment_types & %w[TeacherEnrollment TaEnrollment DesignerEnrollment]).empty?
    roles << 'observer' unless (enrollment_types & %w[ObserverEnrollment]).empty?
    account_users = root_account.all_account_users_for(self)

    if exclude_deleted_accounts
      account_users = account_users.select { |a| a.account.workflow_state == 'active' }
    end

    if account_users.any?
      roles << 'admin'
      root_ids = [root_account.id,  Account.site_admin.id]
      roles << 'root_admin' if account_users.any?{|au| root_ids.include?(au.account_id) }
    end
    roles
  end

  # user tokens are returned by UserListV2 and used to bulk-enroll users using information that isn't easy to guess
  def self.token(id, uuid)
    "#{id}_#{Digest::MD5.hexdigest(uuid)}"
  end

  def token
    User.token(id, uuid)
  end

  def self.from_tokens(tokens)
    id_token_map = tokens.each_with_object({}) do |token, map|
      id, huuid = token.split('_')
      id = Shard.relative_id_for(id, Shard.current, Shard.current)
      map[id] = "#{id}_#{huuid}"
    end
    User.where(:id => id_token_map.keys).to_a.select { |u| u.token == id_token_map[u.id] }
  end
end
