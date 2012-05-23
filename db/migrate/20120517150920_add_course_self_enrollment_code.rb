class AddCourseSelfEnrollmentCode < ActiveRecord::Migration
  self.transactional = false
  tag :predeploy

  def self.up
    add_column :courses, :self_enrollment_code, :string
    if connection.adapter_name =~ /\Apostgresql/i
      execute('CREATE UNIQUE INDEX CONCURRENTLY "index_courses_on_self_enrollment_code" ON courses(self_enrollment_code) WHERE self_enrollment_code IS NOT NULL')
    else
      add_index :courses, [:self_enrollment_code], :unique => true
    end
  end

  def self.down
    remove_column :courses, :self_enrollment_code
  end
end
