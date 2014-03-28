module PermissionsSerializer
  # Returns a hash of all the granted permissions for the calling user
  def permissions
    @@_permissions ||= begin
      permissions = object.class.policy.conditions.
        map { |args| args.second }.
        flatten.
        uniq
    end
    @@_permissions.each_with_object({}) do |permission, hash|
      hash[permission] = object.grants_right?(current_user, session, permission)
    end
  end
end
