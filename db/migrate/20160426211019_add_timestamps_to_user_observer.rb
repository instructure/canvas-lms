class AddTimestampsToUserObserver < ActiveRecord::Migration
  tag :predeploy

  def change
    change_table :user_observers do |t|
      t.timestamps null: true
    end
  end
end
