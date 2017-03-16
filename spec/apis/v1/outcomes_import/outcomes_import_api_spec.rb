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

  def create_full_json(json:, expected_status: 200)
    api_call(:post, "/api/v1/global/outcomes_import",
      {
        controller: 'outcomes_import_api',
        action: 'create',
        account_id: @account.id.to_s,
        format: 'json',
      },
      json,
      { },
      {
        expected_status: expected_status
      }
            )
  end

  def status_json(migration_id:, expected_status: 200)
    api_call(:get, "/api/v1/global/outcomes_import/migration_status/#{migration_id}",
      {
        controller: 'outcomes_import_api',
        action: 'migration_status',
        account_id: @account.id.to_s,
        format: 'json',
        migration_id: migration_id
      },
      { },
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

  def create_request(json)
    {guid: "9426DCAE-734C-40D5-ABF6-FB748CD8BE65"}.merge(json)
  end

  before :once do
    user_with_pseudonym(:active_all => true)
    @account = Account.default
    @account_user = @user.account_users.create(:account => Account.site_admin)
  end

  shared_examples "academic benchmark config" do
    describe "config" do
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
        # Since :partner_key is missing above, we default to using AB API v1.
        # Once AB API v3 becomes default, switch the regex below to /needs partner_key and partner_id/
        expect(request.call(type: request_type)["error"]).to match(/needs api_key and api_url/i)
      end

      context "requires the AcademicBenchmark config api_key or partner_key to be set" do
        # Since :partner_key is missing below, we default to using AB API v1.
        # Once AB API v3 becomes default, switch the regex below to /needs partner_key/
        it "rejects a missing/nil key" do
          stub_ab_config_with({ "api_url" => "http://a.real.url.com" })
          expect(request.call(type: request_type)["error"]).to match(/needs api_key/i)
        end
        # Since :partner_key is empty below, we default to using AB API v1.
        # Once AB API v3 becomes default, switch the regex below to /needs partner_key/
        it "rejects a partner key that is the empty string" do
          stub_ab_config_with({
            partner_id: "instructure",
            partner_key: ""
          })
          expect(request.call(type: request_type)["error"]).to match(/needs api_key/i)
        end
        it "rejects an api key that is the empty string" do
          stub_ab_config_with({
            "api_url" => "http://a.real.url.com",
            "api_key" => ""
          })
          expect(request.call(type: request_type)["error"]).to match(/needs api_key/i)
        end
      end

      it "requires the AcademicBenchmark partner id to be set" do
        stub_ab_config_with({ partner_key: "dont_fear_the_reaper" })
        expect(request.call(type: request_type)["error"]).to match(/needs partner_id/i)
      end
    end
  end

  describe "create" do
    include_examples "academic benchmark config" do
      let(:request_type) { "create" }
    end
  end

  describe "available" do
    include_examples "academic benchmark config" do
      let(:request_type) { "available" }
    end
  end

  shared_examples "outcomes import" do
    context "Account" do
      before :each do
        stub_ab_import
        stub_ab_config
        stub_ab_api
      end

      before :once do
      end

      context "available" do
        it "works" do
          expect(available_json).to eq(filename_to_hash(json_file))
        end

        it "includes the United Kingdom" do
          expect(available_json.any?{|j| j[description_key] == "United Kingdom"}).to be_truthy
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

        it "accepts valid mastery_points" do
          %w[
            0
            1
            100
          ].each do |mastery_points|
            expect(create_full_json(json: create_request({
              mastery_points: mastery_points}))).not_to have_key("error")
          end
        end

        it "rejects malformed mastery_points" do
          %w[
            0.1
            a
            1a
          ].each do |mastery_points|
            expect(create_full_json(json: create_request({
              mastery_points: mastery_points}))).to have_key("error")
          end
        end

        it "accepts valid points_possible" do
          %w[
            0
            1
            100
          ].each do |points_possible|
            expect(create_full_json(json: create_request({
              points_possible: points_possible}))).not_to have_key("error")
          end
        end

        it "rejects malformed points_possible" do
          %w[
            0.1
            a
            1a
          ].each do |points_possible|
            expect(create_full_json(json: create_request({
              points_possible: points_possible}))).to have_key("error")
          end
        end

        it "accepts valid ratings" do
          expect(create_full_json(json: create_request({
            ratings: [{description: "Perfect", points: 10}]}))).not_to have_key("error")
          expect(create_full_json(json: create_request({
            ratings: [{description: "Perfect", points: 10},
                      {description: "Failure", points: 0}]}))).not_to have_key("error")
        end

        it "rejects malformed ratings" do
          expect(create_full_json(json: create_request({
            ratings: "1"}))).to have_key("error")
          expect(create_full_json(json: create_request({
            'ratings[][description]' => nil}))).to have_key("error")
          expect(create_full_json(json: create_request({
            'ratings[][description]' => "stuff"}))).to have_key("error")
          expect(create_full_json(json: create_request({
            'ratings[][description]' => "stuff",
            'ratings[][points]' => nil}))).to have_key("error")
          expect(create_full_json(json: create_request({
            'ratings[][description]' => "stuff",
            'ratings[][points]' => ""}))).to have_key("error")
          expect(create_full_json(json: create_request({
            'ratings[][description]' => "stuff",
            'ratings[][points]' => "0.1"}))).to have_key("error")
          expect(create_full_json(json: create_request({
            ratings: [{description: ["stuff", "more stuff"], points: 10},
                      {description: "Failure"}]}))).to have_key("error")
          expect(create_full_json(json: create_request({
            ratings: [{description: "Perfect", points: 10},
                      {description: "Failure"}]}))).to have_key("error")
          expect(create_full_json(json: create_request({
            ratings: [{description: "Perfect", points: 10},
                      {points: 0}]}))).to have_key("error")
        end

        it "accepts valid calculation methods" do
          expect(create_full_json(json: create_request({
            calculation_method: 'decaying_average',
            calculation_int: 60}))).not_to have_key("error")
          expect(create_full_json(json: create_request({
            calculation_method: 'n_mastery',
            calculation_int: 3}))).not_to have_key("error")
          expect(create_full_json(json: create_request({
            calculation_method: 'highest'}))).not_to have_key("error")
          expect(create_full_json(json: create_request({
            calculation_method: 'latest'}))).not_to have_key("error")
        end

        it "rejects malformed calculation methods" do
          expect(create_full_json(json: create_request({
            calculation_method: 'invalid calculation method',
            calculation_int: 60}))).to have_key("error")
          expect(create_full_json(json: create_request({
            calculation_method: 'decaying_average'}))).to have_key("error")
          expect(create_full_json(json: create_request({
            calculation_method: 'decaying_average',
            calculation_int: 200}))).to have_key("error")
          expect(create_full_json(json: create_request({
            calculation_method: 'n_mastery'}))).to have_key("error")
          expect(create_full_json(json: create_request({
            calculation_method: 'n_mastery',
            calculation_int: 100}))).to have_key("error")
          expect(create_full_json(json: create_request({
            calculation_method: 'highest',
            calculation_int: 1}))).to have_key("error")
          expect(create_full_json(json: create_request({
            calculation_method: 'latest',
            calculation_int: 1}))).to have_key("error")
        end
      end

      context "status" do
        it "requires valid migration id" do
          expect(status_json(migration_id: 1)["error"]).to match(/no content migration matching id/i)
        end
        it "check valid migration id" do
          cm_mock = mock("content_migration", {
            id: 2,
            context_id: 1,
            created_at: Time.zone.now,
            attachment: nil,
            for_course_copy?: false,
            job_progress: nil,
            migration_type: nil
            })
          cm_mock.stubs(:migration_issues).returns([])
          ContentMigration.stubs(:find).with('2').returns(cm_mock)
          expect(status_json(migration_id: 2)["migration_issues_count"]).to eq 0
        end
      end
    end
  end

  describe "v1" do
    def stub_ab_import
      cm_mock = mock("content_migration")
      cm_mock.stubs(:id).returns(3)
      AcademicBenchmark.stubs(:import).returns(cm_mock)
    end
    include_examples "outcomes import" do
      let(:description_key){ "title" }
      let(:json_file) { "available_return_val_v1.json" }
      def stub_ab_api
        api_mock = mock("api")
        api_mock.stubs(:list_available_authorities).
          returns(filename_to_hash("api_list_authorities.json"))
        api_mock.stubs(:browse_guid).
          returns(filename_to_hash("api_browse_guid.json"))
        api_mock.stubs(:browse).
          returns(filename_to_hash("api_browse.json"))
        AcademicBenchmark::Api.stubs(:new).returns(api_mock)
      end

      def stub_ab_config
        stub_ab_config_with({
          "api_key" => "<secret-key>",
          "api_url" => "http://api.statestandards.com/services/rest/"
        })
      end
    end
  end

  describe "v3" do
    def stub_ab_import
      cm_mock = mock("content_migration")
      cm_mock.stubs(:id).returns(3)
      AcademicBenchmark.stubs(:import).returns(cm_mock)
    end
    include_examples "outcomes import" do
      let(:description_key){ "description" }
      let(:json_file) { "available_return_val.json" }
      def stub_ab_api
        standards_mock = mock("standards")
        standards_mock.stubs(:authorities).
          returns(filename_to_hash("available_authorities.json").
                  map{ |a| AcademicBenchmarks::Standards::Authority.from_hash(a) })
        standards_mock.stubs(:authority_documents).
          with { |*args| args[0] != 'CC' && args[0] != 'NRC' }.
          returns(filename_to_hash("national_standards_authority_docs.json").
                  map{ |d| AcademicBenchmarks::Standards::Document.from_hash(d) })
        standards_mock.stubs(:authority_documents).
          with { |*args| args[0] == 'NRC' }.
          returns(filename_to_hash("ngss_nrc_authority_docs.json").
                  map{ |d| AcademicBenchmarks::Standards::Document.from_hash(d) })
        standards_mock.stubs(:authority_documents).
          with { |*args| args[0] == 'CC' }.
          returns(filename_to_hash("common_core_authority_docs.json").
                 map{ |d| AcademicBenchmarks::Standards::Document.from_hash(d) })
        AcademicBenchmarks::Api::Standards.stubs(:new).returns(standards_mock)
      end

      def stub_ab_config
        stub_ab_config_with({
          partner_key: "<secret-key>",
          partner_id: "instructure"
        })
      end
    end
  end

end
