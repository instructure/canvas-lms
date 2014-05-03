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

describe ApplicationController do

  before :each do
    controller.stubs(:form_authenticity_token).returns('asdf')
    controller.stubs(:request).returns(stub(:host_with_port => "www.example.com"))
  end

  describe "js_env" do
    it "should set items" do
      HostUrl.expects(:file_host).with(Account.default, "www.example.com").returns("files.example.com")
      controller.js_env :FOO => 'bar'
      controller.js_env[:FOO].should == 'bar'
      controller.js_env[:AUTHENTICITY_TOKEN].should == 'asdf'
      controller.js_env[:files_domain].should == 'files.example.com'
    end

    it "should auto-set timezone and locale" do
      I18n.locale = :fr
      Time.zone = 'Alaska'
      @controller.js_env[:LOCALE].should == 'fr-FR'
      @controller.js_env[:TIMEZONE].should == 'America/Juneau'
    end

    it "should allow multiple items" do
      controller.js_env :A => 'a', :B => 'b'
      controller.js_env[:A].should == 'a'
      controller.js_env[:B].should == 'b'
    end

    it "should not allow overwriting a key" do
      controller.js_env :REAL_SLIM_SHADY => 'please stand up'
      expect { controller.js_env(:REAL_SLIM_SHADY => 'poser') }.to raise_error
    end
  end

  describe "clean_return_to" do
    before do
      req = stub('request obj', :protocol => 'https://', :host_with_port => 'canvas.example.com')
      controller.stubs(:request).returns(req)
    end

    it "should build from a simple path" do
      controller.send(:clean_return_to, "/calendar").should == "https://canvas.example.com/calendar"
    end

    it "should build from a full url" do
      # ... but always use the request host/protocol, not the given
      controller.send(:clean_return_to, "http://example.org/a/b?a=1&b=2#test").should == "https://canvas.example.com/a/b?a=1&b=2#test"
    end

    it "should reject disallowed paths" do
      controller.send(:clean_return_to, "ftp://example.com/javascript:hai").should be_nil
    end
  end

  describe "safe_domain_file_user" do
    before :each do
      # safe_domain_file_url wants to use request.protocol
      controller.stubs(:request).returns(mock(:protocol => '', :host_with_port => ''))

      @user = User.create!
      @attachment = @user.attachments.new(:filename => 'foo.png')
      @attachment.content_type = 'image/png'
      @attachment.save!

      @common_params = {
        :user_id => nil,
        :ts => nil,
        :sf_verifier => nil,
        :only_path => true
      }
    end

    it "should include inline=1 in url by default" do
      controller.expects(:file_download_url).
        with(@attachment, @common_params.merge(:inline => 1)).
        returns('')
      HostUrl.expects(:file_host_with_shard).with(42, '').returns(['myfiles', Shard.default])
      controller.instance_variable_set(:@domain_root_account, 42)
      url = controller.send(:safe_domain_file_url, @attachment)
      url.should match /myfiles/
    end

    it "should include :download=>1 in inline urls for relative contexts" do
      controller.instance_variable_set(:@context, @attachment.context)
      controller.stubs(:named_context_url).returns('')
      url = controller.send(:safe_domain_file_url, @attachment)
      url.should match(/[\?&]download=1(&|$)/)
    end

    it "should not include :download=>1 in download urls for relative contexts" do
      controller.instance_variable_set(:@context, @attachment.context)
      controller.stubs(:named_context_url).returns('')
      url = controller.send(:safe_domain_file_url, @attachment, nil, nil, true)
      url.should_not match(/[\?&]download=1(&|$)/)
    end

    it "should include download_frd=1 and not include inline=1 in url when specified as for download" do
      controller.expects(:file_download_url).
        with(@attachment, @common_params.merge(:download_frd => 1)).
        returns('')
      controller.send(:safe_domain_file_url, @attachment, nil, nil, true)
    end
  end

  describe "get_context" do
    after do
      I18n.localizer = nil
    end

    it "should find user with api_find for api requests" do
      user_with_pseudonym
      @pseudonym.update_attribute(:sis_user_id, 'test1')
      controller.instance_variable_set(:@domain_root_account, Account.default)
      controller.stubs(:named_context_url).with(@user, :context_url).returns('')
      controller.stubs(:params).returns({ :user_id => 'sis_user_id:test1' })
      controller.stubs(:api_request?).returns(true)
      controller.send(:get_context)
      controller.instance_variable_get(:@context).should == @user
    end

    it "should find course section with api_find for api requests" do
      course_model
      @section = @course.course_sections.first
      @section.update_attribute(:sis_source_id, 'test1')
      controller.instance_variable_set(:@domain_root_account, Account.default)
      controller.stubs(:named_context_url).with(@section, :context_url).returns('')
      controller.stubs(:params).returns({ :course_section_id => 'sis_section_id:test1' })
      controller.stubs(:api_request?).returns(true)
      controller.send(:get_context)
      controller.instance_variable_get(:@context).should == @section
    end

    # this test is supposed to represent calling I18n.t before a context is set
    # and still having later localizations that depend on the locale of the
    # context work.
    it "should reset the localizer" do
      # emulate all the locale related work done before/around a request
      acct = Account.default
      acct.default_locale = "es"
      acct.save!
      controller.instance_variable_set(:@domain_root_account, acct) 
      req = mock()
      req.stubs(:headers).returns({})
      controller.stubs(:request).returns(req)
      controller.send(:assign_localizer)
      I18n.set_locale_with_localizer # this is what t() triggers
      I18n.locale.to_s.should == "es"
      course_model(:locale => "ru")
      controller.stubs(:named_context_url).with(@course, :context_url).returns('')
      controller.stubs(:params).returns({ :course_id => @course.id })
      controller.stubs(:api_request?).returns(false)
      controller.stubs(:session).returns({})
      controller.stubs(:js_env).returns({})
      controller.send(:get_context)
      controller.instance_variable_get(:@context).should == @course
      I18n.set_locale_with_localizer # this is what t() triggers
      I18n.locale.to_s.should == "ru"
    end
  end

  if CANVAS_RAILS2
    describe "#complete_request_uri" do
      it "should filter sensitive parameters from the query string" do
        controller.stubs(:request).returns(mock(:protocol => "https://", :host => "example.com", :fullpath => "/api/v1/courses?password=abcd&test=5&Xaccess_token=13&access_token=sekrit"))
        controller.send(:complete_request_uri).should == "https://example.com/api/v1/courses?password=[FILTERED]&test=5&Xaccess_token=13&access_token=[FILTERED]"
      end
    end
  end

end

describe WikiPagesController do
  describe "set_js_rights" do
    it "should populate js_env with policy rights" do
      controller.stubs(:default_url_options).returns({})

      course_with_teacher_logged_in :active_all => true
      controller.instance_variable_set(:@context, @course)

      get 'pages_index', :course_id => @course.id

      controller.js_env.should include(:WIKI_RIGHTS)
      controller.js_env[:WIKI_RIGHTS].should == Hash[@course.wiki.check_policy(@teacher).map {|right| [right, true]}]
    end
  end
end
