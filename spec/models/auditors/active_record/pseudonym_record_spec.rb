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

describe Auditors::ActiveRecord::PseudonymRecord do
  describe ".ar_attributes_from_event_stream" do
    subject { described_class.ar_attributes_from_event_stream(record) }

    let(:pseudonym_id) { 1234 }
    let(:root_account_id) { 2345 }
    let(:performing_user_id) { 3456 }
    let(:action) { "thingy_done" }
    let(:hostname) { "computer" }
    let(:pid) { 4567 }
    let(:record) do
      Auditors::Pseudonym::Record.new(
        "pseudonym_id" => pseudonym_id,
        "root_account_id" => root_account_id,
        "performing_user_id" => performing_user_id,
        "action" => action,
        "hostname" => hostname,
        "pid" => pid
      )
    end

    it "uses the auditor record id as the active record uuid attribute" do
      expect(subject["uuid"]).to eq(record.id)
    end

    it "uses a local id as the pseudonym_id" do
      expect(subject["pseudonym_id"]).to eq(pseudonym_id)
    end

    it "uses a local id as the root_account_id" do
      expect(subject["root_account_id"]).to eq(root_account_id)
    end

    it "uses a local id as the performing_user_id" do
      expect(subject["performing_user_id"]).to eq(performing_user_id)
    end

    context "when the performing user is on a different shard" do
      let(:different_shard_user_id) { 99_990_000_000_009_999 }
      let(:performing_user_id) { different_shard_user_id }

      it "uses a global id as the performing_user_id" do
        expect(subject["performing_user_id"]).to eq(different_shard_user_id)
      end
    end

    context "inside of a request" do
      let(:request_id) { "abc123" }

      before do
        allow(RequestContext::Generator).to receive(:request_id).and_return(request_id)
      end

      it "includes the request id" do
        expect(subject["request_id"]).to eq(request_id)
      end
    end

    context "outside of a request" do
      before do
        allow(RequestContext::Generator).to receive(:request_id)
      end

      it "uses MISSING in place of the request id" do
        expect(subject["request_id"]).to eq("MISSING")
      end
    end
  end
end
