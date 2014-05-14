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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/shared/_select_content_dialog" do
  it "should alphabetize the file list" do
    course_with_teacher
    folder = @course.folders.create!(:name => 'test')
    folder.attachments.create!(:context => @course, :uploaded_data => default_uploaded_data, :display_name => "b")
    folder.attachments.create!(:context => @course, :uploaded_data => default_uploaded_data, :display_name => "a")
    view_context
    render :partial => "shared/select_content_dialog"
    response.should_not be_nil
    page = Nokogiri(response.body)
    options = page.css("#attachments_select .module_item_select option")
    options[1].text.should == "a"
    options[2].text.should == "b"
  end

  it "should include unpublished wiki pages" do
    Account.default.enable_feature!(:draft_state)
    course_with_teacher
    published_page = @course.wiki.wiki_pages.build title: 'published_page'
    published_page.workflow_state = 'active'
    published_page.save!
    unpublished_page = @course.wiki.wiki_pages.build title: 'unpublished_page'
    unpublished_page.workflow_state = 'unpublished'
    unpublished_page.save!
    view_context
    render partial: 'shared/select_content_dialog'
    page = Nokogiri(response.body)
    options = page.css("#wiki_pages_select .module_item_select option")
    (%w(unpublished_page published_page) - options.map(&:text)).should be_empty
  end

  it "should not offer to create assigments or quizzes if the user doesn't have permission" do
    @account = Account.default
    course_with_ta account: @account, active_all: true
    existing_quiz = @course.quizzes.create! title: 'existing quiz'
    @account.role_overrides.create! enrollment_type: 'TaEnrollment', permission: 'manage_assignments', enabled: false
    view_context
    render partial: 'shared/select_content_dialog'
    page = Nokogiri(response.body)
    page.css(%Q{#quizs_select .module_item_select option[value="#{existing_quiz.id}"]}).should_not be_empty
    page.css(%Q{#quizs_select .module_item_select option[value="new"]}).should be_empty
    page.css(%Q{#assignments_select .module_item_select option[value="new"]}).should be_empty
  end

  it "should offer to create assigments if the user has permission" do
    @account = Account.default
    course_with_ta account: @account, active_all: true
    view_context
    render partial: 'shared/select_content_dialog'
    page = Nokogiri(response.body)
    page.css(%Q{#assignments_select .module_item_select option[value="new"]}).should_not be_empty
  end

  it "should create new topics in unpublished state if draft state is enabled" do
    course_with_teacher(active_all: true, draft_state: true)
    view_context
    render partial: 'shared/select_content_dialog'
    page = Nokogiri(response.body)
    page.at_css(%Q{#discussion_topics_select .new input[name="published"][value="false"]}).should_not be_nil
  end

  it "should create new topics in published state if draft state is disabled" do
    course_with_teacher(active_all: true, draft_state: false)
    view_context
    render partial: 'shared/select_content_dialog'
    page = Nokogiri(response.body)
    page.at_css(%Q{#discussion_topics_select .new input[name="published"]}).should be_nil
  end
end

