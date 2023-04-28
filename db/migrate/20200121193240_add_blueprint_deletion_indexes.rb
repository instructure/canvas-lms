# frozen_string_literal: true

class AddBlueprintDeletionIndexes < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :attachments,
              %i[context_id context_type migration_id],
              opclass: { migration_id: :text_pattern_ops },
              where: "migration_id IS NOT NULL",
              algorithm: :concurrently,
              name: "index_attachments_on_context_and_migration_id_pattern_ops"
    add_index :master_courses_child_content_tags,
              [:child_subscription_id, :migration_id],
              opclass: { migration_id: :text_pattern_ops },
              algorithm: :concurrently,
              name: "index_mc_child_content_tags_on_sub_and_migration_id_pattern_ops"
  end
end
