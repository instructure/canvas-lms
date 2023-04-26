# frozen_string_literal: true

#
# Copyright (C) 2020 Instructure, Inc.
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

class DataServicesMarkdownCreator
  CALIPER_EVENT_TEMPLATE = File.read("doc/api/data_services/caliper_event_template.md.erb")
  CALIPER_STRUCTURE_TEMPLATE = File.read("doc/api/data_services/caliper_structure_template.md.erb")
  CANVAS_EVENT_TEMPLATE = File.read("doc/api/data_services/canvas_event_template.md.erb")
  CANVAS_METADATA_TEMPLATE = File.read("doc/api/data_services/canvas_metadata_template.md.erb")
  MARKDOWN_PATH = "doc/api/data_services/md/dynamic"

  def self.run
    Dir.glob("#{MARKDOWN_PATH}/*.md").each { |file| File.delete(file) }

    DataServicesCanvasLoader.data.each do |content|
      file_name = "canvas_#{content[:event_category]}"

      write_file(file_name, CANVAS_EVENT_TEMPLATE, content)
    end

    write_file("canvas_event_metadata", CANVAS_METADATA_TEMPLATE, DataServicesCanvasLoader.metadata)

    DataServicesCaliperLoader.data.each do |content|
      file_name = "caliper_#{content[:event_category]}"

      write_file(file_name, CALIPER_EVENT_TEMPLATE, content)
    end

    write_file("caliper_structure", CALIPER_STRUCTURE_TEMPLATE, DataServicesCaliperLoader.extensions)
  end

  def self.write_file(file_name, template, content)
    erb_renderer = ERB.new(template)

    File.binwrite("#{MARKDOWN_PATH}/data_service_#{file_name}.md", erb_renderer.result(binding))
  end
end
