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

  # If the file is a zip file, unzip it, if it's an xml file, copy
  # it into the directory with the given file name
  def prepare_cartridge_file(file_name='imsmanifest.xml')
    if @archive_file_path.ends_with?('xml')
      FileUtils::cp(@archive_file_path, File.join(@unzipped_file_path, file_name))
    else
      unzip_archive
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

  def get_all_resources(manifest)
    manifest.css('resource').each do |r_node|
      id = r_node['identifier']
      resource = @resources[id]
      resource ||= {:migration_id=>id}
      resource[:type] = r_node['type']
      resource[:href] = r_node['href']
      if resource[:href]
        resource[:href] = resource[:href].gsub('\\', '/')
      else
        #it could be embedded in the manifest
        @resource_nodes_for_flat_manifest[id] = r_node
      end
      # Should be "Learner", "Instructor", or "Mentor"
      resource[:intended_user_role] = get_node_val(r_node, "intendedEndUserRole value", nil)
      # Should be "assignment", "lessonplan", "syllabus", or "unspecified"
      resource[:intended_use] = r_node['intendeduse']
      resource[:files] = []
      r_node.css('file').each do |file_node|
        resource[:files] << {:href => file_node[:href].gsub('\\', '/')}
      end
      resource[:dependencies] = []
      r_node.css('dependency').each do |d_node|
        resource[:dependencies] << d_node[:identifierref]
      end
      if variant = r_node.at_css('variant')
        resource[:preferred_resource_id] = variant['identifierref']
      end
      @resources[id] = resource
    end
  end

  # Finds the resource object with the specified type(s)
  # does a "start_with?" so that CC version can be ignored
  def resources_by_type(*types)
    @resources.values.find_all {|res| types.any?{|t| res[:type].start_with? t} }
  end

  def open_rel_path(rel_path)
    doc = nil
    if rel_path
      path = get_full_path(rel_path)
      if File.exists?(path)
        doc = open_file_xml(path)
      end
    end
    doc
  end

  def get_node_or_open_file(resource, node_name=nil)
    doc = open_rel_path(resource[:href])
    if !doc && resource[:files]
      resource[:files].each do |file|
        break if doc = open_rel_path(file[:href])
      end
    end

    if !doc && node = @resource_nodes_for_flat_manifest[resource[:migration_id]]
      #check for in-line node
      if node_name
        doc = node.children.find{|c| c.name == node_name}
      else
        doc = node
      end
    end

    doc.remove_namespaces! if doc && doc.respond_to?('remove_namespaces!')
    doc
  end

end
end
