# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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
require_relative "../helpers/context_modules_common"
require_relative "page_objects/modules_index_page"

describe "estimated duration editor for module items" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage

  context "As a teacher" do
    before(:once) do
      course_with_teacher(active_all: true)
      @course.account.enable_feature!(:horizon_course_setting)

      @quiz = @course.quizzes.create!(title: "quizz")
      @assignment = @course.assignments.create!(title: "assignment 1", submission_types: "online_text_entry")
      @attachment = @course.attachments.create!(display_name: "file_name", uploaded_data: default_uploaded_data)
      @discussion_topic = @course.discussion_topics.create!(title: "assignment topic title",
                                                            message: "assignment topic message")
      @wiki_page = @course.wiki_pages.create!(title: "title", body: "")

      @module_1 = @course.context_modules.create!(name: "First module")

      @quiz_tag = @module_1.add_item({ id: @quiz.id, type: "quiz" })
      @assignment_tag = @module_1.add_item({ id: @assignment.id, type: "assignment" })
      @attachment_tag = @module_1.add_item({ id: @attachment.id, type: "attachment" })
      @wiki_page_tag = @module_1.add_item(id: @wiki_page.id, type: "wiki_page")
      @discussion_topic_tag = @module_1.add_item({ id: @discussion_topic.id, type: "discussion_topic" })
      @subheader_tag = @module_1.add_item(type: "context_module_sub_header", title: "subheader")
      @external_url_tag = @module_1.add_item(type: "external_url",
                                             url: "http://example.com/lolcats",
                                             title: "external url")

      @module_1.save!
      @course.reload
    end

    context "with Horizon course disabled" do
      before do
        user_session(@teacher)
        @course.update!(horizon_course: false)
        @course.save!
        get "/courses/#{@course.id}/modules"
      end

      let(:editor_items) do
        [
          @quiz_tag,
          @assignment_tag,
          @wiki_page_tag,
          @external_url_tag,
          @subheader_tag,
          @discussion_topic_tag,
          @attachment_tag
        ]
      end

      it "no estimated duration summary in module header" do
        expect(element_exists?(".estimated_duration_header_title")).to be_falsey
        expect(element_exists?(".estimated_duration_header_minutes")).to be_falsey
      end

      it "no estimated duration editor feature for different editor dialogs" do
        editor_items.each do |item|
          click_on_edit_item_link(item.id)
          check_estimated_duration_in_editor(false, false)
          close_editor_dialog
        end
      end
    end

    context "with Horizon course enabled" do
      before do
        user_session(@teacher)
        @course.update!(horizon_course: true)
        @course.save!
        get "/courses/#{@course.id}/modules"
      end

      # add back discussion topic to test if it's available for horizon courses
      # { tag: @discussion_topic_tag, visible: true, duration: 60 },
      let(:editor_items) do
        [
          { tag: @quiz_tag, visible: true, duration: 34 },
          { tag: @assignment_tag, visible: true, duration: 12 },
          { tag: @wiki_page_tag, visible: true, duration: 20 },
          { tag: @external_url_tag, visible: true, duration: 8 },
          { tag: @attachment_tag, visible: true, duration: 45 },
          { tag: @subheader_tag, visible: false },
        ]
      end

      # add back discussion topic to test if it's available for horizon courses
      # { tag: @discussion_topic_tag, duration: 60, change_duration: 6, selector: ".discussion_topic" }
      let(:editor_items_for_copy) do
        [
          { tag: @wiki_page_tag, duration: 34, change_duration: 43, selector: ".wiki_page" },
          { tag: @assignment_tag, duration: 12, change_duration: 21, selector: ".assignment" }
        ]
      end

      it "estimated duration editor feature available" do
        expect(f(".collapse_module_link .estimated_duration_header_title")).not_to be_displayed
        expect(f(".collapse_module_link .estimated_duration_header_minutes")).not_to be_displayed

        # set estimated duration for each item
        editor_items.each do |item|
          expect(f("#context_module_item_#{item[:tag].id} .estimated_duration_display")).not_to be_displayed
          click_on_edit_item_link(item[:tag].id)
          check_estimated_duration_in_editor(true, item[:visible])

          if item[:visible]
            set_value f("#estimated_minutes"), item[:duration]
            save_edit_item_form
            expect(f("#context_module_item_#{item[:tag].id} .estimated_duration_display").text).to eq("#{item[:duration]} Mins")
          else
            close_editor_dialog
          end
        end

        # check the module header for the total estimated duration
        total_duration = editor_items.select { |item| item[:visible] }.sum { |item| item[:duration] }
        expect(f(".collapse_module_link .estimated_duration_header_title")).to be_displayed
        expect(f(".collapse_module_link .estimated_duration_header_minutes")).to be_displayed
        expect(f(".collapse_module_link .estimated_duration_header_minutes").text).to eq("#{total_duration} Mins")

        # remove the estimated durations from every item
        editor_items.each do |item|
          click_on_edit_item_link(item[:tag].id)

          if item[:visible]
            set_value f("#estimated_minutes"), 0
            save_edit_item_form
            expect(f("#context_module_item_#{item[:tag].id} .estimated_duration_display")).not_to be_displayed
          else
            close_editor_dialog
          end
        end

        expect(f(".collapse_module_link .estimated_duration_header_title")).not_to be_displayed
        expect(f(".collapse_module_link .estimated_duration_header_minutes")).not_to be_displayed
      end

      it "estimated duration is copied when module item is duplicated" do
        editor_items_for_copy.each do |item|
          # add estimated duration to the original item and copy it
          click_on_edit_item_link(item[:tag].id)
          set_value f("#estimated_minutes"), item[:duration]
          save_edit_item_form
          click_on_duplicate_item_link(item[:tag].id)
          wait_for_ajaximations

          # check if the estimated duration is copied
          tags = ff("#{item[:selector]} .estimated_duration_display")
          expect(tags.length).to eq 2
          expect(tags[0].text).to eq(tags[1].text)

          # change the estimated duration of the original item and check that the duplicate is not affected
          click_on_edit_item_link(item[:tag].id)
          set_value f("#estimated_minutes"), item[:change_duration]
          save_edit_item_form
          tags = ff("#{item[:selector]} .estimated_duration_display")
          expect(tags[0].text).not_to eq(tags[1].text)
        end
      end
    end
  end
end
