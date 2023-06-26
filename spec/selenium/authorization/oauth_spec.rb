# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../common"

describe "oauth2 flow" do
  include_context "in-process server selenium tests"

  before do
    @key = DeveloperKey.create!(name: "Specs", redirect_uri: "http://www.example.com")
    enable_developer_key_account_binding!(@key)
    @client_id = @key.id
    @client_secret = @key.api_key
  end

  if Canvas.redis_enabled?
    def oauth_login_fill_out_form
      expect(driver.current_url).to match(%r{/login/canvas$})
      user_element = f("#pseudonym_session_unique_id")
      user_element.send_keys("nobody@example.com")
      password_element = f("#pseudonym_session_password")
      password_element.send_keys("asdfasdf")
      password_element.submit
    end

    describe "a logged-in user" do
      before do
        course_with_student_logged_in(active_all: true)
      end

      it "shows the confirmation dialog without requiring login" do
        get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
        expect(f("#modal-box").text).to match(/Specs is requesting access to your account/)
        expect_new_page_load { f("#modal-box .Button--primary").click }
        expect(driver.current_url).to match(%r{/login/oauth2/auth\?})
        code = driver.current_url.match(/code=([^?&]+)/)[1]
        expect(code).to be_present
      end
    end

    describe "a non-logged-in user" do
      before do
        course_with_student(active_all: true, user: user_with_pseudonym)
      end

      it "shows the terms of use and then confirmation dialog after logging in" do
        get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
        oauth_login_fill_out_form
        form = f(".reaccept_terms")
        expect(form).to be_present
        expect_new_page_load do
          f('[name="user[terms_of_use]"]').click
          submit_form form
        end
        expect(f("#modal-box").text).to match(/Specs is requesting access to your account/)
        expect_new_page_load { f("#modal-box .Button--primary").click }
        expect(driver.current_url).to match(%r{/login/oauth2/auth\?})
        code = driver.current_url.match(/code=([^?&]+)/)[1]
        expect(code).to be_present
      end
    end
  end

  describe "oauth2 tool icons" do
    include_context "in-process server selenium tests"
    before do
      course_with_student_logged_in(active_all: true)
    end

    it "shows no icon if icon_url is not set on the developer key" do
      get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
      expect(f("#modal-box").text).to match(/Specs is requesting access to your account/)
      expect(f("#content")).not_to contain_css(".icon_url")
    end

    it "shows the developer keys icon if icon_url is set" do
      @key.icon_url = "/images/delete.png"
      @key.save!
      get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
      expect(f("#modal-box").text).to match(/Specs is requesting access to your account/)
      expect(f(".ic-Login-confirmation__auth-icon")).to be_displayed
    end

    it "shows remember authorization checkbox only for 'auth/userinfo' scoped token requests" do
      get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=http%3A%2F%2Fwww.example.com&scopes=%2Fauth%2Fuserinfo"
      expect(f("#remember_access")).to be_displayed
    end

    it "does not show remember authorization checkbox for unscoped requests" do
      get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=http%3A%2F%2Fwww.example.com"
      expect(f("#content")).not_to contain_css("#remember_access")
    end

    it "does not show remember authorization checkbox for other scope requests" do
      get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=http%3A%2F%2Fwww.example.com&scopes=url%3AGET%7C%2Fapi%2Fv1%2Faccounts"
      expect(f("#content")).not_to contain_css("#remember_access")
    end

    it "does not let developer keys expire if remember me was checked" do
      expiring_key = DeveloperKey.create!(
        name: "IExpire",
        redirect_uri: "http://www.example.com",
        auto_expire_tokens: true
      )
      enable_developer_key_account_binding!(expiring_key)
      redirect_uri = "http://www.example.com&scopes=/auth/userinfo"
      get "/login/oauth2/auth?response_type=code&client_id=#{expiring_key.id}&redirect_uri=#{redirect_uri}"
      f("#remember_access").click
      f("input[type=submit]").click
      f("body") # wait until the redirect page loads

      code = driver.current_url.match(/code=([^?&]+)/)[1]
      integration_test = ActionDispatch::IntegrationTest.new(self)
      integration_test.post "/login/oauth2/token", params: {
        grant_type: "authorization_code",
        client_id: expiring_key.id,
        client_secret: expiring_key.api_key,
        redirect_uri:,
        code:,
      }
      expect(AccessToken.last.permanent_expires_at).to be_nil
    end

    context "when the using the Commons developer key" do
      before { Setting.set("commons_developer_key_id", @key.global_id) }

      after { Setting.set("commons_developer_key_id", nil) }

      it "shows a data residency message" do
        get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=http%3A%2F%2Fwww.example.com&scopes=url%3AGET%7C%2Fapi%2Fv1%2Faccounts"
        expect(f("#content")).to include_text("Instructure hosts Canvas Commons in the region chosen by your institution, which is the US")
      end

      it "shows a regional data residency message" do
        @key.update!(redirect_uri: "http://commons.singapore.canvaslms.com")
        get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=http%3A%2F%2Fcommons.singapore.canvaslms.com&scopes=url%3AGET%7C%2Fapi%2Fv1%2Faccounts"
        expect(f("#content")).to include_text("Instructure hosts Canvas Commons in the region chosen by your institution, which is Asia Pacific")
        @key.update!(redirect_uri: "http://www.example.com")
      end
    end

    context "when not using the Commons developer key" do
      before { Setting.set("commons_developer_key_id", @key.global_id + 1) }

      after { Setting.set("commons_developer_key_id", nil) }

      it "does not show a data residency message" do
        get "/login/oauth2/auth?response_type=code&client_id=#{@client_id}&redirect_uri=http%3A%2F%2Fwww.example.com&scopes=url%3AGET%7C%2Fapi%2Fv1%2Faccounts"
        expect(f("#content")).to_not include_text("Instructure hosts Canvas Commons in the region chosen by your institution")
      end
    end
  end
end
