# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe SmartSearch do
  before do
    skip "not available" unless ActiveRecord::Base.connection.table_exists?("wiki_page_embeddings")

    allow(SmartSearch).to receive(:generate_embedding) { |input| input.chars.map(&:ord).fill(0, input.size...1024).slice(0...1024) }
    allow(SmartSearch).to receive(:bedrock_client).and_return(double)
  end

  before :once do
    course_factory
    @course.wiki_pages.create! title: "red pandas", body: "foo " * 400
    @course.assignments.create! name: "horse feathers", description: "..."
    @course.assignments.create! name: "hungry hippos", description: "..."
    @course.discussion_topics.create! title: "!!!", message: "..."
    @course.announcements.create! title: "hear ye", message: "..."
    @course.enable_feature! :smart_search
  end

  describe "#index_course" do
    it "indexes a new course" do
      SmartSearch.index_course(@course)
      expect(WikiPageEmbedding.where(wiki_page_id: @course.wiki_pages.select(:id)).count).to eq 2
      expect(AssignmentEmbedding.where(assignment_id: @course.assignments.select(:id)).count).to eq 2
      expect(DiscussionTopicEmbedding.where(discussion_topic_id: @course.discussion_topics.select(:id)).count).to eq 2
    end

    it "indexes only missing items" do
      @course.assignments.first.generate_embeddings(synchronous: true)
      expect_any_instance_of(Assignment).to receive(:generate_embeddings).once.and_call_original
      SmartSearch.index_course(@course)
    end

    it "reindexes items with old embeddings" do
      SmartSearch.index_course(@course)
      @course.assignments.first.embeddings.update_all(version: 0)
      @course.search_embedding_version = 0
      @course.save!
      expect(SmartSearch).to receive(:generate_embedding).once.and_return([2] * 1536)
      SmartSearch.index_course(@course)
      expect(@course.assignments.first.embeddings.first.version).to eq SmartSearch::EMBEDDING_VERSION
    end
  end

  describe "course copy" do
    def run_course_copy(copy_from, copy_to)
      @cm = ContentMigration.new(context: copy_to,
                                 source_course: copy_from,
                                 migration_type: "course_copy_importer",
                                 copy_options: { everything: "1" })
      @cm.migration_settings[:import_immediately] = true
      @cm.set_default_settings
      @cm.save!
      worker = Canvas::Migration::Worker::CourseCopyWorker.new
      worker.perform(@cm)
    end

    before :once do
      next unless ActiveRecord::Base.connection.table_exists?("wiki_page_embeddings")

      @copy_from = @course
      SmartSearch.index_course(@copy_from)

      @copy_to = course_factory
    end

    context "destination does not enable smart search feature" do
      it "does not create or copy embeddings" do
        run_course_copy(@copy_from, @copy_to)
        expect(WikiPageEmbedding.where(wiki_page_id: @copy_to.wiki_pages.select(:id)).count).to eq 0
        expect(AssignmentEmbedding.where(assignment_id: @copy_to.assignments.select(:id)).count).to eq 0
        expect(DiscussionTopicEmbedding.where(discussion_topic_id: @copy_to.discussion_topics.select(:id)).count).to eq 0
      end
    end

    context "destination enables smart search feature" do
      before :once do
        @copy_to&.enable_feature! :smart_search
      end

      it "copies embeddings" do
        # create some existing embeddings first so we can verify they are overwritten or ignored as appropriate
        # we will simulate an assignment that was copied previously, and one that is not part of the migration
        src_assignment = @copy_from.assignments.first
        @copy_to.assignments.create! name: src_assignment.name, description: src_assignment.description, migration_id: CC::CCHelper.create_key(src_assignment, global: true)
        distractor = @copy_to.assignments.create! name: "original", description: "..."
        run_jobs
        expect(distractor.embeddings.count).to eq 1

        expect(SmartSearch).not_to receive(:generate_embedding)
        run_course_copy(@copy_from, @copy_to)
        expect(@copy_from.wiki_pages.first.embeddings.map(&:embedding).sort).to eq @copy_to.wiki_pages.first.embeddings.map(&:embedding).sort
        expect(@copy_from.assignments.first.embeddings.map(&:embedding).sort).to eq @copy_to.assignments.first.embeddings.map(&:embedding).sort
        expect(@copy_from.assignments.last.embeddings.map(&:embedding).sort).to eq @copy_to.assignments.last.embeddings.map(&:embedding).sort
        expect(@copy_from.discussion_topics.only_discussion_topics.first.embeddings.map(&:embedding).sort).to eq @copy_to.discussion_topics.only_discussion_topics.first.embeddings.map(&:embedding).sort
        expect(@copy_from.announcements.first.embeddings.map(&:embedding).sort).to eq @copy_to.announcements.first.embeddings.map(&:embedding).sort
        expect(distractor.reload.embeddings.count).to eq 1
      end

      it "generates embeddings in the destination if the source course doesn't have them or is out of date" do
        @copy_from.disable_feature! :smart_search
        run_course_copy(@copy_from, @copy_to)
        run_jobs
        expect(SmartSearch).to have_received(:generate_embedding).at_least(6).times
        expect(WikiPageEmbedding.where(wiki_page_id: @copy_to.wiki_pages.select(:id)).count).to eq 2
        expect(AssignmentEmbedding.where(assignment_id: @copy_to.assignments.select(:id)).count).to eq 2
        expect(DiscussionTopicEmbedding.where(discussion_topic_id: @copy_to.discussion_topics.select(:id)).count).to eq 2
      end
    end
  end

  describe "blueprint sync" do
    def run_blueprint_sync(template)
      @mm = MasterCourses::MasterMigration.start_new_migration!(template, nil)
      run_jobs
      @mm.reload
    end

    before :once do
      next unless ActiveRecord::Base.connection.table_exists?("wiki_page_embeddings")

      @blueprint = @course
      @template = MasterCourses::MasterTemplate.set_as_master_course(@blueprint)
      @assoc1 = course_factory
      @assoc2 = course_factory
      @template.add_child_course!(@assoc1)
      @template.add_child_course!(@assoc2)
      @blueprint.enable_feature! :smart_search
      @assoc1.enable_feature! :smart_search
      SmartSearch.index_course(@blueprint)
    end

    it "copies embeddings to destinations that enable smart search" do
      expect(SmartSearch).not_to receive(:generate_embedding)
      run_blueprint_sync(@template)

      expect(@blueprint.wiki_pages.first.embeddings.map(&:embedding).sort).to eq @assoc1.wiki_pages.first.embeddings.map(&:embedding).sort
      expect(@blueprint.assignments.first.embeddings.map(&:embedding).sort).to eq @assoc1.assignments.first.embeddings.map(&:embedding).sort
      expect(@blueprint.assignments.last.embeddings.map(&:embedding).sort).to eq @assoc1.assignments.last.embeddings.map(&:embedding).sort
      expect(@blueprint.discussion_topics.only_discussion_topics.first.embeddings.map(&:embedding).sort).to eq @assoc1.discussion_topics.only_discussion_topics.first.embeddings.map(&:embedding).sort
      expect(@blueprint.announcements.first.embeddings.map(&:embedding).sort).to eq @assoc1.announcements.first.embeddings.map(&:embedding).sort

      expect(@assoc2.wiki_pages.first.embeddings).to be_empty
      expect(@assoc2.assignments.first.embeddings).to be_empty
      expect(@assoc2.assignments.last.embeddings).to be_empty
      expect(@assoc2.discussion_topics.only_discussion_topics.first.embeddings).to be_empty
      expect(@assoc2.announcements.first.embeddings).to be_empty
    end
  end
end
