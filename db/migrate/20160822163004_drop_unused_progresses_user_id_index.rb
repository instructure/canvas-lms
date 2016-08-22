class DropUnusedProgressesUserIdIndex < ActiveRecord::Migration
 tag :postdeploy

  def change
    remove_index :progresses, :user_id
  end
end
