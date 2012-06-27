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

    it "should generate valid LTI parameters" do
      student_in_course(:course => @course, :active_all => true)
      user_session(@user)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      response.should be_success
      doc = Nokogiri::HTML.parse(response.body)
      form = doc.at_css('form#tool_form')

      form.at_css('input#launch_presentation_locale')['value'].should == 'en'
      form.at_css('input#oauth_callback')['value'].should == 'about:blank'
      form.at_css('input#oauth_signature_method')['value'].should == 'HMAC-SHA1'
      form.at_css('input#launch_presentation_return_url')['value'].should == "http://www.example.com/courses/#{@course.id}/external_tools/#{@tool.id}/finished"
      form.at_css('input#lti_message_type')['value'].should == "basic-lti-launch-request"
      form.at_css('input#lti_version')['value'].should == "LTI-1p0"
      form.at_css('input#oauth_version')['value'].should == "1.0"
      form.at_css('input#roles')['value'].should == "Learner"
    end

    it "should include outcome service params when viewing as student" do
      student_in_course(:course => @course, :active_all => true)
      user_session(@user)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      response.should be_success
      doc = Nokogiri::HTML.parse(response.body)
      doc.at_css('form#tool_form input#lis_result_sourcedid')['value'].should == BasicLTI::BasicOutcomes.encode_source_id(@tool, @course, @assignment, @user)
      doc.at_css('form#tool_form input#lis_outcome_service_url')['value'].should == lti_grade_passback_api_url(@tool)
      doc.at_css('form#tool_form input#ext_ims_lis_basic_outcome_url')['value'].should == blti_legacy_grade_passback_api_url(@tool)
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
    
    it "should render inline external tool links with a full return url" do
      student_in_course(:active_all => true)
      user_session(@user)
      get "/courses/#{@course.id}/external_tools/retrieve?url=#{CGI.escape(@tag.url)}"
      response.should be_success
      doc = Nokogiri::HTML.parse(response.body)
      doc.at_css('#tool_form').should_not be_nil
      doc.at_css("input[name='launch_presentation_return_url']")['value'].should match(/^http/)
    end
    
    it "should render user navigation tools with a full return url" do
      tool = @course.root_account.context_external_tools.build(:shared_secret => 'test_secret', :consumer_key => 'test_key', :name => 'my grade passback test tool', :domain => 'example.com', :privacy_level => 'public')
      tool.settings[:user_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      
      student_in_course(:active_all => true)
      user_session(@user)
      get "/users/#{@user.id}/external_tools/#{tool.id}"
      response.should be_success
      doc = Nokogiri::HTML.parse(response.body)
      doc.at_css('#tool_form').should_not be_nil
      doc.at_css("input[name='launch_presentation_return_url']")['value'].should match(/^http/)
    end
    
  end
end
