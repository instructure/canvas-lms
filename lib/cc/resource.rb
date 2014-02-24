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
require 'set'

module CC
  class Resource
    include CCHelper
    include WikiResources
    include CanvasResource
    include AssignmentResources
    include TopicResources
    include WebResources
    include WebLinks
    include BasicLTILinks
    
    delegate :add_error, :set_progress, :export_object?, :export_symbol?, :for_course_copy, :add_item_to_export, :to => :@manifest
    delegate :referenced_files, :to => :@html_exporter

    def initialize(manifest, manifest_node)
      @manifest = manifest
      @manifest_node = manifest_node
      @course = @manifest.course
      @user = @manifest.user
      @export_dir = @manifest.export_dir
      @resources = nil
      @zip_file = manifest.zip_file
      # if set to "flash video", this'll export the smaller, post-conversion
      # flv files rather than the larger original files.
      @html_exporter = CCHelper::HtmlContentExporter.new(@course,
                                                         @manifest.exporter.user,
                                                         :for_course_copy => for_course_copy,
                                                         :track_referenced_files => true,
                                                         :media_object_flavor => Setting.get('exporter_media_object_flavor', nil).presence)
    end
    
    def self.create_resources(manifest, manifest_node)
      r = new(manifest, manifest_node)
      r.create_resources
      r
    end
    
    def create_resources
      @manifest_node.resources do |resources|
        @resources = resources
        run_and_set_progress(:add_canvas_non_cc_data, 15, I18n.t('course_exports.errors.canvas_meta', "Failed to export canvas-specific meta data"))
        run_and_set_progress(:add_wiki_pages, 30, I18n.t('course_exports.errors.wiki_pages', "Failed to export wiki pages"))
        run_and_set_progress(:add_assignments, 35, I18n.t('course_exports.errors.assignments', "Failed to export some assignments"))
        run_and_set_progress(:add_topics, 37, I18n.t('course_exports.errors.topics', "Failed to export some topics"))
        run_and_set_progress(:add_web_links, 40, I18n.t('course_exports.errors.web_links', "Failed to export some web links"))

        begin
          QTI::QTIGenerator.generate_qti(@manifest, resources, @html_exporter)
        rescue
          add_error(I18n.t('course_exports.errors.quizzes', "Some quizzes failed to export"), $!)
        end
        set_progress(60)

        # these need to go last, to gather up all the references to the files
        run_and_set_progress(:add_course_files, 70, I18n.t('course_exports.errors.files', "Failed to export some files"))
        run_and_set_progress(:add_media_objects, 90, I18n.t('course_exports.errors.media_files', "Failed to export some media files"), @html_exporter)
        run_and_set_progress(:create_basic_lti_links, 91, I18n.t('course_exports.errors.lti_links', "Failed to export some external tool configurations"))
      end
    end

    def run_and_set_progress(method, progress, fail_message, *args)
      res = nil
      begin
        res = self.send(method, *args)
      rescue
        add_error(fail_message, $!)
      end
      set_progress(progress) if progress
      res
    end
    
  end
end
