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
    include AssignmentConverter
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
      @resource_nodes_for_flat_manifest = {}
    end

    # exports the package into the intermediary json
    def convert(to_export = nil)
      prepare_cartridge_file(MANIFEST_FILE)
      @manifest = open_file_xml(File.join(@unzipped_file_path, MANIFEST_FILE))
      @manifest.remove_namespaces!

      get_all_resources(@manifest)
      create_file_map
      @course[:discussion_topics] = convert_discussions
      lti_converter = CC::Importer::BLTIConverter.new
      @course[:external_tools] = convert_blti_links_with_flat(lti_converter)
      @course[:assignments] = lti_converter.create_assignments_from_lti_links(@course[:external_tools])
      convert_assignments(@course[:assignments])
      @course[:assessment_questions], @course[:assessments] = convert_quizzes if Qti.qti_enabled?
      @course[:modules] = convert_organizations(@manifest)
      @course[:all_files_zip] = package_course_files(@course[:file_map])
      
      #close up shop
      save_to_file
      delete_unzipped_archive
      @course
    end
    alias_method :export, :convert
    
    # Finds the resource object with the specified type(s)
    # does a "start_with?" so that CC version can be ignored
    def resources_by_type(*types)
      @resources.values.find_all {|res| types.any?{|t| res[:type].start_with? t} }
    end
    
    def find_file_migration_id(path)
      @file_path_migration_id[path] || @file_path_migration_id[path.gsub(%r{\$[^$]*\$|\.\./}, '')]
    end
    
    def get_canvas_att_replacement_url(path, resource_dir=nil)
      mig_id = nil
      if resource_dir
        mig_id = find_file_migration_id(File.join(resource_dir, path))
        mig_id ||= find_file_migration_id(File.join(resource_dir, path.gsub(%r{\$[^$]*\$|\.\./}, '')))
      end
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
        if resource[:href]
          resource[:href] = resource[:href].gsub('\\', '/')
        else
          #it could be embedded in the manifest
          @resource_nodes_for_flat_manifest[id] = r_node
        end
        # Should be "Learner", "Instructor", or "Mentor"
        resource[:intended_user_role] = get_node_val(r_node, "intendedEndUserRole value", nil)
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

    def get_node_or_open_file(resource, node_name=nil)
      if resource[:href]
        path = resource[:href]
      elsif resource[:files].first
        path = resource[:files].first[:href]
      end
      doc = nil

      if path
        path = get_full_path(path)
        if File.exists?(path)
          doc = open_file_xml(path)
          doc.remove_namespaces! unless doc.namespaces['xmlns'] && doc.respond_to?('remove_namespaces!')
        end
      elsif node = @resource_nodes_for_flat_manifest[resource[:migration_id]]
        #check for in-line node
        if node_name
          doc = node.children.find{|c| c.name == node_name}
        else
          doc = node
        end
      end

      doc
    end

    def convert_blti_links_with_flat(lti_converter)
      tools = []
      resources_by_type("imsbasiclti").each do |res|
        if doc = get_node_or_open_file(res)
          tool = lti_converter.convert_blti_link(doc)
          tool[:migration_id] = res[:migration_id]
          res[:url] = tool[:url] # for the organization item to reference
          tools << tool
        end
      end

      tools
    end
    
  end
end
