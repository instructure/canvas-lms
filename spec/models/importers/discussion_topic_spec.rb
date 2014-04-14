#
# Copyright (C) 2014 Instructure, Inc.
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

describe Importers::DiscussionTopic do

  SYSTEMS.each do |system|
    if import_data_exists? system, 'discussion_topic'
      it "should import topics for #{system}" do
        data = get_import_data(system, 'discussion_topic')
        data = data.first
        data = data.with_indifferent_access
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
        parsed_description = Nokogiri::HTML::DocumentFragment.parse(data[:description]).to_s
        topic.message.index(parsed_description).should_not be_nil

        if data[:grading]
          Assignment.count.should == 1
          topic.assignment.should_not be_nil
          topic.assignment.points_possible.should == data[:grading][:points_possible].to_f
          topic.assignment.submission_types.should == 'discussion_topic'
        end

      end
    end
  end
end
