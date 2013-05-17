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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe BasicLTI do
  describe "generate_params" do
    it "should generate a correct signature" do
      BasicLTI.explicit_signature_settings('1251600739', 'c8350c0e47782d16d2fa48b2090c1d8f')
      res = BasicLTI.generate_params({
        :resource_link_id                   => '120988f929-274612',
        :user_id                            => '292832126',
        :roles                              => 'Instructor',
        :lis_person_name_full               => 'Jane Q. Public',
        :lis_person_contact_email_primary   => 'user@school.edu',
        :lis_person_sourced_id              => 'school.edu:user',
        :context_id                         => '456434513',
        :context_title                      => 'Design of Personal Environments',
        :context_label                      => 'SI182',
        :lti_version                        => 'LTI-1p0',
        :lti_message_type                   => 'basic-lti-launch-request',
        :tool_consumer_instance_guid        => 'lmsng.school.edu',
        :tool_consumer_instance_description => 'University of School (LMSng)',
        :basiclti_submit                    => 'Launch Endpoint with BasicLTI Data'
      }, 'http://dr-chuck.com/ims/php-simple/tool.php', '12345', 'secret')
      res['oauth_signature'].should eql('TPFPK4u3NwmtLt0nDMP1G1zG30U=')
    end

    it "should generate a correct signature with URL query parameters" do
      BasicLTI.explicit_signature_settings('1251600739', 'c8350c0e47782d16d2fa48b2090c1d8f')
      res = BasicLTI.generate_params({
        :resource_link_id                   => '120988f929-274612',
        :user_id                            => '292832126',
        :roles                              => 'Instructor',
        :lis_person_name_full               => 'Jane Q. Public',
        :lis_person_contact_email_primary   => 'user@school.edu',
        :lis_person_sourced_id              => 'school.edu:user',
        :context_id                         => '456434513',
        :context_title                      => 'Design of Personal Environments',
        :context_label                      => 'SI182',
        :lti_version                        => 'LTI-1p0',
        :lti_message_type                   => 'basic-lti-launch-request',
        :tool_consumer_instance_guid        => 'lmsng.school.edu',
        :tool_consumer_instance_description => 'University of School (LMSng)',
        :basiclti_submit                    => 'Launch Endpoint with BasicLTI Data'
      }, 'http://dr-chuck.com/ims/php-simple/tool.php?a=1&b=2&c=3%20%26a', '12345', 'secret')
      res['oauth_signature'].should eql('uF7LooyefQN5aocx7UlYQ4tQM5k=')
      res['c'].should == "3 &a"
    end
    
    it "should generate a correct signature with a non-standard port" do
      # signatures generated using http://oauth.googlecode.com/svn/code/javascript/example/signature.html
      BasicLTI.explicit_signature_settings('1251600739', 'c8350c0e47782d16d2fa48b2090c1d8f')
      res = BasicLTI.generate_params({
      }, 'http://dr-chuck.com:123/ims/php-simple/tool.php', '12345', 'secret')
      res['oauth_signature'].should eql('ghEdPHwN4iJmsM3Nr4AndDx2Kx8=')
      
      res = BasicLTI.generate_params({
      }, 'http://dr-chuck.com/ims/php-simple/tool.php', '12345', 'secret')
      res['oauth_signature'].should eql('WoSpvCr2HEsLzao6Do0eukxwAsk=')
      
      res = BasicLTI.generate_params({
      }, 'http://dr-chuck.com:80/ims/php-simple/tool.php', '12345', 'secret')
      res['oauth_signature'].should eql('WoSpvCr2HEsLzao6Do0eukxwAsk=')
      
      res = BasicLTI.generate_params({
      }, 'http://dr-chuck.com:443/ims/php-simple/tool.php', '12345', 'secret')
      res['oauth_signature'].should eql('KqAV7eIS/+iWIDpvCyDfY8ZpmT4=')
      
      res = BasicLTI.generate_params({
      }, 'https://dr-chuck.com/ims/php-simple/tool.php', '12345', 'secret')
      res['oauth_signature'].should eql('wFRB/1ZXi/91dop6GwahfboWPvQ=')
      
      res = BasicLTI.generate_params({
      }, 'https://dr-chuck.com:443/ims/php-simple/tool.php', '12345', 'secret')
      res['oauth_signature'].should eql('wFRB/1ZXi/91dop6GwahfboWPvQ=')
      
      res = BasicLTI.generate_params({
      }, 'https://dr-chuck.com:80/ims/php-simple/tool.php', '12345', 'secret')
      res['oauth_signature'].should eql('X8Aq2HXSHnr6u/6z/G9zI5aDoR0=')
    end
  end
  
  describe "generate" do
    before do
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
      hash = BasicLTI.generate(:url => 'http://www.yahoo.com', :tool => @tool, :user => @user, :context => @course, :link_code => '123456', :return_url => 'http://www.google.com')
      hash['lti_message_type'].should == 'basic-lti-launch-request'
      hash['lti_version'].should == 'LTI-1p0'
      hash['resource_link_id'].should == '123456'
      hash['resource_link_title'].should == @tool.name
      hash['user_id'].should == @user.opaque_identifier(:asset_string)
      hash['user_image'].should == @user.avatar_url
      hash['roles'].should == 'Instructor'
      hash['context_id'].should == @course.opaque_identifier(:asset_string)
      hash['context_title'].should == @course.name
      hash['context_label'].should == @course.course_code
      hash['custom_canvas_user_id'].should == @user.id.to_s
      hash['custom_canvas_user_login_id'].should == @user.pseudonyms.first.unique_id
      hash['custom_canvas_course_id'].should == @course.id.to_s
      hash['custom_canvas_api_domain'].should == @course.root_account.domain
      hash['lis_course_offering_sourcedid'].should == 'coursesis'
      hash['lis_person_contact_email_primary'].should == 'nobody@example.com'
      hash['lis_person_name_full'].should == 'A Name'
      hash['lis_person_name_family'].should == 'Name'
      hash['lis_person_name_given'].should == 'A'
      hash['lis_person_sourcedid'].should == 'testfun'
      hash['launch_presentation_locale'].should == I18n.default_locale.to_s
      hash['launch_presentation_document_target'].should == 'iframe'
      hash['launch_presentation_width'].should == '600'
      hash['launch_presentation_height'].should == '400'
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
      hash = BasicLTI.generate(:url => 'http://www.yahoo.com', :tool => @tool, :user => @user, :context => @course, :link_code => '123456', :return_url => 'http://www.google.com')
      hash['launch_presentation_locale'].should == 'es'
      I18n.localizer = lambda { :en }
    end

    it "should add account info in launch data for account navigation" do
      @user = user_with_managed_pseudonym
      sub_account = Account.create(:parent_account => @account)
      sub_account.sis_source_id = 'accountsis'
      sub_account.save!
      @tool = sub_account.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :name => 'tool', :privacy_level => 'public')

      hash = BasicLTI.generate(:url => 'http://www.yahoo.com', :tool => @tool, :user => @user, :context => sub_account, :link_code => '123456', :return_url => 'http://www.google.com')
      hash['custom_canvas_account_id'] = sub_account.id.to_s
      hash['custom_canvas_account_sis_id'] = 'accountsis'
      hash['custom_canvas_user_login_id'].should == @user.pseudonyms.first.unique_id
    end

    it "should add account and user info in launch data for user profile launch" do
      @user = user_with_managed_pseudonym(:sis_user_id => 'testfun')
      sub_account = Account.create(:parent_account => @account)
      sub_account.sis_source_id = 'accountsis'
      sub_account.save!
      @tool = sub_account.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :name => 'tool', :privacy_level => 'public')

      hash = BasicLTI.generate(:url => 'http://www.yahoo.com', :tool => @tool, :user => @user, :context => @user, :link_code => '123456', :return_url => 'http://www.google.com')
      hash['custom_canvas_account_id'] = sub_account.id.to_s
      hash['custom_canvas_account_sis_id'] = 'accountsis'
      hash['lis_person_sourcedid'].should == 'testfun'
      hash['custom_canvas_user_id'].should == @user.id.to_s
      hash['tool_consumer_instance_guid'].should == sub_account.root_account.lti_guid
    end
    
    it "should include URI query parameters" do
      hash = BasicLTI.generate(:url => 'http://www.yahoo.com?a=1&b=2', :tool => @tool, :user => @user, :context => @course, :link_code => '123456', :return_url => 'http://www.google.com')
      hash['a'].should == '1'
      hash['b'].should == '2'
    end
    
    it "should not allow overwriting other parameters from the URI query string" do
      hash = BasicLTI.generate(:url => 'http://www.yahoo.com?user_id=123&oauth_callback=1234', :tool => @tool, :user => @user, :context => @course, :link_code => '123456', :return_url => 'http://www.google.com')
      hash['user_id'].should == @user.opaque_identifier(:asset_string)
      hash['oauth_callback'].should == 'about:blank'
    end
    
    it "should include custom fields" do
      course_with_teacher(:active_all => true)
      @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :custom_fields => {'custom_bob' => 'bob', 'custom_fred' => 'fred', 'john' => 'john', '@$TAA$#$#' => 123}, :name => 'tool')
      hash = BasicLTI.generate(:url => 'http://www.yahoo.com', :tool => @tool, :user => @user, :context => @course, :link_code => '123456', :return_url => 'http://www.yahoo.com')
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
      hash = BasicLTI.generate(:url => 'http://www.yahoo.com', :tool => @tool, :user => @user, :context => @course, :link_code => '123456', :return_url => 'http://www.yahoo.com')
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
      hash = BasicLTI.generate(:url => 'http://www.yahoo.com', :tool => @tool, :user => @user, :context => @course, :link_code => '123456', :return_url => 'http://www.yahoo.com')
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
      hash = BasicLTI.generate(:url => 'http://www.yahoo.com', :tool => @tool, :user => @user, :context => @course, :link_code => '123456', :return_url => 'http://www.yahoo.com')
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
      hash = BasicLTI.generate(:url => 'http://www.yahoo.com', :tool => @tool, :user => @user, :context => @course, :link_code => '123456', :return_url => 'http://www.yahoo.com')
      hash['lis_person_name_given'].should == 'User'
      hash['lis_person_name_family'].should == nil
      hash['lis_person_name_full'].should == @user.name
      hash['lis_person_contact_email_primary'] = @user.email
    end
  end

  it "should include assignment outcome service params" do
    course_with_teacher(:active_all => true)
    @tool = @course.context_external_tools.create!(:domain => 'yahoo.com', :consumer_key => '12345', :shared_secret => 'secret', :privacy_level => 'public', :name => 'tool')
    launch = BasicLTI::ToolLaunch.new(:url => "http://www.yahoo.com", :tool => @tool, :user => @user, :context => @course, :link_code => '123456', :return_url => 'http://www.yahoo.com')
    assignment_model(:submission_types => "external_tool", :course => @course, :points_possible => 5, :title => "an assignment")
    launch.for_assignment!(@assignment, "/my/test/url", "/my/other/test/url")
    hash = launch.generate
    hash['lis_result_sourcedid'].should == BasicLTI::BasicOutcomes.encode_source_id(@tool, @course, @assignment, @user)
    hash['lis_outcome_service_url'].should == "/my/test/url"
    hash['ext_ims_lis_basic_outcome_url'].should == "/my/other/test/url"
    hash['ext_outcome_data_values_accepted'].should == 'url,text'
    hash['custom_canvas_assignment_title'].should == @assignment.title
    hash['custom_canvas_assignment_points_possible'].should == @assignment.points_possible.to_s
  end

  context "sharding" do
    specs_require_sharding

    it "should roundtrip source ids from mixed shards" do
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
      sourceid = BasicLTI::BasicOutcomes.encode_source_id(@tool, @course, @assignment, @user)
      course, assignment, user = BasicLTI::BasicOutcomes.decode_source_id(@tool, sourceid)
      course.should == @course
      assignment.should == @assignment
      user.should == @user
    end
  end

  context "lti_role_types" do
    it "should return the correct role types" do
      course_model
      @course.offer
      teacher = user_model
      designer = user_model
      student = user_model
      nobody = user_model
      admin = user_model
      ta = user_model
      @course.root_account.add_user(admin)
      @course.enroll_teacher(teacher).accept
      @course.enroll_designer(designer).accept
      @course.enroll_student(student).accept
      @course.enroll_ta(ta).accept
      BasicLTI.user_lti_data(teacher, @course)['role_types'].should == ['Instructor']
      BasicLTI.user_lti_data(designer, @course)['role_types'].should == ['ContentDeveloper']
      BasicLTI.user_lti_data(student, @course)['role_types'].should == ['Learner']
      BasicLTI.user_lti_data(nobody, @course)['role_types'].should == ['urn:lti:sysrole:ims/lis/None']
      BasicLTI.user_lti_data(admin, @course)['role_types'].should == ['urn:lti:instrole:ims/lis/Administrator']
      BasicLTI.user_lti_data(ta, @course)['role_types'].should == ['urn:lti:role:ims/lis/TeachingAssistant']
    end

    it "should return multiple role types if applicable" do
      course_model
      @course.offer
      teacher = user_model
      @course.root_account.add_user(teacher)
      @course.enroll_teacher(teacher).accept
      @course.enroll_student(teacher).accept
      BasicLTI.user_lti_data(teacher, @course)['role_types'].sort.should == ['Instructor','Learner','urn:lti:instrole:ims/lis/Administrator'].sort
    end

    it "should not return role types from other contexts" do
      @course1 = course_model
      @course2 = course_model
      @course.offer
      teacher = user_model
      student = user_model
      @course1.enroll_teacher(teacher).accept
      @course1.enroll_student(student).accept
      BasicLTI.user_lti_data(teacher, @course2)['role_types'].should == ['urn:lti:sysrole:ims/lis/None']
      BasicLTI.user_lti_data(student, @course2)['role_types'].should == ['urn:lti:sysrole:ims/lis/None']
    end

    it "xml converter should use raise an error when unescaped ampersands are used in launch url" do
      xml = <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
            xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
            xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
            xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
            xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
            http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
            http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
            http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
            <blti:title>Other Name</blti:title>
            <blti:description>Description</blti:description>
            <blti:launch_url>http://example.com/other_url?unescapedampersands=1&arebadnews=2</blti:launch_url>
            <cartridge_bundle identifierref="BLTI001_Bundle"/>
            <cartridge_icon identifierref="BLTI001_Icon"/>
        </cartridge_basiclti_link>
      XML
      lti = CC::Importer::BLTIConverter.new
      lambda {lti.convert_blti_xml(xml)}.should raise_error
    end

    it "xml converter should use raise an error when unescaped ampersands are used in custom url properties" do
      xml = <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
            xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
            xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
            xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
            xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
            http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
            http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
            http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
            <blti:title>Other Name</blti:title>
            <blti:description>Description</blti:description>
            <blti:launch_url>http://example.com</blti:launch_url>
            <blti:extensions platform="canvas.instructure.com">
              <lticm:property name="privacy_level">public</lticm:property>
              <lticm:options name="course_navigation">
                <lticm:property name="url">https://example.com/attendance?param1=1&param2=2</lticm:property>
                <lticm:property name="enabled">true</lticm:property>
              </lticm:options>
            </blti:extensions>
            <cartridge_bundle identifierref="BLTI001_Bundle"/>
            <cartridge_icon identifierref="BLTI001_Icon"/>
        </cartridge_basiclti_link>
      XML
      lti = CC::Importer::BLTIConverter.new
      lambda {lti.convert_blti_xml(xml)}.should raise_error
    end
  end
end
