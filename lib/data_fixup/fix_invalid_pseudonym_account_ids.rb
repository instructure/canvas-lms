module DataFixup::FixInvalidPseudonymAccountIds
  def self.run
    Pseudonym.where("NOT EXISTS (?)", Account.where("account_id=accounts.id AND root_account_id IS NULL")).
      includes(:account, :user).find_each do |p|
      if p.workflow_state == 'deleted'
        destroy_pseudonym(p)
      elsif Pseudonym.where(account_id: p.root_account_id, sis_user_id: p.sis_user_id).
        order(:workflow_state).where("sis_user_id IS NOT NULL").first

        destroy_pseudonym(p)
      elsif (p2 = Pseudonym.by_unique_id(p.unique_id).active.
        where(account_id: p.root_account_id).order(:workflow_state).first)

        UserMerge.from(p.user).into(p2.user)
        destroy_pseudonym(p)
      else
        p.account_id = p.root_account_id
        p.save!
      end
    end
  end

  def self.destroy_pseudonym(p)
    p.session_persistence_tokens.scoped.delete_all
    p.destroy!
  end

end
