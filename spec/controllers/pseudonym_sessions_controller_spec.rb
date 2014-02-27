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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe PseudonymSessionsController do

  describe 'mobile layout decision' do
    let(:mobile_agents) do
      [
        "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5",
        "Mozilla/5.0 (iPod; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5",
        "Mozilla/5.0 (Linux; U; Android 2.2; en-us; SCH-I800 Build/FROYO) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1",
        "Mozilla/5.0 (Linux; U; Android 2.2; en-us; Sprint APA9292KT Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1",
        "Mozilla/5.0 (Linux; U; Android 2.2; en-us; Nexus One Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1"
      ]
    end

    def confirm_mobile_layout
      mobile_agents.each do |agent|
        controller.js_env.clear
        request.env['HTTP_USER_AGENT'] = agent
        yield
        response.should render_template("pseudonym_sessions/mobile_login")
      end
    end

    it "should render normal layout if not iphone/ipod" do
      get 'new'
      response.should render_template('new')
    end

    it "should render special iPhone/iPod layout if coming from one of those" do
      confirm_mobile_layout { get 'new' }
    end

    it "should render special iPhone/iPod layout if coming from one of those and it's the wrong password'" do
      confirm_mobile_layout { post 'create' }
    end

  end

  it "should re-render if no user" do
    post 'create'
    assert_status(400)
    response.should render_template('new')
  end

  it "should re-render if incorrect password" do
    user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1, :password => 'qwerty')
    post 'create', :pseudonym_session => { :unique_id => 'jt@instructure.com', :password => 'dvorak'}
    assert_status(400)
    response.should render_template('new')
  end

  it "should re-render if no password given" do
    user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1, :password => 'qwerty')
    post 'create', :pseudonym_session => { :unique_id => 'jt@instructure.com', :password => ''}
    assert_status(400)
    response.should render_template('new')
    flash[:error].should match(/no password/i)
  end

  it "password auth should work" do
    user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1, :password => 'qwerty')
    post 'create', :pseudonym_session => { :unique_id => 'jt@instructure.com', :password => 'qwerty'}
    response.should be_redirect
    response.should redirect_to(dashboard_url(:login_success => 1))
    assigns[:user].should == @user
    assigns[:pseudonym].should == @pseudonym
    assigns[:pseudonym_session].should_not be_nil
  end

  it "password auth should work with extra whitespace around unique id " do
    user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1, :password => 'qwerty')
    post 'create', :pseudonym_session => { :unique_id => ' jt@instructure.com ', :password => 'qwerty'}
    response.should be_redirect
    response.should redirect_to(dashboard_url(:login_success => 1))
    assigns[:user].should == @user
    assigns[:pseudonym].should == @pseudonym
    assigns[:pseudonym_session].should_not be_nil
  end

  context "ldap" do
    it "should log in a user with a identifier_format" do
      user_with_pseudonym(:username => '12345', :active_all => 1)
      @pseudonym.update_attribute(:sis_user_id, '12345')
      aac = Account.default.account_authorization_configs.create!(:auth_type => 'ldap', :identifier_format => 'uid')
      aac.any_instantiation.expects(:ldap_bind_result).once.with('username', 'password').returns([{ 'uid' => ['12345'] }])
      aac2 = Account.default.account_authorization_configs.create!(:auth_type => 'ldap', :identifier_format => 'uid')
      aac.any_instantiation.expects(:ldap_bind_result).never
      post 'create', :pseudonym_session => { :unique_id => 'username', :password => 'password'}
      response.should be_redirect
      response.should redirect_to(dashboard_url(:login_success => 1))
      assigns[:user].should == @user
      assigns[:pseudonym].should == @pseudonym
      assigns[:pseudonym_session].should_not be_nil
    end

    it "should only query the LDAP server once, even with a differing identifier_format but a matching pseudonym" do
      user_with_pseudonym(:username => 'username', :active_all => 1)
      aac = Account.default.account_authorization_configs.create!(:auth_type => 'ldap', :identifier_format => 'uid')
      aac.any_instantiation.expects(:ldap_bind_result).once.with('username', 'password').returns(nil)
      post 'create', :pseudonym_session => { :unique_id => 'username', :password => 'password'}
      assert_status(400)
      response.should render_template('new')
    end

    it "should not treat ldap without canvas as delegated for purposes of rendering the login screen" do
      aac = Account.default.account_authorization_configs.create!(:auth_type => 'ldap', :identifier_format => 'uid')
      Account.default.settings[:canvas_authentication] = false
      Account.default.save!
      get 'new'
      response.should render_template('new')
      response.should be_success
      assigns[:is_delegated].should == false
    end
  end

  context "trusted logins" do
    it "should login for a pseudonym from a different account" do
      account = Account.create!
      Account.any_instance.stubs(:trusted_account_ids).returns([account.id])
      user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1, :password => 'qwerty', :account => account)
      post 'create', :pseudonym_session => { :unique_id => 'jt@instructure.com', :password => 'qwerty'}
      response.should redirect_to(dashboard_url(:login_success => 1))
    end

    it "should login for a user with multiple identical pseudonyms" do
      account1 = Account.create!
      user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1, :password => 'qwerty', :account => account1)
      @pseudonym = @user.pseudonyms.create!(:account => Account.site_admin, :unique_id => 'jt@instructure.com', :password => 'qwerty', :password_confirmation => 'qwerty')
      post 'create', :pseudonym_session => { :unique_id => 'jt@instructure.com', :password => 'qwerty'}
      response.should redirect_to(dashboard_url(:login_success => 1))
      # it should have preferred the site admin pseudonym
      assigns[:pseudonym].should == @pseudonym
    end

    it "should not login for multiple users with identical pseudonyms" do
      account1 = Account.create!
      account2 = Account.create!
      Account.any_instance.stubs(:trusted_account_ids).returns([account1.id, account2.id])
      user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1, :password => 'qwerty', :account => account1)
      user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1, :password => 'qwerty', :account => account2)
      post 'create', :pseudonym_session => { :unique_id => 'jt@instructure.com', :password => 'qwerty'}
      response.should_not be_success
      response.should render_template('pseudonym_sessions/new')
    end

    it "should login a site admin user with other identical pseudonyms" do
      account1 = Account.create!
      Account.any_instance.stubs(:trusted_account_ids).returns([account1.id, Account.site_admin.id])
      user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1, :password => 'qwerty', :account => account1)
      user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1, :password => 'qwerty', :account => Account.site_admin)
      post 'create', :pseudonym_session => { :unique_id => 'jt@instructure.com', :password => 'qwerty'}
      response.should redirect_to(dashboard_url(:login_success => 1))
      # it should have preferred the site admin pseudonym
      assigns[:pseudonym].should == @pseudonym
    end

    context "sharding" do
      specs_require_sharding

      it "should login for a user from a different shard" do
        user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1, :password => 'qwerty', :account => Account.site_admin)
        @shard1.activate do
          account = Account.create!
          HostUrl.stubs(:default_domain_root_account).returns(account)
          post 'create', :pseudonym_session => { :unique_id => 'jt@instructure.com', :password => 'qwerty' }
          response.should redirect_to(dashboard_url(:login_success => 1))
          assigns[:pseudonym].should == @pseudonym
        end
      end
    end
  end

  context "merging" do
    it "should set merge params correctly in the session" do
      user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1, :password => 'qwerty')
      @cc = @user.communication_channels.create!(:path => 'jt+1@instructure.com')
      get 'new', :confirm => @cc.confirmation_code, :expected_user_id => @user.id
      response.should render_template 'new'
      session[:confirm].should == @cc.confirmation_code
      session[:expected_user_id].should == @user.id
    end

    it "should redirect back to merge users" do
      user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1, :password => 'qwerty')
      @cc = @user.communication_channels.create!(:path => 'jt+1@instructure.com')
      session[:confirm] = @cc.confirmation_code
      session[:expected_user_id] = @user.id
      post 'create', :pseudonym_session => { :unique_id => 'jt@instructure.com', :password => 'qwerty' }
      response.should redirect_to(registration_confirmation_url(@cc.confirmation_code, :login_success => 1, :enrollment => nil, :confirm => 1))
    end
  end

  context "saml" do
    before do
      pending("requires SAML extension") unless AccountAuthorizationConfig.saml_enabled
    end

    it "should scope logins to the correct domain root account" do
      Setting.set_config("saml", {})
      unique_id = 'foo@example.com'

      account1 = account_with_saml
      user1 = user_with_pseudonym({:active_all => true, :username => unique_id})
      @pseudonym.account = account1
      @pseudonym.save!

      account2 = account_with_saml
      user2 = user_with_pseudonym({:active_all => true, :username => unique_id})
      @pseudonym.account = account2
      @pseudonym.save!

      controller.stubs(:saml_response).returns(
        stub('response', :is_valid? => true, :success_status? => true, :name_id => unique_id, :name_qualifier => nil, :session_index => nil, :process => nil)
      )

      controller.request.env['canvas.domain_root_account'] = account1
      get 'saml_consume', :SAMLResponse => "foo"
      response.should redirect_to(dashboard_url(:login_success => 1))
      session[:saml_unique_id].should == unique_id
      Pseudonym.find(session['pseudonym_credentials_id']).should == user1.pseudonyms.first

      (controller.instance_variables.grep(/@[^_]/) - ['@mock_proxy']).each{ |var| controller.send :remove_instance_variable, var }
      CANVAS_RAILS2 ? session.reset : session.clear

      controller.stubs(:saml_response).returns(
        stub('response', :is_valid? => true, :success_status? => true, :name_id => unique_id, :name_qualifier => nil, :session_index => nil, :process => nil)
      )

      controller.request.env['canvas.domain_root_account'] = account2
      get 'saml_consume', :SAMLResponse => "bar"
      response.should redirect_to(dashboard_url(:login_success => 1))
      session[:saml_unique_id].should == unique_id
      Pseudonym.find(session['pseudonym_credentials_id']).should == user2.pseudonyms.first

      Setting.set_config("saml", nil)
    end

    context "multiple authorization configs" do
      before do
        @account = Account.create!
        @unique_id = 'foo@example.com'
        @user1 = user_with_pseudonym(:active_all => true, :username => @unique_id, :account => @account)
        aac1 = Account.default.account_authorization_configs.create!(:auth_type => 'ldap', :identifier_format => 'uid')
        @account.account_authorization_configs << aac1

        aac2 = AccountAuthorizationConfig.new
        aac2.auth_type = "saml"
        aac2.idp_entity_id = "https://example.com/idp1"
        aac2.log_out_url = "https://example.com/idp1/slo"
        @account.account_authorization_configs << aac2

        @stub_hash = {:issuer => aac2.idp_entity_id, :is_valid? => true, :success_status? => true, :name_id => @unique_id, :name_qualifier => nil, :session_index => nil, :process => nil}
      end

      it "should saml_consume login with multiple authorization configs" do
        controller.stubs(:saml_response).returns(
            stub('response', @stub_hash)
        )
        controller.request.env['canvas.domain_root_account'] = @account
        get 'saml_consume', :SAMLResponse => "foo", :RelayState => "/courses"
        response.should redirect_to(courses_url)
        session[:saml_unique_id].should == @unique_id
      end

      it "should saml_logout with multiple authorization configs" do
        controller.stubs(:saml_logout_response).returns(
            stub('response', @stub_hash)
        )
        controller.request.env['canvas.domain_root_account'] = @account
        get 'saml_logout', :SAMLResponse => "foo", :RelayState => "/courses"

        response.should redirect_to(:action => :destroy)
      end
    end

    context "multiple SAML configs" do
      before do
        @account = account_with_saml(:saml_log_in_url => "https://example.com/idp1/sli")
        @unique_id = 'foo@example.com'
        @user1 = user_with_pseudonym(:active_all => true, :username => @unique_id, :account => @account)
        @aac1 = @account.account_authorization_configs.first
        @aac1.idp_entity_id = "https://example.com/idp1"
        @aac1.log_out_url = "https://example.com/idp1/slo"
        @aac1.save!

        @aac2 = @aac1.clone
        @aac2.idp_entity_id = "https://example.com/idp2"
        @aac2.log_in_url = "https://example.com/idp2/sli"
        @aac2.log_out_url = "https://example.com/idp2/slo"
        @aac2.position = nil
        @aac2.save!

        @stub_hash = {:issuer => @aac2.idp_entity_id, :is_valid? => true, :success_status? => true, :name_id => @unique_id, :name_qualifier => nil, :session_index => nil, :process => nil}
      end

      context "/saml_consume" do
        def get_consume
          controller.stubs(:saml_response).returns(
                  stub('response', @stub_hash)
          )

          controller.request.env['canvas.domain_root_account'] = @account
          get 'saml_consume', :SAMLResponse => "foo", :RelayState => "/courses"
        end

        it "should find the SAML config by entity_id" do
          @aac1.any_instantiation.expects(:saml_settings).never
          @aac2.any_instantiation.expects(:saml_settings)

          get_consume

          response.should redirect_to(courses_url)
          session[:saml_unique_id].should == @unique_id
        end

        it "/saml_consume should redirect to auth url if no AAC found" do
          @account.auth_discovery_url = "http://example.com/discover"
          @account.save!
          @stub_hash[:issuer] = "hahahahahahaha"

          get_consume

          response.should redirect_to(@account.auth_discovery_url + "?message=Canvas%20did%20not%20recognize%20your%20identity%20provider")
        end

        it "/saml_consume should redirect to login screen with message if no AAC found" do
          @stub_hash[:issuer] = "hahahahahahaha"

          get_consume

          flash[:delegated_message].should == "The institution you logged in from is not configured on this account."
          response.should redirect_to(login_url(:no_auto=>'true'))
        end
      end

      context "/new" do
        def get_new(aac_id=nil)
          controller.request.env['canvas.domain_root_account'] = @account
          if aac_id
            get 'new', :account_authorization_config_id => aac_id
          else
            get 'new'
          end
        end

        it "should redirect to auth discovery url" do
          @account.auth_discovery_url = "http://example.com/discover"
          @account.save!

          get_new

          response.should redirect_to(@account.auth_discovery_url)
        end

        it "should redirect to default login" do
          get_new
          response.headers['Location'].starts_with?(controller.delegated_auth_redirect_uri(@aac1.log_in_url)).should be_true
        end

        it "should use the specified AAC" do
          get_new("#{@aac1.id}")
          response.headers['Location'].starts_with?(controller.delegated_auth_redirect_uri(@aac1.log_in_url)).should be_true
          get_new("#{@aac2.id}")
          response.headers['Location'].starts_with?(controller.delegated_auth_redirect_uri(@aac2.log_in_url)).should be_true
        end

        it "should redirect to auth discovery with unknown specified AAC" do
          @account.auth_discovery_url = "http://example.com/discover"
          @account.save!
          get_new("0")
          response.should redirect_to(@account.auth_discovery_url + "?message=The%20Canvas%20account%20has%20no%20authentication%20configuration%20with%20that%20id")
        end

        it "should redirect to login screen with message if unknown specified AAC" do
          get_new("0")
          flash[:delegated_message].should == "The Canvas account has no authentication configuration with that id"
          response.should redirect_to(login_url(:no_auto=>'true'))
        end
      end

      context "logging out" do
        append_before do
          controller.stubs(:saml_response).returns(
                  stub('response', @stub_hash)
          )

          controller.request.env['canvas.domain_root_account'] = @account
          get 'saml_consume', :SAMLResponse => "foo", :RelayState => "/courses"

          response.should redirect_to(courses_url)
          session[:saml_unique_id].should == @unique_id
          session[:saml_aac_id].should == @aac2.id
        end

        context '/destroy' do
          it "should forward to correct IdP" do
            get 'destroy'

            response.headers['Location'].starts_with?(@aac2.log_out_url + "?SAMLRequest=").should be_true
          end

          it "should fail gracefully if AAC id gone" do
            session[:saml_aac_id] = 0

            get 'destroy'
            flash[:message].should == "Canvas was unable to log you out at your identity provider"
            response.should redirect_to(login_url(:no_auto=>'true'))
          end
        end

        context '/saml_logout' do
          def get_saml_consume
            controller.stubs(:saml_logout_response).returns(
                    stub('response', @stub_hash)
            )

            controller.request.env['canvas.domain_root_account'] = @account
            get 'saml_logout', :SAMLResponse => "foo", :RelayState => "/courses"
          end

          it "should find the correct AAC" do
            @aac1.any_instantiation.expects(:saml_settings).never
            @aac2.any_instantiation.expects(:saml_settings)

            get_saml_consume

            response.should redirect_to(:action => :destroy)
          end

          it "should still logout if AAC config not found" do
            @aac1.any_instantiation.expects(:saml_settings).never
            @aac2.any_instantiation.expects(:saml_settings).never

            @stub_hash[:issuer] = "nobody eh"
            get_saml_consume

            response.should redirect_to(:action => :destroy)
          end
        end
      end
    end

    context "login attributes" do
      before(:each) do
        Setting.set_config("saml", {})
        @unique_id = 'foo'

        @account = account_with_saml
        @user = user_with_pseudonym({:active_all => true, :username => @unique_id})
        @pseudonym.account = @account
        @pseudonym.save!

        @aac = @account.account_authorization_config
      end

      it "should use the eduPersonPrincipalName attribute with the domain stripped" do
        @aac.login_attribute = 'eduPersonPrincipalName_stripped'
        @aac.save

        controller.stubs(:saml_response).returns(
          stub('response', :is_valid? => true, :success_status? => true, :name_id => nil, :name_qualifier => nil, :session_index => nil, :process => nil,
            :saml_attributes => {
              'eduPersonPrincipalName' => "#{@unique_id}@example.edu"
            })
        )

        controller.request.env['canvas.domain_root_account'] = @account
        get 'saml_consume', :SAMLResponse => "foo", :RelayState => "/courses"
        response.should redirect_to(courses_url)
        session[:saml_unique_id].should == @unique_id
      end

      it "should use the NameID if no login attribute is specified" do
        @aac.login_attribute = nil
        @aac.save

        controller.stubs(:saml_response).returns(
          stub('response', :is_valid? => true, :success_status? => true, :name_id => @unique_id, :name_qualifier => nil, :session_index => nil, :process => nil)
        )

        controller.request.env['canvas.domain_root_account'] = @account
        get 'saml_consume', :SAMLResponse => "foo", :RelayState => "/courses"
        response.should redirect_to(courses_url)
        session[:saml_unique_id].should == @unique_id
      end
    end
    
    it "should use the eppn saml attribute if configured" do
      Setting.set_config("saml", {})
      unique_id = 'foo'

      account = account_with_saml
      @aac = @account.account_authorization_config
      @aac.login_attribute = 'eduPersonPrincipalName_stripped'
      @aac.save

      user = user_with_pseudonym({:active_all => true, :username => unique_id})
      @pseudonym.account = account
      @pseudonym.save!

      controller.stubs(:saml_response).returns(
        stub('response', :is_valid? => true, :success_status? => true, :name_id => nil, :name_qualifier => nil, :session_index => nil, :process => nil,
          :saml_attributes => {
            'eduPersonPrincipalName' => "#{unique_id}@example.edu"
          })
      )

      controller.request.env['canvas.domain_root_account'] = account
      get 'saml_consume', :SAMLResponse => "foo", :RelayState => "/courses"
      response.should redirect_to(courses_url)
      session[:saml_unique_id].should == unique_id
    end

    it "should redirect to RelayState relative urls" do
      Setting.set_config("saml", {})
      unique_id = 'foo@example.com'

      account = account_with_saml
      user = user_with_pseudonym({:active_all => true, :username => unique_id})
      @pseudonym.account = account
      @pseudonym.save!

      controller.stubs(:saml_response).returns(
        stub('response', :is_valid? => true, :success_status? => true, :name_id => unique_id, :name_qualifier => nil, :session_index => nil, :process => nil)
      )

      controller.request.env['canvas.domain_root_account'] = account
      get 'saml_consume', :SAMLResponse => "foo", :RelayState => "/courses"
      response.should redirect_to(courses_url)
      session[:saml_unique_id].should == unique_id
    end

    it "should decode an actual saml response" do
      Setting.set_config("saml", {})
      unique_id = 'student@example.edu'

      account_with_saml

      @aac = @account.account_authorization_config
      @aac.login_attribute = 'eduPersonPrincipalName'
      @aac.certificate_fingerprint = 'AF:E7:1C:28:EF:74:0B:C8:74:25:BE:13:A2:26:3D:37:97:1D:A1:F9'
      @aac.save

      user = user_with_pseudonym(:active_all => true, :username => unique_id)
      @pseudonym.account = @account
      @pseudonym.save!

      controller.request.env['canvas.domain_root_account'] = @account
      get 'saml_consume', :SAMLResponse => <<-SAML
        PHNhbWxwOlJlc3BvbnNlIHhtbG5zOnNhbWxwPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6cHJv
        dG9jb2wiIHhtbG5zOnNhbWw9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDphc3NlcnRpb24iIElE
        PSJfMzJmMTBlOGU0NjVmY2VmNzIzNjhlMjIwZmFlYjgxZGI0YzcyZjBjNjg3IiBWZXJzaW9uPSIyLjAi
        IElzc3VlSW5zdGFudD0iMjAxMi0wOC0wM1QyMDowNzoxNVoiIERlc3RpbmF0aW9uPSJodHRwOi8vc2hh
        cmQxLmxvY2FsZG9tYWluOjMwMDAvc2FtbF9jb25zdW1lIiBJblJlc3BvbnNlVG89ImQwMDE2ZWM4NThk
        OTIzNjBjNTk3YTAxZDE1NTk0NGY4ZGY4ZmRiMTE2ZCI+PHNhbWw6SXNzdWVyPmh0dHA6Ly9waHBzaXRl
        L3NpbXBsZXNhbWwvc2FtbDIvaWRwL21ldGFkYXRhLnBocDwvc2FtbDpJc3N1ZXI+PGRzOlNpZ25hdHVy
        ZSB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyI+CiAgPGRzOlNpZ25l
        ZEluZm8+PGRzOkNhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9y
        Zy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz4KICAgIDxkczpTaWduYXR1cmVNZXRob2QgQWxnb3JpdGht
        PSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjcnNhLXNoYTEiLz4KICA8ZHM6UmVmZXJl
        bmNlIFVSST0iI18zMmYxMGU4ZTQ2NWZjZWY3MjM2OGUyMjBmYWViODFkYjRjNzJmMGM2ODciPjxkczpU
        cmFuc2Zvcm1zPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5
        L3htbGRzaWcjZW52ZWxvcGVkLXNpZ25hdHVyZSIvPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRw
        Oi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRp
        Z2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGEx
        Ii8+PGRzOkRpZ2VzdFZhbHVlPlM2TmUxMW5CN2cxT3lRQUdZckZFT251NVFBUT08L2RzOkRpZ2VzdFZh
        bHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+bWdxWlVp
        QTNtYXRyajZaeTREbCsxZ2hzZ29PbDh3UEgybXJGTTlQQXFyWUIwc2t1SlVaaFlVa0NlZ0ViRVg5V1JP
        RWhvWjJiZ3dKUXFlVVB5WDdsZU1QZTdTU2RVRE5LZjlraXV2cGNDWVpzMWxGU0VkNTFFYzhmK0h2ZWpt
        SFVKQVUrSklSV3BwMVZrWVVaQVRpaHdqR0xvazNOR2kveWdvYWpOaDQydlo0PTwvZHM6U2lnbmF0dXJl
        VmFsdWU+CjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUNnVEND
        QWVvQ0NRQ2JPbHJXRGRYN0ZUQU5CZ2txaGtpRzl3MEJBUVVGQURDQmhERUxNQWtHQTFVRUJoTUNUazh4
        R0RBV0JnTlZCQWdURDBGdVpISmxZWE1nVTI5c1ltVnlaekVNTUFvR0ExVUVCeE1EUm05dk1SQXdEZ1lE
        VlFRS0V3ZFZUa2xPUlZSVU1SZ3dGZ1lEVlFRREV3OW1aV2xrWlM1bGNteGhibWN1Ym04eElUQWZCZ2tx
        aGtpRzl3MEJDUUVXRW1GdVpISmxZWE5BZFc1cGJtVjBkQzV1YnpBZUZ3MHdOekEyTVRVeE1qQXhNelZh
        Rncwd056QTRNVFF4TWpBeE16VmFNSUdFTVFzd0NRWURWUVFHRXdKT1R6RVlNQllHQTFVRUNCTVBRVzVr
        Y21WaGN5QlRiMnhpWlhKbk1Rd3dDZ1lEVlFRSEV3TkdiMjh4RURBT0JnTlZCQW9UQjFWT1NVNUZWRlF4
        R0RBV0JnTlZCQU1URDJabGFXUmxMbVZ5YkdGdVp5NXViekVoTUI4R0NTcUdTSWIzRFFFSkFSWVNZVzVr
        Y21WaGMwQjFibWx1WlhSMExtNXZNSUdmTUEwR0NTcUdTSWIzRFFFQkFRVUFBNEdOQURDQmlRS0JnUURp
        dmJoUjdQNTE2eC9TM0JxS3h1cFFlMExPTm9saXVwaUJPZXNDTzNTSGJEcmwzK3E5SWJmbmZtRTA0ck51
        TWNQc0l4QjE2MVRkRHBJZXNMQ243YzhhUEhJU0tPdFBsQWVUWlNuYjhRQXU3YVJqWnEzK1BiclA1dVcz
        VGNmQ0dQdEtUeXRIT2dlL09sSmJvMDc4ZFZoWFExNGQxRUR3WEpXMXJSWHVVdDRDOFFJREFRQUJNQTBH
        Q1NxR1NJYjNEUUVCQlFVQUE0R0JBQ0RWZnA4NkhPYnFZK2U4QlVvV1E5K1ZNUXgxQVNEb2hCandPc2cy
        V3lrVXFSWEYrZExmY1VIOWRXUjYzQ3RaSUtGRGJTdE5vbVBuUXo3bmJLK29ueWd3QnNwVkVibkh1VWlo
        WnEzWlVkbXVtUXFDdzRVdnMvMVV2cTNvck9vL1dKVmhUeXZMZ0ZWSzJRYXJRNC82N09aZkhkN1IrUE9C
        WGhvcGhTTXYxWk9vPC9kczpYNTA5Q2VydGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+
        PC9kczpTaWduYXR1cmU+PHNhbWxwOlN0YXR1cz48c2FtbHA6U3RhdHVzQ29kZSBWYWx1ZT0idXJuOm9h
        c2lzOm5hbWVzOnRjOlNBTUw6Mi4wOnN0YXR1czpTdWNjZXNzIi8+PC9zYW1scDpTdGF0dXM+PHNhbWw6
        QXNzZXJ0aW9uIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFu
        Y2UiIHhtbG5zOnhzPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYSIgSUQ9Il82MjEyYjdl
        OGMwNjlkMGY5NDhjODY0ODk5MWQzNTdhZGRjNDA5NWE4MmYiIFZlcnNpb249IjIuMCIgSXNzdWVJbnN0
        YW50PSIyMDEyLTA4LTAzVDIwOjA3OjE1WiI+PHNhbWw6SXNzdWVyPmh0dHA6Ly9waHBzaXRlL3NpbXBs
        ZXNhbWwvc2FtbDIvaWRwL21ldGFkYXRhLnBocDwvc2FtbDpJc3N1ZXI+PGRzOlNpZ25hdHVyZSB4bWxu
        czpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyI+CiAgPGRzOlNpZ25lZEluZm8+
        PGRzOkNhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAx
        LzEwL3htbC1leGMtYzE0biMiLz4KICAgIDxkczpTaWduYXR1cmVNZXRob2QgQWxnb3JpdGhtPSJodHRw
        Oi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjcnNhLXNoYTEiLz4KICA8ZHM6UmVmZXJlbmNlIFVS
        ST0iI182MjEyYjdlOGMwNjlkMGY5NDhjODY0ODk5MWQzNTdhZGRjNDA5NWE4MmYiPjxkczpUcmFuc2Zv
        cm1zPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRz
        aWcjZW52ZWxvcGVkLXNpZ25hdHVyZSIvPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3
        LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1l
        dGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGExIi8+PGRz
        OkRpZ2VzdFZhbHVlPmthWk4xK21vUzMyOHByMnpuOFNLVU1MMUVsST08L2RzOkRpZ2VzdFZhbHVlPjwv
        ZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+MWtVRWtHMzNaR1FN
        Zi8xSDFnenFCT2hUNU4ySTM1dk0wNEpwNjd4VmpuWlhGNTRBcVBxMVphTStXamd4KytBakViTDdrc2FZ
        dU0zSlN5SzdHbFo3N1ZtenBMc01xbjRlTTAwSzdZK0NlWnk1TEIyNHZjbmdYUHhCazZCZFVZa1ZrMHZP
        c1VmQUFaK21SWC96ekJXN1o0QzdxYmpOR2hBQUpnaTEzSm9CV3BVPTwvZHM6U2lnbmF0dXJlVmFsdWU+
        CjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUNnVENDQWVvQ0NR
        Q2JPbHJXRGRYN0ZUQU5CZ2txaGtpRzl3MEJBUVVGQURDQmhERUxNQWtHQTFVRUJoTUNUazh4R0RBV0Jn
        TlZCQWdURDBGdVpISmxZWE1nVTI5c1ltVnlaekVNTUFvR0ExVUVCeE1EUm05dk1SQXdEZ1lEVlFRS0V3
        ZFZUa2xPUlZSVU1SZ3dGZ1lEVlFRREV3OW1aV2xrWlM1bGNteGhibWN1Ym04eElUQWZCZ2txaGtpRzl3
        MEJDUUVXRW1GdVpISmxZWE5BZFc1cGJtVjBkQzV1YnpBZUZ3MHdOekEyTVRVeE1qQXhNelZhRncwd056
        QTRNVFF4TWpBeE16VmFNSUdFTVFzd0NRWURWUVFHRXdKT1R6RVlNQllHQTFVRUNCTVBRVzVrY21WaGN5
        QlRiMnhpWlhKbk1Rd3dDZ1lEVlFRSEV3TkdiMjh4RURBT0JnTlZCQW9UQjFWT1NVNUZWRlF4R0RBV0Jn
        TlZCQU1URDJabGFXUmxMbVZ5YkdGdVp5NXViekVoTUI4R0NTcUdTSWIzRFFFSkFSWVNZVzVrY21WaGMw
        QjFibWx1WlhSMExtNXZNSUdmTUEwR0NTcUdTSWIzRFFFQkFRVUFBNEdOQURDQmlRS0JnUURpdmJoUjdQ
        NTE2eC9TM0JxS3h1cFFlMExPTm9saXVwaUJPZXNDTzNTSGJEcmwzK3E5SWJmbmZtRTA0ck51TWNQc0l4
        QjE2MVRkRHBJZXNMQ243YzhhUEhJU0tPdFBsQWVUWlNuYjhRQXU3YVJqWnEzK1BiclA1dVczVGNmQ0dQ
        dEtUeXRIT2dlL09sSmJvMDc4ZFZoWFExNGQxRUR3WEpXMXJSWHVVdDRDOFFJREFRQUJNQTBHQ1NxR1NJ
        YjNEUUVCQlFVQUE0R0JBQ0RWZnA4NkhPYnFZK2U4QlVvV1E5K1ZNUXgxQVNEb2hCandPc2cyV3lrVXFS
        WEYrZExmY1VIOWRXUjYzQ3RaSUtGRGJTdE5vbVBuUXo3bmJLK29ueWd3QnNwVkVibkh1VWloWnEzWlVk
        bXVtUXFDdzRVdnMvMVV2cTNvck9vL1dKVmhUeXZMZ0ZWSzJRYXJRNC82N09aZkhkN1IrUE9CWGhvcGhT
        TXYxWk9vPC9kczpYNTA5Q2VydGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+PC9kczpT
        aWduYXR1cmU+PHNhbWw6U3ViamVjdD48c2FtbDpOYW1lSUQgU1BOYW1lUXVhbGlmaWVyPSJodHRwOi8v
        c2hhcmQxLmxvY2FsZG9tYWluL3NhbWwyIiBGb3JtYXQ9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIu
        MDpuYW1laWQtZm9ybWF0OnRyYW5zaWVudCI+XzNiM2U3NzE0YjcyZTI5ZGM0MjkwMzIxYTA3NWZhMGI3
        MzMzM2E0ZjI1Zjwvc2FtbDpOYW1lSUQ+PHNhbWw6U3ViamVjdENvbmZpcm1hdGlvbiBNZXRob2Q9InVy
        bjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDpjbTpiZWFyZXIiPjxzYW1sOlN1YmplY3RDb25maXJtYXRp
        b25EYXRhIE5vdE9uT3JBZnRlcj0iMjAxMi0wOC0wM1QyMDoxMjoxNVoiIFJlY2lwaWVudD0iaHR0cDov
        L3NoYXJkMS5sb2NhbGRvbWFpbjozMDAwL3NhbWxfY29uc3VtZSIgSW5SZXNwb25zZVRvPSJkMDAxNmVj
        ODU4ZDkyMzYwYzU5N2EwMWQxNTU5NDRmOGRmOGZkYjExNmQiLz48L3NhbWw6U3ViamVjdENvbmZpcm1h
        dGlvbj48L3NhbWw6U3ViamVjdD48c2FtbDpDb25kaXRpb25zIE5vdEJlZm9yZT0iMjAxMi0wOC0wM1Qy
        MDowNjo0NVoiIE5vdE9uT3JBZnRlcj0iMjAxMi0wOC0wM1QyMDoxMjoxNVoiPjxzYW1sOkF1ZGllbmNl
        UmVzdHJpY3Rpb24+PHNhbWw6QXVkaWVuY2U+aHR0cDovL3NoYXJkMS5sb2NhbGRvbWFpbi9zYW1sMjwv
        c2FtbDpBdWRpZW5jZT48L3NhbWw6QXVkaWVuY2VSZXN0cmljdGlvbj48L3NhbWw6Q29uZGl0aW9ucz48
        c2FtbDpBdXRoblN0YXRlbWVudCBBdXRobkluc3RhbnQ9IjIwMTItMDgtMDNUMjA6MDc6MTVaIiBTZXNz
        aW9uTm90T25PckFmdGVyPSIyMDEyLTA4LTA0VDA0OjA3OjE1WiIgU2Vzc2lvbkluZGV4PSJfMDJmMjZh
        ZjMwYTM3YWZiOTIwODFmM2E3MzcyODgxMDE5M2VmZDdmYTZlIj48c2FtbDpBdXRobkNvbnRleHQ+PHNh
        bWw6QXV0aG5Db250ZXh0Q2xhc3NSZWY+dXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOmFjOmNsYXNz
        ZXM6UGFzc3dvcmQ8L3NhbWw6QXV0aG5Db250ZXh0Q2xhc3NSZWY+PC9zYW1sOkF1dGhuQ29udGV4dD48
        L3NhbWw6QXV0aG5TdGF0ZW1lbnQ+PHNhbWw6QXR0cmlidXRlU3RhdGVtZW50PjxzYW1sOkF0dHJpYnV0
        ZSBOYW1lPSJ1cm46b2lkOjEuMy42LjEuNC4xLjU5MjMuMS4xLjEuMSIgTmFtZUZvcm1hdD0idXJuOm9h
        c2lzOm5hbWVzOnRjOlNBTUw6Mi4wOmF0dHJuYW1lLWZvcm1hdDp1cmkiPjxzYW1sOkF0dHJpYnV0ZVZh
        bHVlIHhzaTp0eXBlPSJ4czpzdHJpbmciPm1lbWJlcjwvc2FtbDpBdHRyaWJ1dGVWYWx1ZT48L3NhbWw6
        QXR0cmlidXRlPjxzYW1sOkF0dHJpYnV0ZSBOYW1lPSJ1cm46b2lkOjEuMy42LjEuNC4xLjU5MjMuMS4x
        LjEuNiIgTmFtZUZvcm1hdD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOmF0dHJuYW1lLWZvcm1h
        dDp1cmkiPjxzYW1sOkF0dHJpYnV0ZVZhbHVlIHhzaTp0eXBlPSJ4czpzdHJpbmciPnN0dWRlbnRAZXhh
        bXBsZS5lZHU8L3NhbWw6QXR0cmlidXRlVmFsdWU+PC9zYW1sOkF0dHJpYnV0ZT48L3NhbWw6QXR0cmli
        dXRlU3RhdGVtZW50Pjwvc2FtbDpBc3NlcnRpb24+PC9zYW1scDpSZXNwb25zZT4=
      SAML
      response.should redirect_to(dashboard_url(:login_success => 1))
      session[:saml_unique_id].should == unique_id
    end
  end

  context "cas" do
    def stubby(stub_response, use_mock = true)
      cas_client = use_mock ? stub_everything(:cas_client) : controller.cas_client
      cas_client.instance_variable_set(:@stub_response, stub_response)
      def cas_client.validate_service_ticket(st)
        st.response = CASClient::ValidationResponse.new(@stub_response)
      end
      PseudonymSessionsController.any_instance.stubs(:cas_client).returns(cas_client) if use_mock
    end

    it "should scope logins to the correct domain root account" do
      unique_id = 'foo@example.com'

      account1 = account_with_cas
      user1 = user_with_pseudonym({:active_all => true, :username => unique_id})
      @pseudonym.account = account1
      @pseudonym.save!

      account2 = account_with_cas
      user2 = user_with_pseudonym({:active_all => true, :username => unique_id})
      @pseudonym.account = account2
      @pseudonym.save!

      stubby("yes\n#{unique_id}\n")

      controller.request.env['canvas.domain_root_account'] = account1
      get 'new', :ticket => 'ST-abcd'
      response.should redirect_to(dashboard_url(:login_success => 1))
      session[:cas_session].should == 'ST-abcd'
      Pseudonym.find(session['pseudonym_credentials_id']).should == user1.pseudonyms.first

      (controller.instance_variables.grep(/@[^_]/) - ['@mock_proxy']).each{ |var| controller.send :remove_instance_variable, var }
      CANVAS_RAILS2 ? session.reset : session.clear

      stubby("yes\n#{unique_id}\n")

      controller.request.env['canvas.domain_root_account'] = account2
      get 'new', :ticket => 'ST-efgh'
      response.should redirect_to(dashboard_url(:login_success => 1))
      session[:cas_session].should == 'ST-efgh'
      Pseudonym.find(session['pseudonym_credentials_id']).should == user2.pseudonyms.first
    end
  end

  context "otp login cookie" do
    before do
      Account.default.settings[:mfa_settings] = :required
      Account.default.save!

      user_with_pseudonym(:active_all => 1, :password => 'qwerty')
      @user.otp_secret_key = ROTP::Base32.random_base32
      @user.save!
    end

    it "should skip otp verification for a valid cookie" do
      cookies['canvas_otp_remember_me'] = @user.otp_secret_key_remember_me_cookie(Time.now.utc)
      post 'create', :pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwerty' }
      response.should redirect_to dashboard_url(:login_success => 1)
    end

    it "should ignore a bogus cookie" do
      cookies['canvas_otp_remember_me'] = 'bogus'
      post 'create', :pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwerty' }
      response.should render_template('otp_login')
    end

    it "should ignore an expired cookie" do
      cookies['canvas_otp_remember_me'] = @user.otp_secret_key_remember_me_cookie(6.months.ago)
      post 'create', :pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwerty' }
      response.should render_template('otp_login')
    end

    it "should ignore a cookie from an old secret_key" do
      cookies['canvas_otp_remember_me'] = @user.otp_secret_key_remember_me_cookie(6.months.ago)

      @user.otp_secret_key = ROTP::Base32.random_base32
      @user.save!

      post 'create', :pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwerty' }
      response.should render_template('otp_login')
    end
  end

  describe 'create' do
    context 'otp' do
      it "should show enrollment for unenrolled, required user" do
        Account.default.settings[:mfa_settings] = :required
        Account.default.save!

        user_with_pseudonym(:active_all => 1, :password => 'qwerty')
        post 'create', :pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwerty' }
        response.should render_template('otp_login')
        session[:pending_otp_secret_key].should_not be_nil
      end

      it "should ask for verification of enrolled, optional user" do
        Account.default.settings[:mfa_settings] = :optional
        Account.default.save!

        user_with_pseudonym(:active_all => 1, :password => 'qwerty')
        @user.otp_secret_key = ROTP::Base32.random_base32
        @user.save!

        post 'create', :pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwerty' }
        response.should render_template('otp_login')
        session[:pending_otp_secret_key].should be_nil
      end

      it "should not ask for verification of unenrolled, optional user" do
        Account.default.settings[:mfa_settings] = :optional
        Account.default.save!

        user_with_pseudonym(:active_all => 1, :password => 'qwerty')

        post 'create', :pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwerty' }
        response.should redirect_to dashboard_url(:login_success => 1)
      end

      it "should send otp to sms channel" do
        CommunicationChannel.any_instance.expects(:send_otp!).once

        Account.default.settings[:mfa_settings] = :required
        Account.default.save!

        user_with_pseudonym(:active_all => 1, :password => 'qwerty')
        @user.otp_secret_key = ROTP::Base32.random_base32
        cc = @user.otp_communication_channel = @user.communication_channels.sms.create!(:path => 'bob')
        @user.save!

        post 'create', :pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwerty' }
        response.should render_template('otp_login')
        session[:pending_otp_secret_key].should be_nil
        assigns[:cc].should == cc
      end
    end
  end

  describe 'otp_login' do
    before do
      Account.default.settings[:mfa_settings] = :required
      Account.default.save!

      user_with_pseudonym(:active_all => 1, :password => 'qwerty')
    end

    context "verification" do
      before do
        CommunicationChannel.any_instance.expects(:send_otp!).never

        @user.otp_secret_key = ROTP::Base32.random_base32
        @user.save!
        user_session(@user, @pseudonym)
        session[:pending_otp] = true
      end

      it "should verify a code" do
        code = ROTP::TOTP.new(@user.otp_secret_key).now
        post 'otp_login', :otp_login => { :verification_code => code }
        response.should redirect_to dashboard_url(:login_success => 1)
        cookies['canvas_otp_remember_me'].should be_nil
        Canvas.redis.get("otp_used:#{code}").should == '1' if Canvas.redis_enabled?
      end

      it "should set a cookie" do
        post 'otp_login', :otp_login => { :verification_code => ROTP::TOTP.new(@user.otp_secret_key).now, :remember_me => '1' }
        response.should redirect_to dashboard_url(:login_success => 1)
        cookies['canvas_otp_remember_me'].should_not be_nil
      end

      it "should fail for an incorrect token" do
        post 'otp_login', :otp_login => { :verification_code => '123456' }
        response.should render_template('otp_login')
      end

      it "should allow 30 seconds of drift by default" do
        ROTP::TOTP.any_instance.expects(:verify_with_drift).with('123456', 30).once.returns(false)
        post 'otp_login', :otp_login => { :verification_code => '123456' }
        response.should render_template('otp_login')
        assigns[:cc].should be_nil
      end

      it "should allow 5 minutes of drift for SMS" do
        cc = @user.otp_communication_channel = @user.communication_channels.sms.create!(:path => 'bob')
        @user.save!

        ROTP::TOTP.any_instance.expects(:verify_with_drift).with('123456', 300).once.returns(false)
        post 'otp_login', :otp_login => { :verification_code => '123456' }
        response.should render_template('otp_login')
        assigns[:cc].should == cc
      end

      it "should not allow the same code to be used multiple times" do
        pending "needs redis" unless Canvas.redis_enabled?

        Canvas.redis.set("otp_used:123456", '1')
        ROTP::TOTP.any_instance.expects(:verify_with_drift).never
        post 'otp_login', :otp_login => { :verification_code => '123456' }
        response.should render_template('otp_login')

      end
    end

    context "enrollment" do
      before do
        user_session(@user, @pseudonym)
      end

      it "should generate a secret key" do
        get 'otp_login'
        session[:pending_otp_secret_key].should_not be_nil
        @user.reload.otp_secret_key.should be_nil
      end

      it "should generate a new secret key for re-enrollment" do
        @user.otp_secret_key = ROTP::Base32.random_base32
        @user.save!

        get 'otp_login'
        session[:pending_otp_secret_key].should_not be_nil
        session[:pending_otp_secret_key].should_not == @user.reload.otp_secret_key
      end

      context "selecting sms" do
        it "should send a message to an existing channel" do
          @cc = @user.communication_channels.sms.create!(:path => 'bob')
          @cc.any_instantiation.expects(:send_otp!).once
          post 'otp_login', :otp_login => { :otp_communication_channel_id => @cc.id }
          response.should render_template('otp_login')
          session[:pending_otp_communication_channel_id].should == @cc.id
          assigns[:cc].should == @cc
        end

        it "should create a new channel" do
          CommunicationChannel.any_instance.expects(:send_otp!).once
          post 'otp_login', :otp_login => { :phone_number => '(800) 555-5555', :carrier => 'instructure.com' }
          response.should render_template('otp_login')
          @cc = @user.communication_channels.sms.first
          @cc.should be_unconfirmed
          @cc.path.should == '8005555555@instructure.com'
          session[:pending_otp_communication_channel_id].should == @cc.id
          assigns[:cc].should == @cc
        end

        it "should re-use an existing channel" do
          @cc = @user.communication_channels.sms.create!(:path => '8005555555@instructure.com')
          @cc.any_instantiation.expects(:send_otp!).once
          post 'otp_login', :otp_login => { :phone_number => '(800) 555-5555', :carrier => 'instructure.com' }
          response.should render_template('otp_login')
          session[:pending_otp_communication_channel_id].should == @cc.id
          assigns[:cc].should == @cc
        end

        it "should re-use an existing retired channel" do
          @cc = @user.communication_channels.sms.create!(:path => '8005555555@instructure.com')
          @cc.retire!
          @cc.any_instantiation.expects(:send_otp!).once
          post 'otp_login', :otp_login => { :phone_number => '(800) 555-5555', :carrier => 'instructure.com' }
          response.should render_template('otp_login')
          @cc.should be_unconfirmed
          session[:pending_otp_communication_channel_id].should == @cc.id
          assigns[:cc].should == @cc
        end
      end

      context "verification" do
        before do
          @secret_key = session[:pending_otp_secret_key] = ROTP::Base32.random_base32
        end

        it "should save the pending key" do
          @user.otp_communication_channel_id = @user.communication_channels.sms.create!(:path => 'bob')

          post 'otp_login', :otp_login => { :verification_code => ROTP::TOTP.new(@secret_key).now }
          response.should redirect_to settings_profile_url
          @user.reload.otp_secret_key.should == @secret_key
          @user.otp_communication_channel.should be_nil

          session[:pending_otp_secret_key].should be_nil
        end

        it "should continue to the dashboard if part of the login flow" do
          session[:pending_otp] = true
          post 'otp_login', :otp_login => { :verification_code => ROTP::TOTP.new(@secret_key).now }
          response.should redirect_to dashboard_url(:login_success => 1)
          session[:pending_otp].should be_nil
        end

        it "should save a pending sms" do
          @cc = @user.communication_channels.sms.create!(:path => 'bob')
          session[:pending_otp_communication_channel_id] = @cc.id
          code = ROTP::TOTP.new(@secret_key).now
          # make sure we get 5 minutes of drift
          ROTP::TOTP.any_instance.expects(:verify_with_drift).with(code.to_s, 300).once.returns(true)
          post 'otp_login', :otp_login => { :verification_code => code.to_s }
          response.should redirect_to settings_profile_url
          @user.reload.otp_secret_key.should == @secret_key
          @user.otp_communication_channel.should == @cc
          @cc.reload.should be_active
          session[:pending_otp_secret_key].should be_nil
          session[:pending_otp_communication_channel_id].should be_nil
        end

        it "shouldn't fail if the sms is already active" do
          @cc = @user.communication_channels.sms.create!(:path => 'bob')
          @cc.confirm!
          session[:pending_otp_communication_channel_id] = @cc.id
          post 'otp_login', :otp_login => { :verification_code => ROTP::TOTP.new(@secret_key).now }
          response.should redirect_to settings_profile_url
          @user.reload.otp_secret_key.should == @secret_key
          @user.otp_communication_channel.should == @cc
          @cc.reload.should be_active
          session[:pending_otp_secret_key].should be_nil
          session[:pending_otp_communication_channel_id].should be_nil
        end
      end
    end
  end

  describe 'disable_otp_login' do
    before do
      Account.default.settings[:mfa_settings] = :optional
      Account.default.save!

      user_with_pseudonym(:active_all => 1, :password => 'qwerty')
      @user.otp_secret_key = ROTP::Base32.random_base32
      @user.otp_communication_channel = @user.communication_channels.sms.create!(:path => 'bob')
      @user.save!
      user_session(@user)
    end

    it "should delete self" do
      post 'disable_otp_login', :user_id => 'self'
      response.should be_success
      @user.reload.otp_secret_key.should be_nil
      @user.otp_communication_channel.should be_nil
    end

    it "should delete self as id" do
      post 'disable_otp_login', :user_id => @user.id
      response.should be_success
      @user.reload.otp_secret_key.should be_nil
      @user.otp_communication_channel.should be_nil
    end

    it "should not be able to delete self if required" do
      Account.default.settings[:mfa_settings] = :required
      Account.default.save!
      post 'disable_otp_login', :user_id => 'self'
      response.should_not be_success
      @user.reload.otp_secret_key.should_not be_nil
      @user.otp_communication_channel.should_not be_nil
    end

    it "should not be able to delete self as id if required" do
      Account.default.settings[:mfa_settings] = :required
      Account.default.save!
      post 'disable_otp_login', :user_id => @user.id
      response.should_not be_success
      @user.reload.otp_secret_key.should_not be_nil
      @user.otp_communication_channel.should_not be_nil
    end

    it "should not be able to delete another user" do
      @other_user = @user
      @admin = user_with_pseudonym(:active_all => 1, :unique_id => 'user2')
      user_session(@admin)
      post 'disable_otp_login', :user_id => @other_user.id
      response.should_not be_success
      @other_user.reload.otp_secret_key.should_not be_nil
      @other_user.otp_communication_channel.should_not be_nil
    end

    it "should be able to delete another user as admin" do
      # even if required
      Account.default.settings[:mfa_settings] = :required
      Account.default.save!

      @other_user = @user
      @admin = user_with_pseudonym(:active_all => 1, :unique_id => 'user2')
      Account.default.add_user(@admin)
      user_session(@admin)
      post 'disable_otp_login', :user_id => @other_user.id
      response.should be_success
      @other_user.reload.otp_secret_key.should be_nil
      @other_user.otp_communication_channel.should be_nil
    end
  end

  describe 'GET oauth2_auth' do
    let(:key) { DeveloperKey.create! :redirect_uri => 'https://example.com' }
    let(:user) { User.create! }

    it 'renders a 400 when there is no client_id' do
      get :oauth2_auth
      assert_status(400)
      response.body.should =~ /invalid client_id/
    end

    it 'renders 400 on a bad redirect_uri' do
      get :oauth2_auth, :client_id => key.id
      assert_status(400)
      response.body.should =~ /invalid redirect_uri/
    end

    it 'redirects to the login url' do
      get :oauth2_auth, :client_id => key.id, :redirect_uri => Canvas::Oauth::Provider::OAUTH2_OOB_URI
      response.should redirect_to(login_url)
    end

    it 'passes on canvas_login if provided' do
      get :oauth2_auth, :client_id => key.id, :redirect_uri => Canvas::Oauth::Provider::OAUTH2_OOB_URI, :canvas_login => 1
      response.should redirect_to(login_url(:canvas_login => 1))
    end
  end

  describe 'GET oauth2_token' do
    let(:key) { DeveloperKey.create! }
    let(:user) { User.create! }
    let(:valid_code) {"thecode"}
    let(:valid_code_redis_key) {"#{Canvas::Oauth::Token::REDIS_PREFIX}#{valid_code}"}
    let(:redis) do
      redis = stub('Redis')
      redis.stubs(:get)
      redis.stubs(:get).with(valid_code_redis_key).returns(%Q{{"client_id": #{key.id}, "user": #{user.id}}})
      redis.stubs(:del).with(valid_code_redis_key).returns(%Q{{"client_id": #{key.id}, "user": #{user.id}}})
      redis
    end

    it 'renders a 400 if theres no client_id' do
      get :oauth2_token
      assert_status(400)
      response.body.should =~ /invalid client_id/
    end

    it 'renders a 400 if the secret is invalid' do
      get :oauth2_token, :client_id => key.id, :client_secret => key.api_key + "123"
      assert_status(400)
      response.body.should =~ /invalid client_secret/
    end

    it 'renders a 400 if the provided code does not match a token' do
      Canvas.stubs(:redis => redis)
      get :oauth2_token, :client_id => key.id, :client_secret => key.api_key, :code => "NotALegitCode"
      assert_status(400)
      response.body.should =~ /invalid code/
    end

    it 'outputs the token json if everything checks out' do
      redis.expects(:del).with(valid_code_redis_key).at_least_once
      Canvas.stubs(:redis => redis)
      get :oauth2_token, :client_id => key.id, :client_secret => key.api_key, :code => valid_code
      response.should be_success
      JSON.parse(response.body).keys.sort.should == ['access_token', 'user']
    end
  end

  describe 'POST oauth2_accept' do
    let(:user) { User.create! }
    let(:key) { DeveloperKey.create! }
    let(:session_hash) { { :oauth2 => { :client_id => key.id, :redirect_uri => Canvas::Oauth::Provider::OAUTH2_OOB_URI  } } }
    let(:oauth_accept) { post :oauth2_accept, {}, session_hash }

    before { user_session user }

    it 'uses the global id of the user for generating the code' do
      Canvas::Oauth::Token.expects(:generate_code_for).with(user.global_id, key.id, {:scopes => nil, :remember_access => nil, :purpose => nil}).returns('code')
      oauth_accept
      response.should redirect_to(oauth2_auth_url(:code => 'code'))
    end

    it 'saves the requested scopes with the code' do
      scopes = 'userinfo'
      session_hash[:oauth2][:scopes] = scopes
      Canvas::Oauth::Token.expects(:generate_code_for).with(user.global_id, key.id, {:scopes => scopes, :remember_access => nil, :purpose => nil}).returns('code')
      oauth_accept
    end

    it 'remembers the users access preference with the code' do
      Canvas::Oauth::Token.expects(:generate_code_for).with(user.global_id, key.id, {:scopes => nil, :remember_access => '1', :purpose => nil}).returns('code')
      post :oauth2_accept, {:remember_access => '1'}, session_hash
    end

    it 'removes oauth session info after code generation' do
      Canvas::Oauth::Token.stubs(:generate_code_for => 'code')
      oauth_accept
      controller.session[:oauth2].should be_nil
    end

    it 'forwards the oauth state if it was provided' do
      session_hash[:oauth2][:state] = '1234567890'
      Canvas::Oauth::Token.stubs(:generate_code_for => 'code')
      oauth_accept
      response.should redirect_to(oauth2_auth_url(:code => 'code', :state => '1234567890'))
    end

  end
end
