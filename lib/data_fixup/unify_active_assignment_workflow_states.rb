module DataFixup::UnifyActiveAssignmentWorkflowStates

  def self.run
    Assignment.where(:workflow_state => "available").find_ids_in_ranges do |min, max|
      Assignment.where(:id => min..max).update_all(:workflow_state => "published")
    end
  end

end
