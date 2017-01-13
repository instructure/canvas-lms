module DataFixup::AddRoleOverridesForNewPermission
  # any time we add a new permission, we should run this to populate the role overrides for
  # custom roles lest there be any rude surprises when the custom roles no longer behave as expected
  # (for instance if a custom account admin has :manage_admin_users, they will
  # suddenly no longer be able to add account admins anymore until this is run)

  def self.run(base_permission, new_permission)
    [base_permission, new_permission].each do |perm|
      raise "#{perm} is not a valid permission" unless RoleOverride.permissions.keys.include?(perm.to_sym)
    end

    RoleOverride.where(:permission => base_permission).find_in_batches do |base_overrides|
      # just in case
      new_overrides = RoleOverride.where(:permission => new_permission, :context_id => base_overrides.map(&:context_id))

      base_overrides.each do |ro|
        next if new_overrides.detect{|nro| nro.context_id == ro.context_id && nro.context_type == ro.context_type && nro.role_id == ro.role_id }
        new_ro = RoleOverride.new
        new_ro.permission = new_permission
        attrs = ro.attributes.slice(*%w{context_type context_id role_id locked enabled applies_to_self applies_to_descendants applies_to_env})
        new_ro.assign_attributes(attrs)
        new_ro.save!
      end
    end
  end
end
