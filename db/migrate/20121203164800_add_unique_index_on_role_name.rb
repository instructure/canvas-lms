class AddUniqueIndexOnRoleName < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    # this cleanup is probably a no-op, because nobody has created any Roles yet, but is here
    # for completeness' sake.
    # note 1: this migration will fail (intentionally) if multiple Roles in the same account have the
    #         same name and different base role types; that can't be cleaned up automatically
    #         (but should not happen because an existing validation prevents this case)
    # note 2: the extra subquery is necessary to avoid error 1093 on mysql
    Role.where("id NOT IN (SELECT * FROM (SELECT MAX(id) FROM roles GROUP BY account_id, name, base_role_type) x)").delete_all
    add_index :roles, [:account_id, :name], :unique => true, :name => "index_roles_unique_account_name"
  end

  def self.down
    remove_index :roles, :name => "index_roles_unique_account_name"
  end
end
