class CreateOrders < ActiveRecord::Migration[4.2]
  tag :predeploy
  def change
    create_table :orders do |t|
      t.integer :user_id
      t.integer :course_id
      t.string :ip_address
      t.string :first_name
      t.string :last_name
      t.string :status
      t.string :authorization
      t.text :message
      t.text :params
      t.string :express_token
      t.string :express_player_id
      t.string :mid
      t.string :order_id
      t.float :txn_amount
      t.string :currency
      t.string :txn_id
      t.string :bank_txn_id
      t.string :resp_code
      t.string :resp_msg
      t.datetime :txn_date
      t.string :gateway_name
      t.string :bank_name
      t.string :payment_mode
      t.text :checksum_hash
      t.timestamps null: false
    end
  end
end
