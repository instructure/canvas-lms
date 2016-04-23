module DataFixup::FixGroupsWithDuplicateWikiAndUuid
  def self.reset_dups(dup_scope, attrs)
    keeper = dup_scope.first
    dup_scope = dup_scope.where.not(:id => keeper)

    attrs.each do |attr|
      dup_scope.where(attr => keeper[attr]).update_all(attr => nil, updated_at: Time.now.utc)
    end
  end

  def self.run
    run_groups(:wiki_id)
    run_groups(:uuid)
    run_uuid_group_memberships
  end

  def self.run_groups(attr)
    Group.where.not(attr => nil).group(attr, :context_id, :context_type).having("COUNT(*) > 1").
      pluck(attr, :context_id, :context_type).each do |value, context_id, context_type|

      scope = Group.where(
        attr => value,
        context_id: context_id,
        context_type: context_type
      ).order(:created_at)

      reset_dups(scope, [:sis_batch_id, :sis_source_id, :wiki_id, :uuid])
    end
  end

  def self.run_uuid_group_memberships
    GroupMembership.group(:uuid).having("COUNT(*) > 1").pluck(:uuid).each do |uuid|
      scope = GroupMembership.where(uuid: uuid).order(:created_at)
      reset_dups(scope, [:sis_batch_id, :uuid])
    end
  end
end
