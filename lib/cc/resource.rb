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

    def initialize(manifest, manifest_node)
      @manifest = manifest
      @manifest_node = manifest_node
      @course = @manifest.course
      @export_dir = @manifest.export_dir
      @resources = nil
      @zip_file = manifest.zip_file
      # if set to "flash video", this'll export the smaller, post-conversion
      # flv files rather than the larger original files.
      @html_exporter = CCHelper::HtmlContentExporter.new(:media_object_flavor => Setting.get('exporter_media_object_flavor', nil).presence)
    end
    
    def self.create_resources(manifest, manifest_node)
      r = new(manifest, manifest_node)
      r.create_resources
    end
    
    def create_resources
      @manifest_node.resources do |resources|
        @resources = resources
        add_canvas_non_cc_data
        set_progress(15)
        add_wiki_pages
        set_progress(30)
        add_assignments
        set_progress(35)
        add_topics
        add_web_links
        set_progress(40)
        QTI::QTIGenerator.generate_qti(@manifest, resources, @html_exporter)
        set_progress(60)
        # these need to go last, to gather up all the references to the files
        add_course_files
        add_media_objects(@html_exporter)
        set_progress(90)
        create_basic_lti_links
      end
    end
    
    def set_progress(progress)
      @manifest.set_progress(progress)
    end
    
  end
end
