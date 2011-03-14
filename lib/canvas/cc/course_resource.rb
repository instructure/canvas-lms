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
  module CourseResource
    def add_course_settings
      #todo - add assignment group weighting and grading schemes
      migration_id = create_key(@course)
      
      lo_folder = File.join(@export_dir, CCHelper::COURSE_SETTINGS_DIR)
      FileUtils::mkdir_p lo_folder

      file_name = CCHelper::SYLLABUS
      syl_rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, file_name)
      path = File.join(lo_folder, file_name)
      File.open(path, 'w') do |file|
        file << CCHelper.html_page(@course.syllabus_body || '', "Syllabus", @course, @manifest.exporter.user)
      end
      
      course_file = File.new(File.join(lo_folder, CCHelper::COURSE_SETTINGS), 'w')
      course_rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::COURSE_SETTINGS)
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
      
      @resources.resource(
              :identifier => migration_id,
              "type" => Manifest::LOR,
              :href => syl_rel_path
      ) do |res|
        res.file(:href=>syl_rel_path)
        res.file(:href=>course_rel_path)
      end
    end
  end
end
