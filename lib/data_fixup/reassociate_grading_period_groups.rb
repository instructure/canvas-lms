module DataFixup::ReassociateGradingPeriodGroups
  def self.run
    # associates root account grading period groups with enrollment terms
    GradingPeriodGroup.active.where.not(account_id: nil).preload(account: :active_enrollment_terms).find_each do |group|
      account = group.account
      next unless account.root_account?
      account.active_enrollment_terms.each do |term|
        term.grading_period_group = group
        term.save!
      end
    end
  end
end
