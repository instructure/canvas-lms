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

        data[:groups_to_import] = {}
        Group.import_from_migration(data, context).should be_nil
        Group.count.should == 0

        data[:groups_to_import][data[:migration_id]] = true
        Group.import_from_migration(data, context)
        Group.import_from_migration(data, context)
        Group.count.should == 1
        g = Group.find_by_migration_id(data[:migration_id])

        g.name.should == data[:title]
      end
    end
  end

  it "should attach to a discussion" do
    data = get_import_data('bb8', 'group')
    context = get_import_context('bb8')

    Group.import_from_migration(data, context)
    Group.count.should == 1

    category = get_import_data('bb8', 'group_discussion')

    category['topics'].each do |topic|
      topic['group_id'] = category['group_id']
      group = Group.find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, topic['group_id'])
      if group
        Importers::DiscussionTopic.import_from_migration(topic, group)
      end
    end

    DiscussionTopic.count.should == 1
    group = Group.find_by_migration_id(data[:migration_id])
    group.discussion_topics.count.should == 1
  end

end
