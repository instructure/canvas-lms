require File.expand_path(File.dirname(__FILE__) + '/common')

describe "auth" do
  include_context "in-process server selenium tests"

  describe "logout" do
    it "should present confirmation on GET /logout" do
      user_logged_in
      get "/logout"

      expect_new_page_load {
        f('.Button--logout-confirm').submit()
      }
      expect(driver.current_url).to match %r{/login}
    end
  end
end
