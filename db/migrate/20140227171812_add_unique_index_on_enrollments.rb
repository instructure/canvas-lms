class AddUniqueIndexOnEnrollments < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::RemoveDuplicateEnrollments.run
    if connection.adapter_name == 'PostgreSQL'
      add_index :enrollments,
                [:user_id, :type, :role_name, :course_section_id, :associated_user_id],
                where: "associated_user_id IS NOT NULL AND role_name IS NOT NULL",
                name: 'index_enrollments_on_user_type_role_section_associated_user',
                unique: true,
                algorithm: :concurrently
      add_index :enrollments,
                [:user_id, :type, :role_name, :course_section_id],
                where: "role_name IS NOT NULL AND associated_user_id IS NULL ",
                name: 'index_enrollments_on_user_type_role_section',
                unique: true,
                algorithm: :concurrently
      add_index :enrollments,
                [:user_id, :type, :course_section_id, :associated_user_id],
                where: "associated_user_id IS NOT NULL AND role_name IS NULL",
                name: 'index_enrollments_on_user_type_section_associated_user',
                unique: true,
                algorithm: :concurrently
      add_index :enrollments,
                [:user_id, :type, :course_section_id],
                where: "associated_user_id IS NULL AND role_name IS NULL",
                unique: true,
                algorithm: :concurrently
    else
      add_index :enrollments,
                [:user_id, :type, :role_name, :course_section_id, :associated_user_id],
                name: 'index_enrollments_on_user_type_role_section_associated_user',
                unique: true,
                algorithm: :concurrently
    end
  end

  def self.down
    remove_index :enrollments, name: 'index_enrollments_on_user_type_role_section_associated_user'
    if connection.adapter_name == 'PostgreSQL'
      remove_index :enrollments, name: 'index_enrollments_on_user_type_role_section'
      remove_index :enrollments, name: 'index_enrollments_on_user_type_section_associated_user'
      remove_index :enrollments, [:user_id, :type, :course_section_id]
    end
  end
end
