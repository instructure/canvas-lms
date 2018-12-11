#
# Copyright (C) 2018 - present Instructure, Inc.
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

# rubocop:disable Metrics/LineLength
module Lti::Ims
  # @API Names and Role
  # @internal
  # API for IMS Names and Role Provisioning Service version 2 .
  #
  # Official specification: https://www.imsglobal.org/spec/lti-nrps/v2p0
  #
  # Requires JWT OAuth2 Access Tokens with the `https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly` scope
  #
  # Response Content-Type is application/vnd.ims.lti-nrps.v2.membershipcontainer+json
  #
  # @model NamesAndRoleContext
  #     {
  #        "id": "NamesAndRoleContext",
  #        "description": "An abbreviated representation of an LTI Context",
  #        "properties":
  #        {
  #          "id": {
  #            "description": "LTI Context unique identifier",
  #            "example": "4dde05e8ca1973bcca9bffc13e1548820eee93a3",
  #            "type": "string"
  #          },
  #          "label": {
  #            "description": "LTI Context short name or code",
  #            "example": "CS-101",
  #            "type": "string"
  #          },
  #          "title": {
  #            "description": "LTI Context full name",
  #            "example": "Computer Science 101",
  #            "type": "string"
  #          }
  #        }
  #     }
  #
  # @model NamesAndRoleMessage
  #     {
  #        "id": "NamesAndRoleMessage",
  #        "description": "Additional attributes which would appear in the LTI launch message were this member to click the specified resource link (`rlid` query parameter)",
  #        "properties":
  #        {
  #          "https://purl.imsglobal.org/spec/lti/claim/message_type": {
  #            "description": "The type of LTI message being described. Always set to 'LtiResourceLinkRequest'",
  #            "enum": [ "LtiResourceLinkRequest" ],
  #            "type": "string",
  #            "example": "LtiResourceLinkRequest"
  #          },
  #          "locale": {
  #            "description": "The member's preferred locale",
  #            "type": "string",
  #            "example": "en"
  #          },
  #          "https://www.instructure.com/canvas_user_id": {
  #            "description": "The member's API ID",
  #            "type": "integer",
  #            "example": 1
  #          },
  #          "https://www.instructure.com/canvas_user_login_id": {
  #            "description": "The member's primary login username",
  #            "type": "string",
  #            "example": "showell@school.edu"
  #          },
  #          "https://purl.imsglobal.org/spec/lti/claim/custom": {
  #            "description": "Expanded LTI custom parameters that pertain to the member (as opposed to the Context)",
  #            "type": "object",
  #            "example": {
  #              "message_locale": "en",
  #              "person_address_timezone": "America/Denver"
  #            }
  #          }
  #        }
  #     }
  #
  # @model NamesAndRoleMembership
  #     {
  #        "id": "NamesAndRoleMembership",
  #        "description": "A member of a LTI Context in one or more roles",
  #        "properties":
  #        {
  #          "status": {
  #            "description": "Membership state",
  #            "enum": [ "Active" ],
  #            "example": "Active",
  #            "type": "string"
  #          },
  #          "name": {
  #            "description": "Member's full name. Only included if tool privacy level is `public` or `name_only`.",
  #            "example": "Sienna Howell",
  #            "type": "string"
  #          },
  #          "picture": {
  #            "description": "URL to the member's avatar. Only included if tool privacy level is `public`.",
  #            "example": "https://example.instructure.com/images/messages/avatar-50.png",
  #            "type": "string"
  #          },
  #          "given_name": {
  #            "description": "Member's 'first' name. Only included if tool privacy level is `public` or `name_only`.",
  #            "example": "Sienna",
  #            "type": "string"
  #          },
  #          "family_name": {
  #            "description": "Member's 'last' name. Only included if tool privacy level is `public` or `name_only`.",
  #            "example": "Howell",
  #            "type": "string"
  #          },
  #          "email": {
  #            "description": "Member's email address. Only included if tool privacy level is `public` or `email_only`.",
  #            "example": "showell@school.edu",
  #            "type": "string"
  #          },
  #          "lis_person_sourcedid": {
  #            "description": "Member's primary SIS identifier. Only included if tool privacy level is `public` or `name_only`.",
  #            "example": "1238.8763.00",
  #            "type": "string"
  #          },
  #          "user_id": {
  #            "description": "Member's unique LTI identifier.",
  #            "example": "535fa085f22b4655f48cd5a36a9215f64c062838",
  #            "type": "string"
  #          },
  #          "roles": {
  #            "description": "Member's roles in the current Context, expressed as LTI/LIS URNs.",
  #            "items": {
  #              "type": "string",
  #              "enum": [
  #                "http://purl.imsglobal.org/vocab/lis/v2/membership/Instructor#TeachingAssistant",
  #                "http://purl.imsglobal.org/vocab/lis/v2/membership#Learner",
  #                "http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor",
  #                "http://purl.imsglobal.org/vocab/lis/v2/membership#ContentDeveloper",
  #                "http://purl.imsglobal.org/vocab/lis/v2/membership#Mentor",
  #                "http://purl.imsglobal.org/vocab/lis/v2/membership#Member",
  #                "http://purl.imsglobal.org/vocab/lis/v2/membership#Manager"
  #              ]
  #            },
  #            "type": "array",
  #            "example": [
  #              "http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor",
  #              "http://purl.imsglobal.org/vocab/lis/v2/membership#ContentDeveloper"
  #            ]
  #          },
  #          "message": {
  #            "description": "Only present when the request specifies a `rlid` query parameter. Contains additional attributes which would appear in the LTI launch message were this member to click the link referenced by the `rlid` query parameter",
  #            "type": "array",
  #            "items": { "$ref": "NamesAndRoleMessage" },
  #            "example": [
  #              {
  #                "https://purl.imsglobal.org/spec/lti/claim/message_type": "LtiResourceLinkRequest",
  #                "locale": "en",
  #                "https://www.instructure.com/canvas_user_id": 1,
  #                "https://www.instructure.com/canvas_user_login_id": "showell@school.edu",
  #                "https://purl.imsglobal.org/spec/lti/claim/custom": {
  #                   "message_locale": "en",
  #                   "person_address_timezone": "America/Denver"
  #                }
  #              }
  #            ]
  #          }
  #        }
  #     }
  #
  #
  # @model NamesAndRoleMemberships
  #     {
  #        "id": "NamesAndRoleMemberships",
  #        "description": "",
  #        "properties":
  #        {
  #          "id": {
  #            "description": "Invocation URL",
  #            "example": "https://example.instructure.com/api/lti/courses/1/names_and_roles?tlid=f91ca4d8-fa84-4a9b-b08e-47d5527416b0",
  #            "type": "string"
  #          },
  #          "context": {
  #            "description": "The LTI Context containing the memberships",
  #            "$ref": "NamesAndRoleContext",
  #            "example": {
  #              "id": "4dde05e8ca1973bcca9bffc13e1548820eee93a3",
  #              "label": "CS-101",
  #              "title": "Computer Science 101"
  #            }
  #          },
  #          "members": {
  #            "type": "array",
  #            "description": "A list of NamesAndRoleMembership",
  #            "items": { "$ref": "NamesAndRoleMembership" },
  #            "example": [
  #              {
  #                "status": "Active",
  #                "name": "Sienna Howell",
  #                "picture": "https://example.instructure.com/images/messages/avatar-50.png",
  #                "given_name": "Sienna",
  #                "family_name": "Howell",
  #                "email": "showell@school.edu",
  #                "lis_person_sourcedid": "1238.8763.00",
  #                "user_id": "535fa085f22b4655f48cd5a36a9215f64c062838",
  #                "roles": [
  #                  "http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor",
  #                  "http://purl.imsglobal.org/vocab/lis/v2/membership#ContentDeveloper"
  #                ],
  #                "message": [
  #                  {
  #                    "https://purl.imsglobal.org/spec/lti/claim/message_type": "LtiResourceLinkRequest",
  #                    "locale": "en",
  #                    "https://www.instructure.com/canvas_user_id": 1,
  #                    "https://www.instructure.com/canvas_user_login_id": "showell@school.edu",
  #                    "https://purl.imsglobal.org/spec/lti/claim/custom": {
  #                      "message_locale": "en",
  #                      "person_address_timezone": "America/Denver"
  #                    }
  #                  }
  #                ]
  #              },
  #              {
  #                "status": "Active",
  #                "name": "Terrence Walls",
  #                "picture": "https://example.instructure.com/images/messages/avatar-51.png",
  #                "given_name": "Terrence",
  #                "family_name": "Walls",
  #                "email": "twalls@school.edu",
  #                "lis_person_sourcedid": "5790.3390.11",
  #                "user_id": "86157096483e6b3a50bfedc6bac902c0b20a824f",
  #                "roles": [
  #                  "http://purl.imsglobal.org/vocab/lis/v2/membership#Learner"
  #                ],
  #                "message": [
  #                  {
  #                    "https://purl.imsglobal.org/spec/lti/claim/message_type": "LtiResourceLinkRequest",
  #                    "locale": "de",
  #                    "https://www.instructure.com/canvas_user_id": 2,
  #                    "https://www.instructure.com/canvas_user_login_id": "twalls@school.edu",
  #                    "https://purl.imsglobal.org/spec/lti/claim/custom": {
  #                      "message_locale": "en",
  #                      "person_address_timezone": "Europe/Berlin"
  #                    }
  #                  }
  #                ]
  #              }
  #            ]
  #          }
  #        }
  #     }
  class NamesAndRolesController < ApplicationController
    # rubocop:enable Metrics/LineLength
    include Concerns::AdvantageServices

    MIME_TYPE = 'application/vnd.ims.lti-nrps.v2.membershipcontainer+json'.freeze

    # @API List Course Memberships
    # Return active NamesAndRoleMemberships in the given course.
    #
    # @argument rlid [String]
    #   If specified only NamesAndRoleMemberships with access to the LTI link references by this `rlid` will be included.
    #   Also causes the member array to be included for each returned NamesAndRoleMembership.
    #   If the `role` parameter is also present, it will be 'and-ed' together with this parameter
    #
    # @argument role [String]
    #   If specified only NamesAndRoleMemberships having this role in the given Course will be included.
    #   Value must be a fully-qualified LTI/LIS role URN.
    #   If the `rlid` parameter is also present, it will be 'and-ed' together with this parameter
    #
    # @argument limit [String]
    #   May be used to limit the number of NamesAndRoleMemberships returned in a page
    #
    # @returns NamesAndRoleMemberships
    def course_index
      render_memberships
    end

    # @API List Group Memberships
    # Return active NamesAndRoleMemberships in the given group.
    #
    # @argument `rlid` [String]
    #   If specified only NamesAndRoleMemberships with access to the LTI link references by this `rlid` will be included.
    #   Also causes the member array to be included for each returned NamesAndRoleMembership.
    #   If the role parameter is also present, it will be 'and-ed' together with this parameter
    #
    # @argument role [String]
    #   If specified only NamesAndRoleMemberships having this role in the given Group will be included.
    #   Value must be a fully-qualified LTI/LIS role URN. Further, only
    #   http://purl.imsglobal.org/vocab/lis/v2/membership#Member and
    #   http://purl.imsglobal.org/vocab/lis/v2/membership#Manager are supported.
    #   If the `rlid` parameter is also present, it will be 'and-ed' together with this parameter
    #
    # @argument limit [String]
    #   May be used to limit the number of NamesAndRoleMemberships returned in a page
    #
    # @returns NamesAndRoleMemberships
    def group_index
      render_memberships
    end

    def base_url
      polymorphic_url([context, :names_and_roles])
    end

    def scopes_matcher
      self.class.all_of(TokenScopes::LTI_NRPS_V2_SCOPE)
    end

    def context
      get_context
      @context
    end

    private

    def render_memberships
      page = find_memberships_page
      render json: NamesAndRolesSerializer.new(page).as_json, content_type: MIME_TYPE
    rescue AdvantageErrors::AdvantageClientError => e # otherwise it's a system error, so we want normal error trapping and rendering to kick in
      handled_error(e)
      render_error e.api_message, e.status_code
    end

    def find_memberships_page
      {url: request.url}.reverse_merge(new_provider.find)
    end

    def new_provider
      Providers.const_get("#{context.class}MembershipsProvider").new(context, self, tool)
    end
  end
end
