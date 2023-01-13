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

require_relative "../views_helper"

describe "shared/_select_content_dialog" do
  it "indicates plural file upload" do
    assign(:combined_active_quizzes, [])
    course_with_teacher
    view_context
    render partial: "shared/select_content_dialog"
    page = Nokogiri(response.body)
    file_select = page.css("#file_select_label")
    expect(file_select.inner_text).to match(/Create File\(s\)\./)
  end

  describe "new quizzes" do
    before do
      course_with_teacher
      view_context
      allow(NewQuizzesFeaturesHelper).to receive(:new_quizzes_enabled?).and_return(true)
    end

    it "renders classic quizzes and new quizzes together when Quiz is selected" do
      assign(:combined_active_quizzes, [
               [1, "A", "quiz"],
               [2, "B", "quiz"],
               [1, "C", "assignment"]
             ])
      assign(:combined_active_quizzes_includes_both_types, true)
      render partial: "shared/select_content_dialog"
      page = Nokogiri(response.body)
      options = page.css("#quizs_select .module_item_select option").map(&:text)
      expect(options).to eq(["[ Create Quiz ]", "A (classic)", "B (classic)", "C "])
    end

    it "does not render the (classic) identifier when there are only classic quizzes listed" do
      assign(:combined_active_quizzes, [
               [1, "A", "quiz"],
               [2, "B", "quiz"]
             ])
      assign(:combined_active_quizzes_includes_both_types, false)
      render partial: "shared/select_content_dialog"
      page = Nokogiri(response.body)
      options = page.css("#quizs_select .module_item_select option").map(&:text)
      expect(options).to eq(["[ Create Quiz ]", "A ", "B "])
    end

    it "does not render New Quizzes as Assignments" do
      assign(:combined_active_quizzes, [])
      new_quizzes_assignment(course: @course, title: "Some New Quiz")
      render partial: "shared/select_content_dialog"
      page = Nokogiri(response.body)
      options = page.css("#assignments_select .module_item_select option").map(&:text)
      expect(options).to eq(["[ Create Assignment ]"])
    end

    it "renders radios for quiz engine selection" do
      assign(:combined_active_quizzes, [])
      render partial: "shared/select_content_dialog"
      page = Nokogiri(response.body)
      expect(page.at_css('#quizs_select .new input[type="radio"]')).not_to be_nil
    end

    context "with new quizzes FF disabled" do
      before do
        allow(NewQuizzesFeaturesHelper).to receive(:new_quizzes_enabled?).and_return(false)
      end

      it "hides radios for quiz engine selection" do
        assign(:combined_active_quizzes, [])
        render partial: "shared/select_content_dialog"
        page = Nokogiri(response.body)
        expect(page.at_css('#quizs_select .new input[type="radio"]')).to be_nil
      end
    end

    context "with quiz engine selection saved" do
      it "hides radios and honors selection for New Quizzes" do
        assign(:combined_active_quizzes, [])
        expect(@course).to receive(:settings).and_return({
                                                           engine_selected: {
                                                             user_id: {
                                                               newquizzes_engine_selected: "true"
                                                             }
                                                           }
                                                         })
        render partial: "shared/select_content_dialog"
        page = Nokogiri(response.body)
        expect(page.css("#quizs_select .new tr").first["style"]).to eq "display: none;"
        expect(page.at_css('#quizs_select .new input[type="radio"][checked]')).not_to be_nil
      end

      it "hides radios and honors selection for Classic Quizzes" do
        assign(:combined_active_quizzes, [])
        expect(@course).to receive(:settings).and_return({
                                                           engine_selected: {
                                                             user_id: {
                                                               newquizzes_engine_selected: "false"
                                                             }
                                                           }
                                                         })
        render partial: "shared/select_content_dialog"
        page = Nokogiri(response.body)
        expect(page.css("#quizs_select .new tr").first["style"]).to eq "display: none;"
        expect(page.at_css('#quizs_select .new input[type="radio"][checked]')).to be_nil
      end
    end

    context "with quiz engine never selected" do
      it "shows radios and selects new quizzes by default" do
        assign(:combined_active_quizzes, [])
        expect(@course).to receive(:settings).and_return({})
        render partial: "shared/select_content_dialog"
        page = Nokogiri(response.body)
        expect(page.css("#quizs_select .new tr").first["style"]).to eq ""
        expect(page.at_css('#quizs_select .new input[type="radio"][checked]')).not_to be_nil
      end
    end

    context "with quiz engine selection revoked" do
      it "shows radios and selects new quizzes by default" do
        assign(:combined_active_quizzes, [])
        expect(@course).to receive(:settings).and_return({
                                                           engine_selected: {
                                                             user_id: {
                                                               newquizzes_engine_selected: "null"
                                                             }
                                                           }
                                                         })
        render partial: "shared/select_content_dialog"
        page = Nokogiri(response.body)
        expect(page.css("#quizs_select .new tr").first["style"]).to eq ""
        expect(page.at_css('#quizs_select .new input[type="radio"][checked]')).not_to be_nil
      end
    end
  end

  it "includes unpublished wiki pages" do
    assign(:combined_active_quizzes, [])
    course_with_teacher
    published_page = @course.wiki_pages.build title: "published_page"
    published_page.workflow_state = "active"
    published_page.save!
    unpublished_page = @course.wiki_pages.build title: "unpublished_page"
    unpublished_page.workflow_state = "unpublished"
    unpublished_page.save!
    view_context
    render partial: "shared/select_content_dialog"
    page = Nokogiri(response.body)
    options = page.css("#wiki_pages_select .module_item_select option")
    expect(%w[unpublished_page published_page] - options.map(&:text)).to be_empty
  end

  it "does not offer to create assignments or quizzes if the user doesn't have permission" do
    @account = Account.default
    course_with_ta account: @account, active_all: true
    existing_quiz = @course.quizzes.create! title: "existing quiz"
    assign(:combined_active_quizzes, [[existing_quiz.id, "existing quiz", "quiz"]])
    @account.role_overrides.create! role: ta_role, permission: "manage_assignments_add", enabled: false
    view_context
    render partial: "shared/select_content_dialog"
    page = Nokogiri(response.body)
    expect(page.css(%(#quizs_select .module_item_select option[value="quiz_#{existing_quiz.id}"]))).not_to be_empty
    expect(page.css('#quizs_select .module_item_select option[value="new"]')).to be_empty
    expect(page.css('#assignments_select .module_item_select option[value="new"]')).to be_empty
  end

  it "offers to create assignments if the user has permission" do
    assign(:combined_active_quizzes, [])
    @account = Account.default
    course_with_ta account: @account, active_all: true
    view_context
    render partial: "shared/select_content_dialog"
    page = Nokogiri(response.body)
    expect(page.css('#assignments_select .module_item_select option[value="new"]')).not_to be_empty
  end

  it "creates new topics in unpublished state if draft state is enabled" do
    assign(:combined_active_quizzes, [])
    course_with_teacher(active_all: true)
    view_context
    render partial: "shared/select_content_dialog"
    page = Nokogiri(response.body)
    expect(page.at_css('#discussion_topics_select .new input[name="published"][value="false"]')).not_to be_nil
  end

  describe "sorting" do
    before(:once) do
      course_with_teacher(active_all: true)
      @groupB = @course.assignment_groups.create!(name: "group B")
      @groupA = @course.assignment_groups.create!(name: "group A")
      view_context
    end

    it "sorts wiki pages by name" do
      assign(:combined_active_quizzes, [])
      a = @course.wiki_pages.create!(title: "A")
      c = @course.wiki_pages.create!(title: "C")
      b = @course.wiki_pages.create!(title: "B")
      render partial: "shared/select_content_dialog"
      page = Nokogiri(response.body)
      options = page.css("#wiki_pages_select option").map { |option| [option.text, option.attribute("value").to_s] }
      expect(options).to eq([["[ Create Page ]", "new"], ["A", a.id.to_s], ["B", b.id.to_s], ["C", c.id.to_s]])
    end

    it "sorts quizzes and the quiz assignment group selector by name" do
      a = @course.quizzes.create!(title: "A")
      c = @course.quizzes.create!(title: "C")
      b = @course.quizzes.create!(title: "B")
      assign(:combined_active_quizzes, [
               [a.id, "A", "quiz"],
               [b.id, "B", "quiz"],
               [c.id, "C", "quiz"]
             ])
      render partial: "shared/select_content_dialog"
      page = Nokogiri(response.body)
      options = page.css("#quizs_select .module_item_select option").map { |option| [option.text, option.attribute("value").to_s] }
      expect(options).to eq([["[ Create Quiz ]", "new"], ["A ", "quiz_#{a.id}"], ["B ", "quiz_#{b.id}"], ["C ", "quiz_#{c.id}"]])
      groups = page.css('select[name="quiz[assignment_group_id]"] option').map { |option| [option.text, option.attribute("value").to_s] }
      expect(groups).to eq([["group A", @groupA.id.to_s], ["group B", @groupB.id.to_s]])
    end

    it "sorts assignments by name within assignment groups, which are also sorted by name" do
      assign(:combined_active_quizzes, [])
      bb = @course.assignments.create!(title: "B", assignment_group: @groupB)
      aa = @course.assignments.create!(title: "A", assignment_group: @groupA)
      ac = @course.assignments.create!(title: "C", assignment_group: @groupA)
      ba = @course.assignments.create!(title: "A", assignment_group: @groupB)
      ab = @course.assignments.create!(title: "B", assignment_group: @groupA)
      bc = @course.assignments.create!(title: "C", assignment_group: @groupB)
      render partial: "shared/select_content_dialog"
      page = Nokogiri(response.body)
      optgroups = page.css("#assignments_select .module_item_select optgroup")
      expect(optgroups.map { |optgroup| optgroup.attribute("label").to_s }).to eq(["group A", "group B"])
      aga = page.css('optgroup[label="group A"] option').map { |option| [option.text, option.attribute("value").to_s] }
      expect(aga).to eq([["A", aa.id.to_s], ["B", ab.id.to_s], ["C", ac.id.to_s]])
      agb = page.css('optgroup[label="group B"] option').map { |option| [option.text, option.attribute("value").to_s] }
      expect(agb).to eq([["A", ba.id.to_s], ["B", bb.id.to_s], ["C", bc.id.to_s]])
    end

    it "sorts discussion topics by name" do
      assign(:combined_active_quizzes, [])
      a = @course.discussion_topics.create!(title: "A")
      c = @course.discussion_topics.create!(title: "C")
      b = @course.discussion_topics.create!(title: "B")
      render partial: "shared/select_content_dialog"
      page = Nokogiri(response.body)
      options = page.css("#discussion_topics_select option").map { |option| [option.text, option.attribute("value").to_s] }
      expect(options).to eq([["[ Create Topic ]", "new"], ["A", a.id.to_s], ["B", b.id.to_s], ["C", c.id.to_s]])
    end
  end
end
