#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../helpers/context_modules_common'

describe "master courses - module locking" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon

  before :once do
    Account.default.enable_feature!(:master_courses)

    @course = course_factory(:active_all => true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@course)

    @assmt = @course.assignments.create!(:title => "assmt blah", :description => "bloo")
    @assmt_tag = @template.create_content_tag_for!(@assmt)

    @page = @course.wiki.wiki_pages.create!(:title => "page blah", :body => "bloo")
    @page_tag = @template.create_content_tag_for!(@page, :restrictions => {:all => true})

    @topic = @course.discussion_topics.create!(:title => "topic blah", :message => "bloo")
    # note the lack of a content tag

    @mod = @course.context_modules.create!(:name => "modle")
    @assmt_mod_tag = @mod.add_item(:id => @assmt.id, :type => "assignment")
    @page_mod_tag  = @mod.add_item(:id => @page.id, :type => "wiki_page")
    @topic_mod_tag = @mod.add_item(:id => @topic.id, :type => "discussion_topic")
  end

  before :each do
    user_session(@teacher)
  end

  it "should show all the icons on the modules index" do
    get "/courses/#{@course.id}/modules"

    expect(f("#context_module_item_#{@assmt_mod_tag.id} .lock-icon")).to contain_css('.icon-blueprint')
    expect(f("#context_module_item_#{@page_mod_tag.id} .lock-icon")).to contain_css('.icon-blueprint-lock')
    expect(f("#context_module_item_#{@topic_mod_tag.id} .lock-icon")).to contain_css('.icon-blueprint') # should still have icon even without tag
  end
end
