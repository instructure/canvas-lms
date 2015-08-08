class DropAttachmentAndArtifactTypeFromEportfolioEntries < ActiveRecord::Migration
  tag :postdeploy

  def up
    remove_column :eportfolio_entries, :attachment_id
    remove_column :eportfolio_entries, :artifact_type
  end

  def down
    add_column :eportfolio_entries, :attachment_id, :integer, limit: 8
    add_column :eportfolio_entries, :artifact_type, :integer
  end
end
