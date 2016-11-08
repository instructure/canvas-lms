#
# Copyright (C) 2011 - 2016 Instructure, Inc.
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

class Account < ActiveRecord::Base
  include Context
  strong_params

  INSTANCE_GUID_SUFFIX = 'canvas-lms'

  include Workflow
  include BrandConfigHelpers
  belongs_to :parent_account, :class_name => 'Account'
  belongs_to :root_account, :class_name => 'Account'
  authenticates_many :pseudonym_sessions
  has_many :courses
  has_many :all_courses, :class_name => 'Course', :foreign_key => 'root_account_id'
  has_many :group_categories, -> { where(deleted_at: nil) }, as: :context
  has_many :all_group_categories, :class_name => 'GroupCategory', :as => :context
  has_many :groups, :as => :context
  has_many :all_groups, :class_name => 'Group', :foreign_key => 'root_account_id'
  has_many :all_group_memberships, source: 'group_memberships', through: :all_groups
  has_many :enrollment_terms, :foreign_key => 'root_account_id'
  has_many :active_enrollment_terms, -> { where("enrollment_terms.workflow_state<>'deleted'") }, class_name: 'EnrollmentTerm', foreign_key: 'root_account_id'
  has_many :grading_period_groups, inverse_of: :root_account, dependent: :destroy
  has_many :grading_periods, through: :grading_period_groups
  has_many :enrollments, -> { where("enrollments.type<>'StudentViewEnrollment'") }, foreign_key: 'root_account_id'
  has_many :all_enrollments, :class_name => 'Enrollment', :foreign_key => 'root_account_id'
  has_many :sub_accounts, -> { where("workflow_state<>'deleted'") }, class_name: 'Account', foreign_key: 'parent_account_id'
  has_many :all_accounts, -> { order(:name) }, class_name: 'Account', foreign_key: 'root_account_id'
  has_many :account_users, :dependent => :destroy
  has_many :course_sections, :foreign_key => 'root_account_id'
  has_many :sis_batches
  has_many :abstract_courses, :class_name => 'AbstractCourse', :foreign_key => 'account_id'
  has_many :root_abstract_courses, :class_name => 'AbstractCourse', :foreign_key => 'root_account_id'
  has_many :users, :through => :account_users
  has_many :pseudonyms, -> { preload(:user) }, inverse_of: :account
  has_many :role_overrides, :as => :context
  has_many :course_account_associations
  has_many :child_courses, -> { where(course_account_associations: { depth: 0 }) }, through: :course_account_associations, source: :course
  has_many :attachments, :as => :context, :dependent => :destroy
  has_many :active_assignments, -> { where("assignments.workflow_state<>'deleted'") }, as: :context, class_name: 'Assignment'
  has_many :folders, -> { order('folders.name') }, as: :context, dependent: :destroy
  has_many :active_folders, -> { where("folder.workflow_state<>'deleted'").order('folders.name') }, class_name: 'Folder', as: :context
  has_many :developer_keys
  has_many :authentication_providers,
           -> { order(:position) },
           extend: AccountAuthorizationConfig::FindWithType,
           class_name: "AccountAuthorizationConfig"

  has_many :account_reports
  has_many :grading_standards, -> { where("workflow_state<>'deleted'") }, as: :context
  has_many :assessment_questions, :through => :assessment_question_banks
  has_many :assessment_question_banks, -> { preload(:assessment_questions, :assessment_question_bank_users) }, as: :context
  has_many :roles
  has_many :all_roles, :class_name => 'Role', :foreign_key => 'root_account_id'
  has_many :progresses, :as => :context
  has_many :content_migrations, :as => :context

  def inherited_assessment_question_banks(include_self = false, *additional_contexts)
    sql = []
    conds = []
    contexts = additional_contexts + account_chain
    contexts.delete(self) unless include_self
    contexts.each { |c|
      sql << "context_type = ? AND context_id = ?"
      conds += [c.class.to_s, c.id]
    }
    conds.unshift(sql.join(" OR "))
    AssessmentQuestionBank.where(conds)
  end

  include LearningOutcomeContext
  include RubricContext

  has_many :context_external_tools, -> { order(:name) }, as: :context, dependent: :destroy
  has_many :error_reports
  has_many :announcements, :class_name => 'AccountNotification'
  has_many :alerts, -> { preload(:criteria) }, as: :context
  has_many :user_account_associations
  has_many :report_snapshots
  has_many :external_integration_keys, :as => :context, :dependent => :destroy
  has_many :shared_brand_configs
  belongs_to :brand_config, foreign_key: "brand_config_md5"

  before_validation :verify_unique_sis_source_id
  before_save :ensure_defaults
  after_save :update_account_associations_if_changed

  before_save :setup_cache_invalidation
  after_save :invalidate_caches_if_changed
  after_update :clear_special_account_cache_if_special

  after_create :default_enrollment_term
  after_create :enable_canvas_authentication

  serialize :settings, Hash
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

  validates_locale :default_locale, :allow_nil => true
  validates_length_of :name, :maximum => maximum_string_length, :allow_blank => true
  validate :account_chain_loop, :if => :parent_account_id_changed?
  validate :validate_auth_discovery_url
  validates_presence_of :workflow_state

  include StickySisFields
  are_sis_sticky :name

  include FeatureFlags

  def default_locale(recurse = false)
    result = read_attribute(:default_locale)
    if recurse
      result ||= Rails.cache.fetch(['default_locale', self.global_id].cache_key) do
        parent_account.default_locale(true) if parent_account
      end
    end
    result = nil unless I18n.locale_available?(result)
    result
  end

  include ::Account::Settings

  # these settings either are or could be easily added to
  # the account settings page
  add_setting :sis_app_token, :root_only => true
  add_setting :sis_app_url, :root_only => true
  add_setting :sis_syncing, :boolean => true, :default => false, :inheritable => true
  add_setting :sis_default_grade_export, :boolean => true, :default => false, :inheritable => true

  add_setting :global_includes, :root_only => true, :boolean => true, :default => false
  add_setting :sub_account_includes, :boolean => true, :default => false
  add_setting :error_reporting, :hash => true, :values => [:action, :email, :url, :subject_param, :body_param], :root_only => true

  # Help link settings
  add_setting :custom_help_links, :root_only => true
  add_setting :help_link_icon, :root_only => true
  add_setting :help_link_name, :root_only => true
  add_setting :support_url, :root_only => true

  add_setting :prevent_course_renaming_by_teachers, :boolean => true, :root_only => true
  add_setting :login_handle_name, root_only: true
  add_setting :change_password_url, root_only: true
  add_setting :unknown_user_url, root_only: true
  add_setting :fft_registration_url, root_only: true

  add_setting :restrict_student_future_view, :boolean => true, :default => false, :inheritable => true
  add_setting :restrict_student_future_listing, :boolean => true, :default => false, :inheritable => true
  add_setting :restrict_student_past_view, :boolean => true, :default => false, :inheritable => true

  add_setting :teachers_can_create_courses, :boolean => true, :root_only => true, :default => false
  add_setting :students_can_create_courses, :boolean => true, :root_only => true, :default => false
  add_setting :restrict_quiz_questions, :boolean => true, :root_only => true, :default => false
  add_setting :no_enrollments_can_create_courses, :boolean => true, :root_only => true, :default => false
  add_setting :allow_sending_scores_in_emails, :boolean => true, :root_only => true

  add_setting :self_enrollment
  add_setting :equella_endpoint
  add_setting :equella_teaser
  add_setting :enable_alerts, :boolean => true, :root_only => true
  add_setting :enable_eportfolios, :boolean => true, :root_only => true
  add_setting :users_can_edit_name, :boolean => true, :root_only => true
  add_setting :open_registration, :boolean => true, :root_only => true
  add_setting :show_scheduler, :boolean => true, :root_only => true, :default => false
  add_setting :enable_profiles, :boolean => true, :root_only => true, :default => false
  add_setting :mfa_settings, :root_only => true
  add_setting :admins_can_change_passwords, :boolean => true, :root_only => true, :default => false
  add_setting :admins_can_view_notifications, :boolean => true, :root_only => true, :default => false
  add_setting :canvadocs_prefer_office_online, :boolean => true, :root_only => true, :default => false
  add_setting :outgoing_email_default_name
  add_setting :external_notification_warning, :boolean => true, :default => false
  # Terms of Use and Privacy Policy settings for the root account
  add_setting :terms_changed_at, :root_only => true
  add_setting :account_terms_required, :root_only => true, :boolean => true, :default => true
  # When a user is invited to a course, do we let them see a preview of the
  # course even without registering?  This is part of the free-for-teacher
  # account perks, since anyone can invite anyone to join any course, and it'd
  # be nice to be able to see the course first if you weren't expecting the
  # invitation.
  add_setting :allow_invitation_previews, :boolean => true, :root_only => true, :default => false
  add_setting :large_course_rosters, :boolean => true, :root_only => true, :default => false
  add_setting :edit_institution_email, :boolean => true, :root_only => true, :default => true
  add_setting :js_kaltura_uploader, :boolean => true, :root_only => true, :default => false
  add_setting :google_docs_domain, root_only: true
  add_setting :dashboard_url, root_only: true
  add_setting :product_name, root_only: true
  add_setting :author_email_in_notifications, boolean: true, root_only: true, default: false
  add_setting :include_students_in_global_survey, boolean: true, root_only: true, default: false
  add_setting :trusted_referers, root_only: true
  add_setting :app_center_access_token

  add_setting :strict_sis_check, :boolean => true, :root_only => true, :default => false

  def settings=(hash)
    if hash.is_a?(Hash)
      hash.each do |key, val|
        if account_settings_options && account_settings_options[key.to_sym]
          opts = account_settings_options[key.to_sym]
          if (opts[:root_only] && !self.root_account?) || (opts[:condition] && !self.send("#{opts[:condition]}?".to_sym))
            settings.delete key.to_sym
          elsif opts[:hash]
            new_hash = {}
            if val.is_a?(Hash)
              val.each do |inner_key, inner_val|
                inner_key = inner_key.to_sym
                if opts[:values].include?(inner_key)
                  if opts[:inheritable] && (inner_key == :locked || (inner_key == :value && opts[:boolean]))
                    new_hash[inner_key] = Canvas::Plugin.value_to_boolean(inner_val)
                  else
                    new_hash[inner_key] = inner_val.to_s
                  end
                end
              end
            end
            settings[key.to_sym] = new_hash.empty? ? nil : new_hash
          elsif opts[:boolean]
            settings[key.to_sym] = Canvas::Plugin.value_to_boolean(val)
          else
            settings[key.to_sym] = val.to_s
          end
        end
      end
    end
    # prune nil or "" hash values to save space in the DB.
    settings.reject! { |_, value| value.nil? || value == "" }
    settings
  end

  def product_name
    settings[:product_name] || t("#product_name", "Canvas")
  end

  def allow_global_includes?
    if root_account?
      global_includes?
    else
      root_account.try(:sub_account_includes?) && root_account.try(:allow_global_includes?)
    end
  end


  def mfa_settings
    settings[:mfa_settings].try(:to_sym) || :disabled
  end

  def non_canvas_auth_configured?
    authentication_providers.active.where("auth_type<>'canvas'").exists?
  end

  def canvas_authentication_provider
    @canvas_ap ||= authentication_providers.active.where(auth_type: 'canvas').first
  end

  def canvas_authentication?
    !!canvas_authentication_provider
  end

  def enable_canvas_authentication
    return unless root_account?
    # for migrations creating a new db
    return unless AccountAuthorizationConfig::Canvas.columns_hash.key?('workflow_state')
    return if authentication_providers.active.where(auth_type: 'canvas').exists?
    authentication_providers.create!(auth_type: 'canvas')
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

  def self_registration_allowed_for?(type)
    return false unless self_registration?
    return false if self_registration_type != 'all' && type != self_registration_type
    true
  end

  def enable_self_registration
    canvas_authentication_provider.update_attribute(:self_registration, true)
  end

  def terms_required?
    Setting.get('terms_required', 'true') == 'true' && root_account.account_terms_required?
  end

  def require_acceptance_of_terms?(user)
    soc2_start_date = Setting.get('SOC2_start_date', Time.new(2015, 5, 16, 0, 0, 0).utc).to_datetime

    return false if !terms_required?
    return true if user.nil? || user.new_record?
    terms_changed_at = settings[:terms_changed_at]
    last_accepted = user.preferences[:accepted_terms]

    # make sure existing users are grandfathered in
    return false if terms_changed_at.nil? && user.registered? && user.created_at < soc2_start_date

    return false if last_accepted && (terms_changed_at.nil? || last_accepted > terms_changed_at)
    true
  end

  def ip_filters=(params)
    filters = {}
    require 'ipaddr'
    params.each do |key, str|
      ips = []
      vals = str.split(/,/)
      vals.each do |val|
        ip = IPAddr.new(val) rescue nil
        # right now the ip_filter column on quizzes is just a string,
        # so it has a max length.  I figure whatever we set it to this
        # setter should at the very least limit stored values to that
        # length.
        ips << val if ip && val.length <= 255
      end
      filters[key] = ips.join(',') unless ips.empty?
    end
    settings[:ip_filters] = filters
  end

  def ensure_defaults
    self.uuid ||= CanvasSlug.generate_securish_uuid
    self.lti_guid ||= "#{self.uuid}:#{INSTANCE_GUID_SUFFIX}" if self.respond_to?(:lti_guid)
    self.root_account_id ||= self.parent_account.root_account_id if self.parent_account
    self.root_account_id ||= self.parent_account_id
    self.parent_account_id ||= self.root_account_id
    Account.invalidate_cache(self.id) if self.id
    true
  end

  def verify_unique_sis_source_id
    return true unless self.sis_source_id
    return true if !root_account_id_changed? && !sis_source_id_changed?

    if self.root_account?
      self.errors.add(:sis_source_id, t('#account.root_account_cant_have_sis_id', "SIS IDs cannot be set on root accounts"))
      return false
    end

    scope = root_account.all_accounts.where(sis_source_id:  self.sis_source_id)
    scope = scope.where("id<>?", self) unless self.new_record?

    return true unless scope.exists?

    self.errors.add(:sis_source_id, t('#account.sis_id_in_use', "SIS ID \"%{sis_id}\" is already in use", :sis_id => self.sis_source_id))
    false
  end

  def update_account_associations_if_changed
    send_later_if_production(:update_account_associations) if self.parent_account_id_changed? || self.root_account_id_changed?
  end

  def equella_settings
    endpoint = self.settings[:equella_endpoint] || self.equella_endpoint
    if !endpoint.blank?
      OpenObject.new({
        :endpoint => endpoint,
        :default_action => self.settings[:equella_action] || 'selectOrAdd',
        :teaser => self.settings[:equella_teaser]
      })
    else
      nil
    end
  end

  def settings
    result = self.read_attribute(:settings)
    if result
      @old_settings ||= result.dup
      return result
    end
    return write_attribute(:settings, {}) unless frozen?
    {}.freeze
  end

  def domain
    HostUrl.context_host(self)
  end

  def self.find_by_domain(domain)
    self.default if HostUrl.default_host == domain
  end

  def root_account?
    !self.root_account_id
  end

  def root_account_with_self
    return self if self.root_account?
    root_account_without_self
  end
  alias_method_chain :root_account, :self

  def sub_accounts_as_options(indent = 0, preloaded_accounts = nil)
    unless preloaded_accounts
      preloaded_accounts = {}
      self.root_account.all_accounts.active.each do |account|
        (preloaded_accounts[account.parent_account_id] ||= []) << account
      end
    end
    res = [[("&nbsp;&nbsp;" * indent).html_safe + self.name, self.id]]
    if preloaded_accounts[self.id]
      preloaded_accounts[self.id].each do |account|
        res += account.sub_accounts_as_options(indent + 1, preloaded_accounts)
      end
    end
    res
  end

  def users_visible_to(user)
    self.grants_right?(user, :read) ? self.all_users : self.all_users.none
  end

  def users_name_like(query="")
    @cached_users_name_like ||= {}
    @cached_users_name_like[query] ||= self.fast_all_users.name_like(query)
  end

  def associated_courses
    if root_account?
      all_courses
    else
      shard.activate do
        Course.where("EXISTS (?)", CourseAccountAssociation.where(account_id: self).where("course_id=courses.id"))
      end
    end
  end

  def associated_user?(user)
    user_account_associations.where(user_id: user).exists?
  end

  def fast_course_base(opts = {})
    opts[:order] ||= "#{Course.best_unicode_collation_key("courses.name")} ASC"
    columns = "courses.id, courses.name, courses.workflow_state, courses.course_code, courses.sis_source_id, courses.enrollment_term_id"
    associated_courses = self.associated_courses.active.order(opts[:order])
    associated_courses = associated_courses.with_enrollments if opts[:hide_enrollmentless_courses]
    associated_courses = associated_courses.for_term(opts[:term]) if opts[:term].present?
    associated_courses = yield associated_courses if block_given?
    associated_courses.limit(opts[:limit]).active_first.select(columns).to_a
  end

  def fast_all_courses(opts={})
    @cached_fast_all_courses ||= {}
    @cached_fast_all_courses[opts] ||= self.fast_course_base(opts)
  end

  def all_users(limit=250)
    @cached_all_users ||= {}
    @cached_all_users[limit] ||= User.of_account(self).limit(limit)
  end

  def fast_all_users(limit=nil)
    @cached_fast_all_users ||= {}
    @cached_fast_all_users[limit] ||= self.all_users(limit).active.select("users.id, users.updated_at, users.name, users.sortable_name").order_by_sortable_name
  end

  def users_not_in_groups(groups, opts={})
    scope = User.active.joins(:user_account_associations).
      where(user_account_associations: {account_id: self}).
      where(Group.not_in_group_sql_fragment(groups.map(&:id))).
      select("users.id, users.name")
    scope = scope.select(opts[:order]).order(opts[:order]) if opts[:order]
    scope
  end

  def courses_name_like(query="", opts={})
    opts[:limit] ||= 200
    @cached_courses_name_like ||= {}
    @cached_courses_name_like[[query, opts]] ||= self.fast_course_base(opts) {|q| q.name_like(query)}
  end

  def self_enrollment_course_for(code)
    all_courses.
      where(:self_enrollment_code => code).
      first
  end

  def file_namespace
    Shard.birth.activate { "account_#{self.root_account.id}" }
  end

  def self.account_lookup_cache_key(id)
    ['_account_lookup4', id].cache_key
  end

  def self.invalidate_cache(id)
    return unless id
    birth_id = Shard.relative_id_for(id, Shard.current, Shard.birth)
    Shard.birth.activate do
      Rails.cache.delete(account_lookup_cache_key(birth_id)) if birth_id
    end
  rescue
    nil
  end

  def setup_cache_invalidation
    @invalidations = []
    unless self.new_record?
      invalidate_all = self.parent_account_id_changed?
      # apparently, the try_rescues are because these columns don't exist on old migrations
      @invalidations += ['default_storage_quota', 'current_quota'] if invalidate_all || self.try_rescue(:default_storage_quota_changed?)
      @invalidations << 'default_group_storage_quota' if invalidate_all || self.try_rescue(:default_group_storage_quota_changed?)
      @invalidations << 'default_locale' if invalidate_all || self.try_rescue(:default_locale_changed?)
    end
  end

  def invalidate_caches_if_changed
    @invalidations ||= []
    if self.parent_account_id_changed?
      @invalidations += Account.inheritable_settings # invalidate all of them
    elsif @old_settings
      Account.inheritable_settings.each do |key|
        @invalidations << key if @old_settings[key] != settings[key] # only invalidate if needed
      end
      @old_settings = nil
    end

    if @invalidations.present?
      shard.activate do
        @invalidations.each do |key|
          Rails.cache.delete([key, self.global_id].cache_key)
        end
        Account.send_later_if_production(:invalidate_inherited_caches, self, @invalidations)
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

  def self.default_storage_quota
    Setting.get('account_default_quota', 500.megabytes.to_s).to_i
  end

  def quota
    return storage_quota if read_attribute(:storage_quote)
    return self.class.default_storage_quota if root_account?

    shard.activate do
      Rails.cache.fetch(['current_quota', self.global_id].cache_key) do
        self.parent_account.default_storage_quota
      end
    end
  end

  def default_storage_quota
    return super if read_attribute(:default_storage_quota)
    return self.class.default_storage_quota if root_account?

    shard.activate do
      @default_storage_quota ||= Rails.cache.fetch(['default_storage_quota', self.global_id].cache_key) do
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
      Rails.cache.fetch(['default_group_storage_quota', self.global_id].cache_key) do
        self.parent_account.default_group_storage_quota
      end
    end
  end

  def default_group_storage_quota=(val)
    val = val.to_i
    if (val == Group.default_storage_quota) || (val <= 0) ||
        (self.parent_account && self.parent_account.default_group_storage_quota == val)
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
    self.turnitin_crypted_secret, self.turnitin_salt = Canvas::Security.encrypt_password(secret, 'instructure_turnitin_secret_shared')
  end

  def turnitin_shared_secret
    return nil unless self.turnitin_salt && self.turnitin_crypted_secret
    Canvas::Security.decrypt_password(self.turnitin_crypted_secret, self.turnitin_salt, 'instructure_turnitin_secret_shared')
  end

  def self.account_chain(starting_account_id)
    chain = []

    if (starting_account_id.is_a?(Account))
      chain << starting_account_id
      starting_account_id = starting_account_id.parent_account_id
    end

    if starting_account_id
      if ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'postgresql'
        chain.concat(Shard.shard_for(starting_account_id).activate do
          Account.find_by_sql(<<-SQL)
                WITH RECURSIVE t AS (
                  SELECT * FROM #{Account.quoted_table_name} WHERE id=#{Shard.local_id_for(starting_account_id).first}
                  UNION
                  SELECT accounts.* FROM #{Account.quoted_table_name} INNER JOIN t ON accounts.id=t.parent_account_id
                )
                SELECT * FROM t
          SQL
        end)
      else
        account = Account.find(starting_account_id)
        chain << account
        while account.parent_account
          account = account.parent_account
          chain << account
        end
      end
    end
    chain
  end

  def self.account_chain_ids(starting_account_id)
    if connection.adapter_name == 'PostgreSQL'
      Shard.shard_for(starting_account_id).activate do
        id_chain = []
        if (starting_account_id.is_a?(Account))
          id_chain << starting_account_id.id
          starting_account_id = starting_account_id.parent_account_id
        end

        if starting_account_id
          ids = Account.connection.select_values(<<-SQL)
                WITH RECURSIVE t AS (
                  SELECT * FROM #{Account.quoted_table_name} WHERE id=#{Shard.local_id_for(starting_account_id).first}
                  UNION
                  SELECT accounts.* FROM #{Account.quoted_table_name} INNER JOIN t ON accounts.id=t.parent_account_id
                )
                SELECT id FROM t
              SQL
          id_chain.concat(ids.map(&:to_i))
        end
        id_chain
      end
    else
      account_chain(starting_account_id).map(&:id)
    end
  end

  def self.add_site_admin_to_chain!(chain)
    chain << Account.site_admin unless chain.last.site_admin?
    chain
  end

  def account_chain(include_site_admin: false)
    @account_chain ||= Account.account_chain(self)
    result = @account_chain.dup
    Account.add_site_admin_to_chain!(result) if include_site_admin
    result
  end

  def account_chain_ids
    @cached_account_chain_ids ||= Account.account_chain_ids(self)
  end

  def account_chain_loop
    # this record hasn't been saved to the db yet, so if the the chain includes
    # this account, it won't point to the new parent yet, and should still be
    # valid
    if self.parent_account.account_chain.include?(self)
      errors.add(:parent_account_id,
                 "Setting account #{self.sis_source_id || self.id}'s parent to #{self.parent_account.sis_source_id || self.parent_account_id} would create a loop")
    end
  end

  # returns all sub_accounts recursively as far down as they go, in id order
  # because this uses a custom sql query for postgresql, we can't use a normal
  # named scope, so we pass the limit and offset into the method instead and
  # build our own query string
  def sub_accounts_recursive(limit, offset)
    if ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'postgresql'
      Account.find_by_sql([<<-SQL, self.id, limit.to_i, offset.to_i])
          WITH RECURSIVE t AS (
            SELECT * FROM #{Account.quoted_table_name}
            WHERE parent_account_id = ? AND workflow_state <>'deleted'
            UNION
            SELECT accounts.* FROM #{Account.quoted_table_name}
            INNER JOIN t ON accounts.parent_account_id = t.id
            WHERE accounts.workflow_state <>'deleted'
          )
          SELECT * FROM t ORDER BY parent_account_id, id LIMIT ? OFFSET ?
      SQL
    else
      account_descendents = lambda do |id|
        as = Account.where(:parent_account_id => id).active.order(:id)
        as.empty? ?
          [] :
          as << as.map { |a| account_descendents.call(a.id) }
      end
      account_descendents.call(id).flatten[offset, limit]
    end
  end

  def self.sub_account_ids_recursive(parent_account_id)
    if connection.adapter_name == 'PostgreSQL'
      sql = Account.sub_account_ids_recursive_sql(parent_account_id)
      Account.find_by_sql(sql).map(&:id)
    else
      account_descendants = lambda do |ids|
        as = Account.where(:parent_account_id => ids).active.pluck(:id)
        as + account_descendants.call(as)
      end
      account_descendants.call([parent_account_id])
    end
  end

  def self.sub_account_ids_recursive_sql(parent_account_id)
    "WITH RECURSIVE t AS (
       SELECT id, parent_account_id FROM #{Account.quoted_table_name}
       WHERE parent_account_id = #{parent_account_id} AND workflow_state <> 'deleted'
       UNION
       SELECT accounts.id, accounts.parent_account_id FROM #{Account.quoted_table_name}
       INNER JOIN t ON accounts.parent_account_id = t.id
       WHERE accounts.workflow_state <> 'deleted'
     )
     SELECT id FROM t"
  end

  def associated_accounts
    self.account_chain
  end

  def membership_for_user(user)
    self.account_users.where(user_id: user).first if user
  end

  def available_custom_account_roles(include_inactive=false)
    available_custom_roles(include_inactive).for_accounts.to_a
  end

  def available_account_roles(include_inactive=false, user = nil)
    account_roles = available_custom_account_roles(include_inactive)
    account_roles << Role.get_built_in_role('AccountAdmin')
    if user
      account_roles.select! { |role| au = account_users.new; au.role_id = role.id; au.grants_right?(user, :create) }
    end
    account_roles
  end

  def available_custom_course_roles(include_inactive=false)
    available_custom_roles(include_inactive).for_courses.to_a
  end

  def available_course_roles(include_inactive=false)
    course_roles = available_custom_course_roles(include_inactive)
    course_roles += Role.built_in_course_roles
    course_roles
  end

  def available_custom_roles(include_inactive=false)
    scope = Role.where(:account_id => account_chain_ids)
    scope = include_inactive ? scope.not_deleted : scope.active
    scope
  end

  def available_roles(include_inactive=false)
    available_account_roles(include_inactive) + available_course_roles(include_inactive)
  end

  def get_account_role_by_name(role_name)
    role = get_role_by_name(role_name)
    return role if role && role.account_role?
  end

  def get_course_role_by_name(role_name)
    role = get_role_by_name(role_name)
    return role if role && role.course_role?
  end

  def get_role_by_name(role_name)
    if role = Role.get_built_in_role(role_name)
      return role
    end

    self.shard.activate do
      role_scope = Role.not_deleted.where(:name => role_name)
      if self.class.connection.adapter_name == 'PostgreSQL'
        role_scope = role_scope.where("account_id = ? OR
          account_id IN (
            WITH RECURSIVE t AS (
              SELECT id, parent_account_id FROM #{Account.quoted_table_name} WHERE id = ?
              UNION
              SELECT accounts.id, accounts.parent_account_id FROM #{Account.quoted_table_name} INNER JOIN t ON accounts.id=t.parent_account_id
            )
            SELECT id FROM t
          )", self.id, self.id)
      else
        role_scope = role_scope.where(:account_id => self.account_chain.map(&:id))
      end

      role_scope.first
    end
  end

  def get_role_by_id(role_id)
    role = Role.get_role_by_id(role_id)
    return role if valid_role?(role)
  end

  def valid_role?(role)
    role && (role.built_in? || (self.id == role.account_id) || self.account_chain_ids.include?(role.account_id))
  end

  def login_handle_name_is_customized?
    self.login_handle_name.present?
  end

  def login_handle_name_with_inference
    if login_handle_name_is_customized?
      self.login_handle_name
    elsif self.delegated_authentication?
      AccountAuthorizationConfig.default_delegated_login_handle_name
    else
      AccountAuthorizationConfig.default_login_handle_name
    end
  end

  def self_and_all_sub_accounts
    @self_and_all_sub_accounts ||= Account.where("root_account_id=? OR parent_account_id=?", self, self).pluck(:id).uniq + [self.id]
  end

  workflow do
    state :active
    state :deleted
  end

  def account_users_for(user)
    return [] unless user
    @account_users_cache ||= {}
    if self == Account.site_admin
      shard.activate do
        @account_users_cache[user.global_id] ||= begin
          all_site_admin_account_users_hash = MultiCache.fetch("all_site_admin_account_users3") do
            # this is a plain ruby hash to keep the cached portion as small as possible
            self.account_users.inject({}) { |result, au| result[au.user_id] ||= []; result[au.user_id] << [au.id, au.role_id]; result }
          end
          (all_site_admin_account_users_hash[user.id] || []).map do |(id, role_id)|
            au = AccountUser.new
            au.id = id
            au.account = Account.site_admin
            au.user = user
            au.role_id = role_id
            au.readonly!
            au
          end
        end
      end
    else
      @account_chain_ids ||= self.account_chain(:include_site_admin => true).map { |a| a.active? ? a.id : nil }.compact
      @account_users_cache[user.global_id] ||= Shard.partition_by_shard(@account_chain_ids) do |account_chain_ids|
        if account_chain_ids == [Account.site_admin.id]
          Account.site_admin.account_users_for(user)
        else
          AccountUser.where(:account_id => account_chain_ids, :user_id => user).to_a
        end
      end
    end
    @account_users_cache[user.global_id] ||= []
    @account_users_cache[user.global_id]
  end

  # returns all account users for this entire account tree
  def all_account_users_for(user)
    raise "must be a root account" unless self.root_account?
    Shard.partition_by_shard(account_chain(include_site_admin: true).uniq) do |accounts|
      next unless user.associated_shards.include?(Shard.current)
      AccountUser.eager_load(:account).where("user_id=? AND (root_account_id IN (?) OR account_id IN (?))", user, accounts, accounts)
    end
  end

  set_policy do
    enrollment_types = RoleOverride.enrollment_type_labels.map { |role| role[:name] }
    RoleOverride.permissions.each do |permission, details|
      given { |user| self.account_users_for(user).any? { |au| au.has_permission_to?(self, permission) && (!details[:if] || send(details[:if])) } }
      can permission
      can :create_courses if permission == :manage_courses
    end

    given { |user| !self.account_users_for(user).empty? }
    can :read and can :manage and can :update and can :delete and can :read_outcomes

    given { |user|
      result = false

      if !root_account.site_admin? && user
        scope = root_account.enrollments.active.where(user_id: user)
        result = root_account.teachers_can_create_courses? &&
            scope.where(:type => ['TeacherEnrollment', 'DesignerEnrollment']).exists?
        result ||= root_account.students_can_create_courses? &&
            scope.where(:type => ['StudentEnrollment', 'ObserverEnrollment']).exists?
        result ||= root_account.no_enrollments_can_create_courses? &&
            !scope.exists?
      end

      result
    }
    can :create_courses

    # any logged in user can read global outcomes, but must be checked against the site admin
    given{ |user| self.site_admin? && user }
    can :read_global_outcomes

    # any user with an association to this account can read the outcomes in the account
    given{ |user| user && self.user_account_associations.where(user_id: user).exists? }
    can :read_outcomes

    # any user with an admin enrollment in one of the courses can read
    given { |user| user && self.courses.where(:id => user.enrollments.admin.pluck(:course_id)).exists? }
    can :read

    given { |user| self.grants_right?(user, :lti_add_edit)}
    can :create_tool_manually
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now.utc
    save!
  end

  def to_atom
    Atom::Entry.new do |entry|
      entry.title     = self.name
      entry.updated   = self.updated_at
      entry.published = self.created_at
      entry.links    << Atom::Link.new(:rel => 'alternate',
                                    :href => "/accounts/#{self.id}")
    end
  end

  def default_enrollment_term
    return @default_enrollment_term if @default_enrollment_term
    if self.root_account?
      @default_enrollment_term = self.enrollment_terms.active.where(name: EnrollmentTerm::DEFAULT_TERM_NAME).first_or_create
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
    authentication_providers.active.first.is_a?(AccountAuthorizationConfig::Delegated)
  end

  def forgot_password_external_url
    self.change_password_url
  end

  def auth_discovery_url=(url)
    self.settings[:auth_discovery_url] = url
  end

  def auth_discovery_url
    self.settings[:auth_discovery_url]
  end

  def login_handle_name=(handle_name)
    self.settings[:login_handle_name] = handle_name
  end

  def login_handle_name
    self.settings[:login_handle_name]
  end

  def change_password_url=(change_password_url)
    self.settings[:change_password_url] = change_password_url
  end

  def change_password_url
    self.settings[:change_password_url]
  end

  def unknown_user_url=(unknown_user_url)
    self.settings[:unknown_user_url] = unknown_user_url
  end

  def unknown_user_url
    self.settings[:unknown_user_url]
  end

  def validate_auth_discovery_url
    return if self.settings[:auth_discovery_url].blank?

    begin
      value, uri = CanvasHttp.validate_url(self.settings[:auth_discovery_url])
      self.auth_discovery_url = value
    rescue URI::Error, ArgumentError
      errors.add(:discovery_url, t('errors.invalid_discovery_url', "The discovery URL is not valid" ))
    end
  end

  def find_courses(string)
    self.all_courses.select{|c| c.name.match(string) }
  end

  def find_users(string)
    self.pseudonyms.map{|p| p.user }.select{|u| u.name.match(string) }
  end

  class << self
    def special_accounts
      @special_accounts ||= {}
    end

    def special_account_ids
      @special_account_ids ||= {}
    end

    def special_account_timed_cache
      @special_account_timed_cache ||= TimedCache.new(-> { Setting.get('account_special_account_cache_time', 60).to_i.seconds.ago }) do
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
      self.special_account_list << key
      instance_eval <<-RUBY, __FILE__, __LINE__ + 1
        def self.#{key}(force_create = false)
          get_special_account(:#{key}, #{name.inspect}, force_create)
        end
      RUBY
    end

    def all_special_accounts
      special_account_list.map { |key| send(key) }
    end
  end
  define_special_account(:default, 'Default Account') # Account.default
  define_special_account(:site_admin) # Account.site_admin

  def clear_special_account_cache_if_special
    if self.shard == Shard.birth && Account.special_account_ids.values.map(&:to_i).include?(self.id)
      Account.clear_special_account_cache!(true)
    end
  end

  # an opportunity for plugins to load some other stuff up before caching the account
  def precache
  end

  class ::Canvas::AccountCacheError < StandardError; end

  def self.find_cached(id)
    birth_id = Shard.relative_id_for(id, Shard.current, Shard.birth)
    Shard.birth.activate do
      Rails.cache.fetch(account_lookup_cache_key(birth_id)) do
        begin
          account = Account.find(birth_id)
        rescue ActiveRecord::RecordNotFound => e
          raise ::Canvas::AccountCacheError, e.message
        end
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
        t '#account.default_site_administrator_account_name', 'Site Admin'
        t '#account.default_account_name', 'Default Account'
        account = special_accounts[special_account_type] = Account.new(:name => default_account_name)
        account.save!
        Setting.set("#{special_account_type}_account_id", account.id)
        special_account_ids[special_account_type] = account.id
      end
      account
    end
  end

  def site_admin?
    self == Account.site_admin
  end

  def display_name
    self.name
  end

  # Updates account associations for all the courses and users associated with this account
  def update_account_associations
    self.shard.activate do
      account_chain_cache = {}
      all_user_ids = Set.new

      # make sure to use the non-associated_courses associations
      # to catch courses that didn't ever have an association created
      scopes = if root_account?
                [all_courses,
                 associated_courses.
                     where("root_account_id<>?", self)]
              else
                [courses,
                 associated_courses.
                    where("courses.account_id<>?", self)]
              end
      # match the "batch" size in Course.update_account_associations
      scopes.each do |scope|
        scope.select([:id, :account_id]).find_in_batches(:batch_size => 500) do |courses|
          all_user_ids.merge Course.update_account_associations(courses, :skip_user_account_associations => true, :account_chain_cache => account_chain_cache)
        end
      end

      # Make sure we have all users with existing account associations.
      all_user_ids.merge self.user_account_associations.pluck(:user_id)
      if root_account?
        all_user_ids.merge self.pseudonyms.active.pluck(:user_id)
      end

      # Update the users' associations as well
      User.update_account_associations(all_user_ids.to_a, :account_chain_cache => account_chain_cache)
    end
  end

  def self.update_all_update_account_associations
    Account.root_accounts.active.find_each(&:update_account_associations)
  end

  def course_count
    self.courses.active.count
  end

  def sub_account_count
    self.sub_accounts.active.count
  end

  def user_count
    self.user_account_associations.count
  end

  def current_sis_batch
    if (current_sis_batch_id = self.read_attribute(:current_sis_batch_id)) && current_sis_batch_id.present?
      self.sis_batches.where(id: current_sis_batch_id).first
    end
  end

  def turnitin_settings
    return @turnitin_settings if defined?(@turnitin_settings)
    if self.turnitin_account_id.present? && self.turnitin_shared_secret.present?
      @turnitin_settings = [self.turnitin_account_id, self.turnitin_shared_secret, self.turnitin_host]
    else
      @turnitin_settings = self.parent_account.try(:turnitin_settings)
    end
  end

  def closest_turnitin_pledge
    if self.turnitin_pledge && !self.turnitin_pledge.empty?
      self.turnitin_pledge
    else
      res = self.parent_account.try(:closest_turnitin_pledge)
      res ||= t('#account.turnitin_pledge', "This assignment submission is my own, original work")
    end
  end

  def closest_turnitin_comments
    if self.turnitin_comments && !self.turnitin_comments.empty?
      self.turnitin_comments
    else
      self.parent_account.try(:closest_turnitin_comments)
    end
  end

  def closest_turnitin_originality
    if self.turnitin_originality && !self.turnitin_originality.empty?
      self.turnitin_originality
    else
      self.parent_account.try(:turnitin_originality)
    end
  end

  def self_enrollment_allowed?(course)
    if !settings[:self_enrollment].blank?
      !!(settings[:self_enrollment] == 'any' || (!course.sis_source_id && settings[:self_enrollment] == 'manually_created'))
    else
      !!(parent_account && parent_account.self_enrollment_allowed?(course))
    end
  end

  def allow_self_enrollment!(setting='any')
    settings[:self_enrollment] = setting
    self.save!
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

  # site admin tabs
  TAB_PLUGINS = 14
  TAB_JOBS = 15
  TAB_DEVELOPER_KEYS = 16

  def external_tool_tabs(opts)
    tools = ContextExternalTool.active.find_all_for(self, :account_navigation)
    Lti::ExternalToolTab.new(self, :account_navigation, tools, opts[:language]).tabs
  end

  def tabs_available(user=nil, opts={})
    manage_settings = user && self.grants_right?(user, :manage_account_settings)
    if root_account.site_admin?
      tabs = []
      if user && self.grants_right?(user, :read_roster)
        if feature_enabled?(:course_user_search)
          tabs << { :id => TAB_SEARCH, :label => t("Search"), :css_class => 'search', :href => :account_course_user_search_path }
        else
          tabs << { :id => TAB_USERS, :label => t('#account.tab_users', "Users"), :css_class => 'users', :href => :account_users_path }
        end
      end
      tabs << { :id => TAB_PERMISSIONS, :label => t('#account.tab_permissions', "Permissions"), :css_class => 'permissions', :href => :account_permissions_path } if user && self.grants_right?(user, :manage_role_overrides)
      tabs << { :id => TAB_SUB_ACCOUNTS, :label => t('#account.tab_sub_accounts', "Sub-Accounts"), :css_class => 'sub_accounts', :href => :account_sub_accounts_path } if manage_settings
      tabs << { :id => TAB_AUTHENTICATION, :label => t('#account.tab_authentication', "Authentication"), :css_class => 'authentication', :href => :account_authentication_providers_path } if root_account? && manage_settings
      tabs << { :id => TAB_PLUGINS, :label => t("#account.tab_plugins", "Plugins"), :css_class => "plugins", :href => :plugins_path, :no_args => true } if root_account? && self.grants_right?(user, :manage_site_settings)
      tabs << { :id => TAB_JOBS, :label => t("#account.tab_jobs", "Jobs"), :css_class => "jobs", :href => :jobs_path, :no_args => true } if root_account? && self.grants_right?(user, :view_jobs)
    else
      tabs = []
      if feature_enabled?(:course_user_search)
        tabs << { :id => TAB_SEARCH, :label => t("Search"), :css_class => 'search', :href => :account_path } if user && (grants_right?(user, :read_course_list) || grants_right?(user, :read_roster))
      else
        tabs << { :id => TAB_COURSES, :label => t('#account.tab_courses', "Courses"), :css_class => 'courses', :href => :account_path } if user && self.grants_right?(user, :read_course_list)
        tabs << { :id => TAB_USERS, :label => t('#account.tab_users', "Users"), :css_class => 'users', :href => :account_users_path } if user && self.grants_right?(user, :read_roster)
      end
      tabs << { :id => TAB_STATISTICS, :label => t('#account.tab_statistics', "Statistics"), :css_class => 'statistics', :href => :statistics_account_path } if user && self.grants_right?(user, :view_statistics)
      tabs << { :id => TAB_PERMISSIONS, :label => t('#account.tab_permissions', "Permissions"), :css_class => 'permissions', :href => :account_permissions_path } if user && self.grants_right?(user, :manage_role_overrides)
      if user && self.grants_right?(user, :manage_outcomes)
        tabs << { :id => TAB_OUTCOMES, :label => t('#account.tab_outcomes', "Outcomes"), :css_class => 'outcomes', :href => :account_outcomes_path }
        tabs << { :id => TAB_RUBRICS, :label => t('#account.tab_rubrics', "Rubrics"), :css_class => 'rubrics', :href => :account_rubrics_path }
      end
      tabs << { :id => TAB_GRADING_STANDARDS, :label => t('#account.tab_grading_standards', "Grading"), :css_class => 'grading_standards', :href => :account_grading_standards_path } if user && self.grants_right?(user, :manage_grades)
      tabs << { :id => TAB_QUESTION_BANKS, :label => t('#account.tab_question_banks', "Question Banks"), :css_class => 'question_banks', :href => :account_question_banks_path } if user && self.grants_right?(user, :manage_assignments)
      tabs << { :id => TAB_SUB_ACCOUNTS, :label => t('#account.tab_sub_accounts', "Sub-Accounts"), :css_class => 'sub_accounts', :href => :account_sub_accounts_path } if manage_settings
      tabs << { :id => TAB_FACULTY_JOURNAL, :label => t('#account.tab_faculty_journal', "Faculty Journal"), :css_class => 'faculty_journal', :href => :account_user_notes_path} if self.enable_user_notes && user && self.grants_right?(user, :manage_user_notes)
      tabs << { :id => TAB_TERMS, :label => t('#account.tab_terms', "Terms"), :css_class => 'terms', :href => :account_terms_path } if self.root_account? && manage_settings
      tabs << { :id => TAB_AUTHENTICATION, :label => t('#account.tab_authentication', "Authentication"), :css_class => 'authentication', :href => :account_authentication_providers_path } if self.root_account? && manage_settings
      if self.root_account? && self.allow_sis_import && user && self.grants_any_right?(user, :manage_sis, :import_sis)
        tabs << { id: TAB_SIS_IMPORT, label: t('#account.tab_sis_import', "SIS Import"),
                  css_class: 'sis_import', href: :account_sis_import_path }
      end
    end

    tabs << { :id => TAB_BRAND_CONFIGS, :label => t('#account.tab_brand_configs', "Themes"), :css_class => 'brand_configs', :href => :account_brand_configs_path } if manage_settings && branding_allowed?
    tabs << { :id => TAB_DEVELOPER_KEYS, :label => t("#account.tab_developer_keys", "Developer Keys"), :css_class => "developer_keys", :href => :account_developer_keys_path, account_id: root_account.id } if root_account? && self.grants_right?(user, :manage_developer_keys)

    tabs += external_tool_tabs(opts)
    tabs += Lti::MessageHandler.lti_apps_tabs(self, [Lti::ResourcePlacement::ACCOUNT_NAVIGATION], opts)
    tabs << { :id => TAB_ADMIN_TOOLS, :label => t('#account.tab_admin_tools', "Admin Tools"), :css_class => 'admin_tools', :href => :account_admin_tools_path } if can_see_admin_tools_tab?(user)
    tabs << { :id => TAB_SETTINGS, :label => t('#account.tab_settings', "Settings"), :css_class => 'settings', :href => :account_settings_path }
    tabs.delete_if{ |t| t[:visibility] == 'admins' } unless self.grants_right?(user, :manage)
    tabs
  end

  def can_see_admin_tools_tab?(user)
    return false if !user || root_account.site_admin?
    admin_tool_permissions = RoleOverride.manageable_permissions(self).find_all{|p| p[1][:admin_tool]}
    admin_tool_permissions.any? do |p|
      self.grants_right?(user, p.first)
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
    if !links.blank?
      links.each do |link|
        if link[:type].blank?
          link[:type] = 'custom'
        end
      end
    end

    if settings[:new_custom_help_links]
      links || Account::HelpLinks.default_links
    else
      Account::HelpLinks.default_links + (links || [])
    end
  end

  def set_service_availability(service, enable)
    service = service.to_sym
    raise "Invalid Service" unless AccountServices.allowable_services[service]
    allowed_service_names = (self.allowed_services || "").split(",").compact
    if allowed_service_names.count > 0 && ![ '+', '-' ].include?(allowed_service_names[0][0,1])
      # This account has a hard-coded list of services, so handle accordingly
      allowed_service_names.reject! { |flag| flag.match("^[+-]?#{service}$") }
      allowed_service_names << service if enable
    else
      allowed_service_names.reject! { |flag| flag.match("^[+-]?#{service}$") }
      if enable
        # only enable if it is not enabled by default
        allowed_service_names << "+#{service}" unless AccountServices.default_allowable_services[service]
      else
        # only disable if it is not enabled by default
        allowed_service_names << "-#{service}" if AccountServices.default_allowable_services[service]
      end
    end

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
    if self.allowed_services
      allowed_service_names = self.allowed_services.split(",").compact

      if allowed_service_names.count > 0
        unless [ '+', '-' ].member?(allowed_service_names[0][0,1])
          # This account has a hard-coded list of services, so we clear out the defaults
          account_allowed_services = { }
        end

        allowed_service_names.each do |service_switch|
          if service_switch =~ /\A([+-]?)(.*)\z/
            flag = $1
            service_name = $2.to_sym

            if flag == '-'
              account_allowed_services.delete(service_name)
            else
              account_allowed_services[service_name] = AccountServices.allowable_services[service_name]
            end
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
      AccountServices.allowable_services.reject { |_, setting| setting[:expose_to_ui] != expose_as }
    else
      AccountServices.allowable_services.reject { |_, setting| !setting[:expose_to_ui] }
    end.reject { |_, setting| setting[:expose_to_ui_proc] && !setting[:expose_to_ui_proc].call(current_user, account) }
  end

  def service_enabled?(service)
    service = service.to_sym
    case service
    when :none
      self.allowed_services_hash.empty?
    else
      self.allowed_services_hash.has_key?(service)
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

  def self.serialization_excludes; [:uuid]; end

  def find_child(child_id)
    return all_accounts.find(child_id) if root_account?

    child = Account.find(child_id)
    raise ActiveRecord::RecordNotFound unless child.account_chain.include?(self)

    child
  end

  def manually_created_courses_account
    return self.root_account.manually_created_courses_account unless self.root_account?
    display_name = t('#account.manually_created_courses', "Manually-Created Courses")
    acct = manually_created_courses_account_from_settings
    if acct.blank?
      transaction do
        lock!
        acct = manually_created_courses_account_from_settings
        acct ||= self.sub_accounts.where(name: display_name).first_or_create! # for backwards compatibility
        if acct.id != self.settings[:manually_created_courses_account_id]
          self.settings[:manually_created_courses_account_id] = acct.id
          self.save!
        end
      end
    end
    acct
  end

  def manually_created_courses_account_from_settings
    acct_id = self.settings[:manually_created_courses_account_id]
    acct = self.sub_accounts.where(id: acct_id).first if acct_id.present?
    acct = nil if acct.present? && acct.root_account_id != self.id
    acct
  end
  private :manually_created_courses_account_from_settings

  def trusted_account_ids
    return [] if !root_account? || self == Account.site_admin
    [ Account.site_admin.id ]
  end

  def trust_exists?
    false
  end

  def user_list_search_mode_for(user)
    return :preferred if self.root_account.open_registration?
    return :preferred if self.root_account.grants_right?(user, :manage_user_logins)
    :closed
  end

  scope :root_accounts, -> { where(:root_account_id => nil) }
  scope :processing_sis_batch, -> { where("accounts.current_sis_batch_id IS NOT NULL").order(:updated_at) }
  scope :name_like, lambda { |name| where(wildcard('accounts.name', name)) }
  scope :active, -> { where("accounts.workflow_state<>'deleted'") }

  def change_root_account_setting!(setting_name, new_value)
    root_account.settings[setting_name] = new_value
    root_account.save!
  end

  Bookmarker = BookmarkedCollection::SimpleBookmarker.new(Account, :name, :id)

  def format_referer(referer_url)
    begin
      referer = URI(referer_url || '')
    rescue URI::Error
      return
    end
    return unless referer.host

    referer_with_port = "#{referer.scheme}://#{referer.host}"
    referer_with_port += ":#{referer.port}" unless referer.port == (referer.scheme == 'https' ? 443 : 80)
    referer_with_port
  end

  def trusted_referers=(value)
    self.settings[:trusted_referers] = unless value.blank?
      value.split(',').map { |referer_url| format_referer(referer_url) }.compact.join(',')
    end
  end

  def trusted_referer?(referer_url)
    return if !self.settings.has_key?(:trusted_referers) || self.settings[:trusted_referers].blank?
    if referer_with_port = format_referer(referer_url)
      self.settings[:trusted_referers].split(',').include?(referer_with_port)
    end
  end

  def parent_registration?
    authentication_providers.where(parent_registration: true).exists?
  end

  def parent_auth_type
    return nil unless parent_registration?
    parent_registration_aac.auth_type
  end

  def parent_registration_aac
    authentication_providers.where(parent_registration: true).first
  end

  def to_param
    return 'site_admin' if site_admin?
    super
  end
end
