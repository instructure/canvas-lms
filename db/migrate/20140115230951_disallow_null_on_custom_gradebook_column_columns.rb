class DisallowNullOnCustomGradebookColumnColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.allow_null(frd)
    %w(position workflow_state course_id).each { |col|
      change_column_null :custom_gradebook_columns, col, frd
    }

    %w(content user_id custom_gradebook_column_id).each { |col|
      change_column_null :custom_gradebook_column_data, col, frd
    }
  end

  def self.up
    allow_null(false)
  end

  def self.down
    allow_null(true)
  end
end
