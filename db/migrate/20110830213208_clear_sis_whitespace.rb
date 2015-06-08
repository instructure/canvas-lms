class ClearSisWhitespace < ActiveRecord::Migration
  
  def self.clear(table, *cols)
    cols = cols.map{|col|" #{col} = TRIM(#{col})"}.join(',')
    execute("UPDATE #{table} SET #{cols}")
  end
  
  def self.up
    clear(:pseudonyms, :unique_id, :sis_source_id, :sis_user_id)
    clear(:users, :name, :sis_name)
    clear(:enrollment_terms, :name, :sis_name, :sis_source_id)
    clear(:course_sections, :name, :sis_name, :sis_source_id)
    clear(:groups, :name, :sis_name, :sis_source_id)
    clear(:courses, :name, :sis_name, :sis_source_id, :course_code, :sis_course_code)
    clear(:abstract_courses, :name, :sis_name, :sis_source_id, :short_name, :sis_course_code)
    clear(:course_sections, :name, :sis_name, :sis_source_id)
    clear(:enrollments, :sis_source_id)
    clear(:accounts, :name, :sis_name, :sis_source_id)
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
