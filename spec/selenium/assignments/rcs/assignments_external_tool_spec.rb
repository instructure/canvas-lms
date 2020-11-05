# frozen_string_literal: true

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

require_relative '../../common'

describe "external tool assignments" do
  include_context "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    stub_rcs_config
    @t1 = factory_with_protected_attributes(@course.context_external_tools, :url => "http://www.example.com/tool1", :shared_secret => 'test123', :consumer_key => 'test123', :name => 'tool 1')
    @t2 = factory_with_protected_attributes(@course.context_external_tools, :url => "http://www.example.com/tool2", :shared_secret => 'test123', :consumer_key => 'test123', :name => 'tool 2')
  end

  it "should allow creating through the 'More Options' link", priority: "2", test_id: 209973 do
    get "/courses/#{@course.id}/assignments"

    #create assignment
    f('.add_assignment').click
    expect_new_page_load { f('.more_options').click }

    f('#assignment_name').send_keys('test1')
    click_option('#assignment_submission_type', 'External Tool')
    f('#assignment_external_tool_tag_attributes_url_find').click

    fj('#context_external_tools_select td .tools .tool:first-child:visible').click
    wait_for_ajaximations
    expect(f('#context_external_tools_select input#external_tool_create_url')).to have_attribute('value', @t1.url)

    ff('#context_external_tools_select td .tools .tool')[1].click
    expect(f('#context_external_tools_select input#external_tool_create_url')).to have_attribute('value', @t2.url)

    f('.add_item_button.ui-button').click

    expect(f('#assignment_external_tool_tag_attributes_url')).to have_attribute('value', @t2.url)
    f("#edit_assignment_form button[type='submit']").click

    keep_trying_until do # timing issues require waiting
      expect(@course.assignments.reload.last).to be_present
    end

    a = @course.assignments.reload.last
    expect(a).to be_present
    expect(a.submission_types).to eq 'external_tool'
    expect(a.external_tool_tag).to be_present
    expect(a.external_tool_tag.url).to eq @t2.url
    expect(a.external_tool_tag.new_tab).to be_falsey
  end

end
