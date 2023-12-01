# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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
class OutcomesRequestBatcher
  # Max header size is 8K. We allow the JWT token to be at most 7K. This leaves 1K for any other information.
  MAX_JWT_SIZE = 7_168
  def initialize(protocol, endpoint, context, scope, params)
    @requests = split_requests(protocol, endpoint, context, scope, params)
  end

  attr_reader :requests

  private

  def split_requests(protocol, endpoint, context, scope, params)
    requests = []
    domain, jwt = extract_domain_jwt(
      context.root_account,
      scope,
      **params
    )

    return requests if domain.nil? || jwt.nil?

    if jwt.bytesize < MAX_JWT_SIZE
      # No need to split the request because it is small enough.
      requests.push({ protocol:, endpoint:, domain:, jwt:, params: })
    else
      # Sort the parameters by length and attempt to split one of them
      arr = params.sort_by { |_k, v| -v.length }
      preformed_split = false
      key = ""
      left = ""
      right = ""
      arr.each do |largest_param|
        key = largest_param[0]
        value = largest_param[1].split(",")
        left, right = value.each_slice((value.size / 2.0).round).to_a
        next unless right.present?

        preformed_split = true
        left = left.join(",")
        right = right.join(",")
        break
      end
      if preformed_split
        # We have split the request into two requests, but those requests might still be too big so
        # recursively call split_requests until all requests are below max size
        requests.concat(split_requests(protocol, endpoint, context, scope, new_params(params, key, left)))
        requests.concat(split_requests(protocol, endpoint, context, scope, new_params(params, key, right)))
      else
        # Cannot split the parameters any further. This is the smallest possible set of parameters.
        # If we were unable to split this enough, this request could still fail.
        requests.push({ protocol:, endpoint:, domain:, jwt:, params: })
      end
    end
    requests
  end

  def new_params(params, key, new_value)
    n = params.clone
    n[key] = new_value
    n
  end

  def extract_domain_jwt(account, scope, **props)
    settings = account.settings.dig(:provision, "outcomes") || {}
    domain = nil
    jwt = nil
    if settings.key?(:consumer_key) && settings.key?(:jwt_secret) && settings.key?(domain_key)
      consumer_key = settings[:consumer_key]
      jwt_secret = settings[:jwt_secret]
      domain = settings[domain_key]
      payload = {
        host: domain,
        consumer_key:,
        scope:,
        exp: 1.day.from_now.to_i,
        **props
      }
      jwt = JWT.encode(payload, jwt_secret, "HS512")
    end

    [domain, jwt]
  end

  def domain_key
    # test_cluster? and test_cluster_name are true and not nil for nonprod environments,
    # like beta or test
    if ApplicationController.test_cluster?
      :"#{ApplicationController.test_cluster_name}_domain"
    else
      :domain
    end
  end
end
