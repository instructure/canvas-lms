class AddForceTokenReuseToDevKey < ActiveRecord::Migration[4.2]
   tag :predeploy

  def self.up
    add_column :developer_keys, :force_token_reuse, :boolean
  end

  def self.down
    remove_column :developer_keys, :force_token_reuse
  end

end
