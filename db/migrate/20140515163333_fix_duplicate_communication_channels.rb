class FixDuplicateCommunicationChannels < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    CommunicationChannel.
        group(CommunicationChannel.by_path_condition("path"), :path_type, :user_id).
        select(["#{CommunicationChannel.by_path_condition("path")} AS path", :path_type, :user_id]).
        having("COUNT(*) > 1").find_each do |baddie|
      all = CommunicationChannel.where(user_id: baddie.user_id, path_type: baddie.path_type).
          by_path(baddie.path).order("CASE workflow_state WHEN 'active' THEN 0 WHEN 'unconfirmed' THEN 1 ELSE 2 END", :created_at).to_a
      keeper = all.shift
      all.each(&:destroy!)
    end

    if connection.adapter_name == 'PostgreSQL'
      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      execute("CREATE UNIQUE INDEX#{concurrently} index_communication_channels_on_user_id_and_path_and_path_type ON communication_channels (user_id, LOWER(path), path_type)")
    else
      add_index :communication_channels, [:user_id, :path, :path_type], unique: true
    end
  end
end
