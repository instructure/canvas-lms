# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

# @API InstAccess tokens
# Short term JWT tokens that can be used to authenticate with Canvas and other
# Instructure services.  InstAccess tokens expire after one hour.  Canvas hands
# out encrypted tokens that need to be decrypted by the API Gateway before they
# can be accepted by Canvas or other services.
#
# @model InstAccessToken
#    {
#      "id": "InstAccessToken",
#      "properties": {
#        "token": {
#           "description": "The InstAccess token itself -- a signed, encrypted JWT",
#           "example": "eyJhbGciOiJSU0ExXzUiLCJlbmMiOiJBMTI4Q0JDLUhTMjU2In0.EstatUwzltksvZn4wbjHYiwleM986vzryrv4R9jqvYDGEY4rt6KPG4Q6lJ3oI0piYbH7h17i8vIWv35cqrgRbb7fzmGQ0Ptj74OEjx-1gGBMZCbZTE4W206XxPHRm9TS4qOAvIq0hsvJroE4xZsVWJFiUIKl_Wd2udbvqwF8bvnMKPAx_ooa-9mWaG1N9kd4EWC3Oxu9wi7j8ZG_TbkLSXAg1KxLaO2zXBcU5_HWrKFRxOjHmWpaOMKWkjUInt-DA6fLRszBZp9BFGoop8S9KDs6f1JebLgyM5gGrP-Gz7kSEAPO9eVXtjpd6N29wMClNI0X-Ppp_40Fp4Z3vocTKQ.c_tcevWI68RuZ0s04fDSEQ.wV8KIPHGfYwxm19MWt3K7VVGm4qqZJruPwAZ8rdUANTzJoqwafqOnYZLCyky8lV7J-m64SMVUmR-BOha_CmJEKVVw7T5x70MTP6-nv4RMVPpcViHsNgE2f1GE9HUauVePw7CrnV0PyVaNq2EZasDgdHdye4iG_-hXXQZRnGYzxl8UceTLBVkpEYHlXKdD7DyQ0IT2BYOcZSpXyW7kEIvAHpNaNbvTPCR2t0SeGbuNf8PpYVjohKDpXhNgQ-Pyl9pxs05TrdjTq1fIctzTLqIN58nfqzoqQld6rSkjcAZZXgr8bOsg8EDFMov5gTv2_Uf-YOm52yD1SbL0lJ-VdpKgXu7XtQ4UmEOj40W4uXF-KmLTjEwQmdbmtKrruhakIeth7EZa3w0Xg6RRyHLqKUheAdTgxAIer8MST8tamZlqW1b9wjMw371zSSjeksF_UjTS9p9i7eTtRPuAbf9geDhKb5e-y29MJaL1eKkhTMiEOPY3O4XGGuqRdRMrbjkNmla_RxiQhFJ3T8Dem-yDRan8gqaJLfRRrvGViz-lty96bQT-Z0hVer1uJhAtkM6RT_DgrnAUP_66LfaupZr6bLCKwnYocF1ICcAzkcYw7l5jHa4DTc2ZLgLi-yfbv2wGXpybAvLfZcO424TxHOuQykCSvbfPPuf06kkjPbYmMg6_GdM3JcQ_50VUXQFZkjH45BH5zX7y-2u0ReM8zxt65RpJAvlivrc8j2_E-u0LhlzCwEgsnd61lG4baaI86IVl4wNXkMDui4CgGvAUAf4AXW7Imw_cF0zI69z0SLfahjaYkdREGIYKStBtPAR04sfsR7o.LHBODYub4W4Vq-SXfdbk1Q",
#           "type": "string"
#         }
#       }
#    }
#

class InstAccessTokensController < ApplicationController
  before_action :require_user, :require_non_jwt_auth

  ADDITIONAL_CREATE_REQUEST_COST = 200

  # @API Create InstAccess token
  #
  # Create a unique, encrypted InstAccess token.
  #
  # Generates a different InstAccess token each time it's called, each one expires
  # after a short window (1 hour).
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/inst_access_tokens' \
  #         -X POST \
  #         -H "Accept: application/json" \
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns InstAccessToken
  def create
    # tokens are good for an hour, so nobody should have a legit need to spam this endpoint
    increment_request_cost(ADDITIONAL_CREATE_REQUEST_COST)

    token = InstAccess::Token.for_user(
      user_uuid: @current_user.uuid,
      account_uuid: @domain_root_account.uuid,
      canvas_domain: request.host_with_port,
      real_user_uuid: @real_current_user&.uuid,
      real_user_shard_id: @real_current_user&.shard&.id,
      user_global_id: @current_user.global_id,
      real_user_global_id: @real_current_user&.global_id,
      region: ApplicationController.region
    )
    render status: :created, json: { token: token_string_for(token) }
  end

  private

  def token_string_for(inst_access_token)
    if value_to_boolean(params[:unencrypted]) && Rails.env.development?
      inst_access_token.to_unencrypted_token_string
    else
      inst_access_token.to_token_string
    end
  end
end
