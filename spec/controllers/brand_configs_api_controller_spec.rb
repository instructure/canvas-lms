# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

describe BrandConfigsApiController do
  describe "#show" do
    it "redirects to the default when nothing is set" do
      get :show
      expect(response).to redirect_to("#{Canvas::Cdn.config.host}/#{BrandableCSS.public_default_path("json")}")
    end

    it "redirects to the one for @domain_root_account's brand config if set" do
      brand_config = Account.default.create_brand_config!(variables: { "ic-brand-primary" => "#321" })
      get :show
      expect(response).to redirect_to("#{Canvas::Cdn.config.host}/#{brand_config.public_json_path}")
    end

    it "sets CORS headers" do
      Account.default.create_brand_config!(variables: { "ic-brand-primary" => "#321" })
      get :show
      expect(response.header["Access-Control-Allow-Origin"]).to eq "*"
    end
  end

  describe "show_context" do
    before :once do
      @account = Account.default
      @account.settings[:sub_account_includes] = true
      @account_config = @account.create_brand_config!(variables: { "ic-brand-primary" => "#111" })
      @account.save!

      @subaccount = @account.sub_accounts.create!
      @subaccount_config = @subaccount.build_brand_config(variables: { "ic-brand-primary" => "#222" })
      @subaccount_config.parent_md5 = @account.brand_config.md5
      @subaccount_config.save!
      @subaccount.save!

      @user = user_factory
    end

    it "redirects to the root account's brand config" do
      user_session(@user)
      get :show_context, params: { account_id: @account.id }
      expect(response).to redirect_to("#{Canvas::Cdn.config.host}/#{@account_config.public_json_path}")
    end

    it "redirects to the subaccount's brand config" do
      user_session(@user)
      get :show_context, params: { account_id: @subaccount.id }
      expect(response).to redirect_to("#{Canvas::Cdn.config.host}/#{@subaccount_config.public_json_path}")
    end

    it "redirects to the courses's account's brand config" do
      user_session(@user)
      course = course_factory(account: @subaccount)
      get :show_context, params: { course_id: course.id }
      expect(response).to redirect_to("#{Canvas::Cdn.config.host}/#{@subaccount_config.public_json_path}")
    end

    it "returns 404 if the account doesn't exist" do
      user_session(@user)
      get :show_context, params: { account_id: 0 }
      expect(response).to be_not_found
    end

    it "redirects to login if the user isn't logged in" do
      get :show_context, params: { account_id: @subaccount.id }
      expect(response).to redirect_to(login_url)
    end
  end
end
