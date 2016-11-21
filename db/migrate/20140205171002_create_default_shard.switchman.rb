# This migration comes from switchman (originally 20130328224244)
class CreateDefaultShard < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    unless Switchman::Shard.default.is_a?(Switchman::Shard)
      Switchman::Shard.reset_column_information
      Switchman::Shard.create!(:default => true)
      Switchman::Shard.default(true)
    end
  end
end
