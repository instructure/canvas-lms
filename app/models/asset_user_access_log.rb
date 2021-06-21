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
class AssetUserAccessLog
  # this class is a companion to AssetUserAccess, and is used
  # to relieve write throughput pressure for little changes
  # like bumps to view counts.  The general design is to make
  # many small inserts and compact them into real updates later.
  #
  # aua_logs_0 and other tables (up to aua_logs_6) hold the
  # inserted data for little updates like this for each day of the
  # week (0 == sunday, 6 == saturday).  This lets us truncate
  # a day of processed values rather than deleting a bunch of rows,
  # easier on I/O throughput. (see the AuaLog[INDEX] models below)
  #
  # Managed by a PluginSetting for "asset_user_access_logs",
  # it should default mostly to the "update" write_path which
  # does not use this log-and-compact model.  To make a given
  # setting level use this model, you'd have to set:
  #
  # ps = PluginSetting.find_or_initialize_by(name: "asset_user_access_logs")
  # ps.inheritance_scope = "shard"
  # ps.settings = { max_log_ids: [0,0,0,0,0,0,0], write_path: 'log' }
  # ps.save!
  #
  # and confirm that your settings look right in a new process:
  # PluginSetting.cached_plugin_setting("asset_user_access_logs")

  # Yeah, the multiple models thing below
  # feels a little silly, but we do want to take
  # advantage of all of AR's sql writing helpers,
  # resetting the table name on a single model seems
  # possibly dangerous depending on where that's cached
  # throughout the rails stack, and they should
  # only get used internally to the AssetUserAccessLog
  # class.
  class AuaLog0 < ActiveRecord::Base
    self.table_name = "aua_logs_0"
  end
  class AuaLog1 < ActiveRecord::Base
    self.table_name = "aua_logs_1"
  end
  class AuaLog2 < ActiveRecord::Base
    self.table_name = "aua_logs_2"
  end
  class AuaLog3 < ActiveRecord::Base
    self.table_name = "aua_logs_3"
  end
  class AuaLog4 < ActiveRecord::Base
    self.table_name = "aua_logs_4"
  end
  class AuaLog5 < ActiveRecord::Base
    self.table_name = "aua_logs_5"
  end
  class AuaLog6 < ActiveRecord::Base
    self.table_name = "aua_logs_6"
  end

  MODEL_BY_DAY_OF_WEEK_INDEX = [
    AuaLog0, AuaLog1, AuaLog2, AuaLog3, AuaLog4, AuaLog5, AuaLog6
  ].freeze
  METADATUM_KEY = "aua_logs_compaction_state"
  PULSAR_NAMESPACE="asset_user_access_log"
  PULSAR_SUBSCRIPTION="aua_log_compactor"

  def self.put_view(asset_user_access, timestamp: nil)
    # the "timestamp:" argument is useful for testing or backfill/replay
    # recovery scenarios, but in
    # production generally isn't expected to be used because the log
    # is being written at the time of the view.
    # timestamp is therefor usually "nil", and becomes "now"
    # below when inferring which table to talk to.
    ts = timestamp || Time.now.utc
    log_values = { asset_user_access_id: asset_user_access.id, created_at: ts }
    log_entry = log_model(ts).new(log_values)
    if write_to_db_partition?(::Switchman::Shard.current)
      log_entry.save_without_transaction(touch: false)
    end

    # make sure that any message bus config is relative to the shard
    # the actual AUA record lives on.  The topic name
    # and channel config need to be read relative
    # to the same shard throughput.
    asset_user_access.shard.activate do
      shard = ::Switchman::Shard.current
      if write_to_message_bus?(shard)
        log_values[:created_at] = log_values[:created_at].to_i
        # TODO: these 2 values are used to keep the metadata
        # about which records have been processed already in sync
        # between the postgres and pulsar versions.  Even if we switch
        # back and forth between consuming from postgres and pulsar,
        # we won't compact the same record twice.  When we no longer
        # use the postgres path, we can rely on the internal sequence IDs from
        # the message bus to track what we have and have not processed
        # and the daily partitions won't be relevant anymore; at that point
        # we will no longer need to add these 2 values to the log entry.
        log_values[:log_entry_id] = log_entry.id
        log_values[:partition_index] = ts.wday
        publish_message_to_bus(log_values, shard)
      end
    end
  end

  def self.publish_message_to_bus(log_values, shard)
    producer = MessageBus.producer_for(PULSAR_NAMESPACE, message_bus_topic_name(shard))
    producer.send(log_values.to_json)
  end

  def self.message_bus_topic_name(shard)
    "view-increments-#{shard.id}"
  end

  # mostly useful for verifying writes by using the same
  # partition inference mechanism
  def self.for_today(asset_user_access, timestamp: nil)
    log_model(timestamp).where(asset_user_access_id: asset_user_access.id)
  end

  # Since we're doing "partition" management ourselves
  # this is how we can take a timestamp (usually "now") and decide
  # which model to read/write from.
  def self.log_model(timestamp)
    ts = timestamp || Time.now.utc
    day_of_week = ts.wday
    MODEL_BY_DAY_OF_WEEK_INDEX[day_of_week]
  end

  def self.plugin_setting
    PluginSetting.find_by_name(:asset_user_access_logs)
  end

  # TODO: these config predicate methods should only exist while we are
  # transitioning log compaction from postgres to pulsar.
  # We can remove them entirely, along with the postgres read/write
  # code paths, once that transition is complete.
  def self.write_to_message_bus?(shard)
    self.channel_config(shard).fetch("pulsar_writes_enabled", false)
  end

  # TODO: these config predicate methods should only exist while we are
  # transitioning log compaction from postgres to pulsar.
  # We can remove them entirely, along with the postgres read/write
  # code paths, once that transition is complete.
  def self.write_to_db_partition?(shard)
    self.channel_config(shard).fetch("db_writes_enabled", true)
  end

  # TODO: these config predicate methods should only exist while we are
  # transitioning log compaction from postgres to pulsar.
  # We can remove them entirely, along with the postgres read/write
  # code paths, once that transition is complete.
  def self.read_from_message_bus?(shard)
    self.channel_config(shard).fetch("pulsar_reads_enabled", false)
  end

  # This config map is intended to be used during the transition
  # between writing these log updates through postgres directly
  # to writing them through an external message bus to save on
  # write throughput.
  #
  # TODO: Once we are stably writing logs through the message bus
  # we can drop this config information entirely.
  def self.channel_config(shard)
    settings = DynamicSettings.find(tree: :private, cluster: shard.database_server.id)
    YAML.safe_load(settings['aua.yml'] || '{}')
  end

  # TODO: After completing transition to pulsar, we can remove the "max_log_ids" from this
  # metadata entry entirely and just store the message bus sequence number
  def self.metadatum_payload
    default_metadatum = {
      max_log_ids: [0,0,0,0,0,0,0],
      # in pulsar, there is no order guarantee
      # between partitions.  WITHIN a partition,
      # the message ids are directly comparable.
      # if you take a pulsar message and examine it's
      # message_id it will look like (10668,7,-1,0)
      # which is "([ledger_id], [entry_id], [partition_id], [batch_index])".
      # Since we don't write in batches for AUA, if
      # you have two messages from the same partition, it is
      # sufficient to compare their ledger id, and then their entry_id.
      # larger integer values are later.  That means
      # we need to store the ledger_id&entry_id of the most recently
      # processed message IN EACH PARTITION.  The structure
      # of this metadatum will therefore have the partition_id
      # as a key, and the value will be the string representation of the max ID
      # in that partition so far
      pulsar_partition_iterators: {
        # e.g. 42 => (10668,7,42,0)
      }
    }
    output_metadatum = CanvasMetadatum.get(METADATUM_KEY, default_metadatum)
    # make sure if we have prior storage without this key that
    # we get a default value populated
    output_metadatum[:pulsar_partition_iterators] ||= default_metadatum[:pulsar_partition_iterators]
    output_metadatum
  end

  def self.update_metadatum(compaction_state)
    CanvasMetadatum.set(METADATUM_KEY, compaction_state)
  end

  # This is the job component, taking the inserts that have
  # accumulated and writing them to the AUA records they actually
  # belong to with as few updates as possible.
  def self.compact
    ps = plugin_setting
    if ps.nil? || ps.settings[:write_path] != "log"
      return self.log_message("PluginSetting configured OFF, aborting")
    end

    shard = ::Switchman::Shard.current
    caught_up = if self.read_from_message_bus?(shard)
      self.message_bus_compact
    else
      self.postgres_compact
    end
    # it's ok if we didn't complete, we time the job out so that
    # for things that need to move or hold jobs they don't have to
    # wait forever.  If we completed compaction, though, just finish.
    AssetUserAccessLog.reschedule! unless caught_up
  end

  # Open (usually RE-open) a subscription
  # to the pulsar topic for this shard,
  # use the metadata state (basically an iterator position)
  # to make sure that we aren't double-processing messages,
  # and turn all the messages that we can into bulk SQL
  # update statements so we minimize the consumed DB primary
  # write throughput for keeping AUA counts up to date
  # at the tradeoff of some eventual consistency.
  def self.message_bus_compact
    # Step 0) load iterator state and settings
    compaction_state = self.metadatum_payload
    compaction_start = Time.now.utc
    mb_settings = self.compaction_settings
    log_batch_size = mb_settings[:log_batch_size]
    max_compaction_time = mb_settings[:max_compaction_time]
    receive_timeout = mb_settings[:receive_timeout]
    # semaphore to flip if we manage to advance to the "head"
    # of the topic within this compaction run.
    caught_up = false
    # 1) open subscription
    # usually this will be RE-opening an existing subscription,
    # which means that pulsar's stored state (keyed by the
    # subscription name, "PULSAR_SUBSCRIPTION") will know to
    # start giving us messages from the last place we left off.
    # If that subscription is allowed to expire because the jobs
    # queue gets backlogged badly, a new subscription will start from
    # the earliest message in storage on that topic, but we
    # can use the compaction state from metadatum_payload to
    # skip forward until we find messages we haven't processed.
    shard = ::Switchman::Shard.current
    topic = self.message_bus_topic_name(shard)
    # we explicitly close this consumer at the end of processing, so we don't want
    # a cached consumer.
    consumer = MessageBus.consumer_for(PULSAR_NAMESPACE, topic, PULSAR_SUBSCRIPTION, force_fresh: true)
    # 2) establish in-memory datastructure for compacting a set of events.
    # the hash will have IDs for asset_user_access records as it's key, and
    # the value will be a hash containing the aggregation state for that
    # one record based on all messages addressed to it in the current batch
    # like this:
    #
    # asset_user_access_id => {
    #  count: INT,
    #  max_updated_at: TIMESTAMP
    # }
    compaction_map = {}
    to_acknowledge = []
    new_iterator_state = compaction_state[:max_log_ids].dup
    # map of partition ids to max message ID seen for that partition
    new_message_bus_iterator_state = compaction_state[:pulsar_partition_iterators].dup
    continue_consuming_from_bus = true
    while continue_consuming_from_bus
      consumed_count = 0
      skip_count = 0
      self.log_message("Pulling messages from bus...")
      # 3) subscribe to start receiving messages
      while !caught_up && (consumed_count < log_batch_size)
        message = nil
        begin
          message = consumer.receive(receive_timeout)
        rescue Pulsar::Error::Timeout
          # this basically means we caught up to the end of the topic
          # and don't need to reschedule immediately
          caught_up = true
          break
        end
        message_hash = JSON.parse(message.data).with_indifferent_access
        unless message_hash.key?(:asset_user_access_id)
          self.log_message("MALFORMED MESSAGE, skipping: #{message.data}")
          next
        end
        # 4) check each entry against the metadata index to see if it should be processed before adding to datastructure
        pulsar_message_id = MessageBus::MessageId.from_string(message.message_id.to_s)
        pulsar_partition_id = pulsar_message_id.partition_id
        # TODO: The postgres iterator and metadata values are only here for maintaining
        # iterator state while transitioning from postgres to pulsar.
        # we can ONLY use the message ids from pulsar and the :pulsar_partition_iterators
        # iterator state once that transition is complete.
        message_partition_index = message_hash[:partition_index]
        log_entry_id = message_hash[:log_entry_id]

        max_postgres_partition_id = compaction_state[:max_log_ids][message_partition_index]
        max_pulsar_partition_message_id = compaction_state[:pulsar_partition_iterators][pulsar_partition_id.to_s]
        should_process_message = (
          log_entry_id > max_postgres_partition_id ||
          max_pulsar_partition_message_id.nil? ||
          pulsar_message_id > MessageBus::MessageId.from_string(max_pulsar_partition_message_id)
        )
        # even if we don't PROCESS the message, that's only because
        # we already have that data compacted into the AUA table state
        # so we still want to acknowledge it to avoid seeing it again.
        to_acknowledge << message
        # 5) store the max metadata for each index (order is guaranteed within the partition)
        # for the same reason: even if we don't want to process the message, we want to make sure
        # our iterator is advanced as far as possible.
        new_iterator_state[message_partition_index] = [new_iterator_state[message_partition_index], log_entry_id].max
        # always hold on to the largest message ID we've seen for this pulsar partition.
        new_message_bus_iterator_state[pulsar_partition_id.to_s] = [
          new_message_bus_iterator_state[pulsar_partition_id.to_s], # might be nil if this is the first one
          pulsar_message_id.to_s
        ].compact.map{|mids| MessageBus::MessageId.from_string(mids) }.max.to_s

        if should_process_message
          # 6) compact the message into our bulk-update in-memory state
          aua_id = message_hash[:asset_user_access_id]
          event_ts = Time.zone.at(message_hash[:created_at])
          if compaction_map.key?(aua_id)
            compaction_map[aua_id][:count] += 1
            compaction_map[aua_id][:max_updated_at] = [compaction_map[aua_id][:max_updated_at], event_ts].max
          else
            compaction_map[aua_id] = {
              count: 1,
              max_updated_at: event_ts
            }
          end
          consumed_count += 1
        else
          skip_count += 1
          if skip_count % 1000 == 0
            self.log_message("...Skipped #{skip_count} so far...")
          end
        end
        # 7) loop on subscription until the datastructure is filled or the receive operation times out
      end
      # 8) Either we coudn't find anymore messages on the topic, or we have a full batch.
      #  turn the compaction_map data structure into a sql update.
      #  The adapter array built here turns the message bus reduction
      #  datastructure into the same shape as the results
      #  from the aggregation query in the postgres path so
      #  we can use the same SQL generation in both paths.
      aggregation_results = compaction_map.map do |aua_id_key, aggregation|
        {
          'aua_id' => aua_id_key,
          'view_count' => aggregation[:count],
          'max_updated_at' => aggregation[:max_updated_at]
        }
      end


      # 9) Write batch update if there's anything to compact, and update metadata
      GuardRail.activate(:primary) do
        # transaction ensures that aggregation results and iterator
        # state are updated in lock step, so if we fail we should re-aggregate from the same point.
        AssetUserAccess.transaction do
          if aggregation_results.size > 0
            self.log_message("message bus batch updating (sometimes these queries don't get logged)...")
            AssetUserAccess.connection.execute(self.compaction_sql(aggregation_results))
          end
          # Here we want to write the iteration state into the database
          # so that we don't double count rows later.  The next time the job
          # runs it can pick up at this point and only count rows that haven't yet been counted.
          compaction_state[:max_log_ids] = new_iterator_state
          compaction_state[:pulsar_partition_iterators] = new_message_bus_iterator_state
          self.update_metadatum(compaction_state)
          self.log_message("...batch update complete")
        end
      end

      # 10) acknowledge the messages to pulsar.
      #  no problem if this fails, really, because
      # we'll skip any messages that get re-delivered
      # due to the iterator state stored in the db.
      to_acknowledge.each{|m| consumer.acknowledge(m) }

      # 10) reset data structure for a new batch
      # of messages, then repeat unless the job has timed out or
      # we've caught all the way up to the head of the topic.
      to_acknowledge = []
      compaction_map = {}
      if caught_up
        continue_consuming_from_bus = false
      else
        batch_timestamp = Time.now.utc
        continue_consuming_from_bus = ((batch_timestamp - compaction_start) <= (max_compaction_time * 60))
        # if false, we ran out of time, let the job get re-scheduled
      end
    end

    # 10) close the subscription politely so another
    # job can start a new one later on a different box safely.
    # we want to stay in "exclusive" mode so that only one job
    # can be updating the iterator state.
    consumer.close()
    # 11) return value indicating whether we should immediately re-schedule or not
    caught_up
  end

  def self.compaction_settings
    {
      # how many messages should we pull off the log before compacting them.
      # a higher value would mean more memory pressure for the job,
      # and longer transaction time for the bulk update, but the tradeoff
      # is less overall write throughput because more of the log backlog
      # is packed into a single update (especially between messages that
      # are incrementing counts on the same AUA record).
      log_batch_size: Setting.get("aua_log_batch_size", "10000").to_i,
      # how long should we allow this job to run before rescheduling.
      # higher values mean that the job will be allowed to process more of the log
      # in a single execution, which lowers the overall data latency,
      # but the tradeoff is longer running jobs complicate queue management
      # and juggling.
      max_compaction_time: Setting.get("aua_compaction_time_limit_in_minutes", "5").to_i,
      # how long should we block waiting to see if there are any more messages
      # on the pulsar topic.  This should stay short, because if we make it to
      # the "HEAD" of the topic and block for 30 seconds or something then it's
      # very likely a new message will come in, but that's mostly wasted compute time.
      # If this timeout is exceeded, we can catch that and decide "we've caught up for now,
      # no more work to do".
      receive_timeout: Setting.get("aua_compaction_receive_timeout_ms", "1000").to_i
    }
  end

  # If we're using postgres as the transport layer
  # (TODO: THIS IS GOING AWAY)
  # This should help reduce write throughput on the DB
  # because in many cases people "view" the same
  # asset repeatedly (refreshing over and over for example), so we can condense
  # that to a single update.
  # We also can apply friction to the job (via strand holding or increased sleep timers)
  # to defer the writes for longer by slowing the processing down, which allows us to take
  # fewer writes at peak and use spare I/O capacity later in the day if necessary to catch up.
  def self.postgres_compact
    ts = Time.now.utc
    ps = plugin_setting
    yesterday_ts = ts - 1.day
    yesterday_model = log_model(yesterday_ts)
    if yesterday_model.take(1).size > 0
      yesterday_completed = compact_partition(yesterday_ts)
      ps.reload
      compaction_state = self.metadatum_payload
      max_yesterday_id = compaction_state[:max_log_ids][yesterday_ts.wday]
      if yesterday_completed && max_yesterday_id >= yesterday_model.maximum(:id)
        # we have now compacted all the writes from the previous day.
        # since the timestamp (now) is into the NEXT utc day, no further
        # writes can happen to yesterdays partition, and we can truncate it,
        # and reset our iterator tracking for that day (this is important because
        # in some cases like in specific restoration scenarios sequences can be
        # "reset" by looking for the max id value in a table and making it bigger than that.
        #  Tracking iterator state indefinitely could result in missing writes if a truncated
        # table gets it's iterator reset).
        yesterday_model.transaction do
          if truncation_enabled?
            GuardRail.activate(:deploy) do
              yesterday_model.connection.truncate(yesterday_model.table_name)
            end
            compaction_state[:max_log_ids][yesterday_ts.wday] = 0
            self.update_metadatum(compaction_state)
          end
        end
      end
      return false unless yesterday_completed
    end
    today_completed = compact_partition(ts)
    # it's ok if we didn't complete, we time the job out so that
    # for things that need to move or hold jobs they don't have to
    # wait forever.  If we completed compaction, though, just finish.
    today_completed
  end

  # TODO: We only care about truncation
  # while we're using postgres for the log layer.
  # After the pulsar transition this method should get removed.
  def self.truncation_enabled?
    # we can flip this setting when we're pretty sure it's safe to start dropping
    # data, the iterator state will keep it healthy^
    Setting.get('aua_log_truncation_enabled', 'false') == 'true'
  end

  def self.reschedule!
    AssetUserAccessLog.delay(strand: strand_name).compact
  end

  def self.strand_name
    "AssetUserAccessLog.compact:#{Shard.current.database_server.id}"
  end

  # TODO: These are postgres partitions, not pulsar topic partitions.
  # Once we are doing this log-compaction operation completely via pulsar, we no longer
  # need this implmentation and can remove it.
  def self.compact_partition(ts)
    partition_model = log_model(ts)
    log_batch_size = Setting.get("aua_log_batch_size", "10000").to_i
    max_compaction_time = Setting.get("aua_compaction_time_limit_in_minutes", "5").to_i
    compaction_start = Time.now.utc
    GuardRail.activate(:secondary) do
      # select the boundaries of the log segment we're going to iterate.
      # we may still _process_ records bigger than this as part of a single write,
      # but will stop loading new batches to pluck AUA ids from when we hit the maximum.
      # this is just to avoid a single job never finishing because it's always processing
      # "just a few more"
      partition_upper_bound = partition_model.maximum(:id)
      partition_lower_bound = partition_model.minimum(:id)
      if partition_lower_bound.nil? || partition_upper_bound.nil?
        # no data means there's nothing in this partition to compact.
        return true
      end

      # fetch from the canvas metadatum compaction state the last compacted log id.  This lets us
      # resume log compaction past the records we've already processed, but without
      # having to delete records as we go (which would churn write IO), leaving the log cleanup
      # to the truncation operation that occurs after finally processing "yesterdays" partition.
      # We'd expect them to usually be 0 because we reset the value after truncating the partition
      # (defends against sequences being reset to the "highest" record in a table and then
      # deciding we already chomped these logs).
      compaction_state = self.metadatum_payload
      state_max_log_ids = compaction_state.fetch(:max_log_ids, [0,0,0,0,0,0,0])
      log_id_bookmark = [(partition_lower_bound-1), state_max_log_ids[ts.wday]].max
      while log_id_bookmark < partition_upper_bound
        self.log_message("processing #{log_id_bookmark} from #{partition_upper_bound}")
        # maybe we won't need this, but if we need to slow down throughput and don't want to hold
        # the jobs, increasing this setting value could tradeoff throughput for latency
        # slowly.  We load in INSIDE the loop so that SIGHUPS can get recognized
        # more quickly (otherwise we'd have to wait for a job to die or be killed
        # to respond to updated settings)
        intra_batch_pause = Setting.get("aua_log_compaction_batch_pause", "0.0").to_f
        batch_upper_boundary = log_id_bookmark + log_batch_size
        agg_sql = aggregation_query(partition_model, log_id_bookmark, batch_upper_boundary)
        log_segment_aggregation = partition_model.connection.execute(agg_sql)
        if log_segment_aggregation.to_a.size > 0
          # we found records in this segment, we need to both
          # compute the new iterator position (it's just the max
          # of all ids because we constrained the aggregation to a range of ids,
          # taking the full set of logs in that range)
          update_query = compaction_sql(log_segment_aggregation)
          new_iterator_pos = log_segment_aggregation.map{|r| r["max_id"]}.max
          GuardRail.activate(:primary) do
            partition_model.transaction do
              self.log_message("batch updating (sometimes these queries don't get logged)...")
              partition_model.connection.execute(update_query)
              self.log_message("...batch update complete")
              # Here we want to write the iteration state into the database
              # so that we don't double count rows later.  The next time the job
              # runs it can pick up at this point and only count rows that haven't yet been counted.
              compaction_state[:max_log_ids][ts.wday] = new_iterator_pos
              self.update_metadatum(compaction_state)
            end
          end
          log_id_bookmark = new_iterator_pos
          sleep(intra_batch_pause) if intra_batch_pause > 0.0
        else
          # no records found in this range, we must be paging through an open segment.
          # If we actually have a jump in sequences, there will
          # be more records greater than the batch, so we will choose
          # the minimum ID greater than the current bookmark, because it's safe
          # to advance to that point even under replication lag.
          next_id = partition_model.where('id > ?', log_id_bookmark).minimum(:id)
          return false unless next_id.present? # can't find any more records for now, do not advance
          # make sure we actually process the next record by offsetting
          # to just under it's ID
          new_bookmark_id = next_id - 1
          GuardRail.activate(:primary) do
            compaction_state[:max_log_ids][ts.wday] = new_bookmark_id
            self.update_metadatum(compaction_state)
          end
          log_id_bookmark = new_bookmark_id
        end
        batch_timestamp = Time.now.utc
        if (batch_timestamp - compaction_start) > (max_compaction_time * 60)
          # we ran out of time, let the job get re-scheduled
          return false
        end
      end
    end
    return true # to indicate we didn't bail
  end

  # for a given log segment (the records between IDs A and B),
  # we want to aggregate one row per AUA that needs an update.
  # since each row is a "view", counting them is the amount to increment by.
  # we need to take the max log id from each segment so we can compute
  # an actual bookmark value to offset future iterations.
  #
  # TODO: this aggregation is only important for turning postgres
  # log inserts into update tuples.  When we're on pulsar
  # for AUA log compaction completely, this query can be removed.
  def self.aggregation_query(partition_model, log_id_bookmark, batch_upper_boundary)
    <<~SQL
    SELECT asset_user_access_id AS aua_id,
      COUNT(asset_user_access_id) AS view_count,
      MAX(created_at) AS max_updated_at,
      MAX(id) AS max_id
    FROM #{partition_model.quoted_table_name}
      WHERE id > #{log_id_bookmark}
        AND id <= #{batch_upper_boundary}
      GROUP BY asset_user_access_id
    SQL
  end

  # we want to do the whole set of updates for this batch to AUA rows
  # in one query, if possible.  This builds an update row
  # of literals for each aggregated set of log entris for an AUA.
  # we want to add on top of the view_score in the
  # statement itself to make sure we don't miss any out of band writes
  # from requests at the same time, same with taking the LATEST
  # of the max timestamp from a log segment and the timestamp currently on the
  # AUA record
  def self.compaction_sql(aggregation_results)
    values_list = aggregation_results.map do |row|
      max_updated_at = row['max_updated_at']
      max_updated_at = max_updated_at.to_s(:db)
      "(#{row["aua_id"]}, #{row["view_count"]}, '#{max_updated_at}')"
    end.join(", ")

    update_query = <<~SQL
      UPDATE #{AssetUserAccess.quoted_table_name} AS aua
      SET view_score = COALESCE(aua.view_score, 0) + log_segment.view_count,
        updated_at = GREATEST(aua.updated_at, TO_TIMESTAMP(log_segment.max_updated_at, 'YYYY-MM-DD HH24:MI:SS.US')),
        last_access = GREATEST(aua.last_access, TO_TIMESTAMP(log_segment.max_updated_at, 'YYYY-MM-DD HH24:MI:SS.US'))
      FROM ( VALUES #{values_list} ) AS log_segment(aua_id, view_count, max_updated_at)
      WHERE aua.id=log_segment.aua_id
    SQL
  end

  def self.log_message(msg)
    Rails.logger.info("[AUA_LOG_COMPACTION:#{Shard.current.id}] - #{msg}")
  end
end
