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

    expect(post_payload['oauth_consumer_key']).to eq canvas_tool.consumer_key
    expect(post_payload['oauth_version']).to eq '1.0'
    expect(post_payload['context_id']).to eq canvas_tool.opaque_identifier_for(canvas_course)
    expect(post_payload['context_label']).to eq canvas_course.course_code
    expect(post_payload['context_title']).to eq canvas_course.name
    expect(post_payload['custom_canvas_enrollment_state']).to eq '$Canvas.enrollment.enrollmentState'
    expect(post_payload['custom_canvas_api_domain']).to eq root_account.domain
    expect(post_payload['custom_canvas_course_id']).to eq canvas_course.id.to_s
    expect(post_payload['custom_canvas_user_id']).to eq '$Canvas.user.id'
    expect(post_payload['custom_canvas_user_login_id']).to eq '$Canvas.user.loginId'
    expect(post_payload['custom_variable_canvas_api_domain']).to eq root_account.domain
    expect(post_payload['custom_variable_canvas_assignment_id']).to eq '$Canvas.assignment.id'
    expect(post_payload['custom_variable_canvas_assignment_points_possible']).to eq '$Canvas.assignment.pointsPossible'
    expect(post_payload['custom_variable_canvas_assignment_title']).to eq '$Canvas.assignment.title'
    expect(post_payload['custom_variable_canvas_course_id']).to eq canvas_course.id.to_s
    expect(post_payload['custom_variable_canvas_enrollment_enrollment_state']).to eq '$Canvas.enrollment.enrollmentState'
    expect(post_payload['custom_variable_canvas_membership_concluded_roles']).to eq '$Canvas.membership.concludedRoles'
    expect(post_payload['custom_variable_canvas_user_id']).to eq '$Canvas.user.id'
    expect(post_payload['custom_variable_canvas_user_login_id']).to eq '$Canvas.user.loginId'
    expect(post_payload['custom_variable_person_address_timezone']).to eq 'my/zone'
    expect(post_payload['custom_variable_person_name_family']).to eq canvas_user.last_name
    expect(post_payload['custom_variable_person_name_full']).to eq canvas_user.name
    expect(post_payload['custom_variable_person_name_given']).to eq canvas_user.first_name
    expect(post_payload['launch_presentation_document_target']).to eq 'iframe'
    expect(post_payload['launch_presentation_locale']).to eq 'en'
    expect(post_payload['launch_presentation_return_url']).to eq '/return/url'
    expect(post_payload['lis_course_offering_sourcedid']).to eq canvas_course.sis_source_id
    expect(post_payload['lis_person_contact_email_primary']).to eq canvas_user.email
    expect(post_payload['lis_person_name_family']).to eq canvas_user.last_name
    expect(post_payload['lis_person_name_full']).to eq canvas_user.name
    expect(post_payload['lis_person_name_given']).to eq canvas_user.first_name
    expect(post_payload['lis_person_sourcedid']).to eq pseudonym.sis_user_id
    expect(post_payload['lti_message_type']).to eq 'basic-lti-launch-request'
    expect(post_payload['lti_version']).to eq 'LTI-1p0'
    expect(post_payload['oauth_callback']).to eq 'about:blank'
    expect(post_payload['resource_link_id']).to eq canvas_tool.opaque_identifier_for(canvas_course)
    expect(post_payload['resource_link_title']).to eq canvas_tool.name
    expect(post_payload['roles']).to eq 'urn:lti:role:ims/lis/TeachingAssistant,Instructor'
    expect(post_payload['ext_roles']).to eq "urn:lti:instrole:ims/lis/Administrator,urn:lti:instrole:ims/lis/Instructor,urn:lti:role:ims/lis/Instructor,urn:lti:role:ims/lis/TeachingAssistant,urn:lti:sysrole:ims/lis/User"
    expect(post_payload['tool_consumer_info_product_family_code']).to eq 'canvas'
    expect(post_payload['tool_consumer_info_version']).to eq 'cloud'
    expect(post_payload['tool_consumer_instance_contact_email']).to eq HostUrl.outgoing_email_address
    expect(post_payload['tool_consumer_instance_guid']).to eq root_account.lti_guid
    expect(post_payload['tool_consumer_instance_name']).to eq root_account.name
    expect(post_payload['user_id']).to eq canvas_tool.opaque_identifier_for(canvas_user)
    expect(post_payload['user_image']).to eq canvas_user.avatar_url
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
      expect(hash['lti_message_type']).to eq 'basic-lti-launch-request'
      expect(hash['lti_version']).to eq 'LTI-1p0'
      expect(hash['resource_link_id']).to eq '123456'
      expect(hash['resource_link_title']).to eq @tool.name
      expect(hash['user_id']).to eq @tool.opaque_identifier_for(@user)
      expect(hash['user_image']).to eq @user.avatar_url
      expect(hash['roles']).to eq 'Instructor'
      expect(hash['context_id']).to eq @tool.opaque_identifier_for(@course)
      expect(hash['context_title']).to eq @course.name
      expect(hash['context_label']).to eq @course.course_code
      expect(hash['custom_canvas_user_id']).to eq '$Canvas.user.id'
      expect(hash['custom_canvas_user_login_id']).to eq '$Canvas.user.loginId'
      expect(hash['custom_canvas_course_id']).to eq @course.id.to_s
      expect(hash['custom_canvas_api_domain']).to eq '$Canvas.api.domain'
      expect(hash['lis_course_offering_sourcedid']).to eq 'coursesis'
      expect(hash['lis_person_contact_email_primary']).to eq 'nobody@example.com'
      expect(hash['lis_person_name_full']).to eq 'A Name'
      expect(hash['lis_person_name_family']).to eq 'Name'
      expect(hash['lis_person_name_given']).to eq 'A'
      expect(hash['lis_person_sourcedid']).to eq 'testfun'
      expect(hash['launch_presentation_locale']).to eq I18n.default_locale.to_s
      expect(hash['launch_presentation_document_target']).to eq 'iframe'
      expect(hash['launch_presentation_return_url']).to eq 'http://www.google.com'
      expect(hash['tool_consumer_instance_guid']).to eq @course.root_account.lti_guid
      expect(hash['tool_consumer_instance_name']).to eq @course.root_account.name
      expect(hash['tool_consumer_instance_contact_email']).to eq HostUrl.outgoing_email_address
      expect(hash['tool_consumer_info_product_family_code']).to eq 'canvas'
      expect(hash['tool_consumer_info_version']).to eq 'cloud'
      expect(hash['oauth_callback']).to eq 'about:blank'
    end

    it "should set the locale if I18n.localizer exists" do
      I18n.localizer = lambda { :es }

      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.google.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash = adapter.generate_post_payload
      expect(hash['launch_presentation_locale']).to eq 'es'
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

      expect(hash['custom_canvas_account_id']).to eq sub_account.id.to_s
      expect(hash['custom_canvas_account_sis_id']).to eq 'accountsis'
      expect(hash['custom_canvas_user_login_id']).to eq '$Canvas.user.loginId'
      expect(hash['custom_variable_canvas_membership_concluded_roles']).to eq "$Canvas.membership.concludedRoles"
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
      expect(hash['lis_person_sourcedid']).to eq 'testfun'
      expect(hash['custom_canvas_user_id']).to eq '$Canvas.user.id'
      expect(hash['tool_consumer_instance_guid']).to eq sub_account.root_account.lti_guid
    end

    it "should include URI query parameters" do
      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.google.com', launch_url: 'http://www.yahoo.com?a=1&b=2', link_code: '123456')
      hash = adapter.generate_post_payload

      expect(hash['a']).to eq '1'
      expect(hash['b']).to eq '2'
    end

    it "should not allow overwriting other parameters from the URI query string" do
      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.google.com', launch_url: 'http://www.yahoo.com?user_id=123&oauth_callback=1234', link_code: '123456')
      hash = adapter.generate_post_payload

      expect(hash['user_id']).to eq @tool.opaque_identifier_for(@user)
      expect(hash['oauth_callback']).to eq 'about:blank'
    end

    it "should include custom fields" do
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :custom_fields => {'custom_bob' => 'bob', 'custom_fred' => 'fred', 'john' => 'john', '@$TAA$#$#' => 123}, :name => 'tool')

      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.yahoo.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash = adapter.generate_post_payload

      expect(hash.keys.select{|k| k.match(/^custom_/) }.sort).to eq ['custom___taa____', 'custom_bob', 'custom_canvas_enrollment_state', 'custom_fred', 'custom_john']
      expect(hash['custom_bob']).to eql('bob')
      expect(hash['custom_fred']).to eql('fred')
      expect(hash['custom_john']).to eql('john')
      expect(hash['custom___taa____']).to eql('123')
      expect(hash['@$TAA$#$#']).to be_nil
      expect(hash['john']).to be_nil
    end

    it "should not include name and email if anonymous" do
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :privacy_level => 'anonymous', :name => 'tool')
      expect(@tool.include_name?).to eql(false)
      expect(@tool.include_email?).to eql(false)

      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.yahoo.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash = adapter.generate_post_payload

      expect(hash['lis_person_name_given']).to be_nil
      expect(hash['lis_person_name_family']).to be_nil
      expect(hash['lis_person_name_full']).to be_nil
      expect(hash['lis_person_contact_email_primary']).to be_nil
    end

    it "should include name if name_only" do
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :privacy_level => 'name_only', :name => 'tool')
      expect(@tool.include_name?).to eql(true)
      expect(@tool.include_email?).to eql(false)

      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.yahoo.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash = adapter.generate_post_payload

      expect(hash['lis_person_name_given']).to eq 'User'
      expect(hash['lis_person_name_family']).to eq nil
      expect(hash['lis_person_name_full']).to eq @user.name
      expect(hash['lis_person_contact_email_primary']).to be_nil
    end

    it "should include email if email_only" do
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :privacy_level => 'email_only', :name => 'tool')
      expect(@tool.include_name?).to eql(false)
      expect(@tool.include_email?).to eql(true)

      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.yahoo.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash = adapter.generate_post_payload

      expect(hash['lis_person_name_given']).to eq nil
      expect(hash['lis_person_name_family']).to eq nil
      expect(hash['lis_person_name_full']).to eq nil
      hash['lis_person_contact_email_primary'] = @user.email
    end

    it "should include email if public" do
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :privacy_level => 'public', :name => 'tool')
      expect(@tool.include_name?).to eql(true)
      expect(@tool.include_email?).to eql(true)

      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      adapter.prepare_tool_launch('http://www.yahoo.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash = adapter.generate_post_payload

      expect(hash['lis_person_name_given']).to eq 'User'
      expect(hash['lis_person_name_family']).to eq nil
      expect(hash['lis_person_name_full']).to eq @user.name
      hash['lis_person_contact_email_primary'] = @user.email
    end

    it "should provide a custom_canvas_user_login_id without an sis id" do
      user = user_with_pseudonym(:name => "A Name")
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :name => 'tool', :privacy_level => 'public')

      adapter = Lti::LtiOutboundAdapter.new(@tool, user, @course)
      adapter.prepare_tool_launch('http://www.google.com', launch_url: 'http://www.yahoo.com', link_code: '123456')
      hash = adapter.generate_post_payload

      expect(hash['custom_canvas_user_login_id']).to eq '$Canvas.user.loginId'
    end

    it "should include text if set" do
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :privacy_level => 'public', :name => 'tool')

      adapter = Lti::LtiOutboundAdapter.new(@tool, @user, @course)
      html = "<p>this has <a href='#'>a link</a></p>"
      adapter.prepare_tool_launch('http://www.yahoo.com', launch_url: 'http://www.yahoo.com', link_code: '123456', selected_html: html)

      hash = adapter.generate_post_payload
      expect(hash['text']).to eq CGI::escape(html)
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
      expect(hash['lis_result_sourcedid']).to eq "#{payload}-some_sha"
      expect(hash['lis_outcome_service_url']).to eq "/my/test/url"
      expect(hash['ext_ims_lis_basic_outcome_url']).to eq "/my/other/test/url"
      expect(hash['ext_outcome_data_values_accepted']).to eq 'url,text'
      expect(hash['custom_canvas_assignment_title']).to eq @assignment.title
      expect(hash['custom_canvas_assignment_points_possible']).to eq @assignment.points_possible.to_s
      expect(hash['custom_canvas_assignment_id']).to eq @assignment.id.to_s
    end

    it "should include assignment outcome service params for teacher" do
      hash = tool_setup(false)
      expect(hash['lis_result_sourcedid']).to be_nil
      expect(hash['lis_outcome_service_url']).to eq "/my/test/url"
      expect(hash['ext_ims_lis_basic_outcome_url']).to eq "/my/other/test/url"
      expect(hash['ext_outcome_data_values_accepted']).to eq 'url,text'
      expect(hash['custom_canvas_assignment_title']).to eq @assignment.title
      expect(hash['custom_canvas_assignment_points_possible']).to eq @assignment.points_possible.to_s
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

    expect(hash['launch_presentation_width']).to eq '1000'
    expect(hash['launch_presentation_height']).to eq '300'
  end

  context "sharding" do
    specs_require_sharding

    # TODO: Replace this once we have LTIInbound
    it "should roundtrip source ids from mixed shards", skip: true do
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
      expect(course).to eq @course
      expect(assignment).to eq @assignment
      expect(user).to eq @user
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

      expect(hash1['user_id']).not_to eq hash2['user_id']
    end
  end
end
