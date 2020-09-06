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
  ]

  def self.put_view(asset_user_access, timestamp: nil)
    # the "timestamp:" argument is useful for testing or backfill/replay
    # recovery scenarios, but in
    # production generally isn't expected to be used because the log
    # is being written at the time of the view.
    # timestamp is therefor usually "nil", and becomes "now"
    # below when inferring which table to talk to.
    ts = timestamp || Time.now.utc
    log_values = { asset_user_access_id: asset_user_access.id, created_at: ts }
    log_model(ts).create!(log_values)
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

  # This is the job component, taking the inserts that have
  # accumulated and writing them to the AUA records they actually
  # belong to with as few updates as possible.  This should help control
  #  write throughput on the DB because in many cases people "view" the same
  # asset repeatedly (refreshing over and over for example), so we can condense
  # that to a single update.
  # We also can apply friction to the job (via strand holding or increased sleep timers)
  # to defer the writes for longer by slowing the processing down, which allows us to take
  # fewer writes at peak and use spare I/O capacity later in the day if necessary to catch up.
  def self.compact
    ts = Time.now.utc
    yesterday_ts = ts - 1.day
    yesterday_model = log_model(yesterday_ts)
    if yesterday_model.take(1).size > 0
      yesterday_completed = compact_partition(yesterday_ts)
      ps = plugin_setting.reload
      if yesterday_completed && ps.settings[:max_log_ids][yesterday_ts.wday] >= yesterday_model.maximum(:id)
        # we have now compacted all the writes from the previous day.
        # since the timestamp (now) is into the NEXT utc day, no further
        # writes can happen to yesterdays partition, and we can truncate it,
        # and reset our iterator tracking for that day (this is important because
        # in some cases like in specific restoration scenarios sequences can be
        # "reset" by looking for the max id value in a table and making it bigger than that.
        #  Tracking iterator state indefinitely could result in missing writes if a truncated
        # table gets it's iterator reset).
        Shackles.activate(:deploy) do
          yesterday_model.connection.truncate(yesterday_model.table_name)
        end
        PluginSetting.suspend_callbacks(:clear_cache) do
          ps.settings[:max_log_ids][yesterday_ts.wday] = 0
          ps.save
        end
      end
      return AssetUserAccessLog.reschedule! unless yesterday_completed
    end
    today_completed = compact_partition(ts)
    # it's ok if we didn't complete, we time the job out so that
    # for things that need to move or hold jobs they don't have to
    # wait forever.  If we completed compaction, though, just finish.
    AssetUserAccessLog.reschedule! unless today_completed
  end

  def self.reschedule!
    AssetUserAccessLog.send_later_enqueue_args(:compact, { strand: strand_name })
  end

  def self.strand_name
    "AssetUserAccessLog.compact:#{Shard.current.database_server.id}"
  end

  def self.compact_partition(ts)
    partition_model = log_model(ts)
    log_batch_size = Setting.get("aua_log_batch_size", "10000").to_i
    max_compaction_time = Setting.get("aua_compaction_time_limit_in_minutes", "5").to_i
    compaction_start = Time.now.utc
    Shackles.activate(:slave) do
      # select the boundaries of the log segment we're going to iterate.
      # we may still _process_ records bigger than this as part of a single write,
      # but will stop loading new batches to pluck AUA ids from when we hit the maximum.
      # this is just to avoid a single job never finishing because it's always processing
      # "just a few more"
      partition_upper_bound = partition_model.maximum(:id)
      partition_lower_bound = partition_model.minimum(:id)
      # fetch from the plugin setting the last compacted log id.  This lets us
      # resume log compaction past the records we've already processed, but without
      # having to delete records as we go (which would churn write IO), leaving the log cleanup
      # to the truncation operation that occurs after finally processing "yesterdays" partition.
      # We'd expect them to usually be 0 because we reset the value after truncating the partition
      # (defends against sequences being reset to the "highest" record in a table and then
      # deciding we already chomped these logs).
      ps = plugin_setting
      max_log_ids = ps.reload.settings.fetch(:max_log_ids, [0,0,0,0,0,0,0])
      log_id_bookmark = [(partition_lower_bound-1), (max_log_ids[ts.wday] || 0)].max
      while log_id_bookmark < partition_upper_bound
        Rails.logger.info("[AUA_LOG_COMPACTION:#{Shard.current.id}] - processing #{log_id_bookmark} from #{partition_upper_bound}")
        # maybe we won't need this, but if we need to slow down throughput and don't want to hold
        # the jobs, increasing this setting value could tradeoff throughput for latency
        # slowly.  We load in INSIDE the loop so that SIGHUPS can get recognized
        # more quickly (otherwise we'd have to wait for a job to die or be killed
        # to respond to updated settings)
        intra_batch_pause = Setting.get("aua_log_compaction_batch_pause", "0.0").to_f
        batch_upper_boundary = log_id_bookmark + log_batch_size
        has_compactable_data = partition_model.where("id > ?", log_id_bookmark).take(1)
        agg_sql = aggregation_query(partition_model, log_id_bookmark, batch_upper_boundary)
        log_segment_aggregation = partition_model.connection.execute(agg_sql)
        if log_segment_aggregation.to_a.size > 0
          # we found records in this segment, we need to both
          # compute the new iterator position (it's just the max
          # of all ids because we constrained the aggregation to a range of ids,
          # taking the full set of logs in that range)
          update_query = compaction_sql(log_segment_aggregation)
          new_iterator_pos = log_segment_aggregation.map{|r| r["max_id"]}.max
          Shackles.activate(:master) do
            partition_model.connection.execute(update_query)
          end
          # Here we want to write the iteration state onto the plugin setting
          # so that we don't double count rows later.  The next time the job
          # runs it can pick up at this point and only count rows that haven't yet been counted.
          ps.reload
          # also, no need to clear the cache, these are LOCAL
          # plugin settings, so let's not beat up consul
          PluginSetting.suspend_callbacks(:clear_cache) do
            ps.settings[:max_log_ids] ||= [0,0,0,0,0,0,0] # (just in case...)
            ps.settings[:max_log_ids][ts.wday] = new_iterator_pos
            ps.save
          end
          log_id_bookmark = new_iterator_pos
          sleep(intra_batch_pause) if intra_batch_pause > 0.0
        else
          # no records found in this range, we must be paging through an open segment
          # just keep going until the iterator catches up to real records.
          PluginSetting.suspend_callbacks(:clear_cache) do
            ps.reload.settings[:max_log_ids][ts.wday] = batch_upper_boundary
            ps.save
          end
          # we don't ever want to set the bookmark PAST the partition we expected
          # to consume
          log_id_bookmark = [batch_upper_boundary, partition_upper_bound].min
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
    values_list = aggregation_results.map{|row| "(#{row["aua_id"]}, #{row["view_count"]}, '#{row["max_updated_at"]}')" }.join(", ")
    update_query = <<~SQL
      UPDATE #{AssetUserAccess.quoted_table_name} AS aua
      SET view_score = COALESCE(aua.view_score, 0) + log_segment.view_count,
        updated_at = GREATEST(aua.updated_at, TO_TIMESTAMP(log_segment.max_updated_at, 'YYYY-MM-DD HH24:MI:SS.US')),
        last_access = GREATEST(aua.last_access, TO_TIMESTAMP(log_segment.max_updated_at, 'YYYY-MM-DD HH24:MI:SS.US'))
      FROM ( VALUES #{values_list} ) AS log_segment(aua_id, view_count, max_updated_at)
      WHERE aua.id=log_segment.aua_id
    SQL
  end
end
