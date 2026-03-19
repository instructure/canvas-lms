# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../feature_flag_helper"

describe BrandConfigsController do
  include FeatureFlagHelper

  before :once do
    @account = Account.default
    @bc = BrandConfig.create(variables: { "ic-brand-primary" => "#321" })
  end

  describe "#index" do
    it "allows authorized admin to view" do
      admin = account_admin_user(account: @account)
      user_session(admin)
      get "index", params: { account_id: @account.id }
      assert_status(200)
    end

    it "does not allow non admin access" do
      user = user_with_pseudonym(active_all: true)
      user_session(user)
      get "index", params: { account_id: @account.id }
      assert_status(401)
    end

    it "requires branding enabled on the account" do
      subaccount = @account.sub_accounts.create!(name: "sub")
      admin = account_admin_user(account: @account)
      user_session(admin)
      get "index", params: { account_id: subaccount.id }
      assert_status(302)
      expect(flash[:error]).to match(/cannot edit themes/)
    end
  end

  describe "#new" do
    it "allows authorized admin to see create" do
      admin = account_admin_user(account: @account)
      user_session(admin)
      get "new", params: { brand_config: @bc, account_id: @account.id }
      assert_status(200)
    end

    it "does not allow non admin access" do
      user = user_with_pseudonym(active_all: true)
      user_session(user)
      get "new", params: { brand_config: @bc, account_id: @account.id }
      assert_status(401)
    end

    it "creates variableSchema based on parent configs" do
      @account.brand_config_md5 = @bc.md5
      @account.settings = { global_includes: true, sub_account_includes: true }
      @account.save!

      @subaccount = Account.create!(parent_account: @account)
      @sub_bc = BrandConfig.create(variables: { "ic-brand-global-nav-bgd" => "#123" }, parent_md5: @bc.md5)
      @subaccount.brand_config_md5 = @sub_bc.md5
      @subaccount.save!

      admin = account_admin_user(account: @subaccount)
      user_session(admin)

      get "new", params: { brand_config: @sub_bc, account_id: @subaccount.id }

      variable_schema = assigns[:js_env][:variableSchema]
      variable_schema.each do |s|
        expect(s["group_name"]).to be_present
      end

      vars = variable_schema.pluck("variables").flatten
      vars.each do |v|
        expect(v["human_name"]).to be_present
      end

      expect(vars.detect { |v| v["variable_name"] == "ic-brand-header-image" }["helper_text"]).to be_present

      primary = vars.detect { |v| v["variable_name"] == "ic-brand-primary" }
      expect(primary["default"]).to eq "#321"
    end

    context "with login brand config filter" do
      let_once(:admin) { account_admin_user(account: @account) }

      before do
        user_session(admin)
      end

      it "always calls the login brand config filter with variable schema and account" do
        expect(Login::LoginBrandConfigFilter).to receive(:filter).with(instance_of(Array), @account).and_call_original
        get "new", params: { brand_config: @bc, account_id: @account.id }
        assert_status(200)
      end

      it "filter handles feature flag logic internally" do
        mock_feature_flag(:login_registration_ui_identity, false, [@account])
        expect(Login::LoginBrandConfigFilter).to receive(:filter).with(instance_of(Array), @account).and_call_original
        get "new", params: { brand_config: @bc, account_id: @account.id }
        assert_status(200)
      end
    end
  end

  describe "#create" do
    let_once(:admin) { account_admin_user(account: @account) }
    let(:bcin) { { variables: { "ic-brand-primary" => "#000000" } } }

    it "allows authorized admin to create" do
      user_session(admin)
      post "create", params: { account_id: @account.id, brand_config: bcin }
      assert_status(200)
      json = response.parsed_body
      expect(json["brand_config"]["variables"]["ic-brand-primary"]).to eq "#000000"
    end

    it "does not fail when a brand_config is not passed" do
      user_session(admin)
      post "create", params: { account_id: @account.id }
      assert_status(200)
    end

    it "does not allow non admin access" do
      user = user_with_pseudonym(active_all: true)
      user_session(user)
      post "create", params: { account_id: @account.id, brand_config: bcin }
      assert_status(401)
    end

    it "returns an existing brand config" do
      user_session(admin)
      post "create", params: { account_id: @account.id,
                               brand_config: {
                                 variables: {
                                   "ic-brand-primary" => "#321"
                                 }
                               } }
      assert_status(200)
      json = response.parsed_body
      expect(json["brand_config"]["md5"]).to eq @bc.md5
    end

    it "uploads a js file successfully" do
      user_session(admin)
      tf = Tempfile.new("test.js")
      tf.write("test")
      uf = ActionDispatch::Http::UploadedFile.new(tempfile: tf, filename: "test.js")
      request.headers["CONTENT_TYPE"] = "multipart/form-data"
      expect_any_instance_of(Attachment).to receive(:save_to_storage).and_return(true)

      post "create", params: { account_id: @account.id, brand_config: bcin, js_overrides: uf }
      assert_status(200)

      json = response.parsed_body
      expect(json["brand_config"]["js_overrides"]).to be_present
    end

    context "textarea variable processing" do
      it "sanitizes XSS attempts in textarea values" do
        user_session(admin)
        post "create", params: {
          account_id: @account.id,
          brand_config: {
            variables: {
              "ic-brand-Login-custom-message" => "<script>alert('xss')</script>Hello"
            }
          }
        }
        json = response.parsed_body
        expect(json["brand_config"]["variables"]["ic-brand-Login-custom-message"]).to eq("Hello")
      end

      it "sanitizes event handlers in textarea values" do
        user_session(admin)
        post "create", params: {
          account_id: @account.id,
          brand_config: {
            variables: {
              "ic-brand-Login-custom-message" => "<img src=x onerror=\"alert(1)\">"
            }
          }
        }
        json = response.parsed_body
        expect(json["brand_config"]["variables"]["ic-brand-Login-custom-message"]).not_to include("<img")
        expect(json["brand_config"]["variables"]["ic-brand-Login-custom-message"]).not_to include("onerror")
      end

      it "rejects textarea values exceeding 500 characters" do
        user_session(admin)
        long_text = "a" * 501
        post "create", params: {
          account_id: @account.id,
          brand_config: {
            variables: {
              "ic-brand-Login-custom-message" => long_text
            }
          }
        }
        expect(response).to have_http_status(:bad_request)
      end

      it "rejects textarea values with control characters" do
        user_session(admin)
        post "create", params: {
          account_id: @account.id,
          brand_config: {
            variables: {
              "ic-brand-Login-custom-message" => "test\x00value"
            }
          }
        }
        expect(response).to have_http_status(:bad_request)
      end

      it "preserves legitimate textarea content" do
        user_session(admin)
        text = "Welcome to our login page!\nPlease sign in."
        post "create", params: {
          account_id: @account.id,
          brand_config: {
            variables: {
              "ic-brand-Login-custom-message" => text
            }
          }
        }
        json = response.parsed_body
        expect(json["brand_config"]["variables"]["ic-brand-Login-custom-message"]).to eq(text)
      end

      it "accepts textarea values at exactly 500 characters" do
        user_session(admin)
        exact_text = "a" * 500
        post "create", params: {
          account_id: @account.id,
          brand_config: {
            variables: {
              "ic-brand-Login-custom-message" => exact_text
            }
          }
        }
        json = response.parsed_body
        expect(json["brand_config"]["variables"]["ic-brand-Login-custom-message"].length).to eq(500)
        expect(json["brand_config"]["variables"]["ic-brand-Login-custom-message"]).to eq(exact_text)
      end

      it "rejects other control characters in the range" do
        user_session(admin)
        # test various control characters: \x01, \x08, \x0B (vertical tab), \x0C (form feed), \x0E-\x1F, \x7F (DEL)
        ["\x01", "\x08", "\x0B", "\x0C", "\x0E", "\x1F", "\x7F"].each do |control_char|
          post "create", params: {
            account_id: @account.id,
            brand_config: {
              variables: {
                "ic-brand-Login-custom-message" => "test#{control_char}value"
              }
            }
          }
          expect(response).to have_http_status(:bad_request)
        end
      end

      it "preserves tabs in textarea content" do
        user_session(admin)
        text = "Line 1\tTabbed\tText"
        post "create", params: {
          account_id: @account.id,
          brand_config: {
            variables: {
              "ic-brand-Login-custom-message" => text
            }
          }
        }
        json = response.parsed_body
        expect(json["brand_config"]["variables"]["ic-brand-Login-custom-message"]).to eq(text)
        expect(json["brand_config"]["variables"]["ic-brand-Login-custom-message"]).to include("\t")
      end

      it "normalizes line endings in textarea content" do
        user_session(admin)
        text = "Line 1\r\nLine 2"
        post "create", params: {
          account_id: @account.id,
          brand_config: {
            variables: {
              "ic-brand-Login-custom-message" => text
            }
          }
        }
        json = response.parsed_body
        # Sanitize.clean normalizes \r\n to \n
        expect(json["brand_config"]["variables"]["ic-brand-Login-custom-message"]).to eq("Line 1\nLine 2")
      end

      it "handles textarea values that become empty after sanitization" do
        user_session(admin)
        post "create", params: {
          account_id: @account.id,
          brand_config: {
            variables: {
              "ic-brand-Login-custom-message" => "<script></script>"
            }
          }
        }
        json = response.parsed_body
        expect(json["brand_config"]["variables"]["ic-brand-Login-custom-message"]).to eq("")
      end

      it "rejects oversized content even after sanitization" do
        user_session(admin)
        # 501 'a's wrapped in <b> tags - still over limit after tag removal
        long_html = "<b>#{"a" * 501}</b>"
        post "create", params: {
          account_id: @account.id,
          brand_config: {
            variables: {
              "ic-brand-Login-custom-message" => long_html
            }
          }
        }
        expect(response).to have_http_status(:bad_request)
      end

      it "sanitizes multiple XSS vectors" do
        user_session(admin)
        xss_payload = '<script>alert(1)</script><img src=x onerror="alert(2)"><a href="javascript:alert(3)">click</a>Hello'
        post "create", params: {
          account_id: @account.id,
          brand_config: {
            variables: {
              "ic-brand-Login-custom-message" => xss_payload
            }
          }
        }
        json = response.parsed_body
        result = json["brand_config"]["variables"]["ic-brand-Login-custom-message"]
        expect(result).to eq("clickHello")
        expect(result).not_to include("<script")
        expect(result).not_to include("<img")
        expect(result).not_to include("onerror")
        expect(result).not_to include("javascript:")
      end

      it "sanitizes HTML entities and special characters" do
        user_session(admin)
        text = "Test &lt;script&gt;alert('xss')&lt;/script&gt; &amp; more"
        post "create", params: {
          account_id: @account.id,
          brand_config: {
            variables: {
              "ic-brand-Login-custom-message" => text
            }
          }
        }
        json = response.parsed_body
        # FullSanitizer strips tags but preserves HTML entities
        expect(json["brand_config"]["variables"]["ic-brand-Login-custom-message"]).to include("&")
      end

      it "handles mixed content with newlines and HTML" do
        user_session(admin)
        text = "Welcome!\n<script>alert('xss')</script>\nPlease login."
        post "create", params: {
          account_id: @account.id,
          brand_config: {
            variables: {
              "ic-brand-Login-custom-message" => text
            }
          }
        }
        json = response.parsed_body
        result = json["brand_config"]["variables"]["ic-brand-Login-custom-message"]
        expect(result).to eq("Welcome!\n\nPlease login.")
        expect(result).not_to include("<script")
      end
    end
  end

  describe "#destroy" do
    it "allows authorized admin to create" do
      admin = account_admin_user(account: @account)
      user_session(admin)
      session[:brand_config] = { md5: @bc.md5, type: :base }
      delete "destroy", params: { account_id: @account.id }
      assert_status(302)
      expect(session[:brand_config]).to be_nil
      expect { @bc.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not allow non admin access" do
      user = user_with_pseudonym(active_all: true)
      user_session(user)
      delete "destroy", params: { account_id: @account.id }
      assert_status(401)
    end
  end

  describe "#save_to_account" do
    it "allows authorized admin to create" do
      admin = account_admin_user(account: @account)
      user_session(admin)
      post "save_to_account", params: { account_id: @account.id }
      assert_status(200)
    end

    it "regenerates sub accounts" do
      subbc = BrandConfig.create(variables: { "ic-brand-primary" => "#111" })
      @account.sub_accounts.create!(name: "Sub", brand_config_md5: subbc.md5)

      admin = account_admin_user(account: @account)
      user_session(admin)
      session[:brand_config] = { md5: @bc.md5, type: :base }
      post "save_to_account", params: { account_id: @account.id }
      assert_status(200)
      json = response.parsed_body
      expect(json["subAccountProgresses"]).to be_present
    end

    it "does not allow non admin access" do
      user = user_with_pseudonym(active_all: true)
      user_session(user)
      post "save_to_account", params: { account_id: @account.id }
      assert_status(401)
    end
  end

  describe "#save_to_user_session" do
    it "allows authorized admin to create" do
      admin = account_admin_user(account: @account)
      user_session(admin)
      post "save_to_user_session", params: { account_id: @account.id, brand_config_md5: @bc.md5 }
      assert_status(302)
      expect(session[:brand_config]).to eq({ md5: @bc.md5, type: :base })
    end

    it "allows authorized admin to remove" do
      admin = account_admin_user(account: @account)
      user_session(admin)
      session[:brand_config] = { md5: @bc.md5, type: :base }
      post "save_to_user_session", params: { account_id: @account.id, brand_config_md5: "" }
      assert_status(302)
      expect(session[:brand_config]).to eq({ md5: nil, type: :default })
      expect { @bc.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not allow non admin access" do
      user = user_with_pseudonym(active_all: true)
      user_session(user)
      post "save_to_user_session", params: { account_id: @account.id, brand_config_md5: @bc.md5 }
      assert_status(401)
      expect(session[:brand_config]).to be_nil
    end
  end
end
