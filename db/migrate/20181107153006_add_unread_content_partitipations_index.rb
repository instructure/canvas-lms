class AddUnreadContentPartitipationsIndex < ActiveRecord::Migration[5.1]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :content_participations, :user_id,
      name: "index_content_participations_on_user_id_unread",
      where: "workflow_state = 'unread'",
      algorithm: :concurrently
  end
end
