class ConvertStorageQuotasToBytes < ActiveRecord::Migration[4.2]
  tag :predeploy

  FIELDS_TO_FIX = [
    [ User, :storage_quota ],
    [ Account, :storage_quota ],
    [ Account, :default_storage_quota ],
    [ Course, :storage_quota ],
    [ Group, :storage_quota ],
  ]

  def self.up
    FIELDS_TO_FIX.each do |klass, field|
      change_column klass.table_name.to_s, field, :integer, :limit => 8
      update("UPDATE #{klass.quoted_table_name} SET #{field} = #{field} * 1024 * 1024 WHERE #{field} IS NOT NULL AND #{field} < 1024 * 1024")
    end
  end

  def self.down
    FIELDS_TO_FIX.each do |klass, field|
      change_column klass.table_name.to_s, field, :integer, :limit => 4
      update("UPDATE #{klass.quoted_table_name} SET #{field} = #{field} / 1024 * 1024 WHERE #{field} IS NOT NULL AND #{field} >= 1024 * 1024")
    end
  end
end
