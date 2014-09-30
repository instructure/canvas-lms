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
    SUPPORTED_TYPES = /assessment\z|\Aassignment|\Aimswl|\Aimsbasiclti|\Aimsdt|webcontent|learning-application-resource\z/
    
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
      @archive.prepare_cartridge_file(MANIFEST_FILE)
      @manifest = open_file_xml(File.join(@unzipped_file_path, MANIFEST_FILE))
      @manifest.remove_namespaces!

      get_all_resources(@manifest)
      process_variants
      create_file_map

      @course[:discussion_topics] = convert_discussions
      lti_converter = CC::Importer::BLTIConverter.new
      @course[:external_tools] = convert_blti_links_with_flat(lti_converter)
      @course[:assignments] = lti_converter.create_assignments_from_lti_links(@course[:external_tools])
      convert_cc_assignments(@course[:assignments])
      @course[:assessment_questions], @course[:assessments] = convert_quizzes if Qti.qti_enabled?
      @course[:modules] = convert_organizations(@manifest)
      @course[:all_files_zip] = package_course_files(@course[:file_map])

      #close up shop
      save_to_file
      delete_unzipped_archive
      @course
    end
    alias_method :export, :convert

    # A resource can have a "variant" that points to another resource.
    # That means the other resource is preferred if it's supported.
    # After this runs all migration_ids in @resources for the variant chain
    # should point to just one object
    def process_variants
      @resources.values.select{|r|r[:preferred_resource_id]}.each do |res|
        preferred = @resources[res[:preferred_resource_id]]
        if preferred && preferred != res
          if preferred[:type] =~ SUPPORTED_TYPES
            # The preferred resource is supported, use it instead
            @resources[res[:migration_id]] = preferred
          else
            # The preferred resource isn't supported, don't try to import it
            @resources[preferred[:migration_id]] = res
          end
          res.delete :preferred_resource_id
        end
      end
    end

    def find_file_migration_id(path)
      @file_path_migration_id[path] || @file_path_migration_id[path.gsub(%r{\$[^$]*\$|\.\./}, '')] ||
        @file_path_migration_id[path.gsub(%r{\$[^$]*\$|\.\./}, '').sub(WEB_RESOURCES_FOLDER + '/', '')]
    end
    
    def get_canvas_att_replacement_url(path, resource_dir=nil)
      if path.start_with?('../')
        if url = get_canvas_att_replacement_url(path.sub('../', ''), resource_dir)
          return url
        end
      end
      path = path[1..-1] if path.start_with?('/')
      mig_id = nil
      if resource_dir
        mig_id = find_file_migration_id(File.join(resource_dir, path))
      end
      mig_id ||= find_file_migration_id(path)

      unless mig_id
        path = path.gsub(%r{\$[^$]*\$|\.\./}, '')
        if key = @file_path_migration_id.keys.detect{|k| k.end_with?(path)}
          mig_id = @file_path_migration_id[key]
        end
      end

      mig_id ? "$CANVAS_OBJECT_REFERENCE$/attachments/#{mig_id}" : nil
    end

    def add_file(file)
      @course[:file_map][file[:migration_id]] = file
    end

    def add_course_file(file, overwrite=false)
      return unless file[:path_name]
      file[:path_name].sub!(WEB_RESOURCES_FOLDER + '/', '')
      file[:path_name] = file[:path_name][1..-1] if file[:path_name].start_with?('/')
      if @file_path_migration_id[file[:path_name]] && overwrite
        @course[:file_map].delete @file_path_migration_id[file[:path_name]]
      elsif @file_path_migration_id[file[:path_name]]
        return
      end
      @file_path_migration_id[file[:path_name]] = file[:migration_id]
      add_file(file)
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
