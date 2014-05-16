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

require 'open-uri'
module Canvas::Migration
class Migrator
  include MigratorHelper
  SCRAPE_ALL_HASH = { 'course_outline' => true, 'announcements' => true, 'assignments' => true, 'goals' => true, 'rubrics' => true, 'web_links' => true, 'learning_modules' => true, 'calendar_events' => true, 'calendar_start' => nil, 'calendar_end' => nil, 'discussions' => true, 'assessments' => true, 'question_bank' => true, 'all_files' => true, 'groups' => true, 'assignment_groups' => true, 'tasks' => true, 'wikis' => true }

  attr_accessor :course, :unzipped_file_path, :extra_settings, :total_error_count
  attr_reader :base_export_dir, :manifest, :import_objects, :settings

  def initialize(settings, migration_type)
    @settings = settings
    @settings[:migration_type] = migration_type
    @manifest = nil
    @error_count = 0
    @errors = []
    @course = {:file_map=>{}, :wikis=>[]}
    @course[:name] = @settings[:course_name]

    unless settings[:no_archive_file]
      unless settings[:archive_file]
        MigratorHelper::download_archive(settings)
      end
      if @archive_file = settings[:archive_file]
        @archive_file_path = @archive_file.path
      end
    end
    
    config = ConfigFile.load('external_migration') || {}
    @unzipped_file_path = Dir.mktmpdir(migration_type.to_s, config[:data_folder].presence)
    @base_export_dir = @settings[:base_download_dir] || find_export_dir
    @course[:export_folder_path] = File.expand_path(@base_export_dir)
    make_export_dir
  end

  def export
    raise "Migrator.export should have been overwritten by a sub-class"
  end

  def unzip_archive
    command = MigratorHelper.unzip_command(@archive_file_path, @unzipped_file_path)
    logger.debug "Running unzip command: #{command}"
    zip_std_out = `#{command}`

    if $?.exitstatus == 0
      return true
    elsif $?.exitstatus == 1
      add_warning(I18n.t('canvas.migration.warning.unzip_warning', 'The content package unzipped successfully, but with a warning'), zip_std_out)
      return true
    elsif $?.exitstatus == 127
      raise "unzip isn't installed on this system, exit status #{$?.exitstatus}, message: #{zip_std_out}"
    else
      raise "Could not unzip archive file, exit status #{$?.exitstatus}, message: #{zip_std_out}"
    end
  end

  def delete_unzipped_archive
    delete_file(@unzipped_file_path)
  end

  def delete_file(file)
    if File.exists?(file)
      begin
        FileUtils::rm_rf(file)
      rescue
        Rails.logger.warn "Couldn't delete #{file} for content_migration #{@settings[:content_migration_id]}"
      end
    end
  end

  def get_full_path(file_name)
    File.join(@unzipped_file_path, file_name) if file_name
  end

  def move_archive_to(full_path)
    if @archive_file.is_a?(Tempfile)
      FileUtils.move(@archive_file.path, full_path)
    else
      FileUtils.copy(@archive_file.path, full_path)
    end
  end
  
  def package_course_files(base_dir=nil)
    base_dir ||= @unzipped_file_path
    zip_file = File.join(@base_export_dir, MigratorHelper::ALL_FILES_ZIP)
    make_export_dir

    Zip::File.open(zip_file, 'w') do |zipfile|
      @course[:file_map].each_value do |val|
        file_path = File.join(base_dir, val[:real_path] || val[:path_name])
        val.delete :real_path
        if File.exists?(file_path)
          zipfile.add(val[:path_name], file_path)
        else
          add_warning(I18n.t('canvas.migration.errors.file_does_not_exist', 'The file "%{file_path}" did not exist in the content package and could not be imported.', :file_path => val[:path_name]))
        end
      end
    end

    File.expand_path(zip_file)
  end
  
end
end
