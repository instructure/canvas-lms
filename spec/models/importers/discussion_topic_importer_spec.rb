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

require 'nokogiri'

describe Importers::DiscussionTopicImporter do

  SYSTEMS.each do |system|
    if import_data_exists? system, 'discussion_topic'
      it "should import topics for #{system}" do
        data = get_import_data(system, 'discussion_topic')
        data = data.first
        data = data.with_indifferent_access

        context = get_import_context(system)
        migration = context.content_migrations.create!

        data[:topics_to_import] = {}
        expect(Importers::DiscussionTopicImporter.import_from_migration(data, context, migration)).to be_nil
        expect(context.discussion_topics.count).to eq 0

        data[:topics_to_import][data[:migration_id]] = true
        Importers::DiscussionTopicImporter.import_from_migration(data, context, migration)
        Importers::DiscussionTopicImporter.import_from_migration(data, context, migration)
        expect(context.discussion_topics.count).to eq 1

        topic = DiscussionTopic.where(migration_id: data[:migration_id]).first
        expect(topic.title).to eq data[:title]
        parsed_description = Nokogiri::HTML::DocumentFragment.parse(data[:description]).to_s
        expect(topic.message.index(parsed_description)).not_to be_nil

        if data[:grading]
          expect(context.assignments.count).to eq 1
          expect(topic.assignment).not_to be_nil
          expect(topic.assignment.points_possible).to eq data[:grading][:points_possible].to_f
          expect(topic.assignment.submission_types).to eq 'discussion_topic'
        end

      end
    end
  end

  describe "Importing announcements" do
    SYSTEMS.each do |system|
      if import_data_exists? system, 'announcements'
        it "should import assignments for #{system}" do
          data = get_import_data(system, 'announcements')
          context = get_import_context(system)
          migration = context.content_migrations.create!
          data[:topics_to_import] = {}
          expect(Importers::DiscussionTopicImporter.import_from_migration(data, context, migration)).to be_nil
          expect(context.discussion_topics.count).to eq 0

          data[:topics_to_import][data[:migration_id]] = true
          Importers::DiscussionTopicImporter.import_from_migration(data, context, migration)
          Importers::DiscussionTopicImporter.import_from_migration(data, context, migration)
          expect(context.discussion_topics.count).to eq 1

          topic = DiscussionTopic.where(migration_id: data[:migration_id]).first
          expect(topic.title).to eq data[:title]
          expect(topic.message.index(data[:text])).not_to be_nil
        end
      end
    end
  end

  it "should not attach files when no attachment_migration_id is specified" do
    data = get_import_data('bb8', 'discussion_topic').first.with_indifferent_access
    context = get_import_context('bb8')
    migration = context.content_migrations.create!

    data[:attachment_migration_id] = nil
    attachment_model(:context => context) # create a file with no migration id

    data[:topics_to_import] = {data[:migration_id] => true}
    Importers::DiscussionTopicImporter.import_from_migration(data, context, migration)

    topic = DiscussionTopic.where(migration_id: data[:migration_id]).first
    expect(topic.attachment).to be_nil
  end
end
