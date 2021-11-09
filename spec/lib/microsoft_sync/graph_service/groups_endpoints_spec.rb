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

describe MicrosoftSync::GraphService::GroupsEndpoints do
  include_context 'microsoft_sync_graph_service_endpoints'

  def succ(id)
    { id: id, status: 204, body: nil }
  end

  def err(id)
    { id: id, status: 400, body: "bad" }
  end

  def err2(id)
    { id: id, status: 500, body: "bad2" }
  end

  def throttled(id, retry_after = nil)
    resp = { id: id, status: 429, body: "badthrottled" }
    resp[:headers] = { 'Retry-After' => retry_after.to_s } if retry_after
    resp
  end

  shared_examples_for 'a batch request that fails' do
    it 'raises an error with a message with the codes/bodies' do
      expected_message = "Batch of #{bad_codes.count}: codes #{bad_codes}, bodies #{bad_bodies.inspect}"
      expect { subject }.to raise_error(expected_error, expected_message) do |e|
        expect(e).to be_a_microsoft_sync_public_error(/while making a batch request/)
      end
    end

    it 'increments statsd counters based on the responses' do
      expect { subject }.to raise_error(expected_error)

      codes.each do |type, codes_list|
        codes_list = [codes_list].flatten
        codes_list.uniq.each do |code|
          expect(InstStatsd::Statsd).to have_received(:count).once.with(
            "microsoft_sync.graph_service.batch.#{type}", codes_list.count(code), tags: {
              msft_endpoint: endpoint_name, status: code, extra_tag: 'abc'
            }
          )
        end
      end
    end
  end

  shared_examples_for 'a members/owners batch request that can fail' do
    let(:ignored_code) { ignored_members_m1_response[:status] }
    let(:expected_error) { MicrosoftSync::GraphService::Http::BatchRequestFailed }

    context 'a batch request with an errored subrequest' do
      it_behaves_like 'a batch request that fails' do
        let(:bad_codes) { [400] }
        let(:bad_bodies) { %w[bad] }
        let(:codes) { { success: [204, 204], error: 400, ignored: ignored_code } }
        let(:batch_responses) do
          [ignored_members_m1_response, succ('members_m2'), err('owners_o1'), succ('owners_o2')]
        end
      end
    end

    context 'a batch request with different types of errored subrequests' do
      it_behaves_like 'a batch request that fails' do
        let(:bad_codes) { [400, 400, 500] }
        let(:bad_bodies) { %w[bad bad bad2] }
        let(:codes) { { success: 204, error: [400, 400, 500] } }
        let(:batch_responses) do
          [err('members_m1'), err('members_m2'), err2('owners_o1'), succ('owners_o2')]
        end
      end
    end

    context 'a batch request with two throttled subrequests' do
      let(:batch_responses) do
        [
          ignored_members_m1_response,
          throttled('members_m2', retry_delay1), throttled('owners_o1', retry_delay2),
          succ('owners_o2')
        ]
      end

      let(:retry_delay1) { nil }
      let(:retry_delay2) { nil }

      it_behaves_like 'a batch request that fails' do
        let(:bad_codes) { [429, 429] }
        let(:bad_bodies) { %w[badthrottled badthrottled] }
        let(:codes) { { success: 204, throttled: [429, 429], ignored: ignored_code } }
        let(:expected_error) { MicrosoftSync::GraphService::Http::BatchRequestThrottled }
      end

      context 'when no response has a retry delay' do
        it 'raises an error with retry_after_delay of nil' do
          expect { subject }.to raise_error(MicrosoftSync::Errors::Throttled) do |e|
            expect(e.retry_after_seconds).to eq(nil)
          end
        end
      end

      context 'when one response has a retry delay' do
        let(:retry_delay1) { '1.23' }

        it 'raises an error with that retry delay' do
          expect { subject }.to raise_error { |e| expect(e.retry_after_seconds).to eq(1.23) }
        end
      end

      context 'when both responses have a retry delay' do
        let(:retry_delay1) { '1.23' }
        let(:retry_delay2) { '2.34' }

        it 'raises an error with the greater retry delay' do
          expect { subject }.to raise_error { |e| expect(e.retry_after_seconds).to eq(2.34) }
        end
      end
    end

    context 'a batch request with throttled and errored subrequests' do
      let(:bad_codes) { [400, 429] }
      let(:bad_bodies) { %w[bad badthrottled] }
      let(:codes) { { success: 204, error: 400, throttled: 429, ignored: ignored_code } }
      let(:batch_responses) do
        [
          ignored_members_m1_response,
          err('members_m2'), throttled('owners_o1'), succ('owners_o2')
        ]
      end
      let(:expected_error) { MicrosoftSync::GraphService::Http::BatchRequestThrottled }

      it_behaves_like 'a batch request that fails'

      context 'when the overall response is a 424' do
        let(:batch_overall_response_code) { 424 }

        it_behaves_like 'a batch request that fails'
      end
    end
  end

  #### INDIVIDUAL METHODS / ENDPOINTS

  describe '#update_group' do
    subject { endpoints.update('msgroupid', abc: { def: 'ghi' }) }

    let(:http_method) { :patch }
    let(:url) { 'https://graph.microsoft.com/v1.0/groups/msgroupid' }
    let(:with_params) { { body: { abc: { def: 'ghi' } } } }
    let(:response) { { status: 204, body: '' } }

    it { is_expected.to eq(nil) }

    it_behaves_like 'a graph service endpoint'
    it_behaves_like 'an endpoint that uses up quota', [1, 1]
  end

  describe '#add_users_ignore_duplicates' do
    subject do
      endpoints.add_users_ignore_duplicates(
        'msgroupid', members: members, owners: owners
      )
    end

    let(:members) { Set.new %w[m1 m2] }
    let(:owners) { Set.new %w[o1 o2] }

    let(:http_method) { :patch }
    let(:url) { 'https://graph.microsoft.com/v1.0/groups/msgroupid' }
    let(:with_params) { { body: req_body } }
    let(:req_body) do
      {
        'members@odata.bind' => %w[
          https://graph.microsoft.com/v1.0/directoryObjects/m1
          https://graph.microsoft.com/v1.0/directoryObjects/m2
        ],
        'owners@odata.bind' => %w[
          https://graph.microsoft.com/v1.0/directoryObjects/o1
          https://graph.microsoft.com/v1.0/directoryObjects/o2
        ]
      }
    end
    let(:response) { { status: 204, body: '' } }

    it_behaves_like 'a graph service endpoint'

    it { is_expected.to eq(nil) }

    context 'when members is not given' do
      subject { endpoints.add_users_ignore_duplicates('msgroupid', owners: owners) }

      let(:req_body) { super().slice('owners@odata.bind') }

      it { is_expected.to eq(nil) }
    end

    context 'when owners is not given' do
      subject { endpoints.add_users_ignore_duplicates('msgroupid', members: members) }

      let(:req_body) { super().slice('members@odata.bind') }

      it { is_expected.to eq(nil) }
    end

    context 'when members and owners are not given' do
      it 'raises an ArgumentError' do
        expect { endpoints.add_users_ignore_duplicates('msgroupid') }.to \
          raise_error(ArgumentError, 'Missing members/owners')
      end
    end

    context 'when 20 users are given' do
      subject { endpoints.add_users_ignore_duplicates('msgroupid', members: (1..20).map(&:to_s)) }

      let(:req_body) do
        {
          'members@odata.bind' =>
            (1..20).map { |i| "https://graph.microsoft.com/v1.0/directoryObjects/#{i}" }
        }
      end

      it { is_expected.to eq(nil) }

      # Microsoft told us write quota is about one per three users...
      it_behaves_like 'an endpoint that uses up quota', [1, 7]
    end

    context 'when more than 20 users are given' do
      it 'raises an ArgumentError' do
        expect {
          endpoints.add_users_ignore_duplicates(
            'msgroupid', members: ['x'] * 10, owners: ['y'] * 11
          )
        }.to raise_error(
          ArgumentError, "Only 20 users can be batched at once. Got 21."
        )
      end
    end

    %w[members owners].each do |members_or_owners|
      context "when the PATCH endpoint returns a '#{members_or_owners} quota exceeded' error" do
        let(:response) do
          {
            status: 403,
            body: {
              code: "Directory_QuotaExceeded",
              message: "Unable to perform operation as '121' would exceed the maximum quota count '100' for forward-link '#{members_or_owners}'.",
            }.to_json
          }
        end

        it 'falls back to the batch api' do
          expect(endpoints).to receive(:add_users_via_batch)
            .with('msgroupid', members, owners).and_return('foo')
          expect(subject).to eq('foo')
        end
      end
    end

    context 'when using JSON batching because some users already exist' do
      let(:response) { { status: 400, body: 'One or more added object references already exist' } }
      let(:batch_overall_response_code) { 200 }
      let(:batch_url) { 'https://graph.microsoft.com/v1.0/$batch' }
      let(:batch_method) { :post }
      let(:batch_body) do
        {
          requests: [
            {
              id: "members_m1", url: "/groups/msgroupid/members/$ref", method: "POST",
              body: { "@odata.id": "https://graph.microsoft.com/v1.0/directoryObjects/m1" },
              headers: { "Content-Type": "application/json" }
            },
            {
              id: "members_m2", url: "/groups/msgroupid/members/$ref", method: "POST",
              body: { "@odata.id": "https://graph.microsoft.com/v1.0/directoryObjects/m2" },
              headers: { "Content-Type": "application/json" }
            },
            {
              id: "owners_o1", url: "/groups/msgroupid/owners/$ref", method: "POST",
              body: { "@odata.id": "https://graph.microsoft.com/v1.0/directoryObjects/o1" },
              headers: { "Content-Type": "application/json" }
            },
            {
              id: "owners_o2", url: "/groups/msgroupid/owners/$ref", method: "POST",
              body: { "@odata.id": "https://graph.microsoft.com/v1.0/directoryObjects/o2" },
              headers: { "Content-Type": "application/json" }
            }
          ]
        }
      end

      def dupe(id)
        err_msg = "One or more added object references already exist for the following modified properties: 'members'."
        { id: id, status: 400, body: { error: { code: "Request_BadRequest", message: err_msg } } }
      end

      before do
        stub_request(batch_method, batch_url).with(body: batch_body)
                                             .to_return(json_response(batch_overall_response_code, responses: batch_responses))
      end

      context 'when all are successfully added' do
        let(:batch_responses) do
          [succ('members_m1'), succ('members_m2'), succ('owners_o1'), succ('owners_o2')]
        end

        it { is_expected.to eq(nil) }

        it 'passes along the quota used to run_batch' do
          expect(endpoints.http).to \
            receive(:run_batch).with(anything, anything, hash_including(quota: [4, 4]))
                               .and_call_original
          subject
        end

        it 'increments the "expected" counter for the first request' do
          subject
          expect(InstStatsd::Statsd).to have_received(:increment)
            .with('microsoft_sync.graph_service.expected',
                  tags: hash_including(msft_endpoint: 'patch_groups'))
        end
      end

      context 'when some owners were already in the group' do
        let(:batch_responses) do
          [succ('members_m1'), succ('members_m2'), succ('owners_o1'), dupe('owners_o2')]
        end

        it 'returns a hash with an array with those users' do
          expect(subject.transform_values(&:sort)).to eq(owners: %w[o2])
        end
      end

      context 'when some members were already in the group' do
        let(:batch_responses) do
          [dupe('members_m1'), dupe('members_m2'), succ('owners_o1'), succ('owners_o2')]
        end

        it 'returns a hash with an array with those users' do
          expect(subject.transform_values(&:sort)).to eq(members: %w[m1 m2])
        end
      end

      context 'when some members and owners were already in the group' do
        let(:batch_responses) do
          [dupe('members_m1'), succ('members_m2'), dupe('owners_o1'), dupe('owners_o2')]
        end

        it 'returns a hash with arrays with those users' do
          expect(subject.transform_values(&:sort)).to eq(members: %w[m1], owners: %w[o1 o2])
        end
      end

      %w[members owners].each do |members_or_owners|
        context "when the API returns a '#{members_or_owners} quota exceeded' error" do
          let(:batch_responses) do
            [
              dupe('members_m1'),
              succ('members_m2'),
              succ('owners_m1'),
              { id: 'owners_m2', status: 403, body: msft_api_error_body }
            ]
          end

          let(:msft_api_error_body) do
            {
              code: "Directory_QuotaExceeded",
              message: "Unable to perform operation as '121' would exceed the maximum quota count '100' for forward-link '#{members_or_owners}'.",
            }
          end

          it "raises an Errors::#{members_or_owners.capitalize}QuotaExceeded error" do
            expect { subject }.to raise_error(
              "MicrosoftSync::Errors::#{members_or_owners.capitalize}QuotaExceeded".constantize
            )
          end
        end
      end

      it_behaves_like 'a members/owners batch request that can fail' do
        let(:endpoint_name) { 'group_add_users' }
        let(:ignored_members_m1_response) { dupe('members_m1') }
      end
    end
  end

  describe '#list_members' do
    let(:method_name) { :list_members }
    let(:method_args) { ['mygroup'] }
    let(:url) { 'https://graph.microsoft.com/v1.0/groups/mygroup/members' }

    it_behaves_like 'a paginated list endpoint' do
      it_behaves_like 'an endpoint that uses up quota', [3, 0]
    end
  end

  describe '#list_owners' do
    let(:method_name) { :list_owners }
    let(:method_args) { ['mygroup'] }
    let(:url) { 'https://graph.microsoft.com/v1.0/groups/mygroup/owners' }
    let(:url_variables) { ['mygroup'] }

    it_behaves_like 'a paginated list endpoint' do
      it_behaves_like 'an endpoint that uses up quota', [2, 0]
    end
  end

  describe '#remove_users_ignore_missing' do
    subject do
      endpoints.remove_users_ignore_missing('msgroupid', members: %w[m1 m2], owners: %w[o1 o2])
    end

    let(:url) { 'https://graph.microsoft.com/v1.0/$batch' }
    let(:http_method) { :post }
    let(:with_params) do
      {
        body: {
          requests: [
            { id: "members_m1", url: "/groups/msgroupid/members/m1/$ref", method: "DELETE" },
            { id: "members_m2", url: "/groups/msgroupid/members/m2/$ref", method: "DELETE" },
            { id: "owners_o1", url: "/groups/msgroupid/owners/o1/$ref", method: "DELETE" },
            { id: "owners_o2", url: "/groups/msgroupid/owners/o2/$ref", method: "DELETE" }
          ]
        }
      }
    end
    let(:response_body) { { responses: batch_responses } }
    let(:batch_responses) { [] }
    let(:status) { batch_overall_response_code }
    let(:batch_overall_response_code) { 200 }

    def missing(id)
      err_msg = "Resource '12345689-1212-1212-1212-abc212121212' does not exist or one of " \
                "its queried reference-property objects are not present."
      { id: id, status: 404, body: { error: { code: "Request_ResourceNotFound", msg: err_msg } } }
    end

    # This style seems to happen if we remove with the API after (right after?) removing from the UI
    def missing2(id)
      msg = "One or more removed object references do not exist for the following " \
            "modified properties: 'members'."
      { id: id, status: 400, body: { error: { code: "Request_BadRequest", message: msg } } }
    end

    def last_owner_removed(id)
      msg = "The group must have at least one owner, hence this owner cannot be removed."
      { id: id, status: 400, body: { error: { code: "Request_BadRequest", message: msg } } }
    end

    context 'when all are successfully removed' do
      let(:batch_responses) do
        [succ('members_m1'), succ('members_m2'), succ('owners_o1'), succ('owners_o2')]
      end

      it { is_expected.to eq(nil) }

      it 'passes along the quota used to run_batch' do
        expect(endpoints.http).to \
          receive(:run_batch).with(anything, anything, hash_including(quota: [4, 4]))
                             .and_call_original
        subject
      end
    end

    context 'when some owners were not in the group' do
      let(:batch_responses) do
        [succ('members_m1'), succ('members_m2'), succ('owners_o1'), missing('owners_o2')]
      end

      it 'returns a hash with an array with those users' do
        expect(subject.transform_values(&:sort)).to eq(owners: %w[o2])
      end
    end

    context 'when some members were not in the group' do
      let(:batch_responses) do
        [missing('members_m1'), missing('members_m2'), succ('owners_o1'), succ('owners_o2')]
      end

      it 'returns a hash with an array with those users' do
        expect(subject.transform_values(&:sort)).to eq(members: %w[m1 m2])
      end
    end

    context 'when some members were not in the group (alternate response format)' do
      let(:batch_responses) do
        [missing2('members_m1'), missing2('members_m2'), succ('owners_o1'), succ('owners_o2')]
      end

      it 'returns a hash with an array with those users' do
        expect(subject.transform_values(&:sort)).to eq(members: %w[m1 m2])
      end
    end

    context 'when some members and owners were not in the group' do
      let(:batch_responses) do
        [missing('members_m1'), succ('members_m2'), missing('owners_o1'), missing('owners_o2')]
      end

      it 'returns a hash with arrays with those users' do
        expect(subject.transform_values(&:sort)).to eq(members: %w[m1], owners: %w[o1 o2])
      end
    end

    context 'when the last owner in a group is removed' do
      let(:batch_responses) do
        [succ('members_m1'), succ('members_m2'), last_owner_removed('owners_o1'), succ('owners_o2')]
      end

      it 'raises an MissingOwners' do
        expect { subject }.to raise_microsoft_sync_graceful_cancel_error(
          MicrosoftSync::Errors::MissingOwners, /must have owners/
        )
      end
    end

    context 'when more than 20 users are given' do
      it 'raises an ArgumentError' do
        expect {
          endpoints.remove_users_ignore_missing(
            'msgroupid', members: ['x'] * 10, owners: ['y'] * 11
          )
        }.to raise_error(ArgumentError, "Only 20 users can be batched at once. Got 21.")
      end
    end

    it_behaves_like 'a members/owners batch request that can fail' do
      let(:endpoint_name) { 'group_remove_users' }
      let(:ignored_members_m1_response) { missing('members_m1') }
    end
  end
end
