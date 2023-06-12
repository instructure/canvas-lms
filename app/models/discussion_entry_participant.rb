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

class DiscussionEntryParticipant < ActiveRecord::Base
  include Workflow

  belongs_to :discussion_entry
  belongs_to :user

  before_create :set_root_account_id

  validates :discussion_entry_id, :user_id, :workflow_state, presence: true
  validate :prevent_creates

  validates :report_type, inclusion: { in: %w[inappropriate offensive other],
                                       message: -> { t("%{value} is not valid") } }

  def prevent_creates
    if new_record?
      # e.g. DiscussionEntryParticipant.upsert_for_entries(entry, user, new_state: 'read')
      errors.add(:base, "Regular creation is disabled on DiscussionEntryParticipant - use upsert_for_entries")
    end
  end

  def self.read_entry_ids(entry_ids, user)
    where(user_id: user, discussion_entry_id: entry_ids, workflow_state: "read")
      .pluck(:discussion_entry_id)
  end

  def self.forced_read_state_entry_ids(entry_ids, user)
    where(user_id: user, discussion_entry_id: entry_ids, forced_read_state: true)
      .pluck(:discussion_entry_id)
  end

  def self.entry_ratings(entry_ids, user)
    ratings = where(user_id: user, discussion_entry_id: entry_ids).where.not(rating: nil)
    ratings.to_h { |x| [x.discussion_entry_id, x.rating] }
  end

  def self.not_null_column_object(column: nil, entry: nil, user: nil)
    entry_participant = new(discussion_entry: entry, user:)
    error_message = "Null value in column '#{column}' violates not-null constraint"
    entry_participant.errors.add(column, error_message)
    entry_participant
  end

  # creates or updates entry_participants returning ids if changed.
  # small amount of validation to ensure we have the required attributes.
  # build an insert statement.
  # build an update statement.
  # execute.
  # takes an entry, user, and accepts batch, new_state, forced, and rating.
  # runs for the entry when a batch is not provided.
  # when run for a batch, still uses an entry, mainly to pull root_account_id.
  # returns the ids of records changed or inserted, or a
  # DiscussionEntryParticipant object with errors for backwards compatability to
  # the previous method.
  def self.upsert_for_entries(entry_or_topic, user, batch: nil, new_state: nil, forced: nil, rating: nil, report_type: nil)
    return nil if entry_or_topic.nil? || user.nil?

    batch ||= [entry_or_topic]
    entry_or_topic.shard.activate do
      raise(ArgumentError) if batch.count > 1_000
      return not_null_column_object(column: :entry, entry: entry_or_topic, user:) unless entry_or_topic
      return not_null_column_object(column: :user, entry: entry_or_topic, user:) unless user

      insert_columns = %w[discussion_entry_id user_id root_account_id workflow_state read_at]
      update_columns = []
      update_values = []

      # need to still set to false when passed as false, so check for not nil.
      unless forced.nil?
        update_columns << "forced_read_state"
        update_values << connection.quote(forced)
      end

      # need to still set to 0 when passed as 0, so check for not nil.
      unless rating.nil?
        update_columns << "rating"
        update_values << connection.quote(rating)
      end

      unless report_type.nil?
        unless %w[inappropriate offensive other].include? report_type
          raise(ArgumentError)
        end

        update_columns << "report_type"
        update_values << connection.quote(report_type)
      end

      insert_columns += update_columns
      # workflow_state is a non null column and is required for the insert side.
      # The update side does not require workflow_state. Already exists in the
      # non-null column
      default_state = new_state || "unread"
      insert_values = batch.map do |batch_entry|
        row_values(batch_entry, user.id, entry_or_topic.root_account_id, default_state, update_values)
      end

      # takes ruby arrays of values into sql arrays ready for insert.
      # [[entry_id, user_id, root_account_id, "'read'"],[...]] =>
      # ["(entry_id,user_id,root_account_id,'read'),(...)"]
      insert_rows = insert_values.map { |row| "(#{row.join(",")})" }

      # new_state needs to be handled after the insert_values because we always
      # have workflow_state in the insert, but should only be on the update side
      # if the value is provided. We don't want to accidentally mark an entry as
      # 'unread', but also don't want to include 'workflow_state' two times in the
      # insert.
      if new_state
        update_columns << "workflow_state"
        update_values << connection.quote(new_state)

        read_at_datetime = (new_state&.to_s == "read") ? Time.now : nil
        update_columns << "read_at"
        update_values << connection.quote(read_at_datetime)
      end

      # if there are no values in the update_columns, there is no point to
      # creating the record. A non-existent record is treated as an unread record.
      return not_null_column_object(column: :workflow_state, entry: entry_or_topic, user:) if update_columns.empty?

      # takes two ruby arrays and makes into a sql update statement.
      # ['workflow_state', 'forced_read_state'], ["'read'", true] =>
      # "workflow_state='read',forced_read_state=true"
      update_statement = update_columns.zip(update_values).map { |a| a.join("=") }.join(",")
      # takes the update_arrays and also creates a where clause so we don't update
      # records that wouldn't end up changing.
      # ['workflow_state', 'forced_read_state'], ["'read'", true] =>
      # "(discussion_entry_participants.workflow_state,discussion_entry_participants.forced_read_state)
      #   IS DISTINCT FROM ('read',true)
      where_clause = "(#{quoted_table_name}.#{update_columns.join(",#{quoted_table_name}.")})
                     IS DISTINCT FROM (#{update_values.join(",")})"

      # actual sql query combined into a statement.
      upsert_sql = <<~SQL.squish
          INSERT INTO #{quoted_table_name}
                      (#{insert_columns.join(",")})
               VALUES #{insert_rows.join(",")}
          ON CONFLICT (discussion_entry_id,user_id)
        DO UPDATE SET #{update_statement}
                WHERE #{where_clause}
      SQL

      # run the query.
      connection.exec_insert(upsert_sql)
    end
  end

  def self.row_values(batch_entry, user_id, root_account_id, default_state, update_values)
    read_at_datetime = (default_state&.to_s == "read") ? Time.now : nil
    [
      connection.quote(batch_entry.is_a?(ActiveRecord::Base) ? batch_entry.id_for_database : batch_entry),
      connection.quote(user_id),
      connection.quote(root_account_id),
      connection.quote(default_state),
      connection.quote(read_at_datetime),
    ] + update_values
  end

  def self.upsert_for_root_entry_and_descendants(root_entry, user, new_state: nil, forced: nil, rating: nil)
    DiscussionEntry.where(root_entry:)
                   .or(DiscussionEntry.where(id: root_entry))
                   .active.find_ids_in_batches do |batch|
      upsert_for_entries(root_entry, user, batch:, new_state:, forced:, rating:)
    end
  end

  def self.upsert_for_topic(topic, user, new_state: nil, forced: nil, rating: nil)
    topic.discussion_entries.active.find_ids_in_batches do |batch|
      upsert_for_entries(topic, user, batch:, new_state:, forced:, rating:)
    end
  end

  workflow do
    state :unread
    state :read
  end

  scope :read, -> { where(workflow_state: "read") }
  scope :existing_participants, lambda { |user, entry_id|
    select([:id, :discussion_entry_id])
      .where(user_id: user, discussion_entry_id: entry_id)
  }

  def set_root_account_id
    self.root_account_id = discussion_entry.root_account_id
  end
end
