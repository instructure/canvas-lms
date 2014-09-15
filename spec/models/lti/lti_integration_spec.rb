#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe "LTI integration tests" do
  let(:canvas_tool) {
    ContextExternalTool.new.tap do |canvas_tool|
      canvas_tool.context = root_account
      canvas_tool.url = 'http://launch/url'
      canvas_tool.name = 'tool'
      canvas_tool.consumer_key = '12345'
      canvas_tool.shared_secret = 'secret'
      canvas_tool.privacy_level = 'public'
      canvas_tool.settings[:custom_fields] = {
          'custom_variable_canvas_api_domain' => '$Canvas.api.domain',
          'custom_variable_canvas_assignment_id' => '$Canvas.assignment.id',
          'custom_variable_canvas_assignment_points_possible' => '$Canvas.assignment.pointsPossible',
          'custom_variable_canvas_assignment_title' => '$Canvas.assignment.title',
          'custom_variable_canvas_course_id' => '$Canvas.course.id',
          'custom_variable_canvas_enrollment_enrollment_state' => '$Canvas.enrollment.enrollmentState',
          'custom_variable_canvas_membership_concluded_roles' => '$Canvas.membership.concludedRoles',
          'custom_variable_canvas_user_id' => '$Canvas.user.id',
          'custom_variable_canvas_user_login_id' => '$Canvas.user.loginId',
          'custom_variable_person_address_timezone' => '$Person.address.timezone',
          'custom_variable_person_name_family' => '$Person.name.family',
          'custom_variable_person_name_full' => '$Person.name.full',
          'custom_variable_person_name_given' => '$Person.name.given',
      }
    end
  }

  let_once(:canvas_user) { user(name: 'Shorty McLongishname') }

  let_once(:canvas_course) {
    course(active_course: true, course_name: 'my course').tap do |course|
      course.course_code = 'abc'
      course.sis_source_id = 'course_sis_id'
      course.root_account = root_account
      course.save!
    end
  }

  let_once(:root_account) {
    Account.new.tap do |account|
      account.name = 'root_account'
      account.save!
    end
  }

  let(:return_url) { '/return/url' }

  it "generates the correct post payload" do
    canvas_user.email = 'user@email.com'

    sub_account = Account.create!
    sub_account.root_account = root_account
    sub_account.save!
    pseudonym = pseudonym(canvas_user, account: root_account, username: 'login_id')

    teacher_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)
    course_with_ta(user: canvas_user, course: canvas_course, active_enrollment: true)
    account_admin_user(user: canvas_user, account: sub_account)

    student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true).conclude

    pseudonym.sis_user_id = 'sis id!'
    pseudonym.save!

    Time.zone.tzinfo.stubs(:name).returns('my/zone')

    adapter = Lti::LtiOutboundAdapter.new(canvas_tool, canvas_user, canvas_course)
    adapter.prepare_tool_launch(return_url, custom_substitutions: {'$Canvas.api.domain' => root_account.domain})
    post_payload = adapter.generate_post_payload

    expected_tool_settings = {
        'oauth_consumer_key' => canvas_tool.consumer_key,
        'oauth_version' => '1.0',
        'context_id' => canvas_tool.opaque_identifier_for(canvas_course),
        'context_label' => canvas_course.course_code,
        'context_title' => canvas_course.name,
        'custom_canvas_enrollment_state' => 'active',
        'custom_canvas_api_domain' => root_account.domain,
        'custom_canvas_course_id' => canvas_course.id.to_s,
        'custom_canvas_user_id' => canvas_user.id.to_s,
        'custom_canvas_user_login_id' => pseudonym.unique_id,
        'custom_variable_canvas_api_domain' => root_account.domain,
        'custom_variable_canvas_assignment_id' => '$Canvas.assignment.id',
        'custom_variable_canvas_assignment_points_possible' => '$Canvas.assignment.pointsPossible',
        'custom_variable_canvas_assignment_title' => '$Canvas.assignment.title',
        'custom_variable_canvas_course_id' => canvas_course.id.to_s,
        'custom_variable_canvas_enrollment_enrollment_state' => 'active',
        'custom_variable_canvas_membership_concluded_roles' => 'Learner',
        'custom_variable_canvas_user_id' => canvas_user.id.to_s,
        'custom_variable_canvas_user_login_id' => pseudonym.unique_id,
        'custom_variable_person_address_timezone' => 'my/zone',
        'custom_variable_person_name_family' => canvas_user.last_name,
        'custom_variable_person_name_full' => canvas_user.name,
        'custom_variable_person_name_given' => canvas_user.first_name,
        'launch_presentation_document_target' => 'iframe',
        'launch_presentation_locale' => 'en',
        'launch_presentation_return_url' => '/return/url',
        'lis_course_offering_sourcedid' => canvas_course.sis_source_id,
        'lis_person_contact_email_primary' => canvas_user.email,
        'lis_person_name_family' => canvas_user.last_name,
        'lis_person_name_full' => canvas_user.name,
        'lis_person_name_given' => canvas_user.first_name,
        'lis_person_sourcedid' => pseudonym.sis_user_id,
        'lti_message_type' => 'basic-lti-launch-request',
        'lti_version' => 'LTI-1p0',
        'oauth_callback' => 'about:blank',
        'resource_link_id' => canvas_tool.opaque_identifier_for(canvas_course),
        'resource_link_title' => canvas_tool.name,
        'roles' => 'Instructor,urn:lti:role:ims/lis/TeachingAssistant',
        'tool_consumer_info_product_family_code' => 'canvas',
        'tool_consumer_info_version' => 'cloud',
        'tool_consumer_instance_contact_email' => HostUrl.outgoing_email_address,
        'tool_consumer_instance_guid' => root_account.lti_guid,
        'tool_consumer_instance_name' => root_account.name,
        'user_id' => canvas_tool.opaque_identifier_for(canvas_user),
        'user_image' => canvas_user.avatar_url,
    }

    post_payload.should include(expected_tool_settings)
  end

  describe "legacy integration tests" do
    before :once do
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com',
                                                     :consumer_key => '12345', :shared_secret => 'secret', :name => 'tool')
    end

    it "should generate correct parameters" do
      @user = user_with_managed_pseudonym(:sis_user_id => 'testfun', :name => "A Name")
      course_with_teacher_logged_in(:active_all => true, :user => @user, :account => @account)
      @course.sis_source_id = 'coursesis'
      @course.save!
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :name => 'tool', :privacy_level => 'public')
      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.google.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash = adapter.generate_post_payload
      hash['lti_message_type'].should == 'basic-lti-launch-request'
      hash['lti_version'].should == 'LTI-1p0'
      hash['resource_link_id'].should == '123456'
      hash['resource_link_title'].should == @tool.name
      hash['user_id'].should == @tool.opaque_identifier_for(@user)
      hash['user_image'].should == @user.avatar_url
      hash['roles'].should == 'Instructor'
      hash['context_id'].should == @tool.opaque_identifier_for(@course)
      hash['context_title'].should == @course.name
      hash['context_label'].should == @course.course_code
      hash['custom_canvas_user_id'].should == @user.id.to_s
      hash['custom_canvas_user_login_id'].should == @user.pseudonyms.first.unique_id
      hash['custom_canvas_course_id'].should == @course.id.to_s
      hash['custom_canvas_api_domain'].should == '$Canvas.api.domain'
      hash['lis_course_offering_sourcedid'].should == 'coursesis'
      hash['lis_person_contact_email_primary'].should == 'nobody@example.com'
      hash['lis_person_name_full'].should == 'A Name'
      hash['lis_person_name_family'].should == 'Name'
      hash['lis_person_name_given'].should == 'A'
      hash['lis_person_sourcedid'].should == 'testfun'
      hash['launch_presentation_locale'].should == I18n.default_locale.to_s
      hash['launch_presentation_document_target'].should == 'iframe'
      hash['launch_presentation_return_url'].should == 'http://www.google.com'
      hash['tool_consumer_instance_guid'].should == @course.root_account.lti_guid
      hash['tool_consumer_instance_name'].should == @course.root_account.name
      hash['tool_consumer_instance_contact_email'].should == HostUrl.outgoing_email_address
      hash['tool_consumer_info_product_family_code'].should == 'canvas'
      hash['tool_consumer_info_version'].should == 'cloud'
      hash['oauth_callback'].should == 'about:blank'
    end

    it "should set the locale if I18n.localizer exists" do
      I18n.localizer = lambda { :es }

      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.google.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash = adapter.generate_post_payload
      hash['launch_presentation_locale'].should == 'es'
      I18n.localizer = lambda { :en }
    end

    it "should add account info in launch data for account navigation" do
      @user = user_with_managed_pseudonym
      sub_account = Account.create(:parent_account => @account)
      sub_account.sis_source_id = 'accountsis'
      sub_account.save!
      canvas_tool.context = sub_account

      adapter = Lti::LtiOutboundAdapter.new(canvas_tool, @user, sub_account)
      adapter.prepare_tool_launch('http://www.google.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash = adapter.generate_post_payload

      hash['custom_canvas_account_id'].should == sub_account.id.to_s
      hash['custom_canvas_account_sis_id'].should == 'accountsis'
      hash['custom_canvas_user_login_id'].should == @user.pseudonyms.first.unique_id
      hash['custom_variable_canvas_membership_concluded_roles'].should == LtiOutbound::LTIRole::NONE
    end

    it "should add account and user info in launch data for user profile launch" do
      @user = user_with_managed_pseudonym(:sis_user_id => 'testfun')
      sub_account = Account.create(:parent_account => @account)
      sub_account.sis_source_id = 'accountsis'
      sub_account.save!
      @tool = sub_account.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :name => 'tool', :privacy_level => 'public')

      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @user)
      adapter.prepare_tool_launch('http://www.google.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash = adapter.generate_post_payload

      hash['custom_canvas_account_id'] = sub_account.id.to_s
      hash['custom_canvas_account_sis_id'] = 'accountsis'
      hash['lis_person_sourcedid'].should == 'testfun'
      hash['custom_canvas_user_id'].should == @user.id.to_s
      hash['tool_consumer_instance_guid'].should == sub_account.root_account.lti_guid
    end

    it "should include URI query parameters" do
      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.google.com', launch_url: 'http://www.yahoo.com?a=1&b=2', link_code: '123456')
      hash = adapter.generate_post_payload

      hash['a'].should == '1'
      hash['b'].should == '2'
    end

    it "should not allow overwriting other parameters from the URI query string" do
      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.google.com', launch_url: 'http://www.yahoo.com?user_id=123&oauth_callback=1234', link_code: '123456')
      hash = adapter.generate_post_payload

      hash['user_id'].should == @tool.opaque_identifier_for(@user)
      hash['oauth_callback'].should == 'about:blank'
    end

    it "should include custom fields" do
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :custom_fields => {'custom_bob' => 'bob', 'custom_fred' => 'fred', 'john' => 'john', '@$TAA$#$#' => 123}, :name => 'tool')

      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.yahoo.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash = adapter.generate_post_payload

      hash.keys.select{|k| k.match(/^custom_/) }.sort.should == ['custom___taa____', 'custom_bob', 'custom_canvas_enrollment_state', 'custom_fred', 'custom_john']
      hash['custom_bob'].should eql('bob')
      hash['custom_fred'].should eql('fred')
      hash['custom_john'].should eql('john')
      hash['custom___taa____'].should eql('123')
      hash['@$TAA$#$#'].should be_nil
      hash['john'].should be_nil
    end

    it "should not include name and email if anonymous" do
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :privacy_level => 'anonymous', :name => 'tool')
      @tool.include_name?.should eql(false)
      @tool.include_email?.should eql(false)

      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.yahoo.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash = adapter.generate_post_payload

      hash['lis_person_name_given'].should be_nil
      hash['lis_person_name_family'].should be_nil
      hash['lis_person_name_full'].should be_nil
      hash['lis_person_contact_email_primary'].should be_nil
    end

    it "should include name if name_only" do
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :privacy_level => 'name_only', :name => 'tool')
      @tool.include_name?.should eql(true)
      @tool.include_email?.should eql(false)

      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.yahoo.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash = adapter.generate_post_payload

      hash['lis_person_name_given'].should == 'User'
      hash['lis_person_name_family'].should == nil
      hash['lis_person_name_full'].should == @user.name
      hash['lis_person_contact_email_primary'].should be_nil
    end

    it "should include email if email_only" do
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :privacy_level => 'email_only', :name => 'tool')
      @tool.include_name?.should eql(false)
      @tool.include_email?.should eql(true)

      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.yahoo.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash = adapter.generate_post_payload

      hash['lis_person_name_given'].should == nil
      hash['lis_person_name_family'].should == nil
      hash['lis_person_name_full'].should == nil
      hash['lis_person_contact_email_primary'] = @user.email
    end

    it "should include email if public" do
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :privacy_level => 'public', :name => 'tool')
      @tool.include_name?.should eql(true)
      @tool.include_email?.should eql(true)

      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.yahoo.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash = adapter.generate_post_payload

      hash['lis_person_name_given'].should == 'User'
      hash['lis_person_name_family'].should == nil
      hash['lis_person_name_full'].should == @user.name
      hash['lis_person_contact_email_primary'] = @user.email
    end

    it "should provide a custom_canvas_user_login_id without an sis id" do
      user = user_with_pseudonym(:name => "A Name")
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :name => 'tool', :privacy_level => 'public')

      adapter = Lti::LtiOutboundAdapter.new(@tool, user, @course)
      adapter.prepare_tool_launch('http://www.google.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash = adapter.generate_post_payload

      hash['custom_canvas_user_login_id'].should == user.pseudonyms.first.unique_id
    end

    it "should include text if set" do
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :privacy_level => 'public', :name => 'tool')

      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      html = "<p>this has <a href='#'>a link</a></p>"
      adapter.prepare_tool_launch('http://www.yahoo.com', launch_url: 'http://www.yahoo.com', link_code: '123456', selected_html: html)

      hash = adapter.generate_post_payload
      hash['text'].should == CGI::escape(html)
    end
  end

  context "outcome launch" do
    def tool_setup(for_student=true)
      if for_student
        course_with_student(:active_all => true)
      else
        course_with_teacher(:active_all => true)
      end

      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :privacy_level => 'public', :name => 'tool')
      assignment_model(:submission_types => "external_tool", :course => @course, :points_possible => 5, :title => "an assignment")

      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.yahoo.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      adapter.generate_post_payload_for_assignment(@assignment, "/my/test/url", "/my/other/test/url")
    end

    it "should include assignment outcome service params for student" do
      Canvas::Security.stubs(:hmac_sha1).returns('some_sha')
      hash = tool_setup

      payload = [@tool.id, @course.id, @assignment.id, @user.id].join('-')
      hash['lis_result_sourcedid'].should == "#{payload}-some_sha"
      hash['lis_outcome_service_url'].should == "/my/test/url"
      hash['ext_ims_lis_basic_outcome_url'].should == "/my/other/test/url"
      hash['ext_outcome_data_values_accepted'].should == 'url,text'
      hash['custom_canvas_assignment_title'].should == @assignment.title
      hash['custom_canvas_assignment_points_possible'].should == @assignment.points_possible.to_s
      hash['custom_canvas_assignment_id'].should == @assignment.id.to_s
    end

    it "should include assignment outcome service params for teacher" do
      hash = tool_setup(false)
      hash['lis_result_sourcedid'].should be_nil
      hash['lis_outcome_service_url'].should == "/my/test/url"
      hash['ext_ims_lis_basic_outcome_url'].should == "/my/other/test/url"
      hash['ext_outcome_data_values_accepted'].should == 'url,text'
      hash['custom_canvas_assignment_title'].should == @assignment.title
      hash['custom_canvas_assignment_points_possible'].should == @assignment.points_possible.to_s
    end
  end

  it "gets the correct width and height based on resource type" do
    @user = user_with_managed_pseudonym(:sis_user_id => 'testfun', :name => "A Name")
    course_with_teacher_logged_in(:active_all => true, :user => @user, :account => @account)
    @course.sis_source_id = 'coursesis'
    @course.save!
    @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :name => 'tool', :privacy_level => 'public')
    @tool.editor_button = { :selection_width => 1000, :selection_height => 300, :icon_url => 'www.example.com/icon', :url => 'www.example.com' }
    @tool.save!

    adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
    adapter.prepare_tool_launch('http://www.google.com', launch_url: 'http://www.yahoo.com', link_code: '123456', resource_type: 'editor_button')
    hash = adapter.generate_post_payload

    hash['launch_presentation_width'].should == '1000'
    hash['launch_presentation_height'].should == '300'
  end

  context "sharding" do
    specs_require_sharding

    # TODO: Replace this once we have LTIInbound
    it "should roundtrip source ids from mixed shards", pending: true do
      @shard1.activate do
        @account = Account.create!
        course_with_teacher(:active_all => true, :account => @account)
        @tool = @course.context_external_tools.create!(:domain => 'example.com', :consumer_key => '12345', :shared_secret => 'secret', :privacy_level => 'anonymous', :name => 'tool')
        assignment_model(:submission_types => "external_tool", :course => @course)
        tag = @assignment.build_external_tool_tag(:url => "http://example.com/one")
        tag.content_type = 'ContextExternalTool'
        tag.save!
      end
      user
      @course.enroll_student(@user)

      source_id = @tool.shard.activate do
        payload = [@tool.id, @course.id, @assignment.id, @user.id].join('-')
        "#{payload}-#{Canvas::Security.hmac_sha1(payload, @tool.shard.settings[:encryption_key])}"
      end

      course, assignment, user = BasicLTI::BasicOutcomes.decode_source_id(@tool, source_id)
      course.should == @course
      assignment.should == @assignment
      user.should == @user
    end

    it "should provide different user ids for users with the same local id from different shards" do
      user1 = @shard1.activate do
        user_with_managed_pseudonym(:sis_user_id => 'testfun', :name => "A Name")
      end
      user2 = @shard2.activate do
        user_with_managed_pseudonym(:sis_user_id => 'testfun', :name => "A Name", :id => user1.id)
      end
      course_with_teacher_logged_in(:active_all => true, :user => user1, :account => @account)
      @course.sis_source_id = 'coursesis'
      @course.save!
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :name => 'tool', :privacy_level => 'public')

      adapter = Lti::LtiOutboundAdapter.new(@tool, user1, @course)
      adapter.prepare_tool_launch('http://www.google.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash1 = adapter.generate_post_payload

      adapter2 = Lti::LtiOutboundAdapter.new(@tool, user2, @course)
      adapter2.prepare_tool_launch('http://www.google.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash2 = adapter2.generate_post_payload

      hash1['user_id'].should_not == hash2['user_id']
    end
  end
end
