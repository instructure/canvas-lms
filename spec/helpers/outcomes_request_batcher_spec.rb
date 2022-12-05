# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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
describe OutcomesRequestBatcher do
  before do
    course_with_teacher_logged_in(active_all: true)
    @course.enable_feature!(:outcome_service_results_to_canvas)
  end

  context "when not provisioned with outcome service" do
    it "returns no requests" do
      params = {
        associated_asset_id_list: "asset_ids",
        associated_asset_type: "assign.type",
        external_outcome_id_list: "outcome_ids",
        user_uuid_list: "user_ids"
      }
      batcher = OutcomesRequestBatcher.new("http", "endpoint", @course, "lmgb_results.show", params)
      requests = batcher.requests
      expect(requests.size).to eq 0
    end
  end

  context "when provisioned with outcome service" do
    before do
      settings = { consumer_key: "key", jwt_secret: "secret", domain: "domain" }
      @course.root_account.settings[:provision] = { "outcomes" => settings }
      @course.root_account.save!
    end

    it "nothing to split" do
      expected_asset_ids = (1..10).to_a.join(",")
      expected_outcome_ids = (1..10).to_a.join(",")
      expected_user_ids = (1..10).to_a.map { |x| "5Iiwic2NvcGUiOiJsbWdiX3Jlc3VsdHMuc2hvdyIsImV4cCI6MTY2O-#{x}" }.join(",")
      params = {
        associated_asset_id_list: expected_asset_ids,
        associated_asset_type: "assign.type",
        external_outcome_id_list: expected_outcome_ids,
        user_uuid_list: expected_user_ids
      }
      batcher = OutcomesRequestBatcher.new("http", "endpoint", @course, "lmgb_results.show", params)
      requests = batcher.requests
      expect(requests.size).to eq 1
      request = requests[0]

      expect(request[:jwt].bytesize).to eq 1190
      expect(request[:domain]).to eq "domain"
      expect(request[:params][:associated_asset_id_list]).to eq expected_asset_ids
      expect(request[:params][:associated_asset_type]).to eq "assign.type"
      expect(request[:params][:external_outcome_id_list]).to eq expected_outcome_ids
      expect(request[:params][:user_uuid_list]).to eq expected_user_ids
    end

    it "splitting large request" do
      params = {
        associated_asset_id_list: (1..1000).to_a.join(","),
        associated_asset_type: "assign.type",
        external_outcome_id_list: (1..1000).to_a.join(","),
        user_uuid_list: (1..49).to_a.map { |x| "5Iiwic2NvcGUiOiJsbWdiX3Jlc3VsdHMuc2hvdyIsImV4cCI6MTY2O-#{x}" }.join(",")
      }
      batcher = OutcomesRequestBatcher.new("http", "endpoint", @course, "lmgb_results.show", params)
      requests = batcher.requests
      expect(requests.size).to eq 16

      # Splitting is a bit weird in regards to what parameter it picks to split. All of these are used for the
      # expected_results array to make reading this test easier.
      asset_ids_first_quarter = (1..250).to_a.join(",")
      asset_ids_second_quarter = (251..500).to_a.join(",")
      asset_ids_third_quarter = (501..750).to_a.join(",")
      asset_ids_forth_quarter = (751..1000).to_a.join(",")
      asset_ids_first_half = (1..500).to_a.join(",")

      outcome_ids_third_quarter  = (501..750).to_a.join(",")
      outcome_ids_forth_quarter  = (751..1000).to_a.join(",")
      outcome_ids_first_half     = (1..500).to_a.join(",")
      outcome_ids_last_half      = (501..1000).to_a.join(",")

      user_ids_first_half = (1..25).to_a.map { |x| "5Iiwic2NvcGUiOiJsbWdiX3Jlc3VsdHMuc2hvdyIsImV4cCI6MTY2O-#{x}" }.join(",")
      user_ids_last_half = (26..49).to_a.map { |x| "5Iiwic2NvcGUiOiJsbWdiX3Jlc3VsdHMuc2hvdyIsImV4cCI6MTY2O-#{x}" }.join(",")

      # Important thing is that all permutations are called
      expected_results = [
        [asset_ids_first_quarter, outcome_ids_first_half, user_ids_first_half],
        [asset_ids_second_quarter, outcome_ids_first_half, user_ids_first_half],
        [asset_ids_first_quarter, outcome_ids_first_half, user_ids_last_half],
        [asset_ids_second_quarter, outcome_ids_first_half, user_ids_last_half],
        [asset_ids_first_half, outcome_ids_third_quarter, user_ids_first_half],
        [asset_ids_first_half, outcome_ids_forth_quarter, user_ids_first_half],
        [asset_ids_first_half, outcome_ids_third_quarter, user_ids_last_half],
        [asset_ids_first_half, outcome_ids_forth_quarter, user_ids_last_half],
        [asset_ids_third_quarter, outcome_ids_first_half, user_ids_first_half],
        [asset_ids_forth_quarter, outcome_ids_first_half, user_ids_first_half],
        [asset_ids_third_quarter, outcome_ids_first_half, user_ids_last_half],
        [asset_ids_forth_quarter, outcome_ids_first_half, user_ids_last_half],
        [asset_ids_third_quarter, outcome_ids_last_half, user_ids_first_half],
        [asset_ids_forth_quarter, outcome_ids_last_half, user_ids_first_half],
        [asset_ids_third_quarter, outcome_ids_last_half, user_ids_last_half],
        [asset_ids_forth_quarter, outcome_ids_last_half, user_ids_last_half],
      ]

      requests.each_with_index do |request, index|
        expected_asset_ids = expected_results[index][0]
        expected_outcome_ids = expected_results[index][1]
        expected_user_ids = expected_results[index][2]
        expect(request[:jwt].bytesize).to be <= 8_000
        expect(request[:domain]).to eq "domain"
        expect(request[:params][:associated_asset_id_list]).to eq expected_asset_ids
        expect(request[:params][:associated_asset_type]).to eq "assign.type"
        expect(request[:params][:external_outcome_id_list]).to eq expected_outcome_ids
        expect(request[:params][:user_uuid_list]).to eq expected_user_ids
      end
    end

    it "large request that cannot be split" do
      expected_asset_ids = (1..1000).to_a.join("x")
      expected_outcome_ids = (1..1000).to_a.join("x")
      expected_user_ids = (1..49).to_a.map { "5Iiwic2NvcGUiOiJsbWdiX3Jlc3VsdHMuc2hvdyIsImV4cCI6MTY2O" }.join("x")
      params = {
        associated_asset_id_list: expected_asset_ids,
        associated_asset_type: "assign.type",
        external_outcome_id_list: expected_outcome_ids,
        user_uuid_list: expected_user_ids
      }
      batcher = OutcomesRequestBatcher.new("http", "endpoint", @course, "lmgb_results.show", params)
      requests = batcher.requests
      expect(requests.size).to eq 1
      request = requests[0]
      expect(request[:jwt].bytesize).to eq 14_347
      expect(request[:domain]).to eq "domain"
      expect(request[:params][:associated_asset_id_list]).to eq expected_asset_ids
      expect(request[:params][:associated_asset_type]).to eq "assign.type"
      expect(request[:params][:external_outcome_id_list]).to eq expected_outcome_ids
      expect(request[:params][:user_uuid_list]).to eq expected_user_ids
    end
  end
end
