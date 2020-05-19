class CascasdeUniqueAuditorIndexesToAuthPartitions < CanvasPartman::Migration
  disable_ddl_transaction!
  tag :postdeploy
  self.base_class = Auditors::ActiveRecord::AuthenticationRecord

  def up
    with_each_partition do |partition|
      unless index_exists?(partition, :uuid, unique: true)
        rename_index partition, "#{partition}_uuid_idx", "#{partition}_nonunique_uuid_idx"
        add_index partition, :uuid, unique: true, algorithm: :concurrently
        remove_index partition, name: "#{partition}_nonunique_uuid_idx"
      end
    end
  end

  def down
    with_each_partition do |partition|
      unless index_exists?(partition, :uuid, unique: false)
        rename_index partition, "#{partition}_uuid_idx", "#{partition}_unique_uuid_idx"
        add_index partition, :uuid, algorithm: :concurrently
        remove_index partition, name: "#{partition}_unique_uuid_idx"
      end
    end
  end
end
