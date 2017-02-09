class AddIndexToChildSubscriptions < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def change
    add_index :master_courses_child_subscriptions, :child_course_id, :name => "index_child_subscriptions_on_child_course_id"
  end
end
