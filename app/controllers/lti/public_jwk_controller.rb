# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module Lti
  # @API Public JWK
  #
  # @model DeveloperKey
  #     {
  #       "id":"DeveloperKey",
  #       "description":"",
  #       "properties":{
  #          "id":{
  #             "description":"The ID should match the Developer Key ID in canvas",
  #             "example":"1000000000040",
  #             "type":"number"
  #          },
  #          "is_lti_key":{
  #             "description":"true the tool is a lti key, null is not a lti key",
  #             "example":"true",
  #             "type":"boolean"
  #          },
  #          "visible":{
  #             "description":"Controls if the tool is visable",
  #             "example":"true",
  #             "type":"boolean"
  #          },
  #          "account_name":{
  #             "description":"The name of the account associated with the tool",
  #             "example":"The Academy",
  #             "type":"string"
  #          },
  #          "public_jwk":{
  #             "description":"The public key in jwk format",
  #             "example":"{\n\t\"kty\":\"RSA\",\n\t\"e\":\"AQAB\",\n\t\"n\":\"ufmgt156hs168mgdhy168jrsydt168ju816rtahesuvdbmnrtd87t7h8ser\",\n\t\"alg\":\"RS256\",\n\t\"use\":\"sig\",\n\t\"kid\":\"Se68gr16s6tj_87sdr98g489dsfjy-547a6eht1\",\n}",
  #             "type":"string"
  #          },
  #          "vendor_code":{
  #             "description":"The code of the vendor managing the tool",
  #             "example":"fi5689s9avewr68",
  #             "type":"string"
  #          },
  #          "last_used_at":{
  #             "description":"The date and time the tool was last used",
  #             "example":"2019-06-07T20:34:33Z",
  #             "type":"datetime"
  #          },
  #          "access_token_count":{
  #             "description":"The number of active access tokens associated with the tool",
  #             "example":"0",
  #             "type":"number"
  #          },
  #          "redirect_uris":{
  #             "description":"redirect uris description",
  #             "example":"https://redirect.to.here.com",
  #             "type":"string"
  #          },
  #          "redirect_uri":{
  #             "description":"redirect uri description",
  #             "example":"https://redirect.to.here.com",
  #             "type":"string"
  #          },
  #          "api_key":{
  #             "description":"Api key for api access for the tool",
  #             "example":"sd45fg648sr546tgh15S15df5se56r4xdf45asef456",
  #             "type":"string"
  #          },
  #          "notes":{
  #             "description":"Notes for use specifications for the tool",
  #             "example":"Used for sorting graded assignments",
  #             "type":"string"
  #          },
  #          "name":{
  #             "description":"Display name of the tool",
  #             "example":"Tool 1",
  #             "type":"string"
  #          },
  #          "user_id":{
  #             "description":"ID of the user associated with the tool",
  #             "example":"tu816dnrs6zdsg148918dmu",
  #             "type":"string"
  #          },
  #          "created_at":{
  #             "description":"The time the jwk was created",
  #             "example":"2019-06-07T20:34:33Z",
  #             "type":"datetime"
  #          },
  #          "user_name":{
  #             "description":"The user name of the tool creator",
  #             "example":"johnsmith",
  #             "type":"string"
  #          },
  #          "email":{
  #             "description":"Email associated with the tool owner",
  #             "example":"johnsmith@instructure.com",
  #             "type":"string"
  #          },
  #          "require_scopes":{
  #             "description":"True if the tool has required permissions, null if there are no needed permissions",
  #             "example":"true",
  #             "type":"boolean"
  #          },
  #          "icon_url":{
  #             "description":"Icon to be displayed with the name of the tool",
  #             "example":"null",
  #             "type":"string"
  #          },
  #          "scopes":{
  #             "description":"Specified permissions for the tool",
  #             "example":"https://canvas.instructure.com/lti/public_jwk/scope/update",
  #             "type":"string"
  #          },
  #          "workflow_state":{
  #             "description":"The current state of the tool",
  #             "example":"active",
  #             "type":"string"
  #          }
  #       }
  #     }
  class PublicJwkController < ApplicationController
    include ::Lti::IMS::Concerns::LtiServices
    include Api::V1::DeveloperKey

    MIME_TYPE = "application/vnd.ims.lis.v2.publicjwk+json"

    ACTION_SCOPE_MATCHERS = {
      update: all_of(TokenScopes::LTI_UPDATE_PUBLIC_JWK_SCOPE)
    }.freeze.with_indifferent_access

    # @API Update Public JWK
    # Rotate the public key in jwk format when using lti services
    #
    # @argument public_jwk [Required, json]
    #   The new public jwk that will be set to the tools current public jwk.
    #
    # @returns DeveloperKey
    def update
      developer_key.update!(public_jwk:)
      render json: developer_key_json(developer_key, @current_user, session, context), content_type: MIME_TYPE
    end

    private

    def public_jwk
      params.require(:developer_key)[:public_jwk]&.to_unsafe_h
    end

    def scopes_matcher
      ACTION_SCOPE_MATCHERS.fetch(action_name, self.class.none)
    end
  end
end
