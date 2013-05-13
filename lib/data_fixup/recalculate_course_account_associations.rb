module DataFixup::RecalculateCourseAccountAssociations
  def self.run
    Course.active.joins(:root_account).where("accounts.workflow_state<>'deleted'").find_in_batches do |batch|
      Course.send(:with_exclusive_scope) do
        Course.update_account_associations(batch)
      end
    end
  end
end