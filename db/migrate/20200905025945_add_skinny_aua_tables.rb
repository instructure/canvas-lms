# frozen_string_literal: true

class AddSkinnyAuaTables < ActiveRecord::Migration[5.2]
  tag :predeploy

  def create_aua_log_partition(index)
    table_name = :"aua_logs_#{index}"
    create_table table_name do |t|
      t.bigint :asset_user_access_id, null: false
      t.datetime :created_at, null: false
    end
    # Intentionally not adding FK on asset_user_access_id as the records are transient
    # and we're trying to do as little work as possible on the insert to these
    # and can be thrown away if they don't match anything anyway as the log is compacted.
  end

  # one table for each day of week, they'll periodically
  # be compacted and truncated.  This prevents having to
  # create and drop true partitions at a high rate
  def up
    create_aua_log_partition("0")
    create_aua_log_partition("1")
    create_aua_log_partition("2")
    create_aua_log_partition("3")
    create_aua_log_partition("4")
    create_aua_log_partition("5")
    create_aua_log_partition("6")
  end

  def down
    drop_table(:aua_logs_0)
    drop_table(:aua_logs_1)
    drop_table(:aua_logs_2)
    drop_table(:aua_logs_3)
    drop_table(:aua_logs_4)
    drop_table(:aua_logs_5)
    drop_table(:aua_logs_6)
  end
end
