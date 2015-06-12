class AddBetterCompositeIndexForCourseSearching < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :predeploy

  def self.up
    if is_postgres? && has_postgres_proc?('show_trgm')
      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      execute("CREATE INDEX#{concurrently} index_trgm_courses_composite_search ON
        courses USING gist((
          coalesce(lower(name), '') || ' ' ||
          coalesce(lower(sis_source_id), '') || ' ' ||
          coalesce(lower(course_code), '')
        ) gist_trgm_ops)")
    end
  end

  def self.down
    remove_index :courses, name: 'index_trgm_courses_composite_search'
  end
end
