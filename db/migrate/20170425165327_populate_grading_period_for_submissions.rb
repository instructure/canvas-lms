class PopulateGradingPeriodForSubmissions < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    DataFixup::InitializeSubmissionCachedDueDate.send_later_if_production_enqueue_args(
      :run,
      singleton: "DataFixup:InitializeSubmissionCachedDueDate:#{Shard.current.id}"
    )
  end
end
