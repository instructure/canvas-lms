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
  PULSAR_NAMESPACE = "asset_user_access_log"
  PULSAR_SUBSCRIPTION = "aua_log_compactor"
  PULSAR_TOPIC_PREFIX = "view-increments"

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
        log_values[:root_account_id] = asset_user_access.root_account_id
        root_account = asset_user_access.root_account
        publish_message_to_bus(log_values, root_account)
      end
    end
  end

  def self.publish_message_to_bus(log_values, root_account)
    topic_name = message_bus_topic_name(root_account)
    msg = log_values.to_json
    MessageBus.send_one_message(PULSAR_NAMESPACE, topic_name, msg)
  rescue ::MessageBus::MemoryQueueFullError => e
    Rails.logger.warn("[AUA LOG] Write failed due to throughput: #{topic_name} , #{msg}")
    CanvasErrors.capture_exception(:asset_user_access_logs, e, :warn)
  end

  def self.message_bus_topic_name(root_account)
    "#{PULSAR_TOPIC_PREFIX}-#{root_account.uuid}"
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
      max_log_ids: [0, 0, 0, 0, 0, 0, 0],
      # in pulsar, there is no order guarantee
      # between partitions, and we're using a separate topic for each
      # root account on this shard.  WITHIN a partition,
      # the message ids are directly comparable.
      # if you take a pulsar message and examine it's
      # message_id it will look like (10668,7,-1,0)
      # which is "([ledger_id], [entry_id], [partition_id], [batch_index])".
      # Since we don't write in batches for AUA, if
      # you have two messages from the same partition, it is
      # sufficient to compare their ledger id, and then their entry_id.
      # larger integer values are later.  That means
      # we need to store the ledger_id&entry_id of the most recently
      # processed message IN EACH PARTITION for each topic.  The structure
      # of this metadatum will be bucketed by root_account_id, and
      # under that will therefore have the partition_id
      # as a key, and the value will be the string representation of the max ID
      # in that partition so far.
      pulsar_partition_iterators: {
        # assuming three root accounts with IDs: { 5, 6, 7 },
        # an example structure mapping root_account_ids
        # to partition/message_id hashs might look like this:
        # 5 => { 42 => (10668,7,42,0), 41 => (10602,85,41,0) },
        # 6 => { 2 => (10501,24,2,0) },
        # 7 => { 1 => (10719,13,1,0)}
      },
      # this is a temporary bucket for storing PARTIAL iterator updates
      # while we're working with the message bus transition.
      # Because in the message bus we consume records by root account,
      # there's no global ordering guarantee for which POSTGRES records
      # we've seen except within root account buckets (i.e. it's possible to say
      # "we've seen record 712", but for records 710 and 711 to belong to other root
      # accounts and therefore not YET be consumed in a messagebus compaction run).  In order
      # to not break iterator state during the transition, each topic consumption
      # operation on the message bus side can write it's max iterator state
      # to this part of the metadatum by root account.
      #
      # to be resiliant to a "ripcord to postgres" situation, the postgres compaction
      # operation also needs to consider the presence of this state as a signal
      # to rely on the data in this part of the state as the "true" iterator state
      # for AUA records with this root account id.  A full postgres compaction returns
      # us to a state where we can make claims about how far into the postgres partitions
      # we've advanced, and so is allowed to zero this state out after it updates the
      # global postgres state above for this shard "max_log_ids".
      temp_root_account_max_log_ids: {

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
    Bundler.require(:pulsar) # makes sure we can capture Pulsar errors
    # Step 0) load iterator state and settings
    compaction_state = self.metadatum_payload
    compaction_start = Time.now.utc
    mb_settings = self.compaction_settings
    log_batch_size = mb_settings[:log_batch_size]
    max_compaction_time = mb_settings[:max_compaction_time]
    receive_timeout = mb_settings[:receive_timeout]
    early_exit = false # use to signal as soon as we've decided to bail on compaction.
    positive_runtime_budget = true # set to false when budget runtime exceed allocation

    # 1) begin root_account iteration
    #   most shards have exactly 1 root account.
    #   a few shards have up to 20 root accounts.
    #   there exists at least one shard with around 200 root accounts.
    #   Because we factor topic names by root account ID to be resiliant
    #   to shard changes, we need to iterate through them.
    #   We iterate through them in random order to avoid favoring one root
    #   account over others during heavy compaction load where friction is
    #   being applied to gate down the speed of updates.
    Account.root_accounts.active.order("RANDOM()").pluck(:id).each do |root_account_id|
      # before processing the (next) account in line, make sure we have runtime budget.
      # If not, we need to bail and do other accounts later, just let the job get rescheduled.
      # This is to keep the job healthy by not having it run for too long (that can block
      # things like shard moves, job cluster scaledowns, etc).
      unless positive_runtime_budget
        # make sure this is configured to show we're skipping at least one account.
        early_exit = true
        break
      end

      root_account = Account.find(root_account_id)
      # tracking whether we've consumed all the messages in the topic for just this root account
      caught_up_for_account = false

      # 2) open subscription
      # usually this will be RE-opening an existing subscription,
      # which means that pulsar's stored state (keyed by the
      # subscription name, "PULSAR_SUBSCRIPTION") will know to
      # start giving us messages from the last place we left off.
      # If that subscription is allowed to expire because the jobs
      # queue gets backlogged badly, a new subscription will start from
      # the earliest message in storage on that topic, but we
      # can use the compaction state from metadatum_payload to
      # skip forward until we find messages we haven't processed.
      topic = self.message_bus_topic_name(root_account)
      # we explicitly close this consumer at the end of processing, so we don't want
      # a cached consumer.
      consumer = nil
      connect_attempts = 0
      begin
        consumer = MessageBus.consumer_for(PULSAR_NAMESPACE, topic, PULSAR_SUBSCRIPTION, force_fresh: true)
      rescue ::Pulsar::Error::ConsumerBusy => e
        # this means that another consumer is already running, or is being
        # held open improperly.  If it's the former, we don't want
        # to run at the same time.  If it's the later, we can't really tell
        # that from here, so we should just stop and let that other consumer eventually
        # time out.  No need to fail the job, it will get rescheduled, just like if
        # we'd run out of runtime budget.
        CanvasErrors.capture_exception(:aua_log_compaction, e, :info)
        early_exit = true
        break
      rescue *::MessageBus.rescuable_pulsar_errors => e
        connect_attempts += 1
        CanvasErrors.capture_exception(:aua_log_compaction, e, :warn)
        if connect_attempts >= 2
          # treat it like a runtime timeout, reschedule the job
          # and let it try again.
          early_exit = true
          break
        end
        # It's possible the brokers are being restarted; we'll try
        # one more time to see if pulling new connections allows us to
        # find the brokers again.
        MessageBus.reset!
        retry
      end

      # 3) establish in-memory datastructure for compacting a set of events FOR THIS ROOT ACCOUNT.
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
      compaction_state[:temp_root_account_max_log_ids] ||= {}
      root_account_postgres_iterators = compaction_state[:temp_root_account_max_log_ids].dup
      # map of partition ids to max message ID seen for that partition
      # of the topic for the current root account
      root_account_pulsar_state = compaction_state[:pulsar_partition_iterators].fetch(root_account_id.to_s, {})
      # if there is no temporary state for this root account right now, we should use the global state
      # since that is the max value seen in each partition regardless of root account.
      root_account_postgres_iterator_state = root_account_postgres_iterators.fetch(root_account_id.to_s, new_iterator_state.dup)
      new_message_bus_iterator_state = root_account_pulsar_state.dup
      continue_consuming_from_bus = true

      while continue_consuming_from_bus
        consumed_count = 0
        skip_count = 0
        self.log_message("Pulling messages from bus for RA #{root_account_id}...")
        # 4) subscribe to start receiving messages
        while !caught_up_for_account && (consumed_count < log_batch_size)
          message = nil
          begin
            message = consumer.receive(receive_timeout)
          rescue Pulsar::Error::Timeout
            # this basically means we caught up to the end of THIS topic
            # and don't need to reschedule immediately
            caught_up_for_account = true
            break
          end
          message_hash = JSON.parse(message.data).with_indifferent_access
          unless message_hash.key?(:asset_user_access_id)
            self.log_message("MALFORMED MESSAGE, skipping: #{message.data}")
            next
          end
          # 5) check each entry against the metadata index to see if it should be processed before adding to datastructure
          pulsar_message_id = MessageBus::MessageId.from_string(message.message_id.to_s)
          pulsar_partition_id = pulsar_message_id.partition_id
          # TODO: The postgres iterator and metadata values are only here for maintaining
          # iterator state while transitioning from postgres to pulsar.
          # we can ONLY use the message ids from pulsar and the :pulsar_partition_iterators
          # iterator state once that transition is complete.
          message_partition_index = message_hash[:partition_index]
          log_entry_id = message_hash[:log_entry_id]

          max_postgres_partition_id = compaction_state[:max_log_ids][message_partition_index]
          max_pulsar_partition_message_id = root_account_pulsar_state[pulsar_partition_id.to_s]
          should_process_message = (
            # nil would mean this message ONLY got written to pulsar.
            # exceeding the iterator state would mean the POSTGRES compaction had not processed the letter.
            # NOT nil, but lower than the postgres iterator would mean we'd seen
            # it already in postgres compaction, so no reason to process it now.
            (log_entry_id.nil? || (log_entry_id > max_postgres_partition_id)) &&
            (
              max_pulsar_partition_message_id.nil? ||
              pulsar_message_id > MessageBus::MessageId.from_string(max_pulsar_partition_message_id)
            )
          )

          # even if we don't PROCESS the message, that's only because
          # we already have that data compacted into the AUA table state
          # so we still want to acknowledge it to avoid seeing it again.
          to_acknowledge << message
          # 6) store the max metadata for each index (order is guaranteed within the partition)
          # for the same reason: even if we don't want to process the message, we want to make sure
          # our iterator is advanced as far as possible.
          # (TODO: When we're off of postgres, this iterator state update can go away, and we can
          # just rely on the subsequent MESSAGE BUS iterator state)
          # This is currently only set on the temporary state for this contextual root account
          # in case we have to abort the job (because we cannot make guarantees about postgres
          # ordering when we're processing from each root account in turn).
          root_account_postgres_iterator_state[message_partition_index] = [root_account_postgres_iterator_state[message_partition_index], log_entry_id].compact.max
          # always hold on to the largest message ID we've seen for this pulsar partition.
          most_recent_id_in_this_partition = [
            new_message_bus_iterator_state[pulsar_partition_id.to_s], # might be nil if this is the first one
            pulsar_message_id.to_s
          ].compact.map { |mids| MessageBus::MessageId.from_string(mids) }.max.to_s
          new_message_bus_iterator_state[pulsar_partition_id.to_s] = most_recent_id_in_this_partition

          if should_process_message
            # 7) compact the message into our bulk-update in-memory state
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
          # 8) loop on subscription until the datastructure is filled or the receive operation times out
        end

        # 9) Either we coudn't find anymore messages on the topic, or we have a full batch.
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

        # 10) Write batch update if there's anything to compact, and update metadata
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
            compaction_state[:temp_root_account_max_log_ids][root_account_id.to_s] = root_account_postgres_iterator_state
            compaction_state[:pulsar_partition_iterators][root_account_id.to_s] = new_message_bus_iterator_state
            self.update_metadatum(compaction_state)
            self.log_message("...batch update complete")
          end
        end

        # 11) acknowledge the messages to pulsar.
        #  no problem if this fails, really, because
        # we'll skip any messages that get re-delivered
        # due to the iterator state stored in the db.
        to_acknowledge.each { |m| consumer.acknowledge(m) }

        # 12) reset data structure for a new batch
        # of messages, then repeat unless the job has timed out or
        # we've caught all the way up to the head of the topic.
        to_acknowledge = []
        compaction_map = {}
        if caught_up_for_account
          continue_consuming_from_bus = false
        else
          batch_timestamp = Time.now.utc
          positive_runtime_budget = ((batch_timestamp - compaction_start) <= (max_compaction_time * 60))
          # keep going if we still have time
          continue_consuming_from_bus = positive_runtime_budget
          unless positive_runtime_budget
            # ensure we record this exit since even though we haven't caught
            # up for this account, we're going to signal that it's time
            # to stop.
            early_exit = true
          end
          # if false, we ran out of time, let the job get re-scheduled
        end
      end

      # 13) close the subscription politely so another
      # job can start a new one later on a different box safely.
      # we want to stay in "exclusive" mode so that only one job
      # can be updating the iterator state.
      begin
        consumer.close()
      rescue ::Pulsar::Error::ConnectError => e
        # if we fail to close the connection, but we're already here
        # the job didn't really fail; we already got past all the state updating.
        CanvasErrors.capture_exception(:aua_log_compaction, e, :warn)
      end
    end

    # 14) return value indicating whether we should immediately re-schedule or not
    # As long as we have never flipped the "early_exit" sign, that means
    # we made it through all accounts and didn't run out of job time.
    caught_up = !early_exit
    # you might think "Ah, here we can compact all our postgres iterators into
    # a single global state update since we finished all the root accounts!".
    # Alas, we cannot.  In the time it takes to consume messages
    # from the LAST root account, they may be interleaved with messages from the FIRST root account,
    # and it would be wrong to advance the global iterator state to max values in the last RA
    # without guarantees about what other messages have come in since.  Only
    # a POSTGRES backed compaction job can make global iterator state writes.
    # once we're compacting on the message bus, we need to keep the state-per-root-account
    # until and unless we switch back to postgres.
    caught_up # implicit return
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

    # fetch from the canvas metadatum compaction state the last compacted log id.  This lets us
    # resume log compaction past the records we've already processed, but without
    # having to delete records as we go (which would churn write IO), leaving the log cleanup
    # to the truncation operation that occurs after finally processing "yesterdays" partition.
    # We'd expect them to usually be 0 because we reset the value after truncating the partition
    # (defends against sequences being reset to the "highest" record in a table and then
    # deciding we already chomped these logs).
    compaction_state = self.metadatum_payload

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

      state_max_log_ids = compaction_state.fetch(:max_log_ids, [0, 0, 0, 0, 0, 0, 0])
      root_account_max_ids_map = compaction_state.fetch(:temp_root_account_max_log_ids, {})
      # if there's data in this state bucket, then we're cutting back over from
      # pulsar and we need to consider the partitioned-by-root-account state for
      # the compaction iterators for this one compaction job (afterwards.)
      use_pulsar_ripcord_iterators = !root_account_max_ids_map.empty?
      log_id_bookmark = [(partition_lower_bound - 1), state_max_log_ids[ts.wday]].max
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
        # if there ARE no root accounts that are active, aggregating according to
        # them is pointless.  This can happen in scenarios where a system is being decomissioned.
        if use_pulsar_ripcord_iterators && Account.root_accounts.active.exists?
          # we cannot use the standard aggregation query because of the root-account
          # partition strategy while we were using the message bus transpor layer.
          # We need to replace it with a recovery
          # query that does the aggregation by querying contextual lower-bounds
          # by root account ID, but which produces the same FORMAT of update query.
          agg_sql = pulsar_ripcord_aggregation_query(partition_model, log_id_bookmark, batch_upper_boundary, root_account_max_ids_map, ts.wday)
        end
        log_segment_aggregation = partition_model.connection.execute(agg_sql)
        if log_segment_aggregation.to_a.size > 0
          # we found records in this segment, we need to both
          # compute the new iterator position (it's just the max
          # of all ids because we constrained the aggregation to a range of ids,
          # taking the full set of logs in that range)
          update_query = compaction_sql(log_segment_aggregation)
          new_iterator_pos = log_segment_aggregation.map { |r| r["max_id"] }.max
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
          # the minimum ID greater than the current batch top, because it's safe
          # to advance to that point even under replication lag.
          next_id = partition_model.where('id > ?', log_id_bookmark).minimum(:id)
          if use_pulsar_ripcord_iterators
            # In this case, we actually are advancing because we couldn't find any records
            # we hadn't processed
            # yet in one of the root account partitions.  We need to advance all the way
            # to the top of the batch because we can safely assume replication lag
            # is not in play and that we need to fast forward to the place where
            # we haven't compacted records yet.
            next_id = partition_model.where('id > ?', batch_upper_boundary).minimum(:id)
          end
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
    root_account_max_ids_map = compaction_state.fetch(:temp_root_account_max_log_ids, {})
    unless root_account_max_ids_map.empty?
      # being in this block means that we were in the process of ripcording
      # pulsar back to postgres and we made it all the way through updating our compaction.
      # We are NOW in a position where we don't need to keep checking the by-root-account
      # iteration state from the pulsar processing anymore since we've moved
      # the global iterator past those positions, and we can null out that state
      compaction_state[:temp_root_account_max_log_ids] = {}
      self.update_metadatum(compaction_state)
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

  # This is the "oops" button for switching back to postgres from pulsar.
  # it needs to produce a query that has the same output shape as the "aggregation_query"
  # specified above, but which is sensitive to the individual root account partition iterators
  # in order to get the postgres process back into GLOBALLY consistent postgres iterator
  # state for the shard.
  def self.pulsar_ripcord_aggregation_query(partition_model, log_id_bookmark, batch_upper_boundary, root_account_max_ids_map, pg_partition_index)
    query_prefix = <<~SQL
      SELECT aua_log.asset_user_access_id AS aua_id,
        COUNT(aua_log.asset_user_access_id) AS view_count,
        MAX(aua_log.created_at) AS max_updated_at,
        MAX(aua_log.id) AS max_id
      FROM #{partition_model.quoted_table_name} AS aua_log
      INNER JOIN #{AssetUserAccess.quoted_table_name} AS aua
        ON aua_log.asset_user_access_id = aua.id
      WHERE aua_log.id > #{log_id_bookmark}
        AND aua_log.id <= #{batch_upper_boundary}
        AND#{' '}
    SQL
    default_lower_bounds = [log_id_bookmark] * 7
    root_account_conditions = Account.root_accounts.active.pluck(:id).map do |root_account_id|
      lower_ra_boundary = root_account_max_ids_map.fetch(root_account_id.to_s, default_lower_bounds)[pg_partition_index]
      # in case we have a case where we only PARTIALLY process the job
      # and don't have the opportunity to zero out the temporary ripcord
      # state, we still need to respect iterator advances in the global state.
      # That means we need to also bound each RA group by the max value seen IN THAT ROOT ACCOUNT.
      <<~ROOT_ACCOUNT_SUBCLAUSE
        ( aua.root_account_id = #{root_account_id} AND
          aua_log.id > #{lower_ra_boundary} )
      ROOT_ACCOUNT_SUBCLAUSE
    end.join(" OR ")
    query_string = """
     #{query_prefix} ( #{root_account_conditions} )
     GROUP BY aua_log.asset_user_access_id
    """
    query_string
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

    <<~SQL.squish
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
