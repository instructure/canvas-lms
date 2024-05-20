# frozen_string_literal: true

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
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module Lti
  module Security
    def self.signed_post_params(params, url, key, secret, disable_lti_post_only = false)
      # Signature is based on base string (POST&url&encodedparams) and secret
      # (no oauth token, so the HMAC secret is "secret&", where secret is the
      # shared_secret of the tool). See LTI 1.1 spec (section 4.2, OAuth Message Signing)
      if disable_lti_post_only
        signed_post_params_frd(params, url, key, secret)
      else
        generate_params_deprecated(params, url, key, secret)
      end
    end

    # This is the correct way to sign the params, but in the name of not breaking things, we are using the
    # #generate_params_deprecated method by default
    def self.signed_post_params_frd(params, url, key, secret)
      message = ::IMS::LTI::Models::Messages::Message.generate(params.merge({ oauth_consumer_key: key }))
      message.launch_url = url
      # signed_post_params in IMS::LTI gem handles changing line endings to
      # CRLF to make compliant with browser
      signed_parameters = message.signed_post_params(secret).stringify_keys

      Lti::Logging.lti_1_launch_generated(message.message_authenticator.base_string)

      signed_parameters
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
      uri = URI.parse(url.strip)

      host = if uri.port == uri.default_port
               uri.host
             else
               "#{uri.host}:#{uri.port}"
             end

      consumer = OAuth::Consumer.new(key, secret, {
                                       site: "#{uri.scheme}://#{host}",
                                       signature_method: "HMAC-SHA1"
                                     })

      path = uri.path
      path = "/" if path.empty?
      if uri.query && uri.query != ""
        CGI.parse(uri.query).each do |query_key, query_values|
          unless params[query_key]
            params[query_key] = query_values.first
          end
        end
      end
      options = { scheme: "body" }

      params = params.stringify_keys
      # Browsers convert newlines to CRLF, to we need to do it ourselves before signature
      # generation to make the signature match
      params = ::IMS::LTI::Models::Messages::Message.convert_param_values_to_crlf_endings(params)
      request = consumer.create_signed_request(:post, path, nil, options, params)
      # the request is made by a html form in the user's browser, so we
      # want to revert the escapage and return the hash of post parameters ready
      # for embedding in a html view
      hash = {}
      request.body.split("&").each do |param|
        key, val = param.split("=").map { |v| CGI.unescape(v) }
        hash[key] = val
      end

      # NOTE: this base string has duplicate oauth parameters in it when logged,
      # though these parameters don't affect signature generation and oauth launches (I hope?)
      Lti::Logging.lti_1_launch_generated(request.oauth_helper.signature_base_string)

      hash.stringify_keys
    end
    private_class_method :generate_params_deprecated

    ##
    #  Used to determine if the nonce is still valid
    #
    #  +cache_key+:: This is the redis cache key used to check if the nonce key has been used
    #  +timestamp+:: The timestamp of when the request was signed
    #  +nonce_age+:: An ActiveSupport::Duration describing how old a nonce can be
    #
    #  The +nonce_age+ creates a range that the timestamp must fall between for the nonce to be valid
    #  valid_range = +Time.now+ - (the +nonce_age+ duration)
    #  i.e. if the current time was 2010-04-23T12:30:00Z and the +nonce_age+ was 30min
    #  then the valid time range that the timestamp must fall between would
    #  be "2010-04-23T12:30:00Z/2010-04-23T13:00:00Z"
    #
    #  =Time line Examples for valid and invalid timestamps
    #
    #  |---nonce_age---timestamp---Time.now---|  VALID
    #
    #  |---timestamp---nonce_age---Time.now---| INVALID
    #
    #  |---nonce_age---Time.now---timestamp---| INVALID
    #
    def self.check_and_store_nonce(cache_key, timestamp, nonce_age)
      allowed_future_skew = 1.minute
      valid = timestamp.to_i > nonce_age.ago.to_i
      valid &&= timestamp.to_i <= (Time.zone.now + allowed_future_skew).to_i
      valid &&= !Rails.cache.exist?(cache_key)
      Rails.cache.write(cache_key, "OK", expires_in: nonce_age + allowed_future_skew) if valid
      valid
    end

    def self.decoded_lti_assignment_id(secure_params)
      return if secure_params.blank?

      secure_params = Canvas::Security.decode_jwt(secure_params)
      secure_params[:lti_assignment_id]
    rescue Canvas::Security::InvalidToken
      nil
    end

    def self.decoded_lti_assignment_description(secure_params)
      return if secure_params.blank?

      secure_params = Canvas::Security.decode_jwt(secure_params)
      secure_params[:lti_assignment_description]
    rescue Canvas::Security::InvalidToken
      nil
    end
  end
end
