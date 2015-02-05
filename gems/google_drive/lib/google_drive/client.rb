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
      client = Google::APIClient.new
      client.authorization.client_id = client_secrets['client_id']
      client.authorization.client_secret = client_secrets['client_secret']
      client.authorization.redirect_uri = client_secrets['redirect_uri']
      client.authorization.refresh_token = refresh_token if refresh_token
      client.authorization.access_token = access_token if access_token
      client.authorization.scope = %w{https://www.googleapis.com/auth/drive}
      client
    end


    def self.auth_uri(client, state)
      auth_client = client.authorization
      auth_client.update!

      auth_client.authorization_uri(
        :approval_prompt => :force,
        :state => state,
        :access_type => :offline).to_s
    end
  end
end