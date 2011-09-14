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
module CC::Importer::Standard
  class Converter < Canvas::Migration::Migrator
    include CC::Importer
    include WebcontentConverter
    include OrgConverter

    MANIFEST_FILE = "imsmanifest.xml"
    
    attr_accessor :resources

    # settings will use these keys: :course_name, :base_download_dir
    def initialize(settings)
      super(settings, "cc")
      @course = @course.with_indifferent_access
      @is_canvas_cartridge = nil
      @resources = {}
    end

    # exports the package into the intermediary json
    def export(to_export = SCRAPE_ALL_HASH)
      to_export = SCRAPE_ALL_HASH.merge to_export if to_export
      unzip_archive
      
      @manifest = open_file(File.join(@unzipped_file_path, MANIFEST_FILE))

      get_all_resources
      @course[:file_map] = create_file_map
      @course[:modules] = convert_organizations(@manifest)
      
      package_course_files(@course[:file_map])
      
      # check for assignment intendeduse
      # handle web links
      # handle blti
      # handle quizzes
      # handle banks
      
      #close up shop
      save_to_file
      delete_unzipped_archive
      @course
    end
    
    def get_all_resources(manifest)
      manifest.css('resource').each do |r_node|
        id = r_node['identifier']
        resource = @resources[id]
        resource ||= {:migration_id=>id}
        resource[:type] = r_node['type']
        resource[:href] = get_full_path(r_node['href'])
        # Should be "Learner", "Instructor", or "Mentor"
        resource[:intended_user_role] = get_node_val(r_node, 'intendedEndUserRole value', nil)
        # Should be "assignment", "lessonplan", "syllabus", or "unspecified"
        resource[:intended_use] = r_node['intendeduse']
        resource[:files] = []
        r_node.css('file').each do |file_node|
          resource[:files] << {:href => file_node[:href]}
        end
        resource[:dependencies] = []
        r_node.css('dependency').each do |d_node|
          resource[:dependencies] << d_node[:identifierref]
        end
        @resources[id] = resource
      end
    end
    
  end
end
