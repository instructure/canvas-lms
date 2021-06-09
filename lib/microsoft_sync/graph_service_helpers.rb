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
      def public_message
        I18n.t('Unexpected response from Microsoft API. This is likely a bug. ' \
               'Please contact support.')
      end
    end

    MAX_MAIL_NICKNAME_LENGTH = 64
    GET_GROUP_USERS_BATCH_SIZE = 999 # Max batch size to minimize API calls

    def initialize(tenant)
      @graph_service = GraphService.new(tenant)
    end

    def list_education_classes_for_course(course)
      graph_service.list_education_classes(filter: {externalId: course.uuid})
    end

    # Returns the hash of the new course, including the 'id' key
    def create_education_class(course)
      graph_service.create_education_class(
        description: course.public_description.presence,
        displayName: course.name,
        externalId: course.uuid,
        externalName: course.name,
        externalSource: 'manual',
        mailNickname: mail_nickname_for(course)
      )
    end

    def update_group_with_course_data(ms_group_id, course)
      graph_service.update_group(
        ms_group_id,
        microsoft_EducationClassLmsExt: {
          ltiContextId: course.lti_context_id || Lti::Asset.opaque_identifier_for(course),
          lmsCourseId: course.uuid,
          lmsCourseName: course.name,
          lmsCourseDescription: course.public_description,
        },
        microsoft_EducationClassSisExt: {
          sisCourseId: course.sis_source_id,
        }
      )
    end

    USERS_UPNS_TO_AADS_BATCH_SIZE = 15 # Max number of "OR"s in filter clause

    # Returns a hash from UPN -> AAD. Accepts 15 at a time.
    # A UPN (userPrincipalName) is en email address, username, or other
    # property that Canvas has.  An AAD (short term for AAD [Azure Active
    # Directory] object ID) is the ID for the user on the Microsoft side, which
    # is what Microsoft references in their groups/teams.
    #
    # UPNs are case-insensitive on the Microsoft side; this method downcases
    # them before requesting them from Microsoft, but the keys in the return
    # hash match the case of the upns that were passed in.
    def users_upns_to_aads(upns)
      downcased_uniqued = upns.map(&:downcase).uniq
      if downcased_uniqued.length > USERS_UPNS_TO_AADS_BATCH_SIZE
        raise ArgumentError, "Can't look up #{upns.length} UPNs at once"
      end

      upns_downcased_to_given_forms = upns.group_by(&:downcase)

      unexpected = []
      result_hash = {}

      graph_service.list_users(
        select: %w[id userPrincipalName],
        filter: {userPrincipalName: downcased_uniqued}
      ).each do |result|
        given_forms = upns_downcased_to_given_forms[result['userPrincipalName'].downcase]
        if given_forms
          given_forms.each do |given_form|
            result_hash[given_form] = result['id']
          end
        else
          unexpected << result['userPrincipalName']
        end
      end

      if unexpected.present?
        raise UnexpectedResponseError,
              "/users returned unexpected UPN(s) #{unexpected.inspect}, " \
              "asked for #{downcased_uniqued}"
      end

      result_hash
    end

    def get_group_users_aad_ids(group_id, owners: false)
      method = owners ? :list_group_owners : :list_group_members
      [].tap do |aad_ids|
        graph_service.send(
          method, group_id, select: ['id'], top: GET_GROUP_USERS_BATCH_SIZE
        ) do |users|
          aad_ids.concat(users.map{|user| user['id']})
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
