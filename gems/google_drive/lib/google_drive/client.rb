module GoogleDrive
  class Client

    ##
    #
    # @param [Hash] client_secrets
    #   The parsed client_secrets.json file
    # @param [String] refresh_token
    #   Optional refresh_token
    # @param [String] access_token
    #  Optional access_token
    def self.create(client_secrets, refresh_token = nil, access_token = nil)
      client = Google::APIClient.new(application_name: "Instructure Google Drive", application_version: "0.0.1")
      client.authorization.client_id = client_secrets['client_id']
      client.authorization.client_secret = client_secrets['client_secret']
      client.authorization.redirect_uri = client_secrets['redirect_uri']
      client.authorization.refresh_token = refresh_token if refresh_token
      client.authorization.access_token = access_token if access_token
      client.authorization.scope = %w{https://www.googleapis.com/auth/drive}
      client
    end


    def self.auth_uri(client, state, login=nil)
      auth_client = client.authorization
      auth_client.update!

      request_data = {
        :approval_prompt => :force,
        :state => state,
        :access_type => :offline
      }

      request_data[:login_hint] = login if login


      auth_client.authorization_uri(request_data).to_s
    end
  end
end