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
    include DiscussionConverter
    include CC::Importer::BLTIConverter
    include QuizConverter

    MANIFEST_FILE = "imsmanifest.xml"
    
    attr_accessor :resources

    # settings will use these keys: :course_name, :base_download_dir
    def initialize(settings)
      super(settings, "cc")
      @course = @course
      @is_canvas_cartridge = nil
      @resources = {}
      @file_path_migration_id = {}
      
      # namespace prefixes
      @lom = nil
      @lomimscc = nil
    end

    # exports the package into the intermediary json
    def export(to_export = SCRAPE_ALL_HASH)
      to_export = SCRAPE_ALL_HASH.merge to_export if to_export
      unzip_archive
      @manifest = open_file_xml(File.join(@unzipped_file_path, MANIFEST_FILE))
      check_metadata_namespaces

      get_all_resources(@manifest)
      create_file_map
      @course[:discussion_topics] = convert_discussions
      @course[:external_tools] = convert_blti_links(resources_by_type("imsbasiclti"))
      @course[:assignments] = create_assignments_from_lti_links(@course[:external_tools])
      @course[:assessment_questions], @course[:assessments] = convert_quizzes if Qti.qti_enabled?
      @course[:modules] = convert_organizations(@manifest)
      @course[:all_files_zip] = package_course_files(@course[:file_map])
      
      # check for assignment intendeduse
      
      #close up shop
      save_to_file
      delete_unzipped_archive
      @course
    end
    
    # Finds the resource object with the specified type(s)
    # does a "start_with?" so that CC version can be ignored
    def resources_by_type(*types)
      @resources.values.find_all {|res| types.any?{|t| res[:type].start_with? t} }
    end
    
    def find_file_migration_id(path)
      @file_path_migration_id[path] || @file_path_migration_id[path.gsub(%r{\$[^$]*\$|\.\./}, '')]
    end
    
    def get_canvas_att_replacement_url(path, resource_dir=nil)
      mig_id = find_file_migration_id(resource_dir + '/' + path) if resource_dir
      mig_id ||= find_file_migration_id(path)
      mig_id ? "$CANVAS_OBJECT_REFERENCE$/attachments/#{mig_id}" : nil
    end

    def add_file(file)
      @course[:file_map][file[:migration_id]] = file
    end

    def add_course_file(file, overwrite=false)
      if @file_path_migration_id[file[:path_name]] && overwrite
        @course[:file_map].delete @file_path_migration_id[file[:path_name]]
      elsif @file_path_migration_id[file[:path_name]]
        return
      end
      @file_path_migration_id[file[:path_name]] = file[:migration_id]
      add_file(file)
    end
    
    def get_all_resources(manifest)
      manifest.css('resource').each do |r_node|
        id = r_node['identifier']
        resource = @resources[id]
        resource ||= {:migration_id=>id}
        resource[:type] = r_node['type']
        resource[:href] = r_node['href']
        resource[:href] = resource[:href].gsub('\\', '/') if resource[:href]
        # Should be "Learner", "Instructor", or "Mentor"
        resource[:intended_user_role] = get_node_val(r_node, "#{@lom}|intendedEndUserRole #{@lom}|value", nil) if @lom
        # Should be "assignment", "lessonplan", "syllabus", or "unspecified"
        resource[:intended_use] = r_node['intendeduse']
        resource[:files] = []
        r_node.css('file').each do |file_node|
          resource[:files] << {:href => file_node[:href].gsub('\\', '/')}
        end
        resource[:dependencies] = []
        r_node.css('dependency').each do |d_node|
          resource[:dependencies] << d_node[:identifierref]
        end
        @resources[id] = resource
      end
    end
    
    def check_metadata_namespaces
      @manifest.namespaces.each_pair do |key, val|
        if val =~ %r{lom/resource\z}i
          @lom = key.gsub('xmlns:','')
        elsif val =~ %r{lom/manifest\z}i
          @lomimscc = key.gsub('xmlns:','')
        end
      end
    end

    FILEBASE_REGEX = /\$IMS[-_]CC[-_]FILEBASE\$/
    def replace_urls(html, resource_dir=nil)
      return "" if html.blank?

      doc = Nokogiri::HTML(html || "")
      attrs = ['rel', 'href', 'src', 'data', 'value']
      doc.search("*").each do |node|
        attrs.each do |attr|
          if node[attr]
            val = URI.unescape(node[attr])
            begin
              if val =~ FILEBASE_REGEX
                val.gsub!(FILEBASE_REGEX, '')
                if new_url = get_canvas_att_replacement_url(val, resource_dir)
                  node[attr] = URI::escape(new_url)
                end
              else
                if ImportedHtmlConverter.relative_url?(val)
                  if new_url = get_canvas_att_replacement_url(val)
                    node[attr] = URI::escape(new_url)
                  end
                end
              end
            rescue URI::InvalidURIError
              Rails.logger.warn "attempting to translate invalid url: #{val}"
            end
          end
        end
      end
      doc.at_css('body').inner_html
    end

    def find_assignment(migration_id)
      @course[:assignments].find{|a|a[:migration_id] == migration_id}
    end
    
  end
end
