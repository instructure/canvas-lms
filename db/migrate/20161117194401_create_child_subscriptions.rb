class CreateChildSubscriptions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :master_courses_child_subscriptions do |t|

      t.integer :master_template_id, limit: 8, null: false
      t.integer :child_course_id, limit: 8, null: false

      t.string :workflow_state, null: false

      # i'm thinking we can use this to keep track of which subscriptions are new
      # vs. which ones have been getting regular updates and we can use a selective copy for
      t.boolean :use_selective_copy, null: false, default: false

      t.timestamps null: false
    end

    add_foreign_key :master_courses_child_subscriptions, :master_courses_master_templates, column: "master_template_id"

    # we may have to drop this foreign key at some point for cross-shard subscriptions
    add_foreign_key :master_courses_child_subscriptions, :courses, column: "child_course_id"

    add_index :master_courses_child_subscriptions, :master_template_id
    add_index :master_courses_child_subscriptions, [:master_template_id, :child_course_id],
      :unique => true, :where => "workflow_state <> 'deleted'",
      :name => "index_mc_child_subscriptions_on_template_id_and_course_id"
  end
end
