require File.expand_path(File.dirname(__FILE__) + '/common')

describe "auth" do
  include_examples "in-process server selenium tests"

  describe "logout" do
    it "should present confirmation on GET /logout" do
      user_logged_in(real_login: true)
      get "/logout"

      expect_new_page_load { f('#modal-box form input[type=submit]').submit() }
      driver.current_url.should match %r{/login}
    end
  end
end
