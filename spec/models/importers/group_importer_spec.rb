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

describe "Importing Groups" do

  SYSTEMS.each do |system|
    if import_data_exists? system, 'group'
      it "should import from #{system}" do
        data = get_import_data(system, 'group')
        context = get_import_context(system)
        migration = context.content_migrations.create!

        data[:groups_to_import] = {}
        expect(Importers::GroupImporter.import_from_migration(data, context, migration)).to be_nil
        expect(context.groups.count).to eq 0

        data[:groups_to_import][data[:migration_id]] = true
        Importers::GroupImporter.import_from_migration(data, context, migration)
        Importers::GroupImporter.import_from_migration(data, context, migration)
        expect(context.groups.count).to eq 1
        g = Group.where(migration_id: data[:migration_id]).first

        expect(g.name).to eq data[:title]
      end
    end
  end

  it "should attach to a discussion" do
    data = get_import_data('bb8', 'group')
    context = get_import_context('bb8')
    migration = context.content_migrations.create!

    Importers::GroupImporter.import_from_migration(data, context, migration)
    expect(context.groups.count).to eq 1

    category = get_import_data('bb8', 'group_discussion')

    category['topics'].each do |topic|
      topic['group_id'] = category['group_id']
      group = Group.where(context_id: context, context_type: context.class.to_s, migration_id: topic['group_id']).first
      if group
        Importers::DiscussionTopicImporter.import_from_migration(topic, group, migration)
      end
    end

    group = Group.where(migration_id: data[:migration_id]).first
    expect(group.discussion_topics.count).to eq 1
  end

  it "should respect group_category from the hash" do
    course_with_teacher
    migration = @course.content_migrations.create!
    group = @course.groups.build
    Importers::GroupImporter.import_from_migration({:group_category => "random category"}, @course, migration, group)
    expect(group.group_category.name).to eq "random category"
  end

  it "should default group_category to imported if not in the hash" do
    course_with_teacher
    migration = @course.content_migrations.create!
    group = @course.groups.build
    Importers::GroupImporter.import_from_migration({}, @course, migration, group)
    expect(group.group_category).to eq GroupCategory.imported_for(@course)
  end
end
