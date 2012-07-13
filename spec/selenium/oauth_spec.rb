require File.expand_path(File.dirname(__FILE__) + '/common')


describe "oauth2 flow" do
  it_should_behave_like "in-process server selenium tests"

  before do
    @key = DeveloperKey.create!(:name => 'Specs')
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
        f('#modal-box').text.should match(%r{Specs is requesting access to your account})
        expect_new_page_load { f('#modal-box a.btn-primary').click() }
        driver.current_url.should match(%r{/login/oauth2/auth\?})
        code = driver.current_url.match(%r{code=([^\?&]+)})[1]
        code.should be_present
      end
      
    end
  
    describe "a non-logged-in user" do
      before do
        course_with_student(:active_all => true, :user => user_with_pseudonym)
      end
  
      it "should show the confirmation dialog after logging in" do
        get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
        driver.current_url.should match(%r{/login$})
        user_element = driver.find_element(:css, '#pseudonym_session_unique_id')
        user_element.send_keys("nobody@example.com")
        password_element = driver.find_element(:css, '#pseudonym_session_password')
        password_element.send_keys("asdfasdf")
        password_element.submit
        f('#modal-box').text.should match(%r{Specs is requesting access to your account})
        expect_new_page_load { f('#modal-box a.btn-primary').click() }
        driver.current_url.should match(%r{/login/oauth2/auth\?})
        code = driver.current_url.match(%r{code=([^\?&]+)})[1]
        code.should be_present
      end    
    end
  end

  describe "oauth2 tool icons" do
    it_should_behave_like "in-process server selenium tests"
    before do
      course_with_student_logged_in(:active_all => true)
    end
  
    it "should show no icon if icon_url is not set on the developer key" do
      get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
      f('#modal-box').text.should match(%r{Specs is requesting access to your account})
      f('.icon_url').should be_nil
    end
    
    it "should show the developer key's icon if icon_url is set" do
      @key.icon_url = "/images/delete.png"
      @key.save!
      get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
      f('#modal-box').text.should match(%r{Specs is requesting access to your account})
      f('.icon_url').should_not be_nil
      f('.icon_url').should be_displayed
    end
  end
end

