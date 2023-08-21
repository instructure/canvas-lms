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
module CC::Importer::Canvas
  class Converter < Canvas::Migration::Migrator
    include CC::Importer
    include CourseSettings
    include WikiConverter
    include AssignmentConverter
    include TopicConverter
    include ToolProfileConverter
    include WebcontentConverter
    include QuizConverter
    include MediaTrackConverter
    include LtiResourceLinkConverter

    MANIFEST_FILE = "imsmanifest.xml"

    # settings will use these keys: :course_name, :base_download_dir
    def initialize(settings)
      super(settings, "cc")
      @course = @course.with_indifferent_access
      @resources = {}
      @resource_nodes_for_flat_manifest = {}
      @canvas_converter = true
    end

    # exports the package into the intermediary json
    def export(_to_export = SCRAPE_ALL_HASH)
      unzip_archive
      set_progress(5)

      # this is cheating; we don't deal properly with namespaces
      @manifest = open_file_xml(@package_root.item_path(MANIFEST_FILE)).remove_namespaces!
      get_all_resources(@manifest)

      convert_all_course_settings
      set_progress(10)
      @course[:wikis] = convert_wikis
      set_progress(20)
      @course[:assignments] = convert_canvas_assignments
      set_progress(30)
      @course[:discussion_topics], @course[:announcements] = convert_topics_and_announcements
      set_progress(40)
      lti = CC::Importer::BLTIConverter.new
      res = lti.get_blti_resources(@manifest)
      @course[:external_tools] = lti.convert_blti_links(res, self)
      set_progress(50)
      @course[:tool_profiles] = convert_tool_profiles
      set_progress(52)
      @course[:file_map] = create_file_map
      set_progress(60)
      @course[:all_files_zip] = package_course_files
      set_progress(70)
      @course[:media_tracks] = convert_media_tracks(settings_doc(MEDIA_TRACKS))
      set_progress(71)
      @course[:lti_resource_links] = convert_lti_resource_links
      set_progress(72)
      convert_quizzes if Qti.qti_enabled?
      set_progress(80)

      read_external_content

      # for master course sync
      @course[:deletions] = @settings[:deletions] if @settings[:deletions].present?

      # close up shop
      save_to_file
      set_progress(90)
      delete_unzipped_archive
      @course
    end

    def read_external_content
      folder = @package_root.item_path(EXTERNAL_CONTENT_FOLDER)
      return unless File.directory?(folder)

      external_content = {}
      Dir["#{folder}/**/**"].each do |path|
        next if File.directory?(path)

        service_key = File.basename(path, ".json")
        json = File.read(path)
        begin
          data = JSON.parse(json)
          external_content[service_key] = data
        rescue JSON::ParserError => e
          Canvas::Errors.capture_exception(:external_content_migration, e, :info)
        end
      end
      @course[:external_content] = external_content
    end
  end
end
SafeYAML.whitelist_class!(CC::Importer::Canvas::Converter)
