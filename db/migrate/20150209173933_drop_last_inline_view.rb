class DropLastInlineView < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    remove_column :attachments, :last_inline_view
  end

  def down
    add_column :attachments, :last_inline_view, :datetime
  end
end
