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
#

#
# Wraps GraphService, which provides lower-level access to the Microsoft Graph API, with
# functions specific to canvas models and the particular Microsoft API fields we use.
#
module MicrosoftSync
  class GraphServiceHelpers
    attr_reader :graph_service

    class UnexpectedResponseError < Errors::PublicError
      def self.public_message
        I18n.t("Unexpected response from Microsoft API. This is likely a bug. " \
               "Please contact support.")
      end
    end

    MAX_MAIL_NICKNAME_LENGTH = 64
    GET_GROUP_USERS_BATCH_SIZE = 999 # Max batch size to minimize API calls

    def initialize(tenant, extra_statsd_tags)
      @graph_service = GraphService.new(tenant, extra_statsd_tags)
    end

    def list_education_classes_for_course(course)
      graph_service.education_classes.list(filter: { externalId: course.uuid })
    end

    # Returns the hash of the new course, including the 'id' key
    def create_education_class(course)
      graph_service.education_classes.create(
        description: course.public_description.presence&.truncate(1024),
        displayName: course.name,
        externalId: course.uuid,
        externalName: course.name,
        externalSource: "manual",
        mailNickname: mail_nickname_for(course)
      )
    end

    def update_group_with_course_data(ms_group_id, course)
      graph_service.groups.update(
        ms_group_id,
        microsoft_EducationClassLmsExt: {
          ltiContextId: course.lti_context_id || Lti::Asset.opaque_identifier_for(course),
          lmsCourseId: course.uuid,
          lmsCourseName: course.name,
          lmsCourseDescription: course.public_description&.truncate(256),
        },
        microsoft_EducationClassSisExt: {
          sisCourseId: course.sis_source_id,
        }
      )
    end

    USERS_ULUVS_TO_AADS_BATCH_SIZE = 15 # Max number of "OR"s in filter clause

    # Returns a hash from ULUV -> AAD. Accepts 15 at a time. A ULUV (User
    # LookUp Value) is a value we use to look up users. It is derived from
    # something in Canvas (e.g. a user's email address, username, or SIS ID
    # -- see UsersUluvsFinder).  We expect the ULUV to correspond to the
    # property of the Microsoft user indicated by the `remote_attribute`
    # argument: e.g. userPrincipalName (default if nil is passed) or
    # mailNickname.
    # We then return a hash of ULUV -> AAD object ID. An AAD [Azure Active
    # Directory] object ID, referred to here as just an "aad", is the ID for
    # the user on the Microsoft side, which is what Microsoft references in
    # their groups/teams.
    #
    # The properties on Microsoft's user objects are case-insensitive, so this
    # method downcases and uniqs the ULUVs before requesting them from
    # Microsoft. But whatever casing the Microsoft response uses, this function
    # makes sure the keys in the return hash match the case of the ULUVs that
    # were passed in.
    def users_uluvs_to_aads(remote_attribute, uluvs)
      remote_attribute ||= "userPrincipalName"

      downcased_uniqued = uluvs.map(&:downcase).uniq
      if downcased_uniqued.length > USERS_ULUVS_TO_AADS_BATCH_SIZE
        raise ArgumentError, "Can't look up #{uluvs.length} ULUVs at once"
      end

      uluvs_downcased_to_given_forms = uluvs.group_by(&:downcase)

      unexpected = []
      result_hash = {}

      graph_service.users.list(
        select: ["id", remote_attribute],
        filter: { remote_attribute => downcased_uniqued }
      ).each do |user_object|
        given_forms = uluvs_downcased_to_given_forms[user_object[remote_attribute].downcase]
        if given_forms
          given_forms.each do |given_form|
            result_hash[given_form] = user_object["id"]
          end
        else
          unexpected << user_object[remote_attribute]
        end
      end

      if unexpected.present?
        raise UnexpectedResponseError,
              "/users returned users with unexpected #{remote_attribute} values " \
              "#{unexpected.inspect}, asked for #{downcased_uniqued}"
      end

      result_hash
    end

    def get_group_users_aad_ids(group_id, owners: false)
      method = owners ? :list_owners : :list_members
      [].tap do |aad_ids|
        graph_service.groups.send(
          method, group_id, select: ["id"], top: GET_GROUP_USERS_BATCH_SIZE
        ) do |users|
          aad_ids.concat(users.pluck("id"))
        end
      end
    end

    private

    def mail_nickname_for(course)
      prefix = "Course_"
      postfix = "-#{course.uuid.first(13)}"

      safe_course_code = course.course_code.strip.parameterize.underscore.first(
        MAX_MAIL_NICKNAME_LENGTH - (postfix.length + prefix.length)
      )

      "#{prefix}#{safe_course_code}#{postfix}"
    end
  end
end
