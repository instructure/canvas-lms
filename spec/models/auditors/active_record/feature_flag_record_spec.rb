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

describe Auditors::ActiveRecord::FeatureFlagRecord do
  let(:request_id) { "abcde-12345" }
  let(:feature_name) { "root_account_feature" }

  before do
    allow(RequestContextGenerator).to receive_messages(request_id:)
    allow(Feature).to receive(:definitions).and_return({
                                                         feature_name => Feature.new(feature: feature_name, applies_to: "RootAccount")
                                                       })
  end

  it "appropriately connected to a table" do
    Auditors::ActiveRecord::FeatureFlagRecord.delete_all
    expect(Auditors::ActiveRecord::FeatureFlagRecord.count).to eq(0)
  end

  describe "mapping from event stream record" do
    let(:flag_record) do
      flag = Account.site_admin.feature_flags.build
      flag.feature = feature_name
      flag.state = "on"
      flag.id = -1
      flag
    end
    let(:user) { user_model }
    let(:es_record) { Auditors::FeatureFlag::Record.generate(flag_record, user, "nonexistent") }

    it "is creatable from an event_stream record of the correct type" do
      ar_rec = Auditors::ActiveRecord::FeatureFlagRecord.create_from_event_stream!(es_record)
      expect(ar_rec.id).to_not be_nil
      expect(ar_rec.uuid).to eq(es_record.id)
      expect(ar_rec.request_id).to eq(request_id)
      expect(ar_rec.user_id).to eq(user.id)
      expect(ar_rec.context_id).to eq(es_record.context_id)
      expect(ar_rec.context_type).to eq(es_record.context_type)
      expect(ar_rec.feature_name).to eq(es_record.feature_name)
    end

    it "is updatable from ES record" do
      ar_rec = Auditors::ActiveRecord::FeatureFlagRecord.create_from_event_stream!(es_record)
      es_record.request_id = "aaa-111-bbb-222"
      Auditors::ActiveRecord::FeatureFlagRecord.update_from_event_stream!(es_record)
      expect(ar_rec.reload.request_id).to eq("aaa-111-bbb-222")
    end

    it "fails predictably on attempted update to missing value" do
      unpersisted_rec = es_record
      expect do
        Auditors::ActiveRecord::FeatureFlagRecord.update_from_event_stream!(unpersisted_rec)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
