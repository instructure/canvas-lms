module DataFixup::RemoveDuplicateGroupMemberships
  def self.run
    rank_sql = GroupMembership.rank_sql(["accepted", "invited", "requested", "rejected"], "workflow_state")
    while (dups = GroupMembership.where.not(:workflow_state => "deleted").group(:group_id, :user_id).having("COUNT(*) > 1").pluck(:group_id, :user_id)) && dups.any?
      dups.each do |group_id, user_id|
        GroupMembership.where(:group_id => group_id, :user_id => user_id).order(rank_sql).offset(1).delete_all
      end
    end
  end
end
