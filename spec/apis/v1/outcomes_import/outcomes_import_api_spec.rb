# frozen_string_literal: true

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

require_relative "../../api_spec_helper"

describe "Outcomes Import API", type: :request do
  let(:guid) { "A833C528-901A-11DF-A622-0C319DFF4B22" }

  def filename_to_hash(file)
    JSON.parse(File.read(
                 "#{File.dirname(File.expand_path(__FILE__))}/fixtures/#{file}"
               ))
  end

  def stub_ab_config_with(return_value)
    allow(AcademicBenchmark).to receive(:config).and_return(return_value)
  end

  def available_json(expected_status: 200)
    api_call(:get,
             "/api/v1/global/outcomes_import/available",
             {
               controller: "outcomes_academic_benchmark_import_api",
               action: "available",
               account_id: @account.id.to_s,
               format: "json",
             },
             {},
             {},
             {
               expected_status:
             })
  end

  def create_json(guid:, expected_status: 200)
    api_call(:post,
             "/api/v1/global/outcomes_import",
             {
               controller: "outcomes_academic_benchmark_import_api",
               action: "create",
               account_id: @account.id.to_s,
               format: "json",
             },
             {
               guid:
             },
             {},
             {
               expected_status:
             })
  end

  def create_full_json(json:, expected_status: 200)
    api_call(:post,
             "/api/v1/global/outcomes_import",
             {
               controller: "outcomes_academic_benchmark_import_api",
               action: "create",
               account_id: @account.id.to_s,
               format: "json",
             },
             json,
             {},
             {
               expected_status:
             })
  end

  def status_json(migration_id:, expected_status: 200)
    api_call(:get,
             "/api/v1/global/outcomes_import/migration_status/#{migration_id}",
             {
               controller: "outcomes_academic_benchmark_import_api",
               action: "migration_status",
               account_id: @account.id.to_s,
               format: "json",
               migration_id:
             },
             {},
             {},
             {
               expected_status:
             })
  end

  def revoke_permission(account_user, permission)
    RoleOverride.manage_role_override(
      account_user.account,
      account_user.role,
      permission.to_s,
      override: false
    )
  end

  def create_request(json)
    { guid: "9426DCAE-734C-40D5-ABF6-FB748CD8BE65" }.merge(json)
  end

  before :once do
    user_with_pseudonym(active_all: true)
    @account = Account.default
    @account_user = @user.account_users.create(account: Account.site_admin)
  end

  shared_examples "academic benchmark config" do
    describe "config" do
      let(:request) do
        lambda do |type:, guid: nil, expected_status: 200|
          case type
          when "available" then available_json(expected_status:)
          when "create" then create_json(guid:, expected_status:)
          else raise "unknown request type"
          end
        end
      end

      it "requires the AcademicBenchmark config to be set" do
        stub_ab_config_with(nil)
        expect(request.call(type: request_type)["error"]).to match(/needs partner_key and partner_id/i)
      end

      context "requires the AcademicBenchmark config partner_key to be set" do
        it "rejects a missing/nil key" do
          stub_ab_config_with({})
          expect(request.call(type: request_type)["error"]).to match(/needs partner_key/i)
        end

        it "rejects a partner key that is the empty string" do
          stub_ab_config_with({
                                partner_id: "instructure",
                                partner_key: ""
                              })
          expect(request.call(type: request_type)["error"]).to match(/needs partner_key/i)
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
      before do
        stub_ab_import
        stub_ab_config
        stub_ab_api
      end

      context "available" do
        it "works" do
          expect(available_json).to eq(filename_to_hash(json_file))
        end

        it "includes the United Kingdom" do
          expect(available_json.any? { |j| j["title"] == "UK Department for Education" }).to be true
        end

        it "includes the common core standards" do
          expect(available_json.any? { |j| j["title"] =~ /common core/i }).to be_truthy
        end

        it "includes the NGSS standards" do
          expect(available_json.any? { |j| j["title"] =~ /ngss/i }).to be_truthy
        end

        %w[Administrators Teachers Students].each do |group|
          it "includes the ISTE standards for #{group}" do
            expect(available_json.any? { |j| j["title"] == "NETS for #{group}" }).to be_truthy
          end
        end

        it "requires the user to have manage_global_outcomes permissions" do
          revoke_permission(@account_user, :manage_global_outcomes)
          available_json(expected_status: 401)
        end
      end

      context "create" do
        it "works" do
          expect(create_json(guid:)).to have_key("migration_id")
        end

        it "requires the user to have manage_global_outcomes permissions" do
          revoke_permission(@account_user, :manage_global_outcomes)
          create_json(guid:, expected_status: 401)
        end

        it "returns error if no guid is passed" do
          expect(create_json(guid: nil)).to have_key("error")
        end

        it "rejects malformed guids" do
          %w[
            test
            not
            a
            real
            guid
            A833C528<901A-11DF-A622-0C319DFF4B22
            A833C528-901A-11DF>A622-0C319DFF4B22
            A833C528;901A-11DF-A622-0C319DFF4B22
          ].each do |guid|
            expect(create_json(guid:)).to have_key("error")
          end
        end

        it "accepts case-insensitive GUIDs" do
          %w[
            9426DCAE-734C-40D5-ABF6-FB748CD8BE65
            9426dcae-734c-40d5-abf6-fb748cd8be65
            9426DCAE-734C-40d5-abf6-fb748cd8be65
          ].each do |guid|
            expect(create_json(guid:)).not_to have_key("error")
          end
        end

        it "accepts valid mastery_points" do
          %w[
            0
            1
            100
          ].each do |mastery_points|
            expect(create_full_json(json: create_request({
                                                           mastery_points:
                                                         }))).not_to have_key("error")
          end
        end

        it "rejects malformed mastery_points" do
          %w[
            0.1
            a
            1a
          ].each do |mastery_points|
            expect(create_full_json(json: create_request({
                                                           mastery_points:
                                                         }))).to have_key("error")
          end
        end

        it "accepts valid points_possible" do
          %w[
            0
            1
            100
          ].each do |points_possible|
            expect(create_full_json(json: create_request({
                                                           points_possible:
                                                         }))).not_to have_key("error")
          end
        end

        it "rejects malformed points_possible" do
          %w[
            0.1
            a
            1a
          ].each do |points_possible|
            expect(create_full_json(json: create_request({
                                                           points_possible:
                                                         }))).to have_key("error")
          end
        end

        it "accepts valid ratings" do
          expect(create_full_json(json: create_request({
                                                         ratings: [{ description: "Perfect", points: 10 }]
                                                       }))).not_to have_key("error")
          expect(create_full_json(json: create_request({
                                                         ratings: [{ description: "Perfect", points: 10 },
                                                                   { description: "Failure", points: 0 }]
                                                       }))).not_to have_key("error")
        end

        it "rejects malformed ratings" do
          expect(create_full_json(json: create_request({
                                                         ratings: "1"
                                                       }))).to have_key("error")
          expect(create_full_json(json: create_request({
                                                         "ratings[][description]" => nil
                                                       }))).to have_key("error")
          expect(create_full_json(json: create_request({
                                                         "ratings[][description]" => "stuff"
                                                       }))).to have_key("error")
          expect(create_full_json(json: create_request({
                                                         "ratings[][description]" => "stuff",
                                                         "ratings[][points]" => nil
                                                       }))).to have_key("error")
          expect(create_full_json(json: create_request({
                                                         "ratings[][description]" => "stuff",
                                                         "ratings[][points]" => ""
                                                       }))).to have_key("error")
          expect(create_full_json(json: create_request({
                                                         "ratings[][description]" => "stuff",
                                                         "ratings[][points]" => "0.1"
                                                       }))).to have_key("error")
          expect(create_full_json(json: create_request({
                                                         ratings: [{ description: ["stuff", "more stuff"], points: 10 },
                                                                   { description: "Failure" }]
                                                       }))).to have_key("error")
          expect(create_full_json(json: create_request({
                                                         ratings: [{ description: "Perfect", points: 10 },
                                                                   { description: "Failure" }]
                                                       }))).to have_key("error")
          expect(create_full_json(json: create_request({
                                                         ratings: [{ description: "Perfect", points: 10 },
                                                                   { points: 0 }]
                                                       }))).to have_key("error")
        end

        it "accepts valid calculation methods" do
          expect(create_full_json(json: create_request({
                                                         calculation_method: "decaying_average",
                                                         calculation_int: 60
                                                       }))).not_to have_key("error")
          expect(create_full_json(json: create_request({
                                                         calculation_method: "n_mastery",
                                                         calculation_int: 7
                                                       }))).not_to have_key("error")
          expect(create_full_json(json: create_request({
                                                         calculation_method: "highest"
                                                       }))).not_to have_key("error")
          expect(create_full_json(json: create_request({
                                                         calculation_method: "latest"
                                                       }))).not_to have_key("error")
          expect(create_full_json(json: create_request({
                                                         calculation_method: "average"
                                                       }))).not_to have_key("error")
        end

        it "rejects malformed calculation methods" do
          expect(create_full_json(json: create_request({
                                                         calculation_method: "invalid calculation method",
                                                         calculation_int: 60
                                                       }))).to have_key("error")
          expect(create_full_json(json: create_request({
                                                         calculation_method: "decaying_average"
                                                       }))).to have_key("error")
          expect(create_full_json(json: create_request({
                                                         calculation_method: "decaying_average",
                                                         calculation_int: 200
                                                       }))).to have_key("error")
          expect(create_full_json(json: create_request({
                                                         calculation_method: "n_mastery"
                                                       }))).to have_key("error")
          expect(create_full_json(json: create_request({
                                                         calculation_method: "n_mastery",
                                                         calculation_int: 100
                                                       }))).to have_key("error")
          expect(create_full_json(json: create_request({
                                                         calculation_method: "highest",
                                                         calculation_int: 1
                                                       }))).to have_key("error")
          expect(create_full_json(json: create_request({
                                                         calculation_method: "latest",
                                                         calculation_int: 1
                                                       }))).to have_key("error")
          expect(create_full_json(json: create_request({
                                                         calculation_method: "average",
                                                         calculation_int: 1
                                                       }))).to have_key("error")
        end
      end

      context "status" do
        it "requires valid migration id" do
          expect(status_json(migration_id: 1)["error"]).to match(/no content migration matching id/i)
        end

        it "check valid migration id" do
          cm_mock = double("content_migration", {
                             id: 2,
                             context_id: 1,
                             created_at: Time.zone.now,
                             attachment: nil,
                             for_course_copy?: false,
                             job_progress: nil,
                             migration_type: nil,
                             source_course: nil,
                             migration_settings: {}
                           })
          allow(cm_mock).to receive(:migration_issues).and_return([])
          allow(ContentMigration).to receive(:find).with("2").and_return(cm_mock)
          expect(status_json(migration_id: 2)["migration_issues_count"]).to eq 0
        end
      end
    end
  end

  def stub_ab_import
    cm_mock = double("content_migration")
    allow(cm_mock).to receive(:id).and_return(3)
    allow(AcademicBenchmark).to receive(:import).and_return(cm_mock)
  end
  include_examples "outcomes import" do
    let(:json_file) { "available_return_val.json" }
    def stub_ab_api
      standards_mock = double("standards")
      allow(standards_mock).to receive(:authorities)
        .and_return(filename_to_hash("available_authorities.json")
                .map { |a| AcademicBenchmarks::Standards::Authority.from_hash(a) })
      allow(standards_mock).to receive(:authority_publications)
        .with(not_eq("CC").and(not_eq("Achieve")))
        .and_return(filename_to_hash("iste_authority_pubs.json")
                .map { |d| AcademicBenchmarks::Standards::Document.from_hash(d) })
      allow(standards_mock).to receive(:authority_publications)
        .with("Achieve")
        .and_return(filename_to_hash("achieve_authority_pubs.json")
                .map { |d| AcademicBenchmarks::Standards::Document.from_hash(d) })
      allow(standards_mock).to receive(:authority_publications)
        .with("CC")
        .and_return(filename_to_hash("common_core_authority_pubs.json")
               .map { |d| AcademicBenchmarks::Standards::Document.from_hash(d) })
      allow(AcademicBenchmarks::Api::Standards).to receive(:new).and_return(standards_mock)
    end

    def stub_ab_config
      stub_ab_config_with({
                            partner_key: "<secret-key>",
                            partner_id: "instructure"
                          })
    end
  end
end
