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
  class Resource
    
    COURSE_SETTINGS = "course_settings.xml"

    def initialize(manifest, manifest_node)
      @manifest = manifest
      @manifest_node = manifest_node
      @course = @manifest.course
      @export_dir = @manifest.export_dir
      @resources = nil
    end
    
    def self.create_resources(manifest, manifest_node)
      r = new(manifest, manifest_node)
      r.create_resources
    end
    
    def create_resources
      @manifest_node.resources do |resources|
        @resources = resources
        add_course_settings
        #course content
        #course files
      end
    end

    def add_course_settings
      migration_id = CCHelper.create_key(@course)

      @resources.resource(
              :identifier => migration_id,
              "type" => Manifest::LOR,
              :href => COURSE_SETTINGS
      ) do |res|
        res.file(:href=>COURSE_SETTINGS)
      end

      course_file = File.new(File.join(@export_dir, COURSE_SETTINGS), 'w')
      document = Builder::XmlMarkup.new(:target=>course_file, :indent=>2)

      document.course("identifier" => migration_id,
                      "xmlns" => "http://www.instructure.com/xsd/cccv0p1",
                      "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                      "xsi:schemaLocation"=> "http://www.instructure.com/xsd/cccv0p1 cccv0p1.xsd"
      ) do |c|
        c.title @course.name
        c.start_at CCHelper.ims_datetime(@course.start_at) if @course.start_at
        c.conclude_at CCHelper.ims_datetime(@course.conclude_at) if @course.conclude_at
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