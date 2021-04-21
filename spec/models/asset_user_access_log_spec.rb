# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require 'spec_helper.rb'

describe AssetUserAccessLog do
  describe "write path" do
    before(:once) do
      @course = Account.default.courses.create!(name: 'My Course')
      @assignment = @course.assignments.create!(title: 'My Assignment')
      @user = User.create!
      @asset = factory_with_protected_attributes(AssetUserAccess, user: @user, context: @course, asset_code: @assignment.asset_string)
      @asset.display_name = @assignment.asset_string
      @asset.save!
    end

    it "inserts to correct tables" do
      dt = DateTime.civil(2020, 9, 4, 12, 0, 0) # a friday, index 5
      AssetUserAccessLog::AuaLog5.delete_all
      AssetUserAccessLog.put_view(@asset, timestamp: dt)
      expect(AssetUserAccessLog::AuaLog5.count).to eq(1)
    end
  end

  describe ".compact" do
    before(:once) do
      Setting.set("aua_log_batch_size", "100")
      Setting.set("aua_log_truncation_enabled", "true")
      ps = PluginSetting.find_or_initialize_by(name: "asset_user_access_logs", inheritance_scope: "shard")
      ps.settings = { max_log_ids: [0,0,0,0,0,0,0], write_path: 'log' }
      ps.save!
      @course = Account.default.courses.create!(name: 'My Course')
      @assignment = @course.assignments.create!(title: 'My Assignment')
      @user_1 = User.create!
      @user_2 = User.create!
      @user_3 = User.create!
      @user_4 = User.create!
      @user_5 = User.create!
      @asset_1 = factory_with_protected_attributes(AssetUserAccess, user: @user_1, context: @course, asset_code: @assignment.asset_string)
      @asset_2 = factory_with_protected_attributes(AssetUserAccess, user: @user_2, context: @course, asset_code: @assignment.asset_string)
      @asset_3 = factory_with_protected_attributes(AssetUserAccess, user: @user_3, context: @course, asset_code: @assignment.asset_string)
      @asset_4 = factory_with_protected_attributes(AssetUserAccess, user: @user_4, context: @course, asset_code: @assignment.asset_string)
      @asset_5 = factory_with_protected_attributes(AssetUserAccess, user: @user_5, context: @course, asset_code: @assignment.asset_string)
    end

    def generate_log(assets, count)
      count.times do
        assets.each do |asset|
          AssetUserAccessLog.put_view(asset)
        end
      end
    end

    def advance_sequence(model, by_count)
      sequence_name = model.quoted_table_name.gsub(/"$/, "_id_seq\"")
      model.connection.execute("ALTER SEQUENCE #{sequence_name} RESTART WITH #{(model.maximum(:id) || 0) + by_count}")
    end

    it "aborts job immediately if plugin setting is nil" do
      PluginSetting.where(name: "asset_user_access_logs").delete_all
      expect(AssetUserAccess).to_not receive(:compact_partition)
      AssetUserAccessLog.compact
      expect(@asset_1.reload.view_score).to be_nil
    end

    it "aborts for bad write path config" do
      ps = PluginSetting.where(name: "asset_user_access_logs").first
      ps.settings[:write_path] = "update"
      ps.save!
      expect(AssetUserAccess).to_not receive(:compact_partition)
      AssetUserAccessLog.compact
      expect(@asset_1.reload.view_score).to be_nil
    end

    it "doesn't fail when there is no data" do
      expect{ AssetUserAccessLog.compact }.to_not raise_error
    end

    describe "with data" do

      it "computes correct results for multiple assets with multiple log entries spanning more than one batch" do
        expect(@asset_1.view_score).to be_nil
        expect(@asset_5.view_score).to be_nil
        Timecop.freeze do
          generate_log([@asset_1, @asset_2, @asset_3], 100)
          generate_log([@asset_1, @asset_3, @asset_4], 100)
          generate_log([@asset_1, @asset_4, @asset_5], 100)
          generate_log([@asset_1, @asset_4], 100)
          AssetUserAccessLog.compact
          expect(@asset_1.reload.view_score).to eq(400.0)
          expect(@asset_2.reload.view_score).to eq(100.0)
          expect(@asset_3.reload.view_score).to eq(200.0)
          expect(@asset_4.reload.view_score).to eq(300.0)
          expect(@asset_5.reload.view_score).to eq(100.0)
          # DOES NOT TRUNCATE TODAY!
          expect(AssetUserAccessLog.log_model(Time.now.utc).count).to eq(1100)
        end
      end

      it "writes iterator state properly" do
        expect(@asset_1.view_score).to be_nil
        Timecop.freeze do
          generate_log([@asset_1, @asset_2, @asset_3], 100)
          AssetUserAccessLog.compact
          partition_model = AssetUserAccessLog.log_model(Time.zone.now)
          compaction_state = AssetUserAccessLog.metadatum_payload
          expect(compaction_state[:max_log_ids].max).to eq(partition_model.maximum(:id))
        end
      end

      it "truncates yesterday after compacting changes" do
        Timecop.freeze do
          Timecop.travel(24.hours.ago) do
            generate_log([@asset_1, @asset_2, @asset_3], 50)
            generate_log([@asset_1, @asset_3, @asset_4], 50)
          end
          generate_log([@asset_1, @asset_4, @asset_5], 100)
          generate_log([@asset_1, @asset_4], 100)
          AssetUserAccessLog.compact
          expect(@asset_1.reload.view_score).to eq(300.0)
          expect(@asset_2.reload.view_score).to eq(50.0)
          expect(@asset_3.reload.view_score).to eq(100.0)
          expect(@asset_4.reload.view_score).to eq(250.0)
          expect(@asset_5.reload.view_score).to eq(100.0)
          expect(AssetUserAccessLog.log_model(Time.now.utc).count).to eq(500)
          expect(AssetUserAccessLog.log_model(24.hours.ago).count).to eq(0)
          # we should only have one setting with an offset in it, the other should have been zeroed
          # out during the truncation
          expect(AssetUserAccessLog.metadatum_payload[:max_log_ids].select{|id| id > 0}.size).to eq(1)
        end
      end

      it "chomps small batches correctly" do
        Timecop.freeze do
          generate_log([@asset_1, @asset_2, @asset_3], 2)
          AssetUserAccessLog.compact
          generate_log([@asset_1, @asset_3, @asset_4], 4)
          AssetUserAccessLog.compact
          generate_log([@asset_1, @asset_4, @asset_5], 8)
          AssetUserAccessLog.compact
          generate_log([@asset_1, @asset_4], 16)
          AssetUserAccessLog.compact
          expect(@asset_1.reload.view_score).to eq(30.0)
          expect(@asset_2.reload.view_score).to eq(2.0)
          expect(@asset_3.reload.view_score).to eq(6.0)
          expect(@asset_4.reload.view_score).to eq(28.0)
          expect(@asset_5.reload.view_score).to eq(8.0)
        end
      end

      it "can skip over gaps in the sequence" do
        Timecop.freeze do
          Setting.set('aua_log_seq_jumps_allowed', 'true')
          model = AssetUserAccessLog.log_model(Time.now.utc)
          generate_log([@asset_1, @asset_2, @asset_3], 2)
          AssetUserAccessLog.compact
          advance_sequence(model, 200)
          generate_log([@asset_1, @asset_3, @asset_4], 4)
          AssetUserAccessLog.compact
          advance_sequence(model, 200)
          generate_log([@asset_1, @asset_4, @asset_5], 8)
          AssetUserAccessLog.compact
          advance_sequence(model, 200)
          generate_log([@asset_1, @asset_4], 16)
          AssetUserAccessLog.compact
          expect(@asset_1.reload.view_score).to eq(30.0)
          expect(@asset_2.reload.view_score).to eq(2.0)
          expect(@asset_3.reload.view_score).to eq(6.0)
          expect(@asset_4.reload.view_score).to eq(28.0)
          expect(@asset_5.reload.view_score).to eq(8.0)
        end
      end

      it "does not override updates from requests unless it's bigger" do
        Timecop.freeze do
          generate_log([@asset_1, @asset_2, @asset_3], 2)
          update_ts = Time.now.utc + 2.minutes
          @asset_1.last_access = update_ts
          @asset_1.updated_at = update_ts
          @asset_1.save!
          AssetUserAccessLog.compact
          expect(@asset_1.reload.view_score).to eq(2.0)
          expect(@asset_1.reload.last_access).to eq(update_ts)
          Timecop.travel(10.minutes.from_now) do
            generate_log([@asset_1, @asset_2, @asset_3], 9)
            AssetUserAccessLog.compact
            expect(@asset_1.reload.view_score).to eq(11.0)
            expect(@asset_1.reload.last_access > update_ts).to be_truthy
          end
        end
      end
    end
  end

  describe ".reschedule!" do
    it "puts the new job on the right strand" do
      AssetUserAccessLog.reschedule!
      expect(Delayed::Job.where(strand: AssetUserAccessLog.strand_name).count).to eq(1)
    end
  end
end