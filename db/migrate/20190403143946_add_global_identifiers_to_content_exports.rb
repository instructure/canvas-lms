class AddGlobalIdentifiersToContentExports < ActiveRecord::Migration[5.1]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :content_exports, :global_identifiers, :boolean
    change_column_default(:content_exports, :global_identifiers, false)
    DataFixup::BackfillNulls.run(ContentExport, :global_identifiers, default_value: false)
    change_column_null(:content_exports, :global_identifiers, false)
  end

  def down
    remove_column :content_exports, :global_identifiers
  end
end
