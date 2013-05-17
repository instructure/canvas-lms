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

require File.expand_path(File.dirname(__FILE__) + '/import_helper')

describe "Importing assignments" do

  SYSTEMS.each do |system|
    if import_data_exists? system, 'assignment'
      it "should import assignments for #{system}" do
        data = get_import_data(system, 'assignment')
        context = get_import_context(system)

        data[:assignments_to_import] = {}
        Assignment.import_from_migration(data, context).should be_nil
        Assignment.count.should == 0

        data[:assignments_to_import][data[:migration_id]] = true
        Assignment.import_from_migration(data, context)
        Assignment.import_from_migration(data, context)
        Assignment.count.should == 1
        a = Assignment.find_by_migration_id(data[:migration_id])
        
        a.title.should == data[:title]
        a.description.should contain(data[:instructions]) if data[:instructions]
        a.description.should contain(data[:description]) if data[:description]
        a.due_at = Time.at(data[:due_date].to_i / 1000)
        a.points_possible.should == data[:grading][:points_possible].to_f
      end
    end
  end
  
end
