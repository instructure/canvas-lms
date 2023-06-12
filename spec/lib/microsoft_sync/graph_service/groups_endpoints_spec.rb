# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module MicrosoftSync::GraphService::GroupsEndpoints::SpecHelper
  extend self

  SAMPLE_RESPONSES_CODES_BODIES_HEADERS = {
    success: [204, nil],
    error400: [400, "bad"],
    error500: [500, "bad2"],
    throttled: [429, "badthrottled"],
    throttled123: [429, "badthrottled", { "Retry-After" => "123" }],
    throttled456: [429, "badthrottled", { "Retry-After" => "456" }],

    add_duplicate: [400, { error: { code: "Request_BadRequest", message: "One or more added object references already exist for the following modified properties: 'members'." } }],
    add_owners_quota_exceeded: [403, { error: { code: "Directory_QuotaExceeded", message: "Unable to perform operation as '121' would exceed the maximum quota count '100' for forward-link owners." } }],
    add_members_quota_exceeded: [403, { error: { code: "Directory_QuotaExceeded", message: "Unable to perform operation as '121' would exceed the maximum quota count '100' for forward-link members." } }],
    add_nonexistent_m1_user: [404, { error: { code: "Request_ResourceNotFound", message: "Resource 'm1' does not exist or one of its queried reference-property objects are not present." } }],
    add_nonexistent_o1_user: [404, { error: { code: "Request_ResourceNotFound", message: "Resource 'o1' does not exist or one of its queried reference-property objects are not present." } }],
    add_nonexistent_group: [404, { error: { code: "Request_ResourceNotFound", message: "Resource 'msgroupid' does not exist or one of its queried reference-property objects are not present." } }],

    remove_missing: [404, { error: { code: "Request_ResourceNotFound", msg: "Resource '12345689-1212-1212-1212-abc212121212' does not exist or one of its queried reference-property objects are not present." } }],
    # This style seems to happen if we remove with the API after (right after?) removing from the UI:
    remove_missing2: [400, { error: { code: "Request_BadRequest", message: "One or more removed object references do not exist for the following modified properties: 'members'." } }],
    remove_last_owner: [400, { error: { code: "Request_BadRequest", message: "The group must have at least one owner, hence this owner cannot be removed." } }],
  }.freeze

  def build_batch_response_body(request_ids, _batch_request_types)
    responses = batch_response_types.zip(request_ids).map do |type, req_id|
      code, body, headers = SAMPLE_RESPONSES_CODES_BODIES_HEADERS[type] || raise("bad type #{type}")
      { id: req_id, status: code, body:, headers: }.compact
    end
    { responses: }
  end

  def json_response_from_sample(type)
    json_response(*SAMPLE_RESPONSES_CODES_BODIES_HEADERS[type])
  end

  def status_code_for_sample_type(type)
    SAMPLE_RESPONSES_CODES_BODIES_HEADERS[type].first || raise("bad type")
  end
end

