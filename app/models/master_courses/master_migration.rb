class MasterCourses::MasterMigration < ActiveRecord::Base
  belongs_to :master_template, :class_name => "MasterCourses::MasterTemplate"
  belongs_to :user

  serialize :export_results, Hash
  serialize :import_results, Hash

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

  # create a new migration and queue it up (if we can)
  def self.start_new_migration!(master_template, user=nil)
    master_template.class.transaction do
      master_template.lock!
      if master_template.active_migration_running?
        raise "cannot start new migration while another one is running"
      else
        new_migration = master_template.master_migrations.create!(:user => user)
        master_template.active_migration = new_migration
        master_template.save!
        new_migration.queue_export_job
        new_migration
      end
    end
  end

  def hours_until_expire
    Setting.get('master_course_export_job_expiration_hours', '24').to_i
  end

  def still_running?
    # if something catastrophic happens, just give up after 24 hours
    %w{created queued exporting imports_queued}.include?(self.workflow_state) && self.created_at > self.hours_until_expire.hours.ago
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
    export_to_child_courses(:selective, up_to_date_subs, true) if up_to_date_subs.any?
    export_to_child_courses(:full, new_subs, !up_to_date_subs.any?) if new_subs.any?

    self.workflow_state = 'imports_queued'
    self.imports_queued_at = Time.now
    self.save!
  rescue => e
    self.fail_export_with_error!(e)
    raise e
  end

  def export_to_child_courses(type, subscriptions, export_is_primary)
    export = self.create_export(type, export_is_primary)

    if export.exported_for_course_copy?
      self.queue_imports(type, export, subscriptions)
    else
      self.fail_export_with_error!("#{type} content export #{export.id} failed")
    end
  end

  def create_export(type, is_primary)
    # ideally we'll make this do more than just the usual CC::Exporter but we'll also do some stuff
    # in CC::Importer::Canvas to turn it into the big ol' "course_export.json" and we'll save that alone
    # and return it
    ce = ContentExport.new
    ce.context = self.master_template.course
    ce.export_type = ContentExport::MASTER_COURSE_COPY
    ce.settings[:master_migration_type] = type
    ce.settings[:master_migration_id] = self.id # so we can find on the import side when we copy attachments
    ce.settings[:primary_master_migration] = is_primary
    ce.user = self.user
    ce.save!
    ce.master_migration = self # don't need to reload
    ce.export_course
    self.master_template.ensure_attachment_tags_on_export if is_primary
    ce
  end

  def export_object?(obj)
    return false unless obj
    last_export_at = self.master_template.last_export_started_at
    last_export_at.nil? || obj.updated_at >= last_export_at
  end

  class MigrationPluginStub # so we can (ab)use queue_migration
    def self.settings
      {:skip_initial_progress => true, :import_immediately => true}
    end
  end

  def queue_imports(type, export, subscriptions)
    self.export_results[type] = {:subscriptions => subscriptions.map(&:id), :content_export_id => export.id}

    imports_expire_at = self.created_at + hours_until_expire.hours # tighten the limit until the import jobs expire

    cms = []
    subscriptions.each do |sub|
      cm = sub.child_course.content_migrations.build
      cm.migration_type = "master_course_import"
      cm.migration_settings[:skip_import_notification] = true
      cm.migration_settings[:hide_from_index] = true # we may decide we want to show this after all, but hide them for now
      cm.migration_settings[:master_course_export_id] = export.id
      cm.migration_settings[:master_migration_id] = self.id
      cm.migration_settings[:child_subscription_id] = sub.id
      cm.workflow_state = 'exported'
      cm.exported_attachment = export.attachment
      cm.save!

      self.import_results[cm.id] = {:import_type => type, :subscription_id => sub.id, :state => 'queued'}
      cms << cm
    end
    self.save!

    # just queue them all at once afterwards so we don't have to queue them in a transaction
    cms.each { |cm| cm.queue_migration(MigrationPluginStub, expires_at: imports_expire_at) }
    # this job is finished now but we won't mark ourselves as "completed" until all the import migrations are finished
  end

  def update_import_state!(import_migration, state)
    self.class.transaction do # turns out locking does nothing outside a transaction - oopsimanoob
      self.lock!
      res = self.import_results[import_migration.id]
      res[:state] = state
      if state == 'completed' && res[:import_type] == :full
        if sub = self.master_template.child_subscriptions.active.where(:id => res[:subscription_id], :use_selective_copy => false).first
          sub.update_attribute(:use_selective_copy, true) # mark subscription as up-to-date
        end
      end
      res[:skipped_count] = import_migration.skipped_master_course_items&.count || 0
      if self.import_results.values.all?{|r| r[:state] != 'queued'}
        # all imports are done
        if self.import_results.values.all?{|r| r[:state] == 'completed'}
          self.workflow_state = 'completed'
          self.imports_completed_at = Time.now
        else
          self.workflow_state = 'imports_failed'
        end
      end
      self.save!
    end
  end
end

