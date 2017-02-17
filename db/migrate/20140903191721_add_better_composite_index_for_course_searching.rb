class AddBetterCompositeIndexForCourseSearching < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :predeploy

  def self.up
    if is_postgres? && (schema = connection.extension_installed?(:pg_trgm))
      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      execute("CREATE INDEX#{concurrently} index_trgm_courses_composite_search ON
        #{Course.quoted_table_name} USING gist((
          coalesce(lower(name), '') || ' ' ||
          coalesce(lower(sis_source_id), '') || ' ' ||
          coalesce(lower(course_code), '')
        ) #{schema}.gist_trgm_ops)")
    end
  end

  def self.down
    remove_index :courses, name: 'index_trgm_courses_composite_search'
  end
end
