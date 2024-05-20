# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
require_relative "../spec_helper"
require "webmock/rspec"

describe CanvasOutcomesHelper do
  def stub_get_lmgb_results(params)
    stub_request(:get, "http://domain/api/authoritative_results?#{params}").with({
                                                                                   headers: {
                                                                                     Authorization: /\+*/,
                                                                                     Accept: "*/*",
                                                                                     "Accept-Encoding": /\+*/,
                                                                                     "User-Agent": "Ruby"
                                                                                   }
                                                                                 })
  end

  def stub_get_alignments(params)
    stub_request(:get, "http://domain/api/outcomes/list?#{params}").with({
                                                                           headers: {
                                                                             Authorization: /\+*/,
                                                                             Accept: "*/*",
                                                                             "Accept-Encoding": /\+*/,
                                                                             "User-Agent": "Ruby"
                                                                           }
                                                                         })
  end

  subject { Object.new.extend CanvasOutcomesHelper }

  around do |example|
    WebMock.disable_net_connect!(allow_localhost: true)
    example.run
    WebMock.enable_net_connect!
  end

  before do
    course_with_teacher_logged_in(active_all: true)
  end

  let(:account) { @course.account }

  def create_page(attrs)
    page = @course.wiki_pages.create!(attrs)
    page.publish! if page.unpublished?
    page
  end

  describe "#set_outcomes_alignment_js_env" do
    let(:wiki_page) { create_page title: "title text", body: "body text" }

    context "without outcomes" do
      it "does not set JS_ENV" do
        expect(subject).not_to receive(:js_env)
        subject.set_outcomes_alignment_js_env(wiki_page, account, {})
      end
    end

    context "with outcomes" do
      before do
        outcome_model(context: account)
      end

      it "raises error on invalid artifact type" do
        expect { subject.set_outcomes_alignment_js_env(account, account, {}) }.to raise_error("Unsupported artifact type: Account")
      end

      shared_examples_for "valid js_env settings" do
        it "sets js_env values" do
          expect(subject).to receive(:extract_domain_jwt).and_return ["domain", "jwt"]
          expect(subject).to receive(:js_env).with({
                                                     canvas_outcomes: {
                                                       artifact_type: "canvas.page",
                                                       artifact_id: wiki_page.id,
                                                       context_uuid: account.uuid,
                                                       host: expected_host,
                                                       jwt: "jwt",
                                                       extra_key: "extra_value"
                                                     }
                                                   })
          subject.set_outcomes_alignment_js_env(wiki_page, account, extra_key: "extra_value")
        end
      end

      context "without overriding protocol" do
        let(:expected_host) { "http://domain" }

        it_behaves_like "valid js_env settings"
      end

      context "overriding protocol" do
        let(:expected_host) { "https://domain" }

        before do
          ENV["OUTCOMES_SERVICE_PROTOCOL"] = "https"
        end

        after do
          ENV.delete("OUTCOMES_SERVICE_PROTOCOL")
        end

        it_behaves_like "valid js_env settings"
      end

      context "within a Group" do
        before do
          outcome_model(context: @course)
          @group = @course.groups.create(name: "some group")
        end

        it "sets js_env with the group.context values" do
          expect(subject).to receive(:extract_domain_jwt).and_return ["domain", "jwt"]
          expect(subject).to receive(:js_env).with({
                                                     canvas_outcomes: {
                                                       artifact_type: "canvas.page",
                                                       artifact_id: wiki_page.id,
                                                       context_uuid: @course.uuid,
                                                       host: "http://domain",
                                                       jwt: "jwt"
                                                     }
                                                   })
          subject.set_outcomes_alignment_js_env(wiki_page, @group, {})
        end
      end
    end
  end

  describe "#extract_domain_jwt" do
    it "returns nil domain and jwt with no provision settings" do
      expect(subject.extract_domain_jwt(account, "")).to eq [nil, nil]
    end

    it "returns nil domain and jwt with no outcomes provision settings" do
      account.settings[:provision] = {}
      account.save!
      expect(subject.extract_domain_jwt(account, "")).to eq [nil, nil]
    end

    it "returns domain and jwt with outcomes provision settings" do
      settings = { consumer_key: "key", jwt_secret: "secret", domain: "domain" }
      account.settings[:provision] = { "outcomes" => settings }
      account.save!
      expect(JWT).to receive(:encode).and_return "encoded"
      expect(subject.extract_domain_jwt(account, "")).to eq ["domain", "encoded"]
    end

    describe "if ApplicationController.test_cluster_name is specified" do
      it "returns a domain using the test_cluster_name domain" do
        settings = { consumer_key: "key",
                     jwt_secret: "secret",
                     domain: "domain",
                     beta_domain: "beta.domain" }
        account.settings[:provision] = { "outcomes" => settings }
        account.save!
        expect(JWT).to receive(:encode).and_return "encoded"
        allow(ApplicationController).to receive(:test_cluster?).and_return(true)
        allow(ApplicationController).to receive(:test_cluster_name).and_return("beta")
        expect(subject.extract_domain_jwt(account, "")).to eq ["beta.domain", "encoded"]
        allow(ApplicationController).to receive(:test_cluster_name).and_return("invalid")
        expect(subject.extract_domain_jwt(account, "")).to eq [nil, nil]
      end
    end
  end

  describe "#get_outcome_alignments" do
    before do
      settings = { consumer_key: "key", jwt_secret: "secret", domain: "domain" }
      account.settings[:provision] = { "outcomes" => settings }
      account.save!
    end

    context "without outcome ids" do
      it "returns nil when outcome ids is nil" do
        expect(subject.get_outcome_alignments(@course, nil)).to be_nil
      end

      it "returns nil when outcome ids is empty" do
        expect(subject.get_outcome_alignments(@course, "")).to be_nil
      end
    end

    context "without context" do
      it "returns nil when context is nil" do
        expect(subject.get_outcome_alignments(nil, "123")).to be_nil
      end

      it "returns nil when context is empty" do
        expect(subject.get_outcome_alignments("", "123")).to be_nil
      end
    end

    context "without outcome_service_results_to_canvas feature flag enabled" do
      it "returns nil" do
        expect(subject.get_outcome_alignments(@course, "123")).to be_nil
      end
    end

    context "returns results" do
      before do
        @course.enable_feature!(:outcome_service_results_to_canvas)
      end

      def mock_alignment_response(external_ids, include_group, alignments)
        response = external_ids.split(",").map do |e_id|
          {
            id: "1",
            guid: nil,
            group: include_group,
            label: "",
            title: "Outcome #{e_id}",
            description: "",
            external_id: e_id,
            alignments: []
          }
        end
        if alignments
          response = response.each do |r|
            r[:alignments] = [
              {
                id: 1,
                artifact_type: "quizzes.quiz",
                artifact_id: 1,
                alignment_set_id: 1,
                aligned_at: "2022-10-13T10:13:00.013Z",
                created_at: "2022-10-13T10:13:00.013Z",
                updated_at: "2022-10-13T10:13:00.013Z",
                deleted_at: nil,
                context_id: 1,
                associated_asset_id: nil,
                associated_asset_type: nil
              }
            ]
          end
        end
        response
      end

      it "raises error on non 2xx response" do
        stub_get_alignments("context_uuid=#{@course.uuid}&external_outcome_id_list=1").to_return(status: 401, body: '{"valid_jwt":false}')
        expect { subject.get_outcome_alignments(@course, "1") }.to raise_error(RuntimeError, /Error retrieving aligned assets from Outcomes Service:/)
      end

      it "outcomes only" do
        stub_get_alignments("context_uuid=#{@course.uuid}&external_outcome_id_list=1")
          .to_return(status: 200, body: mock_alignment_response("1", false, false).to_json)
        expect(subject.get_outcome_alignments(@course, "1")).to eq mock_alignment_response("1", false, false)
      end

      it "multiple outcomes" do
        stub_get_alignments("context_uuid=#{@course.uuid}&external_outcome_id_list=1,2")
          .to_return(status: 200, body: mock_alignment_response("1,2", false, false).to_json)
        expect(subject.get_outcome_alignments(@course, "1,2")).to eq mock_alignment_response("1,2", false, false)
      end

      it "outcome with no alignments" do
        stub_get_alignments("context_uuid=#{@course.uuid}&external_outcome_id_list=1&includes=alignments")
          .to_return(status: 200, body: mock_alignment_response("1", false, false).to_json)
        expect(subject.get_outcome_alignments(@course, "1", { includes: "alignments" })).to eq mock_alignment_response("1", false, false)

        outcome = LearningOutcome.new(id: 1)
        expect(subject.outcome_has_alignments?(outcome, @course)).to be false
      end

      it "outcome with alignments" do
        stub_get_alignments("context_uuid=#{@course.uuid}&external_outcome_id_list=1&includes=alignments")
          .to_return(status: 200, body: mock_alignment_response("1", false, true).to_json)
        expect(subject.get_outcome_alignments(@course, "1", { includes: "alignments" })).to eq mock_alignment_response("1", false, true)

        outcome = LearningOutcome.new(id: 1)
        expect(subject.outcome_has_alignments?(outcome, @course)).to be true
      end

      it "outcome with alignments and groups" do
        stub_get_alignments("context_uuid=#{@course.uuid}&external_outcome_id_list=1&includes=alignments&list_groups=true")
          .to_return(status: 200, body: mock_alignment_response("1", true, true).to_json)
        expect(subject.get_outcome_alignments(@course, "1", { includes: "alignments", list_groups: true })).to eq mock_alignment_response("1", true, true)
      end

      it "outcome with alignments and no groups" do
        stub_get_alignments("context_uuid=#{@course.uuid}&external_outcome_id_list=1&includes=alignments&list_groups=false")
          .to_return(status: 200, body: mock_alignment_response("1", false, true).to_json)
        expect(subject.get_outcome_alignments(@course, "1", { includes: "alignments", list_groups: false })).to eq mock_alignment_response("1", false, true)
      end
    end

    context "no results found" do
      before do
        @course.enable_feature!(:outcome_service_results_to_canvas)
      end

      it "returns empty array when no outcome ids are matched" do
        stub_get_alignments("context_uuid=#{@course.uuid}&external_outcome_id_list=123").to_return(status: 200, body: "[]")
        expect(subject.get_outcome_alignments(@course, "123")).to eq []
      end

      it "returns empty array when context is not matched" do
        @course.update!(uuid: "someguid")
        stub_get_alignments("context_uuid=someguid&external_outcome_id_list=1").to_return(status: 200, body: "[]")
        expect(subject.get_outcome_alignments(@course, "1")).to eq []
      end
    end
  end

  describe "#get_lmgb_results" do
    let(:user1) { User.create! }
    let(:one_user_uuid) { user1.uuid }

    context "without account outcome settings" do
      it "returns nil with no provision settings" do
        expect(subject.get_lmgb_results(account, "1", "assign.type", "1", one_user_uuid)).to be_nil
      end

      it "returns nil with no outcome provision settings" do
        account.settings[:provision] = {}
        account.save!
        expect(subject.get_lmgb_results(account, "1", "assign.type", "1", one_user_uuid)).to be_nil
      end
    end

    context "with account outcome settings" do
      before do
        settings = { consumer_key: "key", jwt_secret: "secret", domain: "domain" }
        account.settings[:provision] = { "outcomes" => settings }
        account.save!
      end

      context "without assignment ids" do
        it "returns nil when assignment ids is nil" do
          expect(subject.get_lmgb_results(account, nil, "assign.type", "1", one_user_uuid)).to be_nil
        end

        it "returns nil when assignment ids is empty" do
          expect(subject.get_lmgb_results(account, "", "assign.type", "1", one_user_uuid)).to be_nil
        end
      end

      context "without assignment type" do
        it "returns nil when assignment type is nil" do
          expect(subject.get_lmgb_results(account, "1", nil, "1", one_user_uuid)).to be_nil
        end

        it "returns nil when assignment type is empty" do
          expect(subject.get_lmgb_results(account, "1", "", "1", one_user_uuid)).to be_nil
        end
      end

      context "without outcome ids" do
        it "returns nil when outcome ids is nil" do
          expect(subject.get_lmgb_results(account, "1", "assign.type", nil, one_user_uuid)).to be_nil
        end

        it "returns nil when outcome ids is empty" do
          expect(subject.get_lmgb_results(account, "1", "assign.type", "", one_user_uuid)).to be_nil
        end
      end

      context "without user uuids" do
        it "returns nil when user uuids is nil" do
          expect(subject.get_lmgb_results(account, "1", "assign.type", "1", nil)).to be_nil
        end

        it "returns nil when user uuids is empty" do
          expect(subject.get_lmgb_results(account, "1", "assign.type", "1", "")).to be_nil
        end
      end

      context "with outcomes provision settings" do
        context "with outcome_service_results_to_canvas FF on" do
          let(:user1) { User.create! }
          let(:user2) { User.create! }
          let(:multiple_user_uuids) { "#{user1.uuid},#{user2.uuid}" }

          before do
            @course.enable_feature!(:outcome_service_results_to_canvas)
          end

          it "throws OSFetchError if call fails" do
            expect(CanvasHttp).to receive(:get).and_raise("failed call").exactly(3).times
            expect { subject.get_lmgb_results(@course, "1", "assign.type", "1", one_user_uuid) }.to raise_error(CanvasOutcomesHelper::OSFetchError)
          end

          it "raises error on non 2xx response" do
            stub_get_lmgb_results("associated_asset_id_list=1&associated_asset_type=assign.type&external_outcome_id_list=1&artifact_type=quizzes.quiz&user_uuid_list=#{one_user_uuid}&per_page=200&page=1").to_return(status: 401, body: '{"valid_jwt":false}')
            expect { subject.get_lmgb_results(@course, "1", "assign.type", "1", one_user_uuid) }.to raise_error(CanvasOutcomesHelper::OSFetchError, /Error retrieving results from Outcomes Service:/)
          end

          it "returns results with one assignment id" do
            expected_results = [{ result: "stuff" }]
            stub_get_lmgb_results("associated_asset_id_list=1&associated_asset_type=assign.type&external_outcome_id_list=1&artifact_type=quizzes.quiz&user_uuid_list=#{one_user_uuid}&per_page=200&page=1").to_return(status: 200, body: '{"results":[{"result":"stuff"}]}', headers: { "Per-Page" => 200, "Total" => 1 })
            expect(subject.get_lmgb_results(@course, "1", "assign.type", "1", one_user_uuid)).to eq expected_results
          end

          it "returns results with multiple assignment ids" do
            expected_results = [{ result_one: "stuff1" }, { result_two: "stuff2" }]
            stub_get_lmgb_results("associated_asset_id_list=1,2&associated_asset_type=assign.type&external_outcome_id_list=1&artifact_type=quizzes.quiz&user_uuid_list=#{one_user_uuid}&per_page=200&page=1").to_return(status: 200, body: '{"results":[{"result_one":"stuff1"},{"result_two":"stuff2"}]}', headers: { "Per-Page" => 200, "Total" => 2 })
            expect(subject.get_lmgb_results(@course, "1,2", "assign.type", "1", one_user_uuid)).to eq expected_results
          end

          it "returns results with one outcome id" do
            expected_results = [{ result_one: "stuff" }]
            stub_get_lmgb_results("associated_asset_id_list=1,2&associated_asset_type=assign.type&external_outcome_id_list=1&artifact_type=quizzes.quiz&user_uuid_list=#{one_user_uuid}&per_page=200&page=1").to_return(status: 200, body: '{"results":[{"result_one":"stuff"}]}', headers: { "Per-Page" => 200, "Total" => 1 })
            expect(subject.get_lmgb_results(@course, "1,2", "assign.type", "1", one_user_uuid)).to eq expected_results
          end

          it "returns results with multiple outcome ids" do
            expected_results = [{ result_one: "stuff1" }, { result_two: "stuff2" }]
            stub_get_lmgb_results("associated_asset_id_list=1,2&associated_asset_type=assign.type&external_outcome_id_list=1,2&per_page=200&page=1&artifact_type=quizzes.quiz&user_uuid_list=#{one_user_uuid}")
              .to_return(status: 200, body: '{"results":[{"result_one":"stuff1"},{"result_two":"stuff2"}]}', headers: { "Per-Page" => 200, "Total" => 2 })
            expect(subject.get_lmgb_results(@course, "1,2", "assign.type", "1,2", one_user_uuid)).to eq expected_results
          end

          it "returns results with one user uuid" do
            expected_results = [{ result_one: "stuff1" }]
            stub_get_lmgb_results("associated_asset_id_list=1,2&associated_asset_type=assign.type&external_outcome_id_list=1,2&artifact_type=quizzes.quiz&user_uuid_list=#{one_user_uuid}&per_page=200&page=1").to_return(status: 200, body: '{"results":[{"result_one":"stuff1"}]}', headers: { "Per-Page" => 200, "Total" => 1 })
            expect(subject.get_lmgb_results(@course, "1,2", "assign.type", "1,2", one_user_uuid)).to eq expected_results
          end

          it "returns results with multiple user uuids" do
            expected_results = [{ result_one: "stuff1" }, { result_two: "stuff2" }]
            stub_get_lmgb_results("associated_asset_id_list=1,2&associated_asset_type=assign.type&external_outcome_id_list=1,2&artifact_type=quizzes.quiz&user_uuid_list=#{multiple_user_uuids}&per_page=200&page=1").to_return(status: 200, body: '{"results":[{"result_one":"stuff1"},{"result_two":"stuff2"}]}', headers: { "Per-Page" => 200, "Total" => 2 })
            expect(subject.get_lmgb_results(@course, "1,2", "assign.type", "1,2", multiple_user_uuids)).to eq expected_results
          end

          it "returns empty array when assignment type is not matched" do
            expected_results = []
            stub_get_lmgb_results("associated_asset_id_list=1&associated_asset_type=assign.type.no.match&external_outcome_id_list=1&artifact_type=quizzes.quiz&user_uuid_list=#{one_user_uuid}&per_page=200&page=1").to_return(status: 200, body: '{"results":[]}', headers: { "Per-Page" => 200, "Total" => 0 })
            expect(subject.get_lmgb_results(@course, "1", "assign.type.no.match", "1", one_user_uuid)).to eq expected_results
          end

          it "returns empty array when assignment ids are not matched" do
            expected_results = []
            stub_get_lmgb_results("associated_asset_id_list=4,5&associated_asset_type=assign.type&external_outcome_id_list=1&artifact_type=quizzes.quiz&user_uuid_list=#{one_user_uuid}&per_page=200&page=1").to_return(status: 200, body: '{"results":[]}', headers: { "Per-Page" => 200, "Total" => 0 })
            expect(subject.get_lmgb_results(@course, "4,5", "assign.type", "1", one_user_uuid)).to eq expected_results
          end

          it "returns empty array when no outcome ids are matched" do
            expected_results = []
            stub_get_lmgb_results("associated_asset_id_list=1&associated_asset_type=assign.type&external_outcome_id_list=5&artifact_type=quizzes.quiz&user_uuid_list=#{one_user_uuid}&per_page=200&page=1").to_return(status: 200, body: '{"results":[]}', headers: { "Per-Page" => 200, "Total" => 0 })
            expect(subject.get_lmgb_results(@course, "1", "assign.type", "5", one_user_uuid)).to eq expected_results
          end

          it "returns empty array when no user uuids are matched" do
            expected_results = []
            stub_get_lmgb_results("associated_asset_id_list=1&associated_asset_type=assign.type&external_outcome_id_list=1&artifact_type=quizzes.quiz&user_uuid_list=fake_no_match_uuid&per_page=200&page=1").to_return(status: 200, body: '{"results":[]}', headers: { "Per-Page" => 200, "Total" => 0 })
            expect(subject.get_lmgb_results(@course, "1", "assign.type", "1", "fake_no_match_uuid")).to eq expected_results
          end

          it "returns empty array when artifact type is not matched" do
            expected_results = []
            stub_get_lmgb_results("associated_asset_id_list=1&associated_asset_type=assign.type&external_outcome_id_list=1&artifact_type=quizzes.quiz&user_uuid_list=#{one_user_uuid}&artifact_type=no.match.type&per_page=200&page=1").to_return(status: 200, body: '{"results":[]}', headers: { "Per-Page" => 200, "Total" => 0 })
            expect(subject.get_lmgb_results(@course, "1", "assign.type", "1", one_user_uuid, "no.match.type")).to eq expected_results
          end

          it "returns results with no artifact type" do
            expected_results = [{ result_one: "stuff1" }, { result_two: "stuff2" }]
            stub_get_lmgb_results("associated_asset_id_list=1,2&associated_asset_type=assign.type&external_outcome_id_list=1,2&user_uuid_list=#{one_user_uuid}&per_page=200&page=1").to_return(status: 200, body: '{"results":[{"result_one":"stuff1"},{"result_two":"stuff2"}]}', headers: { "Per-Page" => 200, "Total" => 2 })
            expect(subject.get_lmgb_results(@course, "1,2", "assign.type", "1,2", one_user_uuid, "")).to eq expected_results
          end

          context "pagination" do
            def get_results(num)
              Array.new(num) { |i| { "result_#{i}": "stuff#{i}" } }
            end

            def get_response(num)
              array_results = get_results(num)
              { results: array_results }.to_json
            end
            it "fetches each page and returns concatentated results" do
              stub_get_lmgb_results("associated_asset_id_list=1,2,3,4&associated_asset_type=assign.type&external_outcome_id_list=1,2,3,4&artifact_type=quizzes.quiz&user_uuid_list=#{one_user_uuid}&per_page=200&page=1").to_return(status: 200, body: get_response(200), headers: { "Per-Page" => 200, "Total" => 201 })
              stub_get_lmgb_results("associated_asset_id_list=1,2,3,4&associated_asset_type=assign.type&external_outcome_id_list=1,2,3,4&artifact_type=quizzes.quiz&user_uuid_list=#{one_user_uuid}&per_page=200&page=2").to_return(status: 200, body: '{"results":[{"result_200":"stuff200"}]}', headers: { "Per-Page" => 200, "Total" => 201 })
              expect(subject.get_lmgb_results(@course, "1,2,3,4", "assign.type", "1,2,3,4", one_user_uuid)).to eq get_results(201)
            end

            it "there are authoritative results" do
              a = new_quizzes_assignment(course: @course, title: "New Quiz")
              outcome = outcome_model(context: @course)
              stub_get_lmgb_results("associated_asset_id_list=#{a.id}&associated_asset_type=canvas.assignment.quizzes&external_outcome_id_list=#{outcome.id}&per_page=1&page=1").to_return(status: 200, body: get_response(1), headers: { "Per-Page" => 1, "Total" => 201 })
              expect(subject.outcome_has_authoritative_results?(outcome, @course)).to be true
            end

            it "there are no authoritative results" do
              a = new_quizzes_assignment(course: @course, title: "New Quiz")
              outcome = outcome_model(context: @course)
              stub_get_lmgb_results("associated_asset_id_list=#{a.id}&associated_asset_type=canvas.assignment.quizzes&external_outcome_id_list=#{outcome.id}&per_page=1&page=1").to_return(status: 200, body: '{"results":[]}', headers: { "Per-Page" => 1, "Total" => 0 })
              expect(subject.outcome_has_authoritative_results?(outcome, @course)).to be false
            end
          end
        end

        context "with outcome_service_results_to_canvas FF off" do
          before do
            @course.disable_feature!(:outcome_service_results_to_canvas)
          end

          it "returns nil when FF is off" do
            expect(subject.get_lmgb_results(@course, "1", "assign.type", "1", one_user_uuid)).to be_nil
          end
        end
      end
    end
  end

  describe "#get_lmgb_results by account" do
    context "with outcomes provision settings" do
      let(:user1) { User.create! }
      let(:one_user_uuid) { user1.uuid }

      before do
        settings = { consumer_key: "key", jwt_secret: "secret", domain: "domain" }
        account.settings[:provision] = { "outcomes" => settings }
        account.save!
      end

      context "with outcome_service_results_to_canvas FF off" do
        it "returns nil when FF is off" do
          expect(subject.get_lmgb_results(account, "1", "assign.type", "1", one_user_uuid)).to be_nil
        end
      end

      context "with outcome_service_results_to_canvas FF on" do
        before do
          account.enable_feature!(:outcome_service_results_to_canvas)
        end

        it "returns results with one assignment id" do
          expected_results = [{ result: "stuff" }]
          stub_get_lmgb_results("associated_asset_id_list=1&associated_asset_type=assign.type&external_outcome_id_list=1&artifact_type=quizzes.quiz&user_uuid_list=#{one_user_uuid}&per_page=200&page=1").to_return(status: 200, body: '{"results":[{"result":"stuff"}]}', headers: { "Per-Page" => 200, "Total" => 1 })
          expect(subject.get_lmgb_results(account, "1", "assign.type", "1", one_user_uuid)).to eq expected_results
        end

        def attempt(id, points, json_to_hash_with_symbol_keys: false)
          metadata = "{\"question_metadata\":[{\"quiz_item_id\":\"#{id}\",\"quiz_item_title\":\"Question #{id}\",\"points\":\"#{points}\",\"points_possible\":\"3.0\"}]}"
          if json_to_hash_with_symbol_keys
            metadata = JSON.parse(metadata).deep_symbolize_keys
            { id:, metadata: }
          else
            { "id" => id, "metadata" => metadata }
          end
        end

        it "can parse string metadata" do
          mocked_result = "{\"results\":[{\"associated_asset_id\":1,\"attempts\":[{\"id\":\"id\",\"metadata\":\"{\\\"quiz_metadata\\\":{\\\"quiz_id\\\":\\\"5\\\",\\\"title\\\":\\\"NewQuizOnePoint\\\",\\\"points_possible\\\":1.0,\\\"points\\\":0.0}}\"}]}]}"
          expected_results = [{
            associated_asset_id: 1,
            attempts: [{
              id: "id",
              metadata: {
                quiz_metadata: {
                  points: 0.0,
                  points_possible: 1.0,
                  quiz_id: "5",
                  title: "NewQuizOnePoint"
                }
              }
            }]
          }]
          stub_get_lmgb_results("associated_asset_id_list=1&associated_asset_type=assign.type&external_outcome_id_list=1&artifact_type=quizzes.quiz&user_uuid_list=#{one_user_uuid}&per_page=200&page=1")
            .to_return(status: 200, body: mocked_result, headers: { "Per-Page" => 200, "Total" => 2 })
          expect(subject.get_lmgb_results(account, "1", "assign.type", "1", one_user_uuid)).to eq expected_results
        end

        it "can parse null metadata" do
          mocked_result = "{\"results\":[{\"associated_asset_id\":1,\"attempts\":[{\"id\":\"id\",\"metadata\":\"null\"}]}]}"
          expected_results = [{
            associated_asset_id: 1,
            attempts: [{
              id: "id",
              metadata: nil
            }]
          }]
          stub_get_lmgb_results("associated_asset_id_list=1&associated_asset_type=assign.type&external_outcome_id_list=1&artifact_type=quizzes.quiz&user_uuid_list=#{one_user_uuid}&per_page=200&page=1")
            .to_return(status: 200, body: mocked_result, headers: { "Per-Page" => 200, "Total" => 2 })
          expect(subject.get_lmgb_results(account, "1", "assign.type", "1", one_user_uuid)).to eq expected_results
        end

        it "can parse json metadata" do
          mocked_result = "{\"results\":[{\"associated_asset_id\":1,\"attempts\":[{\"id\":\"id\",\"metadata\":{\"quiz_metadata\":{\"quiz_id\":\"5\",\"title\":\"NewQuizOnePoint\",\"points_possible\":1.0,\"points\":0.0}}}]}]}"
          expected_results = [{
            associated_asset_id: 1,
            attempts: [{
              id: "id",
              metadata: {
                quiz_metadata: {
                  points: 0.0,
                  points_possible: 1.0,
                  quiz_id: "5",
                  title: "NewQuizOnePoint"
                }
              }
            }]
          }]
          stub_get_lmgb_results("associated_asset_id_list=1&associated_asset_type=assign.type&external_outcome_id_list=1&artifact_type=quizzes.quiz&user_uuid_list=#{one_user_uuid}&per_page=200&page=1")
            .to_return(status: 200, body: mocked_result, headers: { "Per-Page" => 200, "Total" => 2 })
          expect(subject.get_lmgb_results(account, "1", "assign.type", "1", one_user_uuid)).to eq expected_results
        end

        it "returns parsed results, multiple results with multiple attempts" do
          mocked_result = { "results" => [
            {
              "associated_asset_id" => 1,
              "attempts" => [
                attempt(0, 0.0),
                attempt(1, 1.0)
              ]
            },
            {
              "associated_asset_id" => 2,
              "attempts" => [
                attempt(2, 2.0),
                attempt(3, 3.0)
              ]
            },
            {
              "associated_asset_id" => 3
            }
          ] }
          expected_results = [
            {
              associated_asset_id: 1,
              attempts: [
                attempt(0, 0.0, json_to_hash_with_symbol_keys: true),
                attempt(1, 1.0, json_to_hash_with_symbol_keys: true)
              ]
            },
            {
              associated_asset_id: 2,
              attempts: [
                attempt(2, 2.0, json_to_hash_with_symbol_keys: true),
                attempt(3, 3.0, json_to_hash_with_symbol_keys: true)
              ]
            },
            {
              associated_asset_id: 3
            }
          ]

          stub_get_lmgb_results("associated_asset_id_list=1&associated_asset_type=assign.type&external_outcome_id_list=1&artifact_type=quizzes.quiz&user_uuid_list=#{one_user_uuid}&per_page=200&page=1")
            .to_return(status: 200, body: mocked_result.to_json.to_s, headers: { "Per-Page" => 200, "Total" => 2 })

          expect(subject.get_lmgb_results(account, "1", "assign.type", "1", one_user_uuid)).to eq expected_results
        end
      end
    end
  end

  describe "#threaded_request" do
    before do
      settings = { consumer_key: "key", jwt_secret: "secret", domain: "domain" }
      account.settings[:provision] = { "outcomes" => settings }
      account.save!
    end

    def get_params(num_user_uuids, num_outcome_ids, num_asset_ids)
      {
        # using largest possible value for each datatype: character varying(255), bigint, bigit
        user_uuid_list: Array.new(num_user_uuids) { "5LdvHVebADW0o0gpkaYGugCyK3meOXiwRGqmjTi10DQrwrEr1fcg7q3X5nq9YRVkMHNMv9rq9F6vvM34vpKByHSxuogLeMWV7jel77rHSN5sRaaNDc7aYILY6AU918ZpfTAlu47Hy1dyj0mHnQwXXAoLmwW5Z1aDsrP5K012u3IBxFIanos8Ig4RzNt9AzM4HatWKs3HU3I42tqcvoLaPzCnQwhqNYOXpagxUrfDD2ZXfpqrm5jZhDzB8nCfaA2" }.join(","),
        external_outcome_id_list: Array.new(num_outcome_ids) { 9_223_372_036_854_775_807 }.join(","),
        associated_asset_id_list: Array.new(num_asset_ids) { 9_223_372_036_854_775_807 }.join(","),
        static_parameter: "static.value"
      }
    end

    # context, scope, endpoint, sliced_params, static_params
    context "does not thread request" do
      it "if sliced_params are under the slice maximums" do
        expect(subject).to receive(:get_request).once
        subject.threaded_request(@course, "lmgb_results.show", "api/endpoint", get_params(1, 1, 1))
      end
    end

    # context, scope, endpoint, sliced_params, static_params
    context "uses threaded requests" do
      it "sliced_params are over the slice maximums" do
        expect(subject).to receive(:get_request).at_least(:twice)
        subject.threaded_request(@course, "lmgb_results.show", "api/endpoint", get_params(250, 250, 250))
      end
    end
  end

  describe "#build_request_url" do
    it "add params if present" do
      params = { param: "stuff" }
      expect(subject.build_request_url("protocol", "domain", "endpoint", params)).to eq "protocol://domain/endpoint?param=stuff"
    end

    it "does not add params when not present" do
      params = {}
      expect(subject.build_request_url("protocol", "domain", "endpoint", params)).to eq "protocol://domain/endpoint"
      params = nil
      expect(subject.build_request_url("protocol", "domain", "endpoint", params)).to eq "protocol://domain/endpoint"
    end
  end
end
