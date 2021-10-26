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

describe AssetUserAccessLog do
  around(:each) do |example|
    old_compaction_recv_timeout = Setting.get("aua_compaction_receive_timeout_ms", "1000")
    # let's not waste time with queue throttling in tests
    MessageBus.worker_process_interval = -> { 0.01 }
    MessageBus.max_mem_queue_size = -> { 1000 }
    Setting.set("aua_compaction_receive_timeout_ms", "50")
    example.run
  ensure
    Canvas::MessageBusConfig.apply # resets config changes made to interval and queue size
    Setting.set("aua_compaction_receive_timeout_ms", old_compaction_recv_timeout)
  end

  def reset_message_bus_topic(topic_root_account, subscription_name)
    MessageBus.reset!
    pre_consumer = MessageBus.consumer_for(
      AssetUserAccessLog::PULSAR_NAMESPACE,
      AssetUserAccessLog.message_bus_topic_name(topic_root_account),
      subscription_name, force_fresh: true
    )
    begin
      while (message = pre_consumer.receive(200))
        pre_consumer.acknowledge(message)
      end
    rescue Pulsar::Error::Timeout
      # subscription is caught up
      MessageBus.reset!
    end
  end

  describe "write path" do
    before(:once) do
      @course = Account.default.courses.create!(name: 'My Course')
      @assignment = @course.assignments.create!(title: 'My Assignment')
      @user = User.create!
      @asset = factory_with_protected_attributes(AssetUserAccess, user: @user, context: @course, asset_code: @assignment.asset_string)
      @asset.display_name = @assignment.asset_string
      @asset.save!
    end

    describe "via postgres" do
      it "inserts to correct tables" do
        dt = DateTime.civil(2020, 9, 4, 12, 0, 0) # a friday, index 5
        AssetUserAccessLog::AuaLog5.delete_all
        AssetUserAccessLog.put_view(@asset, timestamp: dt)
        expect(AssetUserAccessLog::AuaLog5.count).to eq(1)
      end
    end

    describe "via message bus" do
      before(:each) do
        skip("pulsar config required to test") unless MessageBus.enabled?
        MessageBus.reset!
        @channel_config = {
          "pulsar_writes_enabled" => true,
          "pulsar_reads_enabled" => false
        }
        allow(AssetUserAccessLog).to receive(:channel_config).and_return(@channel_config)
      end

      after(:each) do
        MessageBus.process_all_and_reset!
      end

      it "sends any log writes to the database AND to the message bus" do
        dt = DateTime.civil(2021, 4, 29, 12, 0, 0) # a thursday, index 4
        AssetUserAccessLog::AuaLog4.delete_all
        subscription_name = "test"
        # clear mb topic
        reset_message_bus_topic(Account.default, subscription_name)
        AssetUserAccessLog.put_view(@asset, timestamp: dt)
        expect(AssetUserAccessLog::AuaLog4.count).to eq(1)
        record = AssetUserAccessLog::AuaLog4.last
        MessageBus.process_all_and_reset!
        consumer = MessageBus.consumer_for(
          AssetUserAccessLog::PULSAR_NAMESPACE,
          AssetUserAccessLog.message_bus_topic_name(Account.default),
          subscription_name
        )
        message = consumer.receive(1000)
        data = JSON.parse(message.data)
        expect(data["asset_user_access_id"]).to eq(record.asset_user_access_id)
        expect(data["log_entry_id"]).to eq(record.id)
        expect(data["partition_index"]).to eq(4)
      end

      it "can be configured to ONLY write to the message bus" do
        @channel_config["db_writes_enabled"] = false
        dt = DateTime.civil(2021, 6, 21, 12, 0, 0) # a monday, index 1
        AssetUserAccessLog::AuaLog1.delete_all
        subscription_name = "test"
        # clear mb topic
        reset_message_bus_topic(Account.default, subscription_name)
        AssetUserAccessLog.put_view(@asset, timestamp: dt)
        expect(AssetUserAccessLog::AuaLog1.count).to eq(0)
        MessageBus.process_all_and_reset!
        consumer = MessageBus.consumer_for(
          AssetUserAccessLog::PULSAR_NAMESPACE,
          AssetUserAccessLog.message_bus_topic_name(Account.default),
          subscription_name
        )
        message = consumer.receive(1000)
        data = JSON.parse(message.data)
        expect(data["asset_user_access_id"]).to eq(@asset.id)
        expect(data["log_entry_id"]).to be_nil
        expect(data["partition_index"]).to eq(1)
      end
    end

    describe "under emergency load shedding" do
      before(:each) do
        @channel_config = {
          "pulsar_writes_enabled" => false,
          "pulsar_reads_enabled" => false,
          "db_writes_enabled" => false
        }
        allow(AssetUserAccessLog).to receive(:channel_config).and_return(@channel_config)
      end

      it "writes nowhere on increment" do
        dt = DateTime.civil(2021, 6, 21, 12, 0, 0) # a monday, index 1
        AssetUserAccessLog::AuaLog1.delete_all
        expect(MessageBus).to_not receive(:producer_for)
        AssetUserAccessLog.put_view(@asset, timestamp: dt)
        expect(AssetUserAccessLog::AuaLog1.count).to eq(0)
      end
    end
  end

  describe ".compact" do
    before(:once) do
      Setting.set("aua_log_batch_size", "100")
      Setting.set("aua_log_truncation_enabled", "true")
      ps = PluginSetting.find_or_initialize_by(name: "asset_user_access_logs", inheritance_scope: "shard")
      ps.settings = { max_log_ids: [0, 0, 0, 0, 0, 0, 0], write_path: 'log' }
      ps.save!
      @account = Account.default
      @course = @account.courses.create!(name: 'My Course')
      @assignment = @course.assignments.create!(title: 'My Assignment')
      @user_1 = User.create!
      @user_2 = User.create!
      @user_3 = User.create!
      @user_4 = User.create!
      @user_5 = User.create!
      @asset_1 = factory_with_protected_attributes(AssetUserAccess, user: @user_1, context: @course, asset_code: @assignment.asset_string, root_account_id: @account.id)
      @asset_2 = factory_with_protected_attributes(AssetUserAccess, user: @user_2, context: @course, asset_code: @assignment.asset_string, root_account_id: @account.id)
      @asset_3 = factory_with_protected_attributes(AssetUserAccess, user: @user_3, context: @course, asset_code: @assignment.asset_string, root_account_id: @account.id)
      @asset_4 = factory_with_protected_attributes(AssetUserAccess, user: @user_4, context: @course, asset_code: @assignment.asset_string, root_account_id: @account.id)
      @asset_5 = factory_with_protected_attributes(AssetUserAccess, user: @user_5, context: @course, asset_code: @assignment.asset_string, root_account_id: @account.id)
    end

    def generate_log(assets, count)
      count.times do
        assets.each do |asset|
          AssetUserAccessLog.put_view(asset)
        end
        # pull back if we start to grow the queue
        if MessageBus.production_worker.queue_depth > 150
          await_message_bus_queue!(target_depth: 75)
        end
      end
      # finish applying all writes
      await_message_bus_queue!(target_depth: 0)
    end

    def await_message_bus_queue!(target_depth: 0)
      # rubocop:disable Lint/NoSleep this is the best way I know of to give up thread priority
      while MessageBus.production_worker.queue_depth > target_depth
        # we need autoloading to not deadlock if the background thread is awaiting
        # autoloading. https://guides.rubyonrails.org/threading_and_code_execution.html#permit-concurrent-loads
        ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
          sleep 0.01 # give background thread a chance to make progress
        end
      end
      # rubocop:enable Lint/NoSleep
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
      expect { AssetUserAccessLog.compact }.to_not raise_error
    end

    describe "with data via postgres" do
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
          expect(AssetUserAccessLog.metadatum_payload[:max_log_ids].count { |id| id > 0 }).to eq(1)
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

    describe "via message bus" do
      before(:each) do
        skip("pulsar config required to test") unless MessageBus.enabled?
        allow(AssetUserAccessLog).to receive(:channel_config).and_return({
                                                                           "pulsar_writes_enabled" => true,
                                                                           "pulsar_reads_enabled" => true,
                                                                           "db_writes_enabled" => true
                                                                         })

        @account = Account.default

        # clear mb topic
        reset_message_bus_topic(@account, AssetUserAccessLog::PULSAR_SUBSCRIPTION)
      end

      after(:each) do
        MessageBus.process_all_and_reset!
      end

      it "does not choke on pre-existing un-postgres-partitioned iterator state" do
        default_metadata = AssetUserAccessLog.metadatum_payload
        default_metadata.delete(:temp_root_account_max_log_ids)
        AssetUserAccessLog.update_metadatum(default_metadata)
        expect { AssetUserAccessLog.compact }.to_not raise_error
      end

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
        end
      end

      it "writes iterator state properly" do
        expect(@asset_1.view_score).to be_nil
        partition_id = "-1" # safe assumption in dev/test
        # because data won't be big enough to partition a topic.
        prior_state = AssetUserAccessLog.metadatum_payload
        checkpoint_iterator_state = nil
        final_iterator_state = nil
        expect(prior_state[:pulsar_partition_iterators][@account.id.to_s]).to be_nil
        Timecop.freeze do
          generate_log([@asset_1, @asset_2, @asset_3], 100)
          AssetUserAccessLog.compact
          checkpoint_state = AssetUserAccessLog.metadatum_payload
          checkpoint_iterator_state = checkpoint_state[:pulsar_partition_iterators][@account.id.to_s][partition_id]
          expect(checkpoint_iterator_state).to_not be_nil
        end
        Timecop.freeze do
          generate_log([@asset_1, @asset_2, @asset_3], 100)
          AssetUserAccessLog.compact
          final_state = AssetUserAccessLog.metadatum_payload
          final_iterator_state = final_state[:pulsar_partition_iterators][@account.id.to_s][partition_id]
          expect(final_iterator_state).to_not be_nil
        end
        checkpoint_id = MessageBus::MessageId.from_string(checkpoint_iterator_state)
        final_id = MessageBus::MessageId.from_string(final_iterator_state)
        expect(final_id).to be > checkpoint_id
        expect(@asset_1.reload.view_score).to eq(200.0)
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

    describe "multiple root accounts with ripcord" do
      before(:each) do
        skip("pulsar config required to test") unless MessageBus.enabled?
        allow(AssetUserAccessLog).to receive(:channel_config).and_return({
                                                                           "pulsar_writes_enabled" => true,
                                                                           "pulsar_reads_enabled" => false,
                                                                           "db_writes_enabled" => true
                                                                         })

        @account1 = Account.default
        @account2 = account_model(root_account_id: nil)

        @course2 = @account2.courses.create!(name: 'My Course')
        @assignment2 = @course2.assignments.create!(title: 'My Other Assignment')
        @user_6 = User.create!
        @user_7 = User.create!
        @user_8 = User.create!
        @asset_6 = factory_with_protected_attributes(AssetUserAccess, user: @user_6, context: @course2, asset_code: @assignment2.asset_string, root_account_id: @account2.id)
        @asset_7 = factory_with_protected_attributes(AssetUserAccess, user: @user_7, context: @course2, asset_code: @assignment2.asset_string, root_account_id: @account2.id)
        @asset_8 = factory_with_protected_attributes(AssetUserAccess, user: @user_8, context: @course2, asset_code: @assignment2.asset_string, root_account_id: @account2.id)

        # clear mb topics just in case
        reset_message_bus_topic(@account1, AssetUserAccessLog::PULSAR_SUBSCRIPTION)
        reset_message_bus_topic(@account2, AssetUserAccessLog::PULSAR_SUBSCRIPTION)
      end

      it "tolerates swapping out backend between compaction runs and does not double count anything" do
        # do postgres for a bit
        Timecop.freeze do
          generate_log([@asset_1, @asset_6, @asset_8], 20)
          AssetUserAccessLog.compact
          generate_log([@asset_1, @asset_2, @asset_5], 40)
          AssetUserAccessLog.compact
        end
        expect(@asset_1.reload.view_score).to eq(60.0)
        expect(@asset_2.reload.view_score).to eq(40.0)
        expect(@asset_3.reload.view_score).to be_nil
        expect(@asset_4.reload.view_score).to be_nil
        expect(@asset_5.reload.view_score).to eq(40.0)
        expect(@asset_6.reload.view_score).to eq(20.0)
        expect(@asset_7.reload.view_score).to be_nil
        expect(@asset_8.reload.view_score).to eq(20.0)
        # do pulsar for a bit
        allow(AssetUserAccessLog).to receive(:channel_config).and_return({
                                                                           "pulsar_writes_enabled" => true,
                                                                           "pulsar_reads_enabled" => true,
                                                                           "db_writes_enabled" => true
                                                                         })
        compaction_state = AssetUserAccessLog.metadatum_payload
        expect(compaction_state[:max_log_ids].count { |id| id > 0 } > 0).to be_truthy
        Timecop.freeze do
          generate_log([@asset_2, @asset_7, @asset_3], 5)
          AssetUserAccessLog.compact
          generate_log([@asset_2, @asset_4, @asset_6], 40)
          AssetUserAccessLog.compact
        end
        expect(@asset_1.reload.view_score).to eq(60.0)
        expect(@asset_2.reload.view_score).to eq(85.0)
        expect(@asset_3.reload.view_score).to eq(5.0)
        expect(@asset_4.reload.view_score).to eq(40.0)
        expect(@asset_5.reload.view_score).to eq(40.0)
        expect(@asset_6.reload.view_score).to eq(60.0)
        expect(@asset_7.reload.view_score).to eq(5.0)
        expect(@asset_8.reload.view_score).to eq(20.0)
        compaction_state = AssetUserAccessLog.metadatum_payload
        expect(compaction_state[:max_log_ids].count { |id| id > 0 } > 0).to be_truthy
        # Stop writing to postgres entirely for a while
        allow(AssetUserAccessLog).to receive(:channel_config).and_return({
                                                                           "pulsar_writes_enabled" => true,
                                                                           "pulsar_reads_enabled" => true,
                                                                           "db_writes_enabled" => false
                                                                         })
        Timecop.freeze do
          generate_log([@asset_3, @asset_8, @asset_4], 10)
          AssetUserAccessLog.compact
        end
        compaction_state = AssetUserAccessLog.metadatum_payload
        expect(compaction_state[:max_log_ids].count { |id| id > 0 } > 0).to be_truthy
        expect(@asset_1.reload.view_score).to eq(60.0)
        expect(@asset_2.reload.view_score).to eq(85.0)
        expect(@asset_3.reload.view_score).to eq(15.0)
        expect(@asset_4.reload.view_score).to eq(50.0)
        expect(@asset_5.reload.view_score).to eq(40.0)
        expect(@asset_6.reload.view_score).to eq(60.0)
        expect(@asset_7.reload.view_score).to eq(5.0)
        expect(@asset_8.reload.view_score).to eq(30.0)

        # resume postgres writing
        allow(AssetUserAccessLog).to receive(:channel_config).and_return({
                                                                           "pulsar_writes_enabled" => true,
                                                                           "pulsar_reads_enabled" => true,
                                                                           "db_writes_enabled" => true
                                                                         })
        Timecop.freeze do
          generate_log([@asset_4, @asset_1, @asset_5], 10)
          AssetUserAccessLog.compact
        end
        compaction_state = AssetUserAccessLog.metadatum_payload
        expect(compaction_state[:max_log_ids].count { |id| id > 0 } > 0).to be_truthy
        expect(@asset_1.reload.view_score).to eq(70.0)
        expect(@asset_2.reload.view_score).to eq(85.0)
        expect(@asset_3.reload.view_score).to eq(15.0)
        expect(@asset_4.reload.view_score).to eq(60.0)
        expect(@asset_5.reload.view_score).to eq(50.0)
        expect(@asset_6.reload.view_score).to eq(60.0)
        expect(@asset_7.reload.view_score).to eq(5.0)
        expect(@asset_8.reload.view_score).to eq(30.0)
        # switch back to postgres compaction!
        allow(AssetUserAccessLog).to receive(:channel_config).and_return({
                                                                           "pulsar_writes_enabled" => true,
                                                                           "pulsar_reads_enabled" => false,
                                                                           "db_writes_enabled" => true
                                                                         })
        Timecop.freeze do
          generate_log([@asset_3, @asset_8, @asset_4], 5)
          AssetUserAccessLog.compact
          generate_log([@asset_3, @asset_5, @asset_7], 5)
          AssetUserAccessLog.compact
        end
        compaction_state = AssetUserAccessLog.metadatum_payload
        expect(compaction_state[:max_log_ids].count { |id| id > 0 } > 0).to be_truthy
        expect(@asset_1.reload.view_score).to eq(70.0)
        expect(@asset_2.reload.view_score).to eq(85.0)
        expect(@asset_3.reload.view_score).to eq(25.0)
        expect(@asset_4.reload.view_score).to eq(65.0)
        expect(@asset_5.reload.view_score).to eq(55.0)
        expect(@asset_6.reload.view_score).to eq(60.0)
        expect(@asset_7.reload.view_score).to eq(10.0)
        expect(@asset_8.reload.view_score).to eq(35.0)
      end
    end
  end

  describe ".reschedule!" do
    it "puts the new job on the right strand" do
      AssetUserAccessLog.reschedule!
      expect(Delayed::Job.where(strand: AssetUserAccessLog.strand_name).count).to eq(1)
    end
  end

  describe ".metadatum_payload" do
    it "has a reasonable default" do
      CanvasMetadatum.delete_all
      default_metadatum = AssetUserAccessLog.metadatum_payload
      expect(default_metadatum[:max_log_ids]).to eq([0, 0, 0, 0, 0, 0, 0])
      expect(default_metadatum[:pulsar_partition_iterators]).to eq({})
    end

    it "faithfully returns existing state" do
      AssetUserAccessLog.update_metadatum({
                                            max_log_ids: [1, 2, 3, 4, 5, 6, 7],
                                            pulsar_partition_iterators: {
                                              42 => "(10668,7,42,0)"
                                            }
                                          })
      stored_metadatum = AssetUserAccessLog.metadatum_payload
      expect(stored_metadatum[:max_log_ids]).to eq([1, 2, 3, 4, 5, 6, 7])
      expect(stored_metadatum[:pulsar_partition_iterators]["42"]).to eq("(10668,7,42,0)")
    end

    it "defaults MISSING state during transition to message bus" do
      AssetUserAccessLog.update_metadatum({
                                            max_log_ids: [1, 2, 3, 4, 5, 6, 7]
                                          })
      stored_metadatum = AssetUserAccessLog.metadatum_payload
      expect(stored_metadatum[:max_log_ids]).to eq([1, 2, 3, 4, 5, 6, 7])
      default_pulsar_state = stored_metadatum[:pulsar_partition_iterators]
      expect(default_pulsar_state).to eq({})
    end
  end
end
