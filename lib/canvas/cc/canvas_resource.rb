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
module Canvas::CC
  module CanvasResource
    include ModuleMeta
    include ExternalFeeds
    include AssignmentGroups
    include GradingStandards
    include LearningOutcomes
    
    def add_canvas_non_cc_data
      migration_id = create_key(@course)
      
      @canvas_resource_dir = File.join(@export_dir, CCHelper::COURSE_SETTINGS_DIR)
      FileUtils::mkdir_p @canvas_resource_dir

      file_name = CCHelper::SYLLABUS
      syl_rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, file_name)
      path = File.join(@canvas_resource_dir, file_name)
      File.open(path, 'w') do |file|
        file << CCHelper.html_page(@course.syllabus_body || '', "Syllabus", @course, @manifest.exporter.user)
      end

      resources = []
      resources << create_course_settings(migration_id)
      resources << create_module_meta
      resources << create_external_feeds
      resources << create_assignment_groups
      resources << create_grading_standards
      resources << create_learning_outcomes
      # todo add all canvas-specific (non common cartridge supported) data
      #conferences
      #rubrics
      
      @resources.resource(
              :identifier => migration_id,
              "type" => Manifest::LOR,
              :href => syl_rel_path
      ) do |res|
        res.file(:href=>syl_rel_path)
        resources.each do |resource|
          res.file(:href=>resource) if resource
        end
      end
    end
    
    def create_course_settings(migration_id)
      course_file = File.new(File.join(@canvas_resource_dir, CCHelper::COURSE_SETTINGS), 'w')
      rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::COURSE_SETTINGS)
      document = Builder::XmlMarkup.new(:target=>course_file, :indent=>2)
      document.instruct!
      document.course("identifier" => migration_id,
                      "xmlns" => CCHelper::CANVAS_NAMESPACE,
                      "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                      "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |c|
        c.title @course.name
        c.start_at ims_datetime(@course.start_at) if @course.start_at
        c.conclude_at ims_datetime(@course.conclude_at) if @course.conclude_at
        atts = Course.clonable_attributes
        atts -= [:name, :start_at, :conclude_at, :grading_standard_id, :hidden_tabs, :tab_configuration, :syllabus_body]
        atts.each do |att|
          c.tag!(att, @course.send(att)) unless @course.send(att).blank?
        end
      end
      course_file.close
      rel_path
    end
  end
end
