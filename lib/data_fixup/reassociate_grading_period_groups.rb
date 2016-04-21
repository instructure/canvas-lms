module DataFixup::ReassociateGradingPeriodGroups
  def self.run
    # associates root account grading period groups with enrollment terms
    GradingPeriodGroup.active.where.not(account_id: nil).find_in_batches do |groups|
      account_subquery = Account.where(id: groups.map(&:account_id), root_account_id: nil)
      term_ids = EnrollmentTerm.active.where(root_account_id: account_subquery).pluck(:id)
      groups.each do |group|
        EnrollmentTerm.
          where(id: term_ids, root_account_id: group.account_id).
          update_all(grading_period_group_id: group)
      end
    end
  end
end
