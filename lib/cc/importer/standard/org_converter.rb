#
# Copyright (C) 2011 - present Instructure, Inc.
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
  module OrgConverter
    include CC::Importer
    include WeblinkConverter

    def convert_organizations(doc)
      modules = []
      return modules unless doc
      misc_module = nil

      doc.css('organizations organization > item > item').each do |item_node|
        if item_node['identifierref']
          # item points to a single item
          if item = process_item(item_node, 0)
            if !misc_module
              misc_module = {:title => "Misc Module", :migration_id => "misc_module_top_level_items", :items => []}
              modules << misc_module
            end
            misc_module[:items] << item
          end
        else
          # It's a folder
          mod = {:items=>[]}
          mod[:migration_id] = item_node['identifier']
          add_children(item_node, mod)
          modules << mod
        end
      end

      modules
    end

    def add_children(node, mod, indent=0)
      node.children.each do |item_node|
        if item_node.name == 'title'
          if mod[:title]
            # This is a sub folder, or a "heading" in a canvas module
            item = {:title => item_node.text, :indent => (indent > 0 ? indent - 1 : 0), :type => 'heading'}
            mod[:items] << item
          else
            mod[:title] = item_node.text
          end
        else
          if !item_node['identifierref']
            if item_node['identifier']
              sub_mod = {:items => [], :migration_id => item_node['identifier'], :type => 'submodule'}
              add_children(item_node, sub_mod, indent)
              mod[:items] << sub_mod
            else
              add_children(item_node, mod, indent + 1)
            end
          elsif item = process_item(item_node, indent)
            mod[:items] << item
          end
        end
      end
    end

    def process_item(item_node, indent)
      item = nil
      if resource = @resources[item_node['identifierref']]
        case resource[:type]
          when /assessment\z/
            item = {
                    :indent =>indent,
                    :linked_resource_type => 'ASSESSMENT',
                    :linked_resource_id => resource[:migration_id],
                    :linked_resource_title => get_node_val(item_node, 'title'),
            }
          when /\Aassignment/
            item = {
                    :indent =>indent,
                    :linked_resource_type => 'ASSIGNMENT',
                    :linked_resource_id => resource[:migration_id],
                    :linked_resource_title => get_node_val(item_node, 'title'),
            }
          when /\Aimswl/
            item = {:indent => indent, :linked_resource_type => 'URL'}
            item[:linked_resource_title] = get_node_val(item_node, 'title')
            title, item[:url] = get_weblink_title_and_url(resource)
            item[:linked_resource_title] ||= title
            item = nil if item[:url].blank?
          when /\Aimsbasiclti/
            if asmnt = find_assignment(resource[:migration_id])
              item = {
                      :indent =>indent,
                      :linked_resource_type => 'ASSIGNMENT',
                      :linked_resource_id => asmnt[:migration_id],
                      :linked_resource_title => get_node_val(item_node, 'title')
              }
            else
              item = {
                      :indent =>indent,
                      :linked_resource_type => 'CONTEXTEXTERNALTOOL',
                      :linked_resource_id => resource[:migration_id],
                      :linked_resource_title => get_node_val(item_node, 'title'),
                      :url => resource[:url]
              }
            end
          when /\Aimsdt/
            item = {
                    :indent =>indent,
                    :linked_resource_type => 'DISCUSSION',
                    :linked_resource_id => resource[:migration_id],
                    :linked_resource_title => get_node_val(item_node, 'title')
            }
          when /webcontent|learning-application-resource\z/
            item = {:indent => indent}
            item[:linked_resource_id] = item_node['identifierref']
            item[:linked_resource_title] = get_node_val(item_node, 'title')

            if resource[:intended_use] == "assignment" &&
                (assignments = @course[:assignments].select{|a| a[:migration_id] == item[:linked_resource_id]}.presence)
              assignments.each do |a|
                # because of course the title isn't anywhere else
                a[:title] ||= item[:linked_resource_title]
              end
              item[:linked_resource_type] = "ASSIGNMENT"
            elsif @convert_html_to_pages &&
                (pages = @course[:wikis].select{|p| p[:migration_id] == item[:linked_resource_id]}.presence)
              pages.each do |p|
                p[:title] ||= item[:linked_resource_title]
              end
              item[:linked_resource_type] = "WIKIPAGE"
            else
              item[:linked_resource_type] = "FILE_TYPE"
            end
          end

        if item && resource[:intended_user_role] == 'Instructor'
          item[:workflow_state] = 'unpublished'
        end
      end
      item
    end

  end
end
