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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/context_modules/index" do
  before :each do
    assign(:body_classes, [])
    assign(:menu_tools, Hash.new([]))
    assign(:module_index_tools, [])
    assign(:module_group_tools, [])
    assign(:collapsed_modules, [])
  end

  it "should render" do
    course_factory
    view_context(@course, @user)
    assign(:modules, @course.context_modules.active)
    render 'context_modules/index'
    expect(response).not_to be_nil
  end

  it "should show content_tags" do
    course_factory
    context_module = @course.context_modules.create!
    module_item = context_module.add_item :type => 'context_module_sub_header'
    module_item.publish! if module_item.unpublished?
    view_context(@course, @user)
    assign(:modules, @course.context_modules.active)
    render 'context_modules/index'
    expect(response).not_to be_nil
    page = Nokogiri('<document>' + response.body + '</document>')
    expect(page.css("#context_module_item_#{module_item.id}").length).to eq 1
  end

  it "should show unpublished content_tags" do
    course_with_teacher(:active_all => true)
    wiki_page = wiki_page_model(:course => @course)
    wiki_page.workflow_state = 'unpublished'
    wiki_page.save!

    context_module = @course.context_modules.create!
    module_item = context_module.add_item(:type => 'wiki_page', :id => wiki_page.id)
    expect(module_item.workflow_state).to eq 'unpublished'

    view_context(@course, @user)
    assign(:modules, @course.context_modules.active)
    render 'context_modules/index'

    expect(response).not_to be_nil
    page = Nokogiri('<document>' + response.body + '</document>')
    expect(page.css("#context_module_item_#{module_item.id}").length).to eq 1
  end

  it "should not show deleted content_tags" do
    course_factory
    context_module = @course.context_modules.create!
    module_item = context_module.add_item :type => 'context_module_sub_header'
    module_item.destroy
    view_context(@course, @user)
    assign(:modules, @course.context_modules.active)
    render 'context_modules/index'
    expect(response).not_to be_nil
    page = Nokogiri('<document>' + response.body + '</document>')
    expect(page.css("#context_module_item_#{module_item.id}").length).to eq 0
  end

  it "does not show download course content if setting is disabled" do
    course_factory
    view_context(@course, @user)
    assign(:modules, @course.context_modules.active)
    render 'context_modules/index'
    expect(response).not_to be_nil
    page = Nokogiri('<document>' + response.body + '</document>')
    expect(page.css(".offline_web_export").length).to eq 0
  end

  it "shows download course content if settings are enabled" do
    course_factory
    acct = @course.root_account
    acct.settings[:enable_offline_web_export] = true
    acct.save!
    view_context(@course, @user)
    assign(:modules, @course.context_modules.active)
    assign(:allow_web_export_download, true)
    render 'context_modules/index'
    expect(response).not_to be_nil
    page = Nokogiri('<document>' + response.body + '</document>')
    expect(page.css(".offline_web_export").length).to eq 1
  end

  context "direct_share" do
    before :once do
      course_with_teacher
      @assignment = assignment_model
      @module = @course.context_modules.create!
      @tag = @module.add_item(type: 'assignment', id: @assignment.id)
    end

    it "does not show module sharing menu items if direct_share is disabled" do
      view_context(@course, @user)
      assign(:modules, @course.context_modules.active)
      render 'context_modules/index'
      page = Nokogiri('<document>' + response.body + '</document>')
      expect(page.css(".module_copy_to").length).to eq 0
      expect(page.css(".module_send_to").length).to eq 0
      expect(page.css(".module_item_copy_to").length).to eq 0
      expect(page.css(".module_item_send_to").length).to eq 0
    end

    it "shows module sharing menu items if direct_share is enabled" do
      @course.root_account.enable_feature!(:direct_share)
      view_context(@course, @teacher)
      assign(:modules, @course.context_modules.active)
      render 'context_modules/index'
      page = Nokogiri('<document>' + response.body + '</document>')
      expect(page.css(".module_copy_to").length).to eq 1
      expect(page.css(".module_send_to").length).to eq 1
      expect(page.css(".module_item_copy_to").length).to eq 1
      expect(page.css(".module_item_send_to").length).to eq 1
    end

    it "does not include item sharing menu items for things that can't stand alone" do
      @course.root_account.enable_feature!(:direct_share)
      @tag.destroy
      @module.add_item type: 'context_module_sub_header', title: 'blah'
      view_context(@course, @teacher)
      assign(:modules, @course.context_modules.active)
      render 'context_modules/index'
      page = Nokogiri('<document>' + response.body + '</document>')
      expect(page.css(".module_item_copy_to").length).to eq 0
      expect(page.css(".module_item_send_to").length).to eq 0
    end
  end
end
