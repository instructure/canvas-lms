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

require File.expand_path(File.dirname(__FILE__) + '../../../import_helper')

describe "Importing Calendar Events" do

  SYSTEMS.each do |system|
    if import_data_exists? system, 'calendar_event'
      it "should import calendar events for #{system}" do
        data = get_import_data(system, 'calendar_event')
        context = get_import_context(system)
        
        data[:events_to_import] = {}
        CalendarEvent.import_from_migration(data, context).should be_nil
        CalendarEvent.count.should == 0
        
        data[:events_to_import][data[:migration_id]] = true
        CalendarEvent.import_from_migration(data, context)
        CalendarEvent.import_from_migration(data, context)
        CalendarEvent.count.should == 1
        
        event = CalendarEvent.find_by_migration_id(data[:migration_id])
        event.title.should == data[:title]
        event.description.gsub("&#x27;", "'").index(data[:description]).should_not be_nil
      end
    end
  end
end
