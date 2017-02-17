class AddTimestampsToUserObserver < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    change_table :user_observers do |t|
      t.timestamps null: true
    end
  end
end
