require 'net/http'
require 'cgi'

module AcademicBenchmark
  def self.config
    Canvas::Plugin.find('academic_benchmark_importer').settings || {}
  end

  class APIError < StandardError;end

  def self.queue_migration_for_guid(guid, user)
    if !Account.site_admin.grants_right?(user, :manage_global_outcomes)
      raise Canvas::Migration::Error.new("User isn't allowed to edit global outcomes")
    end

    cm = ContentMigration.create(:context => Account.site_admin)
    cm.converter_class = self.config['converter_class']
    cm.migration_settings[:migration_type] = 'academic_benchmark_importer'
    cm.migration_settings[:import_immediately] = true
    cm.migration_settings[:guids] = [guid]
    cm.migration_settings[:no_archive_file] = true
    cm.migration_settings[:skip_import_notification] = true
    cm.strand = "academic_benchmark"
    cm.user = user
    cm.save!
    [cm, cm.export_content]
  end

  def self.set_common_core_setting!
    if guid = self.config[:common_core_guid]
      if group = LearningOutcomeGroup.find_by_migration_id(guid)
        Setting.set(common_core_setting_key, group.id)
      end
    end
  end

  def self.common_core_setting_key
    "common_core_outcome_group_id:#{Shard.current.id}"
  end

end

require 'academic_benchmark/api'
require 'academic_benchmark/converter'
require 'academic_benchmark/standard'