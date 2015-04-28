class DropContextFromGradebookUploads < ActiveRecord::Migration
  tag :postdeploy

  def up
    # these are conditional because a previous (and later modified) migration may have removed them
    remove_column :gradebook_uploads, :context_type if column_exists?(:gradebook_uploads, :context_type)
    remove_column :gradebook_uploads, :context_id if column_exists?(:gradebook_uploads, :context_id)
  end

  def down
    add_column :gradebook_uploads, :context_type, :string
    add_column :gradebook_uploads, :context_id, :integer, limit: 8
  end
end
