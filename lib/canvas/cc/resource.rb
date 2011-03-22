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
    include CCHelper
    include WikiResources
    include CanvasResource
    include AssignmentResources
    include TopicResources
    include WebResources
    include WebLinks

    def initialize(manifest, manifest_node)
      @manifest = manifest
      @manifest_node = manifest_node
      @course = @manifest.course
      @export_dir = @manifest.export_dir
      @resources = nil
      @zip_file = manifest.zip_file
    end
    
    def self.create_resources(manifest, manifest_node)
      r = new(manifest, manifest_node)
      r.create_resources
    end
    
    def create_resources
      @manifest_node.resources do |resources|
        @resources = resources
        add_canvas_non_cc_data
        add_wiki_pages
        add_assignments
        add_topics
        add_web_links
        add_course_files
        #todo quizzes
        #todo download kaltura videos?
        #todo basic LTI links
      end
    end
  end
end
