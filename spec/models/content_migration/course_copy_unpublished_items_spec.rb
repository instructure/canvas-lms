# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "course_copy_helper"

describe ContentMigration do
  context "course copy unpublished items" do
    include_context "course copy"

    it "copies unpublished modules" do
      cm = @copy_from.context_modules.create!(name: "some module")
      cm.publish
      cm2 = @copy_from.context_modules.create!(name: "another module")
      cm2.unpublish

      run_course_copy

      expect(@copy_to.context_modules.count).to eq 2
      cm_2 = @copy_to.context_modules.where(migration_id: mig_id(cm)).first
      expect(cm_2.workflow_state).to eq "active"
      cm2_2 = @copy_to.context_modules.where(migration_id: mig_id(cm2)).first
      expect(cm2_2.workflow_state).to eq "unpublished"
    end

    it "preserves published state of contentless module items" do
      cm = @copy_from.context_modules.create!(name: "eh module")
      pu = cm.add_item(type: "external_url", title: "published", url: "http://published.example.com")
      pu.publish!
      uu = cm.add_item(type: "external_url", title: "unpublished", url: "http://unpublished.example.com")
      expect(uu).to be_unpublished

      run_course_copy

      pu2 = @copy_to.context_module_tags.where(migration_id: mig_id(pu)).first
      expect(pu2).to be_active
      uu2 = @copy_to.context_module_tags.where(migration_id: mig_id(uu)).first
      expect(uu2).to be_unpublished
    end

    it "copies links to unpublished items in modules" do
      mod1 = @copy_from.context_modules.create!(name: "some module")
      page = @copy_from.wiki_pages.create(title: "some page")
      page.workflow_state = :unpublished
      page.save!
      mod1.add_item({ id: page.id, type: "wiki_page" })

      asmnt1 = @copy_from.assignments.create!(title: "some assignment")
      asmnt1.workflow_state = :unpublished
      asmnt1.save!
      mod1.add_item({ id: asmnt1.id, type: "assignment", indent: 1 })

      run_course_copy

      mod1_copy = @copy_to.context_modules.where(migration_id: mig_id(mod1)).first
      expect(mod1_copy.content_tags.count).to eq 2

      mod1_copy.content_tags.each do |tag_copy|
        expect(tag_copy.unpublished?).to be true
        expect(tag_copy.content.unpublished?).to be true
      end
    end

    it "copies unpublished discussion topics" do
      dt1 = @copy_from.discussion_topics.create!(message: "hideeho", title: "Blah")
      dt1.workflow_state = :unpublished
      dt1.save!
      dt2 = @copy_from.discussion_topics.create!(message: "asdf", title: "qwert")
      dt2.workflow_state = :active
      dt2.save!

      run_course_copy

      dt1_copy = @copy_to.discussion_topics.where(migration_id: mig_id(dt1)).first
      expect(dt1_copy.workflow_state).to eq "unpublished"
      dt2_copy = @copy_to.discussion_topics.where(migration_id: mig_id(dt2)).first
      expect(dt2_copy.workflow_state).to eq "active"
    end

    it "copies unpublished wiki pages" do
      wiki = @copy_from.wiki_pages.create(title: "wiki", body: "ohai")
      wiki.workflow_state = :unpublished
      wiki.save!

      run_course_copy

      wiki2 = @copy_to.wiki_pages.where(migration_id: mig_id(wiki)).first
      expect(wiki2.workflow_state).to eq "unpublished"
    end

    it "copies unpublished quiz assignments" do
      skip unless Qti.qti_enabled?
      @quiz = @copy_from.quizzes.create!
      @quiz.did_edit
      @quiz.offer!
      @quiz.unpublish!
      expect(@quiz.assignment).to be_unpublished

      @cm.copy_options = {
        assignments: { mig_id(@quiz.assignment) => "0" },
        quizzes: { mig_id(@quiz) => "1" },
      }
      @cm.save!

      run_course_copy

      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(@quiz)).first
      expect(quiz_to).not_to be_nil
      expect(quiz_to.assignment).not_to be_nil
      expect(quiz_to.assignment).to be_unpublished
      expect(quiz_to.assignment.migration_id).to eq mig_id(@quiz.assignment)
    end

    it "does not re-unpublish module items on re-copy" do
      skip "Requires QtiMigrationTool" unless Qti.qti_enabled?

      mod = @copy_from.context_modules.create!(name: "some module")
      tags = []

      tags << mod.add_item({ title: "Example 1", type: "external_url", url: "http://derp.derp/something" })

      asmnt = @copy_from.assignments.create!(title: "some assignment")
      tags << mod.add_item({ id: asmnt.id, type: "assignment" })

      quiz = @copy_from.quizzes.create!(title: "some quiz")
      tags << mod.add_item({ id: quiz.id, type: "quiz" })

      topic = @copy_from.discussion_topics.create!(title: "some topic")
      tags << mod.add_item({ id: topic.id, type: "discussion_topic" })

      page = @copy_from.wiki_pages.create!(title: "some page")
      tags << mod.add_item({ id: page.id, type: "wiki_page" })

      file = @copy_from.attachments.create!(display_name: "some file", uploaded_data: default_uploaded_data, locked: true)
      tags << mod.add_item({ id: file.id, type: "attachment" })

      tags.each do |tag|
        tag.unpublish
        tag.save!
        tag.update_asset_workflow_state!
      end

      run_course_copy

      mod_to = @copy_to.context_modules.where(migration_id: mig_id(mod)).first
      expect(mod_to.content_tags.count).to eq tags.count

      mod_to.content_tags.each do |tag_to|
        expect(tag_to).to be_unpublished
        tag_to.publish
        tag_to.save!
        tag_to.update_asset_workflow_state!
      end

      run_course_copy

      mod_to.content_tags.each do |tag_to|
        tag_to.reload
        expect(tag_to).to be_published

        tag_to.content&.destroy
      end
      mod_to.destroy

      run_course_copy

      mod_to.reload
      expect(mod_to).to_not be_deleted
      mod_to.content_tags.each do |tag_to|
        if tag_to.content
          tag_to.content.reload
          expect(tag_to.content).to_not be_deleted
        end
      end
    end
  end
end
