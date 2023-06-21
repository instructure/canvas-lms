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

describe Auditors::ActiveRecord::AuthenticationRecord do
  let(:request_id) { "abcde-12345" }

  before do
    allow(RequestContextGenerator).to receive_messages(request_id:)
  end

  it "appropriately connected to a table" do
    Auditors::ActiveRecord::AuthenticationRecord.delete_all
    expect(Auditors::ActiveRecord::AuthenticationRecord.count).to eq(0)
  end

  describe "mapping from event stream record" do
    let(:user_record) { user_with_pseudonym }
    let(:pseudonym_record) { user_record.pseudonym }
    let(:es_record) { Auditors::Authentication::Record.generate(pseudonym_record, "login") }

    it "is creatable from an event_stream record of the correct type" do
      ar_rec = Auditors::ActiveRecord::AuthenticationRecord.create_from_event_stream!(es_record)
      expect(ar_rec.id).to_not be_nil
      expect(ar_rec.uuid).to eq(es_record.id)
      expect(ar_rec.request_id).to eq(request_id)
      expect(ar_rec.pseudonym_id).to eq(pseudonym_record.id)
      expect(ar_rec.account_id).to eq(pseudonym_record.account_id)
      expect(ar_rec.user_id).to eq(user_record.id)
    end

    it "is updatable from ES record" do
      ar_rec = Auditors::ActiveRecord::AuthenticationRecord.create_from_event_stream!(es_record)
      es_record.request_id = "aaa-111-bbb-222"
      Auditors::ActiveRecord::AuthenticationRecord.update_from_event_stream!(es_record)
      expect(ar_rec.reload.request_id).to eq("aaa-111-bbb-222")
    end

    it "fails predictably on attempted update to missing value" do
      unpersisted_rec = es_record
      expect do
        Auditors::ActiveRecord::AuthenticationRecord.update_from_event_stream!(unpersisted_rec)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
