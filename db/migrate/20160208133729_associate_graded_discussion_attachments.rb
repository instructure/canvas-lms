class AssociateGradedDiscussionAttachments < ActiveRecord::Migration
  tag :postdeploy

  def up
    DataFixup::AssociateGradedDiscussionAttachments.send_later_if_production(:run)
  end

  def down
  end
end
