class AddMoreGistIndexes < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :predeploy

  def self.up
    if is_postgres? && has_postgres_proc?('show_trgm')
      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      execute("CREATE INDEX#{concurrently} index_trgm_users_short_name ON users USING gist(LOWER(short_name) gist_trgm_ops)")
      execute("CREATE INDEX#{concurrently} index_trgm_courses_name ON courses USING gist(LOWER(name) gist_trgm_ops)")
      execute("CREATE INDEX#{concurrently} index_trgm_courses_course_code ON courses USING gist(LOWER(course_code) gist_trgm_ops)")
      execute("CREATE INDEX#{concurrently} index_trgm_courses_sis_source_id ON courses USING gist(LOWER(sis_source_id) gist_trgm_ops)")
    end
  end

  def self.down
    remove_index :users, name: 'index_trgm_users_short_name'
    remove_index :courses, name: 'index_trgm_courses_name'
    remove_index :courses, name: 'index_trgm_courses_course_code'
    remove_index :courses, name: 'index_trgm_courses_sis_source_id'
  end
end
