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

class ContentExport < ActiveRecord::Base
  include Workflow
  belongs_to :context, polymorphic: [:course, :group, { context_user: 'User' }]
  belongs_to :user
  belongs_to :attachment
  belongs_to :content_migration
  has_many :attachments, :as => :context, :dependent => :destroy
  has_one :epub_export
  has_a_broadcast_policy
  serialize :settings
  attr_accessible :context, :export_type, :user, :selected_content, :progress
  validates_presence_of :context_id, :workflow_state

  has_one :job_progress, :class_name => 'Progress', :as => :context

  #export types
  COMMON_CARTRIDGE = 'common_cartridge'
  COURSE_COPY = 'course_copy'
  QTI = 'qti'
  USER_DATA = 'user_data'
  ZIP = 'zip'

  workflow do
    state :created
    state :exporting
    state :exported
    state :exported_for_course_copy
    state :failed
    state :deleted
  end

  def send_notification?
    context_type == 'Course' &&
            export_type != ZIP &&
            content_migration.blank? &&
            !settings[:skip_notifications]
  end

  set_broadcast_policy do |p|
    p.dispatch :content_export_finished
    p.to { [user] }
    p.whenever {|record|
      record.changed_state(:exported) && record.send_notification?
    }

    p.dispatch :content_export_failed
    p.to { [user] }
    p.whenever {|record|
      record.changed_state(:failed) && record.send_notification?
    }
  end

  set_policy do
    # file managers (typically course admins) can read all course exports (not zip or user-data exports)
    given { |user, session| self.context.grants_right?(user, session, :manage_files) && [ZIP, USER_DATA].exclude?(self.export_type) }
    can :manage_files and can :read

    # admins can create exports of any type
    given { |user, session| self.context.grants_right?(user, session, :read_as_admin) }
    can :create

    # all users can read exports they created (in contexts they retain read permission)
    given { |user, session| self.user == user && self.context.grants_right?(user, session, :read) }
    can :read

    # non-admins can create zip or user-data exports, but not other types
    given { |user, session| [ZIP, USER_DATA].include?(self.export_type) && self.context.grants_right?(user, session, :read) }
    can :create
  end

  def export(opts={})
    case export_type
    when ZIP
      export_zip(opts)
    when USER_DATA
      export_user_data(opts)
    else
      export_course(opts)
    end
  end
  handle_asynchronously :export, :priority => Delayed::LOW_PRIORITY, :max_attempts => 1

  def export_course(opts={})
    self.workflow_state = 'exporting'
    self.save
    begin
      self.job_progress.try :reset!
      self.job_progress.try :start!

      @cc_exporter = CC::CCExporter.new(self, opts.merge({:for_course_copy => for_course_copy?}))
      if @cc_exporter.export
        self.progress = 100
        self.job_progress.try :complete!
        if for_course_copy?
          self.workflow_state = 'exported_for_course_copy'
        else
          self.workflow_state = 'exported'
        end
      else
        self.workflow_state = 'failed'
        self.job_progress.try :fail!
      end
    rescue
      add_error("Error running course export.", $!)
      self.workflow_state = 'failed'
      self.job_progress.try :fail!
    ensure
      self.save
      epub_export.try(:mark_exported) || true
    end
  end

  def export_user_data(opts)
    self.workflow_state = 'exporting'
    self.save
    begin
      self.job_progress.try :start!

      if exported_attachment = Exporters::UserDataExporter.create_user_data_export(self.context)
        self.attachment = exported_attachment
        self.progress = 100
        self.job_progress.try :complete!
        self.workflow_state = 'exported'
      end
    rescue
      add_error("Error running user_data export.", $!)
      self.workflow_state = 'failed'
      self.job_progress.try :fail!
    ensure
      self.save
    end
  end

  def export_zip(opts={})
    self.workflow_state = 'exporting'
    self.save
    begin
      self.job_progress.try :start!
      if attachment = Exporters::ZipExporter.create_zip_export(self, opts)
        self.attachment = attachment
        self.progress = 100
        self.job_progress.try :complete!
        self.workflow_state = 'exported'
      end
    rescue
      add_error("Error running zip export.", $!)
      self.workflow_state = 'failed'
      self.job_progress.try :fail!
    ensure
      self.save
    end
  end

  def queue_api_job(opts)
    if self.job_progress
      p = self.job_progress
    else
      p = Progress.new(:context => self, :tag => "content_export")
      self.job_progress = p
    end
    p.workflow_state = 'queued'
    p.completion = 0
    p.user = self.user
    p.save!
    export(opts)
  end

  def referenced_files
    @cc_exporter ? @cc_exporter.referenced_files : {}
  end

  def for_course_copy?
    self.export_type == COURSE_COPY
  end

  def common_cartridge?
    self.export_type == COMMON_CARTRIDGE
  end

  def qti_export?
    self.export_type == QTI
  end

  def zip_export?
    self.export_type == ZIP
  end

  def error_message
    self.settings[:errors] ? self.settings[:errors].last : nil
  end

  def error_messages
    self.settings[:errors] ||= []
  end

  def selected_content=(copy_settings)
    self.settings[:selected_content] = copy_settings
  end

  def selected_content
    self.settings[:selected_content] ||= {}
  end

  def select_content_key(obj)
    if zip_export?
      obj.asset_string
    else
      CC::CCHelper.create_key(obj)
    end
  end

  # Method Summary
  #   Takes in an ActiveRecord object. Determines if the item being
  #   checked should be exported or not.
  #
  #   Returns: bool
  def export_object?(obj, asset_type=nil)
    return false unless obj
    return true unless selective_export?

    # because Announcement.table_name == 'discussion_topics'
    if obj.is_a?(Announcement)
      return true if selected_content['discussion_topics'] && is_set?(selected_content['discussion_topics'][select_content_key(obj)])
      asset_type ||= 'announcements'
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

  def add_item_to_export(obj, type=nil)
    return unless obj && (type || obj.class.respond_to?(:table_name))
    return unless selective_export?

    asset_type = type || obj.class.table_name
    selected_content[asset_type] ||= {}
    selected_content[asset_type][select_content_key(obj)] = true
  end

  def selective_export?
    if @selective_export.nil?
      @selective_export = !(selected_content.empty? || is_set?(selected_content[:everything]))
    end
    @selective_export
  end

  def exported_assets
    @exported_assets ||= Set.new
  end

  def add_exported_asset(obj)
    return unless selective_export?
    return if qti_export? || epub_export.present?

    # for integrating selective exports with external content
    if type = Canvas::Migration::ExternalContent::Translator::CLASSES_TO_TYPES[obj.class]
      exported_assets << "#{type}_#{obj.id}"
    end
  end

  def add_error(user_message, exception_or_info=nil)
    self.settings[:errors] ||= []
    er = nil
    if exception_or_info.is_a?(Exception)
      out = Canvas::Errors.capture_exception(:course_export, exception_or_info)
      er = out[:error_report]
      self.settings[:errors] << [user_message, "ErrorReport id: #{er}"]
    else
      self.settings[:errors] << [user_message, exception_or_info]
    end
    if self.content_migration
      self.content_migration.add_issue(user_message, :error, error_report_id: er)
    end
  end

  def root_account
    self.context.try_rescue(:root_account)
  end

  def running?
    ['created', 'exporting'].member? self.workflow_state
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.attachment.destroy_permanently! if self.attachment
    save!
  end

  def settings
    read_or_initialize_attribute(:settings, {}.with_indifferent_access)
  end

  def fast_update_progress(val)
    content_migration.update_conversion_progress(val) if content_migration
    self.progress = val
    ContentExport.where(:id => self).update_all(:progress=>val)
    if EpubExport.exists?(content_export_id: self.id)
      self.epub_export.update_progress_from_content_export!(val)
    end
    self.job_progress.try(:update_completion!, val)
  end

  scope :active, -> { where("content_exports.workflow_state<>'deleted'") }
  scope :not_for_copy, -> { where("content_exports.export_type<>?", COURSE_COPY) }
  scope :common_cartridge, -> { where(export_type: COMMON_CARTRIDGE) }
  scope :qti, -> { where(export_type: QTI) }
  scope :course_copy, -> { where(export_type: COURSE_COPY) }
  scope :running, -> { where(workflow_state: ['created', 'exporting']) }
  scope :admin, ->(user) {
    where("content_exports.export_type NOT IN (?) OR content_exports.user_id=?", [
      ZIP, USER_DATA
    ], user)
  }
  scope :non_admin, ->(user) {
    where("content_exports.export_type IN (?) AND content_exports.user_id=?", [
      ZIP, USER_DATA
    ], user)
  }
  scope :without_epub, -> {eager_load(:epub_export).where(epub_exports: {id: nil})}

  private
  def is_set?(option)
    Canvas::Plugin::value_to_boolean option
  end

end
