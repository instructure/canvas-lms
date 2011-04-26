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
module CC
  module CanvasResource
    include ModuleMeta
    include ExternalFeeds
    include AssignmentGroups
    include GradingStandards
    include LearningOutcomes
    include Rubrics

    def add_canvas_non_cc_data
      migration_id = create_key(@course)
      
      @canvas_resource_dir = File.join(@export_dir, CCHelper::COURSE_SETTINGS_DIR)
      FileUtils::mkdir_p @canvas_resource_dir
      
      syl_rel_path = create_syllabus
      
      resources = []
      resources << create_course_settings(migration_id)
      resources << create_module_meta
      resources << create_external_feeds
      resources << create_assignment_groups
      resources << create_grading_standards
      resources << create_learning_outcomes
      resources << create_rubrics
      resources << create_external_tools
      resources << files_meta_path
      
      @resources.resource(
              :identifier => migration_id,
              "type" => Manifest::LOR,
              :href => syl_rel_path,
              :intendeduse => "syllabus"
      ) do |res|
        res.file(:href=>syl_rel_path)
        resources.each do |resource|
          res.file(:href=>resource) if resource
        end
      end
    end
    
    def create_syllabus(io_object=nil)
      syl_rel_path = nil
      
      unless io_object
        syl_rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::SYLLABUS)
        path = File.join(@canvas_resource_dir, CCHelper::SYLLABUS)
        io_object = File.open(path, 'w')
      end
      io_object << CCHelper.html_page(@course.syllabus_body || '', "Syllabus", @course, @manifest.exporter.user)
      io_object.close
        
      syl_rel_path
    end
    
    def create_course_settings(migration_id, document=nil)
      if document
        course_file = nil
        rel_path = nil
      else
        course_file = File.new(File.join(@canvas_resource_dir, CCHelper::COURSE_SETTINGS), 'w')
        rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::COURSE_SETTINGS)
        document = Builder::XmlMarkup.new(:target=>course_file, :indent=>2)
      end
      document.instruct!
      document.course("identifier" => migration_id,
                      "xmlns" => CCHelper::CANVAS_NAMESPACE,
                      "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                      "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |c|
        c.title @course.name
        c.course_code @course.course_code
        c.start_at ims_datetime(@course.start_at) if @course.start_at
        c.conclude_at ims_datetime(@course.conclude_at) if @course.conclude_at
        atts = Course.clonable_attributes
        atts -= Canvas::MigratorHelper::COURSE_NO_COPY_ATTS
        atts.each do |att|
          c.tag!(att, @course.send(att)) unless @course.send(att).nil? || @course.send(att) == ''
        end
      end
      course_file.close if course_file
      rel_path
    end
  end
end
