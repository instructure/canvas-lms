# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
module Schemas::Docs
  class User < Schemas::Base
    def self.schema
      {
        id: "User",
        description: "A Canvas user, e.g. a student, teacher, administrator, observer, etc.",
        required: ["id"],
        properties: {
          id: {
            description: "The ID of the user.",
            example: 2,
            type: "integer",
            format: "int64"
          },
          name: {
            description: "The name of the user.",
            example: "Sheldon Cooper",
            type: "string"
          },
          sortable_name: {
            description: "The name of the user that is should be used for sorting groups of users, such as in the gradebook.",
            example: "Cooper, Sheldon",
            type: "string"
          },
          last_name: {
            description: "The last name of the user.",
            example: "Cooper",
            type: "string"
          },
          first_name: {
            description: "The first name of the user.",
            example: "Sheldon",
            type: "string"
          },
          short_name: {
            description: "A short name the user has selected, for use in conversations or other less formal places through the site.",
            example: "Shelly",
            type: "string"
          },
          sis_user_id: {
            description: "The SIS ID associated with the user.  This field is only included if the user came from a SIS import and has permissions to view SIS information.",
            example: "SHEL93921",
            type: "string"
          },
          sis_import_id: {
            description: "The id of the SIS import.  This field is only included if the user came from a SIS import and has permissions to manage SIS information.",
            example: "18",
            type: "integer",
            format: "int64"
          },
          integration_id: {
            description: "The integration_id associated with the user.  This field is only included if the user came from a SIS import and has permissions to view SIS information.",
            example: "ABC59802",
            type: "string"
          },
          login_id: {
            description: "The unique login id for the user.  This is what the user uses to log in to Canvas.",
            example: "sheldon@caltech.example.com",
            type: "string"
          },
          avatar_url: {
            description: "If avatars are enabled, this field will be included and contain a url to retrieve the user's avatar.",
            example: "https://en.gravatar.com/avatar/d8cb8c8cd40ddf0cd05241443a591868?s=80&r=g",
            type: "string"
          },
          avatar_state: {
            description: "Optional: If avatars are enabled and caller is admin, this field can be requested and will contain the current state of the user's avatar.",
            example: "approved",
            type: "string"
          },
          enrollments: {
            description: "Optional: This field can be requested with certain API calls, and will return a list of the users active enrollments. See the List enrollments API for more details about the format of these records.",
            type: "array",
            items: { "$ref": "Enrollment" }
          },
          email: {
            description: "Optional: This field can be requested with certain API calls, and will return the users primary email address.",
            example: "sheldon@caltech.example.com",
            type: "string"
          },
          locale: {
            description: "Optional: This field can be requested with certain API calls, and will return the users locale in RFC 5646 format.",
            example: "tlh",
            type: "string"
          },
          last_login: {
            description: "Optional: This field is only returned in certain API calls, and will return a timestamp representing the last time the user logged in to canvas.",
            example: "2012-05-30T17:45:25Z",
            type: "string",
            format: "date-time"
          },
          time_zone: {
            description: "Optional: This field is only returned in certain API calls, and will return the IANA time zone name of the user's preferred timezone.",
            example: "America/Denver",
            type: "string"
          },
          bio: {
            description: "Optional: The user's bio.",
            example: "I like the Muppets.",
            type: "string"
          },
          pronouns: {
            description: "Optional: This field is only returned if pronouns are enabled, and will return the pronouns of the user.",
            example: "he/him",
            type: "string"
          }
        }
      }
    end
  end
end
