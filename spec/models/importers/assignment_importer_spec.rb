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

describe "Importing assignments" do

  SYSTEMS.each do |system|
    if import_data_exists? system, 'assignment'
      it "should import assignments for #{system}" do
        data = get_import_data(system, 'assignment')
        context = get_import_context(system)

        data[:assignments_to_import] = {}
        expect {
          Importers::AssignmentImporter.import_from_migration(data, context).should be_nil
        }.to change(Assignment, :count).by(0)

        data[:assignments_to_import][data[:migration_id]] = true
        expect {
          Importers::AssignmentImporter.import_from_migration(data, context)
          Importers::AssignmentImporter.import_from_migration(data, context)
        }.to change(Assignment, :count).by(1)
        a = Assignment.find_by_migration_id(data[:migration_id])
        
        a.title.should == data[:title]
        a.description.should include(data[:instructions]) if data[:instructions]
        a.description.should include(data[:description]) if data[:description]
        a.due_at = Time.at(data[:due_date].to_i / 1000)
        a.points_possible.should == data[:grading][:points_possible].to_f
      end
    end
  end

  it "should import grading information when rubric is included" do
    file_data = get_import_data('', 'assignment')
    context = get_import_context('')

    assignment_hash = file_data.find{|h| h['migration_id'] == '4469882339231'}.with_indifferent_access

    rubric = rubric_model(:context => context)
    rubric.migration_id = assignment_hash[:grading][:rubric_id]
    rubric.points_possible = 42
    rubric.save!

    Importers::AssignmentImporter.import_from_migration(assignment_hash, context)
    a = Assignment.find_by_migration_id(assignment_hash[:migration_id])
    a.points_possible.should == rubric.points_possible
  end
  
end
