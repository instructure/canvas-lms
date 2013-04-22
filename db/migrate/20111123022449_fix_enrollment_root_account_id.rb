class FixEnrollmentRootAccountId < ActiveRecord::Migration
  def self.up
    case adapter_name
    when "PostgreSQL"
      execute "UPDATE enrollments SET root_account_id = c.root_account_id FROM courses As c WHERE course_id = c.id AND enrollments.root_account_id != c.root_account_id"
    when 'MySQL', 'Mysql2'
      execute "UPDATE enrollments e, courses c SET e.root_account_id = c.root_account_id WHERE e.course_id = c.id AND e.root_account_id != c.root_account_id"
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
