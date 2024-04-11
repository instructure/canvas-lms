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
require "English"

class ContentExport < ActiveRecord::Base
  include Workflow
  belongs_to :context, polymorphic: [:course, :group, { context_user: "User" }]
  belongs_to :user
  belongs_to :attachment
  belongs_to :content_migration
  has_many :attachments, as: :context, inverse_of: :context, dependent: :destroy
  has_one :sent_content_share
  has_many :received_content_shares
  has_many :quiz_migration_alerts, as: :migration, inverse_of: :migration, dependent: :destroy
  has_one :epub_export
  has_a_broadcast_policy
  serialize :settings

  attr_writer :master_migration
  attr_accessor :new_quizzes_export_url, :new_quizzes_export_state

  validates :context_id, :workflow_state, presence: true

  has_one :job_progress, class_name: "Progress", as: :context, inverse_of: :context

  before_save :assign_quiz_migration_limitation_alert
  before_save :set_new_quizzes_export_settings
  before_create :set_global_identifiers

  # export types
  COMMON_CARTRIDGE = "common_cartridge"
  COURSE_COPY = "course_copy"
  MASTER_COURSE_COPY = "master_course_copy"
  QTI = "qti"
  USER_DATA = "user_data"
  ZIP = "zip"
  QUIZZES2 = "quizzes2"
  CC_EXPORT_TYPES = [COMMON_CARTRIDGE, COURSE_COPY, MASTER_COURSE_COPY, QTI, QUIZZES2].freeze

  workflow do
    state :created
    state :waiting_for_external_tool
    state :exporting
    state :exported
    state :exported_for_course_copy
    state :failed
    state :deleted
  end

  def send_notification?
    context_type == "Course" &&
      export_type != ZIP &&
      content_migration.blank? &&
      !settings[:skip_notifications] &&
      !epub_export
  end

  set_broadcast_policy do |p|
    p.dispatch :content_export_finished
    p.to { [user] }
    p.whenever do |record|
      record.changed_state(:exported) && record.send_notification?
    end

    p.dispatch :content_export_failed
    p.to { [user] }
    p.whenever do |record|
      record.changed_state(:failed) && record.send_notification?
    end
  end

  set_policy do
    # file managers (typically course admins) can read all course exports (not zip or user-data exports)
    given do |user, session|
      context.grants_any_right?(user, session, *RoleOverride::GRANULAR_FILE_PERMISSIONS) &&
        [ZIP, USER_DATA].exclude?(export_type)
    end
    can :read

    # admins can create exports of any type
    given { |user, session| context.grants_right?(user, session, :read_as_admin) }
    can :create

    # admins can read any export they created
    given { |user, session| self.user == user && context.grants_right?(user, session, :read_as_admin) }
    can :read

    # all users can read zip/user data exports they created (in contexts they retain read permission)
    # NOTE: other exports may be created on their behalf that they do *not* have direct access to;
    # e.g. a common cartridge export created under the hood when a student creates a web zip export
    given { |user, session| self.user == user && [ZIP, USER_DATA].include?(export_type) && context.grants_right?(user, session, :read) }
    can :read

    # non-admins can create zip or user-data exports, but not other types
    given { |user, session| [ZIP, USER_DATA].include?(export_type) && context.grants_right?(user, session, :read) }
    can :create

    # users can read exports that are shared with them
    given { |user| user && user.content_shares.where(content_export: self).exists? }
    can :read
  end

  def set_global_identifiers
    self.global_identifiers = can_use_global_identifiers? if CC_EXPORT_TYPES.include?(export_type)
  end

  def can_use_global_identifiers?
    # use global identifiers if no other cc export from this course has used local identifiers
    # i.e. all exports from now on should try to use global identifiers
    # unless there's a risk of not matching up with a previous export
    !context.content_exports.where(export_type: CC_EXPORT_TYPES, global_identifiers: false).exists?
  end

  def quizzes_next?
    return false unless context.feature_enabled?(:quizzes_next)

    export_type == QUIZZES2 || settings[:quizzes2].present?
  end

  def new_quizzes_page_enabled?
    quizzes_next? && root_account.feature_enabled?(:newquizzes_on_quiz_page)
  end

  def export(opts = {})
    save if capture_job_id

    shard.activate do
      opts = opts.with_indifferent_access
      case export_type
      when ZIP
        export_zip(opts)
      when USER_DATA
        export_user_data(**opts)
      when QUIZZES2
        return unless context.feature_enabled?(:quizzes_next)

        new_quizzes_page_enabled? ? quizzes2_export_complete : export_quizzes2
      else
        export_course(opts)
      end
    end
  end
  handle_asynchronously :export, priority: Delayed::LOW_PRIORITY, max_attempts: 1, on_permanent_failure: :fail_with_error!

  def capture_job_id
    job = Delayed::Worker.current_job
    return false unless job

    settings[:job_id] = job.id
    true
  end

  def reset_and_start_job_progress
    job_progress.try :reset!
    job_progress.try :start!
  end

  def mark_waiting_for_external_tool
    self.workflow_state = "waiting_for_external_tool"
  end

  def mark_exporting
    self.workflow_state = "exporting"
    save
  end

  def mark_exported
    job_progress.try :complete!
    self.workflow_state = "exported"
  end

  def mark_failed
    self.workflow_state = "failed"
    job_progress.fail! if job_progress&.queued? || job_progress&.running?
  end

  def fail_with_error!(exception_or_info = nil, error_message: I18n.t("Unexpected error while performing export"))
    add_error(error_message, exception_or_info) if exception_or_info
    mark_failed
    save!
  end

  def export_course(opts = {})
    mark_exporting
    begin
      reset_and_start_job_progress

      @cc_exporter = CC::CCExporter.new(self, opts.merge({ for_course_copy: for_course_copy? }))
      if @cc_exporter.export
        self.progress = 100
        job_progress.try :complete!
        duration = Time.now - created_at
        InstStatsd::Statsd.timing("content_migrations.export_duration", duration, tags: { export_type:, selective_export: selective_export? })
        self.workflow_state = if for_course_copy?
                                "exported_for_course_copy"
                              else
                                "exported"
                              end
      else
        mark_failed
      end
    rescue
      add_error("Error running course export.", $ERROR_INFO)
      mark_failed
    ensure
      save
      epub_export.try(:mark_exported) || true
    end
  end

  def export_user_data(**)
    mark_exporting
    begin
      job_progress.try :start!

      if (exported_attachment = Exporters::UserDataExporter.create_user_data_export(context))
        self.attachment = exported_attachment
        self.progress = 100
        mark_exported
      end
    rescue
      add_error("Error running user_data export.", $ERROR_INFO)
      mark_failed
    ensure
      save
    end
  end

  def export_zip(opts = {})
    mark_exporting
    begin
      job_progress.try :start!
      if (attachment = Exporters::ZipExporter.create_zip_export(self, **opts))
        self.attachment = attachment
        self.progress = 100
        mark_exported
      end
    rescue
      add_error("Error running zip export.", $ERROR_INFO)
      mark_failed
    ensure
      save
    end
  end

  def quizzes2_build_assignment(opts = {})
    mark_exporting
    reset_and_start_job_progress

    @quiz_exporter = Exporters::Quizzes2Exporter.new(self)
    if @quiz_exporter.export(opts)
      update(
        selected_content: {
          quizzes: {
            create_key(@quiz_exporter.quiz) => true
          }
        }
      )
      settings[:quizzes2] = @quiz_exporter.build_assignment_payload
      save!
      return true
    else
      add_error("Error running export to Quizzes 2.", $ERROR_INFO)
      mark_failed
    end

    false
  end

  def quizzes2_export_complete
    return unless quizzes_next?

    assignment_id = settings.dig(:quizzes2, :assignment, :assignment_id)
    assignment = Assignment.find_by(id: assignment_id)
    if assignment.blank?
      mark_failed
      return
    end

    begin
      if new_quizzes_bank_migration_enabled?
        selected_content = self.selected_content || {}
        selected_content["all_#{AssessmentQuestionBank.table_name}"] = true

        update(
          export_type: QTI,
          selected_content:
        )
      else
        update(export_type: QTI)
      end
      @cc_exporter = CC::CCExporter.new(self)

      if @cc_exporter.export
        update(
          export_type: QUIZZES2
        )
        settings[:quizzes2][:qti_export] = {}
        settings[:quizzes2][:qti_export][:url] = attachment.public_download_url
        self.progress = 100
        mark_exported
      else
        assignment.fail_to_migrate
        mark_failed
      end
    rescue
      add_error("Error running export to Quizzes 2.", $ERROR_INFO)
      assignment.fail_to_migrate
      mark_failed
    ensure
      save
    end
  end

  def disable_content_rewriting?
    quizzes_next? && NewQuizzesFeaturesHelper.disable_content_rewriting?(context)
  end

  def export_quizzes2
    mark_exporting
    begin
      reset_and_start_job_progress

      @quiz_exporter = Exporters::Quizzes2Exporter.new(self)

      if @quiz_exporter.export
        update(
          export_type: QTI,
          selected_content: {
            quizzes: {
              create_key(@quiz_exporter.quiz) => true
            },
            "all_#{AssessmentQuestionBank.table_name}": new_quizzes_bank_migration_enabled? || nil
          }.compact
        )
        settings[:quizzes2] = @quiz_exporter.build_assignment_payload
        @cc_exporter = CC::CCExporter.new(self)
      end

      if @cc_exporter&.export
        update(
          export_type: QUIZZES2
        )
        settings[:quizzes2][:qti_export] = {}
        settings[:quizzes2][:qti_export][:url] = attachment.public_download_url
        self.progress = 100
        mark_exported
      else
        mark_failed
      end
    rescue
      add_error("Error running export to Quizzes 2.", $ERROR_INFO)
      mark_failed
    ensure
      save
    end
  end

  def queue_api_job(opts)
    if job_progress
      p = job_progress
    else
      p = Progress.new(context: self, tag: "content_export")
      self.job_progress = p
    end
    p.workflow_state = "queued"
    p.completion = 0
    p.user = user
    p.save!
    quizzes2_build_assignment(opts) if new_quizzes_page_enabled?
    export(opts)
  end

  def referenced_files
    @cc_exporter ? @cc_exporter.referenced_files : {}
  end

  def for_course_copy?
    export_type == COURSE_COPY || export_type == MASTER_COURSE_COPY
  end

  def for_master_migration?
    export_type == MASTER_COURSE_COPY
  end

  def master_migration
    @master_migration ||= MasterCourses::MasterMigration.find(settings[:master_migration_id])
  end

  def common_cartridge?
    export_type == COMMON_CARTRIDGE
  end

  def qti_export?
    export_type == QTI
  end

  def quizzes2_export?
    export_type == QUIZZES2
  end

  def zip_export?
    export_type == ZIP
  end

  def error_message
    settings[:errors]&.last
  end

  def error_messages
    settings[:errors] ||= []
  end

  def selected_content=(copy_settings)
    settings[:selected_content] = copy_settings
  end

  def selected_content
    settings[:selected_content] ||= {}
  end

  def select_content_key(obj)
    if zip_export?
      obj.asset_string
    else
      create_key(obj)
    end
  end

  def create_key(obj, prepend = "")
    shard.activate do
      if for_master_migration? && !is_external_object?(obj)
        master_migration.master_template.migration_id_for(obj, prepend) # because i'm too scared to use normal migration ids
      else
        CC::CCHelper.create_key(obj, prepend, global: global_identifiers?)
      end
    end
  end

  def is_external_object?(obj)
    obj.is_a?(ContextExternalTool) && obj.context_type == "Account"
  end

  # Method Summary
  #   Takes in an ActiveRecord object. Determines if the item being
  #   checked should be exported or not.
  #
  #   Returns: bool
  def export_object?(obj, asset_type: nil, ignore_updated_at: false)
    return false unless obj
    return true unless selective_export?

    return true if for_master_migration? && master_migration.export_object?(obj, ignore_updated_at:) # fallback to selected_content otherwise

    # because Announcement.table_name == 'discussion_topics'
    if obj.is_a?(Announcement)
      return true if selected_content["discussion_topics"] && is_set?(selected_content["discussion_topics"][select_content_key(obj)])

      asset_type ||= "announcements"
    end

    asset_type ||= obj.class.table_name
    return true if is_set?(selected_content["all_#{asset_type}"])
    return true if is_set?(selected_content["all_assignments"]) && asset_type == "assignment_groups"

    return false unless selected_content[asset_type]
    return true if is_set?(selected_content[asset_type][select_content_key(obj)])

    false
  end

  # Method Summary
  #   Takes a symbol containing the items that were selected to export.
  #   is_set? will return true if the item is selected. Also handles
  #   a case where 'everything' is set and returns true
  #
  # Returns: bool
  def export_symbol?(symbol)
    selected_content.empty? || is_set?(selected_content[symbol]) || is_set?(selected_content[:everything])
  end

  def add_item_to_export(obj, type = nil)
    return unless obj && (type || obj.class.respond_to?(:table_name))
    return unless selective_export?

    asset_type = type || obj.class.table_name
    selected_content[asset_type] ||= {}
    selected_content[asset_type][select_content_key(obj)] = true
  end

  def selective_export?
    if @selective_export.nil?
      @selective_export = if for_master_migration?
                            (settings[:master_migration_type] == :selective)
                          else
                            !(selected_content.empty? || is_set?(selected_content[:everything]))
                          end
    end
    @selective_export
  end

  def exported_assets
    @exported_assets ||= Set.new
  end

  def add_exported_asset(obj)
    if for_master_migration? && settings[:primary_master_migration]
      master_migration.master_template.ensure_tag_on_export(obj)
      master_migration.add_exported_asset(obj)
    end
    return unless selective_export?
    return if qti_export? || epub_export.present? || quizzes2_export?

    # for integrating selective exports with external content
    if (type = Canvas::Migration::ExternalContent::Translator::CLASSES_TO_TYPES[obj.class])
      exported_assets << "#{type}_#{obj.id}"
      if obj.respond_to?(:for_assignment?) && obj.for_assignment?
        exported_assets << "assignment_#{obj.assignment_id}"
      end
    end
  end

  def add_error(user_message, exception_or_info = nil)
    settings[:errors] ||= []
    er = nil
    if exception_or_info.is_a?(Exception)
      out = Canvas::Errors.capture_exception(:course_export, exception_or_info)
      er = out[:error_report]
      settings[:errors] << [user_message, "ErrorReport id: #{er}"]
    else
      settings[:errors] << [user_message, exception_or_info]
    end
    content_migration&.add_issue(user_message, :error, error_report_id: er)
  end

  def root_account
    context.try_rescue(:root_account)
  end

  def running?
    ["created", "exporting"].member? workflow_state
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"
    attachment&.destroy_permanently_plus
    save!
  end

  def settings
    read_or_initialize_attribute(:settings, {}.with_indifferent_access)
  end

  def fast_update_progress(val)
    content_migration&.update_conversion_progress(val)
    self.progress = val
    ContentExport.where(id: self).update_all(progress: val)
    if EpubExport.where(content_export_id: id).exists?
      epub_export.update_progress_from_content_export!(val)
    end
    job_progress.try(:update_completion!, val)
  end

  def self.expire_days
    Setting.get("content_exports_expire_after_days", "30").to_i
  end

  def self.expire?
    ContentExport.expire_days > 0
  end

  def expired?
    return false unless ContentExport.expire?

    return false if user && user.content_shares.where(content_export: self).exists?

    created_at < ContentExport.expire_days.days.ago
  end

  def assign_quiz_migration_limitation_alert
    if workflow_state_changed? && exported? && quizzes_next? && context.is_a?(Course) &&
       NewQuizzesFeaturesHelper.new_quizzes_bank_migrations_enabled?(context)
      context.create_or_update_quiz_migration_alert(user_id, self)
    end
  end

  def set_contains_new_quizzes_settings
    settings[:contains_new_quizzes] = contains_new_quizzes?
  end

  def contains_new_quizzes?
    return false unless new_quizzes_common_cartridge_enabled?

    context.assignments.active.type_quiz_lti.count.positive?
  end

  def include_new_quizzes_in_export?
    return false unless new_quizzes_common_cartridge_enabled?
    return false unless settings[:new_quizzes_export_state] == "completed"
    return false unless settings[:new_quizzes_export_url].present?

    true
  end

  scope :active, -> { where("content_exports.workflow_state<>'deleted'") }
  scope :not_for_copy, -> { where.not(content_exports: { export_type: [COURSE_COPY, MASTER_COURSE_COPY] }) }
  scope :common_cartridge, -> { where(export_type: COMMON_CARTRIDGE) }
  scope :qti, -> { where(export_type: QTI) }
  scope :quizzes2, -> { where(export_type: QUIZZES2) }
  scope :course_copy, -> { where(export_type: COURSE_COPY) }
  scope :running, -> { where(workflow_state: ["created", "exporting"]) }
  scope :admin, lambda { |user|
    where("content_exports.export_type NOT IN (?) OR content_exports.user_id=?",
          [
            ZIP, USER_DATA
          ],
          user)
  }
  scope :non_admin, lambda { |user|
    where("content_exports.export_type IN (?) AND content_exports.user_id=?",
          [
            ZIP, USER_DATA
          ],
          user)
  }
  scope :without_epub, -> { eager_load(:epub_export).where(epub_exports: { id: nil }) }
  scope :expired, lambda {
    if ContentExport.expire?
      where("created_at < ?", ContentExport.expire_days.days.ago)
    else
      none
    end
  }

  def set_new_quizzes_export_settings
    return unless common_cartridge? && new_quizzes_export_state.present?

    settings[:new_quizzes_export_url] = new_quizzes_export_url
    settings[:new_quizzes_export_state] = new_quizzes_export_state
  end

  def new_quizzes_export_state_failed?
    settings[:new_quizzes_export_state] == "failed"
  end

  def new_quizzes_export_state_completed?
    settings[:new_quizzes_export_state] == "completed"
  end

  private

  def is_set?(option)
    Canvas::Plugin.value_to_boolean option
  end

  def new_quizzes_bank_migration_enabled?
    context_type == "Course" && NewQuizzesFeaturesHelper.new_quizzes_bank_migrations_enabled?(context)
  end

  def new_quizzes_common_cartridge_enabled?
    context_type == "Course" && NewQuizzesFeaturesHelper.new_quizzes_common_cartridge_enabled?(context)
  end
end
