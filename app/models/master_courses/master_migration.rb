#
# Copyright (C) 2016 - present Instructure, Inc.
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

class MasterCourses::MasterMigration < ActiveRecord::Base
  belongs_to :master_template, :class_name => "MasterCourses::MasterTemplate"
  belongs_to :user

  has_many :migration_results, :class_name => "MasterCourses::MigrationResult"

  serialize :export_results, Hash
  serialize :migration_settings, Hash

  has_a_broadcast_policy

  include Workflow
  workflow do
    state :created
    state :queued # before the migration job has run
    state :exporting # while we're running the full and/or selective exports
    state :imports_queued # after we've queued up imports in all the child courses and finished the initial migration job

    state :completed # after all the imports have run (successfully hopefully)
    state :exports_failed # if we break during export
    state :imports_failed # if one or more of the imports failed
  end

  class MigrationRunningError < StandardError; end

  # create a new migration and queue it up (if we can)
  def self.start_new_migration!(master_template, user, opts = {})
    master_template.class.transaction do
      master_template.lock!
      if master_template.active_migration_running?
        if opts[:retry_later]
          self.send_later_enqueue_args(:start_new_migration!,
            {:singleton => "retry_start_master_migration_#{master_template.global_id}",
              :run_at => 10.minutes.from_now, :max_attempts => 1},
            master_template, user, opts)
        else
          raise MigrationRunningError.new("cannot start new migration while another one is running")
        end
      else
        new_migration = master_template.master_migrations.create!({:user => user}.merge(opts.except(:retry_later)))
        master_template.active_migration = new_migration
        master_template.save!
        new_migration.queue_export_job
        new_migration
      end
    end
  end

  def copy_settings=(val)
    self.migration_settings[:copy_settings] = val
  end

  def hours_until_expire
    Setting.get('master_course_export_job_expiration_hours', '24').to_i
  end

  def in_running_state?
    %w{created queued exporting imports_queued}.include?(self.workflow_state)
  end

  def still_running?
    # if something catastrophic happens, just give up after 24 hours
    in_running_state? && self.created_at > self.hours_until_expire.hours.ago
  end

  def expire_if_necessary!
    if in_running_state? && self.created_at < self.hours_until_expire.hours.ago
      self.workflow_state = (self.workflow_state == 'imports_queued') ? 'imports_failed' : 'exports_failed'
      self.save!
    end
  end

  def queue_export_job
    expires_at = self.hours_until_expire.hours.from_now
    queue_opts = {
      :priority => Delayed::LOW_PRIORITY, :max_attempts => 1,
      :expires_at => expires_at, :on_permanent_failure => :fail_export_with_error!,
      :n_strand => ["master_course_exports", self.master_template.course.global_root_account_id]
      # we may need to raise the n_strand limit (in the settings) for this key since it'll default to 1 at a time
    }

    self.update_attribute(:workflow_state, 'queued')
    self.send_later_enqueue_args(:perform_exports, queue_opts)
  end

  def fail_export_with_error!(exception_or_info)
    if exception_or_info.is_a?(Exception)
      report_id = Canvas::Errors.capture_exception(:master_course_migration, exception_or_info)[:error_report]
      self.export_results[:error_report_id] = report_id
    else
      self.export_results[:error_message] = exception_or_info
    end
    self.workflow_state = 'exports_failed'
    self.save
  end

  def perform_exports
    self.workflow_state = 'exporting'
    self.exports_started_at = Time.now
    self.save!

    subs = self.master_template.child_subscriptions.active.preload(:child_course).to_a
    subs.reject!{|s| s.child_course.deleted?}
    if subs.empty?
      self.workflow_state = 'completed'
      self.export_results[:message] = "No child courses to export to"
      self.save!
      return
    end

    # 1) determine whether to make a full export, a selective export, or both
    up_to_date_subs, new_subs = subs.partition(&:use_selective_copy?)

    # do a selective export first (if necessary)
    # if any changes are made between the selective export and the full export, then we'll carry those in the next selective export
    # and the ones that got the full export will get the changes twice
    # the primary export is the one we'll use to mark the content tags as exported (i.e. the first one)
    cms = []
    cms += export_to_child_courses(:selective, up_to_date_subs, true).to_a if up_to_date_subs.any?
    cms += export_to_child_courses(:full, new_subs, !up_to_date_subs.any?).to_a if new_subs.any?

    unless self.workflow_state == 'exports_failed'
      self.workflow_state = 'imports_queued'
      self.imports_queued_at = Time.now
      self.save!
      self.queue_imports(cms)
    end
  rescue => e
    self.fail_export_with_error!(e)
    raise e
  end

  def export_to_child_courses(type, subscriptions, export_is_primary)
    @export_type = type
    if type == :selective
      @deletions = self.master_template.deletions_since_last_export
      @creations = {} # will be populated during export
      @updates = {}   # "
      @export_count = 0
    end
    export = self.create_export(type, export_is_primary, :deletions => @deletions)

    if export.exported_for_course_copy?
      self.export_results[type] = {:subscriptions => subscriptions.map(&:id), :content_export_id => export.id}
      if type == :selective
        self.export_results[type][:deleted] = @deletions
        self.export_results[type][:created] = @creations
        self.export_results[type][:updated] = @updates
      end
      self.generate_imports(type, export, subscriptions)
    else
      self.fail_export_with_error!("#{type} content export #{export.id} failed")
      return nil
    end
  end

  def create_export(type, is_primary, export_opts)
    # ideally we'll make this do more than just the usual CC::Exporter but we'll also do some stuff
    # in CC::Importer::Canvas to turn it into the big ol' "course_export.json" and we'll save that alone
    # and return it
    ce = ContentExport.new
    ce.context = self.master_template.course
    ce.export_type = ContentExport::MASTER_COURSE_COPY
    ce.settings[:master_migration_type] = type
    ce.settings[:master_migration_id] = self.id # so we can find on the import side when we copy attachments
    ce.settings[:primary_master_migration] = is_primary
    ce.settings[:selected_content] = selected_content(type)
    ce.user = self.user
    ce.save!
    ce.master_migration = self # don't need to reload
    ce.export_course(export_opts)
    if type == :selective && ce.referenced_files.present?
      ce.settings[:referenced_file_migration_ids] = ce.referenced_files.values
      ce.save!
    end
    if ce.exported_for_course_copy? && is_primary
      detect_updated_attachments(type)
      detect_updated_syllabus(type, ce)
    end
    ce
  end

  def selected_content(type)
    {}.tap do |h|
      h[:all_course_settings] = if migration_settings.has_key?(:copy_settings)
        migration_settings[:copy_settings]
      else
        type == :full
      end
      h[:syllabus_body] = type == :full || master_template.course.syllabus_updated_at&.>(last_export_at)
    end
  end

  def last_export_at
    self.master_template.last_export_started_at
  end

  def export_object?(obj)
    return false unless obj
    return true if last_export_at.nil?
    if obj.is_a?(LearningOutcome) && obj.context_type == "Account"
      link = self.master_template.course.learning_outcome_links.polymorphic_where(:content => obj).first
      obj = link if link # export the outcome if it's a new link
    end
    obj.updated_at.nil? || obj.updated_at >= last_export_at
  end

  def detect_updated_attachments(type)
    # because attachments don't get "added" to the export
    scope = self.master_template.course.attachments.not_deleted
    scope = scope.where('updated_at>?', last_export_at) if type == :selective && last_export_at
    scope.each do |att|
      master_template.ensure_tag_on_export(att)
      add_exported_asset(att)
    end
  end

  def detect_updated_syllabus(type, content_export)
    selected_content = content_export.settings[:selected_content]
    @updates['syllabus'] = true if @updates && selected_content && selected_content[:syllabus_body]
  end

  def add_exported_asset(asset)
    return unless @export_type == :selective
    @export_count += 1
    return if @export_count > Setting.get('master_courses_history_count', '150').to_i
    set = asset.created_at >= last_export_at ? @creations : @updates
    set[asset.class.name] ||= []
    set[asset.class.name] << master_template.content_tag_for(asset).migration_id
  end

  class MigrationPluginStub # so we can (ab)use queue_migration
    def self.settings
      {:skip_initial_progress => true, :import_immediately => true}
    end
  end

  def generate_imports(type, export, subscriptions)
    # generate all the content_migrations right now (and mark them in the migration results table) - queue afterwards
    cms = []
    subscriptions.each do |sub|
      cm = sub.child_course.content_migrations.build
      cm.migration_type = "master_course_import"
      cm.migration_settings[:skip_import_notification] = true
      cm.migration_settings[:hide_from_index] = true # we may decide we want to show this after all, but hide them for now
      cm.migration_settings[:master_course_export_id] = export.id
      cm.migration_settings[:master_migration_id] = self.id
      cm.child_subscription_id = sub.id
      cm.workflow_state = 'exported'
      cm.exported_attachment = export.attachment
      cm.user_id = export.user_id
      cm.save!

      self.migration_results.create!(:content_migration => cm, :import_type => type, :child_subscription_id => sub.id, :state => "queued")
      cms << cm
    end
    self.save!
    cms
  end

  def queue_imports(cms)
    imports_expire_at = self.created_at + hours_until_expire.hours # tighten the limit until the import jobs expire
    cms.each { |cm| cm.queue_migration(MigrationPluginStub, expires_at: imports_expire_at) }
    # this job is finished now but we won't mark ourselves as "completed" until all the import migrations are finished
  end

  def update_import_state!(import_migration, state)
    res = self.migration_results.where(:content_migration_id => import_migration).first
    res.state = state
    res.results[:skipped] = import_migration.skipped_master_course_items.to_a if import_migration.skipped_master_course_items
    res.save!
    if state == 'completed' && res.import_type == 'full'
      if sub = self.master_template.child_subscriptions.active.where(:id => res.child_subscription_id, :use_selective_copy => false).first
        sub.update_attribute(:use_selective_copy, true) # mark subscription as up-to-date
      end
    end

    unless self.migration_results.where.not(:state => %w{completed failed}).exists?
      self.class.transaction do
        self.lock!
        if self.workflow_state == 'imports_queued'
          if self.migration_results.where.not(:state => "completed").exists?
            self.workflow_state = 'imports_failed'
          else
            self.workflow_state = 'completed'
            self.imports_completed_at = Time.now
          end
          self.save!
        end
      end
    end
  end

  set_broadcast_policy do |p|
    p.dispatch :blueprint_sync_complete
    p.to { [user] }
    p.whenever { |record|
      record.changed_state_to(:completed) && record.send_notification?
    }
  end

  def notification_link_anchor
    "!/blueprint/blueprint_templates/#{master_template_id}/#{id}"
  end

end

