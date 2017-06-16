class CreateOrders < ActiveRecord::Migration[4.2]
  tag :predeploy
  def change
    create_table :orders do |t|
      t.integer :user_id
      t.integer :course_id
      t.string :ip_address
      t.string :first_name
      t.string :last_name
      t.float :amount
      t.boolean :status
      t.string :authorization
      t.text :message
      t.text :params
      t.string :express_token
      t.string :express_player_id
      t.timestamps null: false
    end
  end
end
