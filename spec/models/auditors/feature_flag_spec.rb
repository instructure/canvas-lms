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

require_relative "../../cassandra_spec_helper"

describe Auditors::FeatureFlag do
  let(:request_id) { 42 }
  let(:feature_name) { "root_account_feature" }

  before do
    allow(Feature).to receive(:definitions).and_return({
                                                         feature_name => Feature.new(feature: feature_name, applies_to: "RootAccount")
                                                       })
    allow(Audits).to receive(:config).and_return({ "write_paths" => ["active_record"], "read_path" => "active_record" })
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
    allow(RequestContextGenerator).to receive_messages(request_id: request_id)
  end

  describe "with cassandra backend" do
    include_examples "cassandra audit logs"

    before do
      allow(Audits).to receive(:config).and_return({ "write_paths" => ["cassandra"], "read_path" => "cassandra" })
      @event = Auditors::FeatureFlag.record(@flag, @user, "off")
    end

    context "nominal cases" do
      it "returns the event on generation" do
        expect(@event.class).to eq(Auditors::FeatureFlag::Record)
      end

      it "includes event for feature_flag index" do
        expect(Auditors::FeatureFlag.for_feature_flag(@flag).paginate(per_page: 10))
          .to include(@event)
      end

      it "sets request_id" do
        expect(@event.request_id).to eq request_id.to_s
      end

      it "doesn't record an error when not configured" do
        allow(Auditors::FeatureFlag::Stream).to receive(:database).and_return(nil)
        expect(CanvasCassandra::DatabaseBuilder).to receive(:configured?).with("auditors").once.and_return(false)
        expect(EventStream::Logger).not_to receive(:error)
        Auditors::FeatureFlag.record(@flag, @user, "off")
      end
    end
  end

  describe "with dual writing enabled" do
    before do
      allow(Audits).to receive(:config).and_return({ "write_paths" => ["cassandra", "active_record"], "read_path" => "cassandra" })
      @event = Auditors::FeatureFlag.record(@flag, @user, "off")
    end

    it "writes to cassandra" do
      expect(Audits.write_to_cassandra?).to eq(true)
      expect(Auditors::FeatureFlag.for_feature_flag(@flag).paginate(per_page: 10))
        .to include(@event)
    end

    it "writes to postgres" do
      expect(Audits.write_to_postgres?).to eq(true)
      pg_record = Auditors::ActiveRecord::FeatureFlagRecord.where(uuid: @event.id).first
      expect(pg_record.feature_flag_id).to eq(@flag.id)
    end
  end

  describe "with postgres backend" do
    before do
      allow(Audits).to receive(:config).and_return({ "write_paths" => ["active_record"], "read_path" => "active_record" })
      @event = Auditors::FeatureFlag.record(@flag, @user, "off")
    end

    it "can be read from postgres" do
      expect(Audits.read_from_postgres?).to eq(true)
      pg_record = Auditors::ActiveRecord::FeatureFlagRecord.where(uuid: @event.id).first
      expect(Auditors::FeatureFlag.for_feature_flag(@flag).paginate(per_page: 10)).to include(pg_record)
    end

    it "does not swallow auditor write errors" do
      test_err_class = Class.new(StandardError)
      allow(Auditors::ActiveRecord::FeatureFlagRecord).to receive(:create_from_event_stream!).and_raise(test_err_class.new("DB Error"))
      expect { Auditors::FeatureFlag.record(@flag, @user, "on") }.to raise_error(test_err_class)
    end
  end
end
