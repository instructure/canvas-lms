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

describe "Importing Assignment Groups" do

  SYSTEMS.each do |system|
    if import_data_exists? system, 'assignment_group'
      it "should import from #{system}" do
        data = get_import_data(system, 'assignment_group')
        context = get_import_context(system)

        data[:assignment_groups_to_import] = {}
        expect {
          AssignmentGroup.import_from_migration(data, context).should be_nil
        }.to change(AssignmentGroup, :count).by(0)

        data[:assignment_groups_to_import][data[:migration_id]] = true
        expect {
          AssignmentGroup.import_from_migration(data, context)
          AssignmentGroup.import_from_migration(data, context)
        }.to change(AssignmentGroup, :count).by(1)
        g = AssignmentGroup.find_by_migration_id(data[:migration_id])

        g.name.should == data[:title]
      end
    end
  end

  it "should get attached to an assignment" do
    data = get_import_data('bb8', 'assignment_group')
    context = get_import_context('bb8')
    expect {
      AssignmentGroup.import_from_migration(data, context)
    }.to change(AssignmentGroup, :count).by(1)

    expect {
      ass = Assignment.import_from_migration(get_import_data('bb8', 'assignment'), context)
      ass.assignment_group.name.should == data[:title]
    }.to change(AssignmentGroup, :count).by(0)
  end

end
