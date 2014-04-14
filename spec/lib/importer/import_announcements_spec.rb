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

describe "Importing announcements" do

  SYSTEMS.each do |system|
    if import_data_exists? system, 'announcements'
      it "should import assignments for #{system}" do
        data = get_import_data(system, 'announcements')
        context = get_import_context(system)
        data[:topics_to_import] = {}
        Importers::DiscussionTopic.import_from_migration(data, context).should be_nil
        DiscussionTopic.count.should == 0

        data[:topics_to_import][data[:migration_id]] = true
        Importers::DiscussionTopic.import_from_migration(data, context)
        Importers::DiscussionTopic.import_from_migration(data, context)
        DiscussionTopic.count.should == 1

        topic = DiscussionTopic.find_by_migration_id(data[:migration_id])
        topic.title.should == data[:title]
        topic.message.index(data[:text]).should_not be_nil
      end
    end
  end

end
