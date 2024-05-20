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
    log_entry.save_without_transaction(touch: false)
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
      temp_root_account_max_log_ids: {}
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
      return log_message("PluginSetting configured OFF, aborting")
    end

    caught_up = postgres_compact
    # it's ok if we didn't complete, we time the job out so that
    # for things that need to move or hold jobs they don't have to
    # wait forever.  If we completed compaction, though, just finish.
    AssetUserAccessLog.reschedule! unless caught_up
  end

  # If we're using postgres as the transport layer
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
    unless yesterday_model.take(1).empty?
      yesterday_completed = compact_partition(yesterday_ts)
      ps.reload
      compaction_state = metadatum_payload
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
          GuardRail.activate(:deploy) do
            yesterday_model.connection.truncate(yesterday_model.table_name)
          end
          compaction_state[:max_log_ids][yesterday_ts.wday] = 0
          update_metadatum(compaction_state)
        end
      end
      return false unless yesterday_completed
    end
    compact_partition(ts)
    # it's ok if we didn't complete, we time the job out so that
    # for things that need to move or hold jobs they don't have to
    # wait forever.  If we completed compaction, though, just finish.
  end

  def self.reschedule!
    AssetUserAccessLog.delay(strand: strand_name).compact
  end

  def self.strand_name
    "AssetUserAccessLog.compact:#{Shard.current.database_server.id}"
  end

  LOG_BATCH_SIZE = 10_000
  MAX_COMPACTION_TIME = 5.minutes

  # slow down throughput and without holding the jobs, by trading off throughput
  # for latency
  INTRA_BATCH_PAUSE = 2.seconds

  # TODO: These are postgres partitions, not pulsar topic partitions.
  # Once we are doing this log-compaction operation completely via pulsar, we no longer
  # need this implmentation and can remove it.
  def self.compact_partition(ts)
    partition_model = log_model(ts)
    compaction_start = Time.now.utc

    # fetch from the canvas metadatum compaction state the last compacted log id.  This lets us
    # resume log compaction past the records we've already processed, but without
    # having to delete records as we go (which would churn write IO), leaving the log cleanup
    # to the truncation operation that occurs after finally processing "yesterdays" partition.
    # We'd expect them to usually be 0 because we reset the value after truncating the partition
    # (defends against sequences being reset to the "highest" record in a table and then
    # deciding we already chomped these logs).
    compaction_state = metadatum_payload

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
        log_message("processing #{log_id_bookmark} from #{partition_upper_bound}")
        batch_upper_boundary = log_id_bookmark + LOG_BATCH_SIZE
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
        if log_segment_aggregation.to_a.empty?
          # no records found in this range, we must be paging through an open segment.
          # If we actually have a jump in sequences, there will
          # be more records greater than the batch, so we will choose
          # the minimum ID greater than the current batch top, because it's safe
          # to advance to that point even under replication lag.
          next_id = partition_model.where("id > ?", log_id_bookmark).minimum(:id)
          if use_pulsar_ripcord_iterators
            # In this case, we actually are advancing because we couldn't find any records
            # we hadn't processed
            # yet in one of the root account partitions.  We need to advance all the way
            # to the top of the batch because we can safely assume replication lag
            # is not in play and that we need to fast forward to the place where
            # we haven't compacted records yet.
            next_id = partition_model.where("id > ?", batch_upper_boundary).minimum(:id)
          end
          return false unless next_id.present? # can't find any more records for now, do not advance

          # make sure we actually process the next record by offsetting
          # to just under it's ID
          new_bookmark_id = next_id - 1
          GuardRail.activate(:primary) do
            compaction_state[:max_log_ids][ts.wday] = new_bookmark_id
            update_metadatum(compaction_state)
          end
          log_id_bookmark = new_bookmark_id
        else
          # we found records in this segment, we need to both
          # compute the new iterator position (it's just the max
          # of all ids because we constrained the aggregation to a range of ids,
          # taking the full set of logs in that range)
          update_query = compaction_sql(log_segment_aggregation)
          new_iterator_pos = log_segment_aggregation.pluck("max_id").max
          GuardRail.activate(:primary) do
            partition_model.transaction do
              log_message("batch updating (sometimes these queries don't get logged)...")
              partition_model.connection.with_max_update_limit(LOG_BATCH_SIZE) do
                partition_model.connection.execute(update_query)
              end
              log_message("...batch update complete")
              # Here we want to write the iteration state into the database
              # so that we don't double count rows later.  The next time the job
              # runs it can pick up at this point and only count rows that haven't yet been counted.
              compaction_state[:max_log_ids][ts.wday] = new_iterator_pos
              update_metadatum(compaction_state)
            end
          end
          log_id_bookmark = new_iterator_pos
          sleep(INTRA_BATCH_PAUSE)
        end
        batch_timestamp = Time.now.utc
        if (batch_timestamp - compaction_start) > MAX_COMPACTION_TIME
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
      update_metadatum(compaction_state)
    end
    true # to indicate we didn't bail
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
    <<~SQL.squish
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
    query_prefix = <<~SQL.squish
      SELECT aua_log.asset_user_access_id AS aua_id,
        COUNT(aua_log.asset_user_access_id) AS view_count,
        MAX(aua_log.created_at) AS max_updated_at,
        MAX(aua_log.id) AS max_id
      FROM #{partition_model.quoted_table_name} AS aua_log
      INNER JOIN #{AssetUserAccess.quoted_table_name} AS aua
        ON aua_log.asset_user_access_id = aua.id
      WHERE aua_log.id > #{log_id_bookmark}
        AND aua_log.id <= #{batch_upper_boundary}
        AND#{" "}
    SQL
    default_lower_bounds = [log_id_bookmark] * 7
    root_account_conditions = Account.root_accounts.active.pluck(:id).map do |root_account_id|
      lower_ra_boundary = root_account_max_ids_map.fetch(root_account_id.to_s, default_lower_bounds)[pg_partition_index]
      # in case we have a case where we only PARTIALLY process the job
      # and don't have the opportunity to zero out the temporary ripcord
      # state, we still need to respect iterator advances in the global state.
      # That means we need to also bound each RA group by the max value seen IN THAT ROOT ACCOUNT.
      <<~SQL.squish
        ( aua.root_account_id = #{root_account_id} AND
          aua_log.id > #{lower_ra_boundary} )
      SQL
    end.join(" OR ")
    <<~SQL.squish
      #{query_prefix} ( #{root_account_conditions} )
      GROUP BY aua_log.asset_user_access_id
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
      max_updated_at = row["max_updated_at"]
      max_updated_at = max_updated_at.to_fs(:db)
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
