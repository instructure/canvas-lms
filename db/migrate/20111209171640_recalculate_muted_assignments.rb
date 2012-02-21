class RecalculateMutedAssignments < ActiveRecord::Migration
  def self.up
    
    course_ids = Assignment.find(:all, 
                                 :conditions => ['muted = ? AND context_type = ?', true, 'Course'], 
                                 :select => 'distinct context_id').map(&:context_id)
    course_ids.each do |id|
      c = Course.find id
      c.recompute_student_scores
    end
    
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
