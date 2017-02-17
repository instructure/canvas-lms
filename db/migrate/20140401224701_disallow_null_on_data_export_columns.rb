class DisallowNullOnDataExportColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    %w(user_id context_id context_type workflow_state).each do |c|
      change_column_null :data_exports, c, false
    end
  end

  def self.down
    %w(user_id context_id context_type workflow_state).each do |c|
      change_column_null :data_exports, c, true
    end
  end
end
