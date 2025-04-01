# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../../import_helper"

require "nokogiri"

describe Importers::DiscussionTopicImporter do
  SYSTEMS.each do |system|
    next unless import_data_exists? system, "discussion_topic"

    it "imports topics for #{system}" do
      data = get_import_data(system, "discussion_topic")
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
      parsed_description = Nokogiri::HTML5.fragment(data[:description]).to_s
      expect(topic.message.index(parsed_description)).not_to be_nil
      expect(topic.reply_to_entry_required_count).to eq(0)

      if data[:grading]
        expect(context.assignments.count).to eq 1
        expect(topic.assignment).not_to be_nil
        expect(topic.assignment.points_possible).to eq data[:grading][:points_possible].to_f
        expect(topic.assignment.submission_types).to eq "discussion_topic"
      end
    end
  end

  describe "Importing announcements" do
    SYSTEMS.each do |system|
      next unless import_data_exists? system, "announcements"

      it "imports assignments for #{system}" do
        data = get_import_data(system, "announcements")
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

  it "does not attach files when no attachment_migration_id is specified" do
    data = get_import_data("bb8", "discussion_topic").first.with_indifferent_access
    context = get_import_context("bb8")
    migration = context.content_migrations.create!

    data[:attachment_migration_id] = nil
    attachment_model(context:) # create a file with no migration id

    data[:topics_to_import] = { data[:migration_id] => true }
    Importers::DiscussionTopicImporter.import_from_migration(data, context, migration)

    topic = DiscussionTopic.where(migration_id: data[:migration_id]).first
    expect(topic.attachment).to be_nil
  end

  describe "assignments" do
    subject do
      Importers::DiscussionTopicImporter.import_from_migration(data, context, migration)
      DiscussionTopic.where(migration_id: data[:migration_id]).first
    end

    let(:data) { get_import_data("", "discussion_assignments")[:discussion_topics].first }
    let(:context) { get_import_context }
    let(:migration) { context.content_migrations.create! }

    it "saves reply_to_entry_required_count" do
      expect(subject.reply_to_entry_required_count).to eq(2)
    end

    it "saves assignment description" do
      expect(subject.assignment.description).to eq(data[:description])
    end

    context "when discussion_checkpoints feature is enabled" do
      before do
        context.account.enable_feature!(:discussion_checkpoints)
      end

      it "saves the sub assignments" do
        expect(subject.sub_assignments.count).to eq(2)
      end

      it "saves topic message to the sub assignments" do
        topic = subject
        topic.sub_assignments.each do |sub_assignment|
          expect(sub_assignment.description).to eq(topic.message)
        end
      end

      context "when sub_assignments are not present" do
        before { data[:assignment].delete(:sub_assignments) }

        it "imports assignment" do
          expect(subject.assignment).to be_present
        end

        it "does not create sub assignments" do
          expect(subject.sub_assignments).to be_empty
        end
      end
    end

    context "when reply_to_entry_required_count is not present" do
      it "defaults to 0" do
        context.account.disable_feature!(:discussion_checkpoints)
        data.delete(:reply_to_entry_required_count)
        expect(subject.reply_to_entry_required_count).to eq(0)
      end
    end
  end
end
