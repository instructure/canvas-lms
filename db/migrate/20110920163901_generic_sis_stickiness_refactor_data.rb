class GenericSisStickinessRefactorData < ActiveRecord::Migration

  def self.up
    execute <<-SQL
      UPDATE abstract_courses SET stuck_sis_fields =
          (CASE WHEN sis_name <> name THEN
            (CASE WHEN sis_course_code <> short_name THEN
              'name,short_name'
            ELSE
              'name'
            END)
          WHEN sis_course_code <> short_name THEN
            'short_name'
          ELSE
            NULL
          END);
    SQL
    execute <<-SQL
      UPDATE courses SET stuck_sis_fields =
          (CASE WHEN sis_name <> name THEN
            (CASE WHEN sis_course_code <> course_code THEN
              'name,course_code'
            ELSE
              'name'
            END)
          WHEN sis_course_code <> course_code THEN
            'course_code'
          ELSE
            NULL
          END);
    SQL
    execute <<-SQL
      UPDATE course_sections SET stuck_sis_fields =
          (CASE WHEN sis_name <> name THEN
            (CASE WHEN sticky_xlist THEN
              'course_id,name'
            ELSE
              'name'
            END)
          WHEN sticky_xlist THEN
            'course_id'
          ELSE
            NULL
          END);
    SQL
    execute("UPDATE accounts SET stuck_sis_fields = 'name' WHERE sis_name <> name;")
    execute("UPDATE groups SET stuck_sis_fields = 'name' WHERE sis_name <> name;")
    execute("UPDATE enrollment_terms SET stuck_sis_fields = 'name' WHERE sis_name <> name;")
    execute("UPDATE users SET stuck_sis_fields = 'name' WHERE sis_name <> name;")
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
