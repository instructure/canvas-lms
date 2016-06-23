

module AcceptOpenIDConnectParamAsValidResponse
  def get_token(params, access_token_opts = {}, access_token_class = OAuth2::AccessToken)
    opts = {:raise_errors => options[:raise_errors], :parse => params.delete(:parse)}
    if options[:token_method] == :post
      headers = params.delete(:headers)
      opts[:body] = params
      opts[:headers] =  {'Content-Type' => 'application/x-www-form-urlencoded'}
      opts[:headers].merge!(headers) if headers
    else
      opts[:params] = params
    end
    response = request(options[:token_method], token_url, opts)
    error = OAuth2::Error.new(response)
    # only change is on this line; Microsoft doesn't send back an access_token if you're doing a pure OpenID Connect auth
    fail(error) if options[:raise_errors] && !(response.parsed.is_a?(Hash) && (response.parsed['access_token'] || response.parsed['id_token']))
    access_token_class.from_hash(self, response.parsed.merge(access_token_opts))
  end
end
OAuth2::Client.prepend(AcceptOpenIDConnectParamAsValidResponse)
