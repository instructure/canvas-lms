require 'net/http'
require 'cgi'

require 'academic_benchmark/api'
require 'academic_benchmark/engine'
require 'academic_benchmark/standard'
require 'academic_benchmark/cli_tools'

module AcademicBenchmark
  def self.config
    empty_settings = {}.freeze
    p = Canvas::Plugin.find('academic_benchmark_importer')
    return empty_settings unless p
    p.settings || empty_settings
  end

  class APIError < StandardError; end

  def self.import(guid_or_guids)
    unless AcademicBenchmark.config[:api_key]
      raise Canvas::Migration::Error.new("Not importing academic benchmark data because no API key is set")
    end

    # need a user with global outcome management rights
    user_id = Setting.get("academic_benchmark_migration_user_id", nil)
    unless user_id
      raise Canvas::Migration::Error.new("Not importing academic benchmark data because no user id set")
    end

    unless (permissionful_user = User.where(id: user_id).first)
      raise Canvas::Migration::Error.new("Not importing academic benchmark data because no user found")
    end

    Array(guid_or_guids).map do |guid|
      AcademicBenchmark.queue_migration_for_guid(guid, permissionful_user).first
    end
  end

  def self.queue_migration_for_guid(guid, user)
    unless Account.site_admin.grants_right?(user, :manage_global_outcomes)
      raise Canvas::Migration::Error.new(I18n.t('academic_benchmark.no_permissions', "User isn't allowed to edit global outcomes"))
    end

    cm = ContentMigration.new(:context => Account.site_admin)
    cm.converter_class = self.config['converter_class']
    cm.migration_settings[:migration_type] = 'academic_benchmark_importer'
    cm.migration_settings[:import_immediately] = true
    cm.migration_settings[:guids] = [guid]
    cm.migration_settings[:no_archive_file] = true
    cm.migration_settings[:skip_import_notification] = true
    cm.migration_settings[:skip_job_progress] = true
    cm.strand = "academic_benchmark"
    cm.user = user
    cm.save!
    [cm, cm.export_content]
  end

  def self.set_common_core_setting!
    if (guid = self.config[:common_core_guid])
      if (group = LearningOutcomeGroup.where(migration_id: guid).first)
        Setting.set(common_core_setting_key, group.id)
      end
    end
  end

  def self.common_core_setting_key
    "common_core_outcome_group_id:#{Shard.current.id}"
  end
end