describe MicrosoftSync::GraphService::GroupsEndpoints do
  include MicrosoftSync::GraphService::GroupsEndpoints::SpecHelper
  include_context "microsoft_sync_graph_service_endpoints"

  describe "#update_group" do
    subject { endpoints.update("msgroupid", abc: { def: "ghi" }) }

    let(:http_method) { :patch }
    let(:url) { "https://graph.microsoft.com/v1.0/groups/msgroupid" }
    let(:with_params) { { body: { abc: { def: "ghi" } } } }
    let(:response) { { status: 204, body: "" } }

    it { is_expected.to be_nil }

    it_behaves_like "a graph service endpoint"
    it_behaves_like "an endpoint that uses up quota", [1, 1]
  end

  describe "#add_users_ignore_duplicates" do
    subject do
      endpoints.add_users_ignore_duplicates(
        "msgroupid", members:, owners:
      )
    end

    let(:members) { Set.new %w[m1 m2] }
    let(:owners) { Set.new %w[o1 o2] }

    let(:url) { "https://graph.microsoft.com/v1.0/groups/msgroupid" }
    let(:http_method) { :patch }
    let(:with_params) { { body: req_body } }
    let(:req_body) do
      {
        "members@odata.bind" => %w[
          https://graph.microsoft.com/v1.0/directoryObjects/m1
          https://graph.microsoft.com/v1.0/directoryObjects/m2
        ],
        "owners@odata.bind" => %w[
          https://graph.microsoft.com/v1.0/directoryObjects/o1
          https://graph.microsoft.com/v1.0/directoryObjects/o2
        ]
      }
    end
    let(:response) { { status: 204, body: "" } }

    it_behaves_like "a graph service endpoint"

    it { is_expected.to be_nil }

    context "when members is not given" do
      subject { endpoints.add_users_ignore_duplicates("msgroupid", owners:) }

      let(:req_body) { super().slice("owners@odata.bind") }

      it { is_expected.to be_nil }
    end

    context "when owners is not given" do
      subject { endpoints.add_users_ignore_duplicates("msgroupid", members:) }

      let(:req_body) { super().slice("members@odata.bind") }

      it { is_expected.to be_nil }
    end

    context "when members and owners are not given" do
      it "raises an ArgumentError" do
        expect { endpoints.add_users_ignore_duplicates("msgroupid") }.to \
          raise_error(ArgumentError, "Missing members/owners")
      end
    end

    context "when 20 users are given" do
      subject { endpoints.add_users_ignore_duplicates("msgroupid", members: (1..20).map(&:to_s)) }

      let(:req_body) do
        {
          "members@odata.bind" =>
            (1..20).map { |i| "https://graph.microsoft.com/v1.0/directoryObjects/#{i}" }
        }
      end

      it { is_expected.to be_nil }

      # Microsoft told us write quota is about one per three users...
      it_behaves_like "an endpoint that uses up quota", [1, 7]
    end

    context "when more than 20 users are given" do
      it "raises an ArgumentError" do
        expect do
          endpoints.add_users_ignore_duplicates(
            "msgroupid", members: ["x"] * 10, owners: ["y"] * 11
          )
        end.to raise_error(
          ArgumentError, "Only 20 users can be batched at once. Got 21."
        )
      end
    end

    shared_examples_for "a fallback to the batch api" do
      it "falls back to the batch api" do
        expect(endpoints).to receive(:add_users_via_batch)
          .with("msgroupid", members, owners).and_return("foo")
        expect(subject).to eq("foo")
      end

      it 'increments the "expected" counter' do
        allow(endpoints).to receive(:add_users_via_batch)
        subject
        expect(InstStatsd::Statsd).to have_received(:increment)
          .with("microsoft_sync.graph_service.expected",
                tags: hash_including(msft_endpoint: "patch_groups"))
      end
    end

    %w[members owners].each do |members_or_owners|
      context "when the PATCH endpoint returns a '#{members_or_owners} quota exceeded' error" do
        let(:response) { json_response_from_sample(:"add_#{members_or_owners}_quota_exceeded") }

        it_behaves_like "a fallback to the batch api"
      end
    end

    context "when some users are already in the group" do
      let(:response) { json_response_from_sample(:add_duplicate) }

      it_behaves_like "a fallback to the batch api"
    end

    context "when some users cannot be found on the microsoft side" do
      let(:response) { json_response_from_sample(:add_nonexistent_o1_user) }

      it_behaves_like "a fallback to the batch api"
    end

    context "when the group cannot be found on the microsoft side" do
      let(:response) { json_response_from_sample(:add_nonexistent_group) }

      it "raises a GroupNotFound error" do
        expect { subject }.to raise_error(MicrosoftSync::Errors::GroupNotFound)
      end
    end
  end

  describe "#list_members" do
    let(:method_name) { :list_members }
    let(:method_args) { ["mygroup"] }
    let(:url) { "https://graph.microsoft.com/v1.0/groups/mygroup/members" }

    it_behaves_like "a paginated list endpoint" do
      it_behaves_like "an endpoint that uses up quota", [3, 0]
    end
  end

  describe "#list_owners" do
    let(:method_name) { :list_owners }
    let(:method_args) { ["mygroup"] }
    let(:url) { "https://graph.microsoft.com/v1.0/groups/mygroup/owners" }
    let(:url_variables) { ["mygroup"] }

    it_behaves_like "a paginated list endpoint" do
      it_behaves_like "an endpoint that uses up quota", [2, 0]
    end
  end

  #### BATCH ENDPOINTS ###

  # Sets `batch_response_types` and `status` and expects subject to use those.
  # Tests that the proper error is raised and that it increments the statsd counters
  # for each subresponse type
  shared_examples_for "a members/owners batch request that can fail" do |ignored_type:, endpoint_name:|
    ignored_code = MicrosoftSync::GraphService::GroupsEndpoints::SpecHelper
                   .status_code_for_sample_type(ignored_type)

    {
      [ignored_type, :success, :error400, :success] => {
        throttled: false,
        bad_codes: [400],
        bad_bodies: %w[bad],
        statsd_codes: { success: [204, 204], error: 400, ignored: ignored_code }
      },
      # Mixed error types:
      %i[success error400 error400 error500] => {
        throttled: false,
        bad_codes: [400, 400, 500],
        bad_bodies: %w[bad bad bad2],
        statsd_codes: { success: [204], error: [400, 400, 500] },
      },
      [ignored_type, :throttled, :throttled, :success] => {
        throttled: true,
        bad_codes: [429, 429],
        bad_bodies: %w[badthrottled badthrottled],
        statsd_codes: { success: 204, throttled: [429, 429], ignored: ignored_code },
        retry_delay: nil
      },
      [ignored_type, :throttled, :throttled123, :success] => {
        throttled: true,
        bad_codes: [429, 429],
        bad_bodies: %w[badthrottled badthrottled],
        statsd_codes: { success: 204, throttled: [429, 429], ignored: ignored_code },
        retry_delay: 123
      },
      [ignored_type, :throttled123, :throttled456, :success] => {
        throttled: true,
        bad_codes: [429, 429],
        bad_bodies: %w[badthrottled badthrottled],
        statsd_codes: { success: 204, throttled: [429, 429], ignored: ignored_code },
        # Uses the greater retry delay:
        retry_delay: 456
      },
      [ignored_type, :error400, :throttled, :success] => {
        throttled: true,
        bad_codes: [400, 429],
        bad_bodies: %w[bad badthrottled],
        statsd_codes: { success: 204, error: 400, throttled: 429, ignored: ignored_code },
      },
    }.each do |response_types, params|
      context "when batch response types are #{response_types.inspect}" do
        let(:batch_response_types) { response_types }

        it "raises an error with a message with the codes/bodies" do
          expected_error = if params[:throttled]
                             MicrosoftSync::GraphService::Http::BatchRequestThrottled
                           else
                             MicrosoftSync::GraphService::Http::BatchRequestFailed
                           end
          expected_message = "Batch of #{params[:bad_codes].count}: " \
                             "codes #{params[:bad_codes]}, bodies #{params[:bad_bodies].inspect}"
          expect { subject }.to raise_error(expected_error, expected_message) do |e|
            expect(e).to be_a_microsoft_sync_public_error(/while making a batch request/)
          end
        end

        it "increments statsd counters based on the responses" do
          expect { subject }.to raise_error(/Batch of.*codes/)

          params[:statsd_codes].each do |type, codes_list|
            codes_list = [codes_list].flatten
            codes_list.uniq.each do |code|
              expect(InstStatsd::Statsd).to have_received(:count).once.with(
                "microsoft_sync.graph_service.batch.#{type}", codes_list.count(code), tags: {
                  msft_endpoint: endpoint_name, status: code, extra_tag: "abc"
                }
              )
            end
          end
        end

        if params[:retry_relay]
          it "raises an error with the proper retry delay" do
            expect { subject }.to raise_error(e) do
              expect(e.retry_after_seconds).to eq(params[:retry_delay])
            end
          end
        end
      end
    end
  end

  describe "#add_users_via_batch" do
    subject do
      endpoints.add_users_via_batch("msgroupid", %w[m1 m2], %w[o1 o2])
               .issues_by_member_type.symbolize_keys.transform_values(&:symbolize_keys)
    end

    let(:url) { "https://graph.microsoft.com/v1.0/$batch" }
    let(:http_method) { :post }
    let(:with_params) { { body: { requests: batch_requests } } }
    let(:batch_requests) do
      [
        {
          id: "members_m1",
          url: "/groups/msgroupid/members/$ref",
          method: "POST",
          body: { "@odata.id": "https://graph.microsoft.com/v1.0/directoryObjects/m1" },
          headers: { "Content-Type": "application/json" }
        },
        {
          id: "members_m2",
          url: "/groups/msgroupid/members/$ref",
          method: "POST",
          body: { "@odata.id": "https://graph.microsoft.com/v1.0/directoryObjects/m2" },
          headers: { "Content-Type": "application/json" }
        },
        {
          id: "owners_o1",
          url: "/groups/msgroupid/owners/$ref",
          method: "POST",
          body: { "@odata.id": "https://graph.microsoft.com/v1.0/directoryObjects/o1" },
          headers: { "Content-Type": "application/json" }
        },
        {
          id: "owners_o2",
          url: "/groups/msgroupid/owners/$ref",
          method: "POST",
          body: { "@odata.id": "https://graph.microsoft.com/v1.0/directoryObjects/o2" },
          headers: { "Content-Type": "application/json" }
        },
      ]
    end

    let(:status) { 200 }
    let(:response_body) { build_batch_response_body(request_ids, batch_response_types) }
    let(:batch_response_types) { [] }
    let(:request_ids) { %w[members_m1 members_m2 owners_o1 owners_o2] }

    it_behaves_like "a members/owners batch request that can fail",
                    ignored_type: :add_duplicate,
                    endpoint_name: "group_add_users"

    it "passes along the quota used to run_batch" do
      expect(endpoints.http).to receive(:run_batch)
        .with(anything, anything, hash_including(quota: [4, 4]))
        .and_call_original
      subject
    end

    {
      # all are successfully added:
      %i[success success success success] => {},
      # some owners were already in the group:
      %i[success success success add_duplicate] =>
        { owners: { o2: :already_in_group } },
      # some members were already in the group:
      %i[add_duplicate add_duplicate success success] =>
        { members: { m1: :already_in_group, m2: :already_in_group } },
      # some members and owners were already in the group:
      %i[add_duplicate success add_duplicate add_duplicate] =>
        { members: { m1: :already_in_group }, owners: { o1: :already_in_group, o2: :already_in_group } },
      # Trying to add member that doesn't exist:
      %i[add_nonexistent_m1_user success success success] =>
        { members: { m1:
                    MicrosoftSync::GraphService::GroupMembershipChangeResult::NONEXISTENT_USER } },
      # Trying to add o1 user (owner) but o1 doesn't exist:
      %i[success success add_nonexistent_o1_user success] =>
        { owners: { o1:
                    MicrosoftSync::GraphService::GroupMembershipChangeResult::NONEXISTENT_USER } },
      # Trying to add o2 user, got message saying something else (o1) didn't exist:
      %i[success success success add_nonexistent_o1_user] =>
        MicrosoftSync::GraphService::Http::BatchRequestFailed,
      %i[add_duplicate success success add_owners_quota_exceeded] =>
        MicrosoftSync::Errors::OwnersQuotaExceeded,
      %i[add_duplicate success success add_members_quota_exceeded] =>
        MicrosoftSync::Errors::MembersQuotaExceeded,
    }.each do |types, result|
      context "when the batch responses are: #{types.inspect}" do
        let(:batch_response_types) { types }

        if result.is_a?(Class)
          it { expect { subject }.to raise_error(result) }
        else
          it { is_expected.to eq(result) }
        end
      end
    end
  end

  describe "#remove_users_ignore_missing" do
    subject do
      endpoints
        .remove_users_ignore_missing("msgroupid", members: %w[m1 m2], owners: %w[o1 o2])
        .issues_by_member_type.symbolize_keys.transform_values(&:symbolize_keys)
    end

    let(:url) { "https://graph.microsoft.com/v1.0/$batch" }
    let(:http_method) { :post }
    let(:with_params) { { body: { requests: batch_requests } } }
    let(:batch_requests) do
      [
        { id: "members_m1", url: "/groups/msgroupid/members/m1/$ref", method: "DELETE" },
        { id: "members_m2", url: "/groups/msgroupid/members/m2/$ref", method: "DELETE" },
        { id: "owners_o1", url: "/groups/msgroupid/owners/o1/$ref", method: "DELETE" },
        { id: "owners_o2", url: "/groups/msgroupid/owners/o2/$ref", method: "DELETE" }
      ]
    end

    let(:status) { 200 }
    let(:response_body) { build_batch_response_body(request_ids, batch_response_types) }
    let(:request_ids) { %w[members_m1 members_m2 owners_o1 owners_o2] }
    let(:batch_response_types) { [] }

    it_behaves_like "a members/owners batch request that can fail",
                    ignored_type: :remove_missing,
                    endpoint_name: "group_remove_users"

    it "passes along the quota used to run_batch" do
      expect(endpoints.http).to receive(:run_batch)
        .with(anything, anything, hash_including(quota: [4, 4]))
        .and_call_original
      subject
    end

    {
      # all successfully removed:
      %i[success success success success] => {},
      # some owners were not in the group:
      %i[success success success remove_missing] =>
        { owners: { o2: :ignored } },
      # some members were not in the group:
      %i[remove_missing remove_missing success success] =>
        { members: { m1: :ignored, m2: :ignored } },
      # some members were not in the group (alternate response format)
      %i[remove_missing2 remove_missing2 success success] =>
        { members: { m1: :ignored, m2: :ignored } },
      # some members and owners were not in the group
      %i[remove_missing success remove_missing remove_missing] =>
        { members: { m1: :ignored }, owners: { o1: :ignored, o2: :ignored } },
    }.each do |types, result|
      context "when the batch responses are: #{types.inspect}" do
        let(:batch_response_types) { types }

        it { is_expected.to eq(result) }
      end
    end

    context "when the last owner in a group is removed" do
      let(:batch_response_types) { %i[success success remove_last_owner success] }

      it "raises an MissingOwners" do
        expect { subject }.to raise_microsoft_sync_graceful_cancel_error(
          MicrosoftSync::Errors::MissingOwners, /must have owners/
        )
      end
    end

    context "when more than 20 users are given" do
      it "raises an ArgumentError" do
        expect do
          endpoints.remove_users_ignore_missing(
            "msgroupid", members: ["x"] * 10, owners: ["y"] * 11
          )
        end.to raise_error(ArgumentError, "Only 20 users can be batched at once. Got 21.")
      end
    end
  end
end
