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
#

require_relative '../api_spec_helper'

describe SharedBrandConfigsController, type: :request do

  let(:brand_config) { BrandConfig.create!(variables: {"ic-brand-primary" => "#321"}) }
  let(:shared_config) { Account.default.shared_brand_configs.create!(
    name: "name before update",
    brand_config_md5: brand_config.md5)
  }

  describe '#create' do
    let(:url) { "/api/v1/accounts/#{Account.default.id}/shared_brand_configs" }
    let(:api_args_for_create) {
      {
        controller: 'shared_brand_configs',
        action: 'create',
        format: 'json',
        account_id: Account.default.id.to_s
      }
    }
    let(:params) {
      {shared_brand_config: {'name' => 'New Theme', 'brand_config_md5' => brand_config.md5}}
    }

    it "doesn't allow unauthorized access" do
      raw_api_call(:post, url, api_args_for_create, params)
      assert_status(401)
    end

    it "shares within the correct account" do
      account_admin_user
      expect {
        json = api_call(:post, url, api_args_for_create, params)
        expect(json).to include({
          "account_id" => Account.default.id,
          "brand_config_md5" => brand_config.md5,
          "name" => "New Theme",
        })
      }.to change(Account.default.shared_brand_configs, :count).by(1)
    end

    it "errors if invalid" do
      account_admin_user
      raw_api_call(:post, url, api_args_for_create, {
        shared_brand_config: {
          'name' => 'New Theme',
          'brand_config_md5' => 'INVALID'
        }
      })
      assert_status(422)
    end
  end

  describe "#update" do
    let(:params) { {shared_brand_config: {'name' => 'Updated Name'}} }
    let(:api_args_for_update) {
      {
        controller: 'shared_brand_configs',
        action: 'update',
        format: 'json',
        account_id: Account.default.id.to_s,
        id: shared_config.id
      }
    }
    let(:url) { "/api/v1/accounts/#{Account.default.id}/shared_brand_configs/#{shared_config.id}"}

    it "doesn't allow unauthorized access" do
      raw_api_call(:put, url, api_args_for_update, params)
      assert_status(401)
    end

    it "can rename a shared brand config" do
      account_admin_user
      expect(shared_config.name).to eq('name before update')
      expect {
        json = api_call(:put, url, api_args_for_update, params)
        expect(json["name"]).to eq('Updated Name')
      }.to_not change(Account.default.shared_brand_configs, :count)
      expect(Account.default.shared_brand_configs.find(shared_config.id).name).to eq('Updated Name')
    end

    it "returns invalid for a bad md5" do
      account_admin_user
      json = api_call(:put, url, api_args_for_update, {
        shared_brand_config: { brand_config_md5: 'abc' }
      }, {}, expected_status: 422)
    end
  end

  describe  "#destroy" do
    let(:api_args_for_destroy) {
      {
        controller: 'shared_brand_configs',
        action: 'destroy',
        format: 'json',
        id: shared_config.id
      }
    }
    let(:url) { "/api/v1/shared_brand_configs/#{shared_config.id}"}

    it "doesn't allow unauthorized access" do
      raw_api_call(:delete, url, api_args_for_destroy)
      assert_status(401)
    end

    it "deletes the given shared_brand_config" do
      account_admin_user
      shared_config
      expect {
        api_call(:delete, url, api_args_for_destroy)
      }.to change(Account.default.shared_brand_configs, :count).from(1).to(0)
    end
  end
end
