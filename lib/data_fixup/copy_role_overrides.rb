module DataFixup::CopyRoleOverrides
  def self.run(old_permission, new_permission)
    RoleOverride.where(:permission => old_permission.to_s).find_in_batches do |old_role_overrides|
      possible_new_role_overrides = RoleOverride.where(permission: new_permission.to_s, context_id: old_role_overrides.map(&:context_id)).all

      old_role_overrides.each do |old_role_override|
        unless old_role_override.invalid? || possible_new_role_overrides.detect{|ro|
          ro.context_id == old_role_override.context_id &&
          ro.context_type == old_role_override.context_type &&
          ro.role_id == old_role_override.role_id
        }

          dup = RoleOverride.new
          old_role_override.attributes.delete_if{|k,v| [:id, :permission, :created_at, :updated_at].include?(k.to_sym)}.each do |key, val|
            dup.send("#{key}=", val)
          end
          dup.permission = new_permission.to_s
          dup.save!
        end
      end
    end
  end
end
