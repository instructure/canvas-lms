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

describe "context_modules/index" do
  before do
    assign(:body_classes, [])
    assign(:menu_tools, Hash.new([]))
    assign(:collapsed_modules, [])
  end

  it "renders" do
    course_factory
    view_context(@course, @user)
    assign(:modules, @course.context_modules.active)
    render "context_modules/index"
    expect(response).not_to be_nil
  end

  it "shows content_tags" do
    course_factory
    context_module = @course.context_modules.create!
    module_item = context_module.add_item type: "context_module_sub_header"
    module_item.publish! if module_item.unpublished?
    view_context(@course, @user)
    assign(:modules, @course.context_modules.active)
    render "context_modules/index"
    expect(response).not_to be_nil
    page = Nokogiri("<document>" + response.body + "</document>")
    expect(page.css("#context_module_item_#{module_item.id}").length).to eq 1
  end

  it "shows unpublished content_tags" do
    course_with_teacher(active_all: true)
    wiki_page = wiki_page_model(course: @course)
    wiki_page.workflow_state = "unpublished"
    wiki_page.save!

    context_module = @course.context_modules.create!
    module_item = context_module.add_item(type: "wiki_page", id: wiki_page.id)
    expect(module_item.workflow_state).to eq "unpublished"

    view_context(@course, @user)
    assign(:modules, @course.context_modules.active)
    render "context_modules/index"

    expect(response).not_to be_nil
    page = Nokogiri("<document>" + response.body + "</document>")
    expect(page.css("#context_module_item_#{module_item.id}").length).to eq 1
  end

  it "does not show deleted content_tags" do
    course_factory
    context_module = @course.context_modules.create!
    module_item = context_module.add_item type: "context_module_sub_header"
    module_item.destroy
    view_context(@course, @user)
    assign(:modules, @course.context_modules.active)
    render "context_modules/index"
    expect(response).not_to be_nil
    page = Nokogiri("<document>" + response.body + "</document>")
    expect(page.css("#context_module_item_#{module_item.id}").length).to eq 0
  end

  it "does not show failed_to_duplicate content_tags" do
    course_factory
    context_module = @course.context_modules.create!
    assignment = @course.assignments.create!(workflow_state: "failed_to_duplicate")
    module_item = context_module.add_item(type: "assignment", id: assignment.id)

    view_context(@course, @user)
    assign(:modules, @course.context_modules.active)
    render "context_modules/index"
    expect(response).not_to be_nil
    page = Nokogiri("<document>" + response.body + "</document>")
    expect(page.css("#context_module_item_#{module_item.id}").length).to eq 0
  end

  it "does not show duplicating content_tags" do
    course_factory
    context_module = @course.context_modules.create!
    assignment = @course.assignments.create!(workflow_state: "duplicating")
    module_item = context_module.add_item(type: "assignment", id: assignment.id)

    view_context(@course, @user)
    assign(:modules, @course.context_modules.active)
    render "context_modules/index"
    expect(response).not_to be_nil
    page = Nokogiri("<document>" + response.body + "</document>")
    expect(page.css("#context_module_item_#{module_item.id}").length).to eq 0
  end

  it "shows download course content if settings are enabled" do
    course_factory
    acct = @course.root_account
    acct.settings[:enable_offline_web_export] = true
    acct.save!
    view_context(@course, @user)
    assign(:modules, @course.context_modules.active)
    assign(:allow_web_export_download, true)
    render "context_modules/index"
    expect(response).not_to be_nil
    page = Nokogiri("<document>" + response.body + "</document>")
    expect(page.css(".offline_web_export").length).to eq 1
  end

  context "direct_share" do
    before :once do
      course_with_teacher
      @assignment = assignment_model
      @module = @course.context_modules.create!
      @tag = @module.add_item(type: "assignment", id: @assignment.id)
    end

    it "shows module sharing menu items if direct_share is enabled" do
      view_context(@course, @teacher)
      assign(:modules, @course.context_modules.active)
      render "context_modules/index"
      page = Nokogiri("<document>" + response.body + "</document>")
      expect(page.css(".module_copy_to").length).to eq 1
      expect(page.css(".module_send_to").length).to eq 1
      expect(page.css(".module_item_copy_to").length).to eq 1
      expect(page.css(".module_item_send_to").length).to eq 1
    end

    it "does not include item sharing menu items for things that can't stand alone" do
      @tag.destroy
      @module.add_item type: "context_module_sub_header", title: "blah"
      view_context(@course, @teacher)
      assign(:modules, @course.context_modules.active)
      render "context_modules/index"
      page = Nokogiri("<document>" + response.body + "</document>")
      expect(page.css(".module_item_copy_to").length).to eq 0
      expect(page.css(".module_item_send_to").length).to eq 0
    end
  end

  context "assessments" do
    before :once do
      course_factory
      @assignment = assignment_model
      @assignment.update_attribute(:peer_reviews, true)
      @reviewer = student_in_course(course: @course, active_enrollment: true).user
      @reviewee = student_in_course(course: @course, active_enrollment: true).user
      @assignment.assign_peer_review(@reviewer, @reviewee)
      @assessment = @assignment.submission_for_student(@reviewer).assigned_assessments.first

      context_module = @course.context_modules.create!
      context_module_two = @course.context_modules.create!

      @module_item = context_module.add_item type: "assignment", id: @assignment.id
      @module_item_two = context_module_two.add_item type: "assignment", id: @assignment.id
      @module_item.publish! if @module_item.unpublished?
      @module_item_two.publish! if @module_item_two.unpublished?
    end

    it "shows the list of assessment requests when peer_reviews_for_a2 FF is ON" do
      @course.enable_feature! :peer_reviews_for_a2

      view_context(@course, @reviewer)
      assign(:modules, @course.context_modules.active)
      assign(:is_student, true)
      render "context_modules/index"
      expect(response).not_to be_nil
      page = Nokogiri("<document>" + response.body + "</document>")
      expect(page.css("#module_student_view_peer_reviews_#{@module_item.content_id}_#{@module_item.context_module_id}").length).to eq 1
    end

    it "shows the same assignment in two differenct context_modules" do
      @course.enable_feature! :peer_reviews_for_a2

      view_context(@course, @reviewer)
      assign(:modules, @course.context_modules.active)
      assign(:is_student, true)
      render "context_modules/index"
      expect(response).not_to be_nil

      page = response.body

      expect(page.include?("module_student_view_peer_reviews_#{@module_item.content_id}_#{@module_item.context_module_id}")).to be true
      expect(page.include?("module_student_view_peer_reviews_#{@module_item_two.content_id}_#{@module_item_two.context_module_id}")).to be true
    end

    it "does not show the list of assessment requests when peer_reviews_for_a2 FF is OFF" do
      @course.disable_feature! :peer_reviews_for_a2

      view_context(@course, @reviewer)
      assign(:modules, @course.context_modules.active)
      assign(:is_student, true)
      render "context_modules/index"
      expect(response).not_to be_nil
      page = Nokogiri("<document>" + response.body + "</document>")
      expect(page.css("#module_student_view_peer_reviews_#{@module_item.content_id}_#{@module_item.context_module_id}").length).to eq 0
    end
  end
end
