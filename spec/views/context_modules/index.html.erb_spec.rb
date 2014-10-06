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

describe "/context_modules/index" do
  before :each do
    assigns[:body_classes] = []
    assigns[:menu_tools] = Hash.new([])
    assigns[:collapsed_modules] = []
  end

  it "should render" do
    course
    view_context(@course, @user)
    assigns[:modules] = @course.context_modules.active
    render 'context_modules/index'
    response.should_not be_nil
  end

  it "should show content_tags" do
    course
    context_module = @course.context_modules.create!
    content_tag = context_module.add_item :type => 'context_module_sub_header'
    content_tag.publish! if content_tag.unpublished?
    view_context(@course, @user)
    assigns[:modules] = @course.context_modules.active
    render 'context_modules/index'
    response.should_not be_nil
    page = Nokogiri('<document>' + response.body + '</document>')
    page.css("#context_module_item_#{content_tag.id}").length.should == 1
  end

  it "should show unpublished content_tags" do
    course_with_teacher(:active_all => true)
    wiki_page = wiki_page_model(:course => @course)
    wiki_page.workflow_state = 'unpublished'
    wiki_page.save!

    context_module = @course.context_modules.create!
    content_tag = context_module.add_item(:type => 'wiki_page', :id => wiki_page.id)
    content_tag.workflow_state.should == 'unpublished'

    view_context(@course, @user)
    assigns[:modules] = @course.context_modules.active
    render 'context_modules/index'

    response.should_not be_nil
    page = Nokogiri('<document>' + response.body + '</document>')
    page.css("#context_module_item_#{content_tag.id}").length.should == 1
  end

  it "should not show deleted content_tags" do
    course
    context_module = @course.context_modules.create!
    content_tag = context_module.add_item :type => 'context_module_sub_header'
    content_tag.destroy
    view_context(@course, @user)
    assigns[:modules] = @course.context_modules.active
    render 'context_modules/index'
    response.should_not be_nil
    page = Nokogiri('<document>' + response.body + '</document>')
    page.css("#context_module_item_#{content_tag.id}").length.should == 0
  end
end
