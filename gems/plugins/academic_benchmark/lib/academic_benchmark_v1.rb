require 'net/http'
require 'cgi'

module AcademicBenchmarkV1
  def self.import(guid_or_guids, options={})
    if !AcademicBenchmark.config[:api_key] || AcademicBenchmark.config[:api_key].empty?
      raise Canvas::Migration::Error, "Not importing academic benchmark data because no API key is set"
    end

    # need a user with global outcome management rights
    user_id = Setting.get("academic_benchmark_migration_user_id", nil)
    unless user_id.present?
      raise Canvas::Migration::Error, "Not importing academic benchmark data because no user id set"
    end

    unless (permissionful_user = User.where(id: user_id).first)
      raise Canvas::Migration::Error, "Not importing academic benchmark data because no user found"
    end

    Array(guid_or_guids).map do |guid|
      AcademicBenchmarkV1.queue_migration_for_guid(guid, permissionful_user, options).first
    end
  end

  def self.queue_migration_for_guid(guid, user, options={})
    unless Account.site_admin.grants_right?(user, :manage_global_outcomes)
      raise Canvas::Migration::Error,
        I18n.t("User isn't allowed to edit global outcomes")
    end

    cm = ContentMigration.new(:context => Account.site_admin)
    cm.converter_class = AcademicBenchmark.config['converter_class']
    cm.migration_settings[:migration_type] = 'academic_benchmark_importer'
    cm.migration_settings[:import_immediately] = true
    cm.migration_settings[:guids] = [guid]
    cm.migration_settings[:no_archive_file] = true
    cm.migration_settings[:skip_import_notification] = true
    cm.migration_settings[:skip_job_progress] = true
    cm.migration_settings[:migration_options] = options
    cm.strand = "academic_benchmark"
    cm.user = user
    cm.save!
    [cm, cm.export_content]
  end

  def self.set_common_core_setting!
    if (guid = AcademicBenchmark.config[:common_core_guid])
      if (group = LearningOutcomeGroup.where(migration_id: guid).first)
        Setting.set(common_core_setting_key, group.id)
      end
    end
  end

  def self.common_core_setting_key
    "common_core_outcome_group_id:#{Shard.current.id}"
  end
end
