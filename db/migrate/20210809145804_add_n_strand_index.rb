# frozen_string_literal: true

class AddNStrandIndex < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  tag :predeploy

  def connection
    Delayed::Job.connection
  end

  def change
    add_index :delayed_jobs, [:strand, :next_in_strand, :id],
              name: 'n_strand_index',
              where: 'strand IS NOT NULL',
              algorithm: :concurrently,
              if_not_exists: true
  end
end
