class ChangeSisBatchIdToInteger < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      execute("ALTER TABLE #{AbstractCourse.quoted_table_name} ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE #{Account.quoted_table_name} ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE #{Account.quoted_table_name} ALTER current_sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE #{Account.quoted_table_name} ALTER last_successful_sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE #{CourseSection.quoted_table_name} ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE #{Course.quoted_table_name} ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE #{EnrollmentTerm.quoted_table_name} ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE #{Enrollment.quoted_table_name} ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE #{GroupMembership.quoted_table_name} ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE #{Group.quoted_table_name} ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE #{Pseudonym.quoted_table_name} ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
    else
      change_column :abstract_courses, :sis_batch_id, :integer, :limit => 8
      change_column :accounts, :sis_batch_id, :integer, :limit => 8
      change_column :accounts, :current_sis_batch_id, :integer, :limit => 8
      change_column :accounts, :last_successful_sis_batch_id, :integer, :limit => 8
      change_column :course_sections, :sis_batch_id, :integer, :limit => 8
      change_column :courses, :sis_batch_id, :integer, :limit => 8
      change_column :enrollment_terms, :sis_batch_id, :integer, :limit => 8
      change_column :enrollments, :sis_batch_id, :integer, :limit => 8
      change_column :group_memberships, :sis_batch_id, :integer, :limit => 8
      change_column :groups, :sis_batch_id, :integer, :limit => 8
      change_column :pseudonyms, :sis_batch_id, :integer, :limit => 8
    end
  end

  def self.down
    change_column :pseudonyms, :sis_batch_id, :string
    change_column :groups, :sis_batch_id, :string
    change_column :group_memberships, :sis_batch_id, :string
    change_column :enrollments, :sis_batch_id, :string
    change_column :enrollment_terms, :sis_batch_id, :string
    change_column :courses, :sis_batch_id, :string
    change_column :course_sections, :sis_batch_id, :string
    change_column :accounts, :last_successful_sis_batch_id, :string
    change_column :accounts, :current_sis_batch_id, :string
    change_column :accounts, :sis_batch_id, :string
    change_column :abstract_courses, :sis_batch_id, :string
  end
end
