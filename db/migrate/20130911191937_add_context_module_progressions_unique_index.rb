class AddContextModuleProgressionsUniqueIndex < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    ContextModuleProgression.
        select([:user_id, :context_module_id]).
        group(:user_id, :context_module_id).
        includes(:context_module, :user).
        where("user_id IS NOT NULL AND context_module_id IS NOT NULL").
        having("COUNT(*) > 1").find_each do |cmp|
      scope = ContextModuleProgression.
          where(user_id: cmp.user_id, context_module_id: cmp.context_module_id)
      keeper = scope.order("updated_at DESC").first
      scope.where("id<>?", keeper).delete_all
    end

    add_index :context_module_progressions, [:user_id, :context_module_id], unique: true, name: 'index_cmp_on_user_id_and_module_id', algorithm: :concurrently
    remove_index :context_module_progressions, name: 'u_id_module_id'
  end

  def self.down
    remove_index :context_module_progressions, name: 'index_cmp_on_user_id_and_module_id'
    add_index :context_module_progressions, [:user_id, :context_module_id], name: 'u_id_module_id', algorithm: :concurrently
  end
end
