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

    data = stub('data', id: 1, to_json: { id: 1 }, alternateLink: 'http://localhost/googleDoc')
    doc = stub('doc', data: data)
    adapter = stub('google_adapter', create_doc: doc, acl_add: nil, acl_remove: nil)
    GoogleDocsCollaboration.any_instance.
        stubs(:google_adapter_for_user).
        returns(adapter)

    GoogleDocsCollaboration.any_instance.
        stubs(:delete_document).
        returns(nil)

  end
end
