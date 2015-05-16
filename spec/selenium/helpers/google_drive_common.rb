def set_up_google_docs(setupDrive = true)
  UserService.register(
      :service => "google_docs",
      :token => "token",
      :secret => "secret",
      :user => @user,
      :service_domain => "google.com",
      :service_user_id => "service_user_id",
      :service_user_name => "service_user_name"
  )

  GoogleDocs::Connection.any_instance.
      stubs(:verify_access_token).
      returns(true)

  # GoogleDocs::Connection.any_instance.
  #     stubs(:list).
  #     returns(nil)


  GoogleDocsCollaboration.any_instance.
      stubs(:initialize_document).
      returns(nil)

  GoogleDocsCollaboration.any_instance.
      stubs(:delete_document).
      returns(nil)

  if (setupDrive == true)
    set_up_drive_connection
  end

end

def set_up_drive_connection
  UserService.register(
      :service => "google_drive",
      :token => "token",
      :secret => "secret",
      :user => @user,
      :service_domain => "drive.google.com",
      :service_user_id => "service_user_id",
      :service_user_name => "service_user_name"
  )

  GoogleDocs::DriveConnection.any_instance.
      stubs(:verify_access_token).
      returns(true)
end

