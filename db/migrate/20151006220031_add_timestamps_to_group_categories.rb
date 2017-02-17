class AddTimestampsToGroupCategories < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    change_table(:group_categories) do |t|
      t.timestamps null: true
    end
  end
end
