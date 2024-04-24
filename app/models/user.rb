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

class User < ActiveRecord::Base
  GRAVATAR_PATTERN = %r{^https?://[a-zA-Z0-9.-]+\.gravatar\.com/}
  MAX_ROOT_ACCOUNT_ID_SYNC_ATTEMPTS = 5
  MINIMAL_COLUMNS_TO_SAVE = %i[avatar_image_source
                               avatar_image_url
                               created_at
                               id
                               initial_enrollment_type
                               lti_id
                               name
                               preferences
                               reminder_time_for_due_dates
                               reminder_time_for_grading
                               short_name
                               sortable_name
                               uuid
                               workflow_state].freeze

  include ManyRootAccounts
  include TurnitinID
  include Pronouns

  # this has to be before include Context to prevent a circular dependency in Course
  def self.sortable_name_order_by_clause(table = nil)
    col = table ? "#{table}.sortable_name" : "sortable_name"
    best_unicode_collation_key(col)
  end

  # this has to be before include Context to prevent a circular dependency in Course
  def self.name_order_by_clause(table = nil)
    col = table ? "#{table}.name" : "name"
    best_unicode_collation_key(col)
  end

  include Context
  include ModelCache
  include UserLearningObjectScopes
  include PermissionsHelper

  attr_accessor :previous_id, :gradebook_importer_submissions, :prior_enrollment, :override_lti_id_lock

  before_save :infer_defaults
  before_validation :ensure_lti_id, on: :update
  after_create :set_default_feature_flags
  after_update :clear_cached_short_name, if: ->(user) { user.saved_change_to_short_name? || (user.read_attribute(:short_name).nil? && user.saved_change_to_name?) }
  validate :preserve_lti_id, on: :update

  serialize :preferences
  include TimeZoneHelper
  time_zone_attribute :time_zone
  include Workflow
  include UserPreferenceValue::UserMethods # include after other callbacks are defined

  def self.enrollment_conditions(state)
    Enrollment::QueryBuilder.new(state).conditions or raise "invalid enrollment conditions"
  end

  has_many :communication_channels, -> { order("communication_channels.position ASC") }, dependent: :destroy, inverse_of: :user
  has_many :notification_policies, through: :communication_channels
  has_many :notification_policy_overrides, through: :communication_channels
  has_one :communication_channel, -> { unretired.ordered }
  has_many :ignores
  has_many :planner_notes, dependent: :destroy
  has_many :viewed_submission_comments, dependent: :destroy

  has_many :enrollments, dependent: :destroy
  has_many :course_paces, dependent: :destroy

  has_many :not_ended_enrollments, -> { where("enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted', 'inactive')") }, class_name: "Enrollment", multishard: true
  has_many :not_removed_enrollments, -> { where.not(workflow_state: %w[rejected deleted inactive]) }, class_name: "Enrollment", multishard: true
  has_many :observer_enrollments
  has_many :observee_enrollments, foreign_key: :associated_user_id, class_name: "ObserverEnrollment"

  has_many :observer_pairing_codes, -> { where("workflow_state<>'deleted' AND expires_at > ?", Time.zone.now) }, dependent: :destroy, inverse_of: :user

  has_many :as_student_observation_links,
           -> { where.not(workflow_state: "deleted") },
           class_name: "UserObservationLink",
           foreign_key: :user_id,
           dependent: :destroy,
           inverse_of: :student
  has_many :as_observer_observation_links,
           -> { where.not(workflow_state: "deleted") },
           class_name: "UserObservationLink",
           foreign_key: :observer_id,
           dependent: :destroy,
           inverse_of: :observer

  has_many :as_student_observer_alert_thresholds,
           -> { where.not(workflow_state: "deleted") },
           class_name: "ObserverAlertThreshold",
           foreign_key: :user_id,
           dependent: :destroy,
           inverse_of: :student
  has_many :as_student_observer_alerts,
           -> { where.not(workflow_state: "deleted") },
           class_name: "ObserverAlert",
           foreign_key: :user_id,
           dependent: :destroy,
           inverse_of: :student

  has_many :as_observer_observer_alert_thresholds,
           -> { where.not(workflow_state: "deleted") },
           class_name: "ObserverAlertThreshold",
           foreign_key: :observer_id,
           dependent: :destroy,
           inverse_of: :observer
  has_many :as_observer_observer_alerts,
           -> { where.not(workflow_state: "deleted") },
           class_name: "ObserverAlert",
           foreign_key: :observer_id,
           dependent: :destroy,
           inverse_of: :observer

  has_many :linked_observers, -> { distinct }, through: :as_student_observation_links, source: :observer, class_name: "User"
  has_many :linked_students, -> { distinct }, through: :as_observer_observation_links, source: :student, class_name: "User"

  has_many :all_courses, source: :course, through: :enrollments
  has_many :all_courses_for_active_enrollments, -> { Enrollment.active }, source: :course, through: :enrollments
  has_many :group_memberships, -> { preload(:group) }, dependent: :destroy
  has_many :groups, -> { where("group_memberships.workflow_state<>'deleted'") }, through: :group_memberships
  has_many :polls, class_name: "Polling::Poll"

  has_many :current_group_memberships, -> { eager_load(:group).where("group_memberships.workflow_state = 'accepted' AND groups.workflow_state<>'deleted'") }, class_name: "GroupMembership"
  has_many :current_groups, through: :current_group_memberships, source: :group
  has_many :user_account_associations
  has_many :unordered_associated_accounts, source: :account, through: :user_account_associations
  has_many :associated_accounts, -> { order("user_account_associations.depth") }, source: :account, through: :user_account_associations
  has_many :associated_root_accounts, -> { merge(Account.root_accounts.active) }, source: :account, through: :user_account_associations, multishard: true
  has_many :developer_keys
  has_many :access_tokens, -> { where(workflow_state: "active") }, inverse_of: :user, multishard: true
  has_many :masquerade_tokens, -> { where(workflow_state: "active") }, class_name: "AccessToken", inverse_of: :real_user
  has_many :notification_endpoints, -> { merge(AccessToken.active) }, through: :access_tokens, multishard: true
  has_many :context_external_tools, -> { order(:name) }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :lti_results, inverse_of: :user, class_name: "Lti::Result", dependent: :destroy

  has_many :student_enrollments
  has_many :ta_enrollments
  has_many :teacher_enrollments, -> { where(enrollments: { type: "TeacherEnrollment" }) }, class_name: "TeacherEnrollment"
  has_many :all_submissions, -> { preload(:assignment, :submission_comments).order(updated_at: :desc) }, class_name: "Submission", dependent: :destroy
  has_many :submissions, -> { active.preload(:assignment, :submission_comments, :grading_period).order(updated_at: :desc) }
  has_many :pseudonyms, -> { ordered }, dependent: :destroy
  has_many :active_pseudonyms, -> { where("pseudonyms.workflow_state<>'deleted'") }, class_name: "Pseudonym"
  has_many :pseudonym_accounts, source: :account, through: :pseudonyms
  has_one :pseudonym, -> { where("pseudonyms.workflow_state<>'deleted'").ordered }
  has_many :attachments, as: "context", dependent: :destroy
  has_many :active_images, -> { where("attachments.file_state != ? AND attachments.content_type LIKE 'image%'", "deleted").order(:display_name).preload(:thumbnail) }, as: :context, inverse_of: :context, class_name: "Attachment"
  has_many :active_assignments, -> { where("assignments.workflow_state<>'deleted'") }, as: :context, inverse_of: :context, class_name: "Assignment"
  has_many :mentions, inverse_of: :user
  has_many :discussion_entry_drafts, inverse_of: :user
  has_many :discussion_entry_versions, inverse_of: :user
  has_many :all_attachments, as: "context", class_name: "Attachment"
  has_many :assignment_student_visibilities
  has_many :quiz_student_visibilities, class_name: "Quizzes::QuizStudentVisibility"
  has_many :folders, -> { order("folders.name") }, as: :context, inverse_of: :context
  has_many :submissions_folders, -> { where.not(folders: { submission_context_code: nil }) }, as: :context, inverse_of: :context, class_name: "Folder"
  has_many :active_folders, -> { where("folders.workflow_state<>'deleted'").order(:name) }, class_name: "Folder", as: :context, inverse_of: :context
  has_many :calendar_events, -> { preload(:parent_event) }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :eportfolios, dependent: :destroy
  has_many :quiz_submissions, dependent: :destroy, class_name: "Quizzes::QuizSubmission"
  has_many :dashboard_messages, -> { where(to: "dashboard", workflow_state: "dashboard").order("created_at DESC") }, class_name: "Message", dependent: :destroy
  has_many :collaborations, -> { order("created_at DESC") }
  has_many :user_services, -> { order("created_at") }, dependent: :destroy
  has_many :rubric_associations, -> { preload(:rubric).order(created_at: :desc) }, as: :context, inverse_of: :context
  has_many :rubrics
  has_many :context_rubrics, as: :context, inverse_of: :context, class_name: "Rubric"
  has_many :grading_standards, -> { where("workflow_state<>'deleted'") }
  has_many :context_module_progressions
  has_many :assessment_question_bank_users
  has_many :assessment_question_banks, through: :assessment_question_bank_users
  has_many :learning_outcome_results
  has_many :collaborators
  has_many :collaborations, -> { preload(:user, :collaborators) }, through: :collaborators
  has_many :assigned_submission_assessments, -> { preload(:user, submission: :assignment) }, class_name: "AssessmentRequest", foreign_key: "assessor_id"
  has_many :assigned_assessments, class_name: "AssessmentRequest", foreign_key: "assessor_id"
  has_many :web_conference_participants
  has_many :web_conferences, through: :web_conference_participants
  has_many :account_users
  has_many :media_objects, as: :context, inverse_of: :context
  has_many :user_generated_media_objects, class_name: "MediaObject"
  has_many :user_notes
  has_many :content_shares, dependent: :destroy
  has_many :received_content_shares
  has_many :sent_content_shares
  has_many :account_reports, inverse_of: :user
  has_many :stream_item_instances, dependent: :delete_all
  has_many :all_conversations, -> { preload(:conversation) }, class_name: "ConversationParticipant"
  has_many :conversation_batches, -> { preload(:root_conversation_message) }
  has_many :favorites
  has_many :messages
  has_many :sis_batches
  has_many :sis_post_grades_statuses
  has_many :content_migrations, as: :context, inverse_of: :context
  has_many :content_exports, as: :context, inverse_of: :context
  has_many :usage_rights,
           as: :context,
           inverse_of: :context,
           class_name: "UsageRights",
           dependent: :destroy
  has_many :gradebook_csvs, dependent: :destroy, class_name: "GradebookCSV"

  has_one :profile, class_name: "UserProfile"

  has_many :progresses, as: :context, inverse_of: :context
  has_many :one_time_passwords, -> { order(:id) }, inverse_of: :user
  has_many :past_lti_ids, class_name: "UserPastLtiId", inverse_of: :user
  has_many :user_preference_values, inverse_of: :user

  has_many :auditor_authentication_records,
           class_name: "Auditors::ActiveRecord::AuthenticationRecord",
           dependent: :destroy,
           inverse_of: :user
  has_many :auditor_course_records,
           class_name: "Auditors::ActiveRecord::CourseRecord",
           dependent: :destroy,
           inverse_of: :user
  has_many :auditor_student_grade_change_records,
           foreign_key: "student_id",
           class_name: "Auditors::ActiveRecord::GradeChangeRecord",
           dependent: :destroy,
           inverse_of: :student
  has_many :auditor_grader_grade_change_records,
           foreign_key: "grader_id",
           class_name: "Auditors::ActiveRecord::GradeChangeRecord",
           dependent: :destroy,
           inverse_of: :grader
  has_many :auditor_feature_flag_records,
           class_name: "Auditors::ActiveRecord::FeatureFlagRecord",
           dependent: :destroy,
           inverse_of: :user

  has_many :comment_bank_items, -> { where("workflow_state<>'deleted'") }
  has_many :microsoft_sync_partial_sync_changes, class_name: "MicrosoftSync::PartialSyncChange", dependent: :destroy, inverse_of: :user

  has_many :gradebook_filters, inverse_of: :user, dependent: :destroy
  has_many :quiz_migration_alerts, dependent: :destroy

  belongs_to :otp_communication_channel, class_name: "CommunicationChannel"

  belongs_to :merged_into_user, class_name: "User"

  include StickySisFields
  are_sis_sticky :name, :sortable_name, :short_name, :pronouns

  include FeatureFlags

  def conversations
    # i.e. exclude any where the user has deleted all the messages
    all_conversations.visible.order("last_message_at DESC, conversation_id DESC")
  end

  def starred_conversations
    all_conversations.order("updated_at DESC, conversation_id DESC").starred
  end

  def page_views(options = {})
    PageView.for_user(self, options)
  end

  def self.clean_name(name, replacement)
    name.downcase.gsub(replacement, "")
  end

  scope :of_account, ->(account) { joins(:user_account_associations).where(user_account_associations: { account_id: account }).shard(account.shard) }
  scope :recently_logged_in, lambda {
    eager_load(:pseudonyms)
      .where("pseudonyms.current_login_at>?", 1.month.ago)
      .order("pseudonyms.current_login_at DESC")
      .limit(25)
  }
  scope :include_pseudonym, -> { preload(:pseudonym) }
  scope :restrict_to_sections, lambda { |sections|
    if sections.empty?
      all
    else
      where("enrollments.limit_privileges_to_course_section IS NULL OR enrollments.limit_privileges_to_course_section<>? OR enrollments.course_section_id IN (?)", true, sections)
    end
  }
  scope :name_like, lambda { |name, source = ""|
    next none if name.strip.empty?

    scopes = []
    all.primary_shard.activate do
      base_scope = except(:select, :order, :group, :having)
      case source
      when "peer_review"
        cleaned_name = clean_name(name, /[\s,]+/)
        scopes << base_scope.where(wildcard("REPLACE(REPLACE(users.sortable_name, ',', ''), ' ', '')", cleaned_name))
        scopes << base_scope.where(wildcard("REPLACE(users.name, ' ', '')", cleaned_name))
      else
        scopes << base_scope.where(wildcard("users.name", name))
        scopes << base_scope.where(wildcard("users.short_name", name))
        scopes << base_scope.joins(:pseudonyms).where(wildcard("pseudonyms.sis_user_id", name)).where(pseudonyms: { workflow_state: "active" })
        scopes << base_scope.joins(:pseudonyms).where(wildcard("pseudonyms.unique_id", name)).where(pseudonyms: { workflow_state: "active" })
      end
    end

    scopes.map!(&:to_sql)
    from("(#{scopes.join("\nUNION\n")}) users")
  }
  scope :active, -> { where.not(workflow_state: "deleted") }

  scope :has_created_account, -> { where("users.workflow_state NOT IN ('creation_pending', 'deleted')") }

  scope :has_current_student_enrollments, lambda {
    where(Enrollment.joins("JOIN #{Course.quoted_table_name} ON courses.id=enrollments.course_id AND courses.workflow_state='available'")
              .where("enrollments.user_id=users.id AND enrollments.workflow_state IN ('active','invited') AND enrollments.type='StudentEnrollment'")
              .arel.exists)
  }

  scope :not_fake_student, -> { where("enrollments.type <> 'StudentViewEnrollment'") }

  # NOTE: only use for courses with differentiated assignments on
  scope :able_to_see_assignment_in_course_with_da, lambda { |assignment_id, course_id|
    joins(:assignment_student_visibilities)
      .where(assignment_student_visibilities: { assignment_id:, course_id: })
  }

  # NOTE: only use for courses with differentiated assignments on
  scope :able_to_see_quiz_in_course_with_da, lambda { |quiz_id, course_id|
    joins(:quiz_student_visibilities)
      .where(quiz_student_visibilities: { quiz_id:, course_id: })
  }

  scope :observing_students_in_course, lambda { |observee_ids, course_ids|
    joins(:enrollments).where(enrollments: { type: "ObserverEnrollment", associated_user_id: observee_ids, course_id: course_ids, workflow_state: "active" })
  }

  # when an observer is added to a course they get an enrollment where associated_user_id is nil. when they are linked to
  # a student, this first enrollment stays the same, but a new one with an associated_user_id is added. thusly to find
  # course observers, you take the difference between all active observers and active observers with associated users
  scope :observing_full_course, lambda { |course_ids|
    active_observer_scope = joins(:enrollments).where(enrollments: { type: "ObserverEnrollment", course_id: course_ids, workflow_state: "active" })
    users_observing_students = active_observer_scope.where.not(enrollments: { associated_user_id: nil }).pluck(:id)

    if users_observing_students == [] || users_observing_students.nil?
      active_observer_scope
    else
      active_observer_scope.where.not(users: { id: users_observing_students })
    end
  }

  scope :linked_through_root_account, lambda { |root_account|
    where(UserObservationLink.table_name => { root_account_id: [root_account.id, nil] + root_account.trusted_account_ids })
  }

  def reload(*)
    @all_pseudonyms = nil
    @all_active_pseudonyms = nil
    super
  end

  def assignment_and_quiz_visibilities(context)
    RequestCache.cache("assignment_and_quiz_visibilities", self, context) do
      GuardRail.activate(:secondary) do
        { assignment_ids: DifferentiableAssignment.scope_filter(context.assignments, self, context).pluck(:id),
          quiz_ids: DifferentiableAssignment.scope_filter(context.quizzes, self, context).pluck(:id) }
      end
    end
  end

  def self.public_lti_id
    [Canvas::Security.config["lti_iss"], "public_user"].join("/")
  end

  def self.order_by_sortable_name(options = {})
    clause = sortable_name_order_by_clause
    sort_direction = (options[:direction] == :descending) ? "DESC" : "ASC"
    scope = order(Arel.sql("#{clause} #{sort_direction}")).order(Arel.sql("#{table_name}.id #{sort_direction}"))
    if scope.select_values.empty?
      scope = scope.select(arel_table[Arel.star])
    end
    if scope.select_values.present?
      scope = scope.select(clause)
    end
    if scope.group_values.present?
      scope = scope.group(clause)
    end
    scope
  end

  def self.order_by_name(options = {})
    clause = name_order_by_clause(options[:table])
    sort_direction = (options[:direction] == :descending) ? "DESC" : "ASC"
    scope = order(Arel.sql("#{clause} #{sort_direction}")).order(Arel.sql("#{table_name}.id #{sort_direction}"))
    if scope.select_values.empty?
      scope = scope.select(arel_table[Arel.star])
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
    scope = all
    if scope.select_values.blank?
      scope = scope.select("users.*")
    end
    scope.select("MIN(#{Enrollment.type_rank_sql(:student)}) AS enrollment_rank")
         .group(User.connection.group_by(User))
         .order("enrollment_rank")
         .order_by_sortable_name
  end

  scope :with_last_login, lambda {
    select_clause = "MAX(current_login_at) as last_login"
    select_clause = "users.*, #{select_clause}" if select_values.blank?
    select(select_clause)
      .joins("LEFT OUTER JOIN #{Pseudonym.quoted_table_name} ON pseudonyms.user_id = users.id")
      .group("users.id")
  }

  attr_accessor :last_login

  def self.preload_last_login(users, account_id)
    maxes = Pseudonym.active.where(user_id: users).group(:user_id).where(account_id:)
                     .maximum(:current_login_at)
    users.each do |u|
      u.last_login = maxes[u.id]
    end
  end

  scope :for_course_with_last_login, lambda { |course, root_account_id, enrollment_type|
    # add a field to each user that is the aggregated max from current_login_at and last_login_at from their pseudonyms
    select_clause = "MAX(current_login_at) as last_login"
    select_clause = "users.*, #{select_clause}" if select_values.blank?
    scope = select(select_clause).
            # left outer join ensures we get the user even if they don't have a pseudonym
            joins(sanitize_sql([<<~SQL.squish, root_account_id])).where(enrollments: { course_id: course })
              LEFT OUTER JOIN #{Pseudonym.quoted_table_name} ON pseudonyms.user_id = users.id AND pseudonyms.account_id = ?
              INNER JOIN #{Enrollment.quoted_table_name} ON enrollments.user_id = users.id
            SQL
    scope = scope.where("enrollments.workflow_state<>'deleted'")
    scope = scope.where(enrollments: { type: enrollment_type }) if enrollment_type
    # the trick to get unique users
    scope.group("users.id")
  }

  attr_accessor :require_acceptance_of_terms,
                :require_presence_of_name,
                :require_self_enrollment_code,
                :self_enrollment_code,
                :self_enrollment_course,
                :validation_root_account,
                :sortable_name_explicitly_set
  attr_reader :self_enrollment

  validates :name, length: { maximum: maximum_string_length, allow_nil: true }
  validates :short_name, length: { maximum: maximum_string_length, allow_nil: true }
  validates :sortable_name, length: { maximum: maximum_string_length, allow_nil: true }
  validates :name, presence: { if: :require_presence_of_name }
  validates_locale :locale, :browser_locale, allow_nil: true
  validates :terms_of_use, acceptance: { if: :require_acceptance_of_terms, allow_nil: false }
  validates_each :self_enrollment_code do |record, attr, value|
    next unless record.require_self_enrollment_code

    if value.blank?
      record.errors.add(attr, "blank")
    elsif record.validation_root_account
      course = record.validation_root_account.self_enrollment_course_for(value)
      record.self_enrollment_course = course
      if course&.self_enrollment_enabled?
        record.errors.add(attr, "full") if course.self_enrollment_limit_met?
        record.errors.add(attr, "concluded") if course.concluded?("StudentEnrollment")
        record.errors.add(attr, "already_enrolled") if course.user_is_student?(record, include_future: true)
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

  def courses_for_enrollments(enrollment_scope, associated_user = nil, include_completed_courses = true)
    if associated_user && associated_user != self
      join = :observer_enrollments
      scope = Course.active.joins(join)
                    .merge(enrollment_scope.except(:joins))
                    .where(enrollments: { associated_user_id: associated_user.id })
    else
      join = (associated_user == self) ? :enrollments_excluding_linked_observers : :all_enrollments
      scope = Course.active.joins(join).merge(enrollment_scope.except(:joins)).distinct
    end

    unless include_completed_courses
      scope = scope.joins(join => :enrollment_state)
                   .where(enrollment_states: { restricted_access: false })
                   .where("enrollment_states.state IN ('active', 'invited', 'pending_invited', 'pending_active')")
    end
    scope
  end

  def courses
    courses_for_enrollments(enrollments.current)
  end

  def current_and_invited_courses(associated_user = nil)
    courses_for_enrollments(enrollments.current_and_invited, associated_user)
  end

  def concluded_courses
    courses_for_enrollments(enrollments.concluded)
  end

  def current_and_concluded_courses
    courses_for_enrollments(enrollments.current_and_concluded)
  end

  def self.skip_updating_account_associations
    @skip_updating_account_associations = true
    yield
  ensure
    @skip_updating_account_associations = false
  end

  def self.skip_updating_account_associations?
    !!@skip_updating_account_associations
  end

  # Update the root_account_ids column on the user
  # and all the users CommunicationChannels
  def update_root_account_ids
    refreshed_root_account_ids = Set.new

    if fake_student?
      # We don't need to worry about relative ids here because test students are never cross-shard
      refreshed_root_account_ids << enrollments.where(type: "StudentViewEnrollment").pick(:root_account_id)
    else
      # See User#associated_shards in MRA for an explanation of
      # shard association levels
      shards = associated_shards(:strong) + associated_shards(:weak)

      Shard.with_each_shard(shards) do
        root_account_ids = user_account_associations.for_root_accounts.shard(Shard.current).distinct.pluck(:account_id)
        root_account_ids.concat(if deleted? || creation_pending?
                                  # if the user is deleted, they'll have no user_account_associations, so we need to add
                                  # back in associations from both active and deleted objects
                                  pseudonyms.shard(Shard.current).except(:order).distinct.pluck(:account_id) +
                                  enrollments.shard(Shard.current).distinct.pluck(:root_account_id) +
                                  account_users.shard(Shard.current).distinct.pluck(:root_account_id)
                                else
                                  # need to add back in deleted associations
                                  pseudonyms.deleted.shard(Shard.current).except(:order).distinct.pluck(:account_id) +
                                  enrollments.deleted.shard(Shard.current).distinct.pluck(:root_account_id) +
                                  account_users.deleted.shard(Shard.current).distinct.pluck(:root_account_id)
                                end)
        root_account_ids.each do |account_id|
          refreshed_root_account_ids << Shard.relative_id_for(account_id, Shard.current, shard)
        end
      end
    end

    # Update the user
    self.root_account_ids = refreshed_root_account_ids.to_a.sort
    if root_account_ids_changed?
      save!
      # Update each communication channel associated with the user
      communication_channels.update_all(root_account_ids:)
    end
  end

  def update_root_account_ids_later
    delay(max_attempts: MAX_ROOT_ACCOUNT_ID_SYNC_ATTEMPTS).update_root_account_ids
  end

  def update_account_associations_later
    delay_if_production.update_account_associations unless self.class.skip_updating_account_associations?
  end

  def update_account_associations_if_necessary
    update_account_associations if !self.class.skip_updating_account_associations? && saved_change_to_workflow_state? && id_before_last_save
  end

  def update_account_associations(opts = nil)
    opts ||= { all_shards: true }
    # incremental is only for the current shard
    return User.update_account_associations([self], opts) if opts[:incremental]

    shard.activate do
      User.update_account_associations([self], opts)
    end
  end

  def enrollments_for_account_and_sub_accounts(account)
    # enrollments are always on the course's shard
    # and courses are always on the root account's shard
    account.shard.activate do
      Enrollment.where(user_id: self).active.joins(:course).where("courses.account_id=? OR courses.root_account_id=?", account, account)
    end
  end

  def self.add_to_account_chain_cache(account_id, account_chain_cache)
    if account_id.is_a? Account
      account = account_id
      account_id = account.id
    end
    return account_chain_cache[account_id] if account_chain_cache.key?(account_id)

    account ||= Account.find(account_id)
    return account_chain_cache[account.id] = [account.id] if account.root_account?

    account_chain_cache[account.id] = [account.id] + add_to_account_chain_cache(account.parent_account_id, account_chain_cache)
  end

  def self.calculate_account_associations_from_accounts(starting_account_ids, account_chain_cache = {})
    results = {}
    remaining_ids = []
    starting_account_ids.each do |account_id|
      unless account_chain_cache.key? account_id
        remaining_ids << account_id
        next
      end
      account_chain = account_chain_cache[account_id]
      account_chain.each_with_index do |a_id, idx|
        results[a_id] ||= idx
        results[a_id] = idx if idx < results[a_id]
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

  def self.update_account_associations(users_or_user_ids, opts = {})
    return if users_or_user_ids.empty?

    opts.reverse_merge! account_chain_cache: {}
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
    unless precalculated_associations
      users = if users_or_user_ids.first.is_a?(User)
                users_or_user_ids
              else
                users_or_user_ids = User.select(%i[id preferences workflow_state updated_at]).where(id: user_ids).to_a
              end

      if opts[:all_shards]
        shards = Set.new
        users.each { |u| shards += u.associated_shards }
        shards = shards.to_a
      end

      # Users are tied to accounts a couple ways:
      #   Through enrollments:
      #      User -> Enrollment -> Section -> Course -> Account
      #      User -> Enrollment -> Section -> Non-Xlisted Course -> Account
      #   Through pseudonyms:
      #      User -> Pseudonym -> Account
      #   Through account_users
      #      User -> AccountUser -> Account
      account_mappings = Hash.new { |h, k| h[k] = Set.new }
      base_shard = Shard.current
      Shard.with_each_shard(shards) do
        courses_relation = Course.select("enrollments.user_id", :account_id).distinct
                                 .joins(course_sections: :enrollments)
                                 .where("enrollments.user_id": users)
                                 .where.not("enrollments.workflow_state": [:deleted, :rejected])
                                 .where.not("enrollments.type": "StudentViewEnrollment")
        non_xlist_relation = Course.select("enrollments.user_id", :account_id).distinct
                                   .joins("INNER JOIN #{CourseSection.quoted_table_name} on course_sections.nonxlist_course_id=courses.id")
                                   .joins("INNER JOIN #{Enrollment.quoted_table_name} on enrollments.course_section_id=course_sections.id")
                                   .where("enrollments.user_id": users)
                                   .where.not("enrollments.workflow_state": [:deleted, :rejected])
                                   .where.not("enrollments.type": "StudentViewEnrollment")
        pseudonym_relation = Pseudonym.active.select(:user_id, :account_id).distinct.where(user: users)
        account_user_relation = AccountUser.active.select(:user_id, :account_id).distinct.where(user: users)

        results = connection.select_rows(<<~SQL.squish)
          #{courses_relation.to_sql} UNION
          #{non_xlist_relation.to_sql} UNION
          #{pseudonym_relation.to_sql} UNION
          #{account_user_relation.to_sql}
        SQL

        results.each do |row|
          account_mappings[Shard.relative_id_for(row.first, Shard.current, base_shard)] << Shard.relative_id_for(row.second, Shard.current, base_shard)
        end
      end
    end

    # TODO: transaction on each shard?
    UserAccountAssociation.transaction do
      current_associations = {}
      to_delete = []
      Shard.with_each_shard(shards) do
        # if shards is more than just the current shard, users will be set; otherwise
        # we never loaded users, but it doesn't matter, cause it's all the current shard
        shard_user_ids = users ? users.map(&:id) : user_ids
        UserAccountAssociation.where(user_id: shard_user_ids).to_a
      end.each do |aa|
        key = [aa.user_id, aa.account_id]
        current_associations[key] = [aa.id, aa.depth]
      end

      account_id_to_root_account_id = Account.where(id: precalculated_associations&.keys).pluck(:id, Arel.sql(Account.resolved_root_account_id_sql)).to_h

      users_or_user_ids.uniq.sort_by { |u| u.try(:id) || u }.each do |user_id|
        if user_id.is_a? User
          user = user_id
          user_id = user.id
        end

        account_ids_with_depth = precalculated_associations
        if account_ids_with_depth.nil?
          user ||= User.find(user_id)
          account_ids_with_depth = if %w[creation_pending deleted].include?(user.workflow_state) || user.fake_student?
                                     []
                                   else
                                     calculate_account_associations_from_accounts(account_mappings[user.id], account_chain_cache)
                                   end
        end

        account_ids_with_depth.sort_by(&:first).each do |account_id, depth|
          key = [user_id, account_id]
          association = current_associations[key]
          if association.nil?
            # new association, create it
            aa = UserAccountAssociation.new
            aa.user_id = user_id
            aa.account_id = account_id
            aa.root_account_id = account_id_to_root_account_id[account_id]
            aa.depth = depth
            aa.shard = Shard.shard_for(account_id)
            aa.shard.activate do
              UserAccountAssociation.transaction(requires_new: true) do
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
          else
            # for incremental, only update the old association if it is deeper than the new one
            # for non-incremental, update it if it changed
            if (incremental && association[1] > depth) || (!incremental && association[1] != depth)
              UserAccountAssociation.where(id: association[0]).update_all(depth:)
            end
            # remove from list of existing for non-incremental
            current_associations.delete(key) unless incremental
          end
        end
      end

      to_delete += current_associations.map { |_k, v| v[0] }
      UserAccountAssociation.where(id: to_delete).delete_all unless incremental || to_delete.empty?
    end
  end

  # These methods can be overridden by a plugin if you want to have an approval
  # process or implement additional tracking for new users
  def registration_approval_required?
    false
  end

  def new_registration(form_params = {}); end

  def update_shadow_records_synchronously!; end

  # DEPRECATED, override new_registration instead
  def new_teacher_registration(form_params = {})
    new_registration(form_params)
  end

  def assign_uuid
    # DON'T use ||=, because that will cause an immediate save to the db if it
    # doesn't already exist
    self.uuid = CanvasSlug.generate_securish_uuid unless read_attribute(:uuid)
  end
  protected :assign_uuid

  scope :with_service, lambda { |service|
    service = service.service if service.is_a?(UserService)
    eager_load(:user_services).where(user_services: { service: service.to_s })
  }
  scope :enrolled_before, ->(date) { where("enrollments.created_at<?", date) }

  def group_memberships_for(context)
    groups.where("groups.context_id" => context,
                 "groups.context_type" => context.class.to_s,
                 "group_memberships.workflow_state" => "accepted")
          .where("groups.workflow_state <> 'deleted'")
  end

  # Returns an array of groups which are currently visible for the user.
  def visible_groups
    @visible_groups ||= filter_visible_groups_for_user(current_groups)
  end

  def filter_visible_groups_for_user(groups)
    enrollments = cached_currentish_enrollments(preload_dates: true, preload_courses: true)
    groups.select do |group|
      group.context_type != "Course" || enrollments.any? do |en|
        en.course == group.context && !(en.inactive? || en.completed?) && (en.admin? || en.course.available?)
      end
    end
  end

  def <=>(other)
    name <=> other.name
  end

  def available?
    true
  end

  def participants(_opts = {})
    []
  end

  # compatibility only - this isn't really last_name_first
  def last_name_first
    sortable_name
  end

  def last_name_first_or_unnamed
    res = last_name_first
    res = "No Name" if res.strip.empty?
    res
  end

  def first_name
    User.name_parts(sortable_name, likely_already_surname_first: true)[0] || ""
  end

  def last_name
    User.name_parts(sortable_name, likely_already_surname_first: true)[1] || ""
  end

  # Feel free to add, but the "authoritative" list (http://en.wikipedia.org/wiki/Title_(name)) is quite large
  SUFFIXES = /^(Sn?r\.?|Senior|Jn?r\.?|Junior|II|III|IV|V|VI|Esq\.?|Esquire)$/i

  # see also user_sortable_name.js
  def self.name_parts(name, prior_surname: nil, likely_already_surname_first: false)
    return [nil, nil, nil] unless name

    surname, given, suffix = name.strip.split(/\s*,\s*/, 3)

    # Doe, John, Sr.
    # Otherwise change Ho, Chi, Min to Ho, Chi Min
    if suffix && suffix !~ SUFFIXES
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
    surname = given_parts.pop(prior_surname_parts.length).join(" ") if !surname && prior_surname.present? && (prior_surname_parts = prior_surname.split) && !prior_surname_parts.empty? && given_parts.length >= prior_surname_parts.length && given_parts[-prior_surname_parts.length..] == prior_surname_parts
    # Last resort; last name is just the last word given
    surname = given_parts.pop if !surname && given_parts.length > 1

    [given_parts.empty? ? nil : given_parts.join(" "), surname, suffix]
  end

  def self.last_name_first(name, name_was = nil, likely_already_surname_first:)
    previous_surname = name_parts(name_was, likely_already_surname_first:)[1]
    given, surname, suffix = name_parts(name, prior_surname: previous_surname)
    given = [given, suffix].compact.join(" ")
    surname ? "#{surname}, #{given}".strip : given
  end

  def infer_defaults
    self.name = nil if name == "User"
    self.name ||= email || t("#user.default_user_name", "User")
    self.short_name = nil if short_name == ""
    self.short_name ||= self.name
    self.sortable_name = nil if sortable_name == ""
    # recalculate the sortable name if the name changed, but the sortable name didn't, and the sortable_name matches the old name
    self.sortable_name = nil if !sortable_name_changed? &&
                                !sortable_name_explicitly_set &&
                                name_changed? &&
                                User.name_parts(sortable_name, likely_already_surname_first: true).compact.join(" ") == name_was
    unless read_attribute(:sortable_name)
      self.sortable_name = User.last_name_first(self.name, sortable_name_was, likely_already_surname_first: true)
    end
    self.reminder_time_for_due_dates ||= 48.hours.to_i
    self.reminder_time_for_grading ||= 0
    self.initial_enrollment_type = nil unless %w[student teacher ta observer].include?(initial_enrollment_type)
    self.lti_id ||= SecureRandom.uuid
    true
  end

  # Because some user's can have old lti ids that differ from self.lti_id,
  # which also depends on the current context.
  def lookup_lti_id(context)
    old_lti_id = context.shard.activate do
      past_lti_ids.where(context:).take&.user_lti_id
    end
    old_lti_id || self.lti_id
  end

  def preserve_lti_id
    errors.add(:lti_id, "Cannot change lti_id!") if lti_id_changed? && !lti_id_was.nil? && !override_lti_id_lock
  end

  def ensure_lti_id
    self.lti_id ||= SecureRandom.uuid
  end

  def set_default_feature_flags
    enable_feature!(:new_user_tutorial_on_off) unless Rails.env.test?
  end

  def sortable_name
    self.sortable_name = read_attribute(:sortable_name) ||
                         User.last_name_first(self.name, likely_already_surname_first: false)
  end

  def primary_pseudonym
    pseudonyms.active.first
  end

  def primary_pseudonym=(p)
    p = Pseudonym.find(p)
    p.move_to_top
    reload
  end

  def email_channel
    # It's already ordered, so find the first one, if there's one.
    if communication_channels.loaded?
      communication_channels.to_a.find { |cc| cc.path_type == "email" && cc.workflow_state != "retired" }
    else
      communication_channels.email.unretired.first
    end
  end

  def email
    shard.activate do
      value = Rails.cache.fetch(email_cache_key) do
        email_channel.try(:path) || :none
      end
      # this sillyness is because rails equates falsey as not in the cache
      (value == :none) ? nil : value
    end
  end

  def email_cache_key
    ["user_email", global_id].cache_key
  end

  def cached_active_emails
    shard.activate do
      Rails.cache.fetch(active_emails_cache_key) do
        communication_channels.active.email.pluck(:path)
      end
    end
  end

  def active_emails_cache_key
    ["active_user_emails", global_id].cache_key
  end

  def clear_email_cache!
    Rails.cache.delete(email_cache_key)
    Rails.cache.delete(active_emails_cache_key)
  end

  def email_cached?
    Rails.cache.exist?(email_cache_key)
  end

  def gmail_channel
    addr = user_services
           .where(service_domain: "google.com")
           .limit(1).pluck(:service_user_id).first
    communication_channels.email.by_path(addr).first
  end

  def gmail
    res = gmail_channel.path rescue nil
    res ||= google_drive_address
    res ||= google_docs_address
    res || email
  end

  def google_docs_address
    google_service_address("google_docs")
  end

  def google_drive_address
    google_service_address("google_drive")
  end

  def google_service_address(service_name)
    user_services.where(service: service_name)
                 .limit(1).pluck((service_name == "google_drive") ? :service_user_name : :service_user_id).first
  end

  def email=(e)
    if e.is_a?(CommunicationChannel) && e.user_id == id
      cc = e
    else
      cc = communication_channels.email.by_path(e).first ||
           communication_channels.email.create!(path: e)
      # If the email already exists but with different casing this allows us to change it
      cc.path = e
      cc.user = self
    end
    cc.move_to_top
    cc.workflow_state = "unconfirmed" if cc.retired?
    cc.save!
    reload
    clear_email_cache!
    cc.path
  end

  def sms_channel
    # It's already ordered, so find the first one, if there's one.
    communication_channels.sms.first
  end

  def sms
    sms_channel&.path
  end

  def short_name
    read_attribute(:short_name) || name
  end

  workflow do
    state :pre_registered do
      event :register, transitions_to: :registered
    end

    # Not listing this first so it is not the default.
    state :pending_approval do
      event :approve, transitions_to: :pre_registered
      event :reject, transitions_to: :deleted
    end

    state :creation_pending do
      event :create_user, transitions_to: :pre_registered
      event :register, transitions_to: :registered
    end

    state :registered

    state :deleted
  end

  def unavailable?
    deleted?
  end

  def clear_caches
    clear_cache_key(*Canvas::CacheRegister::ALLOWED_TYPES["User"])
    touch
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    remove_from_root_account(:all)
    self.workflow_state = "deleted"
    self.deleted_at = Time.now.utc
    if save
      eportfolios.active.in_batches.destroy_all
      gradebook_filters.in_batches.destroy_all
      true
    end
  end

  # avoid extraneous callbacks when enrolled in multiple sections
  def delete_enrollments(enrollment_scope = enrollments, updating_user: nil)
    courses_to_update = enrollment_scope.active.distinct.pluck(:course_id)
    Enrollment.suspend_callbacks(:set_update_cached_due_dates) do
      enrollment_scope.active.preload(:course, :enrollment_state).find_each(&:destroy)
    end
    user_ids = enrollment_scope.pluck(:user_id).uniq
    courses_to_update.each do |course|
      SubmissionLifecycleManager.recompute_users_for_course(user_ids, course, nil, executing_user: updating_user)
    end
  end

  def remove_from_root_account(root_account, updating_user: nil)
    ActiveRecord::Base.transaction do
      if root_account == :all
        # make sure to hit all shards
        enrollment_scope = enrollments.shard(self)
        user_observer_scope = as_student_observation_links.shard(self)
        user_observee_scope = as_observer_observation_links.shard(self)
        pseudonym_scope = pseudonyms.active.shard(self)
        account_users = self.account_users.active.shard(self)
        has_other_root_accounts = false
        group_memberships_scope = group_memberships.active.shard(self)

        # eportfolios will only be in the users home shard
        eportfolio_scope = eportfolios.active
      else
        # make sure to do things on the root account's shard. but note,
        # root_account.enrollments won't include the student view user's
        # enrollments, so we need to fetch them off the user instead; the
        # student view user won't be cross shard, so that will still be the
        # right shard
        enrollment_scope = fake_student? ? enrollments : root_account.enrollments.where(user_id: self)
        user_observer_scope = as_student_observation_links.shard(self)
        user_observee_scope = as_observer_observation_links.shard(self)

        pseudonym_scope = root_account.pseudonyms.active.where(user_id: self)

        account_users = root_account.account_users.where(user_id: self).to_a +
                        self.account_users.shard(root_account).where(account_id: root_account.all_accounts).to_a
        has_other_root_accounts = associated_accounts.shard(self).where.not(accounts: { id: root_account }).exists?
        group_memberships_scope = group_memberships.active.shard(root_account.shard).joins(:group).where(groups: { root_account_id: root_account })

        eportfolio_scope = eportfolios.active if shard == root_account.shard
      end

      delete_enrollments(enrollment_scope, updating_user:)
      group_memberships_scope.destroy_all
      user_observer_scope.destroy_all
      user_observee_scope.destroy_all
      eportfolio_scope&.in_batches&.destroy_all
      pseudonym_scope.each(&:destroy)
      account_users.each(&:destroy)

      # only delete the user's communication channels when the last account is
      # removed (they don't belong to any particular account). they will always
      # be on the user's shard
      communication_channels.unretired.each(&:destroy) unless has_other_root_accounts

      update_account_associations
    end
    reload
  end

  def associate_with_shard(shard, strength = :strong); end

  def self.clone_communication_channel(cc, new_user, max_position)
    new_cc = cc.clone
    new_cc.shard = new_user.shard
    new_cc.position += max_position
    new_cc.user = new_user
    new_cc.workflow_state = "unconfirmed"
    new_cc.save!
    cc.notification_policies.each do |np|
      new_np = np.clone
      new_np.shard = new_user.shard
      new_np.communication_channel = new_cc
      new_np.save!
    end
    unless cc.unconfirmed?
      new_cc.workflow_state = cc.workflow_state
      new_cc.save!
    end
  end

  # Overwrites the old user name, if there was one.  Fills in the new one otherwise.
  def assert_name(name = nil)
    if name && (pre_registered? || creation_pending?) && name != email
      self.name = name
      save!
    end
    self
  end

  def to_atom
    {
      title: self.name,
      updated: updated_at,
      published: created_at,
      link: "/users/#{id}"
    }
  end

  def admins
    [self]
  end

  def students
    [self]
  end

  def latest_pseudonym
    Pseudonym.order(:created_at).where(user_id: id).active.last
  end

  def used_feature(feature)
    update_attribute(:features_used, ((features_used || "").split(",").map(&:to_s) + [feature.to_s]).uniq.join(","))
  end

  def used_feature?(feature)
    features_used&.split(",")&.include?(feature.to_s)
  end

  def available_courses
    # this list should be longer if the person has admin privileges...
    courses
  end

  def check_courses_right?(user, sought_right, enrollments_to_check = nil)
    return false unless user && sought_right

    # Look through the currently enrolled courses first.  This should
    # catch most of the calls.  If none of the current courses grant
    # the right then look at the concluded courses.
    enrollments_to_check ||= enrollments.current_and_concluded

    shards = associated_shards & user.associated_shards
    # search the current shard first
    shards.delete(Shard.current) && shards.unshift(Shard.current) if shards.include?(Shard.current)

    courses_for_enrollments(enrollments_to_check.shard(shards)).any? { |c| c.grants_right?(user, sought_right) }
  end

  def check_accounts_right?(user, sought_right)
    # check if the user we are given is an admin in one of this user's accounts
    return false unless user && sought_right
    return account.grants_right?(user, sought_right) if fake_student? # doesn't have account association

    # Intentionally include deleted pseudonyms when checking deleted users (important for diagnosing deleted users)
    accounts_to_search = if associated_accounts.empty?
                           if merged_into_user
                             # Early return from inside if to ensure we handle chains of merges correctly
                             return merged_into_user.check_accounts_right?(user, sought_right)
                           elsif Account.where(id: pseudonyms.pluck(:account_id)).any?
                             Account.where(id: pseudonyms.pluck(:account_id))
                           else
                             associated_accounts
                           end
                         else
                           associated_accounts
                         end

    common_shards = associated_shards & user.associated_shards
    search_method = lambda do |shard|
      # new users with creation pending enrollments don't have account associations
      if accounts_to_search.shard(shard).empty? && common_shards.length == 1 && !unavailable?
        account.grants_right?(user, sought_right)
      else
        accounts_to_search.shard(shard).any? { |a| a.grants_right?(user, sought_right) }
      end
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
    can %i[
      read
      read_grades
      read_profile
      read_files
      read_as_admin
      manage
      manage_content
      manage_course_content_add
      manage_course_content_edit
      manage_course_content_delete
      manage_files_add
      manage_files_edit
      manage_files_delete
      manage_calendar
      send_messages
      update_avatar
      view_feature_flags
      manage_feature_flags
      api_show_user
      read_email_addresses
      view_user_logins
      generate_observer_pairing_code
    ]

    given { |user| user == self && user.user_can_edit_name? }
    can :rename

    given { |user| courses.any? { |c| c.user_is_instructor?(user) } }
    can :read_profile

    # by default this means that the user we are given is an administrator
    # of an account of one of the courses that this user is enrolled in, or
    # an admin (teacher/ta/designer) in the course
    given { |user| check_courses_right?(user, :read_reports) }
    can :read_profile and can :remove_avatar and can :read_reports

    given { |user| check_courses_right?(user, :manage_user_notes) }
    can :create_user_notes and can :read_user_notes

    %i[read_email_addresses read_sis manage_sis].each do |permission|
      given { |user| check_courses_right?(user, permission) }
      can permission
    end

    given { |user| check_courses_right?(user, :generate_observer_pairing_code, enrollments.not_deleted) }
    can :generate_observer_pairing_code

    given { |user| check_accounts_right?(user, :manage_user_notes) }
    can :create_user_notes and can :read_user_notes and can :delete_user_notes

    given { |user| check_accounts_right?(user, :view_statistics) }
    can :view_statistics

    given { |user| check_accounts_right?(user, :manage_students) }
    can :read_profile and can :read_reports and can :read_grades

    given { |user| check_accounts_right?(user, :manage_user_logins) }
    can %i[read read_reports read_profile api_show_user terminate_sessions read_files]

    given { |user| check_accounts_right?(user, :read_roster) }
    can :read_full_profile and can :api_show_user

    given { |user| check_accounts_right?(user, :view_all_grades) }
    can :read_grades

    given { |user| check_accounts_right?(user, :view_user_logins) }
    can :view_user_logins

    given { |user| check_accounts_right?(user, :read_email_addresses) }
    can :read_email_addresses

    given do |user|
      check_accounts_right?(user, :manage_user_logins) && adminable_accounts.select(&:root_account?).all? { |a| has_subset_of_account_permissions?(user, a) }
    end
    can :manage_user_details and can :rename and can :update_avatar and can :remove_avatar and
      can :manage_feature_flags and can :view_feature_flags

    given { |user| pseudonyms.shard(self).any? { |p| p.grants_right?(user, :update) } }
    can :merge

    given do |user|
      # a user can reset their own MFA, but only if the setting isn't required
      (self == user && mfa_settings != :required) ||

        # a site_admin with permission to reset_any_mfa
        Account.site_admin.grants_right?(user, :reset_any_mfa) ||
        # an admin can reset another user's MFA only if they can manage *all*
        # of the user's pseudonyms
        (self != user && pseudonyms.shard(self).all? do |p|
          p.grants_right?(user, :update) ||
            # the account does not have mfa enabled
            p.account.mfa_settings == :disabled ||
            # they are an admin user and have reset MFA permission
            p.account.grants_right?(user, :reset_any_mfa)
        end)
    end
    can :reset_mfa

    given { |user| user && user.as_observer_observation_links.where(user_id: id).exists? }
    can %i[read read_as_parent read_files]

    given { |user| check_accounts_right?(user, :moderate_user_content) }
    can :moderate_user_content
  end

  def can_masquerade?(masquerader, account)
    return true if self == masquerader
    # student view should only ever have enrollments in a single course
    return true if fake_student?
    return false unless
        account.grants_right?(masquerader, nil, :become_user) && SisPseudonym.for(self, account, type: :implicit, require_sis: false)

    if account.root_account.feature_enabled?(:course_admin_role_masquerade_permission_check)
      return false unless includes_subset_of_course_admin_permissions?(masquerader, account)
    end

    has_subset_of_account_permissions?(masquerader, account)
  end

  def self.all_course_admin_type_permissions_for(user)
    enrollments = Enrollment.for_user(user).of_admin_type.active_by_date.distinct_on(:role_id).to_a
    result = {}

    RoleOverride.permissions.each_key do |permission|
      # iterate and set permissions
      # we want the highest level permission set the user is authorized for
      result[permission] = true if enrollments.any? { |e| e.has_permission_to?(permission) }
    end
    result
  end

  def includes_subset_of_course_admin_permissions?(user, account)
    return true if user == self
    return false unless account.root_account?

    Rails.cache.fetch(["includes_subset_of_course_admin_permissions", self, user, account].cache_key, expires_in: 60.minutes) do
      current_permissions = AccountUser.all_permissions_for(user, account)
      sought_permissions = User.all_course_admin_type_permissions_for(self)
      sought_permissions.all? do |(permission, sought_permission)|
        next true unless sought_permission.present?

        current_permission = current_permissions[permission]
        return false if current_permission.empty?

        true
      end
    end
  end

  def has_subset_of_account_permissions?(user, account)
    return true if user == self
    return false unless account.root_account?

    Rails.cache.fetch(["has_subset_of_account_permissions", self, user, account].cache_key, expires_in: 60.minutes) do
      account_users = account.cached_all_account_users_for(self)
      account_users.all? do |account_user|
        account_user.is_subset_of?(user)
      end
    end
  end

  def allows_user_to_remove_from_account?(account, other_user)
    check_pseudonym = pseudonym
    check_pseudonym ||= Pseudonym.new(account:, user: self) if associated_accounts.exists?
    check_pseudonym&.grants_right?(other_user, :delete) &&
      (check_pseudonym&.grants_right?(other_user, :manage_sis) ||
       account.pseudonyms.active.where(user_id: other_user).where.not(sis_user_id: nil).none?)
  end

  def self.infer_id(obj)
    case obj
    when User, OpenObject
      obj.id
    when Numeric
      obj
    when CommunicationChannel, Pseudonym, AccountUser
      obj.user_id
    when String
      obj.to_i
    else
      raise ArgumentError, "Cannot infer a user_id from #{obj.inspect}"
    end
  end

  def management_contexts
    contexts = [self] + courses + groups.active + all_courses_for_active_enrollments
    contexts.uniq
  end

  def update_avatar_image(force_reload = false)
    if (!avatar_image_url || force_reload) && avatar_image_source == "twitter"
      twitter = user_services.for_service("twitter").first rescue nil
      if twitter
        url = URI.parse("http://twitter.com/users/show.json?user_id=#{twitter.service_user_id}")
        data = JSON.parse(Net::HTTP.get(url)) rescue nil
        if data
          self.avatar_image_url = data["profile_image_url_https"] || avatar_image_url
          self.avatar_image_updated_at = Time.now
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
    Setting.get("max_messages_per_day_per_user", 500).to_i
  end

  def max_messages_per_day
    User.max_messages_per_day
  end

  def gravatar_url(size = 50, fallback = nil, request = nil)
    fallback = self.class.avatar_fallback_url(fallback, request)
    "https://secure.gravatar.com/avatar/#{Digest::MD5.hexdigest(email) rescue "000"}?s=#{size}&d=#{CGI.escape(fallback)}"
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
    return if avatar_state == :locked

    # Clear out the old avatar first, in case of failure to get new avatar.
    # The order of these attributes is standard throughout the method.
    self.avatar_image_source = "no_pic"
    self.avatar_image_url = nil
    self.avatar_image_updated_at = Time.zone.now
    self.avatar_state = "approved"

    # Return here if we're passed a nil val or any non-hash val (both of which
    # will just nil the user's avatar).
    return unless val.is_a?(Hash)

    external_avatar_url_patterns = Setting.get("avatar_external_url_patterns", "^https://[a-zA-Z0-9.-]+\\.instructure\\.com/").split(",").map { |re| Regexp.new re }

    if val["url"]&.match?(GRAVATAR_PATTERN)
      self.avatar_image_source = "gravatar"
      self.avatar_image_url = val["url"]
      self.avatar_state = "submitted"
    elsif val["type"] == "attachment" && val["url"]
      self.avatar_image_source = "attachment"
      self.avatar_image_url = val["url"]
      self.avatar_state = "submitted"
    elsif val["url"] && external_avatar_url_patterns.find { |p| val["url"].match?(p) }
      self.avatar_image_source = "external"
      self.avatar_image_url = val["url"]
      self.avatar_state = "submitted"
    end
  end

  def report_avatar_image!
    self.avatar_state = if avatar_state == :approved || avatar_state == :locked
                          "re_reported"
                        else
                          "reported"
                        end
    save!
  end

  def avatar_state
    if %w[none submitted approved locked reported re_reported].include?(read_attribute(:avatar_state))
      read_attribute(:avatar_state).to_sym
    else
      :none
    end
  end

  def avatar_state=(val)
    if %w[none submitted approved locked reported re_reported].include?(val.to_s)
      if val == "none"
        self.avatar_image_url = nil
        self.avatar_image_source = "no_pic"
        self.avatar_image_updated_at = Time.now
      end
      write_attribute(:avatar_state, val.to_s)
    end
  end

  def avatar_reportable?
    %i[submitted approved reported re_reported].include?(avatar_state)
  end

  def avatar_approvable?
    %i[submitted reported re_reported].include?(avatar_state)
  end

  def avatar_approved?
    %i[approved locked re_reported].include?(avatar_state)
  end

  def avatar_locked?
    avatar_state == :locked
  end

  def self.avatar_key(user_id)
    user_id = user_id.to_s
    if user_id.present? && user_id != "0"
      "#{user_id}-#{Canvas::Security.hmac_sha1(user_id)[0, 10]}"
    else
      "0"
    end
  end

  def self.user_id_from_avatar_key(key)
    user_id, sig = key.to_s.split("-", 2)
    Canvas::Security.verify_hmac_sha1(sig, user_id.to_s, truncate: 10) ? user_id : nil
  end

  AVATAR_SETTINGS = %w[enabled enabled_pending sis_only disabled].freeze
  def avatar_url(size = nil, avatar_setting = nil, fallback = nil, request = nil, use_fallback = true)
    return fallback if avatar_setting == "disabled"

    size ||= 50
    avatar_setting ||= "enabled"
    fallback = use_fallback ? self.class.avatar_fallback_url(fallback, request) : nil
    if avatar_setting == "enabled" || (avatar_setting == "enabled_pending" && avatar_approved?) || (avatar_setting == "sis_only")
      @avatar_url ||= avatar_image_url
    end
    @avatar_url ||= fallback if avatar_image_source == "no_pic"
    if (avatar_setting == "enabled") && (avatar_image_source == "gravatar")
      @avatar_url ||= gravatar_url(size, fallback, request)
    end
    @avatar_url ||= fallback
  end

  def avatar_path
    "/images/users/#{User.avatar_key(id)}"
  end

  def self.default_avatar_fallback
    "/images/messages/avatar-50.png"
  end

  def self.avatar_fallback_url(fallback = nil, request = nil)
    if fallback && (uri = URI.parse(fallback) rescue nil)
      # something got built without request context, so we want to inherit that
      # context now that we have a request
      if uri.host == "localhost"
        uri.scheme = request.scheme
        uri.host = request.host
        uri.port = request.port unless [80, 443].include?(request.port)
      end
      uri.scheme ||= request ? request.protocol[0..-4] : HostUrl.protocol # -4 to chop off the ://
      if HostUrl.cdn_host
        uri.host = HostUrl.cdn_host
      elsif request && !uri.host
        uri.host = request.host
        uri.port = request.port unless [80, 443].include?(request.port)
      elsif !uri.host
        uri.host, port = HostUrl.default_host.split(":")
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

    if avatar_image_url.to_s.match?(/#{uuid}/)
      self.avatar_image_url = nil
      save
    end
  end

  scope :with_avatar_state, lambda { |state|
    scope = where.not(avatar_image_url: nil).order("avatar_image_updated_at DESC")
    if state == "any"
      scope.where("avatar_state IS NOT NULL AND avatar_state<>'none'")
    else
      scope.where(avatar_state: state)
    end
  }

  def sorted_rubrics
    context_codes = ([self] + management_contexts).uniq.map(&:asset_string)
    rubrics = context_rubrics.active
    rubrics += Rubric.active.where(context_code: context_codes).to_a
    rubrics.uniq.sort_by { |r| [((r.association_count || 0) > 3) ? CanvasSort::First : CanvasSort::Last, Canvas::ICU.collation_key(r.title || CanvasSort::Last)] }
  end

  def assignments_recently_graded(opts = {})
    opts = { start_at: 1.week.ago, limit: 10 }.merge(opts)
    Submission.active.recently_graded_assignments(id, opts[:start_at], opts[:limit])
  end

  def preferences
    read_or_initialize_attribute(:preferences, {})
  end

  def new_user_tutorial_statuses
    get_preference(:new_user_tutorial_statuses) || {}
  end

  def apply_contrast(colors)
    colors.each_key do |key|
      darkened_color = colors[key]
      begin
        until WCAGColorContrast.ratio(darkened_color.delete("#"), "ffffff") >= 4.5
          darkened_color = "##{darkened_color.delete("#").chars.map { |c| c + c }.join}" if darkened_color.length == 4
          rgb = darkened_color.match(/^#(..)(..)(..)$/).captures.map { |c| (c.hex.to_i * 0.85).round }
          darkened_color = "#%02x%02x%02x" % rgb
        end
      rescue => e
        Canvas::Errors.capture(e, {}, :info)
      else
        colors[key] = darkened_color
      end
    end
  end

  def custom_colors
    colors_hash = get_preference(:custom_colors) || {}
    if Shard.current != shard
      # translate asset strings to be relative to current shard
      colors_hash = colors_hash.filter_map do |asset_string, value|
        opts = asset_string.split("_")
        id_relative_to_user_shard = opts.pop.to_i
        next if id_relative_to_user_shard > Shard::IDS_PER_SHARD && Shard.shard_for(id_relative_to_user_shard) == shard # this is old data and should be ignored

        new_id = Shard.relative_id_for(id_relative_to_user_shard, shard, Shard.current)
        ["#{opts.join("_")}_#{new_id}", value]
      end.to_h
    end

    return apply_contrast colors_hash if prefers_high_contrast?

    colors_hash
  end

  def dashboard_positions
    @dashboard_positions ||= get_preference(:dashboard_positions) || {}
  end

  def set_dashboard_positions(new_positions)
    @dashboard_positions = nil
    set_preference(:dashboard_positions, new_positions)
  end

  # Use the user's preferences for the default view
  # Otherwise, use the account's default (if set)
  # Fallback to using cards (default option on the Account settings page)
  def dashboard_view(current_account = account)
    preferences[:dashboard_view] || current_account.default_dashboard_view || "cards"
  end

  def dashboard_view=(new_dashboard_view)
    preferences[:dashboard_view] = new_dashboard_view
  end

  def all_course_nicknames(courses = nil)
    if preferences[:course_nicknames] == UserPreferenceValue::EXTERNAL
      shard.activate do
        scope = user_preference_values.where(key: :course_nicknames)
        scope = scope.where(sub_key: courses) if courses
        scope.pluck(:sub_key, :value).to_h
      end
    else
      preferences[:course_nicknames] || {}
    end
  end

  def course_nickname_hash
    if preferences[:course_nicknames].present?
      @nickname_hash ||= Digest::SHA256.hexdigest(user_preference_values.where(key: :course_nicknames).pluck(:sub_key, :value).sort.join(","))
    else
      "default"
    end
  end

  def course_nickname(course)
    shard.activate do
      get_preference(:course_nicknames, course.id)
    end
  end

  def send_scores_in_emails?(course)
    root_account = course.root_account
    return false if root_account.settings[:allow_sending_scores_in_emails] == false

    pref = get_preference(:send_scores_in_emails_override, "course_" + course.global_id.to_s)
    pref = preferences[:send_scores_in_emails] if pref.nil?
    !!pref
  end

  def send_observed_names_in_notifications?
    preferences[:send_observed_names_in_notifications] == true
  end

  def discussions_splitscreen_view?
    !!preferences[:discussions_splitscreen_view]
  end

  def close_announcement(announcement)
    closed = get_preference(:closed_notifications).dup || []
    # serialize ids relative to the user
    shard.activate do
      closed << announcement.id
    end
    set_preference(:closed_notifications, closed.uniq)
  end

  def unread_submission_annotations?(submission)
    !!get_preference(:unread_submission_annotations, submission.global_id)
  end

  def mark_submission_annotations_unread!(submission)
    set_preference(:unread_submission_annotations, submission.global_id, true)
  end

  def mark_submission_annotations_read!(submission)
    # this will delete the user_preference_value
    set_preference(:unread_submission_annotations, submission.global_id, nil)
  end

  def unread_rubric_assessments?(submission)
    !!get_preference(:unread_rubric_comments, submission.global_id)
  end

  def mark_rubric_assessments_unread!(submission)
    set_preference(:unread_rubric_comments, submission.global_id, true)
  end

  def mark_rubric_assessments_read!(submission)
    # this will delete the user_preference_value
    set_preference(:unread_rubric_comments, submission.global_id, nil)
  end

  def add_to_visited_tabs(tab_class)
    visited_tabs = get_preference(:visited_tabs) || []
    set_preference(:visited_tabs, [*visited_tabs, tab_class]) unless visited_tabs.include? tab_class
  end

  def prefers_high_contrast?
    !!feature_enabled?(:high_contrast)
  end

  def auto_show_cc?
    !!feature_enabled?(:auto_show_cc)
  end

  def prefers_no_toast_timeout?
    !!feature_enabled?(:disable_alert_timeouts)
  end

  def prefers_no_celebrations?
    !!feature_enabled?(:disable_celebrations)
  end

  def prefers_no_keyboard_shortcuts?
    !!feature_enabled?(:disable_keyboard_shortcuts)
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

  def elementary_dashboard_disabled?
    !!preferences[:elementary_dashboard_disabled]
  end

  def create_announcements_unlocked?
    preferences.fetch(:create_announcements_unlocked, false)
  end

  def create_announcements_unlocked(bool)
    preferences[:create_announcements_unlocked] = bool
  end

  def default_notifications_disabled=(val)
    # if this is set then all notifications will be disabled by default
    # for the user and will need to be explicitly enabled
    preferences[:default_notifications_disabled] = val
  end

  def default_notifications_disabled?
    !!preferences[:default_notifications_disabled]
  end

  def last_seen_release_note=(val)
    preferences[:last_seen_release_note] = val
  end

  def last_seen_release_note
    preferences[:last_seen_release_note] || Time.at(0)
  end

  def release_notes_badge_disabled?
    !!preferences[:release_notes_badge_disabled]
  end

  def comment_library_suggestions_enabled?
    !!preferences[:comment_library_suggestions_enabled]
  end

  def collapse_course_nav?
    !!preferences[:collapse_course_nav]
  end

  # ***** OHI If you're going to add a lot of data into `preferences` here maybe take a look at app/models/user_preference_value.rb instead ***
  # it will store the data in a separate table on the db and lighten the load on poor `users`

  def uuid
    unless read_attribute(:uuid)
      update_attribute(:uuid, CanvasSlug.generate_securish_uuid)
    end
    read_attribute(:uuid)
  end

  def heap_id(root_account: nil)
    # this is called in read-only contexts where we can't create a missing uuid
    # (uuid-less users should be rare in real life but they exist in specs and maybe unauthenticated requests)
    return nil unless read_attribute(:uuid)

    # for an explanation of these, see
    # https://instructure.atlassian.net/wiki/spaces/HEAP/pages/85854749165/RFC+Advanced+HEAP+installation
    if root_account
      "uu-2-#{Digest::SHA256.hexdigest(uuid)}-#{root_account.uuid}"
    else
      "uu-1-#{Digest::SHA256.hexdigest(uuid)}"
    end
  end

  def self.serialization_excludes
    %i[
      uuid
      phone
      features_used
      otp_communication_channel_id
      otp_secret_key_enc
      otp_secret_key_salt
      collkey
    ]
  end

  def secondary_identifier
    email || id
  end

  def self_enroll_if_necessary
    return unless @self_enrollment_course
    return if @self_enrolling # avoid infinite recursion when enrolling across shards (pseudonym creation + shard association stuff)

    @self_enrolling = true
    @self_enrollment = @self_enrollment_course.self_enroll_student(self, skip_pseudonym: @just_created, skip_touch_user: true)
    @self_enrolling = false
  end

  def is_a_context?
    true
  end

  def account
    pseudonym.account rescue Account.default
  end

  def alternate_account_for_course_creation
    Rails.cache.fetch_with_batched_keys("alternate_account_for_course_creation", batch_object: self, batched_keys: :account_users) do
      account_users.active.detect do |au|
        break au.account if au.root_account_id == account.id && au.account.grants_any_right?(self, :manage_courses, :manage_courses_add)
      end
    end
  end

  def course_creating_teacher_enrollment_accounts
    Rails.cache.fetch_with_batched_keys("course_creating_teacher_enrollment_accounts", batch_object: self, batched_keys: :enrollments) do
      Shard.with_each_shard(in_region_associated_shards) do
        Account.where(id: Course.where(id: enrollments.active.shard(Shard.current)
                                .select(:course_id)
                                .where(type: %w[TeacherEnrollment DesignerEnrollment])
                                .joins(:root_account)
                                .where("accounts.settings LIKE ?", "%teachers_can_create_courses: true%"))
               .select(:account_id))
      end
    end
  end

  def course_creating_student_enrollment_accounts
    Rails.cache.fetch_with_batched_keys("course_creating_student_enrollment_accounts", batch_object: self, batched_keys: :enrollments) do
      Shard.with_each_shard(in_region_associated_shards) do
        Account.where(id: Course.where(id: enrollments.active.shard(Shard.current)
                                .select(:course_id)
                                .where(type: %w[StudentEnrollment ObserverEnrollment])
                                .joins(:root_account)
                                .where("accounts.settings LIKE ?", "%students_can_create_courses: true%"))
               .select(:account_id))
      end
    end
  end

  def courses_with_primary_enrollment(association = :current_and_invited_courses, enrollment_uuid = nil, options = {})
    cache_key = [association, enrollment_uuid, options].cache_key
    @courses_with_primary_enrollment ||= {}
    @courses_with_primary_enrollment.fetch(cache_key) do
      res = shard.activate do
        result = Rails.cache.fetch([self, "courses_with_primary_enrollment2", association, options, ApplicationController.region].cache_key, expires_in: 15.minutes) do
          scope = courses_for_enrollments(enrollments.current_and_invited, options[:observee_user], !!options[:include_completed_courses])
          shards = in_region_associated_shards
          # Limit favorite courses based on current shard.
          if association == :favorite_courses
            ids = favorite_context_ids("Course")
            if ids.empty?
              scope = scope.none
            else
              shards &= ids.map { |id| Shard.shard_for(id) }
              scope = scope.where(id: ids)
            end
          end

          GuardRail.activate(:secondary) do
            Shard.with_each_shard(shards) do
              scope.select("courses.*, enrollments.id AS primary_enrollment_id, enrollments.type AS primary_enrollment_type, enrollments.role_id AS primary_enrollment_role_id, #{Enrollment.type_rank_sql} AS primary_enrollment_rank, enrollments.workflow_state AS primary_enrollment_state, enrollments.created_at AS primary_enrollment_date")
                   .order(Arel.sql("courses.id, #{Enrollment.type_rank_sql}, #{Enrollment.state_rank_sql}"))
                   .distinct_on(:id).shard(Shard.current)
            end
          end
        end
        result.dup
      end

      if association == :current_and_invited_courses
        if enrollment_uuid && (pending_course = Course.active
          .select("courses.*, enrollments.type AS primary_enrollment,
                  #{Enrollment.type_rank_sql} AS primary_enrollment_rank,
                  enrollments.workflow_state AS primary_enrollment_state,
                  enrollments.created_at AS primary_enrollment_date")
          .joins(:enrollments)
          .where(enrollments: { uuid: enrollment_uuid, workflow_state: "invited" }).first)
          res << pending_course
          res.uniq!
        end
        pending_enrollments = temporary_invitations
        unless pending_enrollments.empty?
          ActiveRecord::Associations.preload(pending_enrollments, :course)
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

      Shard.partition_by_shard(res, ->(c) { c.shard }) do |shard_courses|
        roles = Role.where(id: shard_courses.map(&:primary_enrollment_role_id).uniq).to_a.index_by(&:id)
        shard_courses.each { |c| c.primary_enrollment_role = roles[c.primary_enrollment_role_id] }
      end
      @courses_with_primary_enrollment[cache_key] =
        res.sort_by { |c| [c.primary_enrollment_rank, Canvas::ICU.collation_key(c.name)] }
    end
  end

  def temporary_invitations
    cached_active_emails.map { |email| Enrollment.cached_temporary_invitations(email).dup.reject { |e| e.user_id == id } }.flatten
  end

  def active_k5_enrollments?(root_account: false)
    account_ids = if  root_account
                    enrollments.current.active_by_date.where(root_account:).distinct.pluck(:account_id)
                  else
                    enrollments.shard(in_region_associated_shards).current.active_by_date.distinct.pluck(:account_id)
                  end
    Account.where(id: account_ids).any?(&:enable_as_k5_account?)
  end

  # http://github.com/seamusabshere/cacheable/blob/master/lib/cacheable.rb from the cacheable gem
  # to get a head start

  # this method takes an optional {:include_enrollment_uuid => uuid}   so that you can pass it the session[:enrollment_uuid] and it will include it.
  def cached_currentish_enrollments(opts = {})
    # this method doesn't include the "active_by_date" scope and should probably not be used since
    # it will give enrollments which are concluded by date
    # leaving this for existing instances where schools are used to the inconsistent behavior
    # participating_enrollments seems to be a more accurate representation of "current courses"
    RequestCache.cache("cached_current_enrollments", self, opts) do
      enrollments = shard.activate do
        res = Rails.cache.fetch_with_batched_keys(
          ["current_enrollments5", opts[:include_future], ApplicationController.region].cache_key,
          batch_object: self,
          batched_keys: :enrollments
        ) do
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
        ActiveRecord::Associations.preload(enrollments, :course)
      end
      enrollments
    end
  end

  def cached_invitations(opts = {})
    enrollments = Rails.cache.fetch([self, "invited_enrollments", ApplicationController.region].cache_key) do
      self.enrollments.shard(in_region_associated_shards).invited_by_date
          .joins(:course).where.not(courses: { workflow_state: "deleted" }).to_a
    end
    if opts[:include_enrollment_uuid] && !enrollments.find { |e| e.uuid == opts[:include_enrollment_uuid] } &&
       (pending_enrollment = Enrollment.invited_by_date.where(uuid: opts[:include_enrollment_uuid]).first)
      enrollments << pending_enrollment
    end
    enrollments += temporary_invitations

    if opts[:preload_course]
      ActiveRecord::Associations.preload(enrollments, :course)
    end
    enrollments
  end

  def has_enrollment?
    return @_has_enrollment if defined?(@_has_enrollment)

    # don't need an expires_at here because user will be touched upon enrollment creation
    @_has_enrollment = Rails.cache.fetch([self, "has_enrollment", ApplicationController.region].cache_key) do
      enrollments.shard(in_region_associated_shards).active.exists?
    end
  end

  def has_active_enrollment?
    return @_has_active_enrollment if defined?(@_has_active_enrollment)

    # don't need an expires_at here because user will be touched upon enrollment activation
    @_has_active_enrollment = Rails.cache.fetch([self, "has_active_enrollment", ApplicationController.region].cache_key) do
      enrollments.shard(in_region_associated_shards).current.active_by_date.exists?
    end
  end

  def has_future_enrollment?
    return @_has_future_enrollment if defined?(@_has_future_enrollment)

    @_has_future_enrollment = Rails.cache.fetch([self, "has_future_enrollment", ApplicationController.region].cache_key, expires_in: 1.hour) do
      enrollments.shard(in_region_associated_shards).active_or_pending_by_date.exists?
    end
  end

  def cached_current_group_memberships
    @cached_current_group_memberships ||= shard.activate do
      Rails.cache.fetch_with_batched_keys(["current_group_memberships", ApplicationController.region].cache_key, batch_object: self, batched_keys: :groups) do
        current_group_memberships.shard(in_region_associated_shards).to_a
      end
    end
  end

  def cached_current_group_memberships_by_date
    @cached_current_group_memberships_by_date ||= shard.activate do
      Rails.cache.fetch_with_batched_keys(["current_group_memberships_by_date", ApplicationController.region].cache_key, batch_object: self, batched_keys: [:enrollments, :groups]) do
        Shard.with_each_shard(in_region_associated_shards) do
          GroupMembership.where(user_id: self).joins(:group)
                         .joins("LEFT OUTER JOIN #{Enrollment.quoted_table_name} ON enrollments.user_id=group_memberships.user_id AND enrollments.course_id=groups.context_id AND groups.context_type='Course'")
                         .joins("LEFT OUTER JOIN #{EnrollmentState.quoted_table_name} ON enrollment_states.enrollment_id=enrollments.id")
                         .where("group_memberships.workflow_state='accepted' AND groups.workflow_state<>'deleted' AND COALESCE(enrollment_states.state,'active') IN ('invited','active')").to_a
        end
      end
    end
  end

  def membership_for_group_id?(group_id)
    current_group_memberships.active.where(group_id:).exists?
  end

  def has_student_enrollment?
    return @_has_student_enrollment if defined?(@_has_student_enrollment)

    @_has_student_enrollment = Rails.cache.fetch_with_batched_keys(["has_student_enrollment", ApplicationController.region].cache_key, batch_object: self, batched_keys: :enrollments) do
      enrollments.shard(in_region_associated_shards).where(type: %w[StudentEnrollment StudentViewEnrollment])
                 .where.not(workflow_state: %w[rejected inactive deleted]).exists?
    end
  end

  def non_student_enrollment?
    # We should be able to remove this method when the planner works for teachers/other course roles
    return @_non_student_enrollment if defined?(@_non_student_enrollment)

    @_non_student_enrollment = Rails.cache.fetch_with_batched_keys(["has_non_student_enrollment", ApplicationController.region].cache_key, batch_object: self, batched_keys: :enrollments) do
      enrollments.shard(in_region_associated_shards).where.not(type: %w[StudentEnrollment StudentViewEnrollment ObserverEnrollment])
                 .where.not(workflow_state: %w[rejected inactive deleted]).exists?
    end
  end

  def account_membership?
    return @_account_membership if defined?(@_account_membership)

    @_account_membership = Rails.cache.fetch_with_batched_keys(["has_account_user", ApplicationController.region].cache_key, batch_object: self, batched_keys: :account_users) do
      account_users.shard(in_region_associated_shards).active.exists?
    end
  end

  def can_view_content_shares?
    non_student_enrollment? || account_membership?
  end

  def participating_current_and_concluded_course_ids
    cached_course_ids("current_and_concluded") do |enrollments|
      enrollments.current_and_concluded.not_inactive_by_date_ignoring_access
    end
  end

  def participating_student_current_and_concluded_course_ids
    cached_course_ids("student_current_and_concluded") do |enrollments|
      enrollments.current_and_concluded.not_inactive_by_date_ignoring_access.where(type: %w[StudentEnrollment StudentViewEnrollment])
    end
  end

  def participating_student_current_and_unrestricted_concluded_course_ids
    cached_course_ids("student_current_and_concluded") do |enrollments|
      enrollments.current_and_concluded.not_inactive_by_date.where(type: %w[StudentEnrollment StudentViewEnrollment])
    end
  end

  def participating_student_course_ids
    cached_course_ids("participating_student") do |enrollments|
      enrollments.current.active_by_date.where(type: %w[StudentEnrollment StudentViewEnrollment])
    end
  end

  def participating_instructor_course_ids
    cached_course_ids("participating_instructor") do |enrollments|
      enrollments.of_instructor_type.current.active_by_date
    end
  end

  def participating_instructor_course_with_concluded_ids
    cached_course_ids("participating_instructor_with_concluded") do |enrollments|
      enrollments.of_instructor_type.current_and_concluded.not_inactive_by_date
    end
  end

  def participating_course_ids
    cached_course_ids("participating") do |enrollments|
      enrollments.current.active_by_date
    end
  end

  def all_course_ids
    cached_course_ids("all") do |enrollments|
      enrollments.where.not(workflow_state: %w[rejected deleted inactive])
    end
  end

  def cached_course_ids(type)
    @cached_course_ids ||= {}
    @cached_course_ids[type] ||=
      shard.activate do
        Rails.cache.fetch_with_batched_keys(["cached_course_ids", type, ApplicationController.region].cache_key, batch_object: self, batched_keys: :enrollments) do
          yield(enrollments.shard(in_region_associated_shards)).distinct.pluck(:course_id)
        end
      end
  end
  private :cached_course_ids

  def participating_enrollments
    @participating_enrollments ||= shard.activate do
      Rails.cache.fetch_with_batched_keys([self, "participating_enrollments2", ApplicationController.region].cache_key, batch_object: self, batched_keys: :enrollments) do
        enrollments.shard(in_region_associated_shards).current.active_by_date.to_a.each(&:clear_association_cache)
      end
    end
  end

  def submissions_for_course_ids(course_ids, start_at: nil, limit: 20)
    return [] unless course_ids.present?

    shard.activate do
      ids_hash = Digest::SHA256.hexdigest(course_ids.sort.join(","))
      Rails.cache.fetch_with_batched_keys(["submissions_for_course_ids", ids_hash, start_at, limit].cache_key, expires_in: 1.day, batch_object: self, batched_keys: :submissions) do
        start_at ||= 4.weeks.ago

        GuardRail.activate(:secondary) do
          submissions = []
          submissions += self.submissions.posted.where("GREATEST(submissions.submitted_at, submissions.created_at) > ?", start_at)
                             .where(course_id: course_ids).eager_load(:assignment)
                             .where("submissions.score IS NOT NULL AND assignments.workflow_state=?", "published")
                             .order("submissions.created_at DESC")
                             .limit(limit).to_a

          submissions += Submission.active.where(user_id: self)
                                   .where(course_id: course_ids)
                                   .where("submissions.posted_at IS NOT NULL OR post_policies.post_manually IS FALSE")
                                   .joins(:assignment, assignment: [:post_policy])
                                   .where(assignments: { workflow_state: "published" })
                                   .where("last_comment_at > ?", start_at)
                                   .limit(limit).order("last_comment_at").to_a

          submissions = submissions.sort_by { |t| t.last_comment_at || t.created_at }.reverse
          submissions = submissions.uniq
          submissions.first(limit)

          ActiveRecord::Associations.preload(submissions, [{ assignment: :context }, :user, :submission_comments])
          submissions
        end
      end
    end
  end

  # This is only feedback for student contexts (unless specific contexts are passed in)
  def recent_feedback(
    course_ids: nil,
    contexts: nil,
    **opts # forwarded to submissions_for_course_ids
  )
    course_ids ||= if contexts
                     contexts.select { |c| c.is_a?(Course) }.map(&:id)
                   else
                     participating_student_course_ids
                   end
    submissions_for_course_ids(course_ids, **opts)
  end

  def visible_stream_item_instances(opts = {})
    instances = stream_item_instances.where(hidden: false).order("stream_item_instances.id desc")

    # dont make the query do an stream_item_instances.context_code IN
    # ('course_20033','course_20237','course_20247' ...) if they dont pass any
    # contexts, just assume it wants any context code.
    if opts[:contexts]
      # still need to optimize the query to use a root_context_code.  that way a
      # users course dashboard even if they have groups does a query with
      # "context_code=..." instead of "context_code IN ..."
      instances = instances.where(context: opts[:contexts])
    elsif opts[:context]
      instances = instances.where(context: opts[:context])
    elsif opts[:only_active_courses]
      instances = instances.where(context_type: "Course", context_id: participating_course_ids)
    end

    instances
  end

  # NOTE: excludes submission stream items
  def cached_recent_stream_items(opts = {})
    expires_in = 1.day

    # just cache on the user's shard... makes cache invalidation much
    # easier if we visit other shards
    shard.activate do
      if opts[:contexts]
        items = []
        Array(opts[:contexts]).each do |context|
          items.concat(
            Rails.cache.fetch(StreamItemCache.recent_stream_items_key(self, context.class.base_class.name, context.id),
                              expires_in:) do
              recent_stream_items(context:)
            end
          )
        end
        items.sort_by(&:id).reverse
      else
        # no context in cache key
        Rails.cache.fetch(StreamItemCache.recent_stream_items_key(self), expires_in:) do
          recent_stream_items
        end
      end
    end
  end

  # NOTE: excludes submission stream items
  def recent_stream_items(opts = {})
    shard.activate do
      GuardRail.activate(:secondary) do
        visible_instances = visible_stream_item_instances(opts)
                            .preload(stream_item: :context)
                            .limit(Setting.get("recent_stream_item_limit", 100))
        visible_instances.filter_map do |sii|
          si = sii.stream_item
          next if si.blank?
          next if si.asset_type == "Submission"
          next if si.context_type == "Course" && (si.context.concluded? || participating_enrollments.none? { |e| e.course_id == si.context_id })

          si.unread = sii.unread?
          si
        end
      end
    end
  end

  def upcoming_events(opts = {})
    context_codes = opts[:context_codes] || (opts[:contexts] ? setup_context_lookups(opts[:contexts]) : cached_context_codes)
    return [] if context_codes.blank?

    now = Time.zone.now

    opts[:end_at] ||= 1.week.from_now
    opts[:limit] ||= 20

    # if we're looking through a lot of courses, we should probably not spend a lot of time
    # computing which sections are visible or not before we make the db call;
    # instead, i think we should pull for all the sections and filter after the fact
    filter_after_db = !opts[:use_db_filter] &&
                      (context_codes.grep(/\Acourse_\d+\z/).count > Setting.get("filter_events_by_section_code_threshold", "25").to_i)

    section_codes = section_context_codes(context_codes, filter_after_db)
    limit = filter_after_db ? opts[:limit] * 2 : opts[:limit] # pull extra events just in case
    events = CalendarEvent.active.for_user_and_context_codes(self, context_codes, section_codes)
                          .between(now, opts[:end_at]).limit(limit).order(:start_at).to_a.reject(&:hidden?)

    if filter_after_db
      original_count = events.count
      if events.any? { |e| e.context_code.start_with?("course_section_") }
        section_ids = events.map(&:context_code).grep(/\Acourse_section_\d+\z/).map { |s| s.delete_prefix("course_section_").to_i }
        section_course_codes = Course.joins(:course_sections).where(course_sections: { id: section_ids })
                                     .pluck(:id).map { |id| "course_#{id}" }
        visible_section_codes = section_context_codes(section_course_codes)
        events.reject! { |e| e.context_code.start_with?("course_section_") && !visible_section_codes.include?(e.context_code) }
        events = events.first(opts[:limit]) # strip down to the original limit
      end

      # if we've filtered too many (which should be unlikely), just fallback on the old behavior
      if original_count >= opts[:limit] && events.count < opts[:limit]
        return upcoming_events(opts.merge(use_db_filter: true))
      end
    end

    assignments = Assignment.published
                            .for_context_codes(context_codes)
                            .due_between_with_overrides(now, opts[:end_at])
                            .include_submitted_count.to_a

    if assignments.any?
      if AssignmentOverrideApplicator.should_preload_override_students?(assignments, self, "upcoming_events")
        AssignmentOverrideApplicator.preload_assignment_override_students(assignments, self)
      end

      events += select_available_assignments(
        select_upcoming_assignments(assignments.map { |a| a.overridden_for(self) }, opts.merge(time: now))
      )
    end

    sorted_events = events.sort_by do |e|
      due_date = e.start_at
      if e.respond_to? :dates_hash_visible_to
        e.dates_hash_visible_to(self).any? do |due_hash|
          due_date = due_hash[:due_at] if due_hash[:due_at]
        end
      end
      [due_date ? 0 : 1, due_date || 0, Canvas::ICU.collation_key(e.title)]
    end

    sorted_events.uniq.first(opts[:limit])
  end

  def select_available_assignments(assignments, include_concluded: false)
    return [] if assignments.empty?

    available_course_ids = if include_concluded
                             all_course_ids
                           else
                             Shard.partition_by_shard(assignments.map(&:context_id).uniq) do |course_ids|
                               enrollments.shard(Shard.current).where(course_id: course_ids).active_by_date.pluck(:course_id)
                             end
                           end

    assignments.select { |a| available_course_ids.include?(a.context_id) }
  end

  def select_upcoming_assignments(assignments, opts)
    time = opts[:time] || Time.zone.now
    assignments.select do |a|
      if a.context.grants_any_right?(self, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS)
        a.dates_hash_visible_to(self).any? do |due_hash|
          due_hash[:due_at] && due_hash[:due_at] >= time && due_hash[:due_at] <= opts[:end_at]
        end
      else
        a.due_at && a.due_at >= time && a.due_at <= opts[:end_at]
      end
    end
  end

  def undated_events(opts = {})
    opts = opts.dup
    context_codes = opts[:context_codes] || (opts[:contexts] ? setup_context_lookups(opts[:contexts]) : cached_context_codes)
    return [] if context_codes.blank?

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
      Rails.cache.fetch([self, "cached_context_codes", Shard.current].cache_key, expires_in: 15.minutes) do
        group_ids = groups.active.pluck(:id)
        cached_current_course_ids = Rails.cache.fetch([self, "cached_current_course_ids", Shard.current].cache_key) do
          # don't need an expires at because user will be touched if enrollment state changes from 'active'
          enrollments.shard(Shard.current).current.active_by_date.distinct.pluck(:course_id)
        end

        cached_current_course_ids.map { |id| "course_#{id}" } + group_ids.map { |id| "group_#{id}" }
      end
  end

  def cached_course_ids_for_observed_user(observed_user)
    Rails.cache.fetch_with_batched_keys(["course_ids_for_observed_user", self, observed_user].cache_key, batch_object: self, batched_keys: :enrollments, expires_in: 1.day) do
      enrollments
        .shard(in_region_associated_shards)
        .active_or_pending_by_date
        .of_observer_type
        .where(associated_user_id: observed_user)
        .pluck(:course_id)
    end
  end

  # context codes of things that might have a schedulable appointment for the
  # given user, i.e. courses and sections
  def appointment_context_codes(include_observers: false)
    @appointment_context_codes ||= {}
    @appointment_context_codes[include_observers] ||= Rails.cache.fetch([self, "cached_appointment_codes", ApplicationController.region, include_observers].cache_key, expires_in: 1.day) do
      ret = { primary: [], secondary: [] }
      cached_currentish_enrollments(preload_dates: true).each do |e|
        next unless (e.student? || (include_observers && e.observer?)) && e.active?

        ret[:primary] << "course_#{e.course_id}"
        ret[:secondary] << "course_section_#{e.course_section_id}"
      end
      ret[:secondary].concat(groups.map { |g| "group_category_#{g.group_category_id}" })
      ret
    end
  end

  def manageable_appointment_context_codes
    cache_key = [self, "cached_manageable_appointment_codes", ApplicationController.region].cache_key
    @manageable_appointment_context_codes ||= Rails.cache.fetch(cache_key, expires_in: 1.day) do
      ret = { full: [], limited: [], secondary: [] }
      limited_sections = {}
      manageable_enrollments_by_permission(:manage_calendar, cached_currentish_enrollments).each do |e|
        next if ret[:full].include?("course_#{e.course_id}")

        if e.limit_privileges_to_course_section
          ret[:limited] << "course_#{e.course_id}"
          limited_sections[e.course_id] ||= []
          limited_sections[e.course_id] << "course_section_#{e.course_section_id}"
        else
          ret[:limited].delete("course_#{e.course_id}")
          limited_sections.delete(e.course_id)
          ret[:full] << "course_#{e.course_id}"
        end
      end
      ret[:secondary] = limited_sections.values.flatten
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

    Rails.cache.fetch([self, include_concluded_codes, "conversation_context_codes4"].cache_key, expires_in: 1.day) do
      Shard.birth.activate do
        associations = %w[courses concluded_courses current_groups]
        associations.slice!(1) unless include_concluded_codes

        associations.inject([]) do |result, association|
          association_type = association.split("_")[-1].slice(0..-2)
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
        Enrollment.joins(:course)
            .where(User.enrollment_conditions(:active))
            .where(user_id: users)
            .distinct.pluck(:user_id, :course_id)
      )
      course_rows.each do |user_id, course_id|
        active_contexts[user_id] ||= []
        active_contexts[user_id] << "course_#{course_id}"
      end

      cc_rows = convert_global_id_rows(
        Enrollment.joins(:course)
            .where(User.enrollment_conditions(:completed))
            .where(user_id: users)
            .distinct.pluck(:user_id, :course_id)
      )
      cc_rows.each do |user_id, course_id|
        concluded_contexts[user_id] ||= []
        concluded_contexts[user_id] << "course_#{course_id}"
      end

      group_rows = convert_global_id_rows(
        GroupMembership.joins(:group)
            .merge(User.instance_exec(&User.reflections["current_group_memberships"].scope).only(:where))
            .where(user_id: users)
            .distinct.pluck(:user_id, :group_id)
      )
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

  def section_context_codes(context_codes, skip_visibility_filter = false)
    course_ids = context_codes.grep(/\Acourse_\d+\z/).map { |s| s.delete_prefix("course_").to_i }
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
        section_ids.concat(CourseSection.active.where(course_id: shard_course_ids).pluck(:id)
            .map { |id| Shard.relative_id_for(id, Shard.current, current_shard) })
      end
    end
    section_ids.map { |id| "course_section_#{id}" }
  end

  def manageable_courses(include_concluded = false)
    Course.manageable_by_user(id, include_concluded).not_deleted
  end

  def manageable_courses_by_query(query = "", include_concluded = false)
    manageable_courses(include_concluded).not_deleted.name_like(query).limit(50)
  end

  def last_completed_module
    context_module_progressions.select(&:completed?).max_by { |p| p.completed_at || p.created_at }.context_module rescue nil
  end

  def last_completed_course
    enrollments.select(&:completed?).max_by { |e| e.completed_at || e.created_at }.course rescue nil
  end

  def last_mastered_assignment
    learning_outcome_results.active.sort_by { |r| r.assessed_at || r.created_at }.select(&:mastery?).map(&:assignment).last
  end

  def profile_pics_folder
    initialize_default_folder(Folder::PROFILE_PICS_FOLDER_NAME)
  end

  def conversation_attachments_folder
    initialize_default_folder(Folder::CONVERSATION_ATTACHMENTS_FOLDER_NAME)
  end

  def initialize_default_folder(name)
    folder = active_folders.where(name:).first
    folder ||= folders.create!(name:,
                               parent_folder: Folder.root_folders(self).find { |f| f.name == Folder::MY_FILES_FOLDER_NAME })
    folder
  end

  def quota
    return read_attribute(:storage_quota) if read_attribute(:storage_quota)

    accounts = associated_root_accounts.reject(&:site_admin?)
    if accounts.empty?
      self.class.default_storage_quota
    else
      accounts.sum(&:default_user_storage_quota)
    end
  end

  def self.default_storage_quota
    Setting.get("user_default_quota", 50.megabytes.to_s).to_i
  end

  def update_last_user_note
    note = user_notes.active.order("user_notes.created_at").last
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

    RequestCache.cache("user_roles", self, root_account) do
      root_account.shard.activate do
        base_key = ["user_roles_for_root_account5", root_account.global_id].cache_key
        Rails.cache.fetch_with_batched_keys(base_key, batch_object: self, batched_keys: [:enrollments, :account_users]) do
          user_roles(root_account)
        end
      end
    end
  end

  def root_admin_for?(root_account, cached_account_users: nil)
    root_ids = [root_account.id, Account.site_admin.id]
    aus = cached_account_users || account_users.active
    aus.any? { |au| root_ids.include?(au.account_id) }
  end

  def eportfolios_enabled?
    # For jobs/rails consoles/specs where domain root account is not set
    return true unless Account.current_domain_root_account

    associated_root_accounts.empty? ||
      (associated_root_accounts.include?(Account.current_domain_root_account) && Account.current_domain_root_account.settings[:enable_eportfolios] != false)
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

  delegate :load_messageable_user,
           :load_messageable_users,
           :messageable_users_in_context,
           :count_messageable_users_in_context,
           :messageable_users_in_course,
           :count_messageable_users_in_course,
           :messageable_users_in_section,
           :count_messageable_users_in_section,
           :messageable_users_in_group,
           :count_messageable_users_in_group,
           :search_messageable_users,
           :messageable_sections,
           :messageable_groups,
           to: :messageable_user_calculator

  def mark_all_conversations_as_read!
    updated = conversations.unread.update_all(workflow_state: "read")
    if updated > 0
      User.where(id:).update_all(unread_conversations_count: 0)
    end
  end

  def conversation_participant(conversation_id)
    all_conversations.where(conversation_id:).first
  end

  # Public: Reset the user's cached unread conversations count.
  #
  # Returns nothing.
  def reset_unread_conversations_counter(unread_count = nil)
    unread_count ||= conversations.unread.count
    if unread_conversations_count != unread_count
      self.class.where(id:).update_all(unread_conversations_count: unread_count)
    end
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
      shard.activate do
        # Get favorites and map them to their global ids.
        context_ids = favorites.where(context_type:).pluck(:context_id).map { |id| Shard.global_id_for(id) }
        @favorite_context_ids[context_type] = context_ids
      end
    end

    # Return ids relative for the current shard
    context_ids.map do |id|
      Shard.relative_id_for(id, shard, Shard.current)
    end
  end

  def menu_courses(enrollment_uuid = nil, opts = {})
    return @menu_courses if @menu_courses

    can_favorite = proc { |c| !(c.elementary_subject_course? || c.elementary_homeroom_course?) || c.user_is_admin?(self) || roles(c.root_account).include?("teacher") }
    # this terribleness is so we try to make sure that the newest courses show up in the menu
    courses = courses_with_primary_enrollment(:current_and_invited_courses, enrollment_uuid, opts)
              .sort_by { |c| [c.primary_enrollment_rank, Time.now - (c.primary_enrollment_date || Time.now)] }
              .first(Setting.get("menu_course_limit", "20").to_i)
              .sort_by { |c| [c.primary_enrollment_rank, Canvas::ICU.collation_key(c.name)] }
    favorites = courses_with_primary_enrollment(:favorite_courses, enrollment_uuid, opts)
                .select { |c| can_favorite.call(c) }
    # if favoritable courses (classic courses or k5 courses with admin enrollment) exist, show those and all non-favoritable courses
    @menu_courses = if favorites.empty?
                      courses
                    else
                      favorites + courses.reject { |c| can_favorite.call(c) }
                    end
    ActiveRecord::Associations.preload(@menu_courses, :enrollment_term)
    @menu_courses
  end

  def user_can_edit_name?
    accounts = pseudonyms.shard(self).active.map(&:account)
    return true if accounts.empty?

    accounts.any?(&:users_can_edit_name?)
  end

  def user_can_edit_profile?
    accounts = pseudonyms.shard(self).active.map(&:account)
    return true if accounts.empty?

    accounts.any?(&:users_can_edit_profile?)
  end

  def user_can_edit_comm_channels?
    accounts = pseudonyms.shard(self).active.map(&:account)
    return true if accounts.empty?

    accounts.any?(&:users_can_edit_comm_channels?)
  end

  def suspended?
    active_pseudonyms.empty? ? false : active_pseudonyms.all?(&:suspended?)
  end

  def limit_parent_app_web_access?
    pseudonyms.shard(self).active.map(&:account).any?(&:limit_parent_app_web_access?)
  end

  def sections_for_course(course)
    course.student_enrollments.active.for_user(self).map(&:course_section)
  end

  def can_create_enrollment_for?(course, session, type)
    return false if %w[StudentEnrollment ObserverEnrollment].include?(type) && MasterCourses::MasterTemplate.is_master_course?(course)
    return false if course.template?

    if course.root_account.feature_enabled?(:granular_permissions_manage_users)
      return true if type == "TeacherEnrollment" && course.grants_right?(self, session, :add_teacher_to_course)
      return true if type == "TaEnrollment" && course.grants_right?(self, session, :add_ta_to_course)
      return true if type == "DesignerEnrollment" && course.grants_right?(self, session, :add_designer_to_course)
      return true if type == "StudentEnrollment" && course.grants_right?(self, session, :add_student_to_course)
      return true if type == "ObserverEnrollment" && course.grants_right?(self, session, :add_observer_to_course)
    else
      if type != "StudentEnrollment" && course.grants_right?(self, session, :manage_admin_users)
        return true
      end
      if %w[StudentEnrollment ObserverEnrollment].include?(type) && course.grants_right?(self, session, :manage_students)
        return true
      end
    end
    false
  end

  def can_be_enrolled_in_course?(course)
    !!SisPseudonym.for(self, course, type: :implicit, require_sis: false) ||
      (creation_pending? && enrollments.where(course_id: course).exists?)
  end

  def group_member_json(context)
    h = { user_id: id, name: last_name_first, display_name: self.short_name }
    if context.is_a?(Course)
      sections_for_course(context).each do |section|
        h[:sections] ||= []
        h[:sections] << { section_id: section.id, section_code: section.section_code }
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
      active_pseudonyms = all_active_pseudonyms(:reload).select { |p| !p.password_auto_generated? && !p.account.delegated_authentication? }
      templates = []
      # re-arrange in the order we prefer
      templates.concat(active_pseudonyms.select { |p| p.account_id == preferred_template_account.id }) if preferred_template_account
      templates.concat(active_pseudonyms.select { |p| p.account_id == Account.site_admin.id })
      templates.concat(active_pseudonyms.select { |p| p.account_id == Account.default.id })
      templates.concat(active_pseudonyms)
      templates.uniq!

      template = templates.detect { |t| !account.pseudonyms.active.by_unique_id(t.unique_id).first }
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
    preferences[:fake_student] && !!enrollments.where(type: "StudentViewEnrollment").first
  end

  def private?
    !public?
  end

  def profile
    super || build_profile
  end

  def parse_otp_remember_me_cookie(cookie)
    return 0, [], nil unless cookie

    time, *ips, hmac = cookie.split("-")
    [time, ips, hmac]
  end

  def otp_secret_key_remember_me_cookie(time, current_cookie, remote_ip = nil, options = {})
    _, ips, _ = parse_otp_remember_me_cookie(current_cookie)
    cookie = [time.to_i, *[*ips, remote_ip].compact.sort].join("-")

    hmac_string = "#{cookie}.#{otp_secret_key}"
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

    Canvas::Security.decrypt_password(otp_secret_key_enc, otp_secret_key_salt, "otp_secret_key", shard.settings[:encryption_key]) if otp_secret_key_enc
  end

  def otp_secret_key=(key)
    if key
      self.otp_secret_key_enc, self.otp_secret_key_salt = Canvas::Security.encrypt_password(key, "otp_secret_key")
    else
      self.otp_secret_key_enc = self.otp_secret_key_salt = nil
    end
  end

  def crocodoc_id!
    cid = read_attribute(:crocodoc_id)
    return cid if cid

    Setting.transaction do
      s = Setting.lock.where(name: "crocodoc_counter").first_or_create(value: 0)
      cid = s.value = s.value.to_i + 1
      s.save!
    end

    update_attribute(:crocodoc_id, cid)
    cid
  end

  def crocodoc_user
    "#{crocodoc_id!},#{short_name.delete(",")}"
  end

  def moderated_grading_ids(create_crocodoc_id = false)
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
                          (mfa_settings == :required_for_admins && !pseudonym_hint.account.cached_all_account_users_for(self).empty?)
    end
    return :required if pseudonym_hint&.authentication_provider&.mfa_required?

    pseudonyms = self.pseudonyms.shard(self).preload(:account, authentication_provider: :account)
    return :required if pseudonyms.any? { |p| p.authentication_provider&.mfa_required? }

    result = pseudonyms.map(&:account).uniq.map do |account|
      case account.mfa_settings
      when :disabled
        0
      when :optional
        1
      when :required_for_admins
        # if pseudonym_hint is given, and we got to here, we don't need
        # to redo the expensive all_account_users_for check
        if (pseudonym_hint && pseudonym_hint.account == account) ||
           account.cached_all_account_users_for(self).empty?
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

    [:disabled, :optional][result]
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
    user_bucket = id % DelayedMessage::MINUTES_PER_WEEKLY_ACCOUNT_BUCKET
    (account_bucket * DelayedMessage::MINUTES_PER_WEEKLY_ACCOUNT_BUCKET) + user_bucket
  end

  def daily_notification_time
    # The time daily notifications are sent out is 6pm local time. This is
    # referencing the definition in our documentation and in DelayedMessage#set_send_at
    time_zone = self.time_zone || ActiveSupport::TimeZone["America/Denver"] || Time.zone
    target = time_zone.now.change(hour: 18)
    target += 1.day if target < time_zone.now
    target
  end

  def weekly_notification_time
    # weekly notification scheduling happens in Eastern-time
    time_zone = ActiveSupport::TimeZone.us_zones.find { |zone| zone.name == "Eastern Time (US & Canada)" }

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
    time_zone = ActiveSupport::TimeZone.us_zones.find { |zone| zone.name == "Eastern Time (US & Canada)" }

    # start on January first instead of "today" to avoid DST, but still move to
    # a saturday from there so we get the right day-of-week on start_hour
    target = time_zone.now.change(month: 1, day: 1).next_week - 2.days + weekly_notification_bucket.minutes

    # 2 hour on-the-hour span around the target such that distance from the
    # start hour is at least 30 minutes.
    start_hour = target - 30.minutes
    start_hour = start_hour.change(hour: start_hour.hour)
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
    type = type.to_s.downcase.sub(/(view)?enrollment/, "")
    %w[student teacher ta observer].include?(type) ? type : nil
  end

  def self.preload_shard_associations(users); end

  def associated_shards(strength = :strong)
    (strength == :strong) ? [Shard.default] : []
  end

  def in_region_associated_shards
    associated_shards.select { |shard| shard.in_current_region? || shard.default? }
  end

  def adminable_accounts_cache_key
    ["adminable_accounts_1", self, ApplicationController.region].cache_key
  end

  def clear_adminable_accounts_cache!
    Rails.cache.delete(adminable_accounts_cache_key)
  end

  def adminable_accounts_scope(shard_scope: in_region_associated_shards)
    # i couldn't get EXISTS (?) to work multi-shard, so this is happening instead
    account_ids = account_users.active.shard(shard_scope).distinct.pluck(:account_id)
    Account.active.where(id: account_ids)
  end

  def adminable_accounts
    @adminable_accounts ||= shard.activate do
      Rails.cache.fetch(adminable_accounts_cache_key) do
        adminable_accounts_scope.order(:id).to_a
      end
    end
  end

  def all_paginatable_accounts
    ShardedBookmarkedCollection.build(Account::Bookmarker, adminable_accounts_scope.order(:name, :id))
  end

  def all_pseudonyms_loaded?
    !!@all_pseudonyms
  end

  def all_pseudonyms
    @all_pseudonyms ||= pseudonyms.shard(self).to_a
  end

  def all_active_pseudonyms_loaded?
    !!@all_active_pseudonyms
  end

  def current_active_groups?
    return @_current_active_groups if defined?(@_current_active_groups)

    @_current_active_groups = shard.activate do
      Rails.cache.fetch_with_batched_keys(["current_active_groups", ApplicationController.region].cache_key, batch_object: self, batched_keys: :groups) do
        return true if current_groups.preload(:context).any?(&:context_available?)
        return true if current_groups.shard(in_region_associated_shards).preload(:context).any?(&:context_available?)

        false
      end
    end
  end

  def all_active_pseudonyms(reload = false)
    @all_active_pseudonyms = nil if reload
    @all_active_pseudonyms ||= pseudonyms.shard(self).active.to_a
  end

  def preferred_gradebook_version
    get_preference(:gradebook_version) || "default"
  end

  def should_show_deeply_nested_alert?
    ActiveModel::Type::Boolean.new.cast(get_preference(:split_screen_view_deeply_nested_alert) || true)
  end

  def stamp_logout_time!
    User.where(id: self).update_all(last_logged_out: Time.zone.now)
  end

  def content_exports_visible_to(user)
    content_exports.where(user_id: user)
  end

  def show_bouncing_channel_message!
    unless show_bouncing_channel_message?
      preferences[:show_bouncing_channel_message] = true
      save!
    end
  end

  def show_bouncing_channel_message?
    !!preferences[:show_bouncing_channel_message]
  end

  def dismiss_bouncing_channel_message!
    if show_bouncing_channel_message?
      preferences[:show_bouncing_channel_message] = false
      save!
    end
  end

  def bouncing_channel_message_dismissed?
    preferences[:show_bouncing_channel_message] == false
  end

  def update_bouncing_channel_message!(channel = nil)
    force_set_bouncing = channel&.bouncing? && !channel.imported?
    return show_bouncing_channel_message! if force_set_bouncing

    sis_channel_ids = pseudonyms.shard(self).where.not(sis_communication_channel_id: nil).pluck(:sis_communication_channel_id)
    set_bouncing = communication_channels.unretired.bouncing.where.not(id: sis_channel_ids).exists?

    if set_bouncing
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
        parent_folder = submissions_folder
        Folder.unique_constraint_retry do
          folders.where(parent_folder_id: parent_folder, submission_context_code: for_course.asset_string)
                 .first_or_create!(name: for_course.name)
        end
      else
        return @submissions_folder if @submissions_folder

        Folder.unique_constraint_retry do
          @submissions_folder = folders.where(parent_folder_id: Folder.root_folders(self).first,
                                              submission_context_code: "root")
                                       .first_or_create!(name: I18n.t("Submissions", locale:))
        end
      end
    end
  end

  def authenticate_one_time_password(code)
    result = one_time_passwords.where(code:, used: false).take
    return unless result
    # atomically update used
    return unless one_time_passwords.where(used: false, id: result).update_all(used: true, updated_at: Time.now.utc) == 1

    result
  end

  def generate_one_time_passwords(regenerate: false)
    regenerate ||= !one_time_passwords.exists?
    return unless regenerate

    one_time_passwords.scope.delete_all
    Setting.get("one_time_password_count", 10).to_i.times { one_time_passwords.create! }
  end

  def user_roles(root_account, exclude_deleted_accounts = nil)
    roles = ["user"]
    enrollment_types = GuardRail.activate(:secondary) do
      root_account.all_enrollments.where(user_id: self, workflow_state: "active").distinct.pluck(:type)
    end
    roles << "student" if enrollment_types.intersect?(%w[StudentEnrollment StudentViewEnrollment])
    roles << "fake_student" if fake_student?
    roles << "observer" if enrollment_types.intersect?(%w[ObserverEnrollment])
    roles << "teacher" if enrollment_types.intersect?(%w[TeacherEnrollment TaEnrollment DesignerEnrollment])
    account_users = GuardRail.activate(:secondary) do
      root_account.cached_all_account_users_for(self)
    end

    if exclude_deleted_accounts
      account_users = account_users.select { |a| a.account.workflow_state == "active" }
    end

    if account_users.any?
      roles << "admin"
      roles << "root_admin" if root_admin_for?(root_account, cached_account_users: account_users)
      roles << "consortium_admin" if account_users.any? { |au| au.shard != root_account.shard }
    end
    roles
  end

  # user tokens are returned by UserListV2 and used to bulk-enroll users using information that isn't easy to guess
  def self.token(id, uuid)
    "#{id}_#{Digest::SHA256.hexdigest(uuid)}"
  end

  def token
    User.token(id, uuid)
  end

  def self.from_tokens(tokens)
    id_token_map = tokens.each_with_object({}) do |token, map|
      id, huuid = token.split("_")
      id = Shard.relative_id_for(id, Shard.current, Shard.current)
      map[id] = "#{id}_#{huuid}"
    end
    User.where(id: id_token_map.keys).to_a.select { |u| u.token == id_token_map[u.id] }
  end

  def generate_observer_pairing_code
    code = nil
    loop do
      code = SecureRandom.base64.gsub(/\W/, "")[0..5]
      break unless ObserverPairingCode.active.where(code:).exists?
    end
    observer_pairing_codes.create(expires_at: 7.days.from_now, code:)
  end

  def pronouns
    translate_pronouns(read_attribute(:pronouns))
  end

  def pronouns=(pronouns)
    write_attribute(:pronouns, untranslate_pronouns(pronouns))
  end

  def create_courses_right(account)
    return :admin if account.cached_account_users_for(self).any? do |au|
                       au.permission_check(account, :manage_courses).success? || au.permission_check(account, :manage_courses_add).success?
                     end
    return nil if fake_student? || account.root_account.site_admin?

    scope = account.root_account.enrollments.active.where(user_id: self)
    teacher_right = account.root_account.teachers_can_create_courses? && scope.where(type: %w[TeacherEnrollment DesignerEnrollment]).exists?
    # k5 users can still create courses anywhere, even if the setting restricts them to the manually created courses account
    return :teacher if teacher_right && (account.root_account.teachers_can_create_courses_anywhere? || active_k5_enrollments?)
    return :teacher if teacher_right && account == account.root_account.manually_created_courses_account

    student_right = account.root_account.students_can_create_courses? && scope.where(type: %w[StudentEnrollment ObserverEnrollment]).exists?
    return :student if student_right && (account.root_account.students_can_create_courses_anywhere? || active_k5_enrollments?)
    return :student if student_right && account == account.root_account.manually_created_courses_account
    return :no_enrollments if account.root_account.no_enrollments_can_create_courses? && !scope.exists? && account == account.root_account.manually_created_courses_account

    nil
  end

  def all_account_calendars
    account_user_account_ids = []
    active_account_users = account_users.active
    if active_account_users.any?
      active_accounts = Account.active.where(id: active_account_users.select(:account_id), account_calendar_visible: true)
      account_user_account_ids = active_accounts.reduce([]) do |descendants, account|
        descendants.concat(Account.sub_account_ids_recursive(account.id))
      end
    end
    associated_accounts_ids = unordered_associated_accounts.shard(in_region_associated_shards).select(:id)
    Account.active.where(id: [associated_accounts_ids + account_user_account_ids], account_calendar_visible: true)
  end

  def enabled_account_calendars
    acct_cals = all_account_calendars
    acct_cals.where(id: get_preference(:enabled_account_calendars) || []).or(acct_cals.where(account_calendar_subscription_type: "auto"))
  end

  def inbox_labels
    preferences[:inbox_labels] || []
  end

  # Returns all sub accounts that the user can administer
  # On the shard the starting_root_account resides on.
  #
  # This method first plucks (and caches) the adminable account
  # IDs and then makes a second query to fetch the accounts.
  #
  # This two-query approach was taken intentionally: We do have to store
  # the plucked IDs in memory and make a second query, but it
  # means we can return an ActiveRecord::Relation instead of an Array.
  #
  # This is important to prevent initializing _all_ adminable account
  # models into memory, even if this scope is used in a controller processing
  # a request with pagination params that require a single, small page.
  def adminable_accounts_recursive(starting_root_account:)
    starting_root_account.shard.activate do
      Account.where(id: adminable_account_ids_recursive(starting_root_account:))
    end
  end

  def adminable_account_ids_recursive(starting_root_account:)
    starting_root_account.shard.activate do
      Rails.cache.fetch(
        adminable_account_ids_cache_key(starting_root_account:),
        expires_in: 5.minutes
      ) do
        Account.select(:id, :parent_account_id, :workflow_state).active.multi_parent_sub_accounts_recursive(
          adminable_accounts_scope(
            shard_scope: starting_root_account.shard
          ).where(
            root_account: starting_root_account
          )
        ).pluck(:id)
      end
    end
  end

  def adminable_account_ids_cache_key(starting_root_account:)
    [
      "adminable_account_ids_recursive",
      global_id,
      "starting_root_account",
      starting_root_account.global_id,
    ].cache_key
  end
  private :adminable_account_ids_cache_key
end
