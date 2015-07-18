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
        migration = context.content_migrations.create!

        data[:assignment_groups_to_import] = {}
        expect {
          expect(Importers::AssignmentGroupImporter.import_from_migration(data, context, migration)).to be_nil
        }.to change(AssignmentGroup, :count).by(0)

        data[:assignment_groups_to_import][data[:migration_id]] = true
        expect {
          Importers::AssignmentGroupImporter.import_from_migration(data, context, migration)
          Importers::AssignmentGroupImporter.import_from_migration(data, context, migration)
        }.to change(AssignmentGroup, :count).by(1)
        g = AssignmentGroup.where(migration_id: data[:migration_id]).first

        expect(g.name).to eq data[:title]
      end
    end
  end

  it "should reuse existing empty assignment groups with the same name" do
    course_model
    migration = @course.content_migrations.create!
    assignment_group = @course.assignment_groups.create! name: 'teh group'
    assignment_group_json = { 'title' => 'teh group', 'migration_id' => '123' }
    Importers::AssignmentGroupImporter.import_from_migration(assignment_group_json, @course, migration)
    expect(assignment_group.reload.migration_id).to eq('123')
    expect(@course.assignment_groups.count).to eq 1
  end

  it "should not match assignment groups with migration ids by name" do
    course_model
    migration = @course.content_migrations.create!
    assignment_group = @course.assignment_groups.create name: 'teh group'
    assignment_group.migration_id = '456'
    assignment_group.save!
    assignment_group_json = { 'title' => 'teh group', 'migration_id' => '123' }
    Importers::AssignmentGroupImporter.import_from_migration(assignment_group_json, @course, migration)
    expect(assignment_group.reload.migration_id).to eq('456')
    expect(@course.assignment_groups.count).to eq 2
  end

  it "should get attached to an assignment" do
    data = get_import_data('bb8', 'assignment_group')
    context = get_import_context('bb8')
    migration = context.content_migrations.create!
    expect {
      Importers::AssignmentGroupImporter.import_from_migration(data, context, migration)
    }.to change(AssignmentGroup, :count).by(1)

    expect {
      ass = Importers::AssignmentImporter.import_from_migration(get_import_data('bb8', 'assignment'), context, migration)
      expect(ass.assignment_group.name).to eq data[:title]
    }.to change(AssignmentGroup, :count).by(0)
  end

end
