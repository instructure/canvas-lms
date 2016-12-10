class FixEnrollmentRootAccountId < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    case adapter_name
    when "PostgreSQL"
      update "UPDATE #{Enrollment.quoted_table_name} SET root_account_id = c.root_account_id FROM #{Course.quoted_table_name} As c WHERE course_id = c.id AND enrollments.root_account_id != c.root_account_id"
    else
      Course.find_each do |c|
        bad_enrollments = c.enrollments.where("enrollments.root_account_id<>courses.root_account_id").pluck(:id)
        Enrollment.where(:id => bad_enrollments).update_all(:root_account_id => c.root_account_id)
      end
    end
  end

  def self.down
  end
end
