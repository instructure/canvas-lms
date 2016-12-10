class RecalculateMutedAssignments < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up

    course_ids = Assignment.where(:muted => true, :context_type => 'Course').select(:context_id).uniq.map(&:context_id)
    course_ids.each do |id|
      c = Course.find id
      c.recompute_student_scores
    end

  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
