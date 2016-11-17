class RemoveContextModuleAssociationIdFromContentTags < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    remove_column :content_tags, :context_module_association_id
  end

  def self.down
    add_column :content_tags, :context_module_association_id, :integer, :limit => 8
  end
end
