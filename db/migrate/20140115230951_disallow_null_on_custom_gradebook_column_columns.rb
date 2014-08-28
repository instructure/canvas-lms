class DisallowNullOnCustomGradebookColumnColumns < ActiveRecord::Migration
  tag :predeploy

  def self.allow_null(frd)
    if %w{MySQL Mysql2}.include?(connection.adapter_name)
      mysql = true
      remove_foreign_key :custom_gradebook_columns, :courses
    end

    %w(position workflow_state course_id).each { |col|
      change_column_null :custom_gradebook_columns, col, frd
    }

    if mysql
      add_foreign_key :custom_gradebook_columns, :courses
      remove_foreign_key :custom_gradebook_column_data, :users
      remove_foreign_key :custom_gradebook_column_data, :custom_gradebook_columns
    end

    %w(content user_id custom_gradebook_column_id).each { |col|
      change_column_null :custom_gradebook_column_data, col, frd
    }

    if mysql
      add_foreign_key :custom_gradebook_column_data, :users
      add_foreign_key :custom_gradebook_column_data, :custom_gradebook_columns
    end
  end

  def self.up
    allow_null(false)
  end

  def self.down
    allow_null(true)
  end
end
