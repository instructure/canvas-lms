class DisallowNullOnDataExportColumns < ActiveRecord::Migration
  tag :predeploy

  def self.up
    if %w{MySQL Mysql2}.include?(connection.adapter_name)
      mysql = true
      remove_foreign_key :data_exports, :users
    end

    %w(user_id context_id context_type workflow_state).each do |c|
      change_column_null :data_exports, c, false
    end

    add_foreign_key :data_exports, :users if mysql
  end

  def self.down
    if %w{MySQL Mysql2}.include?(connection.adapter_name)
      mysql = true
      remove_foreign_key :data_exports, :users
    end

    %w(user_id context_id context_type workflow_state).each do |c|
      change_column_null :data_exports, c, true
    end

    add_foreign_key :data_exports, :users if mysql
  end
end
