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
module CC::Exporter::Epub::Converters
  module ModuleEpubConverter
    include CC::Exporter

    def settings_doc(html = false)
      path = @package_root.item_path("course_settings", "module_meta.xml")
      return nil unless File.exist? path
      if html
        open_file path
      else
        open_file_xml path
      end
    end

    def convert_modules
      doc = settings_doc
      modules = []
      return modules unless doc

      doc.css('module').each do |r_node|
        next unless get_node_val(r_node, 'workflow_state') == 'active'
        mod = {}
        mod[:identifier] = r_node['identifier']
        mod[:workflow_state] = get_node_val(r_node, 'workflow_state')
        mod[:title] = get_node_val(r_node, 'title')
        mod[:position] = get_int_val(r_node, 'position')
        mod[:start_at] = get_time_val(r_node, 'start_at')
        mod[:end_at] = get_time_val(r_node, 'end_at')
        mod[:require_sequential_progress] = get_bool_val(r_node, 'require_sequential_progress')
        mod[:locked] = get_bool_val(r_node, 'locked')
        mod[:href] = "#{mod[:identifier]}.xhtml"
        if get_time_val(r_node, 'unlock_at').present?
          mod[:unlock_at] = get_time_val(r_node, 'unlock_at') / 1000
          mod[:time_lock] = mod[:unlock_at] > Time.zone.now.to_i
        end

        mod[:items] = r_node.css('item').map do |item_node|
          next unless get_node_val(item_node, 'workflow_state') == "active"
          item = {
            item_migration_id: item_node['identifier'],
            position: get_int_val(item_node, 'position'),
            indent: get_int_val(item_node, 'indent'),
            title: get_node_val(item_node, 'title'),
            new_tab: get_bool_val(item_node, 'new_tab'),
            linked_resource_type: get_node_val(item_node, 'content_type'),
            linked_resource_global_id: get_node_val(item_node, 'global_identifierref')
          }
          item[:linked_resource_id] = if item.value?("WikiPage")
                                        item[:title].parameterize
                                      else
                                        get_node_val(item_node, 'identifierref')
                                      end
          item[:for_syllabus] = item.value?("Assignment") || item.value?("Quizzes::Quiz")
          item[:href] = "#{mod[:identifier]}.xhtml##{item[:linked_resource_id]}"
          item
        end

        mod[:items].compact!

        mod[:completion_requirements] = []
        r_node.css('completionRequirement').each do |cr_node|
          cr = {}
          cr[:type] = cr_node['type']
          cr[:item_migration_id] = get_node_val(cr_node, 'identifierref')
          cr[:min_score] = get_float_val(cr_node, 'min_score')
          cr[:max_score] = get_float_val(cr_node, 'max_score')

          mod[:completion_requirements] << cr
        end

        mod[:prerequisites] = []
        r_node.css('prerequisite').each do |p_node|
          prereq = {}
          prereq[:type] = p_node['type']
          prereq[:title] = get_node_val(p_node, 'title')
          prereq[:module_migration_id] = get_node_val(p_node, 'identifierref')
          mod[:prerequisites] << prereq
        end

        modules << mod
      end

      modules
    end

  end
end
