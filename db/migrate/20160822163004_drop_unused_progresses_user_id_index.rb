class DropUnusedProgressesUserIdIndex < ActiveRecord::Migration[4.2]
 tag :postdeploy

  def change
    remove_index :progresses, :user_id
  end
end
