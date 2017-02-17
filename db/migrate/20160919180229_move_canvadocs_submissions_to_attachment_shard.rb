class MoveCanvadocsSubmissionsToAttachmentShard < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    DataFixup::MoveCanvadocsSubmissionsToAttachmentShard.send_later_if_production(:run)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
