class CreatePaytmOrders < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def change
    create_table :paytm_orders do |t|
      t.integer :user_id
      t.integer :course_id
      t.string :mid
      t.string :order_id
      t.float :txn_amount
      t.string :currency
      t.string :txn_id
      t.string :bank_txn_id
      t.string :status
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
