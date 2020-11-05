# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module CC::Exporter::Epub
  module ModuleSorter
    def remove_hidden_content_from_syllabus!
      cartridge_json[:syllabus].select! do |syllabus_item|
        if sort_by_content
          item_ids.include?(syllabus_item[:identifier])
        else
          module_item_ids.include?(syllabus_item[:identifier])
        end
      end
    end

    def filter_content_to_module(module_id)
      current_mod = cartridge_json[:modules].find{|mod| mod[:identifier] == module_id}
      current_mod[:items].each do |item|
        next unless item
        merge_with_original_item_data!(item)

        if current_mod[:locked]
          item[:href] = nil
          update_syllabus_item(item[:linked_resource_id], href: nil)
        else
          update_syllabus_item(item[:linked_resource_id], href: item[:href])
        end
      end
      current_mod
    end

    private
    def module_ids
      cartridge_json[:modules].map{|mod| mod[:identifier]}
    end

    def module_item_ids
      @_module_item_ids ||= cartridge_json[:modules].map do |mod|
        mod[:items]
      end.flatten.map do |module_item|
        module_item[:linked_resource_id]
      end.uniq
    end

    def merge_with_original_item_data!(module_item)
      resource_type = Exporter::LINKED_RESOURCE_KEY[module_item[:linked_resource_type]]
      identifier = module_item[:linked_resource_id]
      original_item_data = get_item(resource_type, identifier)

      module_item.reverse_merge!(original_item_data)
      update_item(resource_type, identifier, {href: module_item[:href]})
    end
  end
end
