class AddAssignmentPostColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :assignments, :post_to_sis, :boolean
    add_column :assignments, :integration_id, :string

    # We used to add an index on integration_id here, but decided not
    # to add it at all after it'd already been migrated in some envs
  end

  def self.down
    if index_exists?(:assignments, :integration_id)
      remove_index :assignments, :integration_id
    end

    remove_column :assignments, :post_to_sis
    remove_column :assignments, :integration_id
  end
end
