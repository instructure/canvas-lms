# frozen_string_literal: true

class ChangeFailedJobsHandlerToText < ActiveRecord::Migration[5.1]
  tag :predeploy

  def connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def up
    change_column :failed_jobs, :handler, :text
  end

  def down
    change_column :failed_jobs, :handler, :string, :limit => 500.kilobytes
  end
end
