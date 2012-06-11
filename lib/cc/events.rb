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
module CC
  module Events
    def create_events(document=nil)
      return nil unless @course.calendar_events.active.count > 0
      
      if document
        events_file = nil
        rel_path = nil
      else
        events_file = File.new(File.join(@canvas_resource_dir, CCHelper::EVENTS), 'w')
        rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::EVENTS)
        document = Builder::XmlMarkup.new(:target=>events_file, :indent=>2)
      end
      
      document.instruct!
      document.events(
              "xmlns" => CCHelper::CANVAS_NAMESPACE,
              "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
              "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |events_node|
        @course.calendar_events.active.each do |event|
          next unless export_object?(event)
          migration_id = CCHelper.create_key(event)
          events_node.event(:identifier=>migration_id) do |event_node|
            event_node.title event.title unless event.title.blank?
            event_node.description @html_exporter.html_content(event.description)
            event_node.start_at ims_datetime(event.start_at) if event.start_at
            event_node.end_at ims_datetime(event.end_at) if event.end_at
            if event.all_day
              event_node.all_day 'true'
              event_node.all_day_date ims_date(event.all_day_date) if event.all_day_date
            end
          end
        end
      end
      
      events_file.close if events_file
      rel_path
    end
  end
end
