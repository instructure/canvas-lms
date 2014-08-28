module PermissionsSerializer
  # Returns a hash of all the granted permissions for the calling user
  def permissions
    object.rights_status(current_user, session)
  end
end
