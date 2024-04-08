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

class Account < ActiveRecord::Base
  include Context
  include OutcomeImportContext
  include Pronouns
  include SearchTermHelper

  INSTANCE_GUID_SUFFIX = "canvas-lms"
  CALENDAR_SUBSCRIPTION_TYPES = %w[manual auto].freeze

  include Workflow
  include BrandConfigHelpers
  belongs_to :root_account, class_name: "Account"
  belongs_to :parent_account, class_name: "Account"

  # temporary scope to allow us to deprecate the faculty journal feature. should be removed (along with all references) upon deprecation completion
  scope :having_user_notes_enabled, -> { Account.site_admin.feature_enabled?(:deprecate_faculty_journal) ? Account.none : where(enable_user_notes: true) }

  has_many :courses
  has_many :custom_grade_statuses, inverse_of: :root_account, foreign_key: :root_account_id
  has_many :standard_grade_statuses, inverse_of: :root_account, foreign_key: :root_account_id
  has_many :favorites, inverse_of: :root_account
  has_many :all_courses, class_name: "Course", foreign_key: "root_account_id"
  has_one :terms_of_service, dependent: :destroy
  has_one :terms_of_service_content, dependent: :destroy
  has_many :group_categories, -> { where(deleted_at: nil) }, as: :context, inverse_of: :context
  has_many :all_group_categories, class_name: "GroupCategory", foreign_key: "root_account_id", inverse_of: :root_account
  has_many :groups, as: :context, inverse_of: :context
  has_many :all_groups, class_name: "Group", foreign_key: "root_account_id", inverse_of: :root_account
  has_many :all_group_memberships, source: "group_memberships", through: :all_groups
  has_many :enrollment_terms, foreign_key: "root_account_id"
  has_many :active_enrollment_terms, -> { where("enrollment_terms.workflow_state<>'deleted'") }, class_name: "EnrollmentTerm", foreign_key: "root_account_id"
  has_many :grading_period_groups, inverse_of: :root_account, dependent: :destroy
  has_many :grading_periods, through: :grading_period_groups
  has_many :enrollments, -> { where("enrollments.type<>'StudentViewEnrollment'") }, foreign_key: "root_account_id"
  has_many :all_enrollments, class_name: "Enrollment", foreign_key: "root_account_id"
  has_many :temporary_enrollment_pairings, inverse_of: :root_account, foreign_key: "root_account_id"
  has_many :sub_accounts, -> { where("workflow_state<>'deleted'") }, class_name: "Account", foreign_key: "parent_account_id"
  has_many :all_accounts, -> { order(:name) }, class_name: "Account", foreign_key: "root_account_id"
  has_many :account_users, dependent: :destroy
  has_many :active_account_users, -> { active }, class_name: "AccountUser"
  has_many :course_sections, foreign_key: "root_account_id"
  has_many :sis_batches
  has_many :abstract_courses, class_name: "AbstractCourse"
  has_many :root_abstract_courses, class_name: "AbstractCourse", foreign_key: "root_account_id"
  has_many :user_account_associations
  has_many :all_users, -> { distinct }, through: :user_account_associations, source: :user
  has_many :users, through: :active_account_users
  has_many :user_past_lti_ids, as: :context, inverse_of: :context
  has_many :pseudonyms, -> { preload(:user) }, inverse_of: :account
  has_many :deleted_users, -> { where(pseudonyms: { workflow_state: "deleted" }) }, through: :pseudonyms, source: :user
  has_many :role_overrides, as: :context, inverse_of: :context
  has_many :course_account_associations
  has_many :child_courses, -> { where(course_account_associations: { depth: 0 }) }, through: :course_account_associations, source: :course
  has_many :attachments, as: :context, inverse_of: :context, dependent: :destroy
  has_many :active_assignments, -> { where("assignments.workflow_state<>'deleted'") }, as: :context, inverse_of: :context, class_name: "Assignment"
  has_many :folders, -> { order("folders.name") }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :active_folders, -> { where("folder.workflow_state<>'deleted'").order("folders.name") }, class_name: "Folder", as: :context, inverse_of: :context
  has_many :developer_keys
  has_many :developer_key_account_bindings, inverse_of: :account, dependent: :destroy
  has_many :authentication_providers,
           -> { ordered },
           inverse_of: :account,
           extend: AuthenticationProvider::FindWithType
  has_many :calendar_events, -> { where("calendar_events.workflow_state<>'cancelled'") }, as: :context, inverse_of: :context, dependent: :destroy

  has_many :account_reports, inverse_of: :account
  has_many :grading_standards, -> { where("workflow_state<>'deleted'") }, as: :context, inverse_of: :context
  has_many :assessment_question_banks, -> { preload(:assessment_questions, :assessment_question_bank_users) }, as: :context, inverse_of: :context
  has_many :assessment_questions, through: :assessment_question_banks
  has_many :roles
  has_many :all_roles, class_name: "Role", foreign_key: "root_account_id"
  has_many :progresses, as: :context, inverse_of: :context
  has_many :content_migrations, as: :context, inverse_of: :context
  has_many :sis_batch_errors, foreign_key: :root_account_id, inverse_of: :root_account
  has_many :canvadocs_annotation_contexts
  has_one :outcome_proficiency, -> { preload(:outcome_proficiency_ratings) }, as: :context, inverse_of: :context, dependent: :destroy
  has_one :outcome_calculation_method, as: :context, inverse_of: :context, dependent: :destroy

  has_many :auditor_authentication_records,
           class_name: "Auditors::ActiveRecord::AuthenticationRecord",
           dependent: :destroy,
           inverse_of: :account
  has_many :auditor_course_records,
           class_name: "Auditors::ActiveRecord::CourseRecord",
           dependent: :destroy,
           inverse_of: :account
  has_many :auditor_grade_change_records,
           class_name: "Auditors::ActiveRecord::GradeChangeRecord",
           dependent: :destroy,
           inverse_of: :account
  has_many :auditor_root_grade_change_records,
           foreign_key: "root_account_id",
           class_name: "Auditors::ActiveRecord::GradeChangeRecord",
           dependent: :destroy,
           inverse_of: :root_account
  has_many :auditor_feature_flag_records,
           foreign_key: "root_account_id",
           class_name: "Auditors::ActiveRecord::FeatureFlagRecord",
           dependent: :destroy,
           inverse_of: :root_account
  has_many :auditor_pseudonym_records,
           foreign_key: "root_account_id",
           class_name: "Auditors::ActiveRecord::PseudonymRecord",
           inverse_of: :root_account
  has_many :lti_resource_links,
           as: :context,
           inverse_of: :context,
           class_name: "Lti::ResourceLink",
           dependent: :destroy
  belongs_to :course_template, class_name: "Course", inverse_of: :templated_accounts
  belongs_to :grading_standard

  def inherited_assessment_question_banks(include_self = false, *additional_contexts)
    sql, conds = [], []
    contexts = additional_contexts + account_chain
    contexts.delete(self) unless include_self
    contexts.each do |c|
      sql << "context_type = ? AND context_id = ?"
      conds += [c.class.to_s, c.id]
    end
    conds.unshift(sql.join(" OR "))
    AssessmentQuestionBank.where(conds)
  end

  include LearningOutcomeContext
  include RubricContext

  has_many :context_external_tools, -> { order(:name) }, as: :context, inverse_of: :context, dependent: :destroy
  has_many :error_reports
  has_many :announcements, class_name: "AccountNotification"
  has_many :alerts, -> { preload(:criteria) }, as: :context, inverse_of: :context
  has_many :report_snapshots
  has_many :external_integration_keys, as: :context, inverse_of: :context, dependent: :destroy
  has_many :shared_brand_configs
  belongs_to :brand_config, foreign_key: "brand_config_md5"
  has_many :blackout_dates, as: :context, inverse_of: :context

  before_validation :verify_unique_sis_source_id
  before_save :ensure_defaults
  before_save :remove_template_id, if: ->(a) { a.workflow_state_changed? && a.deleted? }
  before_create :enable_sis_imports, if: :root_account?
  after_save :update_account_associations_if_changed
  after_save :check_downstream_caches

  before_save :setup_cache_invalidation
  after_save :invalidate_caches_if_changed
  after_update :clear_special_account_cache_if_special

  after_update :clear_cached_short_name, if: :saved_change_to_name?

  after_update :log_rqd_setting_enable_or_disable

  after_create :create_default_objects

  serialize :settings, type: Hash
  include TimeZoneHelper

  time_zone_attribute :default_time_zone, default: "America/Denver"
  def default_time_zone
    if read_attribute(:default_time_zone) || root_account?
      super
    else
      root_account.default_time_zone
    end
  end
  alias_method :time_zone, :default_time_zone

  validates_locale :default_locale, allow_nil: true
  validates :name, length: { maximum: maximum_string_length, allow_blank: true }
  validate :account_chain_loop, if: :parent_account_id_changed?
  validate :validate_auth_discovery_url
  validates :workflow_state, presence: true
  validate :no_active_courses, if: ->(a) { a.workflow_state_changed? && !a.active? }
  validate :no_active_sub_accounts, if: ->(a) { a.workflow_state_changed? && !a.active? }
  validate :validate_help_links, if: ->(a) { a.settings_changed? }
  validate :validate_course_template, if: ->(a) { a.has_attribute?(:course_template_id) && a.course_template_id_changed? }
  validates :account_calendar_subscription_type, inclusion: { in: CALENDAR_SUBSCRIPTION_TYPES }

  include StickySisFields
  are_sis_sticky :name, :parent_account_id

  include FeatureFlags
  def feature_flag_cache
    MultiCache.cache
  end

  def self.recursive_default_locale_for_id(account_id)
    local_id, shard = Shard.local_id_for(account_id)
    (shard || Shard.current).activate do
      obj = Account.new(id: local_id) # someday i should figure out a better way to avoid instantiating an object instead of tricking cache register
      Rails.cache.fetch_with_batched_keys("default_locale_for_id", batch_object: obj, batched_keys: [:account_chain, :default_locale]) do
        # couldn't find the cache so now we actually need to find the account
        acc = Account.find(local_id)
        acc.default_locale || (acc.parent_account_id && recursive_default_locale_for_id(acc.parent_account_id))
      end
    end
  end

  def default_locale
    result = read_attribute(:default_locale)
    result = nil unless I18n.locale_available?(result)
    result
  end

  def resolved_outcome_proficiency
    cache_key = ["outcome_proficiency", cache_key(:resolved_outcome_proficiency), cache_key(:account_chain)].cache_key
    Rails.cache.fetch(cache_key) do
      if outcome_proficiency&.active?
        outcome_proficiency
      elsif parent_account
        parent_account.resolved_outcome_proficiency
      elsif feature_enabled?(:account_level_mastery_scales)
        OutcomeProficiency.find_or_create_default!(self)
      end
    end
  end

  def resolved_outcome_calculation_method
    cache_key = ["outcome_calculation_method", cache_key(:resolved_outcome_calculation_method), cache_key(:account_chain)].cache_key
    Rails.cache.fetch(cache_key) do
      if outcome_calculation_method&.active?
        outcome_calculation_method
      elsif parent_account
        parent_account.resolved_outcome_calculation_method
      elsif feature_enabled?(:account_level_mastery_scales)
        OutcomeCalculationMethod.find_or_create_default!(self)
      end
    end
  end

  def allow_student_anonymous_discussion_topics
    false
  end

  include ::Account::Settings
  include ::Csp::AccountHelper

  # these settings either are or could be easily added to
  # the account settings page
  add_setting :sis_app_token, root_only: true
  add_setting :sis_app_url, root_only: true
  add_setting :sis_name, root_only: true
  add_setting :sis_syncing, boolean: true, default: false, inheritable: true
  add_setting :sis_default_grade_export, boolean: true, default: false, inheritable: true
  add_setting :include_integration_ids_in_gradebook_exports, boolean: true, default: false, root_only: true
  add_setting :sis_require_assignment_due_date, boolean: true, default: false, inheritable: true
  add_setting :sis_assignment_name_length, boolean: true, default: false, inheritable: true
  add_setting :sis_assignment_name_length_input, inheritable: true

  add_setting :global_includes, root_only: true, boolean: true, default: false
  add_setting :sub_account_includes, boolean: true, default: false
  add_setting :restrict_quantitative_data, boolean: true, default: false, inheritable: true

  # Microsoft Sync Account Settings
  add_setting :microsoft_sync_enabled, root_only: true, boolean: true, default: false
  add_setting :microsoft_sync_tenant, root_only: true
  add_setting :microsoft_sync_login_attribute, root_only: true
  add_setting :microsoft_sync_login_attribute_suffix, root_only: true
  add_setting :microsoft_sync_remote_attribute, root_only: true

  # Help link settings
  add_setting :custom_help_links, root_only: true
  add_setting :new_custom_help_links, root_only: true
  add_setting :help_link_icon, root_only: true
  add_setting :help_link_name, root_only: true
  add_setting :support_url, root_only: true

  add_setting :prevent_course_renaming_by_teachers, boolean: true, root_only: true
  add_setting :prevent_course_availability_editing_by_teachers, boolean: true, root_only: true
  add_setting :login_handle_name, root_only: true
  add_setting :change_password_url, root_only: true
  add_setting :unknown_user_url, root_only: true
  add_setting :fft_registration_url, root_only: true

  add_setting :restrict_student_future_view, boolean: true, default: false, inheritable: true
  add_setting :restrict_student_future_listing, boolean: true, default: false, inheritable: true
  add_setting :restrict_student_past_view, boolean: true, default: false, inheritable: true

  add_setting :teachers_can_create_courses, boolean: true, root_only: true, default: false
  add_setting :students_can_create_courses, boolean: true, root_only: true, default: false
  add_setting :no_enrollments_can_create_courses, boolean: true, root_only: true, default: false
  add_setting :teachers_can_create_courses_anywhere, boolean: true, root_only: true, default: true
  add_setting :students_can_create_courses_anywhere, boolean: true, root_only: true, default: true

  add_setting :restrict_quiz_questions, boolean: true, root_only: true, default: false
  add_setting :allow_sending_scores_in_emails, boolean: true, root_only: true
  add_setting :can_add_pronouns, boolean: true, root_only: true, default: false
  add_setting :can_change_pronouns, boolean: true, root_only: true, default: true
  add_setting :enable_sis_export_pronouns, boolean: true, root_only: true, default: true
  add_setting :pronouns, root_only: true

  add_setting :self_enrollment
  add_setting :equella_endpoint
  add_setting :equella_teaser
  add_setting :enable_alerts, boolean: true, root_only: true
  add_setting :enable_eportfolios, boolean: true, root_only: true
  add_setting :users_can_edit_name, boolean: true, root_only: true, default: true
  add_setting :users_can_edit_profile, boolean: true, root_only: true, default: true
  add_setting :users_can_edit_comm_channels, boolean: true, root_only: true, default: true
  add_setting :open_registration, boolean: true, root_only: true
  add_setting :show_scheduler, boolean: true, root_only: true, default: false
  add_setting :enable_profiles, boolean: true, root_only: true, default: false
  add_setting :enable_turnitin, boolean: true, default: false
  add_setting :mfa_settings, root_only: true
  add_setting :mobile_qr_login_is_enabled, boolean: true, root_only: true, default: true
  add_setting :admins_can_change_passwords, boolean: true, root_only: true, default: false
  add_setting :admins_can_view_notifications, boolean: true, root_only: true, default: false
  add_setting :canvadocs_prefer_office_online, boolean: true, root_only: true, default: false
  add_setting :outgoing_email_default_name, root_only: true
  add_setting :external_notification_warning, boolean: true, root_only: true, default: false
  # Terms of Use and Privacy Policy settings for the root account
  add_setting :terms_changed_at, root_only: true
  add_setting :account_terms_required, root_only: true, boolean: true, default: true
  # When a user is invited to a course, do we let them see a preview of the
  # course even without registering?  This is part of the free-for-teacher
  # account perks, since anyone can invite anyone to join any course, and it'd
  # be nice to be able to see the course first if you weren't expecting the
  # invitation.
  add_setting :allow_invitation_previews, boolean: true, root_only: true, default: false
  add_setting :large_course_rosters, boolean: true, root_only: true, default: false
  add_setting :edit_institution_email, boolean: true, root_only: true, default: true
  add_setting :js_kaltura_uploader, boolean: true, root_only: true, default: false
  add_setting :google_docs_domain, root_only: true
  add_setting :dashboard_url, root_only: true
  add_setting :product_name, root_only: true
  add_setting :author_email_in_notifications, boolean: true, root_only: true, default: false
  add_setting :include_students_in_global_survey, boolean: true, root_only: true, default: false
  add_setting :trusted_referers, root_only: true
  add_setting :app_center_access_token
  add_setting :enable_offline_web_export, boolean: true, default: false, inheritable: true
  add_setting :disable_rce_media_uploads, boolean: true, default: false, inheritable: true
  add_setting :allow_gradebook_show_first_last_names, boolean: true, default: false, inheritable: true

  add_setting :strict_sis_check, boolean: true, root_only: true, default: false
  add_setting :lock_all_announcements, default: false, boolean: true, inheritable: true

  add_setting :enable_gravatar, boolean: true, root_only: true, default: true

  # For setting the default dashboard (e.g. Student Planner/List View, Activity Stream, Dashboard Cards)
  add_setting :default_dashboard_view, inheritable: true

  add_setting :require_confirmed_email, boolean: true, root_only: true, default: false

  add_setting :enable_course_catalog, boolean: true, root_only: true, default: false
  add_setting :usage_rights_required, boolean: true, default: false, inheritable: true
  add_setting :limit_parent_app_web_access, boolean: true, default: false, root_only: true
  add_setting :kill_joy, boolean: true, default: false, root_only: true
  add_setting :suppress_notifications, boolean: true, default: false, root_only: true
  add_setting :smart_alerts_threshold, default: 36, root_only: true

  add_setting :disable_post_to_sis_when_grading_period_closed, boolean: true, root_only: true, default: false

  add_setting :rce_favorite_tool_ids, inheritable: true

  add_setting :enable_as_k5_account, boolean: true, default: false, inheritable: true
  add_setting :use_classic_font_in_k5, boolean: true, default: false, inheritable: true

  # Allow accounts with strict data residency requirements to turn off mobile
  # push notifications which may be routed through US datacenters by Google/Apple
  add_setting :enable_push_notifications, boolean: true, root_only: true, default: true
  add_setting :allow_last_page_on_course_users, boolean: true, root_only: true, default: false
  add_setting :allow_last_page_on_account_courses, boolean: true, root_only: true, default: false
  add_setting :allow_last_page_on_users, boolean: true, root_only: true, default: false
  add_setting :emoji_deny_list, root_only: true

  add_setting :default_due_time, inheritable: true
  add_setting :conditional_release, default: false, boolean: true, inheritable: true
  add_setting :enable_search_indexing, boolean: true, root_only: true, default: false
  add_setting :disable_login_search_indexing, boolean: true, root_only: true, default: false
  add_setting :allow_additional_email_at_registration, boolean: true, root_only: true, default: false

  # Allow enabling metrics like Heap for sandboxes and other accounts without Salesforce data
  add_setting :enable_usage_metrics, boolean: true, root_only: true, default: false

  add_setting :allow_observers_in_appointment_groups, boolean: true, default: false, inheritable: true

  def settings=(hash)
    if hash.is_a?(Hash) || hash.is_a?(ActionController::Parameters)
      hash.each do |key, val|
        key = key.to_sym
        if account_settings_options && (opts = account_settings_options[key])
          if (opts[:root_only] && !root_account?) || (opts[:condition] && !send(:"#{opts[:condition]}?"))
            settings.delete key
          elsif opts[:hash]
            new_hash = {}
            if val.is_a?(Hash) || val.is_a?(ActionController::Parameters)
              val.each do |inner_key, inner_val|
                inner_key = inner_key.to_sym
                next unless opts[:values].include?(inner_key)

                new_hash[inner_key] = if opts[:inheritable] && (inner_key == :locked || (inner_key == :value && opts[:boolean]))
                                        Canvas::Plugin.value_to_boolean(inner_val)
                                      else
                                        inner_val.to_s.presence
                                      end
              end
            end
            settings[key] = new_hash.empty? ? nil : new_hash
          elsif opts[:boolean]
            settings[key] = Canvas::Plugin.value_to_boolean(val)
          else
            settings[key] = val.to_s.presence
          end
        end
      end
    end
    # prune nil or "" hash values to save space in the DB.
    settings.reject! { |_, value| value.nil? || value == { value: nil } || value == { value: nil, locked: false } }
    settings
  end

  def product_name
    settings[:product_name] || t("#product_name", "Canvas")
  end

  def usage_rights_required?
    usage_rights_required[:value]
  end

  def restrict_quantitative_data?
    root_account.feature_enabled?(:restrict_quantitative_data) && restrict_quantitative_data[:value]
  end

  def allow_global_includes?
    if root_account?
      global_includes?
    else
      root_account.try(:sub_account_includes?) && root_account.try(:allow_global_includes?)
    end
  end

  def pronouns
    return [] unless settings[:can_add_pronouns]

    settings[:pronouns]&.map { |p| translate_pronouns(p) } || Pronouns.default_pronouns
  end

  def pronouns=(pronouns)
    settings[:pronouns] = pronouns&.map { |p| untranslate_pronouns(p) }&.reject(&:blank?)
  end

  def mfa_settings
    settings[:mfa_settings].try(:to_sym) || :disabled
  end

  def non_canvas_auth_configured?
    authentication_providers.active.where("auth_type<>'canvas'").exists?
  end

  def canvas_authentication_provider
    @canvas_ap ||= authentication_providers.active.where(auth_type: "canvas").first
  end

  def canvas_authentication?
    !!canvas_authentication_provider
  end

  def enable_canvas_authentication
    return unless root_account?
    return if dummy?
    # for migrations creating a new db
    return unless Account.connection.data_source_exists?("authentication_providers")
    return if authentication_providers.active.where(auth_type: "canvas").exists?

    authentication_providers.create!(auth_type: "canvas")
  end

  def enable_offline_web_export?
    enable_offline_web_export[:value]
  end

  def disable_rce_media_uploads?
    disable_rce_media_uploads[:value]
  end

  def allow_observers_in_appointment_groups?
    allow_observers_in_appointment_groups[:value] && Account.site_admin.feature_enabled?(:observer_appointment_groups)
  end

  def allow_gradebook_show_first_last_names?
    allow_gradebook_show_first_last_names[:value]
  end

  def enable_as_k5_account?
    enable_as_k5_account[:value]
  end

  def enable_as_k5_account!
    settings[:enable_as_k5_account] = { value: true }
    save!
  end

  def use_classic_font_in_k5?
    use_classic_font_in_k5[:value]
  end

  def conditional_release?
    conditional_release[:value]
  end

  def open_registration?
    !!settings[:open_registration] && canvas_authentication?
  end

  def self_registration?
    canvas_authentication_provider.try(:jit_provisioning?)
  end

  def self_registration_type
    canvas_authentication_provider.try(:self_registration)
  end

  def self_registration_captcha?
    canvas_authentication_provider.try(:enable_captcha)
  end

  def self_registration_allowed_for?(type)
    return false unless self_registration?
    return false if self_registration_type != "all" && type != self_registration_type

    true
  end

  def enable_self_registration
    canvas_authentication_provider.update_attribute(:self_registration, true)
  end

  def terms_required?
    terms = TermsOfService.ensure_terms_for_account(root_account)
    !(terms.terms_type == "no_terms" || terms.passive)
  end

  def require_acceptance_of_terms?(user)
    return false unless terms_required?
    return true if user.nil? || user.new_record?

    soc2_start_date = Setting.get("SOC2_start_date", Time.new(2015, 5, 16, 0, 0, 0).utc).to_datetime
    return false if user.created_at < soc2_start_date

    terms_changed_at = root_account.terms_of_service.terms_of_service_content&.terms_updated_at || settings[:terms_changed_at]
    last_accepted = user.preferences[:accepted_terms]
    return false if last_accepted && (terms_changed_at.nil? || last_accepted > terms_changed_at)

    true
  end

  def ip_filters=(params)
    filters = {}
    require "ipaddr"
    params.each do |key, str|
      ips = []
      vals = str.split(",")
      vals.each do |val|
        ip = IPAddr.new(val) rescue nil
        # right now the ip_filter column on quizzes is just a string,
        # so it has a max length.  I figure whatever we set it to this
        # setter should at the very least limit stored values to that
        # length.
        ips << val if ip && val.length <= 255
      end
      filters[key] = ips.join(",") unless ips.empty?
    end
    settings[:ip_filters] = filters
  end

  def enable_sis_imports
    self.allow_sis_import = true
  end

  def ensure_defaults
    name&.delete!("\r")
    self.uuid ||= CanvasSlug.generate_securish_uuid if has_attribute?(:uuid)
    self.lti_guid ||= "#{self.uuid}:#{INSTANCE_GUID_SUFFIX}" if has_attribute?(:lti_guid)
    self.root_account_id ||= parent_account.root_account_id if parent_account && !parent_account.root_account?
    self.root_account_id ||= parent_account_id
    self.parent_account_id ||= self.root_account_id unless root_account?
    unless root_account_id
      Account.ensure_dummy_root_account
      self.root_account_id = 0
    end
    true
  end

  def verify_unique_sis_source_id
    return true unless has_attribute?(:sis_source_id)
    return true unless sis_source_id
    return true if !root_account_id_changed? && !sis_source_id_changed?

    if root_account?
      errors.add(:sis_source_id, t("#account.root_account_cant_have_sis_id", "SIS IDs cannot be set on root accounts"))
      throw :abort
    end

    scope = root_account.all_accounts.where(sis_source_id:)
    scope = scope.where("id<>?", self) unless new_record?

    return true unless scope.exists?

    errors.add(:sis_source_id, t("#account.sis_id_in_use", "SIS ID \"%{sis_id}\" is already in use", sis_id: sis_source_id))
    throw :abort
  end

  def update_account_associations_if_changed
    # if the account structure changed, but this is _not_ a new object
    if (saved_change_to_parent_account_id? || saved_change_to_root_account_id?) &&
       !saved_change_to_id?
      shard.activate do
        delay_if_production.update_account_associations
      end
    end
  end

  def check_downstream_caches
    # dummy account has no downstream
    return if dummy?
    return if ActiveRecord::Base.in_migration

    keys_to_clear = []
    keys_to_clear << :account_chain if saved_change_to_parent_account_id? || saved_change_to_root_account_id?
    if saved_change_to_brand_config_md5? || (@old_settings && @old_settings[:sub_account_includes] != settings[:sub_account_includes])
      keys_to_clear << :brand_config
    end
    keys_to_clear << :default_locale if saved_change_to_default_locale?
    if keys_to_clear.any?
      shard.activate do
        self.class.connection.after_transaction_commit do
          delay_if_production(singleton: "Account#clear_downstream_caches/#{global_id}:#{keys_to_clear.join("/")}")
            .clear_downstream_caches(*keys_to_clear, xlog_location: self.class.current_xlog_location)
        end
      end
    end
  end

  def clear_downstream_caches(*keys_to_clear, xlog_location: nil, is_retry: false)
    shard.activate do
      if xlog_location && !self.class.wait_for_replication(start: xlog_location, timeout: 1.minute)
        delay(run_at: Time.now + timeout, singleton: "Account#clear_downstream_caches/#{global_id}:#{keys_to_clear.join("/")}")
          .clear_downstream_caches(*keys_to_clear, xlog_location:, is_retry: true)
        # we still clear, but only the first time; after that we just keep waiting
        return if is_retry
      end

      Account.clear_cache_keys([id] + Account.sub_account_ids_recursive(id), *keys_to_clear)
    end
  end

  def equella_settings
    endpoint = settings[:equella_endpoint] || equella_endpoint
    if endpoint.blank?
      nil
    else
      OpenObject.new({
                       endpoint:,
                       default_action: settings[:equella_action] || "selectOrAdd",
                       teaser: settings[:equella_teaser]
                     })
    end
  end

  def settings
    # If the settings attribute is not loaded because it's an old cached object or something, return an empty blob that is read-only
    unless has_attribute?(:settings)
      return SettingsWrapper.new(self, {}.freeze)
    end

    result = self[:settings]
    if result
      @old_settings ||= result.dup
      return SettingsWrapper.new(self, result)
    end
    unless frozen?
      self[:settings] = {}
      return SettingsWrapper.new(self, self[:settings])
    end

    SettingsWrapper.new(self, {}.freeze)
  end

  def setting_enabled?(setting)
    return false unless has_attribute?(:settings)

    !!settings[setting.to_sym]
  end

  def domain(current_host = nil)
    HostUrl.context_host(self, current_host)
  end

  def environment_specific_domain
    domain(ApplicationController.test_cluster_name)
  end

  def self.find_by_domain(domain)
    default if HostUrl.default_host == domain
  end

  def root_account?
    root_account_id.nil? || local_root_account_id.zero?
  end

  def primary_settings_root_account?
    root_account?
  end

  def root_account
    return self if root_account?

    super
  end

  def root_account=(value)
    return if value == self && root_account?
    raise ArgumentError, "cannot change the root account of a root account" if root_account? && persisted?

    super
  end

  def resolved_root_account_id
    root_account? ? id : root_account_id
  end

  def sub_accounts_as_options(indent = 0, preloaded_accounts = nil)
    unless preloaded_accounts
      preloaded_accounts = {}
      root_account.all_accounts.active.each do |account|
        (preloaded_accounts[account.parent_account_id] ||= []) << account
      end
    end
    res = [[("&nbsp;&nbsp;" * indent).html_safe + name, id]]
    preloaded_accounts[id]&.each do |account|
      res += account.sub_accounts_as_options(indent + 1, preloaded_accounts)
    end
    res
  end

  def users_visible_to(user)
    grants_right?(user, :read) ? all_users : all_users.none
  end

  def users_name_like(query = "")
    @cached_users_name_like ||= {}
    @cached_users_name_like[query] ||= fast_all_users.name_like(query)
  end

  def associated_courses(opts = {})
    if root_account?
      all_courses
    else
      shard.activate do
        if opts[:include_crosslisted_courses]
          Course.where(CourseAccountAssociation.where(account_id: self)
            .where("course_id=courses.id")
            .arel.exists)
        else
          Course.where(CourseAccountAssociation.where(account_id: self, course_section_id: nil)
            .where("course_id=courses.id")
            .arel.exists)
        end
      end
    end
  end

  def associated_user?(user)
    user_account_associations.where(user_id: user).exists?
  end

  def fast_all_users(limit = nil)
    @cached_fast_all_users ||= {}
    @cached_fast_all_users[limit] ||= all_users.limit(limit).active.select("users.id, users.updated_at, users.name, users.sortable_name").order_by_sortable_name
  end

  def users_not_in_groups(groups, opts = {})
    scope = User.active.joins(:user_account_associations)
                .where(user_account_associations: { account_id: self })
                .where(Group.not_in_group_sql_fragment(groups.map(&:id)))
                .select("users.id, users.name")
    scope = scope.select(opts[:order]).order(opts[:order]) if opts[:order]
    scope
  end

  def self_enrollment_course_for(code)
    all_courses
      .where(self_enrollment_code: code)
      .first
  end

  def file_namespace
    if Shard.current == Shard.birth
      "account_#{root_account.local_id}"
    else
      root_account.global_asset_string
    end
  end

  def self.account_lookup_cache_key(id)
    ["_account_lookup5", id].cache_key
  end

  def self.invalidate_cache(id)
    return unless id

    default_id = Shard.relative_id_for(id, Shard.current, Shard.default)
    Shard.default.activate do
      MultiCache.delete(account_lookup_cache_key(default_id)) if default_id
    end
  rescue
    nil
  end

  def setup_cache_invalidation
    @invalidations = []
    unless new_record?
      invalidate_all = parent_account_id_changed?
      # apparently, the try_rescues are because these columns don't exist on old migrations
      @invalidations += ["default_storage_quota", "current_quota"] if invalidate_all || try_rescue(:default_storage_quota_changed?)
      @invalidations << "default_group_storage_quota" if invalidate_all || try_rescue(:default_group_storage_quota_changed?)
    end
  end

  def invalidate_association_cache
    shard.activate do
      self.class.connection.after_transaction_commit do
        Account.invalidate_cache(id) if root_account?
        Rails.cache.delete(["account2", id].cache_key)
      end
    end
  end

  def invalidate_caches_if_changed
    invalidate_association_cache if saved_changes?

    @invalidations ||= []
    if saved_change_to_parent_account_id?
      @invalidations += Account.inheritable_settings # invalidate all of them
    elsif @old_settings
      Account.inheritable_settings.each do |key|
        @invalidations << key if @old_settings[key] != settings[key] # only invalidate if needed
      end
      @old_settings = nil
    end

    if @invalidations.present?
      shard.activate do
        self.class.connection.after_transaction_commit do
          @invalidations.each do |key|
            Rails.cache.delete([key, global_id].cache_key)
          end
          Account.delay_if_production(singleton: "Account.invalidate_inherited_caches_#{global_id}")
                 .invalidate_inherited_caches(self, @invalidations)
        end
      end
    end
  end

  def self.invalidate_inherited_caches(parent_account, keys)
    parent_account.shard.activate do
      account_ids = Account.sub_account_ids_recursive(parent_account.id)
      account_ids.each do |id|
        global_id = Shard.global_id_for(id)
        keys.each do |key|
          Rails.cache.delete([key, global_id].cache_key)
        end
      end

      access_keys = keys & [:restrict_student_future_view, :restrict_student_past_view]
      if access_keys.any?
        EnrollmentState.invalidate_access_for_accounts([parent_account.id] + account_ids, access_keys)
      end
    end
  end

  DEFAULT_STORAGE_QUOTA = 500.megabytes

  def quota
    return storage_quota if read_attribute(:storage_quote)
    return DEFAULT_STORAGE_QUOTA if root_account?

    shard.activate do
      Rails.cache.fetch(["current_quota", global_id].cache_key) do
        parent_account.default_storage_quota
      end
    end
  end

  def default_storage_quota
    return super if read_attribute(:default_storage_quota)
    return DEFAULT_STORAGE_QUOTA if root_account?

    shard.activate do
      @default_storage_quota ||= Rails.cache.fetch(["default_storage_quota", global_id].cache_key) do
        parent_account.default_storage_quota
      end
    end
  end

  def default_storage_quota_mb
    default_storage_quota / 1.megabyte
  end

  def default_storage_quota_mb=(val)
    self.default_storage_quota = val.try(:to_i).try(:megabytes)
  end

  def default_storage_quota=(val)
    val = val.to_f
    val = nil if val <= 0
    # If the value is the same as the inherited value, then go
    # ahead and blank it so it keeps using the inherited value
    if parent_account && parent_account.default_storage_quota == val
      val = nil
    end
    write_attribute(:default_storage_quota, val)
  end

  def default_user_storage_quota
    read_attribute(:default_user_storage_quota) ||
      User.default_storage_quota
  end

  def default_user_storage_quota=(val)
    val = val.to_i
    val = nil if val == User.default_storage_quota || val <= 0
    write_attribute(:default_user_storage_quota, val)
  end

  def default_user_storage_quota_mb
    default_user_storage_quota / 1.megabyte
  end

  def default_user_storage_quota_mb=(val)
    self.default_user_storage_quota = val.try(:to_i).try(:megabytes)
  end

  def default_group_storage_quota
    return super if read_attribute(:default_group_storage_quota)
    return Group.default_storage_quota if root_account?

    shard.activate do
      Rails.cache.fetch(["default_group_storage_quota", global_id].cache_key) do
        parent_account.default_group_storage_quota
      end
    end
  end

  def default_group_storage_quota=(val)
    val = val.to_i
    if (val == Group.default_storage_quota) || (val <= 0) ||
       (parent_account && parent_account.default_group_storage_quota == val)
      val = nil
    end
    write_attribute(:default_group_storage_quota, val)
  end

  def default_group_storage_quota_mb
    default_group_storage_quota / 1.megabyte
  end

  def default_group_storage_quota_mb=(val)
    self.default_group_storage_quota = val.try(:to_i).try(:megabytes)
  end

  def turnitin_shared_secret=(secret)
    return if secret.blank?

    self.turnitin_crypted_secret, self.turnitin_salt = Canvas::Security.encrypt_password(secret, "instructure_turnitin_secret_shared")
  end

  def turnitin_shared_secret
    return nil unless turnitin_salt && turnitin_crypted_secret

    Canvas::Security.decrypt_password(turnitin_crypted_secret, turnitin_salt, "instructure_turnitin_secret_shared")
  end

  def self.account_chain(starting_account_id)
    chain = []

    if starting_account_id.is_a?(Account)
      chain << starting_account_id
      starting_account_id = starting_account_id.parent_account_id
    end

    if starting_account_id
      guard_rail_env = (Account.connection.open_transactions == 0) ? :secondary : GuardRail.environment
      GuardRail.activate(guard_rail_env) do
        chain.concat(Shard.shard_for(starting_account_id).activate do
          Account.find_by_sql(<<~SQL.squish)
            WITH RECURSIVE t AS (
              SELECT * FROM #{Account.quoted_table_name} WHERE id=#{Shard.local_id_for(starting_account_id).first}
              UNION
              SELECT accounts.* FROM #{Account.quoted_table_name} INNER JOIN t ON accounts.id=t.parent_account_id
            )
            SELECT * FROM t
          SQL
        end)
      end
    end
    chain
  end

  def self.account_chain_ids(starting_account_id)
    block = proc do
      original_shard = Shard.current
      Shard.shard_for(starting_account_id).activate do
        id_chain = []
        if starting_account_id.is_a?(Account)
          id_chain << Shard.relative_id_for(starting_account_id.id, Shard.current, original_shard)
          starting_account_id = starting_account_id.parent_account_id
        end

        if starting_account_id
          GuardRail.activate(:secondary) do
            ids = Account.connection.select_values(<<~SQL.squish)
              WITH RECURSIVE t AS (
                SELECT * FROM #{Account.quoted_table_name} WHERE id=#{Shard.local_id_for(starting_account_id).first}
                UNION
                SELECT accounts.* FROM #{Account.quoted_table_name} INNER JOIN t ON accounts.id=t.parent_account_id
              )
              SELECT id FROM t
            SQL
            id_chain.concat(ids.map { |id| Shard.relative_id_for(id, Shard.current, original_shard) })
          end
        end
        id_chain
      end
    end
    key = Account.cache_key_for_id(starting_account_id, :account_chain)
    key ? Rails.cache.fetch(["account_chain_ids", key], &block) : block.call
  end

  def self.multi_account_chain_ids(starting_account_ids)
    original_shard = Shard.current
    Shard.partition_by_shard(starting_account_ids) do |sliced_acc_ids|
      ids = Account.connection.select_values(sanitize_sql(<<~SQL.squish))
        WITH RECURSIVE t AS (
          SELECT * FROM #{Account.quoted_table_name} WHERE id IN (#{sliced_acc_ids.join(", ")})
          UNION
          SELECT accounts.* FROM #{Account.quoted_table_name} INNER JOIN t ON accounts.id=t.parent_account_id
        )
        SELECT id FROM t
      SQL
      ids.map { |id| Shard.relative_id_for(id, Shard.current, original_shard) }
    end
  end

  def self.add_federated_parent_to_chain!(chain)
    chain
  end

  def self.add_federated_parent_id_to_chain!(chain)
    chain
  end

  def self.add_site_admin_to_chain!(chain)
    add_federated_parent_to_chain!(chain)
    chain << Account.site_admin unless chain.last.site_admin?
    chain
  end

  def account_chain(include_site_admin: false, include_federated_parent: false)
    @account_chain ||= Account.account_chain(self).tap do |chain|
      # preload the root account and parent accounts that we also found here
      ra = chain.find(&:root_account?)
      chain.each { |a| a.root_account = ra if a.root_account_id == ra.id }
      chain.each_with_index { |a, idx| a.parent_account = chain[idx + 1] if a.parent_account_id == chain[idx + 1]&.id }
    end.freeze

    # This implicitly includes add_federated_parent_to_chain
    if include_site_admin
      return @account_chain_with_site_admin ||= Account.add_site_admin_to_chain!(@account_chain.dup).freeze
    end

    if include_federated_parent
      return @account_chain_with_federated_parent ||= Account.add_federated_parent_to_chain!(@account_chain.dup).freeze
    end

    @account_chain
  end

  def account_chain_ids(include_federated_parent_id: false)
    @cached_account_chain_ids ||= {}

    result = (@cached_account_chain_ids[Shard.current.id] ||= Account.account_chain_ids(self).freeze)

    if include_federated_parent_id
      @cached_account_chain_ids_with_federated_parent ||= {}
      result = (@cached_account_chain_ids_with_federated_parent[Shard.current.id] ||=
                  Account.add_federated_parent_id_to_chain!(result.dup).freeze)
    end

    result
  end

  def account_chain_loop
    # this record hasn't been saved to the db yet, so if the the chain includes
    # this account, it won't point to the new parent yet, and should still be
    # valid
    if parent_account.account_chain.include?(self)
      errors.add(:parent_account_id,
                 "Setting account #{sis_source_id || id}'s parent to #{parent_account.sis_source_id || self.parent_account_id} would create a loop")
    end
  end

  # compat for reports
  def sub_accounts_recursive(limit, offset)
    Account.limit(limit).offset(offset).sub_accounts_recursive(id)
  end

  def self.sub_accounts_recursive(parent_account_id, pluck = false)
    raise ArgumentError unless [false, :pluck].include?(pluck)

    original_shard = Shard.current
    result = Shard.shard_for(parent_account_id).activate do
      parent_account_id = Shard.relative_id_for(parent_account_id, original_shard, Shard.current)

      with_secondary_role_if_possible do
        sql = Account.sub_accounts_recursive_sql(parent_account_id)
        if pluck
          Account.connection.select_all(sql).map do |row|
            new_row = row.map do |(column, value)|
              if sharded_column?(column)
                Shard.relative_id_for(value, Shard.current, original_shard)
              else
                value
              end
            end
            new_row = new_row.first if new_row.length == 1
            new_row
          end
        else
          Account.find_by_sql(sql)
        end
      end
    end
    unless (preload_values = all.preload_values).empty?
      ActiveRecord::Associations.preload(result, preload_values)
    end
    result
  end

  def self.multi_parent_sub_accounts_recursive(parent_account_ids)
    return [] if parent_account_ids.blank?

    # Validate all parent_account_ids are on the same shard
    account_shards = parent_account_ids.map do |parent_account_id|
      Shard.shard_for(parent_account_id)
    end.uniq
    raise ArgumentError, "all parent_account_ids must be in the same shard" if account_shards.length > 1

    account_shards.first.activate do
      with_secondary_role_if_possible do
        Account.find_by_sql(
          # Switchman will make the IDs in parent_account_ids
          # relative to the currently activated shard
          Account.sub_accounts_recursive_sql(parent_account_ids, include_parents: true)
        )
      end
    end
  end

  def self.with_secondary_role_if_possible(&)
    guard_rail_env = (Account.connection.open_transactions == 0) ? :secondary : GuardRail.environment

    GuardRail.activate(guard_rail_env, &)
  end

  # a common helper
  def self.sub_account_ids_recursive(parent_account_id)
    active.select(:id).sub_accounts_recursive(parent_account_id, :pluck)
  end

  # compat for reports
  def self.sub_account_ids_recursive_sql(parent_account_id)
    active.select(:id).sub_accounts_recursive_sql(parent_account_id)
  end

  # the default ordering will have each tier in a group, followed by the next tier, etc.
  # if an order is set on the relation, that order is only applied within each group
  def self.sub_accounts_recursive_sql(parent_account_id, include_parents: false)
    relation = except(:group, :having, :limit, :offset).shard(Shard.current)
    relation_with_ids = if relation.select_values.empty? || (relation.select_values & [:id, :parent_account_id]).length == 2
                          relation
                        else
                          relation.select(:id, :parent_account_id)
                        end

    relation_with_select = all
    relation_with_select = relation_with_select.select("*") if relation_with_select.select_values.empty?

    scope = relation_with_ids.where(parent_account_id:)
    scope = relation_with_ids.where(id: parent_account_id) if include_parents

    "WITH RECURSIVE t AS (
       #{scope.to_sql}
       UNION
       #{relation_with_ids.joins("INNER JOIN t ON accounts.parent_account_id=t.id").to_sql}
     )
     #{relation_with_select.only(:select, :group, :having, :limit, :offset).from("t").to_sql}"
  end

  def associated_accounts
    account_chain
  end

  def membership_for_user(user)
    account_users.active.where(user_id: user).first if user
  end

  def available_custom_account_roles(include_inactive = false)
    available_custom_roles(include_inactive).for_accounts.to_a
  end

  def available_account_roles(include_inactive = false, user = nil)
    account_roles = available_custom_account_roles(include_inactive)
    account_roles << Role.get_built_in_role("AccountAdmin", root_account_id: resolved_root_account_id)
    if user
      account_roles.select! do |role|
        au = account_users.new
        au.role_id = role.id
        au.grants_right?(user, :create)
      end
    end
    account_roles
  end

  def available_custom_course_roles(include_inactive = false)
    available_custom_roles(include_inactive).for_courses.to_a
  end

  def available_course_roles(include_inactive = false)
    course_roles = available_custom_course_roles(include_inactive)
    course_roles += Role.built_in_course_roles(root_account_id: resolved_root_account_id)
    course_roles
  end

  def available_custom_roles(include_inactive = false)
    scope = if root_account.primary_settings_root_account?
              Role.where(account_id: account_chain_ids)
            else
              Role.shard(account_chain(include_federated_parent: true).map(&:shard).uniq).where(account: account_chain(include_federated_parent: true))
            end
    include_inactive ? scope.not_deleted : scope.active
  end

  def available_roles(include_inactive = false)
    available_account_roles(include_inactive) + available_course_roles(include_inactive)
  end

  def get_account_role_by_name(role_name)
    role = get_role_by_name(role_name)
    role if role&.account_role?
  end

  def get_course_role_by_name(role_name)
    role = get_role_by_name(role_name)
    role if role&.course_role?
  end

  def get_role_by_name(role_name)
    if (role = Role.get_built_in_role(role_name, root_account_id: resolved_root_account_id))
      return role
    end

    shard.activate do
      role_scope = Role.not_deleted.where(name: role_name)
      role_scope = if self.class.connection.adapter_name == "PostgreSQL"
                     role_scope.where("account_id = ? OR
          account_id IN (
            WITH RECURSIVE t AS (
              SELECT id, parent_account_id FROM #{Account.quoted_table_name} WHERE id = ?
              UNION
              SELECT accounts.id, accounts.parent_account_id FROM #{Account.quoted_table_name} INNER JOIN t ON accounts.id=t.parent_account_id
            )
            SELECT id FROM t
          )",
                                      id,
                                      id)
                   else
                     role_scope.where(account_id: account_chain.map(&:id))
                   end

      role_scope.first
    end
  end

  def get_role_by_id(role_id)
    role = Role.get_role_by_id(role_id)
    role if valid_role?(role)
  end

  def valid_role?(role)
    allowed_ids = root_account.primary_settings_root_account? ? account_chain_ids : account_chain(include_federated_parent: true).map(&:id)
    role && (role.built_in? || (id == role.account_id) || allowed_ids.include?(role.account_id))
  end

  def login_handle_name_is_customized?
    login_handle_name.present?
  end

  def customized_login_handle_name
    if login_handle_name_is_customized?
      login_handle_name
    elsif delegated_authentication?
      AuthenticationProvider.default_delegated_login_handle_name
    end
  end

  def login_handle_name_with_inference
    customized_login_handle_name || AuthenticationProvider.default_login_handle_name
  end

  def self_and_all_sub_accounts
    @self_and_all_sub_accounts ||= Account.where("root_account_id=? OR parent_account_id=?", self, self).pluck(:id).uniq + [id]
  end

  workflow do
    state :active
    state :deleted
  end

  def account_users_for(user)
    if self == Account.site_admin
      shard.activate do
        all_site_admin_account_users_hash = MultiCache.fetch("all_site_admin_account_users3") do
          # this is a plain ruby hash to keep the cached portion as small as possible
          account_users.active.each_with_object({}) do |au, result|
            result[au.user_id] ||= []
            result[au.user_id] << [au.id, au.role_id]
          end
        end
        (all_site_admin_account_users_hash[user.id] || []).map do |(id, role_id)|
          au = AccountUser.new
          au.id = id
          au.account = Account.site_admin
          au.user = user
          au.role_id = role_id
          # Marking this record as not new means `persisted?` will be true,
          # which means that `clear_association_cache` will work correctly on
          # these objects.
          au.instance_variable_set(:@new_record, false)
          au.readonly!
          au
        end
      end
    else
      @account_chain_ids ||= account_chain(include_site_admin: true).filter_map { |a| a.active? ? a.id : nil }
      Shard.partition_by_shard(@account_chain_ids) do |account_chain_ids|
        if account_chain_ids == [Account.site_admin.id]
          Account.site_admin.account_users_for(user)
        else
          AccountUser.where(account_id: account_chain_ids, user_id: user).active.to_a
        end
      end
    end
  end

  def cached_account_users_for(user)
    return [] unless user

    @account_users_cache ||= {}
    @account_users_cache[user.global_id] ||= if site_admin?
                                               account_users_for(user) # has own cache
                                             else
                                               Rails.cache.fetch_with_batched_keys(["account_users_for_user", user.cache_key(:account_users)].cache_key,
                                                                                   batch_object: self,
                                                                                   batched_keys: :account_chain,
                                                                                   skip_cache_if_disabled: true) do
                                                 account_users_for(user).each(&:clear_association_cache)
                                               end
                                             end
  end

  # returns all active account users for this entire account tree
  def all_account_users_for(user)
    raise "must be a root account" unless root_account?

    Shard.partition_by_shard(account_chain(include_site_admin: true).uniq) do |accounts|
      next unless user.associated_shards.include?(Shard.current)

      AccountUser.active.eager_load(:account).where("user_id=? AND (accounts.root_account_id IN (?) OR account_id IN (?))", user, accounts, accounts)
    end
  end

  def cached_all_account_users_for(user)
    return [] unless user

    Rails.cache.fetch_with_batched_keys(
      ["all_account_users_for_user", user.cache_key(:account_users)].cache_key,
      batch_object: self,
      batched_keys: :account_chain,
      skip_cache_if_disabled: true
    ) { all_account_users_for(user) }
  end

  set_policy do
    #################### Begin legacy permission block #########################
    given do |user|
      user && !root_account.feature_enabled?(:granular_permissions_manage_lti) &&
        grants_right?(user, :lti_add_edit)
    end
    can :create_tool_manually
    ##################### End legacy permission block ##########################

    RoleOverride.permissions.each_key do |permission|
      given do |user|
        results = cached_account_users_for(user).map do |au|
          res = au.permission_check(self, permission)
          if res.success?
            break :success
          else
            res
          end
        end
        next true if results == :success

        # return the first result with a justification or nil, either of which will deny access
        results.find { |r| r.is_a?(AdheresToPolicy::JustifiedFailure) }
      end
      can permission
      can :create_courses if permission == :manage_courses_add
    end

    given do |user|
      results = cached_account_users_for(user).map do |au|
        res = au.permitted_for_account?(self)
        if res.success?
          break :success
        else
          res
        end
      end
      next true if results == :success

      # return the first result with a justification or nil, either of which will deny access
      results.find { |r| r.is_a?(AdheresToPolicy::JustifiedFailure) }
    end
    can %i[
      read
      read_as_admin
      manage
      update
      delete
      read_outcomes
      read_terms
      read_files
      launch_external_tool
    ]

    given { |user| root_account? && cached_all_account_users_for(user).any? { |au| au.permitted_for_account?(self).success? } }
    can :read_terms

    given { |user| user&.create_courses_right(self).present? }
    can :create_courses

    # allow teachers to view term dates
    given { |user| root_account? && !site_admin? && enrollments.active.of_instructor_type.where(user_id: user).exists? }
    can :read_terms

    # any logged in user can read global outcomes, but must be checked against the site admin
    given { |user| site_admin? && user }
    can :read_global_outcomes

    # any user with an association to this account can read the outcomes in the account
    given { |user| user && user_account_associations.where(user_id: user).exists? }
    can [:read_outcomes, :launch_external_tool]

    # any user with an admin enrollment in one of the courses can read
    given { |user| !site_admin? && user && courses.where(id: user.enrollments.active.admin.pluck(:course_id)).exists? }
    can [:read, :read_files]

    given do |user|
      root_account? && grants_right?(user, :read_roster) &&
        (grants_right?(user, :view_notifications) || Account.site_admin.grants_right?(user, :read_messages))
    end
    can :view_bounced_emails

    given do |user|
      user &&
        (user_account_associations.where(user_id: user).exists? || grants_right?(user, :read)) &&
        (account_calendar_visible || grants_right?(user, :manage_account_calendar_visibility))
    end
    can :view_account_calendar_details
  end

  def reload(*)
    @account_chain = @account_chain_with_site_admin = nil
    super
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    transaction do
      account_users.update_all(workflow_state: "deleted")
      self.workflow_state = "deleted"
      self.deleted_at = Time.now.utc
      save!
    end
  end

  def to_atom
    {
      title: name,
      updated: updated_at,
      published: created_at,
      link: "/accounts/#{id}"
    }
  end

  def default_enrollment_term
    return @default_enrollment_term if @default_enrollment_term
    return if dummy?

    if root_account?
      @default_enrollment_term = GuardRail.activate(:primary) { enrollment_terms.active.where(name: EnrollmentTerm::DEFAULT_TERM_NAME).first_or_create }
    end
  end

  def context_code
    raise "DONT USE THIS, use .short_name instead" unless Rails.env.production?
  end

  def short_name
    name
  end

  # can be set/overridden by plugin to enforce email pseudonyms
  attr_accessor :email_pseudonyms

  def password_policy
    Canvas::PasswordPolicy.default_policy.merge(settings[:password_policy] || {})
  end

  def delegated_authentication?
    authentication_providers.active.first.is_a?(AuthenticationProvider::Delegated)
  end

  def forgot_password_external_url
    change_password_url
  end

  def auth_discovery_url=(url)
    settings[:auth_discovery_url] = url
  end

  def auth_discovery_url(_request = nil)
    settings[:auth_discovery_url]
  end

  def auth_discovery_url_options(_request)
    {}
  end

  def login_handle_name=(handle_name)
    settings[:login_handle_name] = handle_name
  end

  def login_handle_name
    settings[:login_handle_name]
  end

  def change_password_url=(change_password_url)
    settings[:change_password_url] = change_password_url
  end

  def change_password_url
    settings[:change_password_url]
  end

  def unknown_user_url=(unknown_user_url)
    settings[:unknown_user_url] = unknown_user_url
  end

  def unknown_user_url
    settings[:unknown_user_url]
  end

  def validate_auth_discovery_url
    return if settings[:auth_discovery_url].blank?

    begin
      value, _uri = CanvasHttp.validate_url(settings[:auth_discovery_url])
      self.auth_discovery_url = value
    rescue URI::Error, ArgumentError
      errors.add(:discovery_url, t("errors.invalid_discovery_url", "The discovery URL is not valid"))
    end
  end

  def validate_help_links
    links = settings[:custom_help_links]
    return if links.blank?

    link_errors = HelpLinks.validate_links(links)
    link_errors.each do |link_error|
      errors.add(:custom_help_links, link_error)
    end
  end

  def validate_course_template
    self.course_template_id = nil if course_template_id == 0 && root_account?
    return if [nil, 0].include?(course_template_id)

    unless course_template.root_account_id == resolved_root_account_id
      errors.add(:course_template_id, t("Course template must be in the same root account"))
    end
    unless course_template.template?
      errors.add(:course_template_id, t("Course template must be marked as a template"))
    end
  end

  def no_active_courses
    return true if root_account?

    if associated_courses.not_deleted.exists?
      errors.add(:workflow_state, "Can't delete an account with active courses.")
    end
  end

  def no_active_sub_accounts
    return true if root_account?

    if sub_accounts.exists?
      errors.add(:workflow_state, "Can't delete an account with active sub_accounts.")
    end
  end

  def find_courses(string)
    all_courses.select { |c| c.name.match(string) }
  end

  def find_users(string)
    pseudonyms.map(&:user).select { |u| u.name.match(string) }
  end

  class << self
    def special_accounts
      @special_accounts ||= {}
    end

    def special_account_ids
      @special_account_ids ||= {}
    end

    def special_account_timed_cache
      @special_account_timed_cache ||= TimedCache.new(-> { Setting.get("account_special_account_cache_time", 60).to_i.seconds.ago }) do
        special_accounts.clear
      end
    end

    def special_account_list
      @special_account_list ||= []
    end

    def clear_special_account_cache!(force = false)
      special_account_timed_cache.clear(force)
    end

    def define_special_account(key, name = nil)
      name ||= key.to_s.titleize
      special_account_list << key
      instance_eval <<~RUBY, __FILE__, __LINE__ + 1
        def self.#{key}(force_create = false)
          get_special_account(:#{key}, #{name.inspect}, force_create)
        end
      RUBY
    end

    def all_special_accounts
      special_account_list.map { |key| send(key) }
    end
  end
  define_special_account(:default, "Default Account") # Account.default
  define_special_account(:site_admin) # Account.site_admin

  def clear_special_account_cache_if_special
    if shard == Shard.birth && Account.special_account_ids.values.map(&:to_i).include?(id)
      Account.clear_special_account_cache!(true)
    end
  end

  # an opportunity for plugins to load some other stuff up before caching the account
  def precache
    feature_flags.load
  end

  class ::Canvas::AccountCacheError < StandardError; end

  def self.find_cached(id)
    default_id = Shard.relative_id_for(id, Shard.current, Shard.default)
    Shard.default.activate do
      MultiCache.fetch(account_lookup_cache_key(default_id)) do
        begin
          account = Account.find(default_id)
        rescue ActiveRecord::RecordNotFound => e
          raise ::Canvas::AccountCacheError, e.message
        end
        raise "Account.find_cached should only be used with root accounts" if !account.root_account? && !Rails.env.production?

        account.precache
        account
      end
    end
  end

  def self.get_special_account(special_account_type, default_account_name, force_create = false)
    Shard.birth.activate do
      account = special_accounts[special_account_type]
      unless account
        special_account_id = special_account_ids[special_account_type] ||= Setting.get("#{special_account_type}_account_id", nil)
        begin
          account = special_accounts[special_account_type] = Account.find_cached(special_account_id) if special_account_id
        rescue ::Canvas::AccountCacheError
          raise unless Rails.env.test?
        end
      end
      # another process (i.e. selenium spec) may have changed the setting
      unless account
        special_account_id = Setting.get("#{special_account_type}_account_id", nil)
        if special_account_id && special_account_id != special_account_ids[special_account_type]
          special_account_ids[special_account_type] = special_account_id
          account = special_accounts[special_account_type] = Account.where(id: special_account_id).first
        end
      end
      if !account && default_account_name && ((!special_account_id && !Rails.env.production?) || force_create)
        t "#account.default_site_administrator_account_name", "Site Admin"
        t "#account.default_account_name", "Default Account"
        account = special_accounts[special_account_type] = Account.new(name: default_account_name)
        GuardRail.activate(:primary) do
          account.save!
          Setting.set("#{special_account_type}_account_id", account.id)
        end
        special_account_ids[special_account_type] = account.id
      end
      account
    end
  end

  def site_admin?
    self == Account.site_admin
  end

  def dummy?
    local_id == 0
  end

  def unless_dummy
    return nil if dummy?

    self
  end

  def display_name
    name
  end

  # Updates account associations for all the courses and users associated with this account
  def update_account_associations
    shard.activate do
      account_chain_cache = {}
      all_user_ids = Set.new

      # make sure to use the non-associated_courses associations
      # to catch courses that didn't ever have an association created
      scopes = if root_account?
                 [all_courses,
                  associated_courses
                    .where("root_account_id<>?", self)]
               else
                 [courses,
                  associated_courses
                    .where("courses.account_id<>?", self)]
               end
      # match the "batch" size in Course.update_account_associations
      scopes.each do |scope|
        scope.select([:id, :account_id]).find_in_batches(batch_size: 500) do |courses|
          all_user_ids.merge Course.update_account_associations(courses, skip_user_account_associations: true, account_chain_cache:)
        end
      end

      # Make sure we have all users with existing account associations.
      all_user_ids.merge user_account_associations.pluck(:user_id)
      if root_account?
        all_user_ids.merge pseudonyms.active.pluck(:user_id)
      end

      # Update the users' associations as well
      User.update_account_associations(all_user_ids.to_a, account_chain_cache:)
    end
  end

  def self.update_all_update_account_associations
    Account.root_accounts.active.non_shadow.find_in_batches(strategy: :pluck_ids) do |account_batch|
      account_batch.each(&:update_account_associations)
    end
  end

  def course_count
    courses.active.count
  end

  def sub_account_count
    sub_accounts.active.count
  end

  def user_count
    user_account_associations.count
  end

  def current_sis_batch
    if (current_sis_batch_id = read_attribute(:current_sis_batch_id)) && current_sis_batch_id.present?
      sis_batches.where(id: current_sis_batch_id).first
    end
  end

  def turnitin_settings
    return @turnitin_settings if defined?(@turnitin_settings)

    if turnitin_account_id.present? && turnitin_shared_secret.present?
      if settings[:enable_turnitin]
        @turnitin_settings = [turnitin_account_id,
                              turnitin_shared_secret,
                              turnitin_host]
      end
    else
      @turnitin_settings = parent_account.try(:turnitin_settings)
    end
  end

  def closest_turnitin_pledge
    closest_account_value(:turnitin_pledge, t("This assignment submission is my own, original work"))
  end

  def closest_turnitin_comments
    closest_account_value(:turnitin_comments)
  end

  def closest_turnitin_originality
    closest_account_value(:turnitin_originality, "immediate")
  end

  def closest_account_value(value, default = "")
    account_with_value = account_chain.find { |a| a.send(value.to_sym).present? }
    account_with_value&.send(value.to_sym) || default
  end

  def self_enrollment_allowed?(course)
    if settings[:self_enrollment].blank?
      !!(parent_account && parent_account.self_enrollment_allowed?(course))
    else
      !!(settings[:self_enrollment] == "any" || (!course.sis_source_id && settings[:self_enrollment] == "manually_created"))
    end
  end

  def allow_self_enrollment!(setting = "any")
    settings[:self_enrollment] = setting
    save!
  end

  TAB_COURSES = 0
  TAB_STATISTICS = 1
  TAB_PERMISSIONS = 2
  TAB_SUB_ACCOUNTS = 3
  TAB_TERMS = 4
  TAB_AUTHENTICATION = 5
  TAB_USERS = 6
  TAB_OUTCOMES = 7
  TAB_RUBRICS = 8
  TAB_SETTINGS = 9
  TAB_FACULTY_JOURNAL = 10
  TAB_SIS_IMPORT = 11
  TAB_GRADING_STANDARDS = 12
  TAB_QUESTION_BANKS = 13
  TAB_ADMIN_TOOLS = 17
  TAB_SEARCH = 18
  TAB_BRAND_CONFIGS = 19
  TAB_EPORTFOLIO_MODERATION = 20
  TAB_ACCOUNT_CALENDARS = 21

  # site admin tabs
  TAB_PLUGINS = 14
  TAB_JOBS = 15
  TAB_DEVELOPER_KEYS = 16
  TAB_RELEASE_NOTES = 17
  TAB_EXTENSIONS = 18

  def external_tool_tabs(opts, user)
    tools = Lti::ContextToolFinder
            .new(self, type: :account_navigation)
            .all_tools_scope_union.to_unsorted_array
            .select { |t| t.permission_given?(:account_navigation, user, self) && t.feature_flag_enabled?(self) }

    unless root_account?
      tools.reject! { |t| t.account_navigation[:root_account_only].to_s.downcase == "true" }
    end

    Lti::ExternalToolTab.new(self, :account_navigation, tools, opts[:language]).tabs
  end

  def tabs_available(user = nil, opts = {})
    manage_settings = user && grants_right?(user, :manage_account_settings)
    tabs = []
    if root_account.site_admin?
      tabs << { id: TAB_USERS, label: t("People"), css_class: "users", href: :account_users_path } if user && grants_right?(user, :read_roster)
      tabs << { id: TAB_PERMISSIONS, label: t("#account.tab_permissions", "Permissions"), css_class: "permissions", href: :account_permissions_path } if user && grants_right?(user, :manage_role_overrides)
      tabs << { id: TAB_SUB_ACCOUNTS, label: t("#account.tab_sub_accounts", "Sub-Accounts"), css_class: "sub_accounts", href: :account_sub_accounts_path } if manage_settings
      tabs << { id: TAB_AUTHENTICATION, label: t("#account.tab_authentication", "Authentication"), css_class: "authentication", href: :account_authentication_providers_path } if root_account? && manage_settings
      tabs << { id: TAB_PLUGINS, label: t("#account.tab_plugins", "Plugins"), css_class: "plugins", href: :plugins_path, no_args: true } if root_account? && grants_right?(user, :manage_site_settings)
      tabs << { id: TAB_RELEASE_NOTES, label: t("Release Notes"), css_class: "release_notes", href: :account_release_notes_manage_path } if root_account? && ReleaseNote.enabled? && grants_right?(user, :manage_release_notes)
      tabs << { id: TAB_JOBS, label: t("#account.tab_jobs", "Jobs"), css_class: "jobs", href: :jobs_path, no_args: true } if root_account? && grants_right?(user, :view_jobs)
    else
      tabs << { id: TAB_COURSES, label: t("#account.tab_courses", "Courses"), css_class: "courses", href: :account_path } if user && grants_right?(user, :read_course_list)
      tabs << { id: TAB_USERS, label: t("People"), css_class: "users", href: :account_users_path } if user && grants_right?(user, :read_roster)
      tabs << { id: TAB_STATISTICS, label: t("#account.tab_statistics", "Statistics"), css_class: "statistics", href: :statistics_account_path } if user && grants_right?(user, :view_statistics)
      tabs << { id: TAB_PERMISSIONS, label: t("#account.tab_permissions", "Permissions"), css_class: "permissions", href: :account_permissions_path } if user && grants_right?(user, :manage_role_overrides)
      if user && grants_right?(user, :manage_outcomes)
        tabs << { id: TAB_OUTCOMES, label: t("#account.tab_outcomes", "Outcomes"), css_class: "outcomes", href: :account_outcomes_path }
      end
      if can_see_rubrics_tab?(user)
        tabs << { id: TAB_RUBRICS, label: t("#account.tab_rubrics", "Rubrics"), css_class: "rubrics", href: :account_rubrics_path }
      end

      grading_settings_href = if Account.site_admin.feature_enabled?(:grading_scheme_updates)
                                :account_grading_settings_path
                              else
                                :account_grading_standards_path
                              end
      tabs << { id: TAB_GRADING_STANDARDS, label: t("#account.tab_grading_standards", "Grading"), css_class: "grading_standards", href: grading_settings_href } if user && grants_right?(user, :manage_grades)
      tabs << { id: TAB_QUESTION_BANKS, label: t("#account.tab_question_banks", "Question Banks"), css_class: "question_banks", href: :account_question_banks_path } if user && grants_any_right?(user, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS)
      tabs << { id: TAB_SUB_ACCOUNTS, label: t("#account.tab_sub_accounts", "Sub-Accounts"), css_class: "sub_accounts", href: :account_sub_accounts_path } if manage_settings
      tabs << { id: TAB_ACCOUNT_CALENDARS, label: t("Account Calendars"), css_class: "account_calendars", href: :account_calendar_settings_path } if user && grants_right?(user, :manage_account_calendar_visibility)
      tabs << { id: TAB_FACULTY_JOURNAL, label: t("#account.tab_faculty_journal", "Faculty Journal"), css_class: "faculty_journal", href: :account_user_notes_path } if enable_user_notes && user && grants_right?(user, :manage_user_notes)
      tabs << { id: TAB_TERMS, label: t("#account.tab_terms", "Terms"), css_class: "terms", href: :account_terms_path } if root_account? && manage_settings
      tabs << { id: TAB_AUTHENTICATION, label: t("#account.tab_authentication", "Authentication"), css_class: "authentication", href: :account_authentication_providers_path } if root_account? && manage_settings
      if root_account? && allow_sis_import && user && grants_any_right?(user, :manage_sis, :import_sis)
        tabs << { id: TAB_SIS_IMPORT,
                  label: t("#account.tab_sis_import", "SIS Import"),
                  css_class: "sis_import",
                  href: :account_sis_import_path }
      end
    end

    tabs << { id: TAB_BRAND_CONFIGS, label: t("#account.tab_brand_configs", "Themes"), css_class: "brand_configs", href: :account_brand_configs_path } if manage_settings && branding_allowed?

    if root_account? && grants_right?(user, :manage_developer_keys)
      tabs << { id: TAB_DEVELOPER_KEYS, label: t("#account.tab_developer_keys", "Developer Keys"), css_class: "developer_keys", href: :account_developer_keys_path, account_id: root_account.id }
    end

    if root_account? && grants_right?(user, :manage_developer_keys) && root_account.feature_enabled?(:lti_registrations_page)
      registrations_path = root_account.feature_enabled?(:lti_registrations_discover_page) ? :account_lti_registrations_path : :account_lti_manage_registrations_path
      tabs << { id: TAB_EXTENSIONS, label: t("#account.tab_extensions", "Extensions"), css_class: "extensions", href: registrations_path, account_id: root_account.id }
    end

    tabs += external_tool_tabs(opts, user)
    tabs += Lti::MessageHandler.lti_apps_tabs(self, [Lti::ResourcePlacement::ACCOUNT_NAVIGATION], opts)
    Lti::ResourcePlacement.update_tabs_and_return_item_banks_tab(tabs)
    tabs << { id: TAB_ADMIN_TOOLS, label: t("#account.tab_admin_tools", "Admin Tools"), css_class: "admin_tools", href: :account_admin_tools_path } if can_see_admin_tools_tab?(user)
    if user && grants_right?(user, :moderate_user_content)
      tabs << {
        id: TAB_EPORTFOLIO_MODERATION,
        label: t("ePortfolio Moderation"),
        css_class: "eportfolio_moderation",
        href: :account_eportfolio_moderation_path
      }
    end
    tabs << { id: TAB_SETTINGS, label: t("#account.tab_settings", "Settings"), css_class: "settings", href: :account_settings_path }
    tabs.delete_if { |t| t[:visibility] == "admins" } unless grants_right?(user, :manage)
    tabs
  end

  def can_see_rubrics_tab?(user)
    user && grants_right?(user, :manage_rubrics)
  end

  def can_see_admin_tools_tab?(user)
    return false if !user || root_account.site_admin?

    admin_tool_permissions = RoleOverride.manageable_permissions(self).find_all { |p| p[1][:admin_tool] }
    admin_tool_permissions.any? do |p|
      grants_right?(user, p.first)
    end
  end

  def is_a_context?
    true
  end

  def help_links
    links = settings[:custom_help_links]

    # set the type to custom for any existing custom links that don't have a type set
    # the new ui will set the type ('custom' or 'default') for any new custom links
    # since we now allow reordering the links, the default links get stored in the settings as well
    unless links.blank?
      links.each do |link|
        if link[:type].blank?
          link[:type] = "custom"
        end
      end
      links = help_links_builder.map_default_links(links)
    end

    result = if settings[:new_custom_help_links]
               links || help_links_builder.default_links
             else
               help_links_builder.default_links + (links || [])
             end
    filtered_result = help_links_builder.filtered_links(result)
    help_links_builder.instantiate_links(filtered_result)
  end

  def help_links_builder
    @help_links_builder ||= HelpLinks.new(self)
  end

  def set_service_availability(service, enable)
    service = service.to_sym
    raise "Invalid Service" unless AccountServices.allowable_services[service]

    allowed_service_names = (allowed_services || "").split(",").compact
    # rubocop:disable Style/IdenticalConditionalBranches common line needs to happen after the conditional
    if allowed_service_names.count > 0 && !["+", "-"].include?(allowed_service_names[0][0, 1])
      allowed_service_names.reject! { |flag| flag.match("^[+-]?#{service}$") }
      # This account has a hard-coded list of services, so handle accordingly
      allowed_service_names << service if enable
    else
      allowed_service_names.reject! { |flag| flag.match("^[+-]?#{service}$") }
      if enable
        # only enable if it is not enabled by default
        allowed_service_names << "+#{service}" unless AccountServices.default_allowable_services[service]
      elsif AccountServices.default_allowable_services[service]
        # only disable if it is not enabled by default
        allowed_service_names << "-#{service}"
      end
    end
    # rubocop:enable Style/IdenticalConditionalBranches

    @allowed_services_hash = nil
    self.allowed_services = allowed_service_names.empty? ? nil : allowed_service_names.join(",")
  end

  def enable_service(service)
    set_service_availability(service, true)
  end

  def disable_service(service)
    set_service_availability(service, false)
  end

  def allowed_services_hash
    return @allowed_services_hash if @allowed_services_hash

    account_allowed_services = AccountServices.default_allowable_services
    if allowed_services
      allowed_service_names = allowed_services.split(",").compact

      if allowed_service_names.count > 0
        unless ["+", "-"].member?(allowed_service_names[0][0, 1])
          # This account has a hard-coded list of services, so we clear out the defaults
          account_allowed_services = AccountServices::AllowedServicesHash.new
        end

        allowed_service_names.each do |service_switch|
          next unless service_switch =~ /\A([+-]?)(.*)\z/

          flag = $1
          service_name = $2.to_sym

          if flag == "-"
            account_allowed_services.delete(service_name)
          else
            account_allowed_services[service_name] = AccountServices.allowable_services[service_name]
          end
        end
      end
    end
    @allowed_services_hash = account_allowed_services
  end

  # if expose_as is nil, all services exposed in the ui are returned
  # if it's :service or :setting, then only services set to be exposed as that type are returned
  def self.services_exposed_to_ui_hash(expose_as = nil, current_user = nil, account = nil)
    if expose_as
      AccountServices.allowable_services.select { |_, setting| setting[:expose_to_ui] == expose_as }
    else
      AccountServices.allowable_services.select { |_, setting| setting[:expose_to_ui] }
    end.reject { |_, setting| setting[:expose_to_ui_proc] && !setting[:expose_to_ui_proc].call(current_user, account) }
  end

  def service_enabled?(service)
    service = service.to_sym
    case service
    when :none
      allowed_services_hash.empty?
    else
      allowed_services_hash.key?(service)
    end
  end

  def self.all_accounts_for(context)
    if context.respond_to?(:account)
      context.account.account_chain
    elsif context.respond_to?(:parent_account)
      context.account_chain
    else
      []
    end
  end

  def find_child(child_id)
    return all_accounts.find(child_id) if root_account?

    child = Account.find(child_id)
    raise ActiveRecord::RecordNotFound unless child.account_chain.include?(self)

    child
  end

  def manually_created_courses_account
    return root_account.manually_created_courses_account unless root_account?

    display_name = t("#account.manually_created_courses", "Manually-Created Courses")
    acct = manually_created_courses_account_from_settings
    if acct.blank?
      GuardRail.activate(:primary) do
        transaction do
          lock!
          acct = manually_created_courses_account_from_settings
          acct ||= sub_accounts.where(name: display_name).first_or_create! # for backwards compatibility
          if acct.id != settings[:manually_created_courses_account_id]
            settings[:manually_created_courses_account_id] = acct.id
            save!
          end
        end
      end
    end
    acct
  end

  def manually_created_courses_account_from_settings
    acct_id = settings[:manually_created_courses_account_id]
    acct = sub_accounts.where(id: acct_id).first if acct_id.present?
    acct = nil if acct.present? && acct.root_account_id != id
    acct
  end
  private :manually_created_courses_account_from_settings

  def trusted_account_ids
    return [] if !root_account? || self == Account.site_admin

    [Account.site_admin.id]
  end

  def trust_exists?
    false
  end

  def user_list_search_mode_for(user)
    return :preferred if root_account.open_registration?
    return :preferred if root_account.grants_right?(user, :manage_user_logins)

    :closed
  end

  scope :root_accounts, -> { where("(accounts.root_account_id = 0 OR accounts.root_account_id IS NULL) AND accounts.id != 0") }
  scope :non_root_accounts, -> { where("(accounts.root_account_id != 0 AND accounts.root_account_id IS NOT NULL)") }
  scope :processing_sis_batch, -> { where.not(accounts: { current_sis_batch_id: nil }).order(:updated_at) }
  scope :name_like, ->(name) { where(wildcard("accounts.name", name)) }
  scope :active, -> { where("accounts.workflow_state<>'deleted'") }
  scope :auto_subscribe_calendar, -> { where(account_calendar_subscription_type: "auto") }

  def self.resolved_root_account_id_sql(table = table_name)
    quoted_table_name = connection.quote_local_table_name(table)
    %{COALESCE(NULLIF(#{quoted_table_name}.root_account_id, 0), #{quoted_table_name}."id")}
  end

  def change_root_account_setting!(setting_name, new_value)
    root_account.settings[setting_name] = new_value
    root_account.save!
  end

  Bookmarker = BookmarkedCollection::SimpleBookmarker.new(Account, :name, :id)

  def format_referer(referer_url)
    begin
      referer = URI(referer_url || "")
    rescue URI::Error
      return
    end
    return unless referer.host

    referer_with_port = "#{referer.scheme}://#{referer.host}"
    referer_with_port += ":#{referer.port}" unless referer.port == ((referer.scheme == "https") ? 443 : 80)
    referer_with_port
  end

  def trusted_referers=(value)
    settings[:trusted_referers] = unless value.blank?
                                    value.split(",").filter_map { |referer_url| format_referer(referer_url) }.join(",")
                                  end
  end

  def trusted_referer?(referer_url)
    return false if !settings.key?(:trusted_referers) || settings[:trusted_referers].blank?

    if (referer_with_port = format_referer(referer_url))
      settings[:trusted_referers].split(",").include?(referer_with_port)
    end
  end

  def parent_registration?
    authentication_providers.where(parent_registration: true).exists?
  end

  def parent_registration_ap
    authentication_providers.where(parent_registration: true).first
  end

  def require_email_for_registration?
    Canvas::Plugin.value_to_boolean(settings[:require_email_for_registration]) || false
  end

  def to_param
    return "site_admin" if site_admin?

    super
  end

  def create_default_objects
    return if dummy?

    work = lambda do
      default_enrollment_term
      enable_canvas_authentication
      TermsOfService.ensure_terms_for_account(self, true) if root_account? && !TermsOfService.skip_automatic_terms_creation
      create_built_in_roles if root_account?
    end
    return work.call if Rails.env.test?

    self.class.connection.after_transaction_commit(&work)
  end

  def create_built_in_roles
    return if dummy?

    shard.activate do
      Role::BASE_TYPES.each do |base_type|
        role = Role.new
        role.name = base_type
        role.base_role_type = base_type
        role.workflow_state = :built_in
        role.root_account_id = id
        role.save!
      end
    end
  end

  def migrate_to_canvadocs?
    Canvadocs.hijack_crocodoc_sessions?
  end

  def update_terms_of_service(terms_params)
    terms = TermsOfService.ensure_terms_for_account(self)
    terms.terms_type = terms_params[:terms_type] if terms_params[:terms_type]
    terms.passive = Canvas::Plugin.value_to_boolean(terms_params[:passive]) if terms_params.key?(:passive)

    if terms.custom?
      TermsOfServiceContent.ensure_content_for_account(self)
      terms_of_service_content.update_attribute(:content, terms_params[:content]) if terms_params[:content]
    end

    if terms.changed? && !terms.save
      errors.add(:terms_of_service, t("Terms of Service attributes not valid"))
    end
  end

  # Different views are available depending on feature flags
  def dashboard_views
    %w[activity cards planner]
  end

  # Getter/Setter for default_dashboard_view account setting
  def default_dashboard_view=(view)
    return unless dashboard_views.include?(view)

    settings[:default_dashboard_view] = view
  end

  def default_dashboard_view
    @default_dashboard_view ||= settings[:default_dashboard_view]
  end

  # Forces the default setting to overwrite each user's preference
  def update_user_dashboards
    User.where(id: root_account.pseudonyms.active.joins(:user).where("#{User.table_name}.preferences LIKE ?", "%:dashboard_view:%").select(:user_id)).find_in_batches do |batch|
      users = batch.reject do |user|
        user.preferences[:dashboard_view].nil? ||
          user.dashboard_view(self) == default_dashboard_view
      end
      users.each do |user|
        # don't write to the shadow record
        user.reload unless user.canonical?

        user.preferences.delete(:dashboard_view)
        user.save!
      end
    end
  end
  handle_asynchronously :update_user_dashboards, priority: Delayed::LOW_PRIORITY, max_attempts: 1

  def clear_k5_cache
    User.of_account(self).find_in_batches do |users|
      User.clear_cache_keys(users.pluck(:id), :k5_user)
    end
  end
  handle_asynchronously :clear_k5_cache, priority: Delayed::LOW_PRIORITY, max_attempts: 1

  def process_external_integration_keys(params_keys, current_user, keys = ExternalIntegrationKey.indexed_keys_for(self))
    return unless params_keys

    keys.each do |key_type, key|
      next unless params_keys.key?(key_type)
      next unless key.grants_right?(current_user, :write)

      if params_keys[key_type].blank?
        key.delete
      else
        key.key_value = params_keys[key_type]
        key.save!
      end
    end
  end

  def available_course_visibility_override_options(options = nil)
    options || {}
  end

  def user_needs_verification?(user)
    require_confirmed_email? && (user.nil? || user.cached_active_emails.none?)
  end

  def allow_disable_post_to_sis_when_grading_period_closed?
    return false unless root_account?

    feature_enabled?(:disable_post_to_sis_when_grading_period_closed) && feature_enabled?(:new_sis_integrations)
  end

  def grading_standard_read_permission
    :read
  end

  def grading_standard_enabled
    default_grading_standard.present?
  end
  alias_method :grading_standard_enabled?, :grading_standard_enabled

  def default_grading_standard
    account_chain.find(&:grading_standard_id)&.grading_standard
  end

  class << self
    attr_accessor :current_domain_root_account
  end

  module DomainRootAccountCache
    def find_one(id)
      return Account.current_domain_root_account if Account.current_domain_root_account &&
                                                    Account.current_domain_root_account.shard == shard_value &&
                                                    Account.current_domain_root_account.local_id == id

      super
    end

    def find_take
      return super unless where_clause.send(:predicates).length == 1

      predicates = where_clause.to_h
      return super unless predicates.length == 1
      return super unless predicates.keys.first == "id"
      return Account.current_domain_root_account if Account.current_domain_root_account &&
                                                    Account.current_domain_root_account.shard == shard_value &&
                                                    Account.current_domain_root_account.local_id == predicates.values.first

      super
    end
  end

  relation_delegate_class(ActiveRecord::Relation).prepend(DomainRootAccountCache)
  relation_delegate_class(ActiveRecord::AssociationRelation).prepend(DomainRootAccountCache)

  def self.ensure_dummy_root_account
    return unless Rails.env.test?

    dummy = Account.find_by(id: 0)
    return if dummy

    # this needs to be thread safe because parallel specs might all try to create at once
    transaction(requires_new: true) do
      Account.create!(id: 0, workflow_state: "deleted", name: "Dummy Root Account", root_account_id: 0)
    rescue ActiveRecord::UniqueConstraintViolation
      # somebody else created it. we don't even need to return it, just clean up the transaction
      raise ActiveRecord::Rollback
    end
  end

  def roles_with_enabled_permission(permission)
    roles = available_roles
    roles.select do |role|
      RoleOverride.permission_for(self, permission, role, self, true)[:enabled]
    end
  end

  def get_rce_favorite_tool_ids
    rce_favorite_tool_ids[:value] ||
      Lti::ContextToolFinder.all_tools_for(self, placements: [:editor_button]) # TODO: remove after datafixup and the is_rce_favorite column is removed
                            .where(is_rce_favorite: true).pluck(:id).map { |id| Shard.global_id_for(id) }
  end

  def effective_course_template
    owning_account = account_chain.find(&:course_template_id)
    return nil unless owning_account
    return nil if owning_account.course_template_id == 0

    owning_account.course_template
  end

  def student_reporting?
    false
  end

  def log_rqd_setting_enable_or_disable
    return unless saved_changes.key?("settings") # Skip if no settings were changed

    setting_changes = saved_changes[:settings]
    old_rqd_setting = setting_changes[0].dig(:restrict_quantitative_data, :value)
    new_rqd_setting = setting_changes[1].dig(:restrict_quantitative_data, :value)

    return unless old_rqd_setting != new_rqd_setting # Skip if RQD setting was not changed

    # If an account's RQD setting hasn't been changed before, old_rqd_setting will be nil
    if (old_rqd_setting == false || old_rqd_setting.nil?) && new_rqd_setting == true
      InstStatsd::Statsd.increment("account.settings.restrict_quantitative_data.enabled")
    elsif old_rqd_setting == true && new_rqd_setting == false
      InstStatsd::Statsd.increment("account.settings.restrict_quantitative_data.disabled")
    end
  end

  def remove_template_id
    if has_attribute?(:course_template_id)
      self.course_template_id = nil
    end
  end

  def enable_user_notes
    return false if Account.site_admin.feature_enabled?(:deprecate_faculty_journal)

    read_attribute(:enable_user_notes)
  end
end
