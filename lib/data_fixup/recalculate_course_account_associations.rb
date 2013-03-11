module DataFixup::RecalculateCourseAccountAssociations
  def self.run
    Course.active.scoped(:joins => :root_account, :conditions => "accounts.workflow_state<>'deleted'").find_in_batches do |batch|
      Course.send(:with_exclusive_scope) do
        Course.update_account_associations(batch)
      end
    end
  end
end