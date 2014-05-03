class AddUniqueIndexOnCourseAccountAssociations < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    # clean up any dups first
    course_ids = CourseAccountAssociation.
        select(:course_id).
        uniq.
        group(:course_id, :course_section_id, :account_id).
        having("COUNT(*)>1").
        map(&:course_id)
    Course.update_account_associations(course_ids)

    add_index :course_account_associations, [:course_id, :course_section_id, :account_id], :unique => true, :algorithm => :concurrently, :name => 'index_caa_on_course_id_and_section_id_and_account_id'
    remove_index :course_account_associations, :course_id
  end

  def self.down
    add_index :course_account_associations, :course_id, :algorithm => :concurrently
    remove_index :course_account_associations, 'index_caa_on_course_id_and_section_id_and_account_id'
  end
end
