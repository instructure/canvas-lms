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

class Course < ActiveRecord::Base
  include Context
  include Workflow
  include TextHelper
  include HtmlTextHelper
  include TimeZoneHelper
  include ContentLicenses
  include TurnitinID
  include Courses::ItemVisibilityHelper
  include Courses::ExportWarnings
  include OutcomeImportContext
  include MaterialChanges

  attr_accessor :teacher_names, :master_course, :primary_enrollment_role, :saved_by
  attr_writer :student_count, :teacher_count, :primary_enrollment_type, :primary_enrollment_role_id, :primary_enrollment_rank, :primary_enrollment_state, :primary_enrollment_date, :invitation, :master_migration

  time_zone_attribute :time_zone
  def time_zone
    if read_attribute(:time_zone)
      super
    else
      RequestCache.cache("account_time_zone", root_account_id) do
        root_account.default_time_zone
      end
    end
  end

  serialize :tab_configuration
  serialize :settings, type: Hash
  belongs_to :root_account, class_name: "Account"
  belongs_to :abstract_course
  belongs_to :enrollment_term
  belongs_to :template_course, class_name: "Course"
  has_many :templated_courses, class_name: "Course", foreign_key: "template_course_id"
  has_many :templated_accounts, class_name: "Account", foreign_key: "course_template_id"

  belongs_to :linked_homeroom_course, class_name: "Course", foreign_key: "homeroom_course_id"

  has_many :course_sections, inverse_of: :course
  has_many :active_course_sections, -> { where(workflow_state: "active") }, class_name: "CourseSection", inverse_of: :course
  has_many :enrollments, -> { where("enrollments.workflow_state<>'deleted'") }, inverse_of: :course

  has_many :all_enrollments, class_name: "Enrollment", inverse_of: :course
  has_many :current_enrollments, -> { where("enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted', 'inactive')").preload(:user) }, class_name: "Enrollment"
  has_many :all_current_enrollments, -> { where("enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted')").preload(:user) }, class_name: "Enrollment"
  has_many :prior_enrollments, -> { preload(:user, :course).where(workflow_state: "completed") }, class_name: "Enrollment"
  has_many :prior_users, through: :prior_enrollments, source: :user
  has_many :prior_students, -> { where(enrollments: { type: ["StudentEnrollment", "StudentViewEnrollment"], workflow_state: "completed" }) }, through: :enrollments, source: :user

  has_many :participating_enrollments, -> { where(enrollments: { workflow_state: "active" }).preload(:user) }, class_name: "Enrollment", inverse_of: :course

  has_many :participating_students, -> { where(enrollments: { type: ["StudentEnrollment", "StudentViewEnrollment"], workflow_state: "active" }) }, through: :enrollments, source: :user
  has_many :participating_students_by_date,
           lambda {
             where(enrollments: { type: ["StudentEnrollment", "StudentViewEnrollment"], workflow_state: "active" })
               .joins("INNER JOIN #{EnrollmentState.quoted_table_name} ON enrollment_states.enrollment_id=enrollments.id")
               .where(enrollment_states: { state: "active" })
           },
           through: :all_enrollments,
           source: :user

  has_many :student_enrollments, -> { where("enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted', 'inactive') AND enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment')").preload(:user) }, class_name: "Enrollment"
  has_many :student_enrollments_including_completed, -> { where("enrollments.workflow_state NOT IN ('rejected', 'deleted', 'inactive') AND enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment')").preload(:user) }, class_name: "Enrollment", inverse_of: :course
  has_many :students, through: :student_enrollments, source: :user
  has_many :self_enrolled_students, -> { where("self_enrolled") }, through: :student_enrollments, source: :user
  has_many :admin_visible_student_enrollments, -> { where("enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted') AND enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment')").preload(:user) }, class_name: "Enrollment"
  has_many :admin_visible_students, through: :admin_visible_student_enrollments, source: :user
  has_many :gradable_student_enrollments, -> { where(enrollments: { workflow_state: ["active", "inactive"], type: ["StudentEnrollment", "StudentViewEnrollment"] }).preload(:user) }, class_name: "Enrollment"
  has_many :gradable_students, through: :gradable_student_enrollments, source: :user
  has_many :all_student_enrollments, -> { where("enrollments.workflow_state<>'deleted' AND enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment')").preload(:user) }, class_name: "Enrollment"
  has_many :all_student_enrollments_including_deleted, -> { where("enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment')").preload(:user) }, class_name: "Enrollment"
  has_many :all_students, through: :all_student_enrollments, source: :user
  has_many :all_students_including_deleted, through: :all_student_enrollments_including_deleted, source: :user
  has_many :all_accepted_student_enrollments, -> { where("enrollments.workflow_state NOT IN ('rejected', 'deleted') AND enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment')").preload(:user) }, class_name: "Enrollment"
  has_many :all_accepted_students, -> { distinct }, through: :all_accepted_student_enrollments, source: :user
  has_many :all_real_enrollments, -> { where("enrollments.workflow_state<>'deleted' AND enrollments.type<>'StudentViewEnrollment'").preload(:user) }, class_name: "Enrollment"
  has_many :all_real_users, through: :all_real_enrollments, source: :user
  has_many :all_real_student_enrollments, -> { where("enrollments.type = 'StudentEnrollment' AND enrollments.workflow_state <> 'deleted'").preload(:user) }, class_name: "StudentEnrollment"
  has_many :all_real_students, through: :all_real_student_enrollments, source: :user
  has_many :teacher_enrollments, -> { where("enrollments.workflow_state NOT IN ('rejected', 'deleted') AND enrollments.type = 'TeacherEnrollment'").preload(:user) }, class_name: "TeacherEnrollment"
  has_many :teachers, -> { order("sortable_name") }, through: :teacher_enrollments, source: :user
  has_many :ta_enrollments, -> { where("enrollments.workflow_state NOT IN ('rejected', 'deleted')").preload(:user) }, class_name: "TaEnrollment"
  has_many :tas, through: :ta_enrollments, source: :user
  has_many :observer_enrollments, -> { where("enrollments.workflow_state NOT IN ('rejected', 'deleted')").preload(:user) }, class_name: "ObserverEnrollment"
  has_many :observers, through: :observer_enrollments, source: :user
  has_many :non_observer_enrollments,
           lambda {
             where("enrollments.workflow_state NOT IN ('rejected', 'deleted') AND enrollments.type<>'ObserverEnrollment'")
               .preload(:user)
           },
           class_name: "Enrollment"
  has_many :enrollments_excluding_linked_observers,
           lambda {
             where("enrollments.workflow_state NOT IN ('rejected', 'deleted') AND NOT (enrollments.type = 'ObserverEnrollment' AND enrollments.associated_user_id IS NOT NULL)")
               .preload(:user)
           },
           class_name: "Enrollment"
  has_many :participating_observers, -> { where(enrollments: { workflow_state: "active" }) }, through: :observer_enrollments, source: :user
  has_many :participating_observers_by_date,
           lambda {
             where(enrollments: { type: "ObserverEnrollment", workflow_state: "active" })
               .joins("INNER JOIN #{EnrollmentState.quoted_table_name} ON enrollment_states.enrollment_id=enrollments.id")
               .where(enrollment_states: { state: "active" })
           },
           through: :all_enrollments,
           source: :user

  has_many :instructors, -> { where(enrollments: { type: ["TaEnrollment", "TeacherEnrollment"] }) }, through: :enrollments, source: :user
  has_many :instructor_enrollments, -> { where(type: ["TaEnrollment", "TeacherEnrollment"]) }, class_name: "Enrollment"
  has_many :participating_instructors, -> { where(enrollments: { type: ["TaEnrollment", "TeacherEnrollment"], workflow_state: "active" }) }, through: :enrollments, source: :user
  has_many :participating_instructors_by_date,
           lambda {
             where(enrollments: { type: ["TaEnrollment", "TeacherEnrollment"], workflow_state: "active" })
               .joins("INNER JOIN #{EnrollmentState.quoted_table_name} ON enrollment_states.enrollment_id=enrollments.id")
               .where(enrollment_states: { state: "active" })
           },
           through: :all_enrollments,
           source: :user

  has_many :admins, -> { where(enrollments: { type: %w[TaEnrollment TeacherEnrollment DesignerEnrollment] }) }, through: :enrollments, source: :user
  has_many :admin_enrollments, -> { where(type: %w[TaEnrollment TeacherEnrollment DesignerEnrollment]) }, class_name: "Enrollment"
  has_many :participating_admins, -> { where(enrollments: { type: %w[TaEnrollment TeacherEnrollment DesignerEnrollment], workflow_state: "active" }) }, through: :enrollments, source: :user
  has_many :participating_admins_by_date,
           lambda {
             where(enrollments: { type: %w[TaEnrollment TeacherEnrollment DesignerEnrollment], workflow_state: "active" })
               .joins("INNER JOIN #{EnrollmentState.quoted_table_name} ON enrollment_states.enrollment_id=enrollments.id")
               .where(enrollment_states: { state: "active" })
           },
           through: :all_enrollments,
           source: :user

  has_many :student_view_enrollments, -> { where("enrollments.workflow_state<>'deleted'").preload(:user) }, class_name: "StudentViewEnrollment"
  has_many :student_view_students, through: :student_view_enrollments, source: :user
  has_many :custom_gradebook_columns, -> { order("custom_gradebook_columns.position, custom_gradebook_columns.title") }, dependent: :destroy

  include LearningOutcomeContext
  include RubricContext

  has_many :course_account_associations
  has_many :users, -> { distinct }, through: :enrollments, source: :user
  has_many :all_users, -> { distinct }, through: :all_enrollments, source: :user
  has_many :current_users, -> { distinct }, through: :current_enrollments, source: :user
  has_many :all_current_users, -> { distinct }, through: :all_current_enrollments, source: :user
  has_many :active_users, -> { distinct }, through: :participating_enrollments, source: :user
  has_many :user_past_lti_ids, as: :context, inverse_of: :context
  has_many :group_categories, -> { where(deleted_at: nil) }, as: :context, inverse_of: :context
  has_many :all_group_categories, class_name: "GroupCategory", as: :context, inverse_of: :context
  has_many :groups, as: :context, inverse_of: :context
  has_many :active_groups, -> { where("groups.workflow_state<>'deleted'") }, as: :context, inverse_of: :context, class_name: "Group"
  has_many :assignment_groups, -> { order("assignment_groups.position", AssignmentGroup.best_unicode_collation_key("assignment_groups.name")) }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :assignments, -> { order("assignments.created_at") }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :calendar_events, -> { where("calendar_events.workflow_state<>'cancelled'") }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :submissions, -> { active.order("submissions.updated_at DESC") }, inverse_of: :course, dependent: :destroy
  has_many :submission_comments, -> { published }, as: :context, inverse_of: :context
  has_many :discussion_topics, -> { where("discussion_topics.workflow_state<>'deleted'").preload(:user).order("discussion_topics.position DESC, discussion_topics.created_at DESC") }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :active_discussion_topics, -> { where("discussion_topics.workflow_state<>'deleted'").preload(:user) }, as: :context, inverse_of: :context, class_name: "DiscussionTopic"
  has_many :all_discussion_topics, -> { preload(:user) }, as: :context, inverse_of: :context, class_name: "DiscussionTopic", dependent: :destroy
  has_many :discussion_entries, -> { preload(:discussion_topic, :user) }, through: :discussion_topics, dependent: :destroy
  has_many :announcements, as: :context, inverse_of: :context, class_name: "Announcement", dependent: :destroy
  has_many :active_announcements, -> { where("discussion_topics.workflow_state<>'deleted'") }, as: :context, inverse_of: :context, class_name: "Announcement"
  has_many :attachments, as: :context, inverse_of: :context, dependent: :destroy, extend: Attachment::FindInContextAssociation
  has_many :active_images, -> { where("attachments.file_state<>? AND attachments.content_type LIKE 'image%'", "deleted").order("attachments.display_name").preload(:thumbnail) }, as: :context, inverse_of: :context, class_name: "Attachment"
  has_many :active_assignments, -> { where("assignments.workflow_state<>'deleted'").order("assignments.title, assignments.position") }, as: :context, inverse_of: :context, class_name: "Assignment"
  has_many :folders, -> { order("folders.name") }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :active_folders, -> { where("folders.workflow_state<>'deleted'").order("folders.name") }, class_name: "Folder", as: :context, inverse_of: :context
  has_many :messages, as: :context, inverse_of: :context, dependent: :destroy
  has_many :context_external_tools, -> { order("name") }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :tool_proxies, class_name: "Lti::ToolProxy", as: :context, inverse_of: :context, dependent: :destroy
  belongs_to :wiki
  has_many :wiki_pages, as: :context, inverse_of: :context
  has_many :wiki_page_lookups, as: :context, inverse_of: :context
  has_many :quizzes, -> { order("lock_at, title, id") }, class_name: "Quizzes::Quiz", as: :context, inverse_of: :context, dependent: :destroy
  has_many :quiz_questions, class_name: "Quizzes::QuizQuestion", through: :quizzes
  has_many :active_quizzes, -> { preload(:assignment).where("quizzes.workflow_state<>'deleted'").order(:created_at) }, class_name: "Quizzes::Quiz", as: :context, inverse_of: :context
  has_many :assessment_question_banks, -> { preload(:assessment_questions, :assessment_question_bank_users) }, as: :context, inverse_of: :context
  has_many :assessment_questions, through: :assessment_question_banks
  def inherited_assessment_question_banks(include_self = false)
    account.inherited_assessment_question_banks(true, *(include_self ? [self] : []))
  end

  has_many :external_feeds, as: :context, inverse_of: :context, dependent: :destroy
  belongs_to :grading_standard
  has_many :grading_standards, -> { where("workflow_state<>'deleted'") }, as: :context, inverse_of: :context
  has_many :web_conferences, -> { order("created_at DESC") }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :collaborations, -> { order(Arel.sql("collaborations.title, collaborations.created_at")) }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :context_modules, -> { ordered }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :context_module_progressions, through: :context_modules
  has_many :active_context_modules, -> { where(workflow_state: "active") }, as: :context, inverse_of: :context, class_name: "ContextModule"
  has_many :context_module_tags, -> { ordered.where(tag_type: "context_module") }, class_name: "ContentTag", as: :context, inverse_of: :context, dependent: :destroy
  has_many :media_objects, as: :context, inverse_of: :context
  has_many :page_views, as: :context, inverse_of: :context
  has_many :asset_user_accesses, as: :context, inverse_of: :context
  has_many :role_overrides, as: :context, inverse_of: :context
  has_many :content_migrations, as: :context, inverse_of: :context
  has_many :content_exports, as: :context, inverse_of: :context
  has_many :epub_exports, -> { where(type: nil).order("created_at DESC") }

  has_many :gradebook_filters, inverse_of: :course, dependent: :destroy
  attr_accessor :latest_epub_export

  has_many :web_zip_exports, -> { where(type: "WebZipExport") }
  has_many :alerts, -> { preload(:criteria) }, as: :context, inverse_of: :context
  has_many :appointment_group_contexts, as: :context, inverse_of: :context
  has_many :appointment_groups, through: :appointment_group_contexts
  has_many :appointment_participants, -> { where("workflow_state = 'locked' AND parent_calendar_event_id IS NOT NULL") }, class_name: "CalendarEvent", foreign_key: :effective_context_code, primary_key: :asset_string

  has_many :content_participation_counts, as: :context, inverse_of: :context, dependent: :destroy
  has_many :poll_sessions, class_name: "Polling::PollSession", dependent: :destroy
  has_many :grading_period_groups, dependent: :destroy
  has_many :grading_periods, through: :grading_period_groups
  has_many :usage_rights, as: :context, inverse_of: :context, class_name: "UsageRights", dependent: :destroy

  has_many :custom_grade_statuses, -> { active }, through: :root_account
  has_many :sis_post_grades_statuses

  has_many :progresses, as: :context, inverse_of: :context
  has_many :gradebook_csvs, inverse_of: :course, class_name: "GradebookCSV"

  has_many :master_course_templates, class_name: "MasterCourses::MasterTemplate"
  # only valid if non-nil
  attr_accessor :is_master_course

  has_many :master_course_subscriptions, class_name: "MasterCourses::ChildSubscription", foreign_key: "child_course_id"
  has_one :late_policy, dependent: :destroy, inverse_of: :course
  has_many :quiz_migration_alerts, dependent: :destroy
  has_many :notification_policy_overrides, as: :context, inverse_of: :context

  has_many :post_policies, dependent: :destroy, inverse_of: :course
  has_many :assignment_post_policies, -> { where.not(assignment_id: nil) }, class_name: "PostPolicy", inverse_of: :course
  has_one :default_post_policy, -> { where(assignment_id: nil) }, class_name: "PostPolicy", inverse_of: :course

  has_one :course_score_statistic, dependent: :destroy
  has_many :auditor_course_records,
           class_name: "Auditors::ActiveRecord::CourseRecord",
           dependent: :destroy,
           inverse_of: :course
  has_many :auditor_grade_change_records,
           as: :context,
           inverse_of: :course,
           class_name: "Auditors::ActiveRecord::GradeChangeRecord",
           dependent: :destroy
  has_many :lti_resource_links,
           as: :context,
           inverse_of: :context,
           class_name: "Lti::ResourceLink",
           dependent: :destroy

  has_many :conditional_release_rules, inverse_of: :course, class_name: "ConditionalRelease::Rule", dependent: :destroy
  has_one :outcome_proficiency, -> { preload(:outcome_proficiency_ratings) }, as: :context, inverse_of: :context, dependent: :destroy
  has_one :outcome_calculation_method, as: :context, inverse_of: :context, dependent: :destroy

  has_one :microsoft_sync_group, class_name: "MicrosoftSync::Group", dependent: :destroy, inverse_of: :course
  has_many :microsoft_sync_partial_sync_changes, class_name: "MicrosoftSync::PartialSyncChange", dependent: :destroy, inverse_of: :course

  has_many :comment_bank_items, inverse_of: :course

  has_many :course_paces
  has_many :blackout_dates, as: :context, inverse_of: :context

  prepend Profile::Association

  before_save :assign_uuid
  before_validation :assert_defaults
  before_save :update_enrollments_later
  before_save :update_show_total_grade_as_on_weighting_scheme_change
  before_save :set_self_enrollment_code
  before_save :validate_license
  after_save :update_final_scores_on_weighting_scheme_change
  after_save :update_account_associations_if_changed
  after_save :update_enrollment_states_if_necessary
  after_save :clear_caches_if_necessary
  after_save :log_published_assignment_count
  after_commit :update_cached_due_dates

  after_create :set_default_post_policy
  after_create :copy_from_course_template
  after_create :set_restrict_quantitative_data_when_needed

  after_update :clear_cached_short_name, if: :saved_change_to_course_code?
  after_update :log_create_to_publish_time, if: :saved_change_to_workflow_state?
  after_update :track_end_date_stats
  after_update :log_course_pacing_publish_update, if: :saved_change_to_workflow_state?
  after_update :log_course_format_publish_update, if: :saved_change_to_workflow_state?
  after_update :log_course_pacing_settings_update, if: :change_to_logged_settings?
  after_update :log_rqd_setting_enable_or_disable

  before_update :handle_syllabus_changes_for_master_migration

  before_save :touch_root_folder_if_necessary
  before_validation :verify_unique_ids
  validate :validate_course_dates
  validate :validate_course_image
  validate :validate_banner_image
  validate :validate_default_view
  validate :validate_template
  validate :validate_not_on_siteadmin
  validates :sis_source_id, uniqueness: { scope: :root_account }, allow_nil: true
  validates :account_id, :root_account_id, :enrollment_term_id, :workflow_state, presence: true
  validates :syllabus_body, length: { maximum: maximum_long_text_length, allow_blank: true }
  validates :name, length: { maximum: maximum_string_length, allow_blank: true }
  validates :sis_source_id, length: { maximum: maximum_string_length, allow_nil: true, allow_blank: false }
  validates :course_code, length: { maximum: maximum_string_length, allow_blank: true }
  validates_locale allow_nil: true

  sanitize_field :syllabus_body, CanvasSanitize::SANITIZE

  include StickySisFields
  are_sis_sticky :name,
                 :course_code,
                 :start_at,
                 :conclude_at,
                 :restrict_enrollments_to_course_dates,
                 :enrollment_term_id,
                 :workflow_state,
                 :account_id,
                 :grade_passback_setting

  include FeatureFlags

  include ContentNotices
  define_content_notice :import_in_progress,
                        text: -> { t("One or more items are currently being imported. They will be shown in the course below once they are available.") },
                        link_text: -> { t("Import Status") },
                        link_target: ->(course) { "/courses/#{course.to_param}/content_migrations" },
                        should_show: lambda { |course, user|
                          course.grants_any_right?(user, :manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS)
                        }

  has_a_broadcast_policy

  # A hard limit on the number of graders (excluding the moderator) a moderated
  # assignment can have.
  MODERATED_GRADING_GRADER_LIMIT = 10

  # using a lambda for setting name to avoid caching the translated string when the model is loaded
  # (in case selected language changes)
  CUSTOMIZABLE_PERMISSIONS = ActiveSupport::OrderedHash[
    "syllabus",
    {
      get_setting_name: -> { t("syllabus", "Syllabus") },
      flex: :looser,
      as_bools: true,
    },
    "files",
    {
      get_setting_name: -> { t("files", "Files") },
      flex: :any
    },
  ].freeze

  def [](attr)
    (attr.to_s == "asset_string") ? asset_string : super
  end

  def grade_statuses
    statuses = %w[late missing none excused]
    statuses << "extended" if root_account.feature_enabled?(:extended_submission_state)
    statuses
  end

  def events_for(user)
    if user
      CalendarEvent
        .active
        .for_user_and_context_codes(user, [asset_string])
        .preload(:child_events)
        .reject(&:hidden?) +
        AppointmentGroup.manageable_by(user, [asset_string]) +
        user.assignments_visible_in_course(self)
    else
      calendar_events.active.preload(:child_events).reject(&:hidden?) +
        assignments.active
    end
  end

  def self.ensure_dummy_course
    EnrollmentTerm.ensure_dummy_enrollment_term
    # pre-loading dummy account here to avoid error when finding
    # Account 0 on a new shard before the shard is finished creation,
    # since finding via cache switches away from the creating shard
    a = Account.find(0)
    create_with(account: a, root_account: a, enrollment_term_id: 0, workflow_state: "deleted").find_or_create_by!(id: 0)
  end

  def self.skip_updating_account_associations
    if @skip_updating_account_associations
      yield
    else
      begin
        @skip_updating_account_associations = true
        yield
      ensure
        @skip_updating_account_associations = false
      end
    end
  end

  def self.skip_updating_account_associations?
    !!@skip_updating_account_associations
  end

  def assigned_assignment_ids_by_user
    @assigned_assignment_ids_by_user ||=
      assignments
      .active
      .joins(:submissions)
      .except(:order)
      .pluck("assignments.id", "submissions.user_id")
      .each_with_object({}) do |(assignment_id, user_id), hash|
        hash[user_id] ||= Set.new
        hash[user_id] << assignment_id
      end
  end

  def grading_standard_read_permission
    :read_as_admin
  end

  def update_account_associations_if_changed
    if (saved_change_to_root_account_id? || saved_change_to_account_id?) && !self.class.skip_updating_account_associations?
      delay(synchronous: !Rails.env.production? || saved_change_to_id?).update_account_associations
    end
  end

  def update_enrollment_states_if_necessary
    return if saved_change_to_id # new object, nothing to possibly invalidate

    # a lot of things can change the date logic here :/
    if (saved_changes.keys.intersect?(%w[restrict_enrollments_to_course_dates account_id enrollment_term_id]) ||
       (restrict_enrollments_to_course_dates? && saved_material_changes_to?(:start_at, :conclude_at)) ||
       (saved_change_to_workflow_state? && (completed? || workflow_state_before_last_save == "completed"))) &&
       enrollments.exists?
      EnrollmentState.delay_if_production(n_strand: ["invalidate_enrollment_states", global_root_account_id])
                     .invalidate_states_for_course_or_section(self)
    end
    # if the course date settings have been changed, we'll end up reprocessing all the access values anyway, so no need to queue below for other setting changes
    if saved_change_to_account_id? || @changed_settings
      state_settings = [:restrict_student_future_view, :restrict_student_past_view]
      changed_keys = saved_change_to_account_id? ? state_settings : (@changed_settings & state_settings)
      if changed_keys.any?
        EnrollmentState.delay_if_production(n_strand: ["invalidate_access_for_course", global_root_account_id])
                       .invalidate_access_for_course(self, changed_keys)
      end
    end

    @changed_settings = nil
  end

  def track_end_date_stats
    return unless saved_changes.keys.intersect?(%w[restrict_enrollments_to_course_dates conclude_at enrollment_term_id settings workflow_state]) && published?

    just_published = saved_change_to_workflow_state && workflow_state == "available"
    has_end_date = restrict_enrollments_to_course_dates ? conclude_at.present? : enrollment_term&.end_at.present?
    had_end_date = restrict_enrollments_to_course_dates_before_last_save ? conclude_at_before_last_save.present? : EnrollmentTerm.find(enrollment_term_id_before_last_save)&.end_at&.present?

    return unless just_published || (has_end_date != had_end_date) || (settings_before_last_save[:enable_course_paces] != settings[:enable_course_paces])

    InstStatsd::Statsd.increment(enable_course_paces ? "course.paced.has_end_date" : "course.unpaced.has_end_date") if has_end_date

    return if just_published # Don't decrement on publish

    InstStatsd::Statsd.decrement(settings_before_last_save[:enable_course_paces] ? "course.paced.has_end_date" : "course.unpaced.has_end_date") if had_end_date
  end

  def module_based?
    Rails.cache.fetch(["module_based_course", self].cache_key) do
      context_modules.active.except(:order).any? { |m| m.completion_requirements.present? }
    end
  end

  def has_modules?
    Rails.cache.fetch(["course_has_modules", self].cache_key) do
      context_modules.not_deleted.any?
    end
  end

  def modules_visible_to(user)
    scope = grants_right?(user, :view_unpublished_items) ? context_modules.not_deleted : context_modules.active
    if Account.site_admin.feature_enabled?(:differentiated_modules)
      DifferentiableAssignment.scope_filter(scope, user, self)
    else
      scope
    end
  end

  def module_items_visible_to(user)
    tags = if (user_is_teacher = grants_right?(user, :view_unpublished_items))
             context_module_tags.not_deleted.joins(:context_module).where("context_modules.workflow_state <> 'deleted'")
           else
             context_module_tags.active.joins(:context_module).where(context_modules: { workflow_state: "active" })
           end

    DifferentiableAssignment.scope_filter(tags, user, self, is_teacher: user_is_teacher)
  end

  def sequential_module_item_ids
    Rails.cache.fetch(["ordered_module_item_ids", self].cache_key) do
      GuardRail.activate(:secondary) do
        context_module_tags.not_deleted.joins(:context_module)
                           .where("context_modules.workflow_state <> 'deleted'")
                           .where("content_tags.content_type <> 'ContextModuleSubHeader'")
                           .reorder(Arel.sql("COALESCE(context_modules.position, 0), context_modules.id, content_tags.position NULLS LAST"))
                           .pluck(:id)
      end
    end
  end

  def verify_unique_ids
    infer_root_account unless root_account_id

    is_unique = true
    if sis_source_id && (root_account_id_changed? || sis_source_id_changed?)
      scope = root_account.all_courses.where(sis_source_id:)
      scope = scope.where("id<>?", self) unless new_record?
      if scope.exists?
        is_unique = false
        errors.add(:sis_source_id, t("errors.sis_in_use",
                                     "SIS ID \"%{sis_id}\" is already in use",
                                     sis_id: sis_source_id))
      end
    end

    if integration_id && (root_account_id_changed? || integration_id_changed?)
      scope = root_account.all_courses.where(integration_id:)
      scope = scope.where("id<>?", self) unless new_record?
      if scope.exists?
        is_unique = false
        errors.add(:integration_id, t("Integration ID \"%{int_id}\" is already in use",
                                      int_id: integration_id))
      end
    end

    throw :abort unless is_unique
  end

  def validate_course_dates
    if start_at.present? && conclude_at.present? && conclude_at < start_at
      errors.add(:conclude_at, t("End date cannot be before start date"))
      false
    else
      true
    end
  end

  def validate_banner_image
    if banner_image_url.present? && banner_image_id.present?
      errors.add(:banner_image, t("banner_image_url and banner_image_id cannot both be set."))
      false
    elsif (banner_image_id.present? && valid_course_image_id?(banner_image_id)) ||
          (banner_image_url.present? && valid_course_image_url?(banner_image_url))
      true
    else
      if banner_image_id.present?
        errors.add(:banner_image_id, t("banner_image_id is not a valid ID"))
      elsif banner_image_url.present?
        errors.add(:banner_image_url, t("banner_image_url is not a valid URL"))
      end
      false
    end
  end

  def validate_course_image
    if image_url.present? && image_id.present?
      errors.add(:image, t("image_url and image_id cannot both be set."))
      false
    elsif (image_id.present? && valid_course_image_id?(image_id)) ||
          (image_url.present? && valid_course_image_url?(image_url))
      true
    else
      if image_id.present?
        errors.add(:image_id, t("image_id is not a valid ID"))
      elsif image_url.present?
        errors.add(:image_url, t("image_url is not a valid URL"))
      end
      false
    end
  end

  def valid_course_image_id?(image_id)
    image_id.match(Api::ID_REGEX).present?
  end

  def valid_course_image_url?(image_url)
    URI.parse(image_url) rescue false
  end

  def validate_default_view
    if default_view_changed?
      if !%w[assignments feed modules syllabus wiki].include?(default_view)
        errors.add(:default_view, t("Home page is not valid"))
        return false
      elsif default_view == "wiki" && !(wiki_id && wiki.has_front_page?)
        errors.add(:default_view, t("A Front Page is required"))
        return false
      end
    end
    true
  end

  def validate_template
    return unless self.class.columns_hash.key?("template")
    return unless template_changed?

    if template? && !can_become_template?
      errors.add(:template, t("Courses with enrollments can't become templates"))
    elsif !template? && !can_stop_being_template?
      errors.add(:template, t("Courses that are set as a template in any account can't stop being templates"))
    end
  end

  def validate_not_on_siteadmin
    # Don't validate if we are creating the dummy account so we don't go try to create siteadmin while migrating
    return if id == 0

    if root_account_id_changed? && root_account_id == Account.site_admin&.id
      errors.add(:root_account_id, t("Courses cannot be created on the site_admin account."))
    end
  end

  def image
    @image ||= if image_id.present?
                 shard.activate do
                   attachments.active.where(id: image_id).take&.public_download_url(1.week)
                 end
               elsif image_url
                 image_url
               end
  end

  def banner_image
    @banner_image ||= if banner_image_id.present?
                        shard.activate do
                          attachments.active.where(id: banner_image_id).take&.public_download_url(1.week)
                        end
                      elsif banner_image_url
                        banner_image_url
                      end
  end

  def course_visibility_options
    options = [
      "course",
      {
        setting: t("course", "Course")
      },
      "institution",
      {
        setting: t("institution", "Institution")
      },
      "public",
      {
        setting: t("public", "Public")
      }
    ]
    options = root_account.available_course_visibility_override_options(options).to_a.flatten
    ActiveSupport::OrderedHash[*options]
  end

  def course_visibility_option_descriptions
    {
      "course" => t("All users associated with this course"),
      "institution" => t("All users associated with this institution"),
      "public" => t("Anyone with the URL")
    }
  end

  def custom_course_visibility
    CUSTOMIZABLE_PERMISSIONS.any? do |k, _v|
      custom_visibility_option(k) != course_visibility
    end
  end

  def custom_visibility_option(key)
    perm_cfg = CUSTOMIZABLE_PERMISSIONS[key.to_s]

    if perm_cfg[:as_bools]
      if send(:"public_#{key}") == true
        "public"
      elsif send(:"public_#{key}_to_auth") == true
        "institution"
      else
        "course"
      end
    else
      send(:"#{key}_visibility")
    end
  end

  # DEPRECATED - Used only by View
  def syllabus_visibility_option
    custom_visibility_option(:syllabus)
  end

  # DEPRECATED - Used only by View
  def files_visibility_option
    custom_visibility_option(:files)
  end

  def course_visibility
    if overridden_course_visibility.present?
      overridden_course_visibility
    elsif is_public == true
      "public"
    elsif is_public_to_auth_users == true
      "institution"
    else
      "course"
    end
  end

  def public_license?
    license && self.class.public_license?(license)
  end

  def license_data
    licenses = self.class.licenses
    licenses[license] || licenses["private"]
  end

  def license_url
    license_data[:license_url]
  end

  def readable_license
    license_data[:readable_license].call
  end

  def unpublishable?
    ids = all_real_students.pluck :id
    !submissions.with_assignment.with_point_data.where(user_id: ids).exists?
  end

  def self.update_account_associations(courses_or_course_ids, opts = {})
    return [] if courses_or_course_ids.empty?

    opts.reverse_merge! account_chain_cache: {}
    account_chain_cache = opts[:account_chain_cache]

    # Split it up into manageable chunks
    user_ids_to_update_account_associations = []
    if courses_or_course_ids.length > 500
      opts = opts.dup
      opts.reverse_merge! skip_user_account_associations: true
      courses_or_course_ids.uniq.compact.each_slice(500) do |courses_or_course_ids_slice|
        user_ids_to_update_account_associations += update_account_associations(courses_or_course_ids_slice, opts)
      end
    else
      if courses_or_course_ids.first.is_a? Course
        courses = courses_or_course_ids
        ActiveRecord::Associations.preload(courses, course_sections: :nonxlist_course)
        course_ids = courses.map(&:id)
      else
        course_ids = courses_or_course_ids
        courses = Course.where(id: course_ids)
                        .preload(course_sections: [:course, :nonxlist_course])
                        .select([:id, :account_id]).to_a
      end
      course_ids_to_update_user_account_associations = []
      CourseAccountAssociation.transaction do
        current_associations = {}
        to_delete = []
        CourseAccountAssociation.where(course_id: course_ids).each do |aa|
          key = [aa.course_section_id, aa.account_id]
          current_course_associations = current_associations[aa.course_id] ||= {}
          # duplicates. the unique index prevents these now, but this code
          # needs to hang around for the migration itself
          if current_course_associations.key?(key)
            to_delete << aa.id
            next
          end
          current_course_associations[key] = [aa.id, aa.depth]
        end

        courses.each do |course|
          did_an_update = false
          current_course_associations = current_associations[course.id] || {}

          # Courses are tied to accounts directly and through sections and crosslisted courses
          (course.course_sections + [nil]).each do |section|
            next if section && !section.active?

            section.course = course if section
            starting_account_ids = [course.account_id, section.try(:course).try(:account_id), section.try(:nonxlist_course).try(:account_id)].compact.uniq

            account_ids_with_depth = User.calculate_account_associations_from_accounts(starting_account_ids, account_chain_cache).map

            account_ids_with_depth.each do |account_id_with_depth|
              account_id = account_id_with_depth[0]
              depth = account_id_with_depth[1]
              key = [section.try(:id), account_id]
              association = current_course_associations[key]
              if association.nil?
                # new association, create it
                begin
                  course.transaction(requires_new: true) do
                    course.course_account_associations.create! do |aa|
                      aa.course_section_id = section.try(:id)
                      aa.account_id = account_id
                      aa.depth = depth
                    end
                  end
                rescue ActiveRecord::RecordNotUnique
                  course.course_account_associations.where(course_section_id: section,
                                                           account_id:).update_all(depth:)
                end
                did_an_update = true
              else
                if association[1] != depth
                  CourseAccountAssociation.where(id: association[0]).update_all(depth:)
                  did_an_update = true
                end
                # remove from list of existing
                current_course_associations.delete(key)
              end
            end
          end
          did_an_update ||= !current_course_associations.empty?
          if did_an_update
            course.course_account_associations.reset
            course_ids_to_update_user_account_associations << course.id
          end
        end

        to_delete += current_associations.map { |_k, v| v.map { |_k2, v2| v2[0] } }.flatten
        unless to_delete.empty?
          CourseAccountAssociation.where(id: to_delete).in_batches(of: 10_000).delete_all
        end
      end
      Course.clear_cache_keys(course_ids_to_update_user_account_associations, :account_associations)

      unless course_ids_to_update_user_account_associations.empty?
        user_ids_to_update_account_associations = Enrollment
                                                  .where("course_id IN (?) AND workflow_state<>'deleted'", course_ids_to_update_user_account_associations)
                                                  .group(:user_id).pluck(:user_id)
      end
    end
    User.update_account_associations(user_ids_to_update_account_associations, account_chain_cache:) unless user_ids_to_update_account_associations.empty? || opts[:skip_user_account_associations]
    user_ids_to_update_account_associations
  end

  def update_account_associations
    shard.activate do
      Course.update_account_associations([self])
    end
  end

  def associated_accounts(include_crosslisted_courses: true)
    key = "associated_accounts#{include_crosslisted_courses && "_xlisted"}"
    Rails.cache.fetch_with_batched_keys(key, batch_object: self, batched_keys: :account_associations) do
      GuardRail.activate(:primary) do
        accounts = if association(:course_account_associations).loaded?
                     course_account_associations.filter { |caa| include_crosslisted_courses ? true : caa.course_section_id.nil? }.map(&:account).uniq
                   else
                     shard.activate do
                       Account.find_by_sql(<<~SQL.squish)
                         WITH depths AS (
                           SELECT account_id, MIN(depth)
                           FROM #{CourseAccountAssociation.quoted_table_name}
                           WHERE course_id=#{id}
                           #{"AND course_section_id IS NULL" unless include_crosslisted_courses}
                           GROUP BY account_id
                         )
                         SELECT accounts.*
                         FROM #{Account.quoted_table_name} INNER JOIN depths ON accounts.id=depths.account_id
                         ORDER BY min
                       SQL
                     end
                   end
        accounts << account if account_id && !accounts.find { |a| a.id == account_id }
        accounts << root_account if root_account_id && !accounts.find { |a| a.id == root_account_id }
        accounts
      end
    end
  end

  scope :recently_started, -> { where(start_at: 1.month.ago..Time.zone.now).order("start_at DESC").limit(10) }
  scope :recently_ended, -> { where(conclude_at: 1.month.ago..Time.zone.now).order("start_at DESC").limit(10) }
  scope :recently_created, -> { where(created_at: 1.month.ago..Time.zone.now).order("created_at DESC").limit(50).preload(:teachers) }
  scope :for_term, ->(term) { term ? where(enrollment_term_id: term) : all }
  scope :active_first, -> { order(Arel.sql("CASE WHEN courses.workflow_state='available' THEN 0 ELSE 1 END, #{best_unicode_collation_key("name")}")) }
  scope :name_like, lambda { |query|
    where(coalesced_wildcard("courses.name", "courses.sis_source_id", "courses.course_code", query))
      .or(where(id: query))
  }
  scope :needs_account, ->(account, limit) { where(account_id: nil, root_account_id: account).limit(limit) }
  scope :active, -> { where.not(workflow_state: "deleted") }
  scope :least_recently_updated, ->(limit) { order(:updated_at).limit(limit) }

  scope :manageable_by_user, lambda { |*args|
    # args[0] should be user_id, args[1], if true, will include completed
    # enrollments as well as active enrollments
    user_id = args[0]
    workflow_states = (args[1].present? ? ["'active'", "'completed'"] : ["'active'"]).join(", ")
    admin_completed_sql = ""
    enrollment_completed_sql = ""

    if args[1].blank?
      admin_completed_sql = sanitize_sql(["INNER JOIN #{Course.quoted_table_name} AS courses ON courses.id = caa.course_id
        INNER JOIN #{EnrollmentTerm.quoted_table_name} AS et ON et.id = courses.enrollment_term_id
        WHERE courses.workflow_state<>'completed' AND
          ((et.end_at IS NULL OR et.end_at >= :end) OR
          (courses.restrict_enrollments_to_course_dates = true AND courses.conclude_at >= :end))",
                                          end: Time.now.utc])
      enrollment_completed_sql = sanitize_sql(["INNER JOIN #{EnrollmentTerm.quoted_table_name} AS et ON et.id = courses.enrollment_term_id
        WHERE courses.workflow_state<>'completed' AND
          ((et.end_at IS NULL OR et.end_at >= :end) OR
          (courses.restrict_enrollments_to_course_dates = true AND courses.conclude_at >= :end))",
                                               end: Time.now.utc])
    end

    distinct.joins("INNER JOIN (
         SELECT caa.course_id, au.user_id FROM #{CourseAccountAssociation.quoted_table_name} AS caa
         INNER JOIN #{Account.quoted_table_name} AS a ON a.id = caa.account_id AND a.workflow_state = 'active'
         INNER JOIN #{AccountUser.quoted_table_name} AS au ON au.account_id = a.id AND au.user_id = #{user_id.to_i} AND au.workflow_state = 'active'
         #{admin_completed_sql}
       UNION SELECT courses.id AS course_id, e.user_id FROM #{Course.quoted_table_name}
         INNER JOIN #{Enrollment.quoted_table_name} AS e ON e.course_id = courses.id AND e.user_id = #{user_id.to_i}
           AND e.workflow_state IN(#{workflow_states}) AND e.type IN ('TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment')
         INNER JOIN #{EnrollmentState.quoted_table_name} AS es ON es.enrollment_id = e.id AND es.state IN (#{workflow_states})
         #{enrollment_completed_sql}) AS course_users
       ON course_users.course_id = courses.id")
  }

  scope :not_deleted, -> { where("workflow_state<>'deleted'") }

  scope :with_enrollments, lambda {
    where(Enrollment.active.where("enrollments.course_id=courses.id").arel.exists)
  }
  scope :with_enrollment_types, lambda { |types|
    types = types.map { |type| "#{type.capitalize}Enrollment" }
    where(Enrollment.active.where("enrollments.course_id=courses.id").where(type: types).arel.exists)
  }
  scope :without_enrollments, lambda {
    where.not(Enrollment.active.where("enrollments.course_id=courses.id").arel.exists)
  }

  # completed and not_completed -- logic should match up as much as possible with #soft_concluded?
  scope :completed, lambda {
    joins(:enrollment_term)
      .where("courses.workflow_state='completed' OR courses.conclude_at<? OR (courses.conclude_at IS NULL AND enrollment_terms.end_at<?)", Time.now.utc, Time.now.utc)
  }
  scope :not_completed, lambda {
    joins(:enrollment_term)
      .where("courses.workflow_state<>'completed' AND
          (courses.conclude_at IS NULL OR courses.conclude_at>=?) AND
          (courses.conclude_at IS NOT NULL OR enrollment_terms.end_at IS NULL OR enrollment_terms.end_at>=?)",
             Time.now.utc,
             Time.now.utc)
  }
  scope :by_teachers, lambda { |teacher_ids|
    if teacher_ids.empty?
      none
    else
      where(Enrollment.active.where("enrollments.course_id=courses.id AND enrollments.type='TeacherEnrollment' AND enrollments.user_id IN (?)", teacher_ids).arel.exists)
    end
  }
  scope :by_associated_accounts, lambda { |account_ids|
    if account_ids.empty?
      none
    else
      where(CourseAccountAssociation.where("course_account_associations.course_id=courses.id AND course_account_associations.account_id IN (?)", account_ids).arel.exists)
    end
  }
  scope :published, -> { where(workflow_state: %w[available completed]) }
  scope :unpublished, -> { where(workflow_state: %w[created claimed]) }

  scope :deleted, -> { where(workflow_state: "deleted") }

  scope :master_courses, -> { joins(:master_course_templates).where.not(MasterCourses::MasterTemplate.table_name => { workflow_state: "deleted" }) }
  scope :not_master_courses, -> { joins("LEFT OUTER JOIN #{MasterCourses::MasterTemplate.quoted_table_name} AS mct ON mct.course_id=courses.id AND mct.workflow_state<>'deleted'").where("mct IS NULL") } # rubocop:disable Rails/WhereEquals mct is a table, not a column

  scope :associated_courses, -> { joins(:master_course_subscriptions).where.not(MasterCourses::ChildSubscription.table_name => { workflow_state: "deleted" }) }
  scope :not_associated_courses, -> { joins("LEFT OUTER JOIN #{MasterCourses::ChildSubscription.quoted_table_name} AS mcs ON mcs.child_course_id=courses.id AND mcs.workflow_state<>'deleted'").where("mcs IS NULL") } # rubocop:disable Rails/WhereEquals mcs is a table, not a column

  scope :public_courses, -> { where(is_public: true) }
  scope :not_public_courses, -> { where(is_public: false) }

  scope :templates, -> { where(template: true) }

  scope :homeroom, -> { where(homeroom_course: true) }
  scope :syncing_subjects, -> { joins("INNER JOIN #{Course.quoted_table_name} AS homeroom ON homeroom.id = courses.homeroom_course_id").where("homeroom.homeroom_course = true AND homeroom.workflow_state <> 'deleted'").where(sis_batch_id: nil).where(sync_enrollments_from_homeroom: true) }

  def potential_collaborators
    current_users
  end

  def potential_collaborators_for(current_user)
    users_visible_to(current_user)
  end

  def broadcast_data
    { course_id: id, root_account_id: }
  end

  set_broadcast_policy do |p|
    p.dispatch :grade_weight_changed
    p.to { participating_students_by_date + participating_observers_by_date }
    p.whenever do |record|
      (record.available? && @grade_weight_changed) ||
        (
          record.changed_in_state(:available, fields: :group_weighting_scheme) &&
          record.saved_changes[:group_weighting_scheme] != [nil, "equal"] # not a functional change
        )
    end
    p.data { broadcast_data }

    p.dispatch :new_course
    p.to { root_account.account_users.active }
    p.whenever do |record|
      record.root_account &&
        ((record.just_created && record.name != Course.default_name) ||
         (record.name_before_last_save == Course.default_name &&
           record.name != Course.default_name)
        )
    end
    p.data { broadcast_data }
  end

  def self.default_name
    # TODO: i18n
    t("default_name", "My Course")
  end

  def users_not_in_groups(groups, opts = {})
    scope = User.joins(:not_ended_enrollments)
                .where(enrollments: { course_id: self, type: "StudentEnrollment" })
                .where(Group.not_in_group_sql_fragment(groups.map(&:id)))
                .select("users.id, users.name, users.updated_at").distinct
    scope = scope.select(opts[:order]).order(opts[:order]) if opts[:order]
    scope
  end

  def instructors_in_charge_of(user_id, require_grade_permissions: true)
    GuardRail.activate(:secondary) do
      scope = current_enrollments
              .where(course_id: self, user_id:)
              .where.not(course_section_id: nil)

      if scope.none?
        scope = prior_enrollments.where(course_id: self, user_id:).where.not(course_section_id: nil)
      end

      section_ids = scope.distinct.pluck(:course_section_id)

      instructor_enrollment_scope = instructor_enrollments.active_by_date
      if section_ids.any?
        instructor_enrollment_scope = instructor_enrollment_scope.where("enrollments.limit_privileges_to_course_section IS NULL OR
          enrollments.limit_privileges_to_course_section<>? OR enrollments.course_section_id IN (?)",
                                                                        true,
                                                                        section_ids)
      end

      if require_grade_permissions
        # filter to users with view_all_grades or manage_grades permission
        role_user_ids = instructor_enrollment_scope.pluck(:role_id, :user_id)
        return [] unless role_user_ids.any?

        role_ids = role_user_ids.map(&:first).uniq

        roles = Role.where(id: role_ids).to_a
        allowed_role_ids = roles.select do |role|
          [:view_all_grades, :manage_grades].any? { |permission| RoleOverride.enabled_for?(self, permission, role, self).include?(:self) }
        end.map(&:id)
        return [] unless allowed_role_ids.any?

        allowed_user_ids = Set.new
        role_user_ids.each { |role_id, u_id| allowed_user_ids << u_id if allowed_role_ids.include?(role_id) }
        User.where(id: allowed_user_ids).to_a
      else
        User.where(id: instructor_enrollment_scope.select(:id)).to_a
      end
    end
  end

  def user_is_admin?(user)
    return false unless user

    fetch_on_enrollments("user_is_admin", user) do
      enrollments.for_user(user).active.of_admin_type.exists?
    end
  end

  def user_is_instructor?(user)
    return false unless user

    fetch_on_enrollments("user_is_instructor", user) do
      enrollments.for_user(user).active_by_date.of_instructor_type.exists?
    end
  end

  def user_is_student?(user, opts = {})
    return false unless user

    fetch_on_enrollments("user_is_student", user, opts) do
      enroll_types = ["StudentEnrollment"]
      enroll_types << "StudentViewEnrollment" if opts[:include_fake_student]

      enroll_scope = enrollments.for_user(user).where(type: enroll_types)
      if opts[:include_future]
        enroll_scope = enroll_scope.active_or_pending_by_date_ignoring_access
      elsif opts[:include_all]
        enroll_scope = enroll_scope.not_inactive_by_date_ignoring_access
      else
        return false unless available?

        enroll_scope = enroll_scope.active_by_date
      end
      enroll_scope.exists?
    end
  end

  def preload_user_roles!
    # plz to use before you make a billion calls to user_has_been_X? with different users
    @user_ids_by_enroll_type ||= shard.activate do
      map = {}
      enrollments.active.pluck(:user_id, :type).each do |user_id, type|
        map[type] ||= []
        map[type] << user_id
      end
      map
    end
  end

  def preloaded_user_has_been?(user, types)
    shard.activate do
      Array(types).any? { |type| @user_ids_by_enroll_type.key?(type) && @user_ids_by_enroll_type[type].include?(user.id) }
    end
  end

  def user_has_been_instructor?(user)
    return false unless user
    if @user_ids_by_enroll_type
      return preloaded_user_has_been?(user, %w[TaEnrollment TeacherEnrollment])
    end

    # enrollments should be on the course's shard
    fetch_on_enrollments("user_has_been_instructor", user) do
      instructor_enrollments.active.where(user_id: user).exists? # active here is !deleted; it still includes concluded, etc.
    end
  end

  def user_has_been_admin?(user)
    return false unless user
    if @user_ids_by_enroll_type
      return preloaded_user_has_been?(user, %w[TaEnrollment TeacherEnrollment DesignerEnrollment])
    end

    fetch_on_enrollments("user_has_been_admin", user) do
      admin_enrollments.active.where(user_id: user).exists? # active here is !deleted; it still includes concluded, etc.
    end
  end

  def user_has_been_observer?(user)
    return false unless user
    if @user_ids_by_enroll_type
      return preloaded_user_has_been?(user, "ObserverEnrollment")
    end

    fetch_on_enrollments("user_has_been_observer", user) do
      observer_enrollments.shard(self).active.where(user_id: user).exists? # active here is !deleted; it still includes concluded, etc.
    end
  end

  def user_has_been_student?(user)
    return false unless user
    if @user_ids_by_enroll_type
      return preloaded_user_has_been?(user, %w[StudentEnrollment StudentViewEnrollment])
    end

    fetch_on_enrollments("user_has_been_student", user) do
      all_student_enrollments.where(user_id: user).exists?
    end
  end

  def user_has_no_enrollments?(user)
    return false unless user

    if @user_ids_by_enroll_type
      shard.activate do
        return @user_ids_by_enroll_type.values.none? { |arr| arr.include?(user.id) }
      end
    end

    fetch_on_enrollments("user_has_no_enrollments", user) do
      !enrollments.where(user_id: user).exists?
    end
  end

  # Public: Determine if a group weighting scheme should be applied.
  #
  # Returns boolean.
  def apply_group_weights?
    group_weighting_scheme == "percent"
  end

  def apply_assignment_group_weights=(apply)
    self.group_weighting_scheme = if apply
                                    "percent"
                                  else
                                    "equal"
                                  end
  end

  def grade_weight_changed!
    @grade_weight_changed = true
    save!
    @grade_weight_changed = false
  end

  def membership_for_user(user)
    enrollments.where(user_id: user).order(:workflow_state).first if user
  end

  def infer_root_account
    self.root_account = account if account&.root_account?
    self.root_account_id ||= account&.root_account_id
  end

  def assert_defaults
    self.name = nil if name&.strip&.empty?
    self.name ||= t("missing_name", "Unnamed Course")
    self.name.delete!("\r")
    self.course_code = nil if course_code == ""
    if !course_code && self.name
      res = []
      split = self.name.split(/\s/)
      res << split[0]
      res << split[1..].find { |txt| txt.match(/\d/) } rescue nil
      self.course_code = res.compact.join(" ")
    end
    @group_weighting_scheme_changed = group_weighting_scheme_changed?
    if account_id && account_id_changed?
      infer_root_account
    end
    if self.root_account_id && root_account_id_changed?
      if account
        if account.root_account?
          self.account = nil if root_account_id != account.id
        elsif account&.root_account_id != root_account_id
          self.account = nil
        end
      end
      self.account_id ||= self.root_account_id
    end
    self.root_account = Account.default if root_account_id.nil?
    self.account_id ||= self.root_account_id
    self.enrollment_term = nil if enrollment_term.try(:root_account_id) != self.root_account_id
    self.enrollment_term ||= root_account.default_enrollment_term
    self.allow_student_wiki_edits = (default_wiki_editing_roles || "").split(",").include?("students")
    if course_format && !%w[on_campus online blended].include?(course_format)
      self.course_format = nil
    end
    self.default_view ||= default_home_page
    true
  end

  def update_enrollments_later
    update_enrolled_users if !new_record? && !!changes.keys.intersect?(%w[workflow_state name course_code start_at conclude_at enrollment_term_id])
    true
  end

  def update_enrolled_users(sis_batch: nil)
    shard.activate do
      if workflow_state_changed? || (sis_batch && saved_change_to_workflow_state?)
        if completed?
          enrollment_info = Enrollment.where(course_id: self, workflow_state: ["active", "invited"]).select(:id, :workflow_state).to_a
          if enrollment_info.any?
            data = SisBatchRollBackData.build_dependent_data(sis_batch:, contexts: enrollment_info, updated_state: "completed")
            Enrollment.where(id: enrollment_info.map(&:id)).update_all(workflow_state: "completed", completed_at: Time.now.utc)

            EnrollmentState.transaction do
              locked_ids = EnrollmentState.where(enrollment_id: enrollment_info.map(&:id)).lock(:no_key_update).order(:enrollment_id).pluck(:enrollment_id)
              EnrollmentState.where(enrollment_id: locked_ids)
                             .update_all(["state = ?, state_is_current = ?, access_is_current = ?, lock_version = lock_version + 1, updated_at = ?", "completed", true, false, Time.now.utc])
            end
            EnrollmentState.delay_if_production.process_states_for_ids(enrollment_info.map(&:id)) # recalculate access
          end

          appointment_participants.active.current.update_all(workflow_state: "deleted")
          appointment_groups.each(&:clear_cached_available_slots!)
        elsif deleted?
          enroll_scope = Enrollment.where("course_id=? AND workflow_state<>'deleted'", self)

          user_ids = enroll_scope.group(:user_id).pluck(:user_id).uniq
          if user_ids.any?
            enrollment_info = enroll_scope.select(:id, :workflow_state).to_a
            if enrollment_info.any?
              data = SisBatchRollBackData.build_dependent_data(sis_batch:, contexts: enrollment_info, updated_state: "deleted")
              Enrollment.where(id: enrollment_info.map(&:id)).update_all(workflow_state: "deleted")
              EnrollmentState.transaction do
                locked_ids = EnrollmentState.where(enrollment_id: enrollment_info.map(&:id)).lock(:no_key_update).order(:enrollment_id).pluck(:enrollment_id)
                EnrollmentState.where(enrollment_id: locked_ids)
                               .update_all(["state = ?, state_is_current = ?, lock_version = lock_version + 1, updated_at = ?", "deleted", true, Time.now.utc])
              end
            end
            User.delay_if_production.update_account_associations(user_ids)
          end
        end
      end

      if root_account_id_changed?
        CourseSection.where(course_id: self).update_all(root_account_id: self.root_account_id)
        Enrollment.where(course_id: self).update_all(root_account_id: self.root_account_id)
      end

      self.class.connection.after_transaction_commit do
        Enrollment.where(course_id: self).in_batches(of: 10_000).touch_all
        user_ids = Enrollment.where(course_id: self).distinct.pluck(:user_id).sort
        # We might get lots of database locks when lots of courses with the same users are being updated,
        # so we can skip touching those users' updated_at stamp since another process will do it
        User.touch_and_clear_cache_keys(user_ids, :enrollments, skip_locked: true)
      end

      data
    end
  end

  def self_enrollment_allowed?
    !!(account && account.self_enrollment_allowed?(self))
  end

  def self_enrollment_enabled?
    self_enrollment? && self_enrollment_allowed?
  end

  def self_enrollment_code
    read_attribute(:self_enrollment_code) || set_self_enrollment_code
  end

  def set_self_enrollment_code
    return if !self_enrollment_enabled? || read_attribute(:self_enrollment_code)

    # subset of letters and numbers that are unambiguous
    alphanums = "ABCDEFGHJKLMNPRTWXY346789".chars
    code_length = 6

    # we're returning a 6-digit base-25(ish) code. that means there are ~250
    # million possible codes. we should expect to see our first collision
    # within the first 16k or so (thus the retry loop), but we won't risk ever
    # exhausting a retry loop until we've used up about 15% or so of the
    # keyspace. if needed, we can grow it at that point (but it's scoped to a
    # shard, and not all courses will have enrollment codes, so that may not be
    # necessary)
    code = nil
    10.times do
      code = Array.new(code_length) { alphanums.sample }.join
      next if Course.where(self_enrollment_code: code).exists?

      self.self_enrollment_code = code
      break
    end
    code
  end

  def self_enrollment_limit_met?
    self_enrollment_limit && self_enrolled_students.size >= self_enrollment_limit
  end

  def long_self_enrollment_code
    @long_self_enrollment_code ||= Digest::MD5.hexdigest("#{uuid}_for_#{id}")
  end

  # still include the old longer format, since links may be out there
  def self_enrollment_codes
    [self_enrollment_code, long_self_enrollment_code]
  end

  def update_show_total_grade_as_on_weighting_scheme_change
    if group_weighting_scheme_changed? && group_weighting_scheme == "percent"
      self.show_total_grade_as_points = false
    end
    true
  end

  # set license to "private" if it's present but not recognized
  def validate_license
    if !license.nil? && !self.class.licenses.key?(license)
      self.license = "private"
    end
  end

  # to ensure permissions on the root folder are updated after hiding or showing the files tab
  def touch_root_folder_if_necessary
    if tab_configuration_changed?
      files_tab_was_hidden = tab_configuration_was&.any? { |h| h.present? && h["id"] == TAB_FILES && h["hidden"] }
      Folder.root_folders(self).each(&:touch) if files_tab_was_hidden != tab_hidden?(TAB_FILES)
    end
    true
  end

  def update_cached_due_dates
    if saved_change_to_enrollment_term_id?
      recompute_student_scores
      SubmissionLifecycleManager.recompute_course(self)
    end
  end

  def update_final_scores_on_weighting_scheme_change
    if @group_weighting_scheme_changed
      self.class.connection.after_transaction_commit { recompute_student_scores }
    end
  end

  def recompute_student_scores(student_ids = nil,
                               grading_period_id: nil,
                               update_all_grading_period_scores: true,
                               update_course_score: true,
                               run_immediately: false)
    if run_immediately
      recompute_student_scores_without_send_later(
        student_ids,
        grading_period_id:,
        update_all_grading_period_scores:
      )
    else
      inst_job_opts = { max_attempts: 10 }
      if student_ids.blank? && grading_period_id.nil? && update_all_grading_period_scores && update_course_score
        # if we have all default args, let's queue this job in a singleton to avoid duplicates
        inst_job_opts[:singleton] = "recompute_student_scores:#{global_id}"
      elsif student_ids.blank? && grading_period_id.present?
        # A migration that changes a lot of due dates in a grading period
        # situation can kick off a job storm and redo work. Let's avoid
        # that by putting it into a singleton.
        inst_job_opts[:singleton] = "recompute_student_scores:#{global_id}:#{grading_period_id}"
      end

      delay_if_production(**inst_job_opts).recompute_student_scores_without_send_later(
        student_ids,
        grading_period_id:,
        update_all_grading_period_scores:
      )
    end
  end

  def recompute_student_scores_without_send_later(student_ids = nil, opts = {})
    visible_student_ids = if student_ids.present?
                            # We were given student_ids.  Let's see how many of those students can even see this assignment
                            admin_visible_student_enrollments.where(user_id: student_ids).pluck(:user_id)
                          else
                            # We were not given any student_ids
                            # Let's get them all!
                            admin_visible_student_enrollments.pluck(:user_id)
                          end

    Enrollment.recompute_final_score(
      visible_student_ids,
      id,
      grading_period_id: opts[:grading_period_id],
      update_all_grading_period_scores: opts.fetch(:update_all_grading_period_scores, true)
    )
  end

  def handle_syllabus_changes_for_master_migration
    if syllabus_body_changed?
      self.syllabus_updated_at = Time.now.utc
      if @master_migration
        updating_master_template_id = @master_migration.master_course_subscription.master_template_id
        # master migration sync
        self.syllabus_master_template_id ||= updating_master_template_id if syllabus_body_was.blank? # sync if there was no syllabus before
        if self.syllabus_master_template_id.to_i != updating_master_template_id
          restore_syllabus_body! # revert the change
          @master_migration.add_skipped_item(:syllabus)
        end
      elsif self.syllabus_master_template_id
        # local change - remove the template id to prevent future syncs
        self.syllabus_master_template_id = nil
      end
    end
  end

  def home_page
    wiki.front_page
  end

  def context_code
    raise "DONT USE THIS, use .short_name instead" unless Rails.env.production?
  end

  def allow_media_comments?
    true
  end

  def short_name
    course_code
  end

  def short_name=(val)
    write_attribute(:course_code, val)
  end

  def short_name_slug
    CanvasTextHelper.truncate_text(short_name, ellipsis: "")
  end

  # Allows the account to be set directly
  belongs_to :account

  def wiki
    return super if wiki_id

    Wiki.wiki_for_context(self)
  end

  # A universal lookup for all messages.
  def messages
    Message.for(self)
  end

  def do_complete
    self.conclude_at ||= Time.now
  end

  def do_unconclude
    self.conclude_at = nil
  end

  def do_offer
    delay_if_production.invite_uninvited_students
  end

  def do_claim
    self.workflow_state = "claimed"
  end

  def invite_uninvited_students
    enrollments.where(workflow_state: "creation_pending").each(&:invite!)
  end

  workflow do
    state :created do
      event :claim, transitions_to: :claimed
      event :offer, transitions_to: :available
      event :complete, transitions_to: :completed
      event :delete, transitions_to: :deleted
    end

    state :claimed do
      event :offer, transitions_to: :available
      event :complete, transitions_to: :completed
      event :delete, transitions_to: :deleted
    end

    state :available do
      event :complete, transitions_to: :completed
      event :claim, transitions_to: :claimed
      event :delete, transitions_to: :deleted
    end

    state :completed do
      event :unconclude, transitions_to: :available
      event :offer, transitions_to: :available
      event :claim, transitions_to: :claimed
      event :delete, transitions_to: :deleted
    end

    state :deleted do
      event :undelete, transitions_to: :claimed
    end
  end

  def api_state
    return "unpublished" if workflow_state == "created" || workflow_state == "claimed"

    workflow_state
  end

  def reload(*)
    @account_chain = @account_chain_with_site_admin = nil
    super
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    return false if template?

    gradebook_filters.in_batches.destroy_all
    self.workflow_state = "deleted"
    self.deleted_at = Time.now.utc
    save!
  end

  def self.destroy_batch(courses, sis_batch: nil, batch_mode: false)
    enroll_scope = Enrollment.active.where(course_id: courses)
    enroll_scope.find_in_batches do |e_batch|
      user_ids = e_batch.map(&:user_id).uniq.sort
      data = SisBatchRollBackData.build_dependent_data(sis_batch:,
                                                       contexts: e_batch,
                                                       updated_state: "deleted",
                                                       batch_mode_delete: batch_mode)
      SisBatchRollBackData.bulk_insert_roll_back_data(data) if data
      Enrollment.where(id: e_batch.map(&:id)).update_all(workflow_state: "deleted", updated_at: Time.zone.now)
      EnrollmentState.where(enrollment_id: e_batch.map(&:id))
                     .update_all(["state = ?, state_is_current = ?, lock_version = lock_version + 1, updated_at = ?", "deleted", true, Time.now.utc])
      User.touch_and_clear_cache_keys(user_ids, :enrollments)
      User.delay_if_production.update_account_associations(user_ids) if user_ids.any?
    end
    c_data = SisBatchRollBackData.build_dependent_data(sis_batch:, contexts: courses, updated_state: "deleted", batch_mode_delete: batch_mode)
    SisBatchRollBackData.bulk_insert_roll_back_data(c_data) if c_data
    Course.where(id: courses).update_all(workflow_state: "deleted", updated_at: Time.zone.now)
    courses.count
  end

  def call_event(event)
    send(event) if current_state.events.include? event.to_sym
  end

  def claim_with_teacher(user)
    raise "Must provide a valid teacher" unless user
    return unless state == :created

    e = enroll_user(user, "TeacherEnrollment", enrollment_state: "active") # teacher(user)
    claim
    e
  end

  def self.require_assignment_groups(contexts)
    courses = contexts.select { |c| c.is_a?(Course) }
    groups = Shard.partition_by_shard(courses) do |shard_courses|
      AssignmentGroup.select("id, context_id, context_type").where(context_type: "Course", context_id: shard_courses)
    end.index_by(&:context_id)
    courses.each do |course|
      unless groups[course.id]
        course.require_assignment_group rescue nil
      end
    end
  end

  def require_assignment_group
    shard.activate do
      key = ["has_assignment_group", global_id].cache_key
      return if Rails.cache.read(key)

      if assignment_groups.active.empty?
        GuardRail.activate(:primary) do
          assignment_groups.create!(name: t("#assignment_group.default_name", "Assignments"))
        end
      end
      Rails.cache.write(key, true)
    end
  end

  def self.create_unique(uuid = nil, account_id = nil, root_account_id = nil)
    uuid ||= CanvasSlug.generate_securish_uuid
    course = where(uuid:).first_or_initialize
    course = Course.new if course.deleted?
    course.name = default_name if course.new_record?
    course.short_name = t("default_short_name", "Course-101") if course.new_record?
    course.account_id = account_id || root_account_id
    course.root_account_id = root_account_id
    course.save!
    course
  end

  def <=>(other)
    id <=> other.id
  end

  def quota
    Rails.cache.fetch(["default_quota", self].cache_key) do
      storage_quota
    end
  end

  def storage_quota_mb
    storage_quota / 1.megabyte
  end

  def storage_quota_mb=(val)
    self.storage_quota = val.try(:to_i).try(:megabytes)
  end

  def storage_quota_used_mb
    Attachment.get_quota(self)[:quota_used].to_f / 1.megabyte
  end

  def storage_quota
    read_attribute(:storage_quota) ||
      (account.default_storage_quota rescue nil) ||
      Setting.get("course_default_quota", 500.megabytes.to_s).to_i
  end

  def storage_quota=(val)
    val = val.to_f
    val = nil if val <= 0
    if account && account.default_storage_quota == val
      val = nil
    end
    write_attribute(:storage_quota, val)
  end

  def assign_uuid
    self.uuid ||= CanvasSlug.generate_securish_uuid
  end
  protected :assign_uuid

  def full_name
    name
  end

  def to_atom
    {
      title: self.name,
      updated: updated_at,
      published: created_at,
      link: "/#{context_url_prefix}/courses/#{id}"
    }
  end

  def unenrolled_user_can_read?(user, setting)
    return false unless available?

    setting == "public" || (setting == "institution" && user&.persisted?)
  end

  set_policy do
    given { |user| unenrolled_user_can_read?(user, course_visibility) }
    can :read and can :read_outcomes and can :read_syllabus

    CUSTOMIZABLE_PERMISSIONS.each_key do |type|
      given do |user|
        grants_right?(user, :read_as_member) || unenrolled_user_can_read?(user, custom_visibility_option(type))
      end
      can :"read_#{type}"
    end

    RoleOverride.permissions.each do |permission, details|
      given do |user|
        active_enrollment_allows(user, permission, !details[:restrict_future_enrollments]) ||
          account_membership_allows(user, permission)
      end
      can permission
    end

    given { |_user, session| session && session[:enrollment_uuid] && (hash = Enrollment.course_user_state(self, session[:enrollment_uuid]) || {}) && (hash[:enrollment_state] == "invited" || (hash[:enrollment_state] == "active" && hash[:user_state].to_s == "pre_registered")) && (available? || completed? || (claimed? && hash[:is_admin])) }
    can :read, :read_outcomes, :read_as_member

    given { |user| (available? || completed?) && user && fetch_on_enrollments("has_not_inactive_enrollment", user) { enrollments.for_user(user).not_inactive_by_date.exists? } }
    can :read, :read_outcomes, :read_as_member

    # Active students
    given do |user|
      available? && user && fetch_on_enrollments("has_active_student_enrollment", user) { enrollments.for_user(user).active_by_date.of_student_type.exists? }
    end
    can :read, :participate_as_student, :read_grades, :read_outcomes, :read_as_member

    given do |user|
      (available? || completed?) && user &&
        fetch_on_enrollments("has_active_observer_enrollment", user) { enrollments.for_user(user).active_by_date.where(type: "ObserverEnrollment").where.not(associated_user_id: nil).exists? }
    end
    can :read_grades

    # Active admins (Teacher/TA/Designer)
    #################### Begin legacy permission block #########################
    given do |user|
      !root_account.feature_enabled?(:granular_permissions_manage_courses) && !deleted? &&
        !sis_source_id && user && !template? &&
        fetch_on_enrollments("active_content_admin_enrollments", user) do
          enrollments.for_user(user).of_content_admins.active_by_date.to_a
        end.any? { |e| e.has_permission_to?(:change_course_state) }
    end
    can :delete

    given do |user|
      !root_account.feature_enabled?(:granular_permissions_manage_courses) && !deleted? &&
        user && fetch_on_enrollments("has_active_content_admin_enrollment", user) do
          enrollments.for_user(user).of_content_admins.active_by_date.exists?
        end
    end
    can :reset_content
    ##################### End legacy permission block ##########################

    given do |user|
      user && (available? || created? || claimed?) &&
        fetch_on_enrollments("has_active_admin_enrollment", user) do
          enrollments.for_user(user).of_admin_type.active_by_date.exists?
        end
    end
    can %i[
      read_as_admin
      read
      read_as_member
      manage
      update
      read_outcomes
      view_unpublished_items
      manage_feature_flags
      view_feature_flags
      read_rubrics
      use_student_view
    ]

    # Teachers and Designers can reset content, but not TAs
    given do |user|
      root_account.feature_enabled?(:granular_permissions_manage_courses) &&
        user && !deleted? && !template? &&
        fetch_on_enrollments("active_content_admin_enrollments", user) do
          enrollments.for_user(user).of_content_admins.active_by_date.to_a
        end.any? { |e| e.has_permission_to?(:manage_courses_reset) }
    end
    can :reset_content

    # Teachers and Designers can delete, but not TAs
    given do |user|
      root_account.feature_enabled?(:granular_permissions_manage_courses) && user &&
        !template? && !deleted? && !sis_source_id &&
        fetch_on_enrollments("active_content_admin_enrollments", user) do
          enrollments.for_user(user).of_content_admins.active_by_date.to_a
        end.any? { |e| e.has_permission_to?(:manage_courses_delete) }
    end
    can :delete

    # Student view student
    given { |user| user&.fake_student? && current_enrollments.for_user(user).exists? }
    can %i[read participate_as_student read_grades read_outcomes read_as_member]

    # Prior users
    given do |user|
      (available? || completed?) && user &&
        fetch_on_enrollments("has_completed_enrollment", user) { enrollments.for_user(user).completed_by_date.exists? }
    end
    can :read, :read_outcomes, :read_as_member

    # Admin (Teacher/TA/Designer) of a concluded course
    given do |user|
      !deleted? && user &&
        fetch_on_enrollments("has_completed_admin_enrollment", user) { enrollments.for_user(user).of_admin_type.completed_by_date.exists? }
    end
    can %i[read read_as_admin use_student_view read_outcomes view_unpublished_items read_rubrics read_as_member]

    # overrideable permissions for concluded users
    RoleOverride.concluded_permission_types.each do |permission, details|
      applicable_roles = details[:applies_to_concluded].is_a?(Array) && details[:applies_to_concluded]

      given do |user|
        !deleted? && user &&
          fetch_on_enrollments("completed_enrollments", user) { enrollments.for_user(user).completed_by_date.to_a }.any? { |e| e.has_permission_to?(permission) && (!applicable_roles || applicable_roles.include?(e.type)) }
      end
      can permission
    end

    # Teacher or Designer of a concluded course
    #################### Begin legacy permission block #########################
    given do |user|
      !root_account.feature_enabled?(:granular_permissions_manage_courses) && !deleted? &&
        !sis_source_id && user && !template? &&
        enrollments.for_user(user).of_content_admins.completed_by_date.to_a.any? do |e|
          e.has_permission_to?(:change_course_state)
        end
    end
    can :delete
    ##################### End legacy permission block ##########################

    given do |user|
      root_account.feature_enabled?(:granular_permissions_manage_courses) && user &&
        !sis_source_id && !deleted? && !template? &&
        enrollments.for_user(user).of_content_admins.completed_by_date.to_a.any? do |e|
          e.has_permission_to?(:manage_courses_delete)
        end
    end
    can :delete

    # Student of a concluded course
    given do |user|
      (available? || completed?) && user &&
        fetch_on_enrollments("has_completed_student_enrollment", user) do
          enrollments.for_user(user).completed_by_date
                     .where("enrollments.type = ? OR (enrollments.type = ? AND enrollments.associated_user_id IS NOT NULL)", "StudentEnrollment", "ObserverEnrollment").exists?
        end
    end
    can :read, :read_grades, :read_outcomes, :read_as_member

    # Admin
    #################### Begin legacy permission block #########################
    given do |user|
      !root_account&.feature_enabled?(:granular_permissions_manage_courses) &&
        account_membership_allows(user, :manage_courses)
    end
    can :read_as_admin and can :manage and can :update and can :use_student_view and can :reset_content and
      can :view_unpublished_items and can :manage_feature_flags and can :view_feature_flags

    given do |user|
      !root_account&.feature_enabled?(:granular_permissions_manage_courses) && !template? &&
        grants_right?(user, :change_course_state) && account_membership_allows(user, :manage_courses)
    end
    can :delete

    given do |user|
      !root_account&.feature_enabled?(:granular_permissions_manage_courses) && !deleted? &&
        sis_source_id && !template? && grants_right?(user, :change_course_state) && account_membership_allows(user, :manage_sis)
    end
    can :delete

    given do |user|
      user && !root_account.feature_enabled?(:granular_permissions_manage_lti) &&
        grants_right?(user, :lti_add_edit)
    end
    can :create_tool_manually
    ##################### End legacy permission block ##########################

    given { |user| account_membership_allows(user) }
    can :read_as_admin and can :view_unpublished_items

    given do |user|
      root_account.feature_enabled?(:granular_permissions_manage_courses) &&
        account_membership_allows(user, :manage_courses_admin)
    end
    can :manage and can :update and can :use_student_view and can :manage_feature_flags and
      can :view_feature_flags

    # reset course content
    given do |user|
      root_account.feature_enabled?(:granular_permissions_manage_courses) && !template? &&
        account_membership_allows(user, :manage_courses_reset)
    end
    can :reset_content

    # delete or undelete a given course
    given do |user|
      root_account.feature_enabled?(:granular_permissions_manage_courses) && !template? &&
        account_membership_allows(user, :manage_courses_delete)
    end
    can :delete

    given { |user| account_membership_allows(user, :read_course_content) }
    can %i[read read_outcomes read_as_member]

    # Admins with read_roster can see prior enrollments (can't just check read_roster directly,
    # because students can't see prior enrollments)
    given { |user| grants_all_rights?(user, :read_roster, :read_as_admin) }
    can :read_prior_roster

    given do |user|
      grants_any_right?(user, :manage_content, :manage_course_content_add) ||
        (concluded? && grants_right?(user, :read_as_admin))
    end
    can :direct_share

    given do |user|
      account.grants_any_right?(user, :manage_courses, :manage_courses_admin) ||
        (grants_right?(user, :manage) && !root_account.settings[:prevent_course_availability_editing_by_teachers])
    end
    can :edit_course_availability
  end

  def allows_gradebook_uploads?
    !large_roster?
  end

  # Public: Determine if SpeedGrader is enabled for the Course.
  #
  # Returns a boolean.
  def allows_speed_grader?
    !large_roster?
  end

  def active_enrollment_allows(user, permission, allow_future = true)
    return false unless user && permission && !deleted?

    is_unpublished = created? || claimed?
    active_enrollments = fetch_on_enrollments("active_enrollments_for_permissions2", user, is_unpublished) do
      scope = enrollments.for_user(user).active_or_pending_by_date.select("enrollments.*, enrollment_states.state AS date_based_state_in_db")
      scope = scope.where(type: %w[TeacherEnrollment TaEnrollment DesignerEnrollment StudentViewEnrollment]) if is_unpublished
      scope.to_a.each(&:clear_association_cache)
    end
    active_enrollments.each { |e| e.course = self } # set association so we don't requery
    active_enrollments.any? { |e| (allow_future || e.date_based_state_in_db == "active") && e.has_permission_to?(permission) }
  end

  def self.find_all_by_context_code(codes)
    ids = codes.filter_map { |c| c.match(/\Acourse_(\d+)\z/)[1] rescue nil }
    Course.where(id: ids).preload(:current_enrollments).to_a
  end

  def end_at
    conclude_at
  end

  def end_at_changed?
    conclude_at_changed?
  end

  def recently_ended?
    conclude_at && conclude_at < Time.now.utc && conclude_at > 1.month.ago
  end

  # People may conclude courses and then unclude them. This is a good alias_method
  # to check for in situations where we are dependent on those cases
  def inactive?
    deleted? || completed?
  end

  # Public: Return true if the end date for a course (or its term, if the course doesn't have one) has passed.
  # Logic should match up as much as possible with scopes `completed` and `not_completed`
  #
  # Returns boolean
  def soft_concluded?(enrollment_type = nil)
    now = Time.now
    return end_at < now if end_at && restrict_enrollments_to_course_dates

    if enrollment_type
      override = enrollment_term.enrollment_dates_overrides.where(enrollment_type:).first
      end_at = override.end_at if override
    end
    end_at ||= enrollment_term.end_at
    end_at ? end_at < now : false
  end

  def soft_conclude!
    self.conclude_at = Time.now
    self.restrict_enrollments_to_course_dates = true
  end

  def concluded?(enrollment_type = nil)
    completed? || soft_concluded?(enrollment_type)
  end

  def account_chain(include_site_admin: false, include_federated_parent: false)
    @account_chain ||= Account.account_chain(account_id).freeze

    # This implicitly includes add_federated_parent_to_chain
    if include_site_admin
      return @account_chain_with_site_admin ||= Account.add_site_admin_to_chain!(@account_chain.dup).freeze
    end

    if include_federated_parent
      return @account_chain_with_federated_parent ||= Account.add_federated_parent_to_chain!(@account_chain.dup).freeze
    end

    @account_chain
  end

  def account_chain_ids
    @account_chain_ids ||= Account.account_chain_ids(account_id)
  end

  def institution_name
    return root_account.name if self.root_account_id != Account.default.id

    (account || root_account).name
  end

  def account_users_for(user)
    @associated_account_ids ||= (associated_accounts(include_crosslisted_courses: false) + root_account.account_chain(include_site_admin: true))
                                .uniq.filter_map { |a| a.active? ? a.id : nil }
    Shard.partition_by_shard(@associated_account_ids) do |account_chain_ids|
      if account_chain_ids == [Account.site_admin.id]
        Account.site_admin.account_users_for(user)
      else
        AccountUser.active.where(account_id: account_chain_ids, user_id: user).to_a
      end
    end
  end

  def cached_account_users_for(user)
    return [] unless user

    @account_users ||= {}
    @account_users[user.global_id] ||= begin
      key = ["account_users_for_course_and_user", user.cache_key(:account_users), Account.cache_key_for_id(account_id, :account_chain)].cache_key
      Rails.cache.fetch_with_batched_keys(key, batch_object: self, batched_keys: :account_associations, skip_cache_if_disabled: true) do
        account_users_for(user).each(&:clear_association_cache)
      end
    end
  end

  # Since this method can return AdheresToPolicy::JustifiedFailure, it must be last in a `given` block
  # or must be explicitly checked for truth
  def account_membership_allows(user, permission = nil)
    return false unless user

    @membership_allows ||= {}
    @membership_allows[[user.id, permission]] ||= begin
      results = cached_account_users_for(user).map do |au|
        res = permission.nil? ? au.permitted_for_account?(root_account) : au.permission_check(self, permission)
        if res.success?
          break :success
        else
          res
        end
      end
      if results == :success
        true
      else
        # return the first result with a justification or false, either of which will deny access
        results.find { |r| r.is_a?(AdheresToPolicy::JustifiedFailure) } || false
      end
    end
  end

  def grade_publishing_status_translation(status, message)
    status = "unpublished" if status.blank?

    if message.present?
      case status
      when "error"
        t("Error: %{message}", message:)
      when "unpublished"
        t("Not Synced: %{message}", message:)
      when "pending"
        t("Pending: %{message}", message:)
      when "publishing"
        t("Syncing: %{message}", message:)
      when "published"
        t("Synced: %{message}", message:)
      when "unpublishable"
        t("Unsyncable: %{message}", message:)
      else
        t("Unknown status, %{status}: %{message}", message:, status:)
      end
    else
      case status
      when "error"
        t("Error")
      when "unpublished"
        t("Not Synced")
      when "pending"
        t("Pending")
      when "publishing"
        t("Syncing")
      when "published"
        t("Synced")
      when "unpublishable"
        t("Unsyncable")
      else
        t("Unknown status, %{status}", status:)
      end
    end
  end

  def grade_publishing_statuses
    found_statuses = [].to_set
    enrollments = student_enrollments.not_fake.group_by do |e|
      found_statuses.add e.grade_publishing_status
      grade_publishing_status_translation(e.grade_publishing_status, e.grade_publishing_message)
    end
    overall_status = "error"
    overall_status = "unpublished" if found_statuses.empty?
    overall_status = %w[error unpublished pending publishing published unpublishable].detect { |s| found_statuses.include?(s) } || overall_status
    [enrollments, overall_status]
  end

  def should_kick_off_grade_publishing_timeout?
    settings = Canvas::Plugin.find!("grade_export").settings
    settings[:success_timeout].to_i > 0 && Canvas::Plugin.value_to_boolean(settings[:wait_for_success])
  end

  def self.valid_grade_export_types
    @valid_grade_export_types ||= {
      "instructure_csv" => {
        name: t("grade_export_types.instructure_csv", "Instructure formatted CSV"),
        callback: lambda do |course, enrollments, publishing_user, publishing_pseudonym|
                    grade_export_settings = Canvas::Plugin.find!("grade_export").settings || {}
                    include_final_grade_overrides = Canvas::Plugin.value_to_boolean(
                      grade_export_settings[:include_final_grade_overrides]
                    )
                    include_final_grade_overrides &= course.allow_final_grade_override?

                    course.generate_grade_publishing_csv_output(
                      enrollments,
                      publishing_user,
                      publishing_pseudonym,
                      include_final_grade_overrides:
                    )
                  end,
        requires_grading_standard: false,
        requires_publishing_pseudonym: false
      }
    }
  end

  def allows_grade_publishing_by(user)
    return false unless Canvas::Plugin.find!("grade_export").enabled?

    settings = Canvas::Plugin.find!("grade_export").settings
    format_settings = Course.valid_grade_export_types[settings[:format_type]]
    return false unless format_settings
    return false if SisPseudonym.for(user, self).nil? && format_settings[:requires_publishing_pseudonym]

    true
  end

  def publish_final_grades(publishing_user, user_ids_to_publish = nil)
    # we want to set all the publishing statuses to 'pending' immediately,
    # and then as a delayed job, actually go publish them.

    raise "final grade publishing disabled" unless Canvas::Plugin.find!("grade_export").enabled?

    settings = Canvas::Plugin.find!("grade_export").settings

    last_publish_attempt_at = Time.now.utc
    scope = student_enrollments.not_fake
    scope = scope.where(user_id: user_ids_to_publish) if user_ids_to_publish
    scope.update_all(grade_publishing_status: "pending",
                     grade_publishing_message: nil,
                     last_publish_attempt_at:)

    delay_if_production(n_strand: ["send_final_grades_to_endpoint", global_root_account_id])
      .send_final_grades_to_endpoint(publishing_user, user_ids_to_publish)
    delay(run_at: last_publish_attempt_at + settings[:success_timeout].to_i.seconds).expire_pending_grade_publishing_statuses(last_publish_attempt_at) if should_kick_off_grade_publishing_timeout?
  end

  def send_final_grades_to_endpoint(publishing_user, user_ids_to_publish = nil)
    # actual grade publishing logic is here, but you probably want
    # 'publish_final_grades'

    recompute_student_scores_without_send_later(user_ids_to_publish)
    enrollments = student_enrollments.not_fake.eager_load(:user).preload(:course_section).order_by_sortable_name
    enrollments = enrollments.where(user_id: user_ids_to_publish) if user_ids_to_publish

    errors = []
    posts_to_make = []
    posted_enrollment_ids = []
    all_enrollment_ids = enrollments.map(&:id)

    begin
      raise "final grade publishing disabled" unless Canvas::Plugin.find!("grade_export").enabled?

      settings = Canvas::Plugin.find!("grade_export").settings
      raise "endpoint undefined" if settings[:publish_endpoint].blank?

      format_settings = Course.valid_grade_export_types[settings[:format_type]]
      raise "unknown format type: #{settings[:format_type]}" unless format_settings
      raise "grade publishing requires a grading standard" if !grading_standard_enabled? && format_settings[:requires_grading_standard]

      publishing_pseudonym = SisPseudonym.for(publishing_user, self)
      raise "publishing disallowed for this publishing user" if publishing_pseudonym.nil? && format_settings[:requires_publishing_pseudonym]

      callback = Course.valid_grade_export_types[settings[:format_type]][:callback]
      posts_to_make = callback.call(self, enrollments, publishing_user, publishing_pseudonym)
    rescue => e
      Enrollment.where(id: all_enrollment_ids).update_all(grade_publishing_status: "error", grade_publishing_message: e.to_s)
      raise e
    end

    default_timeout = Setting.get("send_final_grades_to_endpoint_timelimit", 15.seconds.to_s).to_f

    timeout_options = { raise_on_timeout: true, fallback_timeout_length: default_timeout }

    posts_to_make.each do |enrollment_ids, res, mime_type, headers = {}|
      posted_enrollment_ids += enrollment_ids
      if res
        Canvas.timeout_protection("send_final_grades_to_endpoint:#{global_root_account_id}", timeout_options) do
          SSLCommon.post_data(settings[:publish_endpoint], res, mime_type, headers)
        end
      end
      Enrollment.where(id: enrollment_ids).update_all(grade_publishing_status: (should_kick_off_grade_publishing_timeout? ? "publishing" : "published"), grade_publishing_message: nil)
    rescue => e
      errors << e
      Enrollment.where(id: enrollment_ids).update_all(grade_publishing_status: "error", grade_publishing_message: e.to_s)
    end

    Enrollment.where(id: (all_enrollment_ids.to_set - posted_enrollment_ids.to_set).to_a).update_all(grade_publishing_status: "unpublishable", grade_publishing_message: nil)

    raise errors[0] unless errors.empty?
  end

  def generate_grade_publishing_csv_output(enrollments, publishing_user, publishing_pseudonym, include_final_grade_overrides: false)
    ActiveRecord::Associations.preload(enrollments, { user: :pseudonyms })
    custom_gradebook_statuses_enabled = Account.site_admin.feature_enabled?(:custom_gradebook_statuses) && include_final_grade_overrides

    enrollment_ids = []

    res = CSV.generate do |csv|
      column_names = %w[
        publisher_id
        publisher_sis_id
        course_id
        course_sis_id
        section_id
        section_sis_id
        student_id
        student_sis_id
        enrollment_id
        enrollment_status
        score
      ]
      column_names << "grade" if grading_standard_enabled?
      column_names << "custom_grade_status" if custom_gradebook_statuses_enabled
      csv << column_names

      if include_final_grade_overrides
        custom_grade_status_map = custom_grade_statuses.pluck(:id, :name).to_h
      end

      enrollments.each do |enrollment|
        next if include_final_grade_overrides && !enrollment.effective_final_score
        next if !include_final_grade_overrides && !enrollment.computed_final_score

        enrollment_ids << enrollment.id

        if include_final_grade_overrides
          grade = enrollment.effective_final_grade
          score = enrollment.effective_final_score

          if custom_gradebook_statuses_enabled
            custom_grade_status_id = enrollment.effective_final_grade_custom_status_id
            custom_grade_status_name = custom_grade_status_map[custom_grade_status_id]
          end
        else
          grade = enrollment.computed_final_grade
          score = enrollment.computed_final_score
        end

        sis_pseudonyms =
          SisPseudonym.for(enrollment.user, root_account, include_all_pseudonyms: true)
        pseudonym_sis_ids = sis_pseudonyms ? sis_pseudonyms.map(&:sis_user_id) : [nil]

        pseudonym_sis_ids.each do |pseudonym_sis_id|
          row = [
            publishing_user.try(:id),
            publishing_pseudonym.try(:sis_user_id),
            enrollment.course.id,
            enrollment.course.sis_source_id,
            enrollment.course_section.id,
            enrollment.course_section.sis_source_id,
            enrollment.user.id,
            pseudonym_sis_id,
            enrollment.id,
            enrollment.workflow_state,
            score
          ]
          row << grade if grading_standard_enabled?
          row << custom_grade_status_name if custom_gradebook_statuses_enabled
          csv << row
        end
      end
    end

    if enrollment_ids.any?
      [[enrollment_ids, res, "text/csv"]]
    else
      []
    end
  end

  def expire_pending_grade_publishing_statuses(last_publish_attempt_at)
    student_enrollments.not_fake.where(grade_publishing_status: ["pending", "publishing"],
                                       last_publish_attempt_at:)
                       .update_all(grade_publishing_status: "error", grade_publishing_message: "Timed out.")
  end

  def gradebook_to_csv_in_background(filename, user, options = {})
    progress = progresses.build(tag: "gradebook_to_csv", user:)
    progress.save!

    exported_gradebook = gradebook_csvs.where(user_id: user).first_or_initialize
    attachment = user.attachments.build
    attachment.filename = filename
    attachment.content_type = "text/csv"
    attachment.file_state = "hidden"
    attachment.save!
    exported_gradebook.attachment = attachment
    exported_gradebook.progress = progress
    exported_gradebook.save!

    progress.process_job(
      self,
      :generate_csv,
      { priority: Delayed::HIGH_PRIORITY },
      user,
      options,
      attachment
    )
    { attachment_id: attachment.id, progress_id: progress.id, filename: }
  end

  def generate_csv(progress, user, options, attachment)
    csv = GradebookExporter.new(self, user, options.merge(progress:)).to_csv
    create_attachment(attachment, csv)
  end

  def create_attachment(attachment, csv)
    Attachments::Storage.store_for_attachment(attachment, StringIO.new(csv))
    attachment.content_type = "text/csv"
    attachment.save!
  end

  def create_or_update_quiz_migration_alert(user_id, migration)
    quiz_migration_alert = quiz_migration_alerts.find_by(user_id:)

    if quiz_migration_alert.nil?
      new_quiz_migration_alert = quiz_migration_alerts.build(user_id:, migration:)
      new_quiz_migration_alert.save
    elsif quiz_migration_alert && quiz_migration_alert.migration != migration
      quiz_migration_alert.update(migration:)
    end
  end

  def quiz_migration_alert_for_user(user_id)
    quiz_migration_alerts.find_by(user_id:)
  end

  # included to make it easier to work with api, which returns
  # sis_source_id as sis_course_id.
  alias_attribute :sis_course_id, :sis_source_id

  def grading_standard_title
    if grading_standard_enabled?
      default_grading_standard.try(:title) || t("default_grading_scheme_name", "Default Grading Scheme")
    else
      nil
    end
  end

  def score_to_grade(score, user: nil)
    return nil unless (grading_standard_enabled? || restrict_quantitative_data?(user)) && score

    if default_grading_standard
      default_grading_standard.score_to_grade(score)
    else
      GradingStandard.default_instance.score_to_grade(score)
    end
  end

  def active_course_level_observers
    participating_observers.observing_full_course(id)
  end

  def participants(opts = {})
    participants = []
    by_date = opts[:by_date]
    participants += by_date ? participating_admins_by_date : participating_admins

    students = by_date ? participating_students_by_date : participating_students
    applicable_students = if opts[:excluded_user_ids]
                            students.reject { |p| opts[:excluded_user_ids].include?(p.id) }
                          else
                            students
                          end

    participants += applicable_students

    if opts[:include_observers]
      participants += User.observing_students_in_course(applicable_students.map(&:id), id)
      participants += User.observing_full_course(id)
    end

    participants.uniq
  end

  def filter_users_by_permission(users, permission)
    scope = enrollments.where(user_id: users)
    details = RoleOverride.permissions[permission]
    scope = details[:applies_to_concluded] ? scope.not_inactive_by_date : scope.active_or_pending_by_date

    role_user_ids = scope.pluck(:role_id, :user_id)
    role_ids = role_user_ids.map(&:first).uniq

    roles = Role.where(id: role_ids).to_a
    allowed_role_ids = roles.select { |role| RoleOverride.enabled_for?(self, permission, role, self).include?(:self) }.map(&:id)
    return [] unless allowed_role_ids.any?

    allowed_user_ids = Set.new
    role_user_ids.each { |role_id, user_id| allowed_user_ids << user_id if allowed_role_ids.include?(role_id) }
    users.select { |user| allowed_user_ids.include?(user.id) }
  end

  def enroll_user(user, type = "StudentEnrollment", opts = {})
    enrollment_state = opts[:enrollment_state]
    if (type == "ObserverEnrollment" || opts[:temporary_enrollment_source_user_id]) && user.registered?
      enrollment_state ||= "active"
    end
    section = opts[:section]
    limit_privileges_to_course_section = opts[:limit_privileges_to_course_section] || false
    associated_user_id = opts[:associated_user_id]

    role = opts[:role] || shard.activate { Enrollment.get_built_in_role_for_type(type, root_account_id: self.root_account_id) }

    start_at = opts[:start_at]
    end_at = opts[:end_at]
    self_enrolled = opts[:self_enrolled]
    section ||= default_section
    enrollment_state ||= available? ? "invited" : "creation_pending"
    if type.include?("TeacherEnrollment") || type.include?("TaEnrollment") || type.include?("DesignerEnrollment")
      enrollment_state = "invited" if enrollment_state == "creation_pending"
    elsif enrollment_state == "invited" && !available?
      enrollment_state = "creation_pending"
    end

    Course.unique_constraint_retry do
      scope = all_enrollments.where(user_id: user,
                                    type:,
                                    role_id: role,
                                    associated_user_id:)
      if root_account.feature_enabled?(:temporary_enrollments) && opts[:temporary_enrollment_source_user_id] &&
         opts[:temporary_enrollment_pairing_id]
        source_user_id = opts[:temporary_enrollment_source_user_id]
        pairing_id = opts[:temporary_enrollment_pairing_id]
      end
      e = if opts[:allow_multiple_enrollments]
            scope.where(course_section_id: section.id).first
          else
            # order by course_section_id<>section.id so that if there *is* an existing
            # enrollment for this section, we get it (false orders before true)
            scope.order(Arel.sql("course_section_id<>#{section.id}")).first
          end
      if e && (!e.active? || opts[:force_update])
        e.already_enrolled = true
        if e.workflow_state == "deleted"
          e.sis_batch_id = nil
        end
        if e.completed? || e.rejected? || e.deleted? || e.workflow_state != enrollment_state
          e.attributes = {
            course_section: section,
            workflow_state: e.is_a?(StudentViewEnrollment) ? "active" : enrollment_state
          }
        end
      end
      # if we're reusing an enrollment and +limit_privileges_to_course_section+ was supplied, apply it
      e.limit_privileges_to_course_section = limit_privileges_to_course_section if e
      # if we're creating a new enrollment, we want to return it as the correct
      # subclass, but without using associations, we need to manually activate
      # sharding. We should probably find a way to go back to using the
      # association here -- just ran out of time.
      shard.activate do
        e ||= Enrollment.typed_enrollment(type).new(
          user:,
          course: self,
          course_section: section,
          workflow_state: enrollment_state,
          limit_privileges_to_course_section:
        )
      end
      e.associated_user_id = associated_user_id
      e.temporary_enrollment_source_user_id = source_user_id
      e.temporary_enrollment_pairing_id = pairing_id
      e.role = role
      e.self_enrolled = self_enrolled
      e.start_at = start_at
      e.end_at = end_at
      e.sis_pseudonym_id = opts[:sis_pseudonym_id]
      if e.changed?
        e.need_touch_user = true if opts[:skip_touch_user]
        if opts[:no_notify]
          e.save_without_broadcasting
        else
          e.save
        end
      end
      e.user = user
      claim if created? && e && e.admin?
      unless opts[:skip_touch_user]
        e.associated_user.try(:touch)
        user.touch
      end
      user.reload
      e
    end
  end

  def enroll_student(user, opts = {})
    enroll_user(user, "StudentEnrollment", opts)
  end

  def self_enroll_student(user, opts = {})
    enrollment = enroll_student(user, opts.merge(self_enrolled: true))
    enrollment.accept(:force)
    unless opts[:skip_pseudonym]
      new_pseudonym = user.find_or_initialize_pseudonym_for_account(root_account)
      new_pseudonym.save if new_pseudonym&.changed?
    end
    enrollment
  end

  def enroll_ta(user, opts = {})
    enroll_user(user, "TaEnrollment", opts)
  end

  def enroll_designer(user, opts = {})
    enroll_user(user, "DesignerEnrollment", opts)
  end

  def enroll_teacher(user, opts = {})
    enroll_user(user, "TeacherEnrollment", opts)
  end

  def resubmission_for(asset)
    asset.ignores.where(purpose: "grading", permanent: false).delete_all
    instructors.clear_cache_keys(:todo_list)
  end

  def default_grading_standard
    if grading_standard_id
      grading_standard
    else
      account.default_grading_standard
    end
  end

  def course_grading_standard_enabled
    !!grading_standard_id
  end
  alias_method :course_grading_standard_enabled?, :course_grading_standard_enabled

  def grading_standard_enabled
    !!grading_standard_id || account.grading_standard_enabled?
  end
  alias_method :grading_standard_enabled?, :grading_standard_enabled

  def grading_standard_enabled=(val)
    if Canvas::Plugin.value_to_boolean(val)
      self.grading_standard_id ||= 0
    else
      self.grading_standard = self.grading_standard_id = nil
    end
  end
  alias_method :course_grading_standard_enabled=, :grading_standard_enabled=

  def readable_default_wiki_editing_roles
    roles = default_wiki_editing_roles || "teachers"
    case roles
    when "teachers,students"
      t("wiki_permissions.teachers_students", "Teacher and Students")
    when "teachers,students,public"
      t("wiki_permissions.all", "Anyone")
    else # 'teachers'
      t("wiki_permissions.only_teachers", "Only Teachers")
    end
  end

  def default_section(opts = {})
    section = course_sections.active.where(default_section: true).first
    if !section && opts[:include_xlists]
      section = CourseSection.active.where(nonxlist_course_id: self).order(:id).first
    end
    if !section && !opts[:no_create]
      section = course_sections.build
      section.default_section = true
      section.course = self
      section.root_account_id = self.root_account_id
      unless new_record?
        GuardRail.activate(:primary) do
          CourseSection.unique_constraint_retry do |retry_count|
            if retry_count > 0
              section = course_sections.active.where(default_section: true).first
            else
              section.save
            end
          end
        end
      end
    end
    section
  end

  def assert_section
    if course_sections.active.empty?
      default = default_section
      default.workflow_state = "active"
      default.save
    end
  end

  def file_structure_for(user)
    User.file_structure_for(self, user)
  end

  delegate :turnitin_settings, to: :account

  def turnitin_pledge
    account.closest_turnitin_pledge
  end

  def turnitin_originality
    account.closest_turnitin_originality
  end

  def all_turnitin_comments
    comments = account.closest_turnitin_comments || ""
    if turnitin_comments.present?
      comments += "\n\n" if comments.present?
      comments += turnitin_comments
    end
    extend TextHelper
    format_message(comments).first
  end

  def turnitin_enabled?
    !!turnitin_settings
  end

  def vericite_enabled?
    Canvas::Plugin.find(:vericite).try(:enabled?)
  end

  def vericite_pledge
    if vericite_enabled?
      Canvas::Plugin.find(:vericite).settings[:pledge]
    end
  end

  def vericite_comments
    if vericite_enabled?
      Canvas::Plugin.find(:vericite).settings[:comments]
    end
  end

  def bool_res(val)
    Canvas::Plugin.value_to_boolean(val)
  end

  attr_accessor :full_migration_hash,
                :external_url_hash,
                :folder_name_lookups,
                :assignment_group_no_drop_assignments,
                :migration_results

  def map_merge(old_item, new_item)
    @merge_mappings ||= {}
    @merge_mappings[old_item.asset_string] = new_item && new_item.id
  end

  def merge_mapped_id(old_item)
    @merge_mappings ||= {}
    return nil unless old_item
    return @merge_mappings[old_item] if old_item.is_a?(String)

    @merge_mappings[old_item.asset_string]
  end

  def same_dates?(old, new, columns)
    old && new && columns.all? do |column|
      old.respond_to?(column) && new.respond_to?(column) && old.send(column) == new.send(column)
    end
  end

  def student_annotation_documents_folder
    Folder.unique_folder(
      self,
      Folder::STUDENT_ANNOTATION_DOCUMENTS_UNIQUE_TYPE,
      -> { t "Student Annotation Documents" }
    )
  end

  def copy_attachments_from_course(course, options = {})
    root_folder = Folder.root_folders(self).first
    root_folder_name = root_folder.name + "/"
    ce = options[:content_export]
    cm = options[:content_migration]

    attachments = course.attachments.not_deleted.to_a
    total = attachments.count + 1

    Attachment.skip_media_object_creation do
      attachments.each_with_index do |file, i|
        cm.update_import_progress((i.to_f / total) * 18.0) if cm && (i % 10 == 0)

        next unless !ce || ce.export_object?(file)

        begin
          migration_id = ce&.create_key(file)
          new_file = file.clone_for(self, nil, overwrite: true, migration_id:, migration: cm, match_on_migration_id: cm.for_master_course_import?)
          cm.add_attachment_path(file.full_display_path.gsub(/\A#{root_folder_name}/, ""), new_file.migration_id)
          new_folder_id = merge_mapped_id(file.folder)

          if file.folder && file.folder.parent_folder_id.nil?
            new_folder_id = root_folder.id
          end
          # make sure the file has somewhere to go
          unless new_folder_id
            # gather mapping of needed folders from old course to new course
            old_folders = []
            old_folders << file.folder
            new_folders = []
            new_folders << old_folders.last.clone_for(self, nil, options.merge({ include_subcontent: false }))
            while old_folders.last.parent_folder&.parent_folder_id
              old_folders << old_folders.last.parent_folder
              new_folders << old_folders.last.clone_for(self, nil, options.merge({ include_subcontent: false }))
            end
            old_folders.reverse!
            new_folders.reverse!
            # try to use folders that already match if possible
            final_new_folders = []
            parent_folder = Folder.root_folders(self).first
            old_folders.each_with_index do |folder, idx|
              final_new_folders << if (f = parent_folder.active_sub_folders.where(name: folder.name).first)
                                     f
                                   else
                                     new_folders[idx]
                                   end
              parent_folder = final_new_folders.last
            end
            # add or update the folder structure needed for the file
            final_new_folders.first.parent_folder_id ||=
              merge_mapped_id(old_folders.first.parent_folder) ||
              Folder.root_folders(self).first.id
            old_folders.each_with_index do |folder, idx|
              final_new_folders[idx].save!
              map_merge(folder, final_new_folders[idx])
              final_new_folders[idx + 1].parent_folder_id ||= final_new_folders[idx].id if final_new_folders[idx + 1]
            end
            new_folder_id = merge_mapped_id(file.folder)
          end
          new_file.folder_id = new_folder_id
          new_file.need_notify = false
          new_file.save_without_broadcasting!
          new_file.handle_duplicates(:rename)
          cm.add_imported_item(new_file)
          cm.add_imported_item(new_file.folder, key: new_file.folder.id)
          map_merge(file, new_file)
        rescue => e
          Canvas::Errors.capture(e)
          Rails.logger.error "Couldn't copy file: #{e}"
          cm.add_warning(t(:file_copy_error, "Couldn't copy file \"%{name}\"", name: file.display_name || file.path_name), $!)
        end
      end
    end
  end

  def self.clonable_attributes
    %i[group_weighting_scheme
       grading_standard_id
       is_public
       is_public_to_auth_users
       public_syllabus
       public_syllabus_to_auth
       files_visibility
       allow_student_wiki_edits
       show_public_context_messages
       syllabus_body
       syllabus_course_summary
       allow_student_forum_attachments
       lock_all_announcements
       default_wiki_editing_roles
       allow_student_organized_groups
       default_view
       show_total_grade_as_points
       allow_final_grade_override
       open_enrollment
       filter_speed_grader_by_student_group
       storage_quota
       tab_configuration
       allow_wiki_comments
       turnitin_comments
       self_enrollment
       license
       indexed
       locale
       hide_final_grade
       hide_distribution_graphs
       allow_student_anonymous_discussion_topics
       allow_student_discussion_topics
       allow_student_discussion_editing
       lock_all_announcements
       allow_student_discussion_reporting
       organize_epub_by_content_type
       show_announcements_on_home_page
       home_page_announcement_limit
       enable_offline_web_export
       usage_rights_required
       restrict_student_future_view
       restrict_student_past_view
       restrict_enrollments_to_course_dates
       homeroom_course
       course_color
       alt_name
       restrict_quantitative_data]
  end

  def student_reporting?
    !!allow_student_discussion_reporting
  end

  def set_course_dates_if_blank(shift_options)
    unless Canvas::Plugin.value_to_boolean(shift_options[:remove_dates])
      self.start_at ||= shift_options[:default_start_at]
      self.conclude_at ||= shift_options[:default_conclude_at]
    end
  end

  def real_start_date
    return self.start_at.to_date if self.start_at

    all_dates.min
  end

  def all_dates
    (calendar_events.active + assignments.active).each_with_object([]) do |e, list|
      list << e.end_at if e.end_at
      list << e.start_at if e.start_at
    end.compact.flatten.map(&:to_date).uniq rescue []
  end

  def real_end_date
    return self.conclude_at.to_date if self.conclude_at

    all_dates.max
  end

  def is_a_context?
    true
  end

  def self.serialization_excludes
    [:uuid]
  end

  # helper method to DRY-up some similar methods that all can be cached based on a user's enrollments
  def fetch_on_enrollments(key, user, opts = nil, &)
    shard.activate do
      RequestCache.cache(key, user, self, opts) do
        Rails.cache.fetch_with_batched_keys([key, global_asset_string, opts].compact.cache_key, batch_object: user, batched_keys: :enrollments) do
          GuardRail.activate(:primary, &)
        end
      end
    end
  end

  ADMIN_TYPES = %w[TeacherEnrollment TaEnrollment DesignerEnrollment].freeze
  def section_visibilities_for(user, opts = {})
    fetch_on_enrollments("section_visibilities_for", user, opts) do
      workflow_not = opts[:excluded_workflows] || "deleted"

      enrollment_rows = all_enrollments
                        .where(user:)
                        .where.not(workflow_state: workflow_not)
                        .pluck(
                          :course_section_id,
                          :limit_privileges_to_course_section,
                          :type,
                          :associated_user_id,
                          :workflow_state
                        )

      enrollment_rows.map do |section_id, limit_privileges, type, associated_user_id, workflow_state|
        {
          course_section_id: section_id,
          limit_privileges_to_course_section: limit_privileges,
          type:,
          associated_user_id:,
          admin: ADMIN_TYPES.include?(type),
          workflow_state:
        }
      end
    end
  end

  def visibility_limited_to_course_sections?(user, visibilities = section_visibilities_for(user))
    visibilities.all? { |s| s[:limit_privileges_to_course_section] }
  end

  # returns a scope, not an array of users/enrollments
  def students_visible_to(user, include: nil)
    include = Array(include)

    if include.include?(:priors_and_deleted)
      scope = all_students_including_deleted
    elsif include.include?(:priors)
      scope = all_students
    elsif include.include?(:inactive) || include.include?(:completed)
      scope = all_accepted_students
      scope = scope.where("enrollments.workflow_state<>'inactive'") unless include.include?(:inactive)
      scope = scope.where("enrollments.workflow_state<>'completed'") unless include.include?(:completed)
    else
      scope = students
    end

    apply_enrollment_visibility(scope, user, nil, include:)
  end

  # can apply to user scopes as well if through enrollments (e.g. students, teachers)
  # returns a scope for enrollments
  def apply_enrollment_visibility(scope, user, section_ids = nil, include: [])
    include = Array(include)
    if section_ids
      scope = scope.where("enrollments.course_section_id" => section_ids.to_a)
    end

    visibilities = section_visibilities_for(user)
    visibility_level = enrollment_visibility_level_for(user, visibilities)

    # teachers, account admins, and student view students can see student view students
    unless visibility_level == :full ||
           visibilities.any? { |v| v[:admin] || v[:type] == "StudentViewEnrollment" }
      scope = scope.where("enrollments.type<>'StudentViewEnrollment'")
    end

    if include.include?(:inactive) && ![:full, :sections].include?(visibility_level)
      # don't really include inactive unless user is able to view them
      scope = scope.where("enrollments.workflow_state <> 'inactive'")
    end
    if include.include?(:completed) && ![:full, :sections].include?(visibility_level)
      # don't really include concluded unless user is able to view them
      scope = scope.where("enrollments.workflow_state <> 'completed'")
    end
    # See also MessageableUser::Calculator (same logic used to get
    # users across multiple courses) (should refactor)
    case visibility_level
    when :full, :limited
      scope
    when :sections, :sections_limited
      scope.where("enrollments.course_section_id IN (?) OR (enrollments.limit_privileges_to_course_section=? AND enrollments.type IN ('TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment'))",
                  visibilities.pluck(:course_section_id),
                  false)
    when :restricted
      user_ids = visibilities.filter_map { |s| s[:associated_user_id] }
      scope.where(enrollments: { user_id: (user_ids + [user&.id]).compact })
    else
      scope.none
    end
  end

  def users_visible_to(user, include_priors = false, opts = {})
    visibilities = section_visibilities_for(user)
    visibility = enrollment_visibility_level_for(user, visibilities)

    scope = if include_priors
              users
            elsif opts[:include_inactive] && [:full, :sections].include?(visibility)
              all_current_users
            else
              current_users
            end

    apply_enrollment_visibilities_internal(scope,
                                           user,
                                           visibilities,
                                           visibility,
                                           enrollment_state: opts[:enrollment_state],
                                           exclude_enrollment_state: opts[:exclude_enrollment_state])
  end

  def enrollments_visible_to(user, opts = {})
    visibilities = section_visibilities_for(user)
    visibility = enrollment_visibility_level_for(user, visibilities)

    enrollment_scope = opts[:include_concluded] ? enrollments : current_enrollments
    apply_enrollment_visibilities_internal(enrollment_scope.except(:preload), user, visibilities, visibility)
  end

  def apply_enrollment_visibilities_internal(scope, user, visibilities, visibility, enrollment_state: nil, exclude_enrollment_state: nil)
    if enrollment_state
      scope = scope.where(enrollments: { workflow_state: enrollment_state })
    elsif exclude_enrollment_state
      scope = scope.where.not(enrollments: { workflow_state: exclude_enrollment_state })
    end
    # See also MessageableUsers (same logic used to get users across multiple courses) (should refactor)
    case visibility
    when :full then scope
    when :sections then scope.where(enrollments: { course_section_id: visibilities.pluck(:course_section_id) })
    when :restricted then scope.where(enrollments: { user_id: (visibilities.filter_map { |s| s[:associated_user_id] } + [user]) })
    when :limited then scope.where(enrollments: { type: %w[StudentEnrollment TeacherEnrollment TaEnrollment StudentViewEnrollment] })
    when :sections_limited then scope.where(enrollments: { course_section_id: visibilities.pluck(:course_section_id) })
                                     .where(enrollments: { type: %w[StudentEnrollment TeacherEnrollment TaEnrollment StudentViewEnrollment] })
    else scope.none
    end
  end

  # returns :all or an array of section ids
  def course_section_visibility(user, opts = {})
    visibilities = section_visibilities_for(user, opts)
    visibility = enrollment_visibility_level_for(user, visibilities, check_full: false)
    enrollment_types = %w[StudentEnrollment StudentViewEnrollment ObserverEnrollment]
    if [:restricted, :sections].include?(visibility) || (
        visibilities.any? && visibilities.all? { |v| enrollment_types.include? v[:type] }
      )
      visibilities.map { |s| s[:course_section_id] }.sort # rubocop:disable Rails/Pluck
    else
      :all
    end
  end

  def sections_visible_to(user, sections = active_course_sections, opts = {})
    is_scope = sections.respond_to?(:where)
    section_ids = course_section_visibility(user, opts)
    case section_ids
    when :all
      sections
    when :none
      # return an empty set, but keep it as a scope for downstream consistency
      is_scope ? sections.none : []
    when Array
      is_scope ? sections.where(id: section_ids) : sections.select { |section| section_ids.include?(section.id) }
    end
  end

  # check_full is a hint that we don't care about the difference between :full and :limited,
  # so don't bother with an extra permission check to see if they have :full. Just return :limited.
  def enrollment_visibility_level_for(user,
                                      visibilities = section_visibilities_for(user),
                                      require_message_permission: false,
                                      check_full: true)
    manage_perm = if root_account.feature_enabled? :granular_permissions_manage_users
                    :allow_course_admin_actions
                  else
                    :manage_admin_users
                  end

    return :restricted if require_message_permission && !grants_right?(user, :send_messages)

    has_read_roster = grants_right?(user, :read_roster) unless require_message_permission

    visibility_limited_to_section = visibilities.present? && visibility_limited_to_course_sections?(user, visibilities)
    if require_message_permission
      has_admin = true
    elsif visibility_limited_to_section || check_full || !has_read_roster
      has_admin = grants_any_right?(user,
                                    :read_as_admin,
                                    :view_all_grades,
                                    :manage_grades,
                                    :manage_students,
                                    manage_perm)
    end

    # e.g. observer, can only see admins in the course
    return :restricted unless has_read_roster || has_admin

    if visibility_limited_to_section
      has_admin ? :sections : :sections_limited
    elsif has_admin
      :full
    else
      :limited
    end
  end

  def invited_count_visible_to(user)
    scope = users_visible_to(user)
            .where("enrollments.workflow_state in ('invited', 'creation_pending') AND enrollments.type != 'StudentViewEnrollment'")
    scope.select("users.id").distinct.count
  end

  def published?
    available? || completed?
  end

  def unpublished?
    created? || claimed?
  end

  def tab_configuration
    # `account_id.present?` is there to prevent a failure in `feature_enabled?`
    # if an account hasn't been set on the course yet
    if account_id.present? && feature_enabled?(:canvas_k6_theme) && super.nil?
      return canvas_k6_tab_configuration.map(&:with_indifferent_access)
    end

    super.compact.map(&:with_indifferent_access) rescue []
  end

  TAB_HOME = 0
  TAB_SYLLABUS = 1
  TAB_PAGES = 2
  TAB_ASSIGNMENTS = 3
  TAB_QUIZZES = 4
  TAB_GRADES = 5
  TAB_PEOPLE = 6
  TAB_GROUPS = 7
  TAB_DISCUSSIONS = 8
  TAB_MODULES = 10
  TAB_FILES = 11
  TAB_CONFERENCES = 12
  TAB_SETTINGS = 13
  TAB_ANNOUNCEMENTS = 14
  TAB_OUTCOMES = 15
  TAB_COLLABORATIONS = 16
  TAB_COLLABORATIONS_NEW = 17
  TAB_RUBRICS = 18
  TAB_SCHEDULE = 19
  TAB_COURSE_PACES = 20
  TAB_SEARCH = 21

  CANVAS_K6_TAB_IDS = [TAB_HOME, TAB_ANNOUNCEMENTS, TAB_GRADES, TAB_MODULES].freeze
  COURSE_SUBJECT_TAB_IDS = [TAB_HOME, TAB_SCHEDULE, TAB_MODULES, TAB_GRADES, TAB_GROUPS].freeze

  def self.default_tabs
    [{
      id: TAB_HOME,
      label: t("#tabs.home", "Home"),
      css_class: "home",
      href: :course_path
    },
     {
       id: TAB_ANNOUNCEMENTS,
       label: t("#tabs.announcements", "Announcements"),
       css_class: "announcements",
       href: :course_announcements_path,
       icon: "icon-announcement"
     },
     {
       id: TAB_ASSIGNMENTS,
       label: t("#tabs.assignments", "Assignments"),
       css_class: "assignments",
       href: :course_assignments_path,
       icon: "icon-assignment"
     },
     {
       id: TAB_DISCUSSIONS,
       label: t("#tabs.discussions", "Discussions"),
       css_class: "discussions",
       href: :course_discussion_topics_path,
       icon: "icon-discussion"
     },
     {
       id: TAB_GRADES,
       label: t("#tabs.grades", "Grades"),
       css_class: "grades",
       href: :course_grades_path,
     },
     {
       id: TAB_PEOPLE,
       label: t("#tabs.people", "People"),
       css_class: "people",
       href: :course_users_path
     },
     {
       id: TAB_PAGES,
       label: t("#tabs.pages", "Pages"),
       css_class: "pages",
       href: :course_wiki_path
     },
     {
       id: TAB_FILES,
       label: t("#tabs.files", "Files"),
       css_class: "files",
       href: :course_files_path,
       icon: "icon-folder"
     },
     {
       id: TAB_SYLLABUS,
       label: t("#tabs.syllabus", "Syllabus"),
       css_class: "syllabus",
       href: :syllabus_course_assignments_path
     },
     {
       id: TAB_OUTCOMES,
       label: t("#tabs.outcomes", "Outcomes"),
       css_class: "outcomes",
       href: :course_outcomes_path
     },
     {
       id: TAB_RUBRICS,
       label: t("#tabs.rubrics", "Rubrics"),
       css_class: "rubrics",
       href: :course_rubrics_path,
       visibility: "admins"
     },
     {
       id: TAB_QUIZZES,
       label: t("#tabs.quizzes", "Quizzes"),
       css_class: "quizzes",
       href: :course_quizzes_path
     },
     {
       id: TAB_MODULES,
       label: t("#tabs.modules", "Modules"),
       css_class: "modules",
       href: :course_context_modules_path
     },
     {
       id: TAB_CONFERENCES,
       label: WebConference.conference_tab_name,
       css_class: "conferences",
       href: :course_conferences_path
     },
     {
       id: TAB_COLLABORATIONS,
       label: t("#tabs.collaborations", "Collaborations"),
       css_class: "collaborations",
       href: :course_collaborations_path
     },
     {
       id: TAB_COLLABORATIONS_NEW,
       label: t("#tabs.collaborations", "Collaborations"),
       css_class: "collaborations",
       href: :course_lti_collaborations_path
     },
     {
       id: TAB_SETTINGS,
       label: t("#tabs.settings", "Settings"),
       css_class: "settings",
       href: :course_settings_path,
     }]
  end

  def self.default_homeroom_tabs
    default_tabs = Course.default_tabs
    homeroom_tabs = [default_tabs.find { |tab| tab[:id] == TAB_ANNOUNCEMENTS }]
    syllabus_tab = default_tabs.find { |tab| tab[:id] == TAB_SYLLABUS }
    syllabus_tab[:label] = t("Important Info")
    homeroom_tabs << syllabus_tab
    homeroom_tabs << default_tabs.find { |tab| tab[:id] == TAB_PEOPLE }
    homeroom_tabs << default_tabs.find { |tab| tab[:id] == TAB_FILES }
    homeroom_tabs << default_tabs.find { |tab| tab[:id] == TAB_SETTINGS }
    homeroom_tabs.compact
  end

  def self.course_subject_tabs
    course_tabs = Course.default_tabs.select { |tab| COURSE_SUBJECT_TAB_IDS.include?(tab[:id]) }
    # Add the unique TAB_SCHEDULE and TAB_GROUPS
    course_tabs.insert(1,
                       {
                         id: TAB_SCHEDULE,
                         label: t("#tabs.schedule", "Schedule"),
                         css_class: "schedule",
                         href: :course_path
                       },
                       {
                         id: TAB_GROUPS,
                         label: t("#tabs.groups", "Groups"),
                         css_class: "groups",
                         href: :course_groups_path,
                       })
    course_tabs.sort_by { |tab| COURSE_SUBJECT_TAB_IDS.index tab[:id] }
  end

  def self.elementary_course_nav_tabs
    tabs = Course.default_tabs.reject { |tab| tab[:id] == TAB_HOME }
    tabs.find { |tab| tab[:id] == TAB_SYLLABUS }[:label] = t("Important Info")
    tabs
  end

  def tab_enabled?(tab)
    elementary_subject_course? || tab[:id] != TAB_HOME
  end

  def tab_hidden?(id)
    tab = tab_configuration.find { |t| t[:id] == id }
    tab && tab[:hidden]
  end

  def external_tool_tabs(opts, user)
    tools = Lti::ContextToolFinder.new(self, type: :course_navigation)
                                  .all_tools_scope_union.to_unsorted_array.select { |t| t.permission_given?(:course_navigation, user, self) && t.feature_flag_enabled?(self) }
    Lti::ExternalToolTab.new(self, :course_navigation, tools, opts[:language]).tabs
  end

  def tabs_available(user = nil, opts = {})
    opts.reverse_merge!(include_external: true, include_hidden_unused: true)
    cache_key = [user, self, opts].cache_key
    @tabs_available ||= {}
    @tabs_available[cache_key] ||= uncached_tabs_available(user, opts)
  end

  def uncached_tabs_available(user, opts)
    # make sure t() is called before we switch to the secondary, in case we update the user's selected locale in the process
    course_subject_tabs = elementary_subject_course? && opts[:course_subject_tabs]
    default_tabs = if elementary_homeroom_course?
                     Course.default_homeroom_tabs
                   elsif course_subject_tabs
                     Course.course_subject_tabs
                   elsif elementary_subject_course?
                     Course.elementary_course_nav_tabs
                   else
                     Course.default_tabs
                   end

    if SmartSearch.smart_search_available?(self)
      default_tabs.insert(1,
                          {
                            id: TAB_SEARCH,
                            label: t("#tabs.search", "Search"),
                            css_class: "search",
                            href: :course_search_path
                          })
    end

    if account.feature_enabled?(:course_paces) && enable_course_paces && grants_any_right?(user, :manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS)
      default_tabs.insert(default_tabs.index { |t| t[:id] == TAB_MODULES } + 1, {
                            id: TAB_COURSE_PACES,
                            label: t("#tabs.course_paces", "Course Pacing"),
                            css_class: "course_paces",
                            href: :course_course_pacing_path
                          })
    end

    opts[:include_external] = false if elementary_homeroom_course?

    GuardRail.activate(:secondary) do
      # We will by default show everything in default_tabs, unless the teacher has configured otherwise.
      tabs = (elementary_subject_course? && !course_subject_tabs) ? [] : tab_configuration.compact
      home_tab = default_tabs.find { |t| t[:id] == TAB_HOME }
      settings_tab = default_tabs.find { |t| t[:id] == TAB_SETTINGS }
      external_tabs = if opts[:include_external]
                        external_tool_tabs(opts, user) + Lti::MessageHandler.lti_apps_tabs(self, [Lti::ResourcePlacement::COURSE_NAVIGATION], opts)
                      else
                        []
                      end
      item_banks_tab = Lti::ResourcePlacement.update_tabs_and_return_item_banks_tab(external_tabs)

      tabs = tabs.map do |tab|
        default_tab = default_tabs.find { |t| t[:id] == tab[:id] } || external_tabs.find { |t| t[:id] == tab[:id] }
        next unless default_tab

        tab[:label] = default_tab[:label]
        tab[:href] = default_tab[:href]
        tab[:css_class] = default_tab[:css_class]
        tab[:args] = default_tab[:args]
        tab[:visibility] = default_tab[:visibility]
        tab[:external] = default_tab[:external]
        tab[:icon] = default_tab[:icon]
        tab[:target] = default_tab[:target] if default_tab[:target]
        default_tabs.delete_if { |t| t[:id] == tab[:id] }
        external_tabs.delete_if { |t| t[:id] == tab[:id] }
        tab
      end
      tabs.compact!

      if course_subject_tabs
        # If we didn't have a saved position for Schedule, insert it in the 2nd position
        schedule_tab = default_tabs.detect { |t| t[:id] == TAB_SCHEDULE }
        tabs.insert(1, default_tabs.delete(schedule_tab)) if schedule_tab && !tabs.empty?
      end
      tabs += default_tabs
      tabs += external_tabs

      tabs.delete_if { |t| t[:id] == TAB_SETTINGS }
      if course_subject_tabs
        # Don't show Settings, ensure that all external tools are at the bottom (with the exception of Groups, which
        # should stick to the end unless it has been re-ordered)
        lti_tabs = tabs.filter { |t| t[:external] }
        tabs -= lti_tabs
        groups_tab = tabs.pop if tabs.last&.dig(:id) == TAB_GROUPS && !opts[:for_reordering]
        tabs += lti_tabs
        tabs << groups_tab if groups_tab
      else
        # Ensure that Settings is always at the bottom
        tabs << settings_tab if settings_tab
        # Ensure that Home is always at the top
        tabs.delete_if { |t| t[:id] == TAB_HOME }
        tabs.unshift home_tab if home_tab
      end

      if opts[:only_check]
        tabs = tabs.select { |t| opts[:only_check].include?(t[:id]) }
      end

      check_for_permission = lambda do |*permissions|
        permissions.any? do |permission|
          if opts[:precalculated_permissions]&.key?(permission)
            opts[:precalculated_permissions][permission]
          else
            grants_right?(user, opts[:session], permission)
          end
        end
      end

      delete_unless = lambda do |tabs_to_check, *permissions|
        matched_tabs = tabs.select { |t| tabs_to_check.include?(t[:id]) }
        tabs -= matched_tabs if matched_tabs.present? && !check_for_permission.call(*permissions)
      end

      tabs_that_can_be_marked_hidden_unused = [
        { id: TAB_MODULES, relation: :modules },
        { id: TAB_FILES, relation: :files },
        { id: TAB_QUIZZES, relation: :quizzes },
        { id: TAB_ASSIGNMENTS, relation: :assignments },
        { id: TAB_ANNOUNCEMENTS, relation: :announcements },
        { id: TAB_OUTCOMES, relation: :outcomes },
        { id: TAB_PAGES, relation: :pages, additional_check: -> { allow_student_wiki_edits } },
        { id: TAB_CONFERENCES, relation: :conferences, additional_check: -> { check_for_permission.call(:create_conferences) } },
        { id: TAB_DISCUSSIONS, relation: :discussions, additional_check: -> { allow_student_discussion_topics } }
      ].select { |hidable_tab| tabs.any? { |t| t[:id] == hidable_tab[:id] } }

      if course_subject_tabs
        # Show modules tab in k5 even if there's no modules (but not if its hidden)
        tabs_that_can_be_marked_hidden_unused.reject! { |t| t[:id] == TAB_MODULES }

        # Hide Groups tab for students if there are no groups
        unless grants_right?(user, :read_as_admin) || active_groups.exists?
          tabs.delete_if { |t| t[:id] == TAB_GROUPS }
        end
      end

      if tabs_that_can_be_marked_hidden_unused.present?
        ar_types = active_record_types(only_check: tabs_that_can_be_marked_hidden_unused.pluck(:relation))
        tabs_that_can_be_marked_hidden_unused.each do |t|
          if !ar_types[t[:relation]] && (!t[:additional_check] || !t[:additional_check].call)
            # that means there are none of this type of thing in the DB
            if opts[:include_hidden_unused] || opts[:for_reordering] || opts[:api]
              tabs.detect { |tab| tab[:id] == t[:id] }[:hidden_unused] = true
            else
              tabs.delete_if { |tab| tab[:id] == t[:id] }
            end
          end
        end
      end

      # remove tabs that the user doesn't have access to
      unless opts[:for_reordering]
        delete_unless.call([TAB_HOME, TAB_ANNOUNCEMENTS, TAB_PAGES, TAB_OUTCOMES, TAB_CONFERENCES, TAB_COLLABORATIONS, TAB_MODULES], :read, :manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS)

        member_only_tabs = tabs.select { |t| t[:visibility] == "members" }
        tabs -= member_only_tabs if member_only_tabs.present? && !check_for_permission.call(:participate_as_student, :read_as_admin)

        delete_unless.call([TAB_ASSIGNMENTS, TAB_QUIZZES], :read, :manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS)
        delete_unless.call([TAB_SYLLABUS], :read, :read_syllabus, :manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS)

        admin_only_tabs = tabs.select { |t| t[:visibility] == "admins" }
        tabs -= admin_only_tabs if admin_only_tabs.present? && !check_for_permission.call(:read_as_admin)

        hidden_external_tabs = tabs.select do |t|
          next false unless t[:external]

          t[:hidden] || (elementary_subject_course? && !course_subject_tabs && tab_hidden?(t[:id]))
        end
        tabs -= hidden_external_tabs if hidden_external_tabs.present? && !(opts[:api] && check_for_permission.call(:read_as_admin))

        delete_unless.call([TAB_GRADES], :read_grades, :view_all_grades, :manage_grades)
        delete_unless.call([TAB_GROUPS], :read_roster)

        delete_unless.call([TAB_PEOPLE], :read_roster)
        delete_unless.call([TAB_DISCUSSIONS], :read_forum, :post_to_forum, :create_forum, :moderate_forum)
        delete_unless.call([TAB_SETTINGS], :read_as_admin)
        delete_unless.call([TAB_ANNOUNCEMENTS], :read_announcements)
        delete_unless.call([TAB_RUBRICS], :read_rubrics, :manage_rubrics)
        delete_unless.call([TAB_FILES], :read_files, *RoleOverride::GRANULAR_FILE_PERMISSIONS)

        if item_banks_tab &&
           !check_for_permission.call(:manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS)
          tabs.reject! { |tab| tab[:id] == item_banks_tab[:id] }
        end
        # remove outcomes tab for logged-out users or non-students
        outcome_tab = tabs.detect { |t| t[:id] == TAB_OUTCOMES }
        tabs.delete(outcome_tab) if outcome_tab && (!user || !check_for_permission.call(:manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS, :participate_as_student, :read_as_admin))

        # remove hidden tabs from students
        additional_checks = {
          TAB_ASSIGNMENTS => [:manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS],
          TAB_SYLLABUS => [:manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS],
          TAB_QUIZZES => [:manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS],
          TAB_GRADES => [:view_all_grades, :manage_grades],
          TAB_PEOPLE => [:manage_students, :manage_admin_users],
          TAB_FILES => RoleOverride::GRANULAR_FILE_PERMISSIONS,
          TAB_DISCUSSIONS => [:moderate_forum]
        }

        if root_account.feature_enabled?(:granular_permissions_manage_users)
          additional_checks[TAB_PEOPLE] = RoleOverride::GRANULAR_MANAGE_USER_PERMISSIONS
        end

        tabs.reject! do |t|
          # tab shouldn't be shown to non-admins
          (t[:hidden] || t[:hidden_unused]) &&
            # not an admin user
            (!user || !check_for_permission.call(:manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS, :read_as_admin)) &&
            # can't do any of the additional things required
            (!additional_checks[t[:id]] || !check_for_permission.call(*additional_checks[t[:id]]))
        end
      end

      tabs
    end
  end

  def allow_wiki_comments
    read_attribute(:allow_wiki_comments)
  end

  def account_name
    account.name rescue nil
  end

  def term_name
    self.enrollment_term.name rescue nil
  end

  def enable_user_notes
    root_account.enable_user_notes rescue false
  end

  def equella_settings
    account = self.account
    while account
      settings = account.equella_settings
      return settings if settings

      account = account.parent_account
    end
  end

  cattr_accessor :settings_options
  self.settings_options = {}

  def self.add_setting(setting, opts = {})
    setting = setting.to_sym
    settings_options[setting] = opts
    valid_keys = %i[boolean default inherited alias arbitrary]
    invalid_keys = opts.except(*valid_keys).keys
    raise "invalid options - #{invalid_keys.inspect} (must be in #{valid_keys.inspect})" if invalid_keys.any?

    cast_expression = "val.to_s.presence"
    cast_expression = "val" if opts[:arbitrary]
    if opts[:boolean]
      opts[:default] ||= false
      cast_expression = "Canvas::Plugin.value_to_boolean(val)"
    end
    class_eval <<~RUBY, __FILE__, __LINE__ + 1
      def #{setting}
        if Course.settings_options[#{setting.inspect}][:inherited]
          inherited = RequestCache.cache('inherited_course_setting', #{setting.inspect}, self.global_account_id) do
            self.account.send(#{setting.inspect})
          end
          if inherited[:locked] || settings_frd[#{setting.inspect}].nil?
            inherited[:value]
          else
            settings_frd[#{setting.inspect}]
          end
        elsif settings_frd[#{setting.inspect}].nil? && !@disable_setting_defaults
          default = Course.settings_options[#{setting.inspect}][:default]
          default.respond_to?(:call) ? default.call(self) : default
        else
          settings_frd[#{setting.inspect}]
        end
      end
      def #{setting}=(val)
        new_val = #{cast_expression}
        if settings_frd[#{setting.inspect}] != new_val
          @changed_settings ||= []
          @changed_settings << #{setting.inspect}
          if new_val.nil?
            settings_frd.delete(#{setting.inspect})
            nil
          else
            settings_frd[#{setting.inspect}] = new_val
          end
        end
      end
    RUBY
    alias_method :"#{setting}?", setting if opts[:boolean]
    if opts[:alias]
      alias_method opts[:alias], setting
      alias_method :"#{opts[:alias]}=", :"#{setting}="
      alias_method :"#{opts[:alias]}?", :"#{setting}?"
    end
  end

  include Csp::CourseHelper

  # unfortunately we decided to pluralize this in the API after the fact...
  # so now we pluralize it everywhere except the actual settings hash and
  # course import/export :(
  add_setting :hide_final_grade, alias: :hide_final_grades, boolean: true
  add_setting :hide_sections_on_course_users_page, boolean: true, default: false
  add_setting :hide_distribution_graphs, boolean: true
  add_setting :allow_final_grade_override, boolean: false, default: false
  add_setting :allow_student_discussion_topics, boolean: true, default: true
  add_setting :allow_student_discussion_editing, boolean: true, default: true
  add_setting :allow_student_forum_attachments, boolean: true, default: true
  add_setting :allow_student_discussion_reporting, boolean: true, default: true
  add_setting :allow_student_anonymous_discussion_topics, boolean: true, default: false
  add_setting :show_total_grade_as_points, boolean: true, default: false
  add_setting :filter_speed_grader_by_student_group, boolean: true, default: false
  add_setting :lock_all_announcements, boolean: true, default: false, inherited: true
  add_setting :large_roster, boolean: true, default: ->(c) { c.root_account.large_course_rosters? }
  add_setting :course_format
  add_setting :newquizzes_engine_selected
  add_setting :image_id
  add_setting :image_url
  add_setting :banner_image_id
  add_setting :banner_image_url
  add_setting :organize_epub_by_content_type, boolean: true, default: false
  add_setting :enable_offline_web_export, boolean: true, default: ->(c) { c.account.enable_offline_web_export? }
  add_setting :is_public_to_auth_users, boolean: true, default: false
  add_setting :overridden_course_visibility

  add_setting :restrict_quantitative_data, boolean: true, default: false
  add_setting :restrict_student_future_view, boolean: true, inherited: true
  add_setting :restrict_student_past_view, boolean: true, inherited: true

  add_setting :timetable_data, arbitrary: true
  add_setting :syllabus_master_template_id
  add_setting :syllabus_course_summary, boolean: true, default: true
  add_setting :syllabus_updated_at

  add_setting :enable_course_paces, boolean: true, default: false

  add_setting :usage_rights_required, boolean: true, default: false, inherited: true

  add_setting :course_color
  add_setting :alt_name

  add_setting :default_due_time, inherited: true
  add_setting :conditional_release, default: false, boolean: true, inherited: true

  def elementary_enabled?
    account.enable_as_k5_account?
  end

  def elementary_homeroom_course?
    homeroom_course? && elementary_enabled?
  end

  def elementary_subject_course?
    !homeroom_course? && elementary_enabled?
  end

  def restrict_quantitative_data_setting_changeable?
    feature_enabled = root_account.feature_enabled?(:restrict_quantitative_data)
    course_setting = restrict_quantitative_data
    account_setting = account.restrict_quantitative_data[:value]
    account_lock_state = account.restrict_quantitative_data[:locked]

    # If the feature flag is off, then the setting is not visible nor has any effect
    return false unless feature_enabled
    # If the RQD setting is on and not locked, courses can turn it on and off at will
    return true if account_setting && !account_lock_state
    # If the course setting is off but the account setting is on and locked, then the course setting can be turned on
    return true if !course_setting && account_setting && account_lock_state
    # If the course setting is on, but the account setting is off, then the course can turn it off, but not back on
    return true if course_setting && !account_setting

    # Otherwise the RQD setting can not be changed
    false
  end

  def restrict_quantitative_data?(user = nil, check_extra_permissions = false)
    return false unless user.is_a?(User)

    # When check_extra_permissions is true, return false for a teacher,ta, admin, or designer
    can_read_as_admin = if check_extra_permissions
                          grants_any_right?(
                            user,
                            :read_as_admin,
                            :manage_grades,
                            *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS,
                            :manage_content,
                            *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS
                          )
                        else
                          false
                        end
    is_account_admin = account.grants_right?(user, :manage)

    # never restrict quantitative data for admins
    root_account.feature_enabled?(:restrict_quantitative_data) && restrict_quantitative_data && !is_account_admin && !can_read_as_admin
  end

  def friendly_name
    elementary_enabled? ? alt_name.presence : nil
  end

  def friendly_name=(name)
    self.alt_name = name
  end

  def lock_all_announcements?
    !!lock_all_announcements || elementary_homeroom_course?
  end

  def self.sync_with_homeroom
    syncing_subjects.find_each(&:sync_with_homeroom)
  end

  def sync_with_homeroom
    sync_homeroom_participation
    sync_homeroom_enrollments
  end

  def can_sync_with_homeroom?
    elementary_subject_course? && sync_enrollments_from_homeroom && sis_batch_id.blank? && linked_homeroom_course.present? && linked_homeroom_course.elementary_homeroom_course? && !linked_homeroom_course.deleted?
  end

  def sync_homeroom_participation
    return unless can_sync_with_homeroom?

    if linked_homeroom_course.restrict_enrollments_to_course_dates
      self.restrict_enrollments_to_course_dates = true
      self.start_at = linked_homeroom_course.start_at
      self.conclude_at = linked_homeroom_course.conclude_at
    else
      self.restrict_enrollments_to_course_dates = false
      self.enrollment_term = linked_homeroom_course.enrollment_term
    end
    save!
  end

  def sync_homeroom_enrollments(progress = nil)
    return false unless can_sync_with_homeroom?

    progress&.calculate_completion!(0, linked_homeroom_course.enrollments.size)
    linked_homeroom_course.all_enrollments.find_each do |enrollment|
      shard.activate do
        course_enrollment = if shard == enrollment.shard
                              all_enrollments.find_or_initialize_by(type: enrollment.type, user_id: enrollment.user_id, role_id: enrollment.role_id, associated_user_id: enrollment.associated_user_id)
                            else
                              # roles don't apply across shards, so fall back to the base type
                              all_enrollments.find_or_initialize_by(type: enrollment.type, user_id: enrollment.user_id, associated_user_id: enrollment.associated_user_id)
                            end
        course_enrollment.workflow_state = enrollment.workflow_state
        course_enrollment.start_at = enrollment.start_at
        course_enrollment.end_at = enrollment.end_at
        course_enrollment.completed_at = enrollment.completed_at
        course_enrollment.save!
        progress.increment_completion!(1) if progress&.total
      end
    end
  end

  def user_can_manage_own_discussion_posts?(user)
    return true if allow_student_discussion_editing?
    return true if user_is_instructor?(user)

    false
  end

  def filter_attributes_for_user(hash, user, _session)
    hash.delete("hide_final_grades") if hash.key?("hide_final_grades") && !grants_right?(user, :update)
    hash
  end

  # DEPRECATED, use setting accessors instead
  def settings=(hash)
    write_attribute(:settings, hash)
  end

  # frozen, because you should use setters
  def settings
    settings_frd.dup.freeze
  end

  def settings_frd
    read_or_initialize_attribute(:settings, {})
  end

  def disable_setting_defaults
    @disable_setting_defaults = true
    yield
  ensure
    @disable_setting_defaults = nil
  end

  def reset_content
    shard.activate do
      Course.transaction do
        new_course = Course.new
        keys_to_copy = Course.column_names - %i[
          id
          created_at
          updated_at
          syllabus_body
          wiki_id
          default_view
          tab_configuration
          lti_context_id
          workflow_state
          latest_outcome_import_id
          grading_standard_id
        ].map(&:to_s)
        attributes.each do |key, val|
          new_course.write_attribute(key, val) if keys_to_copy.include?(key)
        end
        new_course.workflow_state = (admins.any? ? "claimed" : "created")
        # there's a unique constraint on this, so we need to clear it out
        self.self_enrollment_code = nil
        self.self_enrollment = false
        # The order here is important; we have to set our sis id to nil and save first
        # so that the new course can be saved, then we need the new course saved to
        # get its id to move over sections and enrollments.  Setting this course to
        # deleted has to be last otherwise it would set all the enrollments to
        # deleted before they got moved
        self.uuid = self.sis_source_id = self.sis_batch_id = self.integration_id = nil
        save!
        Course.process_as_sis { new_course.save! }
        course_sections.update_all(course_id: new_course.id)
        # we also want to bring along prior enrollments, so don't use the enrollments
        # association
        Enrollment.where(course_id: self).in_batches(of: 10_000).update_all(course_id: new_course.id, updated_at: Time.now.utc)
        user_ids = new_course.all_enrollments.pluck(:user_id)
        self.class.connection.after_transaction_commit do
          User.touch_and_clear_cache_keys(user_ids, :enrollments)
        end
        Shard.partition_by_shard(user_ids) do |sharded_user_ids|
          Favorite.where(user_id: sharded_user_ids, context_type: "Course", context_id: id)
                  .in_batches(of: 10_000).update_all(context_id: new_course.id, updated_at: Time.now.utc)
        end

        self.replacement_course_id = new_course.id
        self.workflow_state = "deleted"
        Course.suspend_callbacks(:copy_from_course_template) do
          save!
        end

        unless profile.new_record?
          profile.update_attribute(:context, new_course)
        end

        Course.find(new_course.id)
      end
    end
  end

  def user_list_search_mode_for(user)
    if root_account.open_registration?
      return root_account.delegated_authentication? ? :preferred : :open
    end
    return :preferred if root_account.grants_right?(user, :manage_user_logins)

    :closed
  end

  def default_home_page
    "modules"
  end

  def participating_users(user_ids)
    User.where(id: enrollments.active_by_date.where(user_id: user_ids).select(:user_id))
  end

  def student_view_student
    fake_student = find_or_create_student_view_student
    sync_enrollments(fake_student)
  end

  # part of the way we isolate this fake student from places we don't want it
  # to appear is to ensure that it does not have a pseudonym or any
  # account_associations. if either of these conditions is false, something is
  # wrong.
  def find_or_create_student_view_student
    if student_view_students.active.count == 0
      fake_student = nil
      User.skip_updating_account_associations do
        fake_student = User.new(name: t("student_view_student_name", "Test Student"))
        fake_student.preferences[:fake_student] = true
        fake_student.workflow_state = "registered"
        fake_student.shard = shard
        fake_student.save
        # hash the unique_id so that it's hard to accidently enroll the user in
        # a course by entering something in a user list. :(
        fake_student.pseudonyms.create!(account: root_account,
                                        unique_id: Canvas::Security.hmac_sha1("Test Student_#{fake_student.id}"))
      end
      fake_student
    else
      student_view_students.active.first
    end
  end
  private :find_or_create_student_view_student

  # we want to make sure the student view student is always enrolled in all the
  # sections of the course, so that a section limited teacher can grade them.
  def sync_enrollments(fake_student)
    default_section unless course_sections.active.any?
    Enrollment.suspend_callbacks(:set_update_cached_due_dates) do
      course_sections.active.each do |section|
        # enroll fake_student will only create the enrollment if it doesn't already exist
        enroll_user(fake_student,
                    "StudentViewEnrollment",
                    allow_multiple_enrollments: true,
                    section:,
                    enrollment_state: "active",
                    no_notify: true,
                    skip_touch_user: true)
      end
    end
    SubmissionLifecycleManager.recompute_users_for_course(fake_student.id, self)
    fake_student.update_root_account_ids
    fake_student
  end
  private :sync_enrollments

  def associated_shards
    [Shard.default]
  end

  def includes_student?(user)
    includes_user?(user, student_enrollments)
  end

  def includes_user?(user, enrollment_scope = enrollments)
    return false if user.nil? || user.new_record?

    enrollment_scope.where(user_id: user).exists?
  end

  def update_one(update_params, user, update_source = :manual)
    options = { source: update_source }

    case update_params[:event]
    when "offer"
      if completed?
        unconclude!
        Auditors::Course.record_unconcluded(self, user, options)
      else
        unless available?
          offer!
          Auditors::Course.record_published(self, user, options)
        end
      end
    when "conclude"
      unless completed?
        complete!
        Auditors::Course.record_concluded(self, user, options)
      end
    when "delete"
      self.sis_source_id = nil
      self.workflow_state = "deleted"
      save!
      Auditors::Course.record_deleted(self, user, options)
    when "undelete"
      self.workflow_state = "claimed"
      save!
      Auditors::Course.record_restored(self, user, options)
    end
  end

  def self.do_batch_update(progress, user, course_ids, update_params, update_source = :manual)
    account = progress.context
    progress_runner = ProgressRunner.new(progress)

    progress_runner.completed_message do |completed_count|
      t("batch_update_message",
        {
          one: "1 course processed",
          other: "%{count} courses processed"
        },
        count: completed_count)
    end

    progress_runner.do_batch_update(course_ids) do |course_id|
      course = account.associated_courses.where(id: course_id).first
      raise t("course_not_found", "The course was not found") unless course &&
                                                                     (course.workflow_state != "deleted" || update_params[:event] == "undelete")
      raise t("access_denied", "Access was denied") unless course.grants_right? user, :update

      course.update_one(update_params, user, update_source)
    end
  end

  def self.batch_update(account, user, course_ids, update_params, update_source = :manual)
    progress = account.progresses.create! tag: "course_batch_update", completion: 0.0
    job = Course.delay(ignore_transaction: true)
                .do_batch_update(progress, user, course_ids, update_params, update_source)
    progress.user_id = user.id
    progress.delayed_job_id = job.id
    progress.save!
    progress
  end

  def re_send_invitations!(from_user)
    apply_enrollment_visibility(student_enrollments, from_user).invited.except(:preload).preload(user: :communication_channels).find_each do |e|
      e.re_send_confirmation! if e.invited?
    end
  end

  def serialize_permissions(permissions_hash, user, session)
    permissions_hash.merge(
      create_discussion_topic: DiscussionTopic.context_allows_user_to_create?(self, user, session),
      create_announcement: Announcement.context_allows_user_to_create?(self, user, session)
    )
  end

  def active_section_count
    @section_count ||= active_course_sections.count
  end

  def multiple_sections?
    active_section_count > 1
  end

  def content_exports_visible_to(user)
    if grants_right?(user, :read_as_admin)
      content_exports.admin(user)
    else
      content_exports.non_admin(user)
    end
  end

  %w[student_count teacher_count primary_enrollment_type primary_enrollment_role_id primary_enrollment_rank primary_enrollment_state primary_enrollment_date invitation].each do |method|
    class_eval <<~RUBY, __FILE__, __LINE__ + 1
      def #{method}
        read_attribute(:#{method}) || @#{method}
      end
    RUBY
  end

  # only send one
  def touch_content_if_public_visibility_changed(changes = {}, **kwargs)
    # RUBY 2.7 this can go away (**{} will work at the caller)
    raise ArgumentError, "Only send one hash" if !changes.empty? && !kwargs.empty?

    changes = kwargs if changes.empty? && !kwargs.empty?

    if changes[:is_public] || changes[:is_public_to_auth_users]
      assignments.touch_all
      attachments.touch_all
      calendar_events.touch_all
      context_modules.touch_all
      discussion_topics.touch_all
      quizzes.touch_all
      wiki.touch
      wiki_pages.touch_all
    end
  end

  def clear_todo_list_cache_later(association_type)
    raise "invalid association" unless association(association_type).klass == User

    delay(run_at: 15.seconds.from_now, singleton: "course_clear_cache_#{global_id}_#{association_type}", on_conflict: :loose)
      .clear_todo_list_cache(association_type)
  end

  def clear_todo_list_cache(association_type)
    raise "invalid association" unless association(association_type).klass == User

    send(association_type).clear_cache_keys(:todo_list)
  end

  def touch_admins # TODO: remove after existing jobs run
    clear_todo_list_cache(:admins)
  end

  def clear_caches_if_necessary
    clear_cache_key(:account_associations) if saved_change_to_root_account_id? || saved_change_to_account_id?
  end

  def refresh_content_participation_counts(_progress)
    user_ids = content_participation_counts.pluck(:user_id)
    User.clear_cache_keys(user_ids, :potential_unread_submission_ids)
    content_participation_counts.each(&:refresh_unread_count)
  end

  def refresh_content_participation_counts_for_users(user_ids)
    content_participation_counts.where(user: user_ids).find_each(&:refresh_unread_count)
  end

  attr_accessor :preloaded_nickname, :preloaded_favorite

  def favorite_for_user?(user)
    return @preloaded_favorite if defined?(@preloaded_favorite)

    user.favorites.where(context_type: "Course", context_id: self).exists?
  end

  def preloaded_nickname?
    !!defined?(@preloaded_nickname)
  end

  def nickname_for(user, fallback = :name, prefer_friendly_name: true)
    return friendly_name if prefer_friendly_name && friendly_name.present?

    nickname = preloaded_nickname? ? @preloaded_nickname : user&.course_nickname(self)
    nickname ||= send(fallback) if fallback
    nickname
  end

  def name
    return @nickname if @nickname

    read_attribute(:name)
  end

  def apply_nickname_for!(user)
    @nickname = user && nickname_for(user, nil)
  end

  def self.preload_menu_data_for(courses, user, preload_favorites: false)
    ActiveRecord::Associations.preload(courses, :enrollment_term)
    # preload favorites and nicknames
    favorite_ids = preload_favorites && user.favorite_context_ids("Course")
    nicknames = user.all_course_nicknames(courses)
    courses.each do |course|
      course.preloaded_favorite = favorite_ids.include?(course.id) if favorite_ids
      # keys in nicknames are relative to the user's shard
      course.preloaded_nickname = nicknames[Shard.relative_id_for(course.id, course.shard, user.shard)]
    end
  end

  def any_assignment_in_closed_grading_period?
    effective_due_dates.any_in_closed_grading_period?
  end

  def relevant_grading_period_group
    return @relevant_grading_period_group if defined?(@relevant_grading_period_group)

    @relevant_grading_period_group = grading_period_groups.detect { |gpg| gpg.workflow_state == "active" }
    return @relevant_grading_period_group unless @relevant_grading_period_group.nil?

    if enrollment_term.grading_period_group&.workflow_state == "active"
      @relevant_grading_period_group = enrollment_term.grading_period_group
    end
  end

  # Does this course have grading periods?
  # checks for both legacy and account-level grading period groups
  def grading_periods?
    return @has_grading_periods unless @has_grading_periods.nil?
    return @has_grading_periods = true if @has_weighted_grading_periods

    @has_grading_periods = relevant_grading_period_group.present?
  end

  def display_totals_for_all_grading_periods?
    return @display_totals_for_all_grading_periods if defined?(@display_totals_for_all_grading_periods)

    @display_totals_for_all_grading_periods = !!relevant_grading_period_group&.display_totals_for_all_grading_periods?
  end

  def weighted_grading_periods?
    return @has_weighted_grading_periods unless @has_weighted_grading_periods.nil?
    return @has_weighted_grading_periods = false if @has_grading_periods == false

    @has_weighted_grading_periods = grading_period_groups.to_a.none? { |gpg| gpg.workflow_state == "active" } &&
                                    !!relevant_grading_period_group&.weighted?
  end

  def quiz_lti_tool
    context_external_tools.active.quiz_lti.first ||
      account.context_external_tools.active.quiz_lti.first ||
      root_account.context_external_tools.active.quiz_lti.first
  end

  def has_new_quizzes?
    assignments.active.quiz_lti.exists?
  end

  def find_or_create_progressions_for_user(user)
    @progressions ||= {}
    @progressions[user.id] ||= ContextModuleProgressions::Finder.find_or_create_for_context_and_user(self, user)
  end

  def show_total_grade_as_points?
    !!settings[:show_total_grade_as_points] &&
      group_weighting_scheme != "percent" &&
      !relevant_grading_period_group&.weighted?
  end

  # This method will be around while we still have two
  # gradebooks. This method should be used in situations where we want
  # to identify the user can't move backwards, such as feature flags
  def gradebook_backwards_incompatible_features_enabled?
    # The old gradebook can't deal with late policies at all
    return true if late_policy&.missing_submission_deduction_enabled? ||
                   late_policy&.late_submission_deduction_enabled? ||
                   feature_enabled?(:final_grades_override)

    # If you've used the grade tray status changes at all, you can't
    # go back. Even if set to none, it'll break "Message Students
    # Who..." for unsubmitted.
    expire_time = Setting.get("late_policy_tainted_submissions", 1.hour).to_i
    Rails.cache.fetch(["late_policy_tainted_submissions", self].cache_key, expires_in: expire_time) do
      submissions.except(:order).where(late_policy_status: %w[missing late extended none]).exists?
    end
  end

  def grading_standard_or_default
    default_grading_standard || GradingStandard.default_instance
  end

  def allow_final_grade_override?
    feature_enabled?(:final_grades_override) && allow_final_grade_override == "true"
  end

  def filter_speed_grader_by_student_group?
    return false unless root_account.feature_enabled?(:filter_speed_grader_by_student_group)

    filter_speed_grader_by_student_group
  end

  def moderators
    participating_instructors.distinct.select { |user| grants_right?(user, :select_final_grade) }
  end

  def moderated_grading_max_grader_count
    count = participating_instructors.distinct.count
    # A moderated assignment must have at least 1 (non-moderator) grader.
    return 1 if count < 2
    # grader count cannot exceed the hard limit
    return MODERATED_GRADING_GRADER_LIMIT if count > MODERATED_GRADING_GRADER_LIMIT + 1

    # for any given assignment: 1 assigned moderator + N max graders = all participating instructors
    # so N max graders = all participating instructors - 1 assigned moderator
    count - 1
  end

  def post_manually?
    return false unless post_policies_enabled?

    default_post_policy.present? && default_post_policy.post_manually?
  end

  def apply_post_policy!(post_manually:)
    return unless PostPolicy.feature_enabled?

    course_policy = PostPolicy.find_or_create_by(course: self, assignment_id: nil)
    course_policy.update!(post_manually:) unless course_policy.post_manually == post_manually

    matching_post_policies_scope = PostPolicy
                                   .where("assignment_id = #{Assignment.quoted_table_name}.id")
                                   .where(post_manually:)

    assignments.active
               .where(anonymous_grading: false, moderated_grading: false)
               .where.not(matching_post_policies_scope.arel.exists)
               .preload(:post_policy)
               .each do |assignment|
      assignment.ensure_post_policy(post_manually:)
    end
  end

  CUSTOMIZABLE_PERMISSIONS.each do |key, cfg|
    if cfg[:as_bools]
      add_setting :"public_#{key}", boolean: true, default: ->(c) { c.is_public || false }
      add_setting :"public_#{key}_to_auth", boolean: true, default: ->(c) { c.is_public_to_auth_users || false }
    else
      add_setting :"#{key}_visibility", default: ->(c) { c.course_visibility }
    end
  end

  def apply_overridden_course_visibility(visibility)
    self.overridden_course_visibility = if !%w[institution public course].include?(visibility) &&
                                           root_account.available_course_visibility_override_options.key?(visibility)
                                          visibility
                                        else
                                          nil
                                        end
  end

  def apply_visibility_configuration(course_visibility)
    apply_overridden_course_visibility(course_visibility)
    case course_visibility
    when "institution"
      self.is_public_to_auth_users = true
      self.is_public = false
    when "public"
      self.is_public = true
    else
      self.is_public_to_auth_users = false
      self.is_public = false
    end
  end

  def apply_custom_visibility_configuration(key, visibility)
    return unless visibility.present?

    perm_cfg = CUSTOMIZABLE_PERMISSIONS[key.to_s]

    if visibility.to_s == "inherit"
      if perm_cfg[:as_bools]
        settings_frd.delete(:"public_#{key}")
        settings_frd.delete(:"public_#{key}_to_auth")
      else
        settings_frd.delete(:"#{key}_visibility")
      end
    else
      flex = perm_cfg[:flex]
      allow_tighter = [:tighter, :any].include?(flex)
      allow_looser = [:looser, :any, nil].include?(flex)

      visibility_levels = course_visibility_options.keys
      course_level = visibility_levels.index(course_visibility)
      key_level = visibility_levels.index(visibility)

      if (!allow_tighter && key_level < course_level) || (!allow_looser && key_level > course_level)
        visibility = visibility_levels[course_level]
      end

      if perm_cfg[:as_bools]
        send(:"public_#{key}=", visibility == "public")
        send(:"public_#{key}_to_auth=", visibility == "institution")
      else
        send(:"#{key}_visibility=", visibility)
      end
    end
  end

  def post_policies_enabled?
    PostPolicy.feature_enabled?
  end

  def sections_hidden_on_roster_page?(current_user:)
    course_sections.active.many? &&
      hide_sections_on_course_users_page? &&
      !current_user.enrollments.active.where(course: self).empty? &&
      current_user.enrollments.active.where(course: self).all?(&:student?)
  end

  def resolved_outcome_proficiency
    outcome_proficiency&.active? ? outcome_proficiency : account&.resolved_outcome_proficiency
  end

  def resolved_outcome_calculation_method
    outcome_calculation_method&.active? ? outcome_calculation_method : account&.resolved_outcome_calculation_method
  end

  def can_become_template?
    !enrollments.active.exists?
  end

  def can_stop_being_template?
    !templated_accounts.exists?
  end

  def batch_update_context_modules(progress = nil, event:, module_ids:, skip_content_tags: false)
    completed_ids = []
    modules = context_modules.not_deleted.where(id: module_ids)
    progress&.calculate_completion!(0, modules.size)
    modules.each do |context_module|
      # Break out of the loop if the progress has been canceled
      break if progress&.reload&.failed?

      case event.to_s
      when "publish"
        context_module.publish unless context_module.active?
        unless skip_content_tags
          context_module.publish_items!(progress:)
        end
      when "unpublish"
        context_module.unpublish unless context_module.unpublished?
        unless skip_content_tags
          context_module.unpublish_items!(progress:)
        end
      when "delete"
        context_module.destroy
      end
      progress&.increment_completion!(1) if progress&.total
      completed_ids << context_module.id
    end
    completed_ids
  end

  # fix for appointment_participants using asset_string as primary key, even though it's
  # not a real column
  def _read_attribute(attr_name)
    return asset_string if attr_name == "asset_string"

    super
  end

  private

  def effective_due_dates
    @effective_due_dates ||= EffectiveDueDates.for_course(self)
  end

  def set_default_post_policy
    return if default_post_policy.present?

    create_default_post_policy(assignment: nil, post_manually: false)
  end

  def canvas_k6_tab_configuration
    visible, hidden = Course.default_tabs.partition { |tab| CANVAS_K6_TAB_IDS.include?(tab[:id]) }
    [*visible, *hidden.tap { |tabs| tabs.each { |t| t[:hidden] = true } }]
  end

  def copy_from_course_template
    if root_account.feature_enabled?(:course_templates) &&
       (template = account.effective_course_template)
      content_migration = content_migrations.new(
        source_course: template,
        migration_type: "course_copy_importer",
        initiated_source: :course_template
      )
      content_migration.migration_settings[:source_course_id] = template.id

      content_migration.migration_settings[:import_immediately] = true
      content_migration.copy_options = { everything: true }
      content_migration.migration_settings[:migration_ids_to_import] = { copy: { everything: true } }
      content_migration.workflow_state = "importing"
      priority = Delayed::LOW_PRIORITY
      if saved_by == :sis_import
        priority += 5
        content_migration.strand = "sis_import_course_templates"
      end
      content_migration.save!
      content_migration.queue_migration(priority:)
    end
  end

  def set_restrict_quantitative_data_when_needed
    if root_account.feature_enabled?(:restrict_quantitative_data) &&
       account.restrict_quantitative_data[:value] == true &&
       account.restrict_quantitative_data[:locked] == true
      self.restrict_quantitative_data = true
      save!
    end
  end

  def log_create_to_publish_time
    return unless publishing?

    publish_time = ((updated_at - created_at) * 1000).round
    statsd_bucket = (account.feature_enabled?(:course_paces) && enable_course_paces?) ? "paced" : "unpaced"
    InstStatsd::Statsd.timing("course.#{statsd_bucket}.create_to_publish_time", publish_time)
  end

  def log_published_assignment_count
    return unless publishing?

    statsd_bucket = enable_course_paces? ? "paced" : "unpaced"
    InstStatsd::Statsd.count("course.#{statsd_bucket}.assignment_count", assignments.published.size)
  end

  def publishing?
    valid_workflow_states = %w[created claimed]
    available? && valid_workflow_states.include?(workflow_state_before_last_save)
  end

  def log_course_pacing_publish_update
    if publishing?
      statsd_bucket = enable_course_paces? ? "paced" : "unpaced"
      InstStatsd::Statsd.increment("course.#{statsd_bucket}.paced_courses")
    end
  end

  def log_course_format_publish_update
    if publishing?
      statsd_bucket = enable_course_paces? ? "paced" : "unpaced"
      course_format_value = course_format.nil? ? "unset" : course_format
      InstStatsd::Statsd.increment("course.#{statsd_bucket}.#{course_format_value}")
    end
  end

  def change_to_logged_settings?
    return false unless saved_change_to_settings? && available? && !publishing?

    @enable_paces_change = change_to_enable_paces?
    @course_format_change = changes_to_course_format?

    @enable_paces_change || @course_format_change
  end

  def change_to_enable_paces?
    # Get the settings changes into a parameter
    setting_changes = saved_changes[:settings]
    old_enable_paces_setting = setting_changes[0][:enable_course_paces]
    new_enable_paces_setting = setting_changes[1][:enable_course_paces]

    # Check to see if enable_course_paces is in list of updated items
    return false if new_enable_paces_setting.nil?

    # If enable_course_paces IS in the list, then check to see if the original value is present or if it's nil
    # It can be nil when a course is initially created and published without other settings present.
    # In this case, then, it's going from nil to a value we care about one way or the other.
    if old_enable_paces_setting.nil?
      return true
    end

    # Finally this is the case where the list of settings may include enable_course_paces, but it didn't change --
    # another setting changed.
    old_enable_paces_setting != new_enable_paces_setting
  end

  def changes_to_course_format?
    # Get the settings changes into a parameter
    setting_changes = saved_changes[:settings]
    old_course_format_setting = setting_changes[0][:course_format]
    new_course_format_setting = setting_changes[1][:course_format]

    old_course_format_setting != new_course_format_setting
  end

  def log_course_pacing_settings_update
    if @enable_paces_change
      log_enable_pacing_update
    end

    if @course_format_change
      log_course_format_update
    end
  end

  def log_enable_pacing_update
    setting_changes = saved_changes[:settings]
    new_enable_paces_setting = setting_changes[1][:enable_course_paces]

    statsd_bucket = new_enable_paces_setting ? "paced" : "unpaced"

    InstStatsd::Statsd.increment("course.#{statsd_bucket}.paced_courses")

    log_course_format_update unless @course_format_change
  end

  def log_course_format_update
    setting_changes = saved_changes[:settings]
    new_enable_paces_setting = setting_changes[1][:enable_course_paces]

    new_stats_course_format = setting_changes[1][:course_format].nil? ? "unset" : setting_changes[1][:course_format]

    statsd_bucket = new_enable_paces_setting ? "paced" : "unpaced"
    InstStatsd::Statsd.increment("course.#{statsd_bucket}.#{new_stats_course_format}")
  end

  def log_rqd_setting_enable_or_disable
    return unless saved_changes.key?("settings") # Skip if no settings were changed

    setting_changes = saved_changes[:settings]
    old_rqd_setting = setting_changes[0].fetch(:restrict_quantitative_data, false)
    new_rqd_setting = setting_changes[1].fetch(:restrict_quantitative_data, false)

    return unless old_rqd_setting != new_rqd_setting # Skip if RQD setting was not changed

    if old_rqd_setting == false && new_rqd_setting == true
      InstStatsd::Statsd.increment("course.settings.restrict_quantitative_data.enabled")
    elsif old_rqd_setting == true && new_rqd_setting == false
      InstStatsd::Statsd.increment("course.settings.restrict_quantitative_data.disabled")
    end
  end
end
