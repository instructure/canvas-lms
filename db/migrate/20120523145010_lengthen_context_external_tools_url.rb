class LengthenContextExternalToolsUrl < ActiveRecord::Migration
  tag :predeploy

  def self.up
    change_column :context_external_tools, :url, :string, :limit => 4.kilobytes
  end

  def self.down
    change_column :context_external_tools, :url, :string, :limit => 255
  end
end
