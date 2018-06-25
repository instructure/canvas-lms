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
require 'csv'

class Course < ActiveRecord::Base
  include Context
  include Workflow
  include TextHelper
  include HtmlTextHelper
  include TimeZoneHelper
  include ContentLicenses
  include TurnitinID
  include Courses::ItemVisibilityHelper
  include OutcomeImportContext

  attr_accessor :teacher_names, :master_course
  attr_writer :student_count, :primary_enrollment_type, :primary_enrollment_role_id, :primary_enrollment_rank, :primary_enrollment_state, :primary_enrollment_date, :invitation, :updating_master_template_id

  time_zone_attribute :time_zone
  def time_zone
    if read_attribute(:time_zone)
      super
    else
      RequestCache.cache("account_time_zone", self.root_account_id) do
        root_account.default_time_zone
      end
    end
  end

  serialize :tab_configuration
  serialize :settings, Hash
  belongs_to :root_account, :class_name => 'Account'
  belongs_to :abstract_course
  belongs_to :enrollment_term
  belongs_to :grading_standard
  belongs_to :template_course, :class_name => 'Course'
  has_many :templated_courses, :class_name => 'Course', :foreign_key => 'template_course_id'

  has_many :course_sections
  has_many :active_course_sections, -> { where(workflow_state: 'active') }, class_name: 'CourseSection'
  has_many :enrollments, -> { where("enrollments.workflow_state<>'deleted'") }, inverse_of: :course

  has_many :all_enrollments, :class_name => 'Enrollment'
  has_many :current_enrollments, -> { where("enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted', 'inactive')").preload(:user) }, class_name: 'Enrollment'
  has_many :all_current_enrollments, -> { where("enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted')").preload(:user) }, class_name: 'Enrollment'
  has_many :prior_enrollments, -> { preload(:user, :course).where(workflow_state: 'completed') }, class_name: 'Enrollment'
  has_many :prior_users, :through => :prior_enrollments, :source => :user
  has_many :prior_students, -> { where(enrollments: { type: ['StudentEnrollment', 'StudentViewEnrollment'], workflow_state: 'completed' }) }, through: :enrollments, source: :user

  has_many :participating_students, -> { where(enrollments: { type: ['StudentEnrollment', 'StudentViewEnrollment'], workflow_state: 'active' }) }, through: :enrollments, source: :user
  has_many :participating_students_by_date, -> { where(enrollments: { type: ['StudentEnrollment', 'StudentViewEnrollment'], workflow_state: 'active' }).
    joins("INNER JOIN #{EnrollmentState.quoted_table_name} ON enrollment_states.enrollment_id=enrollments.id").
    where(:enrollment_states => {:state => 'active'})}, through: :all_enrollments, source: :user

  has_many :student_enrollments, -> { where("enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted', 'inactive') AND enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment')").preload(:user) }, class_name: 'Enrollment'
  has_many :students, :through => :student_enrollments, :source => :user
  has_many :self_enrolled_students, -> { where("self_enrolled") }, through: :student_enrollments, source: :user
  has_many :admin_visible_student_enrollments, -> { where("enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted') AND enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment')").preload(:user) }, class_name: 'Enrollment'
  has_many :admin_visible_students, :through => :admin_visible_student_enrollments, :source => :user
  has_many :gradable_student_enrollments, -> { where(enrollments: { workflow_state: ['active', 'inactive'], type: ['StudentEnrollment', 'StudentViewEnrollment'] }).preload(:user) }, class_name: 'Enrollment'
  has_many :gradable_students, through: :gradable_student_enrollments, source: :user
  has_many :all_student_enrollments, -> { where("enrollments.workflow_state<>'deleted' AND enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment')").preload(:user) }, class_name: 'Enrollment'
  has_many :all_student_enrollments_including_deleted, -> { where("enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment')").preload(:user) }, class_name: 'Enrollment'
  has_many :all_students, :through => :all_student_enrollments, :source => :user
  has_many :all_students_including_deleted, :through => :all_student_enrollments_including_deleted, source: :user
  has_many :all_accepted_student_enrollments, -> { where("enrollments.workflow_state NOT IN ('rejected', 'deleted') AND enrollments.type IN ('StudentEnrollment', 'StudentViewEnrollment')").preload(:user) }, class_name: 'Enrollment'
  has_many :all_accepted_students, -> { distinct }, :through => :all_accepted_student_enrollments, :source => :user
  has_many :all_real_enrollments, -> { where("enrollments.workflow_state<>'deleted' AND enrollments.type<>'StudentViewEnrollment'").preload(:user) }, class_name: 'Enrollment'
  has_many :all_real_users, :through => :all_real_enrollments, :source => :user
  has_many :all_real_student_enrollments, -> { where("enrollments.type = 'StudentEnrollment' AND enrollments.workflow_state <> 'deleted'").preload(:user) }, class_name: 'StudentEnrollment'
  has_many :all_real_students, :through => :all_real_student_enrollments, :source => :user
  has_many :teacher_enrollments, -> { where("enrollments.workflow_state <> 'deleted' AND enrollments.type = 'TeacherEnrollment'").preload(:user) }, class_name: 'TeacherEnrollment'
  has_many :teachers, -> { order("sortable_name") }, :through => :teacher_enrollments, :source => :user
  has_many :ta_enrollments, -> { where("enrollments.workflow_state<>'deleted'").preload(:user) }, class_name: 'TaEnrollment'
  has_many :tas, :through => :ta_enrollments, :source => :user
  has_many :observer_enrollments, -> { where("enrollments.workflow_state<>'deleted'").preload(:user) }, class_name: 'ObserverEnrollment'
  has_many :observers, :through => :observer_enrollments, :source => :user
  has_many :participating_observers, -> { where(enrollments: { workflow_state: 'active' }) }, through: :observer_enrollments, source: :user
  has_many :participating_observers_by_date, -> { where(enrollments: { type: 'ObserverEnrollment', workflow_state: 'active' }).
    joins("INNER JOIN #{EnrollmentState.quoted_table_name} ON enrollment_states.enrollment_id=enrollments.id").
    where(:enrollment_states => {:state => 'active'})}, through: :all_enrollments, source: :user

  has_many :instructors, -> { where(enrollments: { type: ['TaEnrollment', 'TeacherEnrollment'] }) }, through: :enrollments, source: :user
  has_many :instructor_enrollments, -> { where(type: ['TaEnrollment', 'TeacherEnrollment']) }, class_name: 'Enrollment'
  has_many :participating_instructors, -> { where(enrollments: { type: ['TaEnrollment', 'TeacherEnrollment'], workflow_state: 'active' }) }, through: :enrollments, source: :user
  has_many :participating_instructors_by_date, -> { where(enrollments: { type: ['TaEnrollment', 'TeacherEnrollment'], workflow_state: 'active' }).
    joins("INNER JOIN #{EnrollmentState.quoted_table_name} ON enrollment_states.enrollment_id=enrollments.id").
    where(:enrollment_states => {:state => 'active'})}, through: :all_enrollments, source: :user

  has_many :admins, -> { where(enrollments: { type: ['TaEnrollment', 'TeacherEnrollment', 'DesignerEnrollment'] }) }, through: :enrollments, source: :user
  has_many :admin_enrollments, -> { where(type: ['TaEnrollment', 'TeacherEnrollment', 'DesignerEnrollment']) }, class_name: 'Enrollment'
  has_many :participating_admins, -> { where(enrollments: { type: ['TaEnrollment', 'TeacherEnrollment', 'DesignerEnrollment'], workflow_state: 'active' }) }, through: :enrollments, source: :user
  has_many :participating_admins_by_date, -> { where(enrollments: { type: ['TaEnrollment', 'TeacherEnrollment', 'DesignerEnrollment'], workflow_state: 'active' }).
    joins("INNER JOIN #{EnrollmentState.quoted_table_name} ON enrollment_states.enrollment_id=enrollments.id").
    where(:enrollment_states => {:state => 'active'}) }, through: :all_enrollments, source: :user

  has_many :student_view_enrollments, -> { where("enrollments.workflow_state<>'deleted'").preload(:user) }, class_name: 'StudentViewEnrollment'
  has_many :student_view_students, :through => :student_view_enrollments, :source => :user
  has_many :custom_gradebook_columns, -> { order('custom_gradebook_columns.position, custom_gradebook_columns.title') }, dependent: :destroy

  include LearningOutcomeContext
  include RubricContext

  has_many :course_account_associations
  has_many :non_unique_associated_accounts, -> { order('course_account_associations.depth') }, source: :account, through: :course_account_associations
  has_many :users, -> { distinct }, through: :enrollments, source: :user
  has_many :all_users, -> { distinct }, through: :all_enrollments, source: :user
  has_many :current_users, -> { distinct }, through: :current_enrollments, source: :user
  has_many :all_current_users, -> { distinct }, through: :all_current_enrollments, source: :user
  has_many :group_categories, -> {where(deleted_at: nil) }, as: :context, inverse_of: :context
  has_many :all_group_categories, :class_name => 'GroupCategory', :as => :context, :inverse_of => :context
  has_many :groups, :as => :context, :inverse_of => :context
  has_many :active_groups, -> { where("groups.workflow_state<>'deleted'") }, as: :context, inverse_of: :context, class_name: 'Group'
  has_many :assignment_groups, -> { order('assignment_groups.position', AssignmentGroup.best_unicode_collation_key('assignment_groups.name')) }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :assignments, -> { order('assignments.created_at') }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :calendar_events, -> { where("calendar_events.workflow_state<>'cancelled'") }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :submissions, -> { active.order('submissions.updated_at DESC') }, through: :assignments, dependent: :destroy
  has_many :submission_comments, -> { published }, as: :context, inverse_of: :context
  has_many :discussion_topics, -> { where("discussion_topics.workflow_state<>'deleted'").preload(:user).order('discussion_topics.position DESC, discussion_topics.created_at DESC') }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :active_discussion_topics, -> { where("discussion_topics.workflow_state<>'deleted'").preload(:user) }, as: :context, inverse_of: :context, class_name: 'DiscussionTopic'
  has_many :all_discussion_topics, -> { preload(:user) }, as: :context, inverse_of: :context, class_name: "DiscussionTopic", dependent: :destroy
  has_many :discussion_entries, -> { preload(:discussion_topic, :user) }, through: :discussion_topics, dependent: :destroy
  has_many :announcements, :as => :context, :inverse_of => :context, :class_name => 'Announcement', :dependent => :destroy
  has_many :active_announcements, -> { where("discussion_topics.workflow_state<>'deleted'") }, as: :context, inverse_of: :context, class_name: 'Announcement'
  has_many :attachments, :as => :context, :inverse_of => :context, :dependent => :destroy, :extend => Attachment::FindInContextAssociation
  has_many :active_images, -> { where("attachments.file_state<>? AND attachments.content_type LIKE 'image%'", 'deleted').order('attachments.display_name').preload(:thumbnail) }, as: :context, inverse_of: :context, class_name: 'Attachment'
  has_many :active_assignments, -> { where("assignments.workflow_state<>'deleted'").order('assignments.title, assignments.position') }, as: :context, inverse_of: :context, class_name: 'Assignment'
  has_many :folders, -> { order('folders.name') }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :active_folders, -> { where("folders.workflow_state<>'deleted'").order('folders.name') }, class_name: 'Folder', as: :context, inverse_of: :context
  has_many :messages, :as => :context, :inverse_of => :context, :dependent => :destroy
  has_many :context_external_tools, -> { order('name') }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :tool_proxies, class_name: 'Lti::ToolProxy', as: :context, inverse_of: :context, dependent: :destroy
  belongs_to :wiki
  has_many :wiki_pages, as: :context, inverse_of: :context
  has_many :quizzes, -> { order('lock_at, title, id') }, class_name: 'Quizzes::Quiz', as: :context, inverse_of: :context, dependent: :destroy
  has_many :quiz_questions, :class_name => 'Quizzes::QuizQuestion', :through => :quizzes
  has_many :active_quizzes, -> { preload(:assignment).where("quizzes.workflow_state<>'deleted'").order(:created_at) }, class_name: 'Quizzes::Quiz', as: :context, inverse_of: :context
  has_many :assessment_question_banks, -> { preload(:assessment_questions, :assessment_question_bank_users) }, as: :context, inverse_of: :context
  has_many :assessment_questions, :through => :assessment_question_banks
  def inherited_assessment_question_banks(include_self = false)
    self.account.inherited_assessment_question_banks(true, *(include_self ? [self] : []))
  end

  has_many :external_feeds, :as => :context, :inverse_of => :context, :dependent => :destroy
  belongs_to :default_grading_standard, :class_name => 'GradingStandard', :foreign_key => 'grading_standard_id'
  has_many :grading_standards, -> { where("workflow_state<>'deleted'") }, as: :context, inverse_of: :context
  has_many :web_conferences, -> { order('created_at DESC') }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :collaborations, -> { order("#{Collaboration.quoted_table_name}.title, #{Collaboration.quoted_table_name}.created_at") }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :context_modules, -> { order(:position) }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :context_module_progressions, through: :context_modules
  has_many :active_context_modules, -> { where(workflow_state: 'active') }, as: :context, inverse_of: :context, class_name: 'ContextModule'
  has_many :context_module_tags, -> { order(:position).where(tag_type: 'context_module') }, class_name: 'ContentTag', as: :context, inverse_of: :context, dependent: :destroy
  has_many :media_objects, :as => :context, :inverse_of => :context
  has_many :page_views, :as => :context, :inverse_of => :context
  has_many :asset_user_accesses, :as => :context, :inverse_of => :context
  has_many :role_overrides, :as => :context, :inverse_of => :context
  has_many :content_migrations, :as => :context, :inverse_of => :context
  has_many :content_exports, :as => :context, :inverse_of => :context
  has_many :epub_exports, -> { where("type IS NULL").order("created_at DESC") }
  attr_accessor :latest_epub_export
  has_many :web_zip_exports, -> { where(type: "WebZipExport") }
  has_many :alerts, -> { preload(:criteria) }, as: :context, inverse_of: :context
  has_many :appointment_group_contexts, :as => :context, :inverse_of => :context
  has_many :appointment_groups, :through => :appointment_group_contexts
  has_many :appointment_participants, -> { where("workflow_state = 'locked' AND parent_calendar_event_id IS NOT NULL") }, class_name: 'CalendarEvent', foreign_key: :effective_context_code, primary_key: :asset_string
  attr_accessor :import_source
  has_many :content_participation_counts, :as => :context, :inverse_of => :context, :dependent => :destroy
  has_many :poll_sessions, class_name: 'Polling::PollSession', dependent: :destroy
  has_many :grading_period_groups, dependent: :destroy
  has_many :grading_periods, through: :grading_period_groups
  has_many :usage_rights, as: :context, inverse_of: :context, class_name: 'UsageRights', dependent: :destroy

  has_many :sis_post_grades_statuses

  has_many :progresses, as: :context, inverse_of: :context
  has_many :gradebook_csvs, inverse_of: :course

  has_many :master_course_templates, :class_name => "MasterCourses::MasterTemplate"
  has_many :master_course_subscriptions, :class_name => "MasterCourses::ChildSubscription", :foreign_key => 'child_course_id'
  has_one :late_policy, dependent: :destroy, inverse_of: :course

  prepend Profile::Association

  before_save :assign_uuid
  before_validation :assert_defaults
  before_save :update_enrollments_later
  before_save :update_show_total_grade_as_on_weighting_scheme_change
  before_save :set_self_enrollment_code
  after_save :update_final_scores_on_weighting_scheme_change
  after_save :update_account_associations_if_changed
  after_save :update_enrollment_states_if_necessary
  after_save :touch_students_if_necessary
  after_commit :update_cached_due_dates

  after_update :clear_cached_short_name, :if => :saved_change_to_course_code?

  before_update :handle_syllabus_changes_for_master_migration

  before_save :touch_root_folder_if_necessary
  before_validation :verify_unique_ids
  validate :validate_course_dates
  validate :validate_course_image
  validate :validate_default_view
  validates :sis_source_id, uniqueness: {scope: :root_account}, allow_nil: true
  validates_presence_of :account_id, :root_account_id, :enrollment_term_id, :workflow_state
  validates_length_of :syllabus_body, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :name, :maximum => maximum_string_length, :allow_nil => true, :allow_blank => true
  validates_length_of :sis_source_id, :maximum => maximum_string_length, :allow_nil => true, :allow_blank => false
  validates_length_of :course_code, :maximum => maximum_string_length, :allow_nil => true, :allow_blank => true
  validates_locale :allow_nil => true

  sanitize_field :syllabus_body, CanvasSanitize::SANITIZE

  include StickySisFields
  are_sis_sticky :name, :course_code, :start_at, :conclude_at,
                 :restrict_enrollments_to_course_dates, :enrollment_term_id,
                 :workflow_state, :account_id

  include FeatureFlags

  include ContentNotices
  define_content_notice :import_in_progress,
    icon_class: 'icon-import-content',
    alert_class: 'alert-info import-in-progress-notice',
    template: 'courses/import_in_progress_notice',
    should_show: ->(course, user) do
      course.grants_right?(user, :manage_content)
    end

  has_a_broadcast_policy

  # A hard limit on the number of graders (excluding the moderator) a moderated
  # assignment can have.
  MODERATED_GRADING_GRADER_LIMIT = 10.freeze

  def [](attr)
    attr.to_s == 'asset_string' ? self.asset_string : super
  end

  def events_for(user)
    if user
      CalendarEvent.
        active.
        for_user_and_context_codes(user, [asset_string]).
        preload(:child_events).
        reject(&:hidden?) +
      AppointmentGroup.manageable_by(user, [asset_string]) +
        user.assignments_visible_in_course(self)
    else
      calendar_events.active.preload(:child_events).reject(&:hidden?) +
        assignments.active
    end
  end

  def self.skip_updating_account_associations(&block)
    if @skip_updating_account_associations
      block.call
    else
      begin
        @skip_updating_account_associations = true
        block.call
      ensure
        @skip_updating_account_associations = false
      end
    end
  end

  def self.skip_updating_account_associations?
    !!@skip_updating_account_associations
  end

  def update_account_associations_if_changed
    if (self.saved_change_to_root_account_id? || self.saved_change_to_account_id?) && !self.class.skip_updating_account_associations?
      send_now_or_later_if_production(new_record? ? :now : :later, :update_account_associations)
    end
  end

  def update_enrollment_states_if_necessary
    if (saved_changes.keys & %w{restrict_enrollments_to_course_dates account_id enrollment_term_id}).any? ||
        (self.restrict_enrollments_to_course_dates? && (saved_changes.keys & %w{start_at conclude_at}).any?) ||
        (self.saved_change_to_workflow_state? && (completed? || self.workflow_state_before_last_save == 'completed'))
        # a lot of things can change the date logic here :/

      EnrollmentState.send_later_if_production(:invalidate_states_for_course_or_section, self) if self.enrollments.exists?
      # if the course date settings have been changed, we'll end up reprocessing all the access values anyway, so no need to queue below for other setting changes
    end
    if @changed_settings
      changed_keys = (@changed_settings & [:restrict_student_future_view, :restrict_student_past_view])
      if changed_keys.any?
        EnrollmentState.send_later_if_production(:invalidate_access_for_course, self, changed_keys)
      end
    end

    @changed_settings = nil
  end

  def module_based?
    Rails.cache.fetch(['module_based_course', self].cache_key) do
      self.context_modules.active.any?{|m| m.completion_requirements && !m.completion_requirements.empty? }
    end
  end

  def modules_visible_to(user)
    if self.grants_right?(user, :view_unpublished_items)
      self.context_modules.not_deleted
    else
      self.context_modules.active
    end
  end

  def module_items_visible_to(user)
    if user_is_teacher = self.grants_right?(user, :view_unpublished_items)
      tags = self.context_module_tags.not_deleted.joins(:context_module).where("context_modules.workflow_state <> 'deleted'")
    else
      tags = self.context_module_tags.active.joins(:context_module).where(:context_modules => {:workflow_state => 'active'})
    end

    tags = DifferentiableAssignment.scope_filter(tags, user, self, is_teacher: user_is_teacher)
    tags
  end

  def sequential_module_item_ids
    Rails.cache.fetch(['ordered_module_item_ids', self].cache_key) do
      self.context_module_tags.not_deleted.joins(:context_module).
        where("context_modules.workflow_state <> 'deleted'").
        where("content_tags.content_type <> 'ContextModuleSubHeader'").
        reorder("COALESCE(context_modules.position, 0), context_modules.id, content_tags.position NULLS LAST").
        pluck(:id)
    end
  end

  def verify_unique_ids
    infer_root_account unless self.root_account_id

    is_unique = true
    if self.sis_source_id && (root_account_id_changed? || sis_source_id_changed?)
      scope = root_account.all_courses.where(sis_source_id: self.sis_source_id)
      scope = scope.where("id<>?", self) unless self.new_record?
      if scope.exists?
        is_unique = false
        self.errors.add(:sis_source_id, t('errors.sis_in_use', "SIS ID \"%{sis_id}\" is already in use",
            :sis_id => self.sis_source_id))
      end
    end

    if self.integration_id && (root_account_id_changed? || integration_id_changed?)
      scope = root_account.all_courses.where(integration_id: self.integration_id)
      scope = scope.where("id<>?", self) unless self.new_record?
      if scope.exists?
        is_unique = false
        self.errors.add(:integration_id, t("Integration ID \"%{int_id}\" is already in use",
            :int_id => self.integration_id))
      end
    end

    throw :abort unless is_unique
  end

  def validate_course_dates
    if start_at.present? && conclude_at.present? && conclude_at < start_at
      self.errors.add(:conclude_at, t("End date cannot be before start date"))
      false
    else
      true
    end
  end

  def validate_course_image
    if self.image_url.present? && self.image_id.present?
      self.errors.add(:image, t("image_url and image_id cannot both be set."))
      false
    elsif self.image_id.present? && valid_course_image_id?(self.image_id)
      true
    elsif self.image_url.present? && valid_course_image_url?(self.image_url)
      true
    else
      if self.image_id.present?
        self.errors.add(:image_id, t("image_id is not a valid ID"))
      elsif self.image_url.present?
        self.errors.add(:image_url, t("image_url is not a valid URL"))
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
    if self.default_view_changed?
      if !%w{assignments feed modules syllabus wiki}.include?(self.default_view)
        self.errors.add(:default_view, t("Home page is not valid"))
        return false
      elsif self.default_view == 'wiki' && !(self.wiki_id && self.wiki.has_front_page?)
        self.errors.add(:default_view, t("A Front Page is required"))
        return false
      end
    end
    true
  end

  def image
    if self.image_id.present?
      self.shard.activate do
        self.attachments.active.where(id: self.image_id).take&.public_download_url
      end
    elsif self.image_url
      self.image_url
    end
  end

  def course_visibility_options
    ActiveSupport::OrderedHash[
        'course',
        {
            :setting => t('course', 'Course')
        },
        'institution',
        {
            :setting => t('institution', 'Institution')
        },
        'public',
        {
            :setting => t('public', 'Public')
        }
      ]
  end

  def custom_course_visibility
    if public_syllabus == is_public && is_public_to_auth_users == public_syllabus_to_auth
      return false
    else
      return true
    end
  end

  def customize_course_visibility_list
    ActiveSupport::OrderedHash[
        'syllabus',
        {
            :setting => t('syllabus', 'Syllabus')
        }
      ]
  end

  def syllabus_visibility_option
    if public_syllabus == true
      'public'
    elsif public_syllabus_to_auth == true
      'institution'
    else
      'course'
    end
  end

  def course_visibility
    if is_public == true
      'public'
    elsif is_public_to_auth_users == true
      'institution'
    else
      'course'
    end
  end

  def public_license?
    license && self.class.public_license?(license)
  end

  def license_data
    licenses = self.class.licenses
    licenses[license] || licenses['private']
  end

  def license_url
    license_data[:license_url]
  end

  def readable_license
    license_data[:readable_license].call
  end

  def unpublishable?
    ids = self.all_real_students.pluck :id
    !self.submissions.with_assignment.with_point_data.where(:user_id => ids).exists?
  end

  def self.update_account_associations(courses_or_course_ids, opts = {})
    return [] if courses_or_course_ids.empty?
    opts.reverse_merge! :account_chain_cache => {}
    account_chain_cache = opts[:account_chain_cache]

    # Split it up into manageable chunks
    user_ids_to_update_account_associations = []
    if courses_or_course_ids.length > 500
      opts = opts.dup
      opts.reverse_merge! :skip_user_account_associations => true
      courses_or_course_ids.uniq.compact.each_slice(500) do |courses_or_course_ids_slice|
        user_ids_to_update_account_associations += update_account_associations(courses_or_course_ids_slice, opts)
      end
    else

      if courses_or_course_ids.first.is_a? Course
        courses = courses_or_course_ids
        ActiveRecord::Associations::Preloader.new.preload(courses, :course_sections => :nonxlist_course)
        course_ids = courses.map(&:id)
      else
        course_ids = courses_or_course_ids
        courses = Course.where(:id => course_ids).
            preload(:course_sections => [:course, :nonxlist_course]).
            select([:id, :account_id]).to_a
      end
      course_ids_to_update_user_account_associations = []
      CourseAccountAssociation.transaction do
        current_associations = {}
        to_delete = []
        CourseAccountAssociation.where(:course_id => course_ids).each do |aa|
          key = [aa.course_section_id, aa.account_id]
          current_course_associations = current_associations[aa.course_id] ||= {}
          # duplicates. the unique index prevents these now, but this code
          # needs to hang around for the migration itself
          if current_course_associations.has_key?(key)
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
                    account_id: account_id).update_all(:depth => depth)
                end
                did_an_update = true
              else
                if association[1] != depth
                  CourseAccountAssociation.where(:id => association[0]).update_all(:depth => depth)
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
            course.non_unique_associated_accounts.reset
            course_ids_to_update_user_account_associations << course.id
          end
        end

        to_delete += current_associations.map { |k, v| v.map { |k2, v2| v2[0] } }.flatten
        unless to_delete.empty?
          CourseAccountAssociation.where(:id => to_delete).delete_all
        end
      end

      user_ids_to_update_account_associations = Enrollment.
          where("course_id IN (?) AND workflow_state<>'deleted'", course_ids_to_update_user_account_associations).
          group(:user_id).pluck(:user_id) unless course_ids_to_update_user_account_associations.empty?
    end
    User.update_account_associations(user_ids_to_update_account_associations, :account_chain_cache => account_chain_cache) unless user_ids_to_update_account_associations.empty? || opts[:skip_user_account_associations]
    user_ids_to_update_account_associations
  end

  def update_account_associations
    self.shard.activate do
      Course.update_account_associations([self])
    end
  end

  def associated_accounts
    accounts = self.non_unique_associated_accounts.to_a.uniq
    accounts << self.account if account_id && !accounts.find { |a| a.id == account_id }
    accounts << self.root_account if root_account_id && !accounts.find { |a| a.id == root_account_id }
    accounts
  end

  scope :recently_started, -> { where(:start_at => 1.month.ago..Time.zone.now).order("start_at DESC").limit(10) }
  scope :recently_ended, -> { where(:conclude_at => 1.month.ago..Time.zone.now).order("start_at DESC").limit(10) }
  scope :recently_created, -> { where("created_at>?", 1.month.ago).order("created_at DESC").limit(50).preload(:teachers) }
  scope :for_term, lambda {|term| term ? where(:enrollment_term_id => term) : all }
  scope :active_first, -> { order("CASE WHEN courses.workflow_state='available' THEN 0 ELSE 1 END, #{best_unicode_collation_key('name')}") }
  scope :name_like, lambda {|name| where(coalesced_wildcard('courses.name', 'courses.sis_source_id', 'courses.course_code', name)) }
  scope :needs_account, lambda { |account, limit| where(:account_id => nil, :root_account_id => account).limit(limit) }
  scope :active, -> { where("courses.workflow_state<>'deleted'") }
  scope :least_recently_updated, lambda { |limit| order(:updated_at).limit(limit) }
  scope :manageable_by_user, lambda { |*args|
    # args[0] should be user_id, args[1], if true, will include completed
    # enrollments as well as active enrollments
    user_id = args[0]
    workflow_states = (args[1].present? ? %w{'active' 'completed'} : %w{'active'}).join(', ')
    distinct.joins("INNER JOIN (
         SELECT caa.course_id, au.user_id FROM #{CourseAccountAssociation.quoted_table_name} AS caa
         INNER JOIN #{Account.quoted_table_name} AS a ON a.id = caa.account_id AND a.workflow_state = 'active'
         INNER JOIN #{AccountUser.quoted_table_name} AS au ON au.account_id = a.id AND au.user_id = #{user_id.to_i} AND au.workflow_state = 'active'
       UNION SELECT courses.id AS course_id, e.user_id FROM #{Course.quoted_table_name}
         INNER JOIN #{Enrollment.quoted_table_name} AS e ON e.course_id = courses.id AND e.user_id = #{user_id.to_i}
           AND e.workflow_state IN(#{workflow_states}) AND e.type IN ('TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment')
         WHERE courses.workflow_state <> 'deleted') as course_users
       ON course_users.course_id = courses.id")
  }
  scope :not_deleted, -> { where("workflow_state<>'deleted'") }

  scope :with_enrollments, -> {
    where("EXISTS (?)", Enrollment.active.where("enrollments.course_id=courses.id"))
  }
  scope :with_enrollment_types, -> (types) {
    types = types.map { |type| "#{type.capitalize}Enrollment" }
    where("EXISTS (?)", Enrollment.active.where("enrollments.course_id=courses.id").where(type: types))
  }
  scope :without_enrollments, -> {
    where("NOT EXISTS (?)", Enrollment.active.where("enrollments.course_id=courses.id"))
  }
  scope :completed, -> {
    joins(:enrollment_term).
        where("courses.workflow_state='completed' OR courses.conclude_at<? OR enrollment_terms.end_at<?", Time.now.utc, Time.now.utc)
  }
  scope :not_completed, -> {
    joins(:enrollment_term).
        where("courses.workflow_state<>'completed' AND
          (courses.conclude_at IS NULL OR courses.conclude_at>=?) AND
          (enrollment_terms.end_at IS NULL OR enrollment_terms.end_at>=?)", Time.now.utc, Time.now.utc)
  }
  scope :by_teachers, lambda { |teacher_ids|
    teacher_ids.empty? ?
      none :
      where("EXISTS (?)", Enrollment.active.where("enrollments.course_id=courses.id AND enrollments.type='TeacherEnrollment' AND enrollments.user_id IN (?)", teacher_ids))
  }
  scope :by_associated_accounts, lambda { |account_ids|
    account_ids.empty? ?
      none :
      where("EXISTS (?)", CourseAccountAssociation.where("course_account_associations.course_id=courses.id AND course_account_associations.account_id IN (?)", account_ids))
  }
  scope :published, -> { where(workflow_state: %w(available completed)) }
  scope :unpublished, -> { where(workflow_state: %w(created claimed)) }

  scope :deleted, -> { where(:workflow_state => 'deleted') }

  scope :master_courses, -> { joins(:master_course_templates).where.not(MasterCourses::MasterTemplate.table_name => {:workflow_state => 'deleted'}) }
  scope :not_master_courses, -> { joins("LEFT OUTER JOIN #{MasterCourses::MasterTemplate.quoted_table_name} AS mct ON mct.course_id=courses.id AND mct.workflow_state<>'deleted'").where("mct IS NULL") }

  scope :associated_courses, -> { joins(:master_course_subscriptions).where.not(MasterCourses::ChildSubscription.table_name => {:workflow_state => 'deleted'}) }
  scope :not_associated_courses, -> { joins("LEFT OUTER JOIN #{MasterCourses::ChildSubscription.quoted_table_name} AS mcs ON mcs.child_course_id=courses.id AND mcs.workflow_state<>'deleted'").where("mcs IS NULL") }

  def potential_collaborators
    current_users
  end

  set_broadcast_policy do |p|
    p.dispatch :grade_weight_changed
    p.to { participating_students_by_date + participating_observers_by_date }
    p.whenever { |record|
      (record.available? && @grade_weight_changed) ||
      record.changed_in_state(:available, :fields => :group_weighting_scheme)
    }

    p.dispatch :new_course
    p.to { self.root_account.account_users.active }
    p.whenever { |record|
      record.root_account &&
      ((record.just_created && record.name != Course.default_name) ||
       (record.name_before_last_save == Course.default_name &&
         record.name != Course.default_name)
      )
    }
  end

  def self.default_name
    # TODO i18n
    t('default_name', "My Course")
  end

  def users_not_in_groups(groups, opts={})
    scope = User.joins(:not_ended_enrollments).
      where(enrollments: {course_id: self, type: 'StudentEnrollment'}).
      where(Group.not_in_group_sql_fragment(groups.map(&:id))).
      select("users.id, users.name, users.updated_at").distinct
    scope = scope.select(opts[:order]).order(opts[:order]) if opts[:order]
    scope
  end

  def instructors_in_charge_of(user_id)
    scope = current_enrollments.
      where(:course_id => self, :user_id => user_id).
      where("course_section_id IS NOT NULL")
    section_ids = scope.distinct.pluck(:course_section_id)
    participating_instructors.restrict_to_sections(section_ids)
  end

  # Tread carefully — this method returns true for Teachers, TAs, and Designers
  # in the course.
  def user_is_admin?(user)
    return unless user
    RequestCache.cache('user_is_admin', self, user) do
      Rails.cache.fetch([self, user, "course_user_is_admin"].cache_key) do
        self.enrollments.for_user(user).active_by_date.of_admin_type.exists?
      end
    end
  end

  def user_is_instructor?(user)
    return unless user
    RequestCache.cache('user_is_instructor', self, user) do
      Rails.cache.fetch([self, user, "course_user_is_instructor"].cache_key) do
        self.enrollments.for_user(user).active_by_date.of_instructor_type.exists?
      end
    end
  end

  def user_is_student?(user, opts = {})
    return unless user

    RequestCache.cache('user_is_student', self, user, opts) do
      Rails.cache.fetch([self, user, "course_user_is_student", opts].cache_key) do
        enroll_types = ["StudentEnrollment"]
        enroll_types << "StudentViewEnrollment" if opts[:include_fake_student]

        enroll_scope = self.enrollments.for_user(user).where(:type => enroll_types)
        if opts[:include_future]
          enroll_scope = enroll_scope.active_or_pending_by_date_ignoring_access
        elsif opts[:include_all]
          enroll_scope = enroll_scope.not_inactive_by_date_ignoring_access
        else
          return false unless self.available?
          enroll_scope = enroll_scope.active_by_date
        end
        enroll_scope.exists?
      end
    end
  end

  def preload_user_roles!
    # plz to use before you make a billion calls to user_has_been_X? with different users
    @user_ids_by_enroll_type ||= begin
      self.shard.activate do
        map = {}
        self.enrollments.active.pluck(:user_id, :type).each do |user_id, type|
          map[type] ||= []
          map[type] << user_id
        end
        map
      end
    end
  end

  def preloaded_user_has_been?(user, types)
    self.shard.activate do
      Array(types).any?{|type| @user_ids_by_enroll_type.has_key?(type) && @user_ids_by_enroll_type[type].include?(user.id)}
    end
  end

  def user_has_been_instructor?(user)
    return unless user
    if @user_ids_by_enroll_type
      return preloaded_user_has_been?(user, %w{TaEnrollment TeacherEnrollment})
    end
    # enrollments should be on the course's shard
    RequestCache.cache('user_has_been_instructor', self, user) do
      self.shard.activate do
        Rails.cache.fetch([self, user, "course_user_has_been_instructor"].cache_key) do
          # active here is !deleted; it still includes concluded, etc.
          self.instructor_enrollments.active.where(user_id: user).exists?
        end
      end
    end
  end

  def user_has_been_admin?(user)
    return unless user
    if @user_ids_by_enroll_type
      return preloaded_user_has_been?(user, %w{TaEnrollment TeacherEnrollment DesignerEnrollment})
    end

    RequestCache.cache('user_has_been_admin', self, user) do
      Rails.cache.fetch([self, user, "course_user_has_been_admin"].cache_key) do
        # active here is !deleted; it still includes concluded, etc.
        self.admin_enrollments.active.where(user_id: user).exists?
      end
    end
  end

  def user_has_been_observer?(user)
    return unless user
    if @user_ids_by_enroll_type
      return preloaded_user_has_been?(user, "ObserverEnrollment")
    end

    RequestCache.cache('user_has_been_observer', self, user) do
      Rails.cache.fetch([self, user, "course_user_has_been_observer"].cache_key) do
        # active here is !deleted; it still includes concluded, etc.
        self.observer_enrollments.shard(self).active.where(user_id: user).exists?
      end
    end
  end

  def user_has_been_student?(user)
    return unless user
    if @user_ids_by_enroll_type
      return preloaded_user_has_been?(user, %w{StudentEnrollment StudentViewEnrollment})
    end

    RequestCache.cache('user_has_been_student', self, user) do
      Rails.cache.fetch([self, user, "course_user_has_been_student"].cache_key) do
        self.all_student_enrollments.where(user_id: user).exists?
      end
    end
  end

  def user_has_no_enrollments?(user)
    return unless user
    if @user_ids_by_enroll_type
      self.shard.activate do
        return !@user_ids_by_enroll_type.values.any?{|arr| arr.include?(user.id)}
      end
    end

    RequestCache.cache('user_has_no_enrollments', self, user) do
      Rails.cache.fetch([self, user, "course_user_has_no_enrollments"].cache_key) do
        !enrollments.where(user_id: user).exists?
      end
    end
  end


  # Public: Determine if a group weighting scheme should be applied.
  #
  # Returns boolean.
  def apply_group_weights?
    group_weighting_scheme == 'percent'
  end

  def apply_assignment_group_weights=(apply)
    if apply
      self.group_weighting_scheme = 'percent'
    else
      self.group_weighting_scheme = 'equal'
    end
  end

  def grade_weight_changed!
    @grade_weight_changed = true
    self.save!
    @grade_weight_changed = false
  end

  def membership_for_user(user)
    self.enrollments.where(user_id: user).first if user
  end

  def infer_root_account
    self.root_account = account if account&.root_account?
    self.root_account_id ||= account&.root_account_id
  end

  def assert_defaults
    self.tab_configuration ||= [] unless self.tab_configuration == []
    self.name = nil if self.name && self.name.strip.empty?
    self.name ||= t('missing_name', "Unnamed Course")
    self.course_code = nil if self.course_code == ''
    if !self.course_code && self.name
      res = []
      split = self.name.split(/\s/)
      res << split[0]
      res << split[1..-1].find{|txt| txt.match(/\d/) } rescue nil
      self.course_code = res.compact.join(" ")
    end
    @group_weighting_scheme_changed = self.group_weighting_scheme_changed?
    if self.account_id && self.account_id_changed?
      infer_root_account
    end
    if self.root_account_id && self.root_account_id_changed?
      if account
        if account.root_account?
          self.account = nil if root_account_id != account.id
        else
          self.account = nil if account&.root_account_id != root_account_id
        end
      end
      self.account_id ||= self.root_account_id
    end
    self.root_account_id ||= Account.default.id
    self.account_id ||= self.root_account_id
    self.enrollment_term = nil if self.enrollment_term.try(:root_account_id) != self.root_account_id
    self.enrollment_term ||= self.root_account.default_enrollment_term
    self.allow_student_wiki_edits = (self.default_wiki_editing_roles || "").split(',').include?('students')
    if self.course_format && !['on_campus', 'online', 'blended'].include?(self.course_format)
      self.course_format = nil
    end
    self.default_view ||= default_home_page
    true
  end

  def update_course_section_names
    return if @course_name_was == self.name || !@course_name_was
    sections = self.course_sections
    fields_to_possibly_rename = [:name]
    sections.each do |section|
      something_changed = false
      fields_to_possibly_rename.each do |field|
        section.send("#{field}=", section.default_section ?
          self.name :
          (section.send(field) || self.name).sub(@course_name_was, self.name) )
        something_changed = true if section.send(field) != section.send("#{field}_was")
      end
      if something_changed
        attr_hash = {:updated_at => Time.now.utc}
        fields_to_possibly_rename.each { |key| attr_hash[key] = section.send(key) }
        CourseSection.where(:id => section).update_all(attr_hash)
      end
    end
  end

  def update_enrollments_later
    self.update_enrolled_users if !self.new_record? && !(self.changes.keys & ['workflow_state', 'name', 'course_code', 'start_at', 'conclude_at', 'enrollment_term_id']).empty?
    true
  end

  def update_enrolled_users(sis_batch: nil)
    self.shard.activate do
      if self.workflow_state_changed? || sis_batch && self.saved_change_to_workflow_state?
        if self.completed?
          enrollment_info = Enrollment.where(:course_id => self, :workflow_state => ['active', 'invited']).select(:id, :workflow_state).to_a
          if enrollment_info.any?
            data = SisBatchRollBackData.build_dependent_data(sis_batch: sis_batch, contexts: enrollment_info, updated_state: 'completed')
            Enrollment.where(:id => enrollment_info.map(&:id)).update_all(:workflow_state => 'completed', :completed_at => Time.now.utc)
            EnrollmentState.where(:enrollment_id => enrollment_info.map(&:id)).
              update_all(["state = ?, state_is_current = ?, access_is_current = ?, lock_version = lock_version + 1", 'completed', true, false])
            EnrollmentState.send_later_if_production(:process_states_for_ids, enrollment_info.map(&:id)) # recalculate access
          end

          appointment_participants.active.current.update_all(:workflow_state => 'deleted')
          appointment_groups.each(&:clear_cached_available_slots!)
        elsif self.deleted?
          enroll_scope = Enrollment.where("course_id=? AND workflow_state<>'deleted'", self)

          user_ids = enroll_scope.group(:user_id).pluck(:user_id).uniq
          if user_ids.any?
            enrollment_info = enroll_scope.select(:id, :workflow_state).to_a
            if enrollment_info.any?
              data = SisBatchRollBackData.build_dependent_data(sis_batch: sis_batch, contexts: enrollment_info, updated_state: 'deleted')
              Enrollment.where(:id => enrollment_info.map(&:id)).update_all(:workflow_state => 'deleted')
              EnrollmentState.where(:enrollment_id => enrollment_info.map(&:id)).
                update_all(["state = ?, state_is_current = ?, lock_version = lock_version + 1", 'deleted', true])
            end
            User.send_later_if_production(:update_account_associations, user_ids)
          end
        end
      end

      if self.root_account_id_changed?
        CourseSection.where(:course_id => self).update_all(:root_account_id => self.root_account_id)
        Enrollment.where(:course_id => self).update_all(:root_account_id => self.root_account_id)
      end

      Enrollment.where(:course_id => self).touch_all
      User.where(id: Enrollment.where(course_id: self).select(:user_id)).touch_all
      data
    end
  end

  def self_enrollment_allowed?
    !!(self.account && self.account.self_enrollment_allowed?(self))
  end

  def self_enrollment_enabled?
    self.self_enrollment? && self.self_enrollment_allowed?
  end

  def self_enrollment_code
    read_attribute(:self_enrollment_code) || set_self_enrollment_code
  end

  def set_self_enrollment_code
    return if !self_enrollment_enabled? || read_attribute(:self_enrollment_code)

    # subset of letters and numbers that are unambiguous
    alphanums = 'ABCDEFGHJKLMNPRTWXY346789'
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
      code = code_length.times.map{
        alphanums[(rand * alphanums.size).to_i, 1]
      }.join
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
    if group_weighting_scheme_changed? and self.group_weighting_scheme == 'percent'
      self.show_total_grade_as_points = false
    end
    true
  end

  # to ensure permissions on the root folder are updated after hiding or showing the files tab
  def touch_root_folder_if_necessary
    if tab_configuration_changed?
      files_tab_was_hidden = tab_configuration_was && tab_configuration_was.any? { |h| !h.blank? && h['id'] == TAB_FILES && h['hidden'] }
      Folder.root_folders(self).each { |f| f.touch } if files_tab_was_hidden != tab_hidden?(TAB_FILES)
    end
    true
  end

  def update_cached_due_dates
    DueDateCacher.recompute_course(self) if saved_change_to_enrollment_term_id?
  end

  def update_final_scores_on_weighting_scheme_change
    if @group_weighting_scheme_changed
      self.class.connection.after_transaction_commit { self.recompute_student_scores }
    end
  end

  def recompute_student_scores(student_ids = nil, grading_period_id: nil,
                                                  update_all_grading_period_scores: true,
                                                  update_course_score: true,
                                                  run_immediately: false)
    if run_immediately
      recompute_student_scores_without_send_later(
        student_ids,
        grading_period_id: grading_period_id,
        update_all_grading_period_scores: update_all_grading_period_scores
      )
    else
      inst_job_opts = {}
      if student_ids.blank? && grading_period_id.nil? && update_all_grading_period_scores && update_course_score
        # if we have all default args, let's queue this job in a singleton to avoid duplicates
        inst_job_opts[:singleton] = "recompute_student_scores:#{global_id}"
      elsif student_ids.blank? && grading_period_id.present?
        # A migration that changes a lot of due dates in a grading period
        # situation can kick off a job storm and redo work. Let's avoid
        # that by putting it into a singleton.
        inst_job_opts[:singleton] = "recompute_student_scores:#{global_id}:#{grading_period_id}"
      end

      send_later_if_production_enqueue_args(
        :recompute_student_scores_without_send_later,
        inst_job_opts,
        student_ids,
        grading_period_id: grading_period_id,
        update_all_grading_period_scores: update_all_grading_period_scores
      )
    end
  end

  def recompute_student_scores_without_send_later(student_ids = nil, opts = {})
    if student_ids.present?
      # We were given student_ids.  Let's see how many of those students can even see this assignment
      student_ids = admin_visible_student_enrollments.where(user_id: student_ids).pluck(:user_id)
    end

    # We were either not given any student_ids or none of those students could see this assignment.
    # Let's get them all!
    student_ids = admin_visible_student_enrollments.pluck(:user_id) unless student_ids.present?

    Rails.logger.debug "GRADES: recomputing scores in course=#{global_id} students=#{student_ids.inspect}"
    Enrollment.recompute_final_score(
      student_ids,
      self.id,
      grading_period_id: opts[:grading_period_id],
      update_all_grading_period_scores: opts.fetch(:update_all_grading_period_scores, true)
    )
  end

  def handle_syllabus_changes_for_master_migration
    if self.syllabus_body_changed?
      if @updating_master_template_id
        # master migration sync
        self.syllabus_master_template_id ||= @updating_master_template_id if self.syllabus_body_was.blank? # sync if there was no syllabus before
        if self.syllabus_master_template_id.to_i != @updating_master_template_id
          self.restore_syllabus_body! # revert the change
        end
      elsif self.syllabus_master_template_id
        # local change - remove the template id to prevent future syncs
        self.syllabus_master_template_id = nil
      end
    end
  end

  def home_page
    self.wiki.front_page
  end

  def context_code
    raise "DONT USE THIS, use .short_name instead" unless Rails.env.production?
  end

  def allow_media_comments?
    true || [].include?(self.id)
  end

  def short_name
    course_code
  end

  def short_name=(val)
    write_attribute(:course_code, val)
  end

  def short_name_slug
    CanvasTextHelper.truncate_text(short_name, :ellipsis => '')
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
    self.start_at ||= Time.now
    send_later_if_production(:invite_uninvited_students)
  end

  def do_claim
    self.workflow_state = 'claimed'
  end

  def invite_uninvited_students
    self.enrollments.where(workflow_state: "creation_pending").each do |e|
      e.invite!
    end
  end

  workflow do
    state :created do
      event :claim, :transitions_to => :claimed
      event :offer, :transitions_to => :available
      event :complete, :transitions_to => :completed
    end

    state :claimed do
      event :offer, :transitions_to => :available
      event :complete, :transitions_to => :completed
    end

    state :available do
      event :complete, :transitions_to => :completed
      event :claim, :transitions_to => :claimed
    end

    state :completed do
      event :unconclude, :transitions_to => :available
    end
    state :deleted
  end

  def api_state
    return 'unpublished' if workflow_state == 'created' || workflow_state == 'claimed'
    workflow_state
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    save!
  end

  def self.destroy_batch(courses, sis_batch: nil, batch_mode: false)
    enroll_scope = Enrollment.where(course_id: courses, workflow_state: 'deleted')
    enroll_scope.find_in_batches do |e_batch|
      user_ids = e_batch.map(&:user_id).uniq.sort
      data = SisBatchRollBackData.build_dependent_data(sis_batch: sis_batch,
                                                       contexts: e_batch,
                                                       updated_state: 'deleted',
                                                       batch_mode_delete: batch_mode)
      SisBatchRollBackData.bulk_insert_roll_back_data(data) if data
      Enrollment.where(id: e_batch.map(&:id)).update_all(workflow_state: 'deleted', updated_at: Time.zone.now)
      EnrollmentState.where(:enrollment_id => e_batch.map(&:id)).
        update_all(["state = ?, state_is_current = ?, lock_version = lock_version + 1", 'deleted', true])
      User.where(id: user_ids).touch_all
      User.send_later_if_production(:update_account_associations, user_ids) if user_ids.any?
    end
    c_data = SisBatchRollBackData.build_dependent_data(sis_batch: sis_batch, contexts: courses, updated_state: 'deleted', batch_mode_delete: batch_mode)
    SisBatchRollBackData.bulk_insert_roll_back_data(c_data) if c_data
    Course.where(id: courses).update_all(workflow_state: 'deleted', updated_at: Time.zone.now)
    courses.count
  end

  def call_event(event)
    self.send(event) if self.current_state.events.include? event.to_sym
  end

  def claim_with_teacher(user)
    raise "Must provide a valid teacher" unless user
    return unless self.state == :created
    e = enroll_user(user, 'TeacherEnrollment', :enrollment_state => 'active') #teacher(user)
    claim
    e
  end

  def self.require_assignment_groups(contexts)
    courses = contexts.select{|c| c.is_a?(Course) }
    groups = Shard.partition_by_shard(courses) do |shard_courses|
      AssignmentGroup.select("id, context_id, context_type").where(:context_type => "Course", :context_id => shard_courses)
    end.index_by(&:context_id)
    courses.each do |course|
      if !groups[course.id]
        course.require_assignment_group rescue nil
      end
    end
  end

  def require_assignment_group
    shard.activate do
      return if Rails.cache.read(['has_assignment_group', self].cache_key)
      if self.assignment_groups.active.empty?
        self.assignment_groups.create(:name => t('#assignment_group.default_name', "Assignments"))
      end
      Rails.cache.write(['has_assignment_group', self].cache_key, true)
    end
  end

  def self.create_unique(uuid=nil, account_id=nil, root_account_id=nil)
    uuid ||= CanvasSlug.generate_securish_uuid
    course = where(uuid: uuid).first_or_initialize
    course = Course.new if course.deleted?
    course.name = self.default_name if course.new_record?
    course.short_name = t('default_short_name', "Course-101") if course.new_record?
    course.account_id = account_id || root_account_id
    course.root_account_id = root_account_id
    course.save!
    course
  end

  def <=>(other)
    self.id <=> other.id
  end

  def quota
    Rails.cache.fetch(['default_quota', self].cache_key) do
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
    return read_attribute(:storage_quota) ||
      (self.account.default_storage_quota rescue nil) ||
      Setting.get('course_default_quota', 500.megabytes.to_s).to_i
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
    Atom::Entry.new do |entry|
      entry.title     = self.name
      entry.updated   = self.updated_at
      entry.published = self.created_at
      entry.links    << Atom::Link.new(:rel => 'alternate',
                                    :href => "/#{context_url_prefix}/courses/#{self.id}")
    end
  end

  set_policy do
    given { |user, session| self.available? && (self.is_public || (self.is_public_to_auth_users && session.present? && session.has_key?(:user_id)))  }
    can :read and can :read_outcomes and can :read_syllabus

    given { |user, session| self.available? && (self.public_syllabus || (self.public_syllabus_to_auth && session.present? && session.has_key?(:user_id)))}
    can :read_syllabus

    RoleOverride.permissions.each do |permission, details|
      given {|user| (self.active_enrollment_allows(user, permission, !details[:restrict_future_enrollments]) || self.account_membership_allows(user, permission)) }
      can permission
    end

    given { |user, session| session && session[:enrollment_uuid] && (hash = Enrollment.course_user_state(self, session[:enrollment_uuid]) || {}) && (hash[:enrollment_state] == "invited" || hash[:enrollment_state] == "active" && hash[:user_state].to_s == "pre_registered") && (self.available? || self.completed? || self.claimed? && hash[:is_admin]) }
    can :read and can :read_outcomes

    given { |user| (self.available? || self.completed?) && user && enrollments.for_user(user).not_inactive_by_date.exists? }
    can :read and can :read_outcomes

    # Active students
    given { |user|
      available?  && user && enrollments.for_user(user).active_by_date.of_student_type.exists?
    }
    can :read and can :participate_as_student and can :read_grades and can :read_outcomes

    given { |user| (self.available? || self.completed?) && user &&
      enrollments.for_user(user).active_by_date.where(:type => "ObserverEnrollment").where.not(:associated_user_id => nil).exists? }
    can :read_grades

    given { |user| self.available? && self.teacherless? && user && enrollments.for_user(user).active_by_date.of_student_type.exists? }
    can :update and can :delete and RoleOverride.teacherless_permissions.each{|p| can p }

    # Active admins (Teacher/TA/Designer)
    given { |user| (self.available? || self.created? || self.claimed?) && user &&
      enrollments.for_user(user).of_admin_type.active_by_date.exists? }
    can :read_as_admin and can :read and can :manage and can :update and can :use_student_view and can :read_outcomes and can :view_unpublished_items and can :manage_feature_flags

    # Teachers and Designers can delete/reset, but not TAs
    given { |user| !self.deleted? && !self.sis_source_id && user &&
      enrollments.for_user(user).of_content_admins.active_by_date.to_a.any?{|e| e.has_permission_to?(:change_course_state)}
    }
    can :delete

    given { |user| !self.deleted? && user && enrollments.for_user(user).of_content_admins.active_by_date.exists? }
    can :reset_content

    # Student view student
    given { |user| user && user.fake_student? && current_enrollments.for_user(user).exists? }
    can :read and can :participate_as_student and can :read_grades and can :read_outcomes

    # Prior users
    given do |user|
      (available? || completed?) && user &&
        enrollments.for_user(user).completed_by_date.exists?
    end
    can :read, :read_outcomes

    # Admin (Teacher/TA/Designer) of a concluded course
    given do |user|
      !self.deleted? && user &&
        enrollments.for_user(user).of_admin_type.completed_by_date.exists?
    end
    can [:read, :read_as_admin, :use_student_view, :read_outcomes, :view_unpublished_items]

    # overrideable permissions for concluded users
    RoleOverride.concluded_permission_types.each do |permission, details|
      applicable_roles = details[:applies_to_concluded].is_a?(Array) && details[:applies_to_concluded]

      given do |user|
        !self.deleted? && user &&
          enrollments.for_user(user).completed_by_date.to_a.any?{|e| e.has_permission_to?(permission) && (!applicable_roles || applicable_roles.include?(e.type))}
      end
      can permission
    end

    # Teacher or Designer of a concluded course
    given do |user|
      !self.deleted? && !self.sis_source_id && user &&
        enrollments.for_user(user).of_content_admins.completed_by_date.to_a.any?{|e| e.has_permission_to?(:change_course_state)}
    end
    can :delete

    # Student of a concluded course
    given do |user|
      (self.available? || self.completed?) && user &&
        enrollments.for_user(user).completed_by_date.
        where("enrollments.type = ? OR (enrollments.type = ? AND enrollments.associated_user_id IS NOT NULL)", "StudentEnrollment", "ObserverEnrollment").exists?
    end
    can :read, :read_grades, :read_outcomes

    # Admin
    given { |user| self.account_membership_allows(user) }
    can :read_as_admin and can :view_unpublished_items

    given { |user| self.account_membership_allows(user, :manage_courses) }
    can :read_as_admin and can :manage and can :update and can :use_student_view and can :reset_content and can :view_unpublished_items and can :manage_feature_flags

    given { |user| self.account_membership_allows(user, :manage_courses) && self.grants_right?(user, :change_course_state) }
    can :delete

    given { |user| self.account_membership_allows(user, :read_course_content) }
    can :read and can :read_outcomes

    given { |user| !self.deleted? && self.sis_source_id && self.account_membership_allows(user, :manage_sis) && self.grants_right?(user, :change_course_state) }
    can :delete

    # Admins with read_roster can see prior enrollments (can't just check read_roster directly,
    # because students can't see prior enrollments)
    given { |user| self.grants_all_rights?(user, :read_roster, :read_as_admin) }
    can :read_prior_roster

    given { |user| self.grants_right?(user, :lti_add_edit)}
    can :create_tool_manually
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

  def active_enrollment_allows(user, permission, allow_future=true)
    return false unless user && permission && !self.deleted?

    is_unpublished = self.created? || self.claimed?
    @enrollment_lookup ||= {}
    @enrollment_lookup[user.id] ||= shard.activate do
      self.enrollments.active_or_pending.for_user(user).except(:preload).preload(:enrollment_state).
        reject { |e| (is_unpublished && !(e.admin? || e.fake_student?)) || [:inactive, :completed].include?(e.state_based_on_date)}
    end

    @enrollment_lookup[user.id].any? {|e| (allow_future || e.state_based_on_date == :active) && e.has_permission_to?(permission) }
  end

  def self.find_all_by_context_code(codes)
    ids = codes.map{|c| c.match(/\Acourse_(\d+)\z/)[1] rescue nil }.compact
    Course.where(:id => ids).preload(:current_enrollments).to_a
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
    self.deleted? || self.completed?
  end

  # Public: Return true if the end date for a course (or its term, if the course doesn't have one) has passed.
  #
  # Returns boolean or nil.
  def soft_concluded?(enrollment_type = nil)
    now = Time.now
    return end_at < now if end_at && restrict_enrollments_to_course_dates
    if enrollment_type
      override = enrollment_term.enrollment_dates_overrides.where(enrollment_type: enrollment_type).first
      end_at = override.end_at if override
    end
    end_at ||= enrollment_term.end_at
    end_at && end_at < now
  end

  def soft_conclude!
    self.conclude_at = Time.now
    self.restrict_enrollments_to_course_dates = true
  end

  def concluded?(enrollment_type = nil)
    completed? || soft_concluded?(enrollment_type)
  end

  def account_chain(include_site_admin: false)
    @account_chain ||= Account.account_chain(account_id)
    result = @account_chain.dup
    Account.add_site_admin_to_chain!(result) if include_site_admin
    result
  end

  def account_chain_ids
    @account_chain_ids ||= Account.account_chain_ids(account_id)
  end

  def institution_name
    return self.root_account.name if self.root_account_id != Account.default.id
    return (self.account || self.root_account).name
  end

  def account_users_for(user)
    return [] unless user
    @associated_account_ids ||= (self.associated_accounts + root_account.account_chain(include_site_admin: true)).
        uniq.map { |a| a.active? ? a.id : nil }.compact
    @account_users ||= {}
    @account_users[user.global_id] ||= Shard.partition_by_shard(@associated_account_ids) do |account_chain_ids|
      if account_chain_ids == [Account.site_admin.id]
        Account.site_admin.account_users_for(user)
      else
        AccountUser.active.where(:account_id => account_chain_ids, :user_id => user).to_a
      end
    end
    @account_users[user.global_id] ||= []
    @account_users[user.global_id]
  end

  def account_membership_allows(user, permission = nil)
    return false unless user

    @membership_allows ||= {}
    @membership_allows[[user.id, permission]] ||= self.account_users_for(user).any? { |au| permission.nil? || au.has_permission_to?(self, permission) }
  end

  def teacherless?
    # TODO: I need a better test for teacherless courses... in the mean time we'll just do this
    return false
    @teacherless_course ||= Rails.cache.fetch(['teacherless_course', self].cache_key) do
      !self.sis_source_id && self.teacher_enrollments.empty?
    end
  end

  def grade_publishing_status_translation(status, message)
    status = "unpublished" if status.blank?

    if message.present?
      case status
      when 'error'
        t("Error: %{message}", message: message)
      when 'unpublished'
        t("Not Synced: %{message}", message: message)
      when 'pending'
        t("Pending: %{message}", message: message)
      when 'publishing'
        t("Syncing: %{message}", message: message)
      when 'published'
        t("Synced: %{message}", message: message)
      when 'unpublishable'
        t("Unsyncable: %{message}", message: message)
      else
        t("Unknown status, %{status}: %{message}", message: message, status: status)
      end
    else
      case status
      when 'error'
        t("Error")
      when 'unpublished'
        t("Not Synced")
      when 'pending'
        t("Pending")
      when 'publishing'
        t("Syncing")
      when 'published'
        t("Synced")
      when 'unpublishable'
        t("Unsyncable")
      else
        t("Unknown status, %{status}", status: status)
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
    overall_status = "unpublished" unless found_statuses.size > 0
    overall_status = (%w{error unpublished pending publishing published unpublishable}).detect{|s| found_statuses.include?(s)} || overall_status
    return enrollments, overall_status
  end

  def should_kick_off_grade_publishing_timeout?
    settings = Canvas::Plugin.find!('grade_export').settings
    settings[:success_timeout].to_i > 0 && Canvas::Plugin.value_to_boolean(settings[:wait_for_success])
  end

  def self.valid_grade_export_types
    @valid_grade_export_types ||= {
        "instructure_csv" => {
            :name => t('grade_export_types.instructure_csv', "Instructure formatted CSV"),
            :callback => lambda { |course, enrollments, publishing_user, publishing_pseudonym|
                course.generate_grade_publishing_csv_output(enrollments, publishing_user, publishing_pseudonym)
            },
            :requires_grading_standard => false,
            :requires_publishing_pseudonym => false
          }
      }
  end

  def allows_grade_publishing_by(user)
    return false unless Canvas::Plugin.find!('grade_export').enabled?
    settings = Canvas::Plugin.find!('grade_export').settings
    format_settings = Course.valid_grade_export_types[settings[:format_type]]
    return false unless format_settings
    return false if SisPseudonym.for(user, self).nil? && format_settings[:requires_publishing_pseudonym]
    return true
  end

  def publish_final_grades(publishing_user, user_ids_to_publish = nil)
    # we want to set all the publishing statuses to 'pending' immediately,
    # and then as a delayed job, actually go publish them.

    raise "final grade publishing disabled" unless Canvas::Plugin.find!('grade_export').enabled?
    settings = Canvas::Plugin.find!('grade_export').settings

    last_publish_attempt_at = Time.now.utc
    scope = self.student_enrollments.not_fake
    scope = scope.where(user_id: user_ids_to_publish) if user_ids_to_publish
    scope.update_all(:grade_publishing_status => "pending",
                     :grade_publishing_message => nil,
                     :last_publish_attempt_at => last_publish_attempt_at)

    send_later_if_production(:send_final_grades_to_endpoint, publishing_user, user_ids_to_publish)
    send_at(last_publish_attempt_at + settings[:success_timeout].to_i.seconds, :expire_pending_grade_publishing_statuses, last_publish_attempt_at) if should_kick_off_grade_publishing_timeout?
  end

  def send_final_grades_to_endpoint(publishing_user, user_ids_to_publish = nil)
    # actual grade publishing logic is here, but you probably want
    # 'publish_final_grades'

    self.recompute_student_scores_without_send_later(user_ids_to_publish)
    enrollments = self.student_enrollments.not_fake.eager_load(:user).preload(:course_section).order_by_sortable_name
    enrollments = enrollments.where(user_id: user_ids_to_publish) if user_ids_to_publish

    errors = []
    posts_to_make = []
    posted_enrollment_ids = []
    all_enrollment_ids = enrollments.map(&:id)

    begin

      raise "final grade publishing disabled" unless Canvas::Plugin.find!('grade_export').enabled?
      settings = Canvas::Plugin.find!('grade_export').settings
      raise "endpoint undefined" if settings[:publish_endpoint].blank?
      format_settings = Course.valid_grade_export_types[settings[:format_type]]
      raise "unknown format type: #{settings[:format_type]}" unless format_settings
      raise "grade publishing requires a grading standard" if !self.grading_standard_enabled? && format_settings[:requires_grading_standard]

      publishing_pseudonym = SisPseudonym.for(publishing_user, self)
      raise "publishing disallowed for this publishing user" if publishing_pseudonym.nil? and format_settings[:requires_publishing_pseudonym]

      callback = Course.valid_grade_export_types[settings[:format_type]][:callback]

      posts_to_make = callback.call(self, enrollments, publishing_user, publishing_pseudonym)

    rescue => e
      Enrollment.where(:id => all_enrollment_ids).update_all(:grade_publishing_status => "error", :grade_publishing_message => e.to_s)
      raise e
    end

    posts_to_make.each do |enrollment_ids, res, mime_type, headers={}|
      begin
        posted_enrollment_ids += enrollment_ids
        if res
          SSLCommon.post_data(settings[:publish_endpoint], res, mime_type, headers )
        end
        Enrollment.where(:id => enrollment_ids).update_all(:grade_publishing_status => (should_kick_off_grade_publishing_timeout? ? "publishing" : "published"), :grade_publishing_message => nil)
      rescue => e
        errors << e
        Enrollment.where(:id => enrollment_ids).update_all(:grade_publishing_status => "error", :grade_publishing_message => e.to_s)
      end
    end

    Enrollment.where(:id => (all_enrollment_ids.to_set - posted_enrollment_ids.to_set).to_a).update_all(:grade_publishing_status => "unpublishable", :grade_publishing_message => nil)

    raise errors[0] if errors.size > 0
  end

  def generate_grade_publishing_csv_output(enrollments, publishing_user, publishing_pseudonym)
    enrollment_ids = []
    res = CSV.generate do |csv|
      row = ["publisher_id", "publisher_sis_id", "course_id", "course_sis_id", "section_id", "section_sis_id", "student_id", "student_sis_id", "enrollment_id", "enrollment_status", "score"]
      row << "grade" if self.grading_standard_enabled?
      csv << row
      enrollments.each do |enrollment|
        next unless enrollment.computed_final_score
        enrollment_ids << enrollment.id
        pseudonym_sis_ids = enrollment.user.pseudonyms.active.where(account_id: self.root_account_id).pluck(:sis_user_id)
        pseudonym_sis_ids = [nil] if pseudonym_sis_ids.empty?
        pseudonym_sis_ids.each do |pseudonym_sis_id|
          row = [publishing_user.try(:id), publishing_pseudonym.try(:sis_user_id),
                 enrollment.course.id, enrollment.course.sis_source_id,
                 enrollment.course_section.id, enrollment.course_section.sis_source_id,
                 enrollment.user.id, pseudonym_sis_id, enrollment.id,
                 enrollment.workflow_state, enrollment.computed_final_score]
          row << enrollment.computed_final_grade if self.grading_standard_enabled?
          csv << row
        end
      end
    end
    return [[enrollment_ids, res, "text/csv"]]
  end

  def expire_pending_grade_publishing_statuses(last_publish_attempt_at)
    self.student_enrollments.not_fake.where(:grade_publishing_status => ['pending', 'publishing'],
                                            :last_publish_attempt_at => last_publish_attempt_at).
        update_all(:grade_publishing_status => 'error', :grade_publishing_message => "Timed out.")
  end

  def gradebook_to_csv_in_background(filename, user, options = {})
    progress = progresses.build(tag: 'gradebook_to_csv')
    progress.save!

    exported_gradebook = gradebook_csvs.where(user_id: user).first_or_initialize
    attachment = user.attachments.build
    attachment.filename = filename
    attachment.content_type = 'text/csv'
    attachment.file_state = 'hidden'
    attachment.save!
    exported_gradebook.attachment = attachment
    exported_gradebook.progress = progress
    exported_gradebook.save!

    progress.process_job(
      self,
      :generate_csv,
      { preserve_method_args: true },
      user,
      options,
      attachment
    )
    {attachment_id: attachment.id, progress_id: progress.id}
  end

  def generate_csv(user, options, attachment)
    csv = GradebookExporter.new(self, user, options).to_csv
    create_attachment(attachment, csv)
  end


  def create_attachment(attachment, csv)
    Attachments::Storage.store_for_attachment(attachment, StringIO.new(csv))
    attachment.content_type = 'text/csv'
    attachment.save!
  end

  # included to make it easier to work with api, which returns
  # sis_source_id as sis_course_id.
  alias_attribute :sis_course_id, :sis_source_id

  def grading_standard_title
    if self.grading_standard_enabled?
      self.grading_standard.try(:title) || t('default_grading_scheme_name', "Default Grading Scheme")
    else
      nil
    end
  end

  def score_to_grade(score)
    return nil unless self.grading_standard_enabled? && score
    if grading_standard
      grading_standard.score_to_grade(score)
    else
      GradingStandard.default_instance.score_to_grade(score)
    end
  end

  def active_course_level_observers
    participating_observers.observing_full_course(self.id)
  end

  def participants(opts={})
    participants = []
    by_date = opts[:by_date]
    participants += by_date ? participating_admins_by_date : participating_admins

    students = by_date ? participating_students_by_date : participating_students
    applicable_students = if opts[:excluded_user_ids]
                 students.reject{|p| opts[:excluded_user_ids].include?(p.id)}
               else
                 students
               end

    participants += applicable_students

    if opts[:include_observers]
      participants += User.observing_students_in_course(applicable_students.map(&:id), self.id)
      participants += User.observing_full_course(self.id)
    end

    participants.uniq
  end

  def filter_users_by_permission(users, permission)
    scope = self.enrollments.where(:user_id => users)
    details = RoleOverride.permissions[permission]
    scope = details[:applies_to_concluded] ? scope.not_inactive_by_date : scope.active_or_pending_by_date

    role_user_ids = scope.pluck(:role_id, :user_id)
    role_ids = role_user_ids.map(&:first).uniq

    roles = Role.where(:id => role_ids).to_a
    allowed_role_ids = roles.select{|role| RoleOverride.enabled_for?(self, permission, role, self).include?(:self)}.map(&:id)
    return [] unless allowed_role_ids.any?

    allowed_user_ids = Set.new
    role_user_ids.each{|role_id, user_id| allowed_user_ids << user_id if allowed_role_ids.include?(role_id)}
    users.select{|user| allowed_user_ids.include?(user.id)}
  end

  def enroll_user(user, type='StudentEnrollment', opts={})
    enrollment_state = opts[:enrollment_state]
    enrollment_state ||= 'active' if type == 'ObserverEnrollment' && user.registered?
    section = opts[:section]
    limit_privileges_to_course_section = opts[:limit_privileges_to_course_section] || false
    associated_user_id = opts[:associated_user_id]

    role = opts[:role] || Enrollment.get_built_in_role_for_type(type)

    start_at = opts[:start_at]
    end_at = opts[:end_at]
    self_enrolled = opts[:self_enrolled]
    section ||= self.default_section
    enrollment_state ||= self.available? ? "invited" : "creation_pending"
    if type == 'TeacherEnrollment' || type == 'TaEnrollment' || type == 'DesignerEnrollment'
      enrollment_state = 'invited' if enrollment_state == 'creation_pending'
    else
      enrollment_state = 'creation_pending' if enrollment_state == 'invited' && !self.available?
    end
    Course.unique_constraint_retry do
      if opts[:allow_multiple_enrollments]
        e = self.all_enrollments.where(user_id: user, type: type, role_id: role.id, associated_user_id: associated_user_id, course_section_id: section.id).first
      else
        # order by course_section_id<>section.id so that if there *is* an existing enrollment for this section, we get it (false orders before true)
        e = self.all_enrollments.
          where(user_id: user, type: type, role_id: role.id, associated_user_id: associated_user_id).
          order(Arel.sql("course_section_id<>#{section.id}")).
          first
      end
      if e && (!e.active? || opts[:force_update])
        e.already_enrolled = true
        if e.workflow_state == 'deleted'
          e.sis_batch_id = nil
        end
        e.attributes = {
          :course_section => section,
          :workflow_state => e.is_a?(StudentViewEnrollment) ? 'active' : enrollment_state
        } if e.completed? || e.rejected? || e.deleted? || e.workflow_state != enrollment_state
      end
      # if we're reusing an enrollment and +limit_privileges_to_course_section+ was supplied, apply it
      e.limit_privileges_to_course_section = limit_privileges_to_course_section if e
      # if we're creating a new enrollment, we want to return it as the correct
      # subclass, but without using associations, we need to manually activate
      # sharding. We should probably find a way to go back to using the
      # association here -- just ran out of time.
      self.shard.activate do
        e ||= Enrollment.typed_enrollment(type).new(
          :user => user,
          :course => self,
          :course_section => section,
          :workflow_state => enrollment_state,
          :limit_privileges_to_course_section => limit_privileges_to_course_section)

      end
      e.associated_user_id = associated_user_id
      e.role = role
      e.self_enrolled = self_enrolled
      e.start_at = start_at
      e.end_at = end_at
      if e.changed?
        e.need_touch_user = true if opts[:skip_touch_user]
        transaction do
          # without this, inserting/updating on enrollments will share lock the course, but then
          # it tries to touch the course, which will deadlock with another transaction doing the
          # same thing.
          self.lock!(:no_key_update)
          if opts[:no_notify]
            e.save_without_broadcasting
          else
            e.save
          end
        end
      end
      e.user = user
      self.claim if self.created? && e && e.admin?
      unless opts[:skip_touch_user]
        e.associated_user.try(:touch)
        user.touch
      end
      user.reload
      e
    end
  end

  def enroll_student(user, opts={})
    enroll_user(user, 'StudentEnrollment', opts)
  end

  def self_enroll_student(user, opts = {})
    enrollment = enroll_student(user, opts.merge(:self_enrolled => true))
    enrollment.accept(:force)
    unless opts[:skip_pseudonym]
      new_pseudonym = user.find_or_initialize_pseudonym_for_account(root_account)
      new_pseudonym.save if new_pseudonym && new_pseudonym.changed?
    end
    enrollment
  end

  def enroll_ta(user, opts={})
    enroll_user(user, 'TaEnrollment', opts)
  end

  def enroll_designer(user, opts={})
    enroll_user(user, 'DesignerEnrollment', opts)
  end

  def enroll_teacher(user, opts={})
    enroll_user(user, 'TeacherEnrollment', opts)
  end

  def resubmission_for(asset)
    asset.ignores.where(:purpose => 'grading', :permanent => false).delete_all
    instructors.touch_all
  end

  def grading_standard_enabled
    !!self.grading_standard_id
  end
  alias_method :grading_standard_enabled?, :grading_standard_enabled

  def grading_standard_enabled=(val)
    if Canvas::Plugin.value_to_boolean(val)
      self.grading_standard_id ||= 0
    else
      self.grading_standard = self.grading_standard_id = nil
    end
  end

  def readable_default_wiki_editing_roles
    roles = self.default_wiki_editing_roles || "teachers"
    case roles
    when 'teachers'
      t('wiki_permissions.only_teachers', 'Only Teachers')
    when 'teachers,students'
      t('wiki_permissions.teachers_students', 'Teacher and Students')
    when 'teachers,students,public'
      t('wiki_permissions.all', 'Anyone')
    else
      t('wiki_permissions.only_teachers', 'Only Teachers')
    end
  end

  def default_section(opts = {})
    section = course_sections.active.where(default_section: true).first
    if !section && opts[:include_xlists]
      section = CourseSection.active.where(:nonxlist_course_id => self).order(:id).first
    end
    if !section && !opts[:no_create]
      section = course_sections.build
      section.default_section = true
      section.course = self
      section.root_account_id = self.root_account_id
      Shackles.activate(:master) do
        section.save unless new_record?
      end
    end
    section
  end

  def assert_section
    if self.course_sections.active.empty?
      default = self.default_section
      default.workflow_state = 'active'
      default.save
    end
  end

  def file_structure_for(user)
    User.file_structure_for(self, user)
  end

  def turnitin_settings
    # check if somewhere up the account chain turnitin is enabled and
    # has valid settings
    account.turnitin_settings
  end

  def turnitin_pledge
    self.account.closest_turnitin_pledge
  end

  def turnitin_originality
    self.account.closest_turnitin_originality
  end

  def all_turnitin_comments
    comments = self.account.closest_turnitin_comments || ""
    if self.turnitin_comments && !self.turnitin_comments.empty?
      comments += "\n\n" if comments && !comments.empty?
      comments += self.turnitin_comments
    end
    self.extend TextHelper
    format_message(comments).first
  end

  def turnitin_enabled?
    !!self.turnitin_settings
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

  attr_accessor :merge_results
  def log_merge_result(text)
    @merge_results ||= []
    logger.debug text
    @merge_results << text
  end

  def warn_merge_result(text)
    log_merge_result(text)
  end

  def bool_res(val)
    Canvas::Plugin.value_to_boolean(val)
  end

  attr_accessor :full_migration_hash, :external_url_hash,
                :folder_name_lookups, :assignment_group_no_drop_assignments, :migration_results

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
    old && new && columns.all?{|column|
      old.respond_to?(column) && new.respond_to?(column) && old.send(column) == new.send(column)
    }
  end

  def copy_attachments_from_course(course, options={})
    root_folder = Folder.root_folders(self).first
    root_folder_name = root_folder.name + '/'
    ce = options[:content_export]
    cm = options[:content_migration]

    attachments = course.attachments.where("file_state <> 'deleted'").to_a
    total = attachments.count + 1

    Attachment.skip_media_object_creation do
      attachments.each_with_index do |file, i|
        cm.update_import_progress((i.to_f/total) * 18.0) if cm && (i % 10 == 0)

        if !ce || ce.export_object?(file)
          begin
            migration_id = ce && ce.create_key(file)
            new_file = file.clone_for(self, nil, :overwrite => true, :migration_id => migration_id, :migration => cm, :match_on_migration_id => cm.for_master_course_import?)
            cm.add_attachment_path(file.full_display_path.gsub(/\A#{root_folder_name}/, ''), new_file.migration_id)
            new_folder_id = merge_mapped_id(file.folder)

            if file.folder && file.folder.parent_folder_id.nil?
              new_folder_id = root_folder.id
            end
            # make sure the file has somewhere to go
            if !new_folder_id
              # gather mapping of needed folders from old course to new course
              old_folders = []
              old_folders << file.folder
              new_folders = []
              new_folders << old_folders.last.clone_for(self, nil, options.merge({:include_subcontent => false}))
              while old_folders.last.parent_folder && old_folders.last.parent_folder.parent_folder_id
                old_folders << old_folders.last.parent_folder
                new_folders << old_folders.last.clone_for(self, nil, options.merge({:include_subcontent => false}))
              end
              old_folders.reverse!
              new_folders.reverse!
              # try to use folders that already match if possible
              final_new_folders = []
              parent_folder = Folder.root_folders(self).first
              old_folders.each_with_index do |folder, idx|
                if f = parent_folder.active_sub_folders.where(name: folder.name).first
                  final_new_folders << f
                else
                  final_new_folders << new_folders[idx]
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
            new_file.save_without_broadcasting!
            cm.add_imported_item(new_file)
            map_merge(file, new_file)
          rescue
            cm.add_warning(t(:file_copy_error, "Couldn't copy file \"%{name}\"", :name => file.display_name || file.path_name), $!)
          end
        end
      end
    end
  end

  def self.clonable_attributes
    [ :group_weighting_scheme, :grading_standard_id, :is_public, :public_syllabus,
      :public_syllabus_to_auth, :allow_student_wiki_edits, :show_public_context_messages,
      :syllabus_body, :allow_student_forum_attachments, :lock_all_announcements,
      :default_wiki_editing_roles, :allow_student_organized_groups,
      :default_view, :show_total_grade_as_points,
      :open_enrollment,
      :storage_quota, :tab_configuration, :allow_wiki_comments,
      :turnitin_comments, :self_enrollment, :license, :indexed, :locale,
      :hide_final_grade, :hide_distribution_graphs,
      :allow_student_discussion_topics, :allow_student_discussion_editing, :lock_all_announcements,
      :organize_epub_by_content_type, :show_announcements_on_home_page,
      :home_page_announcement_limit, :enable_offline_web_export,
      :restrict_student_future_view, :restrict_student_past_view
    ]
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
    (self.calendar_events.active + self.assignments.active).inject([]) {|list, e|
      list << e.end_at if e.end_at
      list << e.start_at if e.start_at
      list
    }.compact.flatten.map{|d| d.to_date }.uniq rescue []
  end

  def real_end_date
    return self.conclude_at.to_date if self.conclude_at
    all_dates.max
  end

  def is_a_context?
    true
  end

  def self.serialization_excludes; [:uuid]; end


  ADMIN_TYPES = %w{TeacherEnrollment TaEnrollment DesignerEnrollment}
  def section_visibilities_for(user, opts={})
    RequestCache.cache('section_visibilities_for', user, self, opts) do
      shard.activate do
        Rails.cache.fetch(['section_visibilities_for', user, self, opts].cache_key) do
          workflow_not = opts[:excluded_workflows] || 'deleted'

          enrollment_rows = all_enrollments.
            where(user: user).
            where.not(workflow_state: workflow_not).
            pluck(
              :course_section_id,
              :limit_privileges_to_course_section,
              :type,
              :associated_user_id)

          enrollment_rows.map do |section_id, limit_privileges, type, associated_user_id|
            {
              :course_section_id => section_id,
              :limit_privileges_to_course_section => limit_privileges,
              :type => type,
              :associated_user_id => associated_user_id,
              :admin => ADMIN_TYPES.include?(type)
            }
          end
        end
      end
    end
  end

  def visibility_limited_to_course_sections?(user, visibilities = section_visibilities_for(user))
    visibilities.all?{|s| s[:limit_privileges_to_course_section] }
  end

  # returns a scope, not an array of users/enrollments
  def students_visible_to(user, include: nil)
    include = Array(include)

    if include.include?(:priors_and_deleted)
      scope = self.all_students_including_deleted
    elsif include.include?(:priors)
      scope = self.all_students
    elsif include.include?(:inactive) || include.include?(:completed)
      scope = self.all_accepted_students
      scope = scope.where("enrollments.workflow_state<>'inactive'") unless include.include?(:inactive)
      scope = scope.where("enrollments.workflow_state<>'completed'") unless include.include?(:completed)
    else
      scope = self.students
    end

    self.apply_enrollment_visibility(scope, user, nil, include: include)
  end

  # can apply to user scopes as well if through enrollments (e.g. students, teachers)
  def apply_enrollment_visibility(scope, user, section_ids=nil, include: [])
    include = Array(include)
    if section_ids
      scope = scope.where('enrollments.course_section_id' => section_ids.to_a)
    end

    visibilities = section_visibilities_for(user)
    visibility_level = enrollment_visibility_level_for(user, visibilities)

    # teachers, account admins, and student view students can see student view students
    unless visibility_level == :full ||
        visibilities.any?{|v| v[:admin] || v[:type] == 'StudentViewEnrollment' }
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
    when :sections
      scope.where("enrollments.course_section_id IN (?) OR (enrollments.limit_privileges_to_course_section=? AND enrollments.type IN ('TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment'))",
                  visibilities.map{|s| s[:course_section_id]}, false)
    when :restricted
      user_ids = visibilities.map { |s| s[:associated_user_id] }.compact
      scope.where(enrollments: { user_id: user_ids + [user.id] })
    else
      scope.none
    end
  end

  def users_visible_to(user, include_priors=false, opts={})
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
                                           enrollment_state: opts[:enrollment_state])
  end

  def enrollments_visible_to(user, opts={})
    visibilities = section_visibilities_for(user)
    visibility = enrollment_visibility_level_for(user, visibilities)

    enrollment_scope = opts[:include_concluded] ? enrollments : current_enrollments
    apply_enrollment_visibilities_internal(enrollment_scope.except(:preload), user, visibilities, visibility)
  end

  def apply_enrollment_visibilities_internal(scope, user, visibilities, visibility, enrollment_state: nil)
    scope = scope.where(enrollments: { workflow_state: enrollment_state }) if enrollment_state
    # See also MessageableUsers (same logic used to get users across multiple courses) (should refactor)
    case visibility
    when :full then scope
    when :sections then scope.where(enrollments: { course_section_id: visibilities.map {|s| s[:course_section_id] } })
    when :restricted then scope.where(enrollments: { user_id: (visibilities.map { |s| s[:associated_user_id] }.compact + [user]) })
    when :limited then scope.where(enrollments: { type: ['StudentEnrollment', 'TeacherEnrollment', 'TaEnrollment', 'StudentViewEnrollment'] })
    else scope.none
    end
  end

  # returns :all, :none, or an array of section ids
  def course_section_visibility(user, opts={})
    visibilities = section_visibilities_for(user, opts)
    visibility = enrollment_visibility_level_for(user, visibilities)
    if [:full, :limited, :restricted, :sections].include?(visibility)
      enrollment_types = ['StudentEnrollment', 'StudentViewEnrollment', 'ObserverEnrollment']
      if [:restricted, :sections].include?(visibility) || (
          visibilities.any? && visibilities.all? { |v| enrollment_types.include? v[:type] }
        )
        visibilities.map{ |s| s[:course_section_id] }
      else
        :all
      end
    else
      :none
    end
  end

  def sections_visible_to(user, sections = active_course_sections, opts={})
    is_scope = sections.respond_to?(:where)
    section_ids = course_section_visibility(user, opts)
    case section_ids
    when :all
      sections
    when :none
      # return an empty set, but keep it as a scope for downstream consistency
      is_scope ? sections.none : []
    when Array
      is_scope ? sections.where(:id => section_ids) : sections.select{|section| section_ids.include?(section.id)}
    end
  end

  # derived from policy for Group#grants_right?(user, :read)
  def groups_visible_to(user, groups = active_groups)
    if grants_any_right?(user, :manage_groups, :view_group_pages)
      # course-wide permissions; all groups are visible
      groups
    else
      # no course-wide permissions; only groups the user is a member of are
      # visible
      groups.joins(:participating_group_memberships).
        where('group_memberships.user_id' => user)
    end
  end

  def enrollment_visibility_level_for(user, visibilities = section_visibilities_for(user), require_message_permission = false)
    permissions = require_message_permission ?
      [:send_messages] :
      [:manage_grades, :manage_students, :manage_admin_users, :read_roster, :view_all_grades, :read_as_admin]
    granted_permissions = self.granted_rights(user, *permissions)
    if granted_permissions.empty?
      :restricted # e.g. observer, can only see admins in the course
    elsif visibilities.present? && visibility_limited_to_course_sections?(user, visibilities)
      :sections
    elsif granted_permissions.eql? [:read_roster]
      :limited
    else
      :full
    end
  end

  def invited_count_visible_to(user)
    scope = users_visible_to(user).
      where("enrollments.workflow_state in ('invited', 'creation_pending') AND enrollments.type != 'StudentViewEnrollment'")
    scope.select('users.id').distinct.count
  end

  def published?
    self.available? || self.completed?
  end

  def unpublished?
    self.created? || self.claimed?
  end

  def tab_configuration
    super.map {|h| h.with_indifferent_access } rescue []
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

  def self.default_tabs
    [{
      :id => TAB_HOME,
      :label => t('#tabs.home', "Home"),
      :css_class => 'home',
      :href => :course_path
    }, {
      :id => TAB_ANNOUNCEMENTS,
      :label => t('#tabs.announcements', "Announcements"),
      :css_class => 'announcements',
      :href => :course_announcements_path,
      :icon => 'icon-announcement'
    }, {
      :id => TAB_ASSIGNMENTS,
      :label => t('#tabs.assignments', "Assignments"),
      :css_class => 'assignments',
      :href => :course_assignments_path,
      :icon => 'icon-assignment'
    }, {
      :id => TAB_DISCUSSIONS,
      :label => t('#tabs.discussions', "Discussions"),
      :css_class => 'discussions',
      :href => :course_discussion_topics_path,
      :icon => 'icon-discussion'
    }, {
      :id => TAB_GRADES,
      :label => t('#tabs.grades', "Grades"),
      :css_class => 'grades',
      :href => :course_grades_path,
    }, {
      :id => TAB_PEOPLE,
      :label => t('#tabs.people', "People"),
      :css_class => 'people',
      :href => :course_users_path
    }, {
      :id => TAB_PAGES,
      :label => t('#tabs.pages', "Pages"),
      :css_class => 'pages',
      :href => :course_wiki_path
    }, {
      :id => TAB_FILES,
      :label => t('#tabs.files', "Files"),
      :css_class => 'files',
      :href => :course_files_path,
      :icon => 'icon-folder'
    }, {
      :id => TAB_SYLLABUS,
      :label => t('#tabs.syllabus', "Syllabus"),
      :css_class => 'syllabus',
      :href => :syllabus_course_assignments_path
    }, {
      :id => TAB_OUTCOMES,
      :label => t('#tabs.outcomes', "Outcomes"),
      :css_class => 'outcomes',
      :href => :course_outcomes_path
    }, {
      :id => TAB_QUIZZES,
      :label => t('#tabs.quizzes', "Quizzes"),
      :css_class => 'quizzes',
      :href => :course_quizzes_path
    }, {
      :id => TAB_MODULES,
      :label => t('#tabs.modules', "Modules"),
      :css_class => 'modules',
      :href => :course_context_modules_path
    }, {
      :id => TAB_CONFERENCES,
      :label => t('#tabs.conferences', "Conferences"),
      :css_class => 'conferences',
      :href => :course_conferences_path
    }, {
      :id => TAB_COLLABORATIONS,
      :label => t('#tabs.collaborations', "Collaborations"),
      :css_class => 'collaborations',
      :href => :course_collaborations_path
    }, {
      :id => TAB_COLLABORATIONS_NEW,
      :label => t('#tabs.collaborations', "Collaborations"),
      :css_class => 'collaborations',
      :href => :course_lti_collaborations_path
    }, {
      :id => TAB_SETTINGS,
      :label => t('#tabs.settings', "Settings"),
      :css_class => 'settings',
      :href => :course_settings_path,
    }]
  end

  def tab_hidden?(id)
    tab = self.tab_configuration.find{|t| t[:id] == id}
    return tab && tab[:hidden]
  end

  def external_tool_tabs(opts)
    tools = self.context_external_tools.active.having_setting('course_navigation')
    tools += ContextExternalTool.active.having_setting('course_navigation').where(context_type: 'Account', context_id: account_chain_ids).to_a
    Lti::ExternalToolTab.new(self, :course_navigation, tools, opts[:language]).tabs
  end

  def tabs_available(user=nil, opts={})
    opts.reverse_merge!(:include_external => true)
    cache_key = [user, opts].cache_key
    @tabs_available ||= {}
    @tabs_available[cache_key] ||= uncached_tabs_available(user, opts)
  end

  def uncached_tabs_available(user, opts)
    # make sure t() is called before we switch to the slave, in case we update the user's selected locale in the process
    default_tabs = Course.default_tabs

    Shackles.activate(:slave) do
      # We will by default show everything in default_tabs, unless the teacher has configured otherwise.
      tabs = self.tab_configuration.compact
      settings_tab = default_tabs[-1]
      external_tabs = if opts[:include_external]
                        external_tool_tabs(opts) + Lti::MessageHandler.lti_apps_tabs(self, [Lti::ResourcePlacement::COURSE_NAVIGATION], opts)
                      else
                        []
                      end
      tabs = tabs.map do |tab|
        default_tab = default_tabs.find {|t| t[:id] == tab[:id] } || external_tabs.find{|t| t[:id] == tab[:id] }
        if default_tab
          tab[:label] = default_tab[:label]
          tab[:href] = default_tab[:href]
          tab[:css_class] = default_tab[:css_class]
          tab[:args] = default_tab[:args]
          tab[:visibility] = default_tab[:visibility]
          tab[:external] = default_tab[:external]
          tab[:icon] = default_tab[:icon]
          tab[:target] = default_tab[:target] if default_tab[:target]
          default_tabs.delete_if {|t| t[:id] == tab[:id] }
          external_tabs.delete_if {|t| t[:id] == tab[:id] }
          tab
        end
      end
      tabs.compact!
      tabs += default_tabs
      tabs += external_tabs
      # Ensure that Settings is always at the bottom
      tabs.delete_if {|t| t[:id] == TAB_SETTINGS }
      tabs << settings_tab

      tabs.each do |tab|
        tab[:hidden_unused] = true if tab[:id] == TAB_MODULES && !active_record_types[:modules]
        tab[:hidden_unused] = true if tab[:id] == TAB_FILES && !active_record_types[:files]
        tab[:hidden_unused] = true if tab[:id] == TAB_QUIZZES && !active_record_types[:quizzes]
        tab[:hidden_unused] = true if tab[:id] == TAB_ASSIGNMENTS && !active_record_types[:assignments]
        tab[:hidden_unused] = true if tab[:id] == TAB_PAGES && !active_record_types[:pages] && !allow_student_wiki_edits
        tab[:hidden_unused] = true if tab[:id] == TAB_CONFERENCES && !active_record_types[:conferences] && !self.grants_right?(user, :create_conferences)
        tab[:hidden_unused] = true if tab[:id] == TAB_ANNOUNCEMENTS && !active_record_types[:announcements]
        tab[:hidden_unused] = true if tab[:id] == TAB_OUTCOMES && !active_record_types[:outcomes]
        tab[:hidden_unused] = true if tab[:id] == TAB_DISCUSSIONS && !active_record_types[:discussions] && !allow_student_discussion_topics
      end

      # remove tabs that the user doesn't have access to
      unless opts[:for_reordering]
        unless self.grants_any_right?(user, opts[:session], :read, :manage_content)
          tabs.delete_if { |t| t[:id] == TAB_HOME }
          tabs.delete_if { |t| t[:id] == TAB_ANNOUNCEMENTS }
          tabs.delete_if { |t| t[:id] == TAB_PAGES }
          tabs.delete_if { |t| t[:id] == TAB_OUTCOMES }
          tabs.delete_if { |t| t[:id] == TAB_CONFERENCES }
          tabs.delete_if { |t| t[:id] == TAB_COLLABORATIONS }
          tabs.delete_if { |t| t[:id] == TAB_MODULES }
        end
        unless self.grants_any_right?(user, opts[:session], :participate_as_student, :read_as_admin)
          tabs.delete_if{ |t| t[:visibility] == 'members' }
        end
        unless self.grants_any_right?(user, opts[:session], :read, :manage_content, :manage_assignments)
          tabs.delete_if { |t| t[:id] == TAB_ASSIGNMENTS }
          tabs.delete_if { |t| t[:id] == TAB_QUIZZES }
        end
        unless self.grants_any_right?(user, opts[:session], :read, :read_syllabus, :manage_content, :manage_assignments)
          tabs.delete_if { |t| t[:id] == TAB_SYLLABUS }
        end
        tabs.delete_if{ |t| t[:visibility] == 'admins' } unless self.grants_right?(user, opts[:session], :read_as_admin)
        if self.grants_any_right?(user, opts[:session], :manage_content, :manage_assignments)
          tabs.detect { |t| t[:id] == TAB_ASSIGNMENTS }[:manageable] = true
          tabs.detect { |t| t[:id] == TAB_SYLLABUS }[:manageable] = true
          tabs.detect { |t| t[:id] == TAB_QUIZZES }[:manageable] = true
        end
        tabs.delete_if { |t| t[:hidden] && t[:external] } unless opts[:api] && self.grants_right?(user,  :read_as_admin)
        tabs.delete_if { |t| t[:id] == TAB_GRADES } unless self.grants_any_right?(user, opts[:session], :read_grades, :view_all_grades, :manage_grades)
        tabs.detect { |t| t[:id] == TAB_GRADES }[:manageable] = true if self.grants_any_right?(user, opts[:session], :view_all_grades, :manage_grades)
        tabs.delete_if { |t| t[:id] == TAB_PEOPLE } unless self.grants_any_right?(user, opts[:session], :read_roster, :manage_students, :manage_admin_users)
        tabs.detect { |t| t[:id] == TAB_PEOPLE }[:manageable] = true if self.grants_any_right?(user, opts[:session], :manage_students, :manage_admin_users)
        tabs.delete_if { |t| t[:id] == TAB_FILES } unless self.grants_any_right?(user, opts[:session], :read, :manage_files)
        tabs.detect { |t| t[:id] == TAB_FILES }[:manageable] = true if self.grants_right?(user, opts[:session], :manage_files)
        tabs.delete_if { |t| t[:id] == TAB_DISCUSSIONS } unless self.grants_any_right?(user, opts[:session], :read_forum, :moderate_forum, :post_to_forum)
        tabs.detect { |t| t[:id] == TAB_DISCUSSIONS }[:manageable] = true if self.grants_right?(user, opts[:session], :moderate_forum)
        tabs.delete_if { |t| t[:id] == TAB_SETTINGS } unless self.grants_right?(user, opts[:session], :read_as_admin)

        unless announcements.temp_record.grants_right?(user, :read)
          tabs.delete_if { |t| t[:id] == TAB_ANNOUNCEMENTS }
        end

        if !user || !self.grants_right?(user, :manage_content)
          # remove outcomes tab for logged-out users or non-students
          unless grants_any_right?(user, :read_as_admin, :participate_as_student)
            tabs.delete_if { |t| t[:id] == TAB_OUTCOMES }
          end

          # remove hidden tabs from students
          unless self.grants_right?(user, opts[:session], :read_as_admin)
            tabs.delete_if {|t| (t[:hidden] || (t[:hidden_unused] && !opts[:include_hidden_unused])) && !t[:manageable] }
          end
        end
      end
      # Uncommenting these lines will always put hidden links after visible links
      # tabs.each_with_index{|t, i| t[:sort_index] = i }
      # tabs = tabs.sort_by{|t| [t[:hidden_unused] || t[:hidden] ? 1 : 0, t[:sort_index]] } if !self.tab_configuration || self.tab_configuration.empty?
      tabs
    end
  end

  def allow_wiki_comments
    read_attribute(:allow_wiki_comments)
  end

  def account_name
    self.account.name rescue nil
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
    cast_expression = "val.to_s"
    cast_expression = "val" if opts[:arbitrary]
    if opts[:boolean]
      opts[:default] ||= false
      cast_expression = "Canvas::Plugin.value_to_boolean(val)"
    end
    class_eval <<-CODE, __FILE__, __LINE__ + 1
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
          settings_frd[#{setting.inspect}] = new_val
        end
      end
    CODE
    alias_method "#{setting}?", setting if opts[:boolean]
    if opts[:alias]
      alias_method opts[:alias], setting
      alias_method "#{opts[:alias]}=", "#{setting}="
      alias_method "#{opts[:alias]}?", "#{setting}?"
    end
  end

  # unfortunately we decided to pluralize this in the API after the fact...
  # so now we pluralize it everywhere except the actual settings hash and
  # course import/export :(
  add_setting :hide_final_grade, :alias => :hide_final_grades, :boolean => true
  add_setting :hide_distribution_graphs, :boolean => true
  add_setting :allow_student_discussion_topics, :boolean => true, :default => true
  add_setting :allow_student_discussion_editing, :boolean => true, :default => true
  add_setting :show_total_grade_as_points, :boolean => true, :default => false
  add_setting :lock_all_announcements, :boolean => true, :default => false, :inherited => true
  add_setting :large_roster, :boolean => true, :default => lambda { |c| c.root_account.large_course_rosters? }
  add_setting :public_syllabus, :boolean => true, :default => false
  add_setting :public_syllabus_to_auth, :boolean => true, :default => false
  add_setting :course_format
  add_setting :image_id
  add_setting :image_url
  add_setting :organize_epub_by_content_type, :boolean => true, :default => false
  add_setting :enable_offline_web_export, :boolean => true, :default => lambda { |c| c.account.enable_offline_web_export? }
  add_setting :is_public_to_auth_users, :boolean => true, :default => false

  add_setting :restrict_student_future_view, :boolean => true, :inherited => true
  add_setting :restrict_student_past_view, :boolean => true, :inherited => true

  add_setting :timetable_data, :arbitrary => true
  add_setting :syllabus_master_template_id

  def user_can_manage_own_discussion_posts?(user)
    return true if allow_student_discussion_editing?
    return true if user_is_instructor?(user)
    false
  end

  def filter_attributes_for_user(hash, user, session)
    hash.delete('hide_final_grades') if hash.key?('hide_final_grades') && !grants_right?(user, :update)
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
    Course.transaction do
      new_course = Course.new
      self.attributes.delete_if{|k,v| [:id, :created_at, :updated_at, :syllabus_body, :wiki_id, :default_view, :tab_configuration, :lti_context_id, :workflow_state].include?(k.to_sym) }.each do |key, val|
        new_course.write_attribute(key, val)
      end
      new_course.workflow_state = (self.admins.any? ? 'claimed' : 'created')
      # there's a unique constraint on this, so we need to clear it out
      self.self_enrollment_code = nil
      self.self_enrollment = false
      # The order here is important; we have to set our sis id to nil and save first
      # so that the new course can be saved, then we need the new course saved to
      # get its id to move over sections and enrollments.  Setting this course to
      # deleted has to be last otherwise it would set all the enrollments to
      # deleted before they got moved
      self.uuid = self.sis_source_id = self.sis_batch_id = self.integration_id = nil;
      self.save!
      Course.process_as_sis { new_course.save! }
      self.course_sections.update_all(:course_id => new_course.id)
      # we also want to bring along prior enrollments, so don't use the enrollments
      # association
      Enrollment.where(:course_id => self).update_all(:course_id => new_course.id, :updated_at => Time.now.utc)
      User.where(id: new_course.all_enrollments.select(:user_id)).
          update_all(updated_at: Time.now.utc)
      self.replacement_course_id = new_course.id
      self.workflow_state = 'deleted'
      self.save!
      unless profile.new_record?
        profile.update_attribute(:context, new_course)
      end

      Course.find(new_course.id)
    end
  end

  def user_list_search_mode_for(user)
    if self.root_account.open_registration?
      return self.root_account.delegated_authentication? ? :preferred : :open
    end
    return :preferred if self.root_account.grants_right?(user, :manage_user_logins)
    :closed
  end

  def default_home_page
    "modules"
  end

  def participating_users(user_ids)
    User.where(:id => self.enrollments.active_by_date.where(:user_id => user_ids).select(:user_id))
  end

  def student_view_student
    fake_student = find_or_create_student_view_student
    fake_student = sync_enrollments(fake_student)
    fake_student
  end

  # part of the way we isolate this fake student from places we don't want it
  # to appear is to ensure that it does not have a pseudonym or any
  # account_associations. if either of these conditions is false, something is
  # wrong.
  def find_or_create_student_view_student
    if self.student_view_students.active.count == 0
      fake_student = nil
      User.skip_updating_account_associations do
        fake_student = User.new(:name => t('student_view_student_name', "Test Student"))
        fake_student.preferences[:fake_student] = true
        fake_student.workflow_state = 'registered'
        fake_student.save
        # hash the unique_id so that it's hard to accidently enroll the user in
        # a course by entering something in a user list. :(
        fake_student.pseudonyms.create!(:account => self.root_account,
                                        :unique_id => Canvas::Security.hmac_sha1("Test Student_#{fake_student.id}"))
      end
      fake_student
    else
      self.student_view_students.active.first
    end
  end
  private :find_or_create_student_view_student

  # we want to make sure the student view student is always enrolled in all the
  # sections of the course, so that a section limited teacher can grade them.
  def sync_enrollments(fake_student)
    self.default_section unless course_sections.active.any?
    Enrollment.suspend_callbacks(:set_update_cached_due_dates) do
      self.course_sections.active.each do |section|
        # enroll fake_student will only create the enrollment if it doesn't already exist
        self.enroll_user(fake_student, 'StudentViewEnrollment',
                         :allow_multiple_enrollments => true,
                         :section => section,
                         :enrollment_state => 'active',
                         :no_notify => true,
                         :skip_touch_user => true)
      end
    end
    DueDateCacher.recompute_users_for_course(fake_student.id, self)
    fake_student
  end
  private :sync_enrollments

  def associated_shards
    [Shard.default]
  end

  def includes_student?(user)
    includes_user?(user, student_enrollments)
  end

  def includes_user?(user, enrollment_scope=enrollments)
    return false if user.nil? || user.new_record?
    enrollment_scope.where(user_id: user).exists?
  end

  def update_one(update_params, user, update_source = :manual)
    options = { source: update_source }

    case update_params[:event]
      when 'offer'
        if self.completed?
          self.unconclude!
          Auditors::Course.record_unconcluded(self, user, options)
        else
          unless self.available?
            self.offer!
            Auditors::Course.record_published(self, user, options)
          end
        end
      when 'conclude'
        unless self.completed?
          self.complete!
          Auditors::Course.record_concluded(self, user, options)
        end
      when 'delete'
        self.sis_source_id = nil
        self.workflow_state = 'deleted'
        self.save!
        Auditors::Course.record_deleted(self, user, options)
      when 'undelete'
        self.workflow_state = 'claimed'
        self.save!
        Auditors::Course.record_restored(self, user, options)
    end
  end

  def self.do_batch_update(progress, user, course_ids, update_params, update_source = :manual)
    account = progress.context
    progress_runner = ProgressRunner.new(progress)

    progress_runner.completed_message do |completed_count|
      t('batch_update_message', {
          :one => "1 course processed",
          :other => "%{count} courses processed"
        },
        :count => completed_count)
    end

    progress_runner.do_batch_update(course_ids) do |course_id|
      course = account.associated_courses.where(id: course_id).first
      raise t('course_not_found', "The course was not found") unless course &&
          (course.workflow_state != 'deleted' || update_params[:event] == 'undelete')
      raise t('access_denied', "Access was denied") unless course.grants_right? user, :update
      course.update_one(update_params, user, update_source)
    end

  end

  def self.batch_update(account, user, course_ids, update_params, update_source = :manual)
    progress = account.progresses.create! :tag => "course_batch_update", :completion => 0.0
    job = Course.send_later_enqueue_args(:do_batch_update,
                                         { no_delay: true },
                                         progress, user, course_ids, update_params, update_source)
    progress.user_id = user.id
    progress.delayed_job_id = job.id
    progress.save!
    progress
  end

  def re_send_invitations!(from_user)
    self.apply_enrollment_visibility(self.student_enrollments, from_user).invited.except(:preload).preload(user: :communication_channels).find_each do |e|
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
    @section_count ||= self.active_course_sections.count
  end

  def multiple_sections?
    active_section_count > 1
  end

  def content_exports_visible_to(user)
    if self.grants_right?(user, :read_as_admin)
      self.content_exports.admin(user)
    else
      self.content_exports.non_admin(user)
    end
  end

  %w{student_count primary_enrollment_type primary_enrollment_role_id primary_enrollment_rank primary_enrollment_state primary_enrollment_date invitation}.each do |method|
    class_eval <<-RUBY
      def #{method}
        read_attribute(:#{method}) || @#{method}
      end
    RUBY
  end

  def touch_content_if_public_visibility_changed(changes)
    if changes[:is_public] || changes[:is_public_to_auth_users]
      self.assignments.touch_all
      self.attachments.touch_all
      self.calendar_events.touch_all
      self.context_modules.touch_all
      self.discussion_topics.touch_all
      self.quizzes.touch_all
      self.wiki.touch
      self.wiki_pages.touch_all
    end
  end

  def touch_admins_later
    send_later_enqueue_args(:touch_admins, { :run_at => 15.seconds.from_now, :singleton => "course_touch_admins_#{global_id}" })
  end

  def touch_admins
    User.where(id: self.admins).touch_all
  end

  def touch_students_if_necessary
    # to update the cached current enrollments
    if saved_change_to_workflow_state? && (workflow_state == 'available' || workflow_state_before_last_save == 'available')
      touch_students_later if self.students.exists?
    end
  end

  def touch_students_later
    send_later_enqueue_args(:touch_students, { :run_at => 15.seconds.from_now, :singleton => "course_touch_students_#{global_id}" })
  end

  def touch_students
    User.where(id: self.students).touch_all
  end

  def list_students_by_sortable_name?
    feature_enabled?(:gradebook_list_students_by_sortable_name)
  end

  ##
  # Returns a boolean describing if the user passed in has marked this course
  # as a favorite.
  def favorite_for_user?(user)
    user.favorites.where(:context_type => 'Course', :context_id => self).exists?
  end

  def nickname_for(user, fallback = :name)
    nickname = user && user.course_nickname(self)
    nickname ||= self.send(fallback) if fallback
    nickname
  end

  def refresh_content_participation_counts(_progress)
    content_participation_counts.each(&:refresh_unread_count)
  end

  def name
    return @nickname if @nickname
    read_attribute(:name)
  end

  def apply_nickname_for!(user)
    @nickname = nickname_for(user, nil)
  end

  def any_assignment_in_closed_grading_period?
    effective_due_dates.any_in_closed_grading_period?
  end

  def relevant_grading_period_group
    return @relevant_grading_period_group if defined?(@relevant_grading_period_group)

    @relevant_grading_period_group = grading_period_groups.detect { |gpg| gpg.workflow_state == 'active' }
    return @relevant_grading_period_group unless @relevant_grading_period_group.nil?

    if enrollment_term.grading_period_group&.workflow_state == 'active'
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

    @has_weighted_grading_periods = grading_period_groups.to_a.none? { |gpg| gpg.workflow_state == 'active' } &&
      !!relevant_grading_period_group&.weighted?
  end

  def quiz_lti_tool
    query = { tool_id: 'Quizzes 2' }
    context_external_tools.active.find_by(query) ||
      account.context_external_tools.active.find_by(query) ||
        root_account.context_external_tools.active.find_by(query)
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
    return true if late_policy&.missing_submission_deduction_enabled? || late_policy&.late_submission_deduction_enabled?

    # If you've used the grade tray status changes at all, you can't
    # go back. Even if set to none, it'll break "Message Students
    # Who..." for unsubmitted.
    expire_time = Setting.get('late_policy_tainted_submissions', 1.hour).to_i
    Rails.cache.fetch(['late_policy_tainted_submissions', self].cache_key, expires_in: expire_time) do
      submissions.except(:order).where(late_policy_status: ['missing', 'late', 'none']).exists?
    end
  end

  def grading_standard_or_default
    default_grading_standard || GradingStandard.default_instance
  end

  def moderators
    active_instructors = users.merge(Enrollment.active_or_pending.of_instructor_type)
    active_instructors.select { |user| grants_right?(user, :select_final_grade) }
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

  private

  def effective_due_dates
    @effective_due_dates ||= EffectiveDueDates.for_course(self)
  end
end
