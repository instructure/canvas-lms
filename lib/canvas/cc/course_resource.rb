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
      #todo - Change this to an html page for syllabus and then course_settings xml file
      #todo - add assignment group weighting and grading schemes
      migration_id = create_key(@course)

      @resources.resource(
              :identifier => migration_id,
              "type" => Manifest::LOR,
              :href => CCHelper::COURSE_SETTINGS
      ) do |res|
        res.file(:href=>CCHelper::COURSE_SETTINGS)
      end

      course_file = File.new(File.join(@export_dir, CCHelper::COURSE_SETTINGS), 'w')
      document = Builder::XmlMarkup.new(:target=>course_file, :indent=>2)

      document.course("identifier" => migration_id,
                      "xmlns" => CCHelper::CANVAS_NAMESPACE,
                      "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                      "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |c|
        c.title @course.name
        c.start_at ims_datetime(@course.start_at) if @course.start_at
        c.conclude_at ims_datetime(@course.conclude_at) if @course.conclude_at
        atts = Course.clonable_attributes
        atts -= [:name, :start_at, :conclude_at, :grading_standard_id, :hidden_tabs, :tab_configuration]
        atts.each do |att|
          c.tag!(att, @course.send(att)) unless @course.send(att).blank?
        end
      end
      course_file.close
    end
  end
end
