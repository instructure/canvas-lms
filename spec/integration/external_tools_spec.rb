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

require 'nokogiri'

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
      expect(response).to be_success
      doc = Nokogiri::HTML.parse(response.body)
      form = doc.at_css('form#tool_form')

      expect(form.at_css('input#launch_presentation_locale')['value']).to eq 'en'
      expect(form.at_css('input#oauth_callback')['value']).to eq 'about:blank'
      expect(form.at_css('input#oauth_signature_method')['value']).to eq 'HMAC-SHA1'
      expect(form.at_css('input#launch_presentation_return_url')['value']).to eq "http://www.example.com/courses/#{@course.id}/external_content/success/external_tool_redirect"
      expect(form.at_css('input#lti_message_type')['value']).to eq "basic-lti-launch-request"
      expect(form.at_css('input#lti_version')['value']).to eq "LTI-1p0"
      expect(form.at_css('input#oauth_version')['value']).to eq "1.0"
      expect(form.at_css('input#roles')['value']).to eq "Learner"
    end

    it "should include outcome service params when viewing as student" do
      student_in_course(:course => @course, :active_all => true)
      user_session(@user)
      Canvas::Security.stubs(:hmac_sha1).returns('some_sha')
      payload = [@tool.id, @course.id, @assignment.id, @user.id].join('-')

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(response).to be_success
      doc = Nokogiri::HTML.parse(response.body)

      expect(doc.at_css('form#tool_form input#lis_result_sourcedid')['value']).to eq "#{payload}-some_sha"
      expect(doc.at_css('form#tool_form input#lis_outcome_service_url')['value']).to eq lti_grade_passback_api_url(@tool)
      expect(doc.at_css('form#tool_form input#ext_ims_lis_basic_outcome_url')['value']).to eq blti_legacy_grade_passback_api_url(@tool)
    end

    it "should not include outcome service sourcedid when viewing as teacher" do
      @course.enroll_teacher(user(:active_all => true))
      user_session(@user)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(response).to be_success
      doc = Nokogiri::HTML.parse(response.body)
      expect(doc.at_css('form#tool_form input#lis_result_sourcedid')).to be_nil
      expect(doc.at_css('form#tool_form input#lis_outcome_service_url')).not_to be_nil
    end

    it "should include time zone in LTI paramaters if included in custom fields" do
      @tool.custom_fields = {
        "custom_time_zone" => "$Person.address.timezone",
      }
      @tool.save!
      student_in_course(:course => @course, :active_all => true)
      user_session(@user)

      account = @course.root_account
      account.default_time_zone = 'Alaska'
      account.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(response).to be_success
      doc = Nokogiri::HTML.parse(response.body)
      expect(doc.at_css('form#tool_form input#custom_time_zone')['value']).to eq "America/Juneau"

      @user.time_zone = "Hawaii"
      @user.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(response).to be_success
      doc = Nokogiri::HTML.parse(response.body)
      expect(doc.at_css('form#tool_form input#custom_time_zone')['value']).to eq "Pacific/Honolulu"
    end

    it "should redirect if the tool can't be configured" do
      @tag.update_attribute(:url, "http://example.net")

      student_in_course(:active_all => true)
      user_session(@user)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(response).to redirect_to(course_url(@course))
      expect(flash[:error]).to be_present
    end
    
    it "should render inline external tool links with a full return url" do
      student_in_course(:active_all => true)
      user_session(@user)
      get "/courses/#{@course.id}/external_tools/retrieve?url=#{CGI.escape(@tag.url)}"
      expect(response).to be_success
      doc = Nokogiri::HTML.parse(response.body)
      expect(doc.at_css('#tool_form')).not_to be_nil
      expect(doc.at_css("input[name='launch_presentation_return_url']")['value']).to match(/^http/)
    end
    
    it "should render user navigation tools with a full return url" do
      tool = @course.root_account.context_external_tools.build(:shared_secret => 'test_secret', :consumer_key => 'test_key', :name => 'my grade passback test tool', :domain => 'example.com', :privacy_level => 'public')
      tool.user_navigation = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      
      student_in_course(:active_all => true)
      user_session(@user)
      get "/users/#{@user.id}/external_tools/#{tool.id}"
      expect(response).to be_success
      doc = Nokogiri::HTML.parse(response.body)
      expect(doc.at_css('#tool_form')).not_to be_nil
      expect(doc.at_css("input[name='launch_presentation_return_url']")['value']).to match(/^http/)
    end
    
  end

  it "should highlight the navigation tab when using an external tool" do
    course_with_teacher_logged_in(:active_all => true)

    @tool = @course.context_external_tools.create!(:shared_secret => 'test_secret', :consumer_key => 'test_key', :name => 'my grade passback test tool', :domain => 'example.com')
    @tool.course_navigation = {:url => "http://www.example.com", :text => "Example URL"}
    @tool.save!

    get "/courses/#{@course.id}/external_tools/#{@tool.id}"
    expect(response).to be_success
    doc = Nokogiri::HTML.parse(response.body)
    tab = doc.at_css("a.#{@tool.asset_string}")
    expect(tab).not_to be_nil
    expect(tab['class'].split).to include("active")
  end

  it "should highlight the navigation tab when using an external tool" do
    course_with_teacher_logged_in(:active_all => true)

    @tool = @course.context_external_tools.create!(:shared_secret => 'test_secret', :consumer_key => 'test_key', :name => 'my grade passback test tool', :domain => 'example.com')
    @tool.course_navigation = {:url => "http://www.example.com", :text => "Example URL"}
    @tool.save!

    get "/courses/#{@course.id}/external_tools/#{@tool.id}"
    expect(response).to be_success
    doc = Nokogiri::HTML.parse(response.body)
    tab = doc.at_css("a.#{@tool.asset_string}")
    expect(tab).not_to be_nil
    expect(tab['class'].split).to include("active")
  end

  context 'global navigation' do
    before :once do
      Account.default.enable_feature!(:lor_for_account)
      @admin_tool = Account.default.context_external_tools.new(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @admin_tool.global_navigation = {:visibility => 'admins', :url => "http://www.example.com", :text => "Example URL"}
      @admin_tool.save!
      @member_tool = Account.default.context_external_tools.new(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @member_tool.global_navigation = {:url => "http://www.example.com", :text => "Example URL 2"}
      @member_tool.save!
    end

    it "should show the admin level global navigation menu items to teachers" do
      course_with_teacher_logged_in(:account => @account, :active_all => true)
      get "/courses"
      expect(response).to be_success
      doc = Nokogiri::HTML.parse(response.body)

      menu_link1 = doc.at_css("##{@admin_tool.asset_string}_menu_item a")
      expect(menu_link1).not_to be_nil
      expect(menu_link1['href']).to eq account_external_tool_path(Account.default, @admin_tool, :launch_type => 'global_navigation')
      expect(menu_link1.text).to match_ignoring_whitespace(@admin_tool.label_for(:global_navigation))

      menu_link2 = doc.at_css("##{@member_tool.asset_string}_menu_item a")
      expect(menu_link2).not_to be_nil
      expect(menu_link2['href']).to eq account_external_tool_path(Account.default, @member_tool, :launch_type => 'global_navigation')
      expect(menu_link2.text).to match_ignoring_whitespace(@member_tool.label_for(:global_navigation))
    end

    it "should only show the member level global navigation menu items to students" do
      course_with_student_logged_in(:account => @account, :active_all => true)
      get "/courses"
      expect(response).to be_success
      doc = Nokogiri::HTML.parse(response.body)

      menu_link1 = doc.at_css("##{@admin_tool.asset_string}_menu_item a")
      expect(menu_link1).to be_nil

      menu_link2 = doc.at_css("##{@member_tool.asset_string}_menu_item a")
      expect(menu_link2).not_to be_nil
      expect(menu_link2['href']).to eq account_external_tool_path(Account.default, @member_tool, :launch_type => 'global_navigation')
      expect(menu_link2.text).to match_ignoring_whitespace(@member_tool.label_for(:global_navigation))
    end
  end
end
