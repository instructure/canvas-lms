class UpdateInvalidRootAttachmentFilenames < ActiveRecord::Migration
  tag :postdeploy

  def up
    DataFixup::EnsureRootAttachmentFilename.send_later_if_production(:run)
  end

  def down
  end
end