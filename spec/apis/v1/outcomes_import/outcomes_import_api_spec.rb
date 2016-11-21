#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')

describe "Outcomes Import API", type: :request do

  let(:guid) { "A833C528-901A-11DF-A622-0C319DFF4B22" }

  def filename_to_hash(file)
    JSON.parse(File.read(
      "#{File.dirname(File.expand_path(__FILE__))}/fixtures/#{file}"
    ))
  end

  def stub_ab_api
    AcademicBenchmark::Api.any_instance.stubs(:list_available_authorities).
      returns(filename_to_hash("api_list_authorities.json"))
    AcademicBenchmark::Api.any_instance.stubs(:browse_guid).
      returns(filename_to_hash("api_browse_guid.json"))
    AcademicBenchmark::Api.any_instance.stubs(:browse).
      returns(filename_to_hash("api_browse.json"))
  end

  def stub_ab_import
    cm_mock = mock("content_migration")
    cm_mock.stubs(:id).returns(3)
    AcademicBenchmark.stubs(:import).returns([cm_mock, nil])
  end

  def stub_ab_config
    stub_ab_config_with({
      "api_key" => "<secret-key>",
      "api_url" => "http://api.statestandards.com/services/rest/"
    })
  end

  def stub_ab_config_with(return_value)
    AcademicBenchmark.stubs(:config).returns(return_value)
  end

  def available_json(expected_status: 200)
    api_call(:get, "/api/v1/global/outcomes_import/available",
      {
        controller: 'outcomes_import_api',
        action: 'available',
        account_id: @account.id.to_s,
        format: 'json',
      },
      { },
      { },
      {
        expected_status: expected_status
      }
    )
  end

  def create_json(guid:, expected_status: 200)
    api_call(:post, "/api/v1/global/outcomes_import",
      {
        controller: 'outcomes_import_api',
        action: 'create',
        account_id: @account.id.to_s,
        format: 'json',
      },
      {
        guid: guid
      },
      { },
      {
        expected_status: expected_status
      }
    )
  end

  def revoke_permission(account_user, permission)
    RoleOverride.manage_role_override(
      account_user.account,
      account_user.role,
      permission.to_s,
      :override => false
    )
  end

  context "Account" do
    before :each do
      stub_ab_import
      stub_ab_config
      stub_ab_api
    end

    before :once do
      user_with_pseudonym(:active_all => true)
      @account = Account.default
      @account_user = @user.account_users.create(:account => Account.site_admin)
    end

    shared_examples "academic benchmark config" do
      describe "api_key" do
        let(:request) do
          ->(type:, guid: nil, expected_status: 200) do
            case type
            when "available" then return available_json(expected_status: expected_status)
            when "create" then return create_json(guid: guid, expected_status: expected_status)
            else fail "unknown request type"
            end
          end
        end

        it "requires the AcademicBenchmark config to be set" do
          stub_ab_config_with(nil)
          expect(request.call(type: request_type)["error"]).to match(/needs api_key and api_url/i)
        end

        context "requires the AcademicBenchmark config api_key to be set" do
          it "rejects a missing/nil key" do
            stub_ab_config_with({ "api_url" => "http://a.real.url.com" })
            expect(request.call(type: request_type)["error"]).to match(/needs api_key/i)
          end

          it "rejects a key that is the empty string" do
            stub_ab_config_with({
              "api_url" => "http://a.real.url.com",
              "api_key" => ""
            })
            expect(request.call(type: request_type)["error"]).to match(/needs api_key/i)
          end
        end

        it "requires the AcademicBenchmark config to be set" do
          stub_ab_config_with({ "api_key" => "dont_fear_the_reaper" })
          expect(request.call(type: request_type)["error"]).to match(/needs api_url/i)
        end
      end
    end

    context "available" do
      it "works" do
        expect(available_json).to eq(filename_to_hash("available_return_val.json"))
      end

      it "includes the United Kingdom" do
        expect(available_json.any?{|j| j["title"] == "United Kingdom"}).to be_truthy
      end

      it "includes the common core standards" do
        expect(available_json.any?{|j| j["title"] =~ /common core/i}).to be_truthy
      end

      it "includes the NGSS standards" do
        expect(available_json.any?{|j| j["title"] =~ /ngss/i}).to be_truthy
      end

      %w[Administrators Teachers Students].each do |group|
        it "includes the ISTE standards for #{group}" do
          expect(available_json.any?{|j| j["title"] == "NETS for #{group}"}).to be_truthy
        end
      end

      it "requires the user to have manage_global_outcomes permissions" do
        revoke_permission(@account_user, :manage_global_outcomes)
        available_json(expected_status: 401)
      end

      include_examples "academic benchmark config" do
        let(:request_type) { "available" }
      end
    end

    context "create" do
      it "works" do
        expect(create_json(guid: guid)).to have_key("migration_id")
      end

      it "requires the user to have manage_global_outcomes permissions" do
        revoke_permission(@account_user, :manage_global_outcomes)
        create_json(guid: guid, expected_status: 401)
      end

      it "returns error if no guid is passed" do
        expect(create_json(guid: nil)).to have_key("error")
      end

      it "rejects malformed guids" do
        %w[
          test
          not a real guid
          A833C528<901A-11DF-A622-0C319DFF4B22
          A833C528-901A-11DF>A622-0C319DFF4B22
          A833C528;901A-11DF-A622-0C319DFF4B22
        ].each do |guid|
          expect(create_json(guid: guid)).to have_key("error")
        end
      end

      it "accepts case-insensitive GUIDs" do
        %w[
          9426DCAE-734C-40D5-ABF6-FB748CD8BE65
          9426dcae-734c-40d5-abf6-fb748cd8be65
          9426DCAE-734C-40d5-abf6-fb748cd8be65
        ].each do |guid|
          expect(create_json(guid: guid)).not_to have_key("error")
        end
      end

      include_examples "academic benchmark config" do
        let(:request_type) { "create" }
      end
    end
  end
end
