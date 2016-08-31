require_relative 'common'

describe "auth" do
  include_context "in-process server selenium tests"

  describe "logout" do
    it "should present confirmation on GET /logout" do
      user_logged_in
      get "/logout"
      f('.Button--logout-confirm').click
      wait_for_ajaximations

      keep_trying_until {
        expect(driver.current_url).to match %r{/login/canvas}
      }
    end
  end
end
