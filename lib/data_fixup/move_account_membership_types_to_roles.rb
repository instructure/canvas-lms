module DataFixup::MoveAccountMembershipTypesToRoles
  def self.run
    # Step 1.
    #   Look for accounts with membership types
    #   make 'active' roles for each of them, if they don't exist already

  Account.find_in_batches(:conditions => "membership_types IS NOT NULL",
                            :select => "id, membership_types") do |accounts|
      roles = Role.all(:conditions => {:account_id => accounts}, :select => "account_id, name")
      account_users = AccountUser.all(:conditions => {:account_id => accounts}, :select => "account_id, membership_type", :group => "account_id, membership_type")

      accounts.each do |account|
        names = roles.select{|r| r.account_id == account.id}.collect(&:name) + RoleOverride::KNOWN_ROLE_TYPES

        types_to_add = account.membership_types.split(",").select{|t| !t.empty? && !names.include?(t)}
        types_to_add.each do |type|
          role = Role.new
          role.account_id = account.id
          role.name = type
          role.base_role_type = 'AccountMembership'
          role.workflow_state = 'active'
          role.save!
        end

        # Step 1b. Also find AccountUsers that have a non-existent membership_type
        # and make an inactive role for them. of course if there isn't one already

        names += types_to_add
        inactive_types_to_add = account_users.select{|au| au.account_id == account.id && !names.include?(au.membership_type)}.collect(&:membership_type)
        inactive_types_to_add.each do |type|
          role = Role.new
          role.account_id = account.id
          role.name = type
          role.base_role_type = 'AccountMembership'
          role.workflow_state = 'inactive'
          role.save!
        end
      end
    end

    # Step 2.
    #   then look for the role overrides that are referencing to a (presumably) deleted membership type
    #   and make 'inactive' roles for each of them, if they don't exist already
    RoleOverride.all(:conditions => ['context_type = ? AND enrollment_type NOT IN (?)', 'Account', RoleOverride::KNOWN_ROLE_TYPES],
                     :group => 'context_id, enrollment_type',
                     :select => 'context_id, enrollment_type').each_slice(500) do |role_overrides|
      roles = Role.all(:conditions => {:account_id => role_overrides.collect(&:context_id).uniq}, :select => "account_id, name")

      role_overrides_to_add_for = role_overrides.select{|ro| roles.find{|r| r.account_id == ro.context_id && r.name == ro.enrollment_type}.nil?}
      role_overrides_to_add_for.each do |ro|
        role = Role.new
        role.account_id =  ro.context_id
        role.name = ro.enrollment_type
        role.base_role_type = 'AccountMembership'
        role.workflow_state = 'inactive'
        role.save!
      end
    end
  end
end
