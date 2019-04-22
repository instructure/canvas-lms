#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.


module AcceptOpenIDConnectParamAsValidResponse
  def get_token(params, access_token_opts = {}, access_token_class = ::OAuth2::AccessToken) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    params = ::OAuth2::Authenticator.new(id, secret, options[:auth_scheme]).apply(params)
    opts = {:raise_errors => options[:raise_errors], :parse => params.delete(:parse)}
    headers = params.delete(:headers) || {}
    if options[:token_method] == :post
      opts[:body] = params
      opts[:headers] = {'Content-Type' => 'application/x-www-form-urlencoded'}
    else
      opts[:params] = params
      opts[:headers] = {}
    end
    opts[:headers].merge!(headers)
    response = request(options[:token_method], token_url, opts)
    # only change is on this line; Microsoft doesn't send back an access_token if you're doing a pure OpenID Connect auth
    if options[:raise_errors] && !(response.parsed.is_a?(Hash) && response.parsed['access_token'] || response.parsed['id_token'])
      error = ::OAuth2::Error.new(response)
      raise(error)
    end
    access_token_class.from_hash(self, response.parsed.merge(access_token_opts))
  end
end
OAuth2::Client.prepend(AcceptOpenIDConnectParamAsValidResponse)
