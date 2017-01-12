class AddTimestampsToUserObserver < ActiveRecord::Migration
  tag :predeploy

  def change
    change_table :user_observers, &:timestamps
  end
end
