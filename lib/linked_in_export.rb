require 'net/http'
require 'net/https'
require 'nokogiri'
require 'uri'

module LinkedInExport

  def linked_in_oauth(service, user, session)
    Rails.logger.debug("### linked_in_oauth - begin for user = #{user.inspect}.")
    linkedin_connection = LinkedIn::Connection.new
    request_token = linkedin_connection.request_token(bz_linked_in_export_oauth_success_url)
    session[:oauth_linked_in_request_token_token] = request_token.token
    session[:oauth_linked_in_request_token_secret] = request_token.secret
    OauthRequest.create(
      :service => 'linked_in',
      :token => request_token.token,
      :secret => request_token.secret,
      :return_url => bz_linked_in_export_oauth_success_url,
      :user => user,
      :original_host_with_port => request.host_with_port
    )
    Rails.logger.debug("### Calling to oauth against LinkedIn API for user = #{user.inspect}.  Target URL: #{request_token.authorize_url}")
    response = request_token.request(:get,  request_token.authorize_url, request_token)
    Rails.logger.debug("### Response = #{response.inspect}, response.body = #{response.body}")

    #http,request = delicious_generate_request('https://api.del.icio.us/v1/posts/update', 'GET', service.service_user_name, service.decrypted_password)
    #response = http.request(request)
    #case response
    #  when Net::HTTPSuccess
    #    updated = Nokogiri::XML(response.body).root["time"]
    #    return Time.parse(updated)
    #  else
    #    response.error!
    #end
  end

  def linked_in_oauth_success(oauth_request, session)
    Rails.logger.debug("### linked_in_oauth_success - begin oauth_request = #{oauth_request.inspect}.")
    linkedin_connection = LinkedIn::Connection.new
    token = session.delete(:oauth_linked_in_request_token_token)
    secret = session.delete(:oauth_linked_in_request_token_secret)
    access_token = linkedin_connection.get_access_token(token, secret, params[:oauth_verifier])
    export_result = linkedin_connection.get_service_user_data_export(access_token)
    # TODO: what does the result look like?  is it in the DB or does it return it as json or something?
    if oauth_request.user
      # TODO: do something with the result.
      if (export_result != true)
        Rails.logger.error("Exporting LinkedIn user data failed for")
      end
    else
      session[:oauth_linked_in_access_token_token] = access_token.token
      session[:oauth_linked_in_access_token_secret] = access_token.secret
    end
  end
end

