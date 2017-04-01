require File.expand_path(File.dirname(__FILE__) + '/common')


describe "oauth2 flow" do
  include_context "in-process server selenium tests"

  before do
    @key = DeveloperKey.create!(:name => 'Specs', :redirect_uri => 'http://www.example.com')
    @client_id = @key.id
    @client_secret = @key.api_key
  end

  if Canvas.redis_enabled?
    describe "a logged-in user" do
      before do
        course_with_student_logged_in(:active_all => true)
      end

      it "should show the confirmation dialog without requiring login" do
        get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
        expect(f('#modal-box').text).to match(%r{Specs is requesting access to your account})
        expect_new_page_load { f('#modal-box .btn-primary').click() }
        expect(driver.current_url).to match(%r{/login/oauth2/auth\?})
        code = driver.current_url.match(%r{code=([^\?&]+)})[1]
        expect(code).to be_present
      end

    end

    describe "a non-logged-in user" do
      before do
        course_with_student(:active_all => true, :user => user_with_pseudonym)
      end

      def oauth_login_fill_out_form
        expect(driver.current_url).to match(%r{/login/canvas$})
        user_element = f('#pseudonym_session_unique_id')
        user_element.send_keys("nobody@example.com")
        password_element = f('#pseudonym_session_password')
        password_element.send_keys("asdfasdf")
        password_element.submit
      end

      it "should show the confirmation dialog after logging in" do
        get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
        oauth_login_fill_out_form
        expect(f('#modal-box').text).to match(%r{Specs is requesting access to your account})
        expect_new_page_load { f('#modal-box .btn-primary').click() }
        expect(driver.current_url).to match(%r{/login/oauth2/auth\?})
        code = driver.current_url.match(%r{code=([^\?&]+)})[1]
        expect(code).to be_present
      end
    end
  end

  describe "oauth2 tool icons" do
    include_context "in-process server selenium tests"
    before do
      course_with_student_logged_in(:active_all => true)
    end

    it "should show no icon if icon_url is not set on the developer key" do
      get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
      expect(f('#modal-box').text).to match(%r{Specs is requesting access to your account})
      expect(f("#content")).not_to contain_css('.icon_url')
    end

    it "should show the developer keys icon if icon_url is set" do
      @key.icon_url = "/images/delete.png"
      @key.save!
      get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
      expect(f('#modal-box').text).to match(%r{Specs is requesting access to your account})
      expect(f('.ic-Login-confirmation__auth-icon')).to be_displayed
    end

    it "should show remember authorization checkbox for scoped token requests" do
      get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=http%3A%2F%2Fwww.example.com&scopes=%2Fauth%2Fuserinfo"
      expect(f('#remember_access')).to be_displayed
    end

    it "should not show remember authorization checkbox for unscoped requests" do
      get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=http%3A%2F%2Fwww.example.com"
      expect(f("#content")).not_to contain_css('#remember_access')
    end
  end
end
