class GenericSisStickinessRefactor < ActiveRecord::Migration

  def self.up
    add_column :abstract_courses, :stuck_sis_fields, :text
    add_column :accounts, :stuck_sis_fields, :text
    add_column :courses, :stuck_sis_fields, :text
    add_column :groups, :stuck_sis_fields, :text
    add_column :course_sections, :stuck_sis_fields, :text
    add_column :enrollment_terms, :stuck_sis_fields, :text
    add_column :users, :stuck_sis_fields, :text
    execute <<-SQL
      UPDATE abstract_courses SET stuck_sis_fields =
          (CASE WHEN sis_name = name THEN
            (CASE WHEN sis_course_code = short_name THEN
              'name,short_name'
            ELSE
              'name'
            END)
          WHEN sis_course_code = short_name THEN
            'short_name'
          ELSE
            NULL
          END);
    SQL
    execute <<-SQL
      UPDATE courses SET stuck_sis_fields =
          (CASE WHEN sis_name = name THEN
            (CASE WHEN sis_course_code = course_code THEN
              'name,course_code'
            ELSE
              'name'
            END)
          WHEN sis_course_code = course_code THEN
            'course_code'
          ELSE
            NULL
          END);
    SQL
    execute <<-SQL
      UPDATE course_sections SET stuck_sis_fields =
          (CASE WHEN sis_name = name THEN
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
    execute("UPDATE accounts SET stuck_sis_fields = 'name' WHERE sis_name = name;")
    execute("UPDATE groups SET stuck_sis_fields = 'name' WHERE sis_name = name;")
    execute("UPDATE enrollment_terms SET stuck_sis_fields = 'name' WHERE sis_name = name;")
    execute("UPDATE users SET stuck_sis_fields = 'name' WHERE sis_name = name;")
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
