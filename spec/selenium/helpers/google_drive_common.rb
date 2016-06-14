module GoogleDriveCommon
  def setup_google_drive(add_user_service=true, authorized=true)


    UserService.register(
      :service => "google_drive",
      :token => "token",
      :secret => "secret",
      :user => @user,
      :service_domain => "drive.google.com",
      :service_user_id => "service_user_id",
      :service_user_name => "service_user_name"
    ) if add_user_service

    GoogleDrive::Connection.any_instance.
      stubs(:authorized?).
      returns(authorized)

    GoogleDocsCollaboration.any_instance.
        stubs(:initialize_document).
        returns(nil)

    GoogleDocsCollaboration.any_instance.
        stubs(:delete_document).
        returns(nil)

  end
end