class ChangeSisBatchIdToInteger < ActiveRecord::Migration
  def self.up
    if connection.adapter_name == 'PostgreSQL'
      execute("ALTER TABLE abstract_courses ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE accounts ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE accounts ALTER current_sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE accounts ALTER last_successful_sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE course_sections ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE courses ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE enrollment_terms ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE enrollments ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE group_memberships ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE groups ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
      execute("ALTER TABLE pseudonyms ALTER sis_batch_id TYPE bigint USING CAST(sis_batch_id AS bigint)")
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
