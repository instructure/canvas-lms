class GenericSisStickinessRefactorData < ActiveRecord::Migration[4.2]
  tag :predeploy


  def self.up
    update <<-SQL
      UPDATE #{AbstractCourse.quoted_table_name} SET stuck_sis_fields =
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
    update <<-SQL
      UPDATE #{Course.quoted_table_name} SET stuck_sis_fields =
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
    update <<-SQL
      UPDATE #{CourseSection.quoted_table_name} SET stuck_sis_fields =
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
    Account.where("sis_name<>name").update_all(stuck_sis_fields: 'name')
    Group.where("sis_name<>name").update_all(stuck_sis_fields: 'name')
    EnrollmentTerm.where("sis_name<>name").update_all(stuck_sis_fields: 'name')
    User.where("sis_name<>name").update_all(stuck_sis_fields: 'name')
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
