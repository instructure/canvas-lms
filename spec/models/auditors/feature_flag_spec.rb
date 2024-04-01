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
#

describe Auditors::FeatureFlag do
  let(:request_id) { 42 }
  let(:feature_name) { "root_account_feature" }

  before do
    allow(Feature).to receive(:definitions).and_return({
                                                         feature_name => Feature.new(feature: feature_name, applies_to: "RootAccount")
                                                       })
    @flag = Account.site_admin.feature_flags.build
    @flag.feature = feature_name
    @flag.state = "on"
    @user = user_with_pseudonym(active_all: true)
    @flag.current_user = @user
    @flag.save!
    Auditors::ActiveRecord::FeatureFlagRecord.delete_all
    shard_class = Class.new do
      define_method(:activate) { |&b| b.call }
    end
    EventStream.current_shard_lookup = lambda do
      shard_class.new
    end
    allow(RequestContextGenerator).to receive_messages(request_id:)
    @event = Auditors::FeatureFlag.record(@flag, @user, "off")
  end

  it "can be read from postgres" do
    pg_record = Auditors::ActiveRecord::FeatureFlagRecord.where(uuid: @event.id).first
    expect(Auditors::FeatureFlag.for_feature_flag(@flag).paginate(per_page: 10)).to include(pg_record)
  end

  it "does not swallow auditor write errors" do
    test_err_class = Class.new(StandardError)
    allow(Auditors::ActiveRecord::FeatureFlagRecord).to receive(:create_from_event_stream!).and_raise(test_err_class.new("DB Error"))
    expect { Auditors::FeatureFlag.record(@flag, @user, "on") }.to raise_error(test_err_class)
  end

  context "root account" do
    it "sets root_account_id attribute to the global id of the account" do
      expect(@event.root_account_id).to eq(Account.site_admin.global_id)
    end
  end
end
