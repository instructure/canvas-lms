#
# Copyright (C) 2015 Instructure, Inc.
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
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module Lti
  module Security

    def self.signed_post_params(params, url, key, secret, disable_lti_post_only=false)
      if disable_lti_post_only
        signed_post_params_frd(params, url, key, secret)
      else
        generate_params_deprecated(params, url, key, secret)
      end
    end

    # This is the correct way to sign the params, but in the name of not breaking things, we are using the
    # #generate_params_deprecated method by default
    def self.signed_post_params_frd(params, url, key, secret)
      message = IMS::LTI::Models::Messages::Message.generate(params.merge({oauth_consumer_key: key}))
      message.launch_url = url
      message.signed_post_params(secret).stringify_keys
    end
    private_class_method :signed_post_params_frd

    # This method does a couple of things wrong
    # 1. It copies params from the url to the body by default, this should really be a config setting instead, not the
    # default behaviour
    # 2. It doesn't generate the signature correctly when there are duplicate params in the body and query. It should
    # add the params to the base string for each time they appear in the query and body.  Instead it only adds the
    # params once no matter how many times it appears. For query params since we copy them to the body, it should
    # appear a minimum of twice in the base string.
    def self.generate_params_deprecated(params, url, key, secret)
      uri = URI.parse(url)

      if uri.port == uri.default_port
        host = uri.host
      else
        host = "#{uri.host}:#{uri.port}"
      end

      consumer = OAuth::Consumer.new(key, secret, {
        :site => "#{uri.scheme}://#{host}",
        :signature_method => 'HMAC-SHA1'
      })

      path = uri.path
      path = '/' if path.empty?
      if uri.query && uri.query != ''
        CGI.parse(uri.query).each do |query_key, query_values|
          unless params[query_key]
            params[query_key] = query_values.first
          end
        end
      end
      options = {:scheme => 'body'}

      request = consumer.create_signed_request(:post, path, nil, options, params.stringify_keys)
      # the request is made by a html form in the user's browser, so we
      # want to revert the escapage and return the hash of post parameters ready
      # for embedding in a html view
      hash = {}
      request.body.split(/&/).each do |param|
        key, val = param.split(/=/).map { |v| CGI.unescape(v) }
        hash[key] = val
      end
      hash.stringify_keys
    end
    private_class_method :generate_params_deprecated

    ##
    ## Timeline Examples for valid and invalid timestamps
    ##
    ## |---exp---timestamp---now---|  VALID
    ##
    ## |---timestamp---exp---now---| INVALID
    ##
    ## |---exp---now---timestamp---| INVALID
    ##
    def self.check_and_store_nonce(cache_key, timestamp, expiration)
      allowed_future_skew = 1.minute
      valid = timestamp.to_i > expiration.ago.to_i
      valid &&= timestamp.to_i <= (Time.now + allowed_future_skew).to_i
      valid &&= !Rails.cache.exist?(cache_key)
      Rails.cache.write(cache_key, 'OK', expires_in: expiration + allowed_future_skew) if valid
      valid
    end


  end
end