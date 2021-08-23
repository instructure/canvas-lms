# frozen_string_literal: true

class AddActiveContentTagsIndex < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :content_tags, [:context_id, :context_type, :content_type], where: "workflow_state = 'active'",
      name: "index_content_tags_on_context_when_active", algorithm: :concurrently
  end
end
