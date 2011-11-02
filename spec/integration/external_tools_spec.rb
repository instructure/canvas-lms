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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "External Tools" do
  describe "Assignments" do
    before do
      course(:active_all => true)
      assignment_model(:course => @course, :submission_types => "external_tool", :points_possible => 25)
      @tool = @course.context_external_tools.create!(:shared_secret => 'test_secret', :consumer_key => 'test_key', :name => 'my grade passback test tool', :domain => 'example.com')
      @tag = @assignment.build_external_tool_tag(:url => "http://example.com/one")
      @tag.content_type = 'ContextExternalTool'
      @tag.save!
    end

    it "should include outcome service params when viewing as student" do
      student_in_course(:course => @course, :active_all => true)
      user_session(@user)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      response.should be_success
      doc = Nokogiri::HTML.parse(response.body)
      doc.at_css('form#tool_form input#lis_result_sourcedid')['value'].should == BasicLTI::BasicOutcomes.result_source_id(@tool, @course, @assignment, @user)
      doc.at_css('form#tool_form input#lis_outcome_service_url')['value'].should == lti_grade_passback_api_url(@course, @assignment, @user)
    end

    it "should not include outcome service params when viewing as teacher" do
      @course.enroll_teacher(user(:active_all => true))
      user_session(@user)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      response.should be_success
      doc = Nokogiri::HTML.parse(response.body)
      doc.at_css('form#tool_form input#lis_result_sourcedid').should be_nil
      doc.at_css('form#tool_form input#lis_outcome_service_url').should be_nil
    end

    it "should redirect if the tool can't be configured" do
      @tag.update_attribute(:url, "http://example.net")

      student_in_course(:active_all => true)
      user_session(@user)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      response.should redirect_to(course_url(@course))
      flash[:error].should be_present
    end
  end
end
