class FixGroupsWithDuplicateWikiAndUuid < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    DataFixup::FixGroupsWithDuplicateWikiAndUuid.run

    # There are a very small number of groups with no uuid
    [Group, GroupMembership].each do |klass|
      klass.where(uuid: nil).find_each do |item|
        klass.where(id: item).update_all(
          uuid: CanvasSlug.generate_securish_uuid,
          updated_at: Time.now.utc
        )
      end
    end

    change_column_null :groups, :uuid, false
    change_column_null :group_memberships, :uuid, false

    add_index :groups, :uuid, unique: true, algorithm: :concurrently
    add_index :group_memberships, :uuid, unique: true, algorithm: :concurrently
  end

  def down
    change_column_null :groups, :uuid, true
    change_column_null :group_memberships, :uuid, true

    remove_index :groups, :uuid
    remove_index :group_memberships, :uuid
  end
end
